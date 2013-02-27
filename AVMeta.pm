package AVMeta;

sub new
{
	
	my $class = shift;
	
	my $self = { 
		_fileName => shift,
		_meta => undef,
		_metaExe => shift
	};

	my %avmeta;
	
	# New metadata gatherer.
#major_brand=isom
#minor_version=1
#compatible_brands=isomavc1
#creation_time=2012-11-17 05:16:47
#FORMAT_NAME=mp4
#STREAMS=2
#STREAM_0_TYPE=VIDEO
#STREAM_VIDEO_CODEC_ID=H264
#STREAM_VIDEO_AFPS_RATIO=25:1
#STREAM_VIDEO_FPS_RATIO=25:1
#STREAM_VIDEO_FPS=25.000000
#STREAM_VIDEO_WIDTH=720
#STREAM_VIDEO_HEIGHT=404
#STREAM_VIDEO_PIX_FMT=yuv420p
#STREAM_VIDEO_SAR=0:1
#STREAM_VIDEO_REFFRAMES=5
#STREAM_VIDEO_COLORSPACE=bt709
#STREAM_VIDEO_COLORRANGE=mpeg
#STREAM_VIDEO_FIELDORDER=UNKNOWN
#STREAM_VIDEO_creation_time=2012-11-17 05:16:47
#STREAM_VIDEO_language=und
#STREAM_VIDEO_handler_name=Video
#STREAM_1_TYPE=AUDIO
#STREAM_AUDIO_CODEC_ID=AAC
#STREAM_AUDIO_SAMPLERATE=48000
#STREAM_AUDIO_CHANNELS=2
#STREAM_AUDIO_SAMPLEFORMAT=fltp
#STREAM_AUDIO_creation_time=2012-11-17 05:17:38
#STREAM_AUDIO_language=eng
#STREAM_AUDIO_handler_name=GPAC ISO Audio Handler

# need to make this program location settable.
	foreach (`$self->{_metaExe} "$self->{_fileName}"`) {
		chop;
		#print "$_";
		
			my ($key,$value) = split(/=/);
			$avmeta{$key} = $value;
			#	print "$key <=> $value\n";
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
#	$codec =~ s/^ff//;
	return $codec;
}

sub getVideoString 
{
	my ($self) = @_;
	return  $self->getCodec('STREAM_VIDEO_CODEC_ID') . "-" . $self->get('STREAM_VIDEO_WIDTH') . "x" . $self->get('STREAM_VIDEO_HEIGHT') . "x". $self->getRounded('STREAM_VIDEO_FPS');

}

sub getAudioString 
{
	my ($self) = @_;
	return  $self->getCodec('STREAM_AUDIO_CODEC_ID') . "-" . $self->getHumanReadable('STREAM_AUDIO_SAMPLERATE');
}

sub getExtension
{
	my ($self) = @_;
	return $self->get('FORMAT_NAME');
}

sub metaExe {
	my ( $self, $exe ) = @_;
    $self->{_metaExe} = $exe if defined($exe);
	
    return $self->{_metaExe};
}


1;
