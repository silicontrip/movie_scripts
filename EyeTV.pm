package EyeTV;

use Mac::AppleEvents::Simple;
use Mac::Errors '$MacError';
use Mac::AppleEvents;  # for kAENoReply
use Time::Local;

%weekdays = (
0 => 'None',
1 => 'Mond',
2 => 'Tues',
4 => 'Wedn',
8 => 'Thur',
16 => 'Frid',
31 => 'Week',
32 => 'Satu',
64 => 'Sund',
96 => 'Wknd',
127 => 'Dail');

%weekparse = (
'None' => 0,
'Mond' => 1,
'Tues' => 2,
'Wedn' => 4,
'Thur' => 8,
'Frid' => 16,
'Week' => 31,
'Satu' => 32,
'Sund' => 64,
'Wknd' => 96,
'Dail' => 127
);


sub new 
{
	my $class = shift;
	my $self = { _uniqueID => shift,
		_type => shift
	};
	
	my $get = makeQuery($self,"Unqu");
	my $evt= build_event(qw/core getd EyTV/,$get);

	my $res =$evt->send_event(kAEWaitReply); 
	# check for error.

	return undef if ($res->{ERRNO} != 0) ;
	
	bless $self, $class;
    return $self;

}

sub EyeTVProgram() { 'cPrg'; }
sub EyeTVRecording() { 'cRec'; }

sub getList($) {
	my ($obj) = @_;

	my $evt = build_event(qw/core getd EyTV/, "'----':'obj '{form:indx,want:type(" . $obj . "),seld:abso('all '),from:null()}");
	my $res=  $evt->send_event(kAEWaitReply);
	
	return undef if ($res->{ERRNO} != 0) ;
	
	my $recordings = AEGetParamDesc($res->{REP},keyDirectObject);
	
	my @recordingList;
	
	for my $k (1..AECountItems($recordings)) {
		my $desc = AEGetNthDesc($recordings,$k);
		my $id = $Mac::AppleEvents::Simple::AE_GET{typeComp()}(AEGetParamDesc($desc,'seld'),typeLongInteger);
		
		push (@recordingList, $id);
	}
	
	return @recordingList;
}

sub getPrograms() {
	
	return getList(EyeTVProgram());
}

sub getRecordings() {
	
	return getList(EyeTVRecording());

}


sub createProgram  {
	
	my ($titl, $chnm, $stim, $dura) = @_;

	my ($year,$mon,$mday, $hour,$min,$sec) = $stim =~ /(\d\d\d\d)-(\d\d)-(\d\d) (\d+):(\d\d):(\d\d)/;
	my $time = timelocal($sec,$min,$hour,$mday,$mon-1,$year)  + 2082880800; 

	#print "Start Time: $time\n";

	my $ldt = pack ('LL',$time);



	my $q = "kocl:type(cPrg),prdt:reco{Titl:utxt(\"".$titl."\"), Chnm:long(" . $chnm . "), Stim:'ldt '(@), Dura:long(" . $dura . "), enbl:fals}";
	#my $q = "kocl:type(cPrg),prdt:reco{Titl:utxt(\"".$titl."\"), Chnm:long(" . $chnm . "),  Dura:long(" . $dura . "), enbl:fals}";
	
	# and populate with data
	
	print "Create Event: $q\n";
	
	my $evt= build_event(qw/core crel EyTV/,$q,$ldt);
	
	print AEPrint ($evt->{EVT}) . "\n";
	
	my $res =$evt->send_event(kAEWaitReply); 
	
	print AEPrint ($res->{REP}) . "\n";

	
	my $newprogram = AEGetParamDesc($res->{REP},keyDirectObject);

	return $Mac::AppleEvents::Simple::AE_GET{typeComp()}(AEGetParamDesc($newprogram,'seld'),typeLongInteger);

}


sub makeQuery($$) {
	my ($self,$prop) = @_;
	
	my $id = $self->{_uniqueID};
	my $obj = $self->{_type};

	
	my $q = "'----':'obj '{ form:enum(prop), want:type(prop), seld:type(" . $prop . "), from:'obj '{ form:enum('ID  '), want:type(" .$obj ."), seld:long(" . $id  . "), from:null() } }";
	
	return $q;
}

sub sendQuery($$) {
	my ($self,$prop) = @_;
	
	my $q = makeQuery($self,$prop);
	
	my $evt= build_event(qw/core getd EyTV/,$q);
	my $res =$evt->send_event(kAEWaitReply); 
	return undef if ($res->{ERRNO} != 0) ;
	
	$att = AEGetParamDesc($res->{REP},keyDirectObject);
	
	return $att;
	
}

sub get {
	my( $self,$prop ) = @_;
	return sendQuery($self,$prop)->get();
}

sub getText {
	my( $self,$prop ) = @_;
	return $Mac::AppleEvents::Simple::AE_GET{typeStyledText()}(sendQuery($self,$prop));
}

sub getDate {
	my( $self,$prop ) = @_;
	return $Mac::AppleEvents::Simple::AE_GET{typeLongDateTime()}(sendQuery($self,$prop));
}

