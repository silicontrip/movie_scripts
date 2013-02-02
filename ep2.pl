#!/usr/bin/perl

use EpisodeFactory;
use EpisodeListFactory;
use AVMeta;


$epfac = new EpisodeFactory('/Volumes/Drobo/TVSeries');
$eplfac = new EpisodeListFactory('/Volumes/Drobo/TVSeries');

while ($filename = shift) {

	print "Initialising Episode data\n";
	$episode = $epfac->episode($filename);
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

