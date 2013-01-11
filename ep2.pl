#!/usr/bin/perl

use EpisodeFactory;


$epfac = new EpisodeFactory('/Volumes/Drobo/TVSeries');


while ($filename = shift) {

	
	$episode = $epfac->episode($filename);
	
	print "$filename: series: " . $episode->seriesNumber() . " episode: " . $episode->episodeNumber() . " Series Name: " . $episode->episodeName() . "\n";
	

}