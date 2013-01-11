#!/usr/bin/perl

use EpisodeFactory;
use AVMeta;


$epfac = new EpisodeFactory('/Volumes/Drobo/TVSeries');


while ($filename = shift) {

	
	$episode = $epfac->episode($filename);
	
	print "$filename: series: " . $episode->seriesNumber() . " episode: " . $episode->episodeNumber() . " Series Name: " . $episode->seriesName() . "\n";
	
	$meta = new AVMeta($filename);
	
	print $meta->getVideoString() . "\n";	
	print $meta->getAudioString() . "\n";
	
}