#!/usr/bin/perl

use EpisodeFactory;
use EpisodeListFactory;
use AVMeta;


$epfac = new EpisodeFactory('/Volumes/Drobo/TVSeries');
$eplfac = new EpisodeListFactory('/Volumes/Drobo/TVSeries');

while ($filename = shift) {

	
	$episode = $epfac->episode($filename);
	$eplfac->initWithName($episode->seriesName());
	$meta = new AVMeta($filename);

	
	print "$filename\n"; 
	#print "series: " . $episode->seriesNumber() . "\n";
	#print "episode: " . $episode->episodeNumber() . "\n";
	#print "Series Name: " . $episode->seriesName() . "\n";
	
	
	#	print $meta->getVideoString() . "\n";	
	#print $meta->getAudioString() . "\n";
	
	
	print $episode->seriesName() . "-" . "s" . $episode->seriesNumber() . "e" . $episode->episodeNumber() . "." . $eplfac->getName($episode->seriesName(),$episode->seriesNumber(),$episode->episodeNumber()) . "." . $meta->getVideoString() . "." . $meta->getAudioString() . "\n";

	#$eplfac->initWithName($episode->seriesName());

	#print $eplfac->getName($episode->seriesName(),$episode->seriesNumber(),$episode->episodeNumber()) . "\n";
	
	
}