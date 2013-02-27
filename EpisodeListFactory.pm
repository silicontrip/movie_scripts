package EpisodeListFactory;
use LWP::Simple;
use Data::Dumper;

sub new
{
	
	my $class = shift;

	my $self = { 
		_targetDir => shift,
		_db => undef
	};
	

	$self->{_db} = {};

	
	bless $self, $class;
	return $self;

}	

sub initWithTVDBId
{
	my ( $self, $id ) = @_;

	# check series isn't populated
	
	
#	if (!defined($self->{_db}->{$name})) {

		my $episodeList = {};

		
		# check for local list
		# determine id
		
		my $id;
		my $targetdir = $self->{_targetDir};
		local $/=undef;
	
		if ($id) {
			
			my $url = "http://thetvdb.com";
			my $episodes = get("$url/?id=$id&tab=seasonall");
			my @lines = split /\n/, $episodes;
			my $title;
			
			foreach my $line (@lines) {
				
				chomp($line);
				
				if ($line =~ /\<h1>/) {
					($title) = $line =~ /\">([^<]*)\<\/a>/; #"
					$title =~ s/[^a-zA-Z10-9]//g;
					# $episodeList{'title'} = $title;
					#print "TITLE: $title\n";
				}
				
				$line =~ s/<[^>]*>/;/g;
				
				#print "$line\n";
				
				#;;;1 - 1;;;;Hairy Maclary from Donaldson's Dairy;;;;;; &nbsp;;;
				#;;;1 - 1;;;;The First Time;;;2012-01-09;;; &nbsp;;;
				
				($se,$ep,$epname,$date) = $line =~ /;*(\d+) [-x] (\d+);*([^;]*);*(\d\d\d\d-\d\d-\d\d);*.*$/;
				# some series are missing dates
				if (!$date) {
					$date = "TBA";
					($se,$ep,$epname) = $line =~ /;*(\d+) - (\d+);*([^;]*);*.*$/;
				}
				
				
				#$ep = sprintf "%02d", $ep;
				#$se = sprintf "%02d", $se;
				
				if ($date) {
					$epname =~ s/\'//g;
					$epname =~ s/[^a-zA-Z10-9]/_/g;
					$epname =~ s/__*/_/g;
					$epname =~ s/^_//;
					$epname =~ s/_$//;
					# maybe cache this in a DB.
					$se = $se + 0;
					$ep = $ep + 0;
					if ($se && $ep) {
						$episodeList->{"${se};${ep}"}=$epname;
						#print "s${se}e$ep-$epname\n";
					}
				}
				
			}
			
		}
		
		$self->{_db}->{$name} = $episodeList;
		
#	}
	

}


sub initWithName
{
	my ( $self, $name ) = @_;

	# check series isn't populated
	
	
	if (!defined($self->{_db}->{$name})) {

		my $episodeList = {};
		
		# check for local list
		# determine id
		
		my $id;
		my $targetdir = $self->{_targetDir};
		local $/=undef;
		if ( -r "$targetdir/$name/.id") 
		{
			open (ID,"$targetdir/$name/.id") ;
			#print "Reading ID\n";
			$id=<ID>;
			close ID;
		
			chop($id);
		} else {
		
			my $sname;
			my $lang;
			my $oldid;
			my $single = 1;
			my $url = "http://thetvdb.com";
			
			$name =~ s/([a-z])([A-Z])/$1+$2/g;
			$name =~ s/([a-zA-Z])([0-9])/$1+$2/g;
			$name =~ s/([0-9])([a-zA-Z])/$1+$2/g;
			$name =~ s/([A-Z])([A-Z])/$1+$2/g;
			
			#print "Name to ID: $name\n";
			
			my $episodes = get("$url/?string=$name&searchseriesid=&tab=listseries&function=Search");
			
			my @lines = split /\n/, $episodes;
			
			
			foreach my $line (@lines) {
				
				chomp($line);
				
				$line =~ s/<[^>]*>/;/g;
				$line =~ s/^\s+//g;
				
				#print "$line\n";
				#;;;Eternal Law; ;;English;;238101;;
				
				($sname,$lang,$id) = $line =~ /^;;;([^;]*);*\s*;*([^;]*);*(\d+);*$/;
				if ($sname) {
					# print "$sname - $lang - $id\n";
					if ($oldid && $oldid != $id) { $single = 0; }
					$oldid = $id;
				}
			}
			
			$id = 0;
			$id = $oldid if $single;
			
		}
		if ($id) {
			$self->initWithTVDBId($id);
		}	
	}
	

}

sub getName {
	my ( $self, $name,$seriesnumber,$episodenumber ) = @_;

	my $se = $seriesnumber + 0;
	my $ep = $episodenumber + 0;
		
	return $self->{_db}->{$name}->{"${se};${ep}"};
	
}

1;
