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

$epfac = new EpisodeFactory($cdn);
$eplfac = new EpisodeListFactory($cdn);


while ($filename = shift) {

#	print "Initialising Episode data\n";
	$episode = $epfac->episode($filename);

	$episode->seriesNumber($seriesNumber);
	$episode->episodeNumber($episodeNumber);
	$episode->seriesName($seriesName);

#	print "Initialising Series data\n";
	if ($id) { 
		$eplfac->initWithTVDBId($id); 
	} else {
		$eplfac->initWithName($episode->seriesName());
	}	
	
#	print "Initialising AVmeta data\n";
	$meta = new AVMeta($filename,"/Volumes/Drobo/bin/metadata-example");

	#$meta->printKeys();
	
	
#	print "$filename: " . $meta->get('ID_DEMUXER') . "\n"; 
	#print "series: " . $episode->seriesNumber() . "\n";
	#print "episode: " . $episode->episodeNumber() . "\n";
	#print "Series Name: " . $episode->seriesName() . "\n";
	
	
	#	print $meta->getVideoString() . "\n";	
	#print $meta->getAudioString() . "\n";
	
	
	$newName =  $episode->seriesName() . "-" . $episode->seNumber() . "." ;

	$epName = $eplfac->getName($episode->seriesName(),$episode->seriesNumber(),$episode->episodeNumber());

		if ($epName) {
			$newName .=  $epName . "." ;
		}
		$newName .= $meta->getVideoString() . "." . $meta->getAudioString() . "." . $meta->getExtension();



	my $dir,$newPath;

	if ($move) {
		# rename to $cdn 
		$dir = $cdn . "/" .  $episode->seriesName() . "/S" . $episode->seriesNumber();
	} else {
		# basename
		$dir = $filename;
		$dir =~ s/[^\/]*$//;
	}

		if ($dir)  {
			$newPath = $dir . "/";
		}
		$newPath .= $newName;
		print "$filename -> ";
		print "$newPath\n"; 
	if (!$test) {
		rename $filename , $newPath;
	}
	
}

