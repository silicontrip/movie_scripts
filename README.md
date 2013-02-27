movie_scripts
=============

Scripts to transcode, organise, rename, find new episodes, series and movie video files.

epinator.pl
-----------

This is a basic Series Episode renaming script.  It gathers episode names from TheTVDB. 

  /TVSeries/SeriesName/S01/SeriesName-s01e01.EpisodeName.h264-720x576x25.aac-48k.mp4

movinator.pl
------------

This names movies and hardlinks them to their genre directory.  It gathers it's information from IMDB. It will attempt to
autofind the movie. And returns a list of IMDB IDs that potentially could match.

  /Movies/Action/ActionMovie.h264-720x288x25.ac3-48k.mp4

series_tracker.pl
-----------------

This script runs periodically (from cron) and compares the content directory with the episodes on TheTVDB.  It lists missed episodes and upcoming episodes.

etvtool.pl
----------

Depends on EyeTV.pm
This is a tool to setup/edit/delete and export programs and recordings from EyeTV.  This supports both version 2 and version 3.
But requires code changes depending on the version.

  Eye TV Tool.  A command line interface for controlling the Eye TV PVR software.
  Usage etvtool.pl [OPTION]
  
  Actions:
  --export     Export selected recordings
  --delete     Delete selected recordings or programs
  -n --new     Create a new program
  -E --enable  Enable a program
  -D --disable Disable a program
  -h --help    This help
  
  Selecting programs and recordings:
  If nothing is selected here, every program and recording is selected.
  -t --title <title> Select matching sub string
  -i --id <id>       Select matching id.  id can be a range eg 1234-1245
  -Y --yes           Allow actions on every program and recording
  -R --recordings    Select only recordings
  -P --programs      Select only programs
  
  Set program data:
  -s --start <YYYY-MM-DD HH:MM:SS> Set start time of a program
  -u --settitle <title>            Set the title of a program or recording
  -l --length <seconds>            Set the record duration of a program
  -p --repeats <days>              Set the repeats of the program
               [None|Sund|Mond|Tues|Wedn|Thur|Frid|Satu|Week|Wknd|Dail] comma separated for multiple days
  -C --channel <channel>           Set the channel number of the program

ep2.pl
------

A re-write of epinator.pl, depends on AVMeta.pm, Episode.pm, EpisodeFactory.pm, EpisodeListFactory.pm

