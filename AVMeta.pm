package AVMeta;

sub new
{
	
	my $class = shift;
	
	my $self = { 
		_fileName => shift,
		_meta => undef
	};

	my %avmeta;
	
	foreach (`/opt/local/bin/mplayer -benchmark -ao null -vo null -identify -frames 0 "$self->{_fileName}"`) {
		chop;
		#print "$_";
		
		if (/^ID_/) {
			my ($key,$value) = split(/=/);
			$avmeta{$key} = $value;
			#	print "$key <=> $value\n";
		}
	}
	
	$self->{_meta} = \%avmeta;

	bless $self, $class;
    return $self;
}

sub printKeys 
{
	my ($self) = @_;
	for $k (keys(%{$self->{_meta}})){
		print "$k\n";
	}
}

sub get
{
	my ( $self, $key ) = @_;
	return $self->{_meta}{$key};
}

sub getRounded
{
	my ( $self, $key ) = @_;
	return int($self->{_meta}{$key} + 0.5);
}

sub getHumanReadable
{
	my ( $self, $key ) = @_;
	$human = $self->{_meta}{$key};
	$human =~ s/000/k/;
	return $human;
}


sub getCodec
{
	my ( $self, $key ) = @_;
	$codec = $self->{_meta}{$key};
	$codec =~ s/^ff//;
	return $codec;
}

sub getVideoString 
{
	my ($self) = @_;
	return  $self->getCodec('ID_VIDEO_CODEC') . "-" . $self->get('ID_VIDEO_WIDTH') . "x" . $self->get('ID_VIDEO_HEIGHT') . "x". $self->getRounded('ID_VIDEO_FPS');

}

sub getAudioString 
{
	my ($self) = @_;
	return  $self->getCodec('ID_AUDIO_CODEC') . "-" . $self->getHumanReadable('ID_AUDIO_RATE');
}



1;
