#!/usr/bin/perl

use LWP::Simple qw($ua get);

use URI::Escape;
use Time::Local;
use Getopt::Std;
use LWP::Simple;

$tvdir = "/Volumes/Drobo/TVSeries";
$dlpath = "/Volumes/Drobo/nzb/tmp";

$ua -> timeout(30);


$nodays = 0;
$retention= 1500 * 86400 ; #days

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


sub verbose_print ($) {
        if ($verbose) {
                print @_;
        }
}


sub disk_eplist ($) {
	my ($dirname) = @_;
	my $sdh;
	my $episode;
	my $sp,$ep;
	my %episodelist;
	
	#&verbose_print("opendir: $dirname\n");
	if (opendir($sdh,$dirname) ) {
		while($episode=readdir $sdh) {
			if (! -l "$dirname/$episode") {
			if (!($episode =~ /^\./)) {
				if ( -d "$dirname/$episode") {
	#&verbose_print("episode is directory: $episode\n");
					my %episodesub = &disk_eplist("$dirname/$episode");
					my %episodenew = (%episodesub, %episodelist);
					%episodelist = %episodenew;
				} else {
					($se,$ep) = $episode =~ /[Ss](\d+)[Ee](\d\d)/;
					$se =~ s/^0+//; $ep = sprintf "%02d", $ep;
					if ($se != "" && $ep) {
						$episodelist{"$se-$ep"} = $episode;
					}
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
			
			
			if ($line =~ /\<h1>/) {
				($title) = $line =~ /">([^<]*)\<\/a>/;  # " # fix up the unclosed quote that is breaking some syntax highlighting editors
				
				$title =~ s/\([^\)]*\)//g;
				$episodelist{'title'} = $title;
			}
			
			
			($se,$ep) = $line =~ /(\d+)-(\d\d+)/;
			$se =~ s/^0+//; $ep = sprintf "%02d", $ep;
			($date) = $line =~ /(\d\d\/[A-Z][a-z][a-z]\/\d\d)/;
			($epname) = $line =~ /'>([^<]*)<\/a>/;
			
			if ($se && $ep && $date) {
				$episodelist{"$se-$ep"} = "$date $epname";
			}
		}
		
		return %episodelist;
	}
	return ();
}
sub name_to_id ($$) {
	
	my ($name,$targetdir) = @_;
	my $id;
	local $/=undef;
	
	
	open (ID,"$targetdir/$name/.id") || return ();
	$id=<ID>;
	close ID;
	
	chop($id);
	
	return $id;
}
sub eplist_thetvdb ($) {
	
	my ($id) = @_;
	
	my $url = "http://thetvdb.com";
	#&verbose_print ("GET: $url/?id=$id&tab=seasonall\n");
	my $episodes = get("$url/?id=$id&tab=seasonall");
	#&verbose_print ("SPLIT: $url/?id=$id&tab=seasonall\n");
	my @lines = split /\n/, $episodes;
	my $title;
	my %episodeList=();

	
	foreach my $line (@lines) {
		
		chomp($line);
		
		if ($line =~ /\<h1>/) {
			($title) = $line =~ /\">([^<]*)\<\/a>/; #"
			$title =~ s/[^a-zA-Z10-9 ]//g;
			$episodeList{'title'} = $title;
		}
		
		$line =~ s/<[^>]*>/;/g;
		

		
		#;;;1 - 1;;;;Hairy Maclary from Donaldson's Dairy;;;;;; &nbsp;;;
		#;;;1 - 1;;;;The First Time;;;2012-01-09;;; &nbsp;;;
		
		($se,$ep,$epname,$date) = $line =~ /;*(\d+) [-x] (\d+);*([^;]*);*(\d\d\d\d-\d\d-\d\d);*.*$/;
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
		#	&verbose_print("$se $ep $date $epname\n");
			$episodeList{"${se}-$ep"}="$date $epname";
		}
		
		
	}
	return %episodeList;
	
}
sub date_to_diff ($) {
	
	my ($date) = @_;
	
	my ($dd,$mm,$yy) = split(/\//,$date);
	my $time_diff;
	
	if (!$yy) {
		($yy,$mm,$dd) = split(/-/,$date);
		
		if ($dd) {
			$time_diff =time  - timelocal (00,00,10,$dd,$mm-1,$yy);
		} else { 
			$time_diff=-99999999;
		}
	} else {
		if ($yy < 20) { $yy += 2000; } else {$yy += 1900; }
		# some meatloaf has claimed an episode is out on the 31st of November...
		#not sure of another way to catch these errors.
		$dd=30 if ($dd == 31 && $month{$mm} == 10); 
		$time_diff = time - timelocal(59, 59, 23, $dd, $month{$mm}, $yy);
	}
	return $time_diff;
}	

$verbose=0;

opendir($dh,$tvdir)  || die "cannot open directory\n";

while($entry=readdir $dh) 
{
	#&verbose_print("$entry\n");
	if (!($entry =~ /^\./) && ! -l "$tvdir/$entry") # && $entry eq "StargateUniverse") 
	{
		if ( -d "$tvdir/$entry") 
		{
			if ( -e "$tvdir/$entry/.id" && ! -e "$tvdir/$entry/.ignore")
			{
				
				$id = &name_to_id($entry, $tvdir);

				
				%episodelist = &eplist_thetvdb($id);
				
				$title = $episodelist{'title'}; delete ($episodelist{'title'});
				
				if ($title) {
					&verbose_print ("$title\n");
					%diskepisode = &disk_eplist ("$tvdir/$entry");
					
					%serieslist = ();
					for $episodes (sort(keys(%episodelist))) 
					{
						#&verbose_print ("$episodes\n");
						if (!$diskepisode{$episodes}) 
						{
							$complete = 0;
							
							($date) = split(/ /,$episodelist{$episodes});
							$time_diff = &date_to_diff($date);
						#	$time_diff /= 86400;
							$time_diff = sprintf ("%d",$time_diff);

							if ($time_diff <= $retention) {
							$time_key = $time_diff;

							while($upcoming{$time_key}) { $time_key += 0.1; }
							$upcoming{$time_key} ="$entry $episodes $episodelist{$episodes} $time_diff";
}
							&verbose_print ("$entry $episodes $episodelist{$episodes} $time_diff\n");
								
						}
					}

				}
			}
		}
	}
}


closedir $dh;


$old=0;
for $k (sort {$a<=>$b} (keys(%upcoming))) {
	if ($old < 0 && $k >= 0) {
		print "----------------------------------------\n";
	}
	print $upcoming{$k} . "\n";
	$old=$k;
}
