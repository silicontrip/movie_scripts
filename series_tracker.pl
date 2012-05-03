#!/usr/bin/perl

use LWP::Simple qw($ua get);

use URI::Escape;
use Time::Local;
use Getopt::Std;

$ua -> timeout(30);

%options=();
getopts("vhigad:e",\%options);

$nodays = 0;
$retention= 200 * 86400;  # 200 days
if ($options{a}) { $nodays = 1; }
if ($options{g}) { $autoget = 1; $retention = 7 * 86400; }
if ($options{d}) { $retention = $options{d} * 86400; }
if ($options{i}) { $ignore = 1; }
if ($options{v}) { $verbose = 1; }
if ($options{e}) { $nodays = 1; $eseug = 1; }
if ($options{h}) { print "usage series_tracker [-agi] [-d days]\n\t-a show all, do not limit by age\n\t-d do not show episodes older than days (default 200)\n\t-g get nzb file for missing episodes\n\t-i ignore the .ignore file\n"; exit; }


#print "$ARGV[0] - $ARGV[1] - $ARGV[2]\n";



%month= (
Jan => "0",
Feb => "1",
Mar => "2",
Apr => "3",
May => "4",
Jun => "5",
Jul => "6",
Aug => "7",
Sep => "8",
Oct => "9",
Nov => "10",
Dec => "11"
);

sub tracker_print ($) {
	
	if (!$autoget || $verbose) {
		print @_;
	}
}

sub verbose_print ($) {
	if ($verbose) {
		print @_;
	}
}


sub name_expand ($$) {

	my ($name,$replace) = @_;

        $name =~ s/([a-z])([A-Z])/$1${replace}$2/g;
        $name =~ s/([a-zA-Z])([0-9])/$1${replace}$2/g;
        $name =~ s/([0-9])([a-zA-Z])/$1${replace}$2/g;
        $name =~ s/([A-Z])([A-Z])/$1${replace}$2/g;

	return $name;
}

