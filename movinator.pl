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
	
	foreach (`mplayer -benchmark -ao null -vo null -identify -frames 0 "$n"`) {
		chop;
		
		if (/^ID_DEMUXER/) { ($ext) = /=(.*)/; }
		if ($ext =~ /^mpeg/) { $ext = "mpg"; }
		# it's actually more than just mkv, but this is the most common I'm moving
		if ($ext =~ /^lavfpref/) { $ext = "mkv"; }
		if (/^ID_VIDEO_FORMAT/) { ($vcodec) =  /=(.*)/; } 
		if ($arch eq "powerpc") { $vcodec = reverse $vcodec; }
		
		if ($vcodec eq "10000001x0") { $vcodec = "mpeg1"; }
		if ($vcodec eq "20000001x0") { $vcodec = "mpeg2"; }
		
		if (/^ID_VIDEO_WIDTH/) { ($width) = /=(.*)/; }
		if (/^ID_VIDEO_HEIGHT/) { ($height) = /=(.*)/; }
		if (/^ID_VIDEO_FPS/) { ($fps) = /=(.*)/; }
		if (/^ID_AUDIO_RATE/) { ($arate) = /=(.*)/; }
		if (/^ID_AUDIO_CODEC/) { ($acodec) = /=(.*)/; }
		
		if ($acodec eq "faad") { $acodec = "aac"; }
	}
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

		if (! -d $g) {
			mkdir $g;
		}
		
		printf "link $nn to $g/\n";

		link $nn, "$targetdir/$g/$nn";
		#rename $n, "$targetdirseries/$nn";

}
}
