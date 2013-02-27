#!/usr/bin/perl

use EpisodeFactory;
use EpisodeListFactory;
use AVMeta;


$result = GetOptions ("no-rename|t" => \$test, 
	"name|N=s" => \$name, 
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

	print "Initialising Episode data\n";
	$episode = $epfac->episode($filename);

	$episode->seriesNumber($seriesNumber);
	$episode->episodeNumber($episodeNumber);

	print "Initialising Series data\n";
	$eplfac->initWithName($episode->seriesName());
	print "Initialising AVmeta data\n";
	$meta = new AVMeta($filename);

	#$meta->printKeys();
	
	
	print "$filename: " . $meta->get('ID_DEMUXER') . "\n"; 
	#print "series: " . $episode->seriesNumber() . "\n";
	#print "episode: " . $episode->episodeNumber() . "\n";
	#print "Series Name: " . $episode->seriesName() . "\n";
	
	
	#	print $meta->getVideoString() . "\n";	
	#print $meta->getAudioString() . "\n";
	
	
	print $episode->seriesName() . "-" . "s" . $episode->seriesNumber() . "e" . $episode->episodeNumber() . "." . $eplfac->getName($episode->seriesName(),$episode->seriesNumber(),$episode->episodeNumber()) . "." . $meta->getVideoString() . "." . $meta->getAudioString() . "\n";

	#$eplfac->initWithName($episode->seriesName());

	#print $eplfac->getName($episode->seriesName(),$episode->seriesNumber(),$episode->episodeNumber()) . "\n";
	
	
}

