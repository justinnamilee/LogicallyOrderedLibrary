package lol::raid5;

#	assumptions:
#		1) all incoming data is valid
#

sub DEBUG_FORMAT_CONSTRUCT(){" (DEBUG) initialize drive %d of %d\n"}
sub DEBUG_FORMAT_DEREF(){" (DEBUG) %d dereference [%d:%d]\n"}
sub DEBUG_FORMAT_REF(){" (DEBUG) [%d:%d] reference %d\n"}
sub DEBUG_FORMAT_HASH(){" (DEBUG) hashing %d to %d\n"}
sub DEBUG_FORMAT_ASH(){" (DEBUG) ashing [%d:%d] from %d\n"}

use lol::drive;

sub get {
	my ($array, $option) = @_;

	return ($array->{META}{$option});
}

sub set {
	my ($array, $option, $value) = @_;
	my $old = $array->get($option);

	$array->{META}{$option} = $value;

	return ($old);
}

sub reference {
	my ($array, $drive, $addr) = @_;
	my $raddr = $addr;

	if ($raddr >= ($drive * $array->get('node_size'))) {
		$raddr -= $array->get('node_size');
	}

	$raddr += ($drive * $array->get('volume_size'));

	printf(DEBUG_FORMAT_REF, $drive, $addr, $raddr);

	return ($raddr);
}

sub dereference {
	my ($array, $raddr) = @_;

	my $drive = int($raddr / $array->get('volume_size'));
	$addr = $raddr % $array->get('volume_size');

	if ($addr >= ($drive * $array->get('node_size'))) {
		$addr += $array->get('node_size');
	}

	printf(DEBUG_FORMAT_DEREF, $raddr, $drive, $addr);

	return ($drive, $addr);
}

sub initialize {
	my ($driver, %config) = @_;

	my $array = bless({}, $driver);
	$array->format(%config);

	return ($array);
}

sub format {
	my ($array, %config) = @_;

	my $drive = delete($config{'drive'});
	$array->{META} = { %config };
	$array->construct($drive);
}

sub construct {
	my ($array, $drive) = @_;

	$array->{DATA} = [];

	for (my ($d, $l) = (0, $array->get('drive_count')); $d < $l; $d++) {
		printf(DEBUG_FORMAT_CONSTRUCT, $d + 1, $l);
		$array->{DATA}[$d] = lol::drive->buy((ref($drive) eq 'HASH') ? %{$drive} : ());
	} print "\n";

	$node = int(
		$array->{DATA}[0]->get('bit_per_drive') / $array->get('drive_count')
	);

	$array->set('node_size',
		($node - ($node % $array->{DATA}[0]->get('bit_per_block')))
	);

	$array->set('cluster_size',
		($array->get('node_size') * $array->get('drive_count'))
	);

	$array->set('volume_size',
		($array->get('cluster_size') - $array->get('node_size'))
	);

	$array->set('array_size',
		($array->get('volume_size') * $array->get('drive_count'))
	);
}

sub sum {
	my ($array, $raddr) = @_;
	my ($drive, $addr) = ($array->dereference($raddr));
	my ($chksum, $volume) = (0, int($addr / $array->get('node_size')));

	for (my ($d, $l) = (0, $array->get('drive_count')); $d < $l; $d++) {
		if ($d == $volume) {
			next;
		}

		$chksum ^= $array->{DATA}[$d]->read($addr);
	}

	return ($chksum);
}

sub hash {
	my ($array, $raddr) = @_;
	my ($drive, $addr) = ($array->dereference($raddr));
	my ($chksum, $volume) =
		($array->sum($raddr), int($addr / $array->get('node_size')));

	printf(DEBUG_FORMAT_HASH, $addr, $volume);

	$array->{DATA}[$volume]->write($addr, $chksum);
}

sub ash {
	my ($array, $raddr) = @_;
	my ($drive, $addr) = ($array->dereference($raddr));
	my $volume = int($addr / $array->get('node_size'));

	if ($volume == $drive) {
		print " (WARNING) you are playing with fire\n";
		return (undef);
	}

	printf(DEBUG_FORMAT_ASH, $drive, $addr, $volume);

	$array->{DATA}[$drive]->write($addr, 0); # zero for recovery
	$array->{DATA}[$drive]->write($addr, # compute and store recovered value
		(($array->{DATA}[$volume]->read($addr)) ^ ($array->sum($raddr))));
}

sub rebuild {
	my ($array, $drive) = @_;

}

sub write {
	my ($array, $raddr, $bit, $nohash) = @_;
	my ($volume, $addr) = $array->dereference($raddr);

	$array->{DATA}[$volume]->write($addr, $bit);

	unless ($nohash) {
		$array->hash($raddr);
	}
}

sub read {
	my ($array, $raddr) = @_;
	my ($volume, $addr) = $array->dereference($raddr);

	return ($array->{DATA}[$volume]->read($addr));
}



__PACKAGE__
