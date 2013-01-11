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