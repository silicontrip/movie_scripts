#!/usr/bin/perl

use Getopt::Long;
use LWP::Simple;

sub findname ($$) {
	
	my ($targetdir,$targetepisode) = @_;
	my $episode;
	my @eplist;
	my $epregex;
	my $epname;
	my $name;
	
	# read episode list from target directory.
	if (opendir($sdh,$targetdir) ) {
		while($episode=readdir $sdh) {
			if (!($episode =~ /^\./)) {
				#print "$targetdir / $episode\n";
				if ( -d "$targetdir/$episode") {
					#print "$episode\n";
					push (@eplist,$episode);
				}
			}
		}
	}
	
	#print join(",",@eplist);
	
	# try and find match.
	# $targetepisode = $ARGV[0]; 
	$targetepisode =~ s/.*\///; 
	#	print "$targetepisode\n";
	for $epname (@eplist) {
		
		# hack up names to match
		
		$epregex = $epname;
		$epregex =~ s/([a-z])([A-Z])/$1.*$2/g;
		$epregex =~ s/([a-zA-Z])([0-9])/$1.*$2/g;
		$epregex =~ s/([0-9])([a-zA-Z])/$1.*$2/g;
		$epregex =~ s/([A-Z])([A-Z])/$1.*$2/g;
		
		#	print "$targetepisode $epregex\n";
		
		if ($targetepisode =~ /$epregex/i) {
			if (!$name) { 
				$name = $epname;
			} else {
				
				print "Multiple matches. $name, $epname\n";
				if (length($name) < length($epname)) {
					$name = $epname;
				}
			}
		}
		
	}
	
	return $name;
	
}
sub epguidesarray ($) {
	
	my ($episodes) = @_;
	my %episodeList;
	my @lines = split /\n/, $episodes;
	my $title;
	
	foreach my $line (@lines) {
		
		chomp($line);
		
		if ($line =~ /\<h1>/) {
			($title) = $line =~ /\">([^<]*)\<\/a>/; #"
			$title =~ s/[^a-zA-Z10-9]//g;
			$episodeList{'title'} = $title;
			#print "TITLE: $title\n";
		}
		
		$line =~ s/<[^>]*>/;/g;
		
		#print "$line\n";
		
		
		
		($se,$ep,$date,$epname) = $line =~ /(\d+)-([\d\s]\d+).*(\d+[\s\/][A-Z][a-z][a-z][\s\/]\d+)\s+;*([^;]*);*.*$/;
		$ep = sprintf "%02d", $ep;
		$se = sprintf "%02d", $se;
		#	($date) = $line =~ /(\d\d\/[A-Z][a-z][a-z]\/\d\d)/;
		#	($epname) = $line =~ /'>([^<]*)<\/a>/;
		
		
		# if ($se > 0 && $ep > 0) { print "$se -- $ep -- $date -- $epname\n"; }
		
		if ($date) {
			$epname =~ s/[^a-zA-Z10-9]/_/g;
			$epname =~ s/__*/_/g;
			$epname =~ s/^_//;
			$epname =~ s/_$//;
			# maybe cache this in a DB.
			$episodeList{"s${se}e$ep"}=$epname;
			#print "s${se}e$ep-$epname\n";
		}
	}
	return $episodeList;
}
sub geteplist_file ($$) {
	
	my ($name,$targetdir) = @_;
	local $/=undef;
	
	open (EPLIST,"$targetdir/$name/.eplist") || return ();
	$episodes=<EPLIST>;
	close EPLIST;
	
	return &epguidesarray($episodes);
	
}
sub geteplist_epguides ($) {
	
	my ($name) = @_;
	my $url = "http://epguides.com";
	my $episodes = get("$url/$name/");
	
	if (!defined $episodes) {
		return ();
	}
	return &epguidesarray($episodes);
}
sub geteplist_thetvdb ($) {

	my ($id) = @_;

#print STDERR "geteplist_thetvdb $id\n";
	
	my $url = "http://thetvdb.com";
	my $episodes = get("$url/?id=$id&tab=seasonall");
	my @lines = split /\n/, $episodes;
	my $title;

	foreach my $line (@lines) {
		
		chomp($line);

		if ($line =~ /\<h1>/) {
			($title) = $line =~ /\">([^<]*)\<\/a>/; #"
			$title =~ s/[^a-zA-Z10-9]//g;
			$episodeList{'title'} = $title;
			#print "TITLE: $title\n";
		}
		
		$line =~ s/<[^>]*>/;/g;

		#print "$line\n";

		#;;;1 - 1;;;;Hairy Maclary from Donaldson's Dairy;;;;;; &nbsp;;;
		#;;;1 - 1;;;;The First Time;;;2012-01-09;;; &nbsp;;;
		
		($se,$ep,$epname,$date) = $line =~ /;*(\d+) - (\d+);*([^;]*);*(\d\d\d\d-\d\d-\d\d);*.*$/;
	# some series are missing dates
		if (!$date) {
			$date = "TBA";
			($se,$ep,$epname) = $line =~ /;*(\d+) - (\d+);*([^;]*);*.*$/;
		}


		$ep = sprintf "%02d", $ep;
		$se = sprintf "%02d", $se;

		if ($date) {
			$epname =~ s/[^a-zA-Z10-9]/_/g;
			$epname =~ s/__*/_/g;
			$epname =~ s/^_//;
			$epname =~ s/_$//;
			# maybe cache this in a DB.
			$episodeList{"s${se}e$ep"}=$epname;
			#	print "s${se}e$ep-$epname\n";
		}
		
		
	}
	return %episodeList;
	
}
sub get_se ($) {
	
	my ($n) = @_;
	
	$n =~ s/.*\///;

	$season ="";
	$episode ="";
	
	if ($n =~ /[^\d](\d?\d)(\d\d)[^\d]/)
	{ $season = $1; $episode = $2; }
	if ($n =~ /(\d?\d)[xe](\d\d?)/i) 
	{ $season = $1; $episode = $2; }
	if ($n =~ /S(\d?\d)[^\d]*E(\d\d?)/i)
	{ $season = $1; $episode = $2; }
	if ($n =~ /[^\d](\d?\d)[^\d]+(\d\d)[^\d]/i)
	{ $season = $1; $episode = $2; }
	if ($n =~ /S(\d?\d)E(\d\d)/i)
	{ $season = $1; $episode = $2; }
	
	return "$season;$episode";
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
sub name_to_id ($$) {
	
	my ($name,$target) = @_;
	my $id;
	local $/=undef;
	
	#	print "$targetdir / $name\n";	
	
	open (ID,"$targetdir/$name/.id") || return ();
	#print "Reading ID\n";
	$id=<ID>;
	close ID;
	
	chop($id);
	#	print "($id)\n";
	
	return $id;
}
sub find_series_thetvdb ($) {
	
	my ($name) = @_;
	my $sname;
	my $lang;
	my $id;
	my $oldid;
	my $single = 1;
	my $url = "http://thetvdb.com";
	
	$name =~ s/([a-z])([A-Z])/$1+$2/g;
	$name =~ s/([a-zA-Z])([0-9])/$1+$2/g;
	$name =~ s/([0-9])([a-zA-Z])/$1+$2/g;
	$name =~ s/([A-Z])([A-Z])/$1+$2/g;
	
	#print "$name\n";
	
	my $episodes = get("$url/?string=$name&searchseriesid=&tab=listseries&function=Search");

	my @lines = split /\n/, $episodes;

	
	foreach my $line (@lines) {
		
		chomp($line);
				
		$line =~ s/<[^>]*>/;/g;
		$line =~ s/^\s+//g;
		
		#print "$line\n";
		#;;;Eternal Law; ;;English;;238101;;

		($sname,$lang,$id) = $line =~ /^;;;([^;]*);*\s*;*([^;]*);*(\d+);*$/;
		if ($sname) {
			print "$sname - $lang - $id\n";
			if ($oldid && $oldid != $id) { print "Multiple TVDB matches\n"; $single = 0; }
			$oldid = $id;
		}
	}
	
	#print "returning $oldid\n";
	return $oldid if $single;
	return 0;
	
}

$arch = `uname -p`;
chop($arch);
$targetdir="/Volumes/Drobo/TVSeries";

$result = GetOptions ("no-rename|t" => \$test, "name|N=s" => \$name, "move|m" => \$move, "id|i=s" => \$id);  # flag

# print "name: $name\n";
# print "id: $id\n";




if (!$id && !$name) {
	$name = findname ($targetdir,$ARGV[0]);
	#print "Chosen $name\n";
	die "Must specify name (-N) or thetvdb id (-i)\nExiting" unless ($name);
	$id = &name_to_id($name,$targetdir);
}

$id = &find_series_thetvdb($name) unless $id;
die "Cannot find thetvdb ID\nExiting" unless ($id);
	

%episodeList = &geteplist_thetvdb($id);
$title = $episodeList{'title'};
	


if ($move  && ! -e "$targetdir/$name") { die "Target Directory $targetdir/$name does not exist. Exiting"; }

%episodeList = geteplist_epguides($title) unless $id;
# test to see if it returned null and try a different method.

if ($episodeList{'title'}) { $seriesname = $episodeList{'title'}; }

# print "Title $title\n";

while ($n = shift) {

	
#print "Testing $n\n";

if ( -f $n) {

	$se = get_se($n);
	($season,$episode) = split(/;/,$se);
	
#	print "$seriesname - $season - $episode\n";
	
	if (($seriesname) && ($season) && ($episode) ) {
		
#			print "Get meta data\n";
		
		$meta = get_movie_meta($n);
		
		($ext,$vcodec,$width,$height,$fps,$arate,$acodec) = split (/;/,$meta);
		
		$season = sprintf("%02d",$season);
		$episode = sprintf("%02d",$episode);
		$epname = $episodeList{"s${season}e$episode"};
		
		print "($epname)\n";
		if ($epname =~ /episode_\d+/i) { $epname = (); } # remove the silly UK nameless naming convention
		
		$nn = "${seriesname}-s${season}e${episode}.$vcodec-${width}x${height}x${fps}.$acodec-$arate.$ext";
		if ($epname) {
			$nn = "${seriesname}-s${season}e${episode}.$epname.$vcodec-${width}x${height}x${fps}.$acodec-$arate.$ext";
		}
		if (! -e "$nn" || $move) {
			if (!$test) {
				#print "Move ...\n";
				if ($move) {
					$targetdirseries = "";
					$season = sprintf("%02d",$season);
					if (-e "$targetdir/$name/S$season") { $targetdirseries="$targetdir/$name/S$season"; }
					#if (-e "$targetdir/$name/Season$season") { $targetdirseries="$targetdir/$name/Season$season"; }
					#if (-e "$targetdir/$name/Series$season") { $targetdirseries="$targetdir/$name/Series$season"; }
					#$season = sprintf("%d",$season);
					#if (-e "$targetdir/$name/Season$season") { $targetdirseries="$targetdir/$name/Season$season"; }
					#if (-e "$targetdir/$name/Series$season") { $targetdirseries="$targetdir/$name/Series$season"; }
	
				#print "Target dir series: $targetdirseries\n";

					if ($targetdirseries) {
						printf "rename $n to $targetdirseries/$nn\n";
						if (! -r "$targetdirseries/$nn") {
							rename $n, "$targetdirseries/$nn";
						} else {
								print "File Exists.\n";
						}
					} else {
						print "mkdir $targetdir/$name/S$season\n";
						die "cannot find Series Directory: $targetdir $name season $season. ($$targetdirseries) Exiting";
					}
					
				} else {
						if (! -r "$nn") {
					printf "rename $n to $nn\n";
					rename $n, $nn;
						} else {
								print "File Exists.\n";
						}
				}
			}
		} else {
			printf "$nn exists\n";
		}
	} 
}


}