sub getTitle {
    my( $self ) = @_;
	return getText($self,'Titl');
}



sub setTitle {
    my( $self,$title ) = @_;
	my $id = $self->{_uniqueID};
	my $obj = $self->{_type};
	
	$prop = 'Titl';
	
	my $q = "'----':'obj '{ form:enum(prop), want:type(prop), seld:type(" . $prop . "), from:'obj '{ form:enum('ID  '), want:type(" .$obj . "), seld:long(" . $id  . "), from:null() } }, data:utxt(\"" . $title . "\")";
	#my $q = "'----':'obj '{ form:enum(prop), want:type(prop), seld:type(@), from:'obj '{ form:enum('ID  '), want:type(@), seld:long(@), from:null() } }, data:utxt(@)";
	
	my $evt= build_event(qw/core setd EyTV/,$q);
	my $res =$evt->send_event(kAEWaitReply); 
}

sub setDuration {
	my( $self,$title ) = @_;
	my $id = $self->{_uniqueID};
	my $obj = $self->{_type};
	
	$prop = 'Dura';
	
	my $q = "'----':'obj '{ form:enum(prop), want:type(prop), seld:type(" . $prop . "), from:'obj '{ form:enum('ID  '), want:type(" .$obj . "), seld:long(" . $id  . "), from:null() } }, data:long(" . $title . ")";
	
	my $evt= build_event(qw/core setd EyTV/,$q);
	my $res =$evt->send_event(kAEWaitReply); 
}

sub setStartFromString  {
	
	my( $self,$title ) = @_;


	# keep this the same format as the output time
	my ($year,$mon,$mday, $hour,$min,$sec) = $title =~ /(\d\d\d\d)-(\d\d)-(\d\d) (\d+):(\d\d):(\d\d)/;

	
	#print "set start to: $year, $mon, $mday, $hour, $min, $sec\n";
	
	my $time = timelocal($sec,$min,$hour,$mday,$mon-1,$year);
	
	setStart($self,$time);
}

sub setStart {
	my( $self,$title ) = @_;
	my $id = $self->{_uniqueID};
	my $obj = $self->{_type};
	
	$title = $title + 2082880800;
	
	$ldt = pack ('LL',$title);
	
	$prop = 'Stim';
	
	my $q = "'----':'obj '{ form:enum(prop), want:type(prop), seld:type(" . $prop . "), from:'obj '{ form:enum('ID  '), want:type(" . $obj . "), seld:long(" . $id . "), from:null() } }, data:'ldt '(@)";
		
	my $evt= build_event(qw/core setd EyTV/,$q,$ldt);
	
	#	for $k (keys(%{$evt})) {
	#		print "$k : " . $evt->{$k} . "\n";
	#	}
	
	my $res =$evt->send_event(kAEWaitReply); 
}

sub parseRepeats($) {
	my ($rpt) = @_;
	# going for format: Mond,Tues,Wedn,Thur,Frid,Satu,Sund

	my @rpts = split(',',$rpt);
	my @packrpts =();
	
	for my $n (@rpts) {
		# probably should validate at this point
		
		if ($weekparse{$n}) {
			# how to determine this at runtime.
			# old v2.0
			#push(@packrpts,'   ' . pack('C',$weekparse{$n}));
			#new v3.0
			push(@packrpts,$n);
		}
	}
	
	# my $list = "enum:('" . join("'),enum:('",@rpts) . "')"; 
	my $list = "'" . join("','",@packrpts) . "'";
	#$list = $rpt;
	#return pack("N",$packrpts);

	return $list;
}

sub setRepeats {
	my( $self,$title ) = @_;
	my $id = $self->{_uniqueID};
	my $obj = $self->{_type};
	
	
	my $prop = 'Rpts';
	
	# might do validation here.
	my $data = parseRepeats($title);
	
	my $q = "data:list[" . $data . "], '----':'obj '{ form:enum(prop), want:type(prop), seld:type(" . $prop . "), from:'obj '{ form:enum('ID  '), want:type(" .$obj . 
	 "), seld:long(" . $id  . "), from:null() } } ";
	
	#	print "$q\n";
	
	my $evt= build_event(qw/core setd EyTV/,$q);
	my $res =$evt->send_event(kAEWaitReply); 

}

sub setChannelNumber {
	my( $self,$title ) = @_;
	my $id = $self->{_uniqueID};
	my $obj = $self->{_type};
	
	$prop = 'Chnm';
	
	my $q = "'----':'obj '{ form:enum(prop), want:type(prop), seld:type(" . $prop . "), from:'obj '{ form:enum('ID  '), want:type(" .$obj . "), seld:long(" . $id  . "), from:null() } }, data:long(" . $title . ")";
	
	my $evt= build_event(qw/core setd EyTV/,$q);
	my $res =$evt->send_event(kAEWaitReply); 
}	
	
sub setEnabled {
	my( $self ) = @_;
	$self -> setEnableFlag(1);
}

sub setDisabled {
	my( $self ) = @_;
	$self -> setEnableFlag(0);
}


