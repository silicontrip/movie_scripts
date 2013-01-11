package EpisodeFactory;

use Episode;

sub new 
{
	my $class = shift;
	my $self = { _targetDir => shift,
				 _epRegex => undef
		};

	my $sdh;
	my $episode;
	my %epregexlist;
	
	if (opendir($sdh,$self->{_targetDir}) ) {
		while($episode=readdir $sdh) {
			if (!($episode =~ /^\./)) {
				$target = $self->{_targetDir} . "/" . $episode;
				#print "$target\n";

				if ( -d $target) {
					#print "$episode\n";
					
					$epregex = $episode;
					$epregex =~ s/([a-z])([A-Z])/$1\\W*$2/g;
					$epregex =~ s/([a-zA-Z])([0-9])/$1\\W*$2/g;
					$epregex =~ s/([0-9])([a-zA-Z])/$1\\W*$2/g;
					$epregex =~ s/([A-Z])([A-Z])/$1\\W*$2/g;
					$epregex =~ s/_/\\W*/g;
					
					$epregexlist{$episode} = $epregex;
					
				}
			}
		}
	}
	
	$self->{_epRegex} = \%epregexlist;
	
	bless $self, $class;
    return $self;

}

sub seriesNumber {

	my ( $self, $n ) = @_;
	$n =~ s/.*\///;
	
	$season ="";
	$episode ="";
	
	if ($n =~ /[^\d](\d)(\d\d)[^\d]/)
	{ $season = $1; $episode = $2; }
	if ($n =~ /(\d?\d)[xe](\d\d?)/i) 
	{ $season = $1; $episode = $2; }
	if ($n =~ /S(\d?\d)[^\d]*E(\d\d?)/i)
	{ $season = $1; $episode = $2; }
	if ($n =~ /[^\d](\d?\d)[^\d](\d\d)[^\d]/i)
	{ $season = $1; $episode = $2; }
	if ($n =~ /S(\d?\d)E(\d\d)/i)
	{ $season = $1; $episode = $2; }

	return $season;
	
}

sub episodeNumber {
	
	my ( $self, $n ) = @_;
	$n =~ s/.*\///;
	
	$season ="";
	$episode ="";
	
	if ($n =~ /[^\d](\d)(\d\d)[^\d]/)
	{ $season = $1; $episode = $2; }
	if ($n =~ /(\d?\d)[xe](\d\d?)/i) 
	{ $season = $1; $episode = $2; }
	if ($n =~ /S(\d?\d)[^\d]*E(\d\d?)/i)
	{ $season = $1; $episode = $2; }
	if ($n =~ /[^\d](\d?\d)[^\d](\d\d)[^\d]/i)
	{ $season = $1; $episode = $2; }
	if ($n =~ /S(\d?\d)E(\d\d)/i)
	{ $season = $1; $episode = $2; }
	
	return $episode;
	
}


sub seriesName {
	my ( $self, $filename ) = @_;
	
	my $found = "";
	my $epregex;
	
	for $series (sort (keys(%{$self->{_epRegex}}))) {
		$regex = $self->{_epRegex}{$series};

		#print "File: $filename <=> $regex\n";
		
		if ($filename =~ /$regex/i) {
			#print "MATCH: " . length($series) . " " . length($found) ."\n";
			
			if (length($series)>length($found))
			{
				# print "SET";
				$found = $series;
			}
		}
	}
	
	return $found;
	
}

sub episode {
	my ( $self, $filename ) = @_;

	my $seriesName = $self->seriesName($filename);
	my $seriesNumber = $self->seriesNumber($filename);
	my $episodeNumber = $self->episodeNumber($filename);

	# get episode name.
	
	my $episode = new Episode($seriesNumber,$episodeNumber,$seriesName,"");
	
}
	
1;