#!/usr/bin/perl

# I should find a good home for these
use lib "/Users/mark/Movies/bin";

use EyeTV;

use Cwd;
use Getopt::Long;

$result = GetOptions ("export|e" => \$action_export,
"delete|d"   => \$action_remove,
"id|i=s" => \$match_id,
"title|t=s" => \$match_title,
"new|n" => \$action_create,
"start|s=s" => \$set_start,
"settitle|u=s" => \$set_title,
"length|l=s" => \$set_duration,
"repeats|p=s" => \$set_repeats,
"channel|C=s" => \$set_channel,
"enable|E" => \$set_enabled,
"disable|D" => \$set_disabled,
"help|h" => \$get_help,
"yes|y" => \$i_am_sure
);

if ($get_help) {
print "Eye TV Tool.  A command line interface for controlling the Eye TV PVR software.\n";
print "Usage etvtool.pl [OPTION]\n\n";
print "Actions:\n";
print "--export  Export selected recordings\n";
print "--delete  Delete selected recordings or programs\n";
print "--new     Create a new program\n";
print "--enable  Enable a program\n";
print "--disable Disable a program\n";
print "-h --help This help\n";
print "\nSelecting programs and recordings:\n";
print "If nothing is selected here every program and recording is selected\n";
print "-t --title <title> Select matching sub string\n";
print "-i --id <id>       Select matching id.  id can be a range eg 1234-1245\n";
print "\nSet program data:\n";
print "-s --start <YYYY-MM-DD HH:MM:SS> Set start time of a program\n";
print "-u --settitle <title>            Set the title of a program or recording\n";
print "-l --length <seconds>            Set the record duration of a program\n";
print "-p --repeats <days>              Set the repeats of the program\n";
print "             <Sund|Mond|Tues|Wedn|Thur|Frid|Satu|Week|Wknd|Dail> comma separated for multiple days\n";
print "-C --channel <channel>           Set the channel number of the program\n";

exit;
}


if ($action_create) {
	
	print "CREATE:\n";
	
	$match_id = EyeTV::createProgram($set_title,$set_channel,$set_start,$set_duration);
	
	($set_title,$set_channel,$set_start,$set_duration) = ();
	
	
}

# going to early exit for "unsafe" operations
if (((!$match_id) || (!$match_title)) && ($action_export || $action_remove || $set_start || $set_title || $set_duration || $set_repeats || $set_channel || $set_enabled || $set_disabled) && !$i_am_sure)
{
	print "No recordings or programs selected for action\n";
	print "if you're sure add -Y\n";
	exit;
}

print "### RECORDINGS ###\n\n";

my @list = EyeTV::getRecordings();

for my $id (sort(@list)) {
	
	#print "id: $id\n";
	my $rec = new EyeTV($id,EyeTV::EyeTVRecording());
	
	if($rec->matchID($match_id) && $rec->matchTitle($match_title)) {
		
		$rec->setTitle($set_title) if ($set_title);
		$rec->setDuration($set_duration) if ($set_duration);

		my $title = $rec->getTitle();
		print "$id: " . $title . ", " . 
		$rec->getActualStartAsString() .", " . 
		$rec->getActualDurationAsString() . "\n";
				
		if ($action_export) {
			my $dir = getcwd;
			my $file = $title;
			
			my $da = $rec->getStartAsString();
			
			($dt, $tm) = split(' ',$da);
			
			$dir =~ s/\//:/g;
			$file =~ s/\s+/_/g;
			$file =~ s/:/_/g;
			
			my $path= "$dir:${file}_${dt}_$id.mpg";

			print "$path\n";
			
			$rec->export($path,"MPEG");
			$| = 1;
			while ($rec->isBusy()) {
				print ".";
				sleep 1;
			}
			print "\n";
			$| = 0;
		}
		
		$rec->remove() if ($action_remove);

		
		
	} 
	
}

my @prglist = EyeTV::getPrograms();

print "\n### PROGRAMS ###\n\n";


for my $id (sort(@prglist)) {
	
	#print "$id\n";
	
	my $rec = new EyeTV($id,EyeTV::EyeTVProgram());
	
	#print "is rec\n";

	# programs also contain recordings.
	# the only way to determine a recording is if it doesn't repeat
	if ($rec && $rec->isRepeating()) {
		if($rec->matchID($match_id) && $rec->matchTitle($match_title)) {
			
			
			$rec->setTitle($set_title) if ($set_title);
			$rec->setDuration($set_duration) if ($set_duration);
			$rec->setRepeats($set_repeats) if ($set_repeats);
			#
			$rec->setChannelNumber($set_channel) if ($set_channel);
			#print "enable\n";

			$rec->setEnabled() if ($set_enabled);
			#print "disable\n";

			$rec->setDisabled() if ($set_disabled);
			#print "start ($set_start)\n";

			$rec->setStartFromString($set_start) if ($set_start);
			
			#print "\n\nid\n\n";
			
			print "$id: " . $rec->getTitle() .  ", " .
			#	$rec->getDescription() . ", " .
			$rec->getStartAsString() . ", " .
			$rec->getDurationAsString() . ", " .
			$rec->getChannelNumber() . ", " .
			$rec->getChannelName() . ", " .
			"[" . join(',',$rec->getRepeats()) . "], " .
			$rec->getEnabled() . "\n";
			
			$rec->remove() if ($action_remove);

		}
	}
	
}	
