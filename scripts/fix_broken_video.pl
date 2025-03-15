#!/usr/bin/perl

use Data::Dumper;
use Getopt::Long;
use File::Basename;  # Для використання fileparse

my($ffmpeg,$ffprobe);

$ffmpeg="ffmpeg";
$ffprobe="ffprobe";

# Змінні для налаштування параметрів
my $goodfile = "$FindBin::Bin/default_template.mov"; # За замовчуванням
my $badfile;
my $outfile_prefix;

use FindBin;  # Для отримання шляху до каталогу зі скриптом

# Отримуємо параметри командного рядка
GetOptions(
    'good|g|reference|r=s' => \$goodfile  # Параметри для "хорошого" файлу
) or die "Error in command line arguments\n";

# Перевіряємо, чи вказаний "поганий файл" як перший аргумент
if (@ARGV) {
    $badfile = $ARGV[0];  # Беремо поганий файл з аргументу
} else {
    die "Bad file is required. Usage:\n$0 [-g good_file.mov | -r reference_file.mov] bad_file.mp4\n";
}

if (!-e $goodfile) {
    die "Good file '$goodfile' does not exist. Please provide a valid path.\n";
}

if (!-e $badfile) {
    die "Bad file '$badfile' does not exist. Please provide a valid path.\n";
}

# Визначаємо префікс для вихідних файлів
my $outfile_prefix = (split /\./, $goodfile)[0] . "_fixed";  # додаємо суфікс _fixed до назви файлу без розширення

my $sample_h264=$outfile_prefix."-headers.h264";
my $sample_stat_h264=$outfile_prefix."-stat.mp4";
my $sample_aac=$outfile_prefix."-headers.aac";
my $sample_nals=$outfile_prefix."-nals.txt";
my $sample_nals_stat=$outfile_prefix."-nals-stat.txt";
my $out_video=$outfile_prefix."-out-video.h264";
my $out_audio=$outfile_prefix."-out-audio.raw";

print "Build intemidiates...\n";
if(!-e($sample_h264)){`$ffmpeg -i "$goodfile" -c copy -frames 1 -bsf h264_mp4toannexb "$sample_h264"`;}
if(!-e($sample_stat_h264)){`$ffmpeg -i "$goodfile" -c copy -t 20 -an "$sample_stat_h264"`;}
if(!-e($sample_nals)){`$ffprobe -select_streams 0 -show_packets -show_data "$sample_stat_h264" > "$sample_nals"`;}
if(!-e($sample_aac)){`$ffmpeg -i "$goodfile" -c copy -t 1 -f adts "$sample_aac"`;}

print "Opening files...\n";
open(bfile,$badfile) or die "$badfile: $!";
open(vhead,$sample_h264);
open(nals,$sample_nals);
open(vout,">".$out_video) or die "$out_video: $!";
open(aout,">".$out_audio) or die "$out_audio: $!";
read(vhead,$header,0x100);
$header=~s/\x00\x00+\x01[\x65\x45\x25].+$//s;

binmode(vout);
binmode(aout);
binmode(bfile);
binmode(vhead);

# get nals
my $buf;
my $size;
my @nals=map{
{
    min=>0xFFFFFF,
    max=>0x0,
    id=>$_
}
}(0..0b11111);
while(<nals>){
    if(/^0.......: (.{40})/){
        $buf.=$1;
        next;
    }
    if(/^\[\/PACKET\]/ && $buf){
        $buf=~s/[^0-9A-F]//igs;

        while(1){
            $size=hex(substr($buf,0,8));
            print "NAL $size bytes, type: $type\n";
            if(length($buf)>=$size*2+8){

                $type=hex(substr($buf,8,2))&0b11111;
                $bytes=pack("H*",substr($buf,8,$type==5?6:4));

                $n=$nals[$type];
                if($n->{min}>$size){ $n->{min}=$size;}
                if($n->{max}<$size){ $n->{max}=$size;}
                $n->{bytes}{$bytes}=1;
                $n->{printbytes}{substr($buf,8,8)}=1;

                $buf=substr($buf,8+$size*2);
            } else {
                last;
            }
        }

        print "Remain ".length($buf).": ".substr($buf,0,32)."\n";
        $buf="";

    }

}

#print join("\n",keys %nals);
print Dumper(\@nals);
open(st,">".$sample_nals_stat);
print st Dumper(\@nals);
close(st);

##################################

#die;@nals{map{s/(..)/pack("C",hex($1))/eg;$_}split(/\n/,$nals)}=undef;

print vout $header;

$was_key=0;
# main loop
$shit="";

$fsize=-s(bfile);

$blocksize=10000000;

$file="";
while(1){
    $fsize=read(bfile,$buf,$blocksize);
    if($fsize==0){
        last;
    }
    $file=$file.$buf;
    $buf="";
    $fsize=length($file)-10;

    $stime=time();
    for($q=0;$q<$fsize;){

        my $size=unpack("N",substr($file,$q,4));
        my $header=unpack("C",substr($file,$q+4,1));
        my $zerobit=$header&0x80;
        my $type=$header&0b11111;

        if(time()!=$stime){
            printf("testing at %.5x (of %.5x) gives us $size\n",tell(bfile)-$q,$fsize);
            $stime=time();
        }
        if($size>0 && $zerobit==0 && $nals[$type]->{max}){
            $nextbytes=substr($file,$q+4,$type==5?3:2);
            $iskey=$type==5?1:0;

            if(exists $nals[$type]->{bytes}{$nextbytes} && $size>=$nals[$type]->{min}/2 && $size <= $nals[$type]->{max}*2){
                print "Got! $size bytes and ".length($shit)." shit\n";
                if($ok){
                    print aout $shit;
                }

                #writing frame
                $tail=length($file)-$q-4;
                if($tail>$size){$tail=$size;}
                $left=$size-$tail;


                if($iskey || $was_key){
                    print vout "\x00\x00\x00\x01"; # signature
                    print vout substr($file,$q+4,$tail);
                    if($left){
                        read(bfile,$buf,$left);
                        print vout $buf;
                        $buf="";
                    }
                    $was_key=1;
                } else {
                    # if very beginning and no key frames was yet - just skip this frames
                    if($left){
                        read(bfile,$buf,$left);
                        $buf="";
                    }
                }
                $shit="";
                $ok++;
                $q+=$size+4;
                next;
            }
        }

        $shit.=substr($file,$q,1);
        $q++;

    }

    $file=substr($file,$q);

}

print `stat $out_video`;

# Після того, як ви закінчили обробку і отримали out-video.h264

# Отримуємо ім'я файлу з $badfile без розширення
my ($basename, $dir, $ext) = fileparse($badfile, qr/\.[^.]*/);

# Формуємо кінцеву назву файлу з префіксом _fin.mp4
my $final_mp4 = "$dir${basename}_fin.mp4";  # Назва фінального MP4

# Команда для конвертації з використанням ffmpeg для відновлення таймлайна
my $ffmpeg_command = "$ffmpeg -i $out_video -c:v libx264 -c:a aac -strict experimental -preset fast -movflags +faststart -y $final_mp4";

# Виконання команди
print "Converting to MP4...\n";
system($ffmpeg_command) == 0 or die "Error during MP4 conversion: $?\n";

# Перевірка створення фінального файлу
print "Final MP4 file: $final_mp4\n";
