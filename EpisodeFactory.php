<?php

    include ("Episode.php");
    
    class EpisodeFactory {
        private $episodeRegex = array();
        
        public function __construct ($targetDir)
        {
            
            
            if ($sdh = @opendir("$targetDir"))
            {
                
                while(($episode=readdir($sdh)) !== false) {

                    if (substr($episode,0,1) !== '.') {
                        $target = $targetDir . "/" . $episode;

                        if ( is_dir($target)){
                            $epregex = $episode;
                            $epregex = preg_replace ("/([a-z])([A-Z])/","$1\\W*$2",$epregex);
                            $epregex = preg_replace ("/([a-zA-Z])([0-9])/","$1\\W*$2",$epregex);
                            $epregex = preg_replace ("/([0-9])([a-zA-Z])/","$1\\W*$2",$epregex);
                            $epregex = preg_replace ("/([A-Z])([A-Z])/","$1\\W*$2",$epregex);
                            $epregex = preg_replace ("/_/","\\W*",$epregex);

                            
                            #  print "<pre>$epregex for $episode</pre>";
                            
                            $this->episodeRegex["$episode"] = $epregex;
                        }
                    }
                }
            }
        }
        
        public function seriesEpisodeNumber($name)
        {
            $se = array();
            $match = array();

            #print ("<pre> ");
            #var_dump($name);
            #print ("</pre>");
            
            if (preg_match("/[^\d](\d)(\d\d)[^\d]/",$name,&$match)) { $se = $match; }
            if (preg_match("/[^\d](\d?\d)[^\d](\d\d)[^\d]/",$name,&$match)) { $se = $match; }
            if (preg_match("/(\d?\d)[xeXE](\d\d?)/",$name,&$match)) { $se = $match; }
            if (preg_match("/[Ss](\d?\d)[^\d]*[Ee](\d\d?)/",$name,&$match)) { $se = $match; }
            if (preg_match("/[Ss](\d?\d)[Ee](\d\d)/",$name,&$match)) { $se = $match; }

            return $se;
            
        }
        
        public function seriesNumber($name)
        {
            $se = $this->seriesEpisodeNumber($name);
            return $se[1];
        }
        
        public function episodeNumber($name)
        {
            $se =  $this->seriesEpisodeNumber($name);
            return $se[2];
        }
        
        public function seriesName($name)
        {
            $found = "";
            
            foreach ($this->episodeRegex as $series => $regex) {
                
                if (preg_match("/$regex/i",$name))
                {
                    if (strlen($series) > strlen($found) )
                    {
                        $found = $series;
                    }
                }
            }
            return $found;
        }
        
        public function episode ($name)
        {
            // get rid of some common strings that can fool the parser.
            $name = preg_replace(",.*/,","",$name);
            $name = preg_replace("/_/",".",$name);
            $name = preg_replace("/720p/","",$name);
            $name = preg_replace("/x264/","",$name);

            return new Episode($this->seriesNumber($name), $this->episodeNumber($name),$this->seriesName($name),"");
        }

    }

?>