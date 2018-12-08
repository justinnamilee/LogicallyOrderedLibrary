use strict;
use lol::raid5;

my $array = lol::raid5->initialize(
	drive_count => 6,

	drive => {
		disk_count => 2,
		sector_count => 4,
		block_count => 8
	}
);

my %cmd = (
	'' => sub {return},
	'limit' => sub { print "\t* limit: ", shift->get('array_size'), "\n" },
	'read' => sub { print "\t* value: ", shift->read(@_), "\n" },
	'write' => sub { shift->write(@_) },
	'ddw' => sub { shift->{DATA}[shift]->write(@_) },
	'ddr' => sub { print "\t* value: ", shift->{DATA}[shift]->read(@_), "\n" },
	'hash' => sub { shift->hash(@_) },
	'ash' => sub { print "\t* ash: ", shift->ash(@_), "\n" },
	'dereference' => sub { print "\t* deref: ", join(', ', shift->dereference(@_)), "\n" },
	'reference' => sub { print "\t* ref: ", shift->reference(@_), "\n" }
);

my $cmd = ''; # first command to run
my @cmd = (); # first command data

while ($cmd ne 'quit') {
	if (exists($cmd{$cmd})) {
		$cmd{$cmd}->($array, @cmd);
	}

	print ' > '; chomp($cmd = <STDIN>);
	$cmd =~ s/\s+/ /g; @cmd = ();
	@cmd = split(' ', $cmd);
	$cmd = splice(@cmd,0,1);
}