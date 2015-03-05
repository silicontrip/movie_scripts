<?php
include ("proxy.php");

class movie {
	
	private static $movie_url = "http://www.imdb.com/";
	private static $movie_metaexe = "/Volumes/Drobo/bin/metadata-example";

	function getIMDBData ($id) {

		$query= self::$movie_url . "title/tt" . $id; 
		$moviedata = file_get_contents($query,False,$cxContext);
		$movielines = explode("\n",$moviedata);

		$imdb_title = "";         
		foreach ($movielines as $line) {
			if (preg_match("/\<title>/",$line)) {
				preg_match("/\<title>([^<]*)\<\/title>/",$line,$matches);
				$imdb_title = $matches[1];
				$file_title = $imdb_title;
				$file_title = preg_replace("/ /","_",$file_title);
				$file_title = preg_replace("/[^a-zA-Z0-9_\&\-]/","",$file_title);
				$file_title = preg_replace("/[^a-zA-Z0-9_\&\-]/","",$file_title);
				$file_title = preg_replace("/_-_IMDb/","",$file_title);
				$file_title = preg_replace("/IMDb_-_/","",$file_title);
				$file_title = preg_replace("/^_*/","",$file_title);
				$file_title = preg_replace("/_*$/","",$file_title);

				preg_match("/.*([12][0-9][0-9][0-9])$/",$file_title,$years);
				$file_year = $years[1];
			}

			if (preg_match("/\/genre\//",$line)) {
				preg_match("/href=\"\/genre\/([^\?]*)?/",$line,$matches);
				$imdb_genre = $matches[1];
				$movie_genres[$imdb_genre] = 1;
					#print "<!--";                 
					#print_r ($matches);                 
					#print"-->";
			}
		}

		$genres = array_keys($movie_genres);

		return array('rawtitle' => $imdb_title,     
			'filetitle' => $file_title,     
			'year' => $file_year,     
			'genres' => $genres    
			);
	}

	function searchIMDB ($value) {


		$query = self::$movie_url . "find?q=" . urlencode($value) . "&s=title"; 

		$moviedata = file_get_contents( $query, False, $cxContext); 
		$lines = explode("<a",$moviedata);

		$res = array();

		foreach ($lines as $lineout) { 
			$lineout = "<a" . $lineout; 
			$thisline =explode ("\n",$lineout);

			foreach ($thisline as $line) {             
				if (preg_match("/\<a href=\"\/title\/tt/",$line)) {

					$id = preg_match("/\<a href=\"\/title\/tt(\d*)/",$line,$matches);                 
					$line = preg_replace("/<[^>]*>/",";",$line);                 
					$imdbdata = explode (";",$line);
#print "<!--"; print_r($imdbdata) ; print "-->";
					if ($imdbdata[1]) {

						$item = array();
						$item['name'] =$imdbdata[1];
						$item['year'] = $imdbdata[2];
						$item['id'] =   $matches[1];
						array_push($res,$item);
					}   
				}   
			} 
		}
		return $res;
	}  

	function getRounded ($num) { return floor($num + 0.5); }
	function getHumanReadable ($num) { return preg_replace ('/000/','k',$num);}

	function formatVideoString ($meta) {     
		return $meta['STREAM_VIDEO_CODEC_ID'] . 
		"-" . $meta['STREAM_VIDEO_WIDTH'] . 
		"x" . $meta['STREAM_VIDEO_HEIGHT'] . 
		"x". self::getRounded($meta['STREAM_VIDEO_FPS']); 
	}

	function formatAudioString ($meta) {
		return $meta['STREAM_AUDIO_CODEC_ID'] . 
		"-" . self::getHumanReadable($meta['STREAM_AUDIO_SAMPLERATE']); 
	}

	function getMeta ($file) {

		$escape = escapeshellarg($file);

		$metadata = array();
		exec(self::$movie_metaexe . " " . $escape, $meta);
		foreach($meta as $entry) {
			$sides = explode('=',$entry);
			$key = $sides[0];
			$metadata[$key] = $sides[1];
		}     
		return $metadata;
	}

}


