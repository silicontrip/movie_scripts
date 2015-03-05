#!/usr/bin/perl

use Getopt::Long;
use LWP::Simple;
use URI::Escape;

sub get_id ($) {

	my ($name) = @_;
	my $url = "http://www.imdb.com/";
	my $query = "find?q=" . uri_escape($name) . "&s=title";

	my $id, $title;
		
my	$moviedata = get("${url}$query");
	my %idhash;
        my @lines = split /\<a/, $moviedata;

	foreach my $lineout (@lines) {
		$lineout =  "<a" . $lineout;
		foreach my $line (split /\n/ , $lineout) {
		if ($line =~ /\<a href=\"\/title\/tt/ ) {

			($id) = $line =~ /\<a href=\"\/title\/tt(\d*)/;
			$line =~ s/<[^>]*>/;/g;

			$line =~ s/&#x([0-9a-f]+);/chr(hex($1))/ige;

			print "$id $line\n";
			$idhash{$id} = $line;
		}
		}
	}

	my @idarray = keys(%idhash);
	if ($#idarray == 0) {
		return shift @idarray;
	}
	return 0;

}

sub get_title ($) {

	my ($n) = @_;
        my @lines = split /\n/, $n;

	foreach my $line (@lines) {
		chomp($line);

                if ($line =~ /\<title>/) {
                        ($title) = $line =~ /\<title>([^<]*)\<\/title>/; #"
			$title =~ s/&#x([0-9a-f]+);/chr(hex($1))/ige;
	print "UNPROCESSED: $title\n";
			$title =~ s/ /_/g;
			$title =~ s/\([^0-9]*\)//;
                        $title =~ s/[^a-zA-Z10-9_\&\-]//g;
			$title =~ s/_-_IMDb//;
			$title =~ s/IMDb_-_//;
			$title =~ s/^_*//;
			$title =~ s/_*$//;
		#	print "TITLE: $title\n";
			return $title;	
		}


	}
	die "Cannot find title\n";
	return "";
}

sub get_genre ($) {

	my ($n) = @_;
        my @lines = split /\n/, $n;

	my %genrelist;
	foreach my $line (@lines) {
		chomp($line);

                if ($line =~ /\/genre\//) {
			#print "$line\n";
                        ($genre) = $line =~ /href=\"\/genre\/([^\?]*)?/; #"
			#print "$genre\n";
			$genrelist{$genre} = 1;
		}


	}
	return keys(%genrelist);
}


sub get_movie_meta ($) {
	
	my ($n) = @_;
	
	foreach (`/Volumes/Drobo/bin/metadata-example "$n"`) {
		chop;

		($key,$val) = split(/=/);
		$meta{$key} = $val;
	}

		
# encoder=transcode-1.1.0
# FORMAT_NAME=avi
# STREAMS=2
# STREAM_0_TYPE=VIDEO
# STREAM_VIDEO_CODEC_ID=MPEG4
# STREAM_VIDEO_AFPS_RATIO=0:0
# STREAM_VIDEO_FPS_RATIO=2997003:125000
# STREAM_VIDEO_FPS=23.976024
# STREAM_VIDEO_WIDTH=640
# STREAM_VIDEO_HEIGHT=352
# STREAM_VIDEO_PIX_FMT=yuv420p
# STREAM_VIDEO_SAR=1:1
# STREAM_VIDEO_REFFRAMES=1
# STREAM_VIDEO_COLORSPACE=UNSPECIFIED
# STREAM_VIDEO_COLORRANGE=mpeg
# STREAM_VIDEO_FIELDORDER=UNKNOWN
# STREAM_1_TYPE=AUDIO
# STREAM_AUDIO_CODEC_ID=AC3
# STREAM_AUDIO_SAMPLERATE=48000
# STREAM_AUDIO_CHANNELS=6
# STREAM_AUDIO_SAMPLEFORMAT=fltp

		
	$ext = $meta{'FORMAT_NAME'};
	$vcodec = $meta{'STREAM_VIDEO_CODEC_ID'};
	$width = $meta{'STREAM_VIDEO_WIDTH'};
	$height = $meta{'STREAM_VIDEO_HEIGHT'};	
	$fps = $meta{'STREAM_VIDEO_FPS'};
	$arate = $meta{'STREAM_AUDIO_SAMPLERATE'};
	$acodec = $meta{'STREAM_AUDIO_CODEC_ID'};
		
	$fps = int($fps + 0.5);
	$arate =~ s/000$/k/;
	
	return "$ext;$vcodec;$width;$height;$fps;$arate;$acodec";
	
}

$arch = `uname -p`;
chop($arch);
$targetdir="/Volumes/Drobo/Movies";

$result = GetOptions ("no-rename|t" => \$test, "no-move|m" => \$nomove, "id|i=s" => \$id, "search|s=s" => \$search);  # flag

# print "name: $name\n";
# print "id: $id\n";

if ($search) { $id = get_id($search); }

die "Must specify imdb id (-i)\nExiting" unless $id;


$url = "http://www.imdb.com";
$moviedata = get("$url/title/tt$id/");
	
$title = &get_title($moviedata);
@genre = &get_genre($moviedata);
		
$n = shift;
$meta = get_movie_meta($n);
		
		($ext,$vcodec,$width,$height,$fps,$arate,$acodec) = split (/;/,$meta);

		$meta = "${width}x${height}-$acodec";

$nn="${title}.${meta}.$ext";

if (! -e $nn) {
		printf "rename $n to $nn\n";
		rename $n, $nn;
}


if (!$nomove) {
for $g (@genre) {

		if (! -d "$targetdir/$g") {
			mkdir "$targetdir/$g";
		}
		
		printf "link $nn to $g/\n";

		link $nn, "$targetdir/.All/$nn";
		link $nn, "$targetdir/$g/$nn";
		#rename $n, "$targetdirseries/$nn";

}
}
