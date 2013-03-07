<?php

    class Episode {
    
        private $seNumber;
        private $epNumber;
        private $seName;
        private $epName;
        
        public function __construct ($seu,$epu,$sea,$epa)
        {
            $this->seNumber = $seu;
            $this->epNumber = $epu;
            $this->seName = $sea;
            $this->epName = $epa;
            
        }

        public function getSeriesNumber () { return sprintf ("%02d",$this->seNumber); }
        public function getEpisodeNumber () { return sprintf ("%02d",$this->epNumber); }
        public function getSENumber() { return "s" . $this->getSeriesNumber() . "e" . $this->getEpisodeNumber(); }
        public function getSeriesName() { return $this->seName; }
        public function getEpisodeName() { return $this->epName; }
        
    }

?>