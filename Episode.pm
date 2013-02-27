package Episode;

sub new
{
	my $class = shift;
	
	my $self = { 
		_seNumber => shift,
		_epNumber => shift,
		_seName => shift,
		_epName => shift
	};
	
	bless $self, $class;
    return $self;

	
}

sub seriesNumber {
	my ( $self, $seriesNumber ) = @_;
    $self->{_seNumber} = $seriesNumber if defined($seriesNumber);
	
	$seNumber = sprintf("%02d",$self->{_seNumber});
	
    return $seNumber;
}

sub episodeNumber {
	my ( $self, $episodeNumber ) = @_;
    $self->{_epNumber} = $episodeNumber if defined($episodeNumber);
	$epNumber = sprintf("%02d",$self->{_epNumber});
	
    return $epNumber;
}

sub seNumber {

	my ( $self ) = @_;
    return "s" . $self->seriesNumber() . "e" . $self->episodeNumber()
}

sub seriesName {
	my ( $self, $seriesName ) = @_;
    $self->{_seName} = $seriesName if defined($seriesName);
    return $self->{_seName};
}

sub episodeName {
	my ( $self, $episodeName ) = @_;
    $self->{_epName} = $episodeName if defined($episodeName);
    return $self->{_epName};
}
1;