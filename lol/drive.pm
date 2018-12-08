package lol::drive;

#	assumptions:
#		1) all incoming data is valid
#		2) blocks contain 8 bits
#

sub BIT_PER_DRIVE(){'bit_per_drive'}
sub BIT_PER_DISK(){'bit_per_disk'}
sub BIT_PER_SECTOR(){'bit_per_sector'}
sub BIT_PER_BLOCK(){'bit_per_block'}

sub DISK_COUNT(){'disk_count'}
sub SECTOR_COUNT(){'sector_count'}
sub BLOCK_COUNT(){'block_count'}

sub DEBUG_FORMAT_WRITE(){" (DEBUG) write %#x [%d:%d:%d:%d] to %d\n"}
sub DEBUG_FORMAT_READ(){" (DEBUG) read %#x [%d:%d:%d:%d]\n"}


sub buy {
	my ($make, %config) = @_;

	my $drive = bless({}, $make);
	$drive->format(%config);

	return ($drive);
}

sub get {
	my ($drive, $option) = @_;

	return ($drive->{META}{$option});
}

sub set {
	my ($drive, $option, $value) = @_;
	my $old = $drive->get($option);

	$drive->{META}{$option} = $value;

	return ($old);
}

sub dereference {
	my ($drive, $raddr) = @_;
	my ($i, $j, $k, $l) = ();

	my $old = $raddr;

	$i = int($raddr / $drive->get(BIT_PER_DISK));
	$raddr %= $drive->get(BIT_PER_DISK);
	$j = int($raddr / $drive->get(BIT_PER_SECTOR));
	$raddr %= $drive->get(BIT_PER_SECTOR);
	$k = int($raddr / $drive->get(BIT_PER_BLOCK));
	$raddr %= $drive->get(BIT_PER_BLOCK);
	$l = $raddr;

	return ($i, $j, $k, $l);
}

sub construct {
	my ($drive) = @_;

	$drive->{DATA} = [];

	for (my ($i, $I) = (0, $drive->get(DISK_COUNT)); $i < $I; $i++) {
		my $eye = [];

		for (my ($j, $J) = (0, $drive->get(SECTOR_COUNT)); $j < $J; $j++) {
			my $jay = [];

			for (my ($k, $K) = (0, $drive->get(BLOCK_COUNT)); $k < $K; $k++) {
				push(@{$jay}, []);
			}

			push(@{$eye}, $jay);
		}

		push(@{$drive->{DATA}}, $eye);
	}

	$drive->set(BIT_PER_BLOCK, 8);
	$drive->set(BIT_PER_SECTOR, 8 * $drive->get(BLOCK_COUNT));
	$drive->set(BIT_PER_DISK,
		$drive->get(BIT_PER_SECTOR) * $drive->get(SECTOR_COUNT));
	$drive->set(BIT_PER_DRIVE,
		$drive->get(BIT_PER_DISK) * $drive->get(DISK_COUNT));
}

sub format {
	my ($drive, %config) = @_;

	$drive->{META} = { %config };
	$drive->construct();
}

sub write {
	my ($drive, $raddr, $bit) = @_;
	my ($i, $j, $k, $l) = $drive->dereference($raddr);

	printf(DEBUG_FORMAT_WRITE, $raddr, $i, $j, $k, $l, $bit ? 1 : 0);

	$drive->{DATA}->[$i][$j][$k][$l] = $bit ? 1 : 0;
}

sub read {
	my ($drive, $raddr) = @_;
	my ($i, $j, $k, $l) = $drive->dereference($raddr);

	printf(DEBUG_FORMAT_READ, $raddr, $i, $j, $k, $l);

	return ($drive->{DATA}->[$i][$j][$k][$l] ? 1 : 0);
}


__PACKAGE__