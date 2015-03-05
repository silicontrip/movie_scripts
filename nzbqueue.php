<?php
include("news.php");
include("EpisodeFactory.php");
function main($t) {

$nzbdir = "/Volumes/Drobo/nzb/tmp";
$queuedir = "/Volumes/Drobo/nzb/queue";

?>
<html>
<head> 
<?news::newshead($t);?>
<div id=text>
<p><a href="/~mark/nzbqueue.php">Refresh</a> <a href="https://inertia.silicontrip.net:9095/">SABnzb</a> <a href="https://silicontrip.net/~mark/nntpget.php">NNTPget</a>
</p>
<?

$value = $_POST['move'];
if (is_array($value)) {
?>
<?
print "<table>";


foreach  ($value as $key2 => $value2) { 
	$file = urldecode($value2);
	print "<tr><td>$key2</td><td> $file</td></tr>\n"; 
	copy ( "$nzbdir/$file" , "$queuedir/$file");
}
print "</table>\n";
} else { ?>
<form method=post>
<input type=submit>
<table>
<?

$epfac = new EpisodeFactory("/Volumes/Drobo/TVSeries");

if ($dir = @opendir("$nzbdir")) {
        while (($file = readdir($dir)) !== false) {
		if (substr($file, -4) === ".nzb") {
			$fdate = stat("$nzbdir/$file");
			$mtime = $fdate[9];
			$filelist["$mtime"] = $file;
		}
	}
	krsort($filelist);
	foreach  ($filelist as $key => $value) { 
		$urlfile = urlencode ($value);
		$episode = $epfac->Episode($value);
		print "<tr><td><input type=checkbox name=move[] value=$urlfile></td>";
		print "<td>";
		if ($episode->getSeriesName()) {
			$seriesDir = "/Volumes/Drobo/TVSeries/".$episode->getSeriesName()."/S" . $episode->getSeriesNumber() ."/";
			$epMatch =  $episode->getSeriesName() . "-" . $episode->getSENumber() ;
			if ($sdh = @opendir($seriesDir)) {
			while (($episodeFile = readdir($sdh)) !== false) {
				if(substr($episodeFile,0,1) != '.') 
				{
					$thisEpisode = $epfac -> episode($episodeFile);
					print $thisEpisode->getSENumber() . " ";
				}
			}
			closedir($sdh);
			}
		}
		print "</td>";
		print "<td>$value</td></tr>\n";
	}
	
	
}	
?>
</table>
<input type=submit>
</form>
<? } ?>
</div>
</body>
</html>
<?
}

news::auth("NZB Queue");
