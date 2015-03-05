#!/usr/bin/perl

use Getopt::Long;

use EpisodeFactory;
use EpisodeListFactory;
use AVMeta;


my $test,$seriesName,$move,$id,$seriesNumber,$episodeNumber,$cdn;

GetOptions (
	"no-rename|t" => \$test, 
	"name|n=s" => \$seriesName, 
	"move|m" => \$move, 
	"tvdb|i=s" => \$id,
	"series|s=s" => \$seriesNumber,
	"episode|e=s" => \$episodeNumber,
	"directory|d=s" => \$cdn
);  # flag

if (!$cdn) { $cdn = "/Volumes/Drobo/TVSeries"; } # should make this a config file option

my $epfac = new EpisodeFactory($cdn);
my $eplfac = new EpisodeListFactory($cdn);


while (my $filename = shift) {

	my $episode = $epfac->episode($filename);

	$episode->seriesNumber($seriesNumber);
	$episode->episodeNumber($episodeNumber);
	$episode->seriesName($seriesName);

	my $id = $eplfac->idFromName($episode->seriesName());

	if ($id) { 
		$title = $eplfac->initWithTVDBId($id);
		$episode->seriesName($title);
	}

	$episode->seriesNumber($seriesNumber);
	$episode->episodeNumber($episodeNumber);
	$episode->seriesName($seriesName);
    
	
	my $meta = new AVMeta($filename,"/Volumes/Drobo/bin/metadata-example"); # should make this a config option.
	my $newName =  $episode->seriesName() . "-" . $episode->seNumber() . "." ;
#	print "DEBUG: " . $episode->seriesName() ." - ".$episode->seriesNumber() . " - " . $episode->episodeNumber . "\n";
	my $epName = $eplfac->getName($episode->seriesName(),$episode->seriesNumber(),$episode->episodeNumber());

	if ($epName) {
		$newName .=  $epName . "." ;
	}
	$newName .= $meta->getVideoString() . "." . $meta->getAudioString() . "." . $meta->getExtension();

	my ($dir,$newPath) = ();

	if ($move) {
		# rename to $cdn 
		$dir = $cdn . "/" .  $episode->seriesName() . "/S" . $episode->seriesNumber();
	} else {
		# basename
		$dir =  $filename;
		$dir =~ s/[^\/]*$//;
	}

	$newPath = "./";
	if ($dir)  {
		$newPath = $dir . "/";
	}


	if (-d $newPath) {
		$newPath .= $newName;

		print "$filename -> ";
		print "$newPath\n"; 

		#print "test ($test)\n";

		if ($test ne 1) {
			if (! -r $newPath) {
				rename $filename , $newPath;
			} else {
				print "exists\n";
			}
		}
	} else {
		print "UNKNOWN $filename ($newPath)\n";
	}
}

