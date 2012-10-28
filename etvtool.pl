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
);

if ($get_help) {


exit;
}


if ($action_create) {
	
	print "CREATE:\n";
	
	$match_id = EyeTV::createProgram($set_title,$set_channel,$set_start,$set_duration);
	
	($set_title,$set_channel,$set_start,$set_duration) = ();
	
	
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