sub disk_eplist ($) {
	my ($dirname) = @_;
	my $sdh;
	my $episode;
	my $sp,$ep;
	my %episodelist;
	
	if (opendir($sdh,$dirname) ) {
		while($episode=readdir $sdh) {
			if (!($episode =~ /^\./)) {
				&verbose_print("$dirname / $episode\n");
				if ( -d "$dirname/$episode") {
					my %episodesub = &disk_eplist("$dirname/$episode");
					my %episodenew = (%episodesub, %episodelist);
					%episodelist = %episodenew;
				} else {
					($se,$ep) = $episode =~ /[Ss](\d+)[Ee](\d\d)/;
					$se =~ s/^0+//; $ep = sprintf "%02d", $ep;
					verbose_print( "On disk $se-$ep\n");
					if ($se != "" && $ep) {
						$episodelist{"$se-$ep"} = $episode;
					}
				}
				
			}
		}
	}
	return %episodelist;
}
sub eplist_epguide ($) {
	
	my ($entry) = @_;
	my $url = "http://epguides.com";
	my $episodes = get("$url/$entry/");
	
	if (defined $episodes) {
		
		my %episodelist = ();
		@lines = split /\n/, $episodes;
		foreach my $line (@lines) {
			
		#	&verbose_print( "$line\n");
			
			if ($line =~ /\<h1>/) {
				($title) = $line =~ /">([^<]*)\<\/a>/;  # " # fix up the unclosed quote that is breaking some syntax highlighting editors
				
				$title =~ s/\([^\)]*\)//g;
				$episodelist{'title'} = $title;
				verbose_print ("$title ($entry)\n"); 
			}
			
			
			($se,$ep) = $line =~ /(\d+)-(\d\d+)/;
			$se =~ s/^0+//; $ep = sprintf "%02d", $ep;
			($date) = $line =~ /(\d\d\/[A-Z][a-z][a-z]\/\d\d)/;
			($epname) = $line =~ /'>([^<]*)<\/a>/;
			
			if ($se && $ep && $date) {
				&verbose_print("$se $ep -> $date $epname\n");
				$episodelist{"$se-$ep"} = "$date $epname";
				&verbose_print ("$ep $date $epname\n");
			}
		}
		
		return %episodelist;
	}
	return ();
}
sub find_series_thetvdb ($) {
	
	my ($name) = @_;
	my $sname;
	my $lang;
	my $id;
	my $oldid;
	my $single = 1;
	my $url = "http://thetvdb.com";
	

	$name = &name_expand($name,'+');
	
	#print "$name\n";
	
	my $episodes = get("$url/?string=$name&searchseriesid=&tab=listseries&function=Search");
	
	my @lines = split /\n/, $episodes;
	
	
	foreach my $line (@lines) {
		
		chomp($line);
		
		$line =~ s/<[^>]*>/;/g;
		$line =~ s/^\s+//g;
		
		#&verbose_print("$line\n");
		#;;;Eternal Law; ;;English;;238101;;
		
		($sname,$lang,$id) = $line =~ /^;;;([^;]*);*\s*;*([^;]*);*(\d+);*$/;
		if ($sname) {
			&tracker_print( "$sname - $lang - $id\n"); 
			if ($oldid && $oldid != $id) { &tracker_print( "Multiple TVDB matches\n" ); $single = 0; }
			$oldid = $id;
		}
	}
	
	&verbose_print ("returning $oldid\n");
	return $oldid if $single;
	return 0;
	
}
sub name_to_id ($$) {
	
	my ($name,$targetdir) = @_;
	my $id;
	local $/=undef;
	
	&verbose_print( "$targetdir / $name\n");	
	
	open (ID,"$targetdir/$name/.id") || return ();
	&verbose_print( "Reading ID\n");
	$id=<ID>;
	close ID;
	
	chop($id);
	&verbose_print( "($id)\n");
	
	return $id;
}
sub eplist_thetvdb ($) {
	
	my ($id) = @_;
	
	my $url = "http://thetvdb.com";
	my $episodes = get("$url/?id=$id&tab=seasonall");
	my @lines = split /\n/, $episodes;
	my $title;
	my %episodeList=();
	
	foreach my $line (@lines) {
		
		chomp($line);
		
		if ($line =~ /\<h1>/) {
			($title) = $line =~ /\">([^<]*)\<\/a>/; #"
			$title =~ s/[^a-zA-Z10-9 ]//g;
			$episodeList{'title'} = $title;
			&verbose_print( "TVDB TITLE: $title\n");
		}
		
		$line =~ s/<[^>]*>/;/g;
		
		#&verbose_print( "$line\n");
		
		#;;;1 - 1;;;;Hairy Maclary from Donaldson's Dairy;;;;;; &nbsp;;;
		#;;;1 - 1;;;;The First Time;;;2012-01-09;;; &nbsp;;;
		
		($se,$ep,$epname,$date) = $line =~ /;*(\d+) - (\d+);*([^;]*);*(\d\d\d\d-\d\d-\d\d);*.*$/;
		# some series are missing dates
		if (!$date) {
			$date = "TBA";
			($se,$ep,$epname) = $line =~ /;*(\d+) - (\d+);*([^;]*);*.*$/;
		}
		
		
		if ($date && $se && $ep) {
			$ep = sprintf "%02d", $ep;
			#$se = sprintf "%02d", $se;
			
			$epname =~ s/[^a-zA-Z10-9]/_/g;
			$epname =~ s/__*/_/g;
			$epname =~ s/^_//;
			$epname =~ s/_$//;
			# maybe cache this in a DB.
			$episodeList{"${se}-$ep"}="$date $epname";
			&verbose_print( "s${se}e$ep-$epname\n");
		}
		
		
	}
	return %episodeList;
	
}
sub date_to_diff ($) {
	
	my ($date) = @_;
	
	my ($dd,$mm,$yy) = split(/\//,$date);
	my $time_diff;
	
	&verbose_print( "($dd) ($mm) ($yy)\n");
	if (!$yy) {
		($yy,$mm,$dd) = split(/-/,$date);
		&verbose_print( "($dd) ($mm) ($yy)\n");
		
		if ($dd) {
			$time_diff =time  - timelocal (59,59,23,$dd,$mm-1,$yy);
		} else { 
			$time_diff= NaN;
		}
	} else {
		if ($yy < 20) { $yy += 2000; } else {$yy += 1900; }
		&verbose_print( "DEBUG: $dd $mm $month{$mm} $yy\n");
		# some meatloaf has claimed an episode is out on the 31st of November...
		#not sure of another way to catch these errors.
		$dd=30 if ($dd == 31 && $month{$mm} == 10); 
		$time_diff = time - timelocal(59, 59, 23, $dd, $month{$mm}, $yy);
	}
	return $time_diff;
}	
sub get_nzb_nzbclub($$) { 
	
	my ($dlpath,$n) = @_;
	
	my $link;
	my $base;
	my $nzburl="http://www.nzbclub.com/nzbfeed.aspx?ig=2&de=17&szs=16&st=1&sp=1&ns=1&q=";
	my $name = uri_escape($n);
	my $count =0;
	&verbose_print( "SEARCH: $nzburl$name\n");
	
	my $filelist = get("$nzburl$name");
	my @lines = split /(\r|\n|\r\n)/, $filelist;
	foreach $_  (@lines) {
		if (/<enclosure/) {
			($link) = $_ =~ /.*url="([^"]*)"/; # " # to help syntax highlighting editors.
			if ($link ne "http://nzbindex.nl/") {
				$base = $link;
				$base =~ s/.*\///;
					&verbose_print ("SEARCH: $nzburl$name\n");
					&verbose_print ("DOWNLOAD: $link\n");
					&verbose_print ("FILE: $dlpath/$base\n");
				
				if (! -r "$dlpath/$base" ) {
					print( "SEARCH: $nzburl$name\n");
					print( "DOWNLOADING: $link\n");
					print("https://silicontrip.net/%7emark/nzbqueue.php\n");
					&tracker_print( "\n");
					
					open FILE,">$dlpath/$base";
					print FILE  get($link);
					close FILE;
				} else {
					&verbose_print( "EXISTS: $dlpath/$base\n");
				}
					
				$count ++;
			}
		}
	}
	&verbose_print( "\n");
	return $count;
}	


use LWP::Simple;


$tvdir = "/Volumes/Drobo/TVSeries";
$dlpath = "/Volumes/Drobo/nzb/tmp";


#$contents = get("");


opendir($dh,$tvdir)  || die "cannot open directory\n";

while($entry=readdir $dh) {
	
	if (!($entry =~ /^\./)) {
		if ( -d "$tvdir/$entry") {
			if (! ( -e "$tvdir/$entry/.autoignore" && $autoget)) {
			if (! -e "$tvdir/$entry/.ignore" || $ignore) {
				
				&verbose_print ("searching for : $entry\n");
				$id = &name_to_id($entry, $tvdir);
				&verbose_print ("id on disk $id\n");
				if (!$id) {
					$id = &find_series_thetvdb($entry);
					if ($id) {
						open (ID,">$tvdir/$entry/.id"); 
						print ID "$id\n";
						close (ID);
					}
				}
				&verbose_print( "found id: $id\n");
				
				%episodelist = &eplist_thetvdb($id);
				
				$title = $episodelist{'title'}; delete ($episodelist{'title'});
				# %episodelist = &eplist_epguide($entry);
				
				if (!$title) {
					&tracker_print ("Cannot find $entry ($id)\n\n");
				} else {
					
					&tracker_print( "$entry\n");
					
					%diskepisode = &disk_eplist ("$tvdir/$entry");
					
					$complete = 1;
					if (!$autoget) {
						&verbose_print( "Auto ignore $tvdir/$entry/.autoignore\n");
						#open (DUM,">$tvdir/$entry/.autoignore"); close (DUM);
						mkdir ("$tvdir/$entry/.autoignore");
					}
					%serieslist = ();
					for $episodes (sort(keys(%episodelist))) 
					{
						if ($eseug) {
							$serieslist{$episodes} = 1;
						}
						if (!$diskepisode{$episodes}) 
						{
							$complete = 0;
							
							&verbose_print( $episodes . " - " . $episodelist{$episodes} . "\n");
							
							($date) = split(/ /,$episodelist{$episodes});
							$time_diff = &date_to_diff($date);
							if (!$autoget) {
								if ($time_diff < 7) {
									&verbose_print( "Auto unignore $tvdir/$entry/.autoignore\n");
									unlink ("$tvdir/$entry/.autoignore");
									rmdir ("$tvdir/$entry/.autoignore");
								}
							}
							if ($time_diff < $retention || $nodays) {
								$time_diff /= 86400;
								$time_diff = sprintf ("%d",$time_diff);
								if ($eseug) {
									$serieslist{$episodes}=-1;
								} else {
									&tracker_print ("DOESN'T HAVE $episodes $episodelist{$episodes} $time_diff days\n");
								}
								
								
								if ($autoget) {
									# conditional logic for an error in the schedule date for torchwood.
									# if ( $entry eq "Torchwood") {
									# print "torchwood adjust\n";
									#	$time_diff += 7;
									#} 
									
									if ($time_diff >= 0) {
										($se,$ep) = $episodes =~ /(\d+)-(\d+)/;;
										$se2 = sprintf "%02d", $se;
										$ep = sprintf "%02d", $ep;
										$searchtitle = &name_expand($title,' ');
										$n = "teevee " . $searchtitle . " s" . $se2 . "e" . $ep;
										$dl = &get_nzb_nzbclub($dlpath,$n);
										if ($dl == 0) {
											$n = "teevee " . $searchtitle ." ${se}x${ep}";
											$dl=&get_nzb_nzbclub($dlpath,$n);
										}
										if ($dl == 0) {
											$n =  $searchtitle ." s${se2}e${ep}";
											$n =~ s/20\d\d//;
											$dl=&get_nzb_nzbclub($dlpath,$n);
										}

									}
								}
							}
						}
					}

					if ($eseug) {
						if (!$complete) {
							print "$title : \n";
							# series compact

						}
					} else {
						if ($complete) { &tracker_print ("COMPLETE\n") ; } else {  &tracker_print ("INCOMPLETE\n"); }
						&tracker_print ("\n");
					}
				}
			}
			}
		}
	}
}


closedir $dh;