sub setEnableFlag {
	my( $self,$title ) = @_;
	my $id = $self->{_uniqueID};
	my $obj = $self->{_type};
	
	$prop = 'enbl';
	
	my $q = "'----':'obj '{ form:enum(prop), want:type(prop), seld:type(" . $prop . "), from:'obj '{ form:enum('ID  '), want:type(" .$obj . "), seld:long(" . $id  . "), from:null() } }, data:bool(" . $title . ")";
	
	my $evt= build_event(qw/core setd EyTV/,$q);
	my $res =$evt->send_event(kAEWaitReply); 
}	


sub getDescription {
    my( $self ) = @_;
	return getText($self,'Pdsc');
}

sub getStart {
	my( $self ) = @_;
	
	$rep = sendQuery($self,"Stim");
		
	return getDate($self,'Stim');
}

sub secToString {
	my($epochsec) = @_;

	$hour = int($epochsec / 3600);
	$min = int(($epochsec % 3600) / 60);
	$sec = $epochsec % 60;
	
	return sprintf "%d:%02d:%02d",$hour,$min,$sec;
}

sub dateToString 
{
	my($epochsec) = @_;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($epochsec);
	$mon ++;
	$year += 1900;
	return sprintf "%04d-%02d-%02d %d:%02d:%02d",$year,$mon,$mday,$hour,$min,$sec;
}

sub getStartAsString {
	my( $self ) = @_;
	# $rep = sendQuery($self,"Stim");
	return dateToString(getDate($self,'Stim'));
}

sub getDuration {
	my( $self ) = @_;
	return get($self,'Dura');
}

sub getDurationAsString {
	my( $self ) = @_;
	return secToString(get($self,'Dura'));
}


sub getActualStart {
	my( $self ) = @_;
	return getDate($self,'Acst');
	
}

sub getActualStartAsString {
	my( $self ) = @_;
	return dateToString(getDate($self,'Acst'));
	
}

sub getActualDuration {
	my( $self ) = @_;
	return get($self,'Acdu');
}

sub getActualDurationAsString {
	my( $self ) = @_;
	return secToString(get($self,'Acdu'));
}


sub getEpisode {
    my( $self ) = @_;
	return getText($self,'Epis');
}

sub isBusy {
	my( $self ) = @_;
	return get($self,'RTsk');
}


sub getChannelNumber {
	my( $self ) = @_;
	return get($self,'Chnm');
}

sub getChannelName {
	my( $self ) = @_;
	return getText($self,'Stnm');
}

sub printRepeats {
	my ($self) = @_;
	return AEPrint(sendQuery($self,'Rpts'));
}

sub getRepeats {
	my ($self) = @_;
	$rpt =  $Mac::AppleEvents::Simple::AE_GET{typeAEList()} (sendQuery($self,'Rpts'));
	
	my @week;
	my $day = 0;
	
	my $old = 0; 
	my $new = 0; 

	
	for $t (@{$rpt}) {
		#print "$t\n";
		if (unpack("N",$t) < 128 )  {
			$old = 1;
			
			$day =  unpack("N",$t);
			push (@week,$weekdays{$day});
		} else {
			$new = 1;
			push(@week,$t);
		}
	}
	
	if ($old and $new) {
		die "Unexpected Error: old: $old. New: $new\n";
	}
	
	return @week;
	
}

sub getEnabled {
	my ($self) = @_;
	return get($self,'enbl');
}

sub isRepeating {
	my ($self) = @_;
	my $repeats = sendQuery($self,'Rpts');
	
	my $desc = AEGetNthDesc($repeats,1);
		
	return unpack("N",$desc->get());
	
}

sub matchTitle {
	my ($self,$match) = @_;
	
	return 1 unless $match;
	
	$title = getTitle($self);
	
	return $title =~ /$match/;
	
}

sub matchID {
	my ($self,$match) = @_;
	
	return 1 unless $match;
	my $id = $self->{_uniqueID};
	
	my ($fromID,$toID) = split('-',$match);
	
	$toID=$fromID unless $toID;
	
	return ($fromID <= $id) && ($toID >= $id);
}

sub export ($$$) {
	
	my( $self, $path, $type ) = @_;
	
	my $id = $self->{_uniqueID};
	
	my $q = "Esrc:'obj '{want:type(cRec), from:null(), form:enum('ID  '), seld:long(" . $id . ")}, Etgt:utxt(\"" . $path . "\"), Etyp:enum('" . $type . "'), Repl:bool(true), Opng:bool(false)"; 
	
	my $evt= build_event(qw/EyTV Expo EyTV/,$q);
	my $res =$evt->send_event(kAEWaitReply); 
	
	print AEPrint ($res->{REP}) . "\n";
}

sub remove {
	my($self) = @_;
	my $id = $self->{_uniqueID};
	my $obj = $self->{_type};
	
	# this is an are you sure moment.
	my $q = "'----':'obj '{want:type(". $obj. "), from:null(), form:enum('ID  '), seld:long(" . $id . ")}";
	
	my $evt= build_event(qw/core delo EyTV/,$q);
	my $res =$evt->send_event(kAEWaitReply); 	
	
	# print AEPrint ($res->{REP}) . "\n";
}


1;
