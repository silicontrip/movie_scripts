#!/usr/bin/php
<?php
include("EpisodeFactory.php");

$nzbdir = "/Volumes/Drobo/nzb/tmp";
$queuedir = "/Volumes/Drobo/nzb/queue";

$epfac = new EpisodeFactory("/Volumes/Drobo/TVSeries");

if ($dir = @opendir("$nzbdir")) {
        while (($file = readdir($dir)) !== false) {
		if (substr($file, -4) === ".nzb") {
			$fdate = stat("$nzbdir/$file");
			$mtime = $fdate[9];
			$filelist["$mtime"] = $file;
		}
	}
	foreach  ($filelist as $key => $value) { 
		$episode = $epfac->Episode($value);
		if ($episode->getSeriesName()) {
			print "" . $episode->getSeriesName() . "-" . $episode->getSENumber() . ": ";
			$seriesDir = "/Volumes/Drobo/TVSeries/".$episode->getSeriesName()."/S" . $episode->getSeriesNumber() ."/";
			$epMatch =  $episode->getSeriesName() . "-" . $episode->getSENumber() ;
			if ($sdh = @opendir($seriesDir)) {
			while (($episodeFile = readdir($sdh)) !== false) {
				if(substr($episodeFile,0,1) != '.') 
				{
					$thisEpisode = $epfac -> episode($episodeFile);

					if ($episode->getSENumber() == $thisEpisode->getSENumber())
					{
						print "\nrm $value";
						unlink ($nzbdir . "/" . $value);
					}
				}
			}
			closedir($sdh);
			}
		}

		print "\n";
	}
	
}	
?>
