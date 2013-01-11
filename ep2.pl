#!/usr/bin/perl

use EpisodeFactory;
use AVMeta;


$epfac = new EpisodeFactory('/Volumes/Drobo/TVSeries');


while ($filename = shift) {

	
	$episode = $epfac->episode($filename);
	
	print "$filename\n"; 
	#print "series: " . $episode->seriesNumber() . "\n";
	#print "episode: " . $episode->episodeNumber() . "\n";
	#print "Series Name: " . $episode->seriesName() . "\n";
	
	$meta = new AVMeta($filename);
	
	#	print $meta->getVideoString() . "\n";	
	#print $meta->getAudioString() . "\n";
	
	print $episode->seriesName() . "-" . "s" . $episode->seriesNumber() . "e" . $episode->episodeNumber() . "." . $meta->getVideoString() . "." . $meta->getAudioString() . "\n";
	
}