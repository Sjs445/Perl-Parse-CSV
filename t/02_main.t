#!/usr/bin/perl

# Compile testing for Parse::CSV

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 108;
use File::Spec::Functions ':ALL';
use Parse::CSV;

my $readfile = catfile( 't', 'data', 'simple.csv' );
ok( -f $readfile, "$readfile exists" );

my $readfile2 = catfile( 't', 'data', 'newlines.csv' );
ok( -f $readfile2, "$readfile2 exists" );

my $malformed_file = catfile( 't', 'data', 'malformed.csv' );
ok( -f $malformed_file, "$malformed_file exists" );

my $header_file = catfile( 't', 'data', 'header_file.csv' );
ok( -f $header_file, "$header_file exists" );

#####################################################################
# Parsing a basic file in array ref mode

SCOPE: {
	my $csv = Parse::CSV->new(
		file => $readfile,
	);
	isa_ok( $csv, 'Parse::CSV' );
	is( $csv->row,    0,  '->row returns 0' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply( [ $csv->names ], [ ], '->names returns a null list' );

	# Pull the first line
	my $fetch1 = $csv->fetch;
	is_deeply( $fetch1, [ qw{a b c d e} ], '->fetch returns as expected' );
	is( $csv->row,    1,  '->row returns 1' );
	is( $csv->errstr, '', '->errstr returns ""' );

	my $fetch2 = $csv->fetch;
	is_deeply( $fetch2, [ qw{this is also a sample} ], '->fetch returns as expected' );
	is( $csv->row,    2,  '->row returns 2' );
	is( $csv->errstr, '', '->errstr returns ""' );

	my $fetch3 = $csv->fetch;
	is_deeply( $fetch3, [ qw{1 2 3 4.5 5} ], '->fetch returns as expected' );
	is( $csv->row,    3,  '->row returns 3' );
	is( $csv->errstr, '', '->errstr returns ""' );

	# Pull the first non-line
	my $fetch4 = $csv->fetch;
	is( $fetch4, undef, '->fetch returns undef' );
	is( $csv->row,    3,  '->row returns 3' );
	is( $csv->errstr, '', '->errstr returns "" still' );
}

SCOPE: {
	my $csv = Parse::CSV->new(
		file => $readfile2,
	);

	# Pull the first line
	my $line = $csv->fetch;
	is_deeply( $line, [ qw{a b c d e} ], '->fetch returns as expected' );
	is( $csv->row,    1,  '->row returns 1' );
	is( $csv->errstr, '', '->errstr returns ""' );

	# Pull the second line
	$line = $csv->fetch;
	is_deeply( $line, [ "this", "\nis\n", "also", "a", "sample with some\nembedded newlines\nin it" ], '->fetch returns as expected' );
	is( $csv->row,    2,  '->row returns 2' );
	is( $csv->errstr, '', '->errstr returns ""' );

	# Pull the third line
	$line = $csv->fetch;
	is_deeply( $line, [ qw{1 2 3 4.5 5} ], '->fetch returns as expected' );
	is( $csv->row,    3,  '->row returns 3' );
	is( $csv->errstr, '', '->errstr returns ""' );
}




#####################################################################
# Test fields

SCOPE: {
	my $csv = Parse::CSV->new(
		file  => $readfile,
		names => 1,
	);
	isa_ok( $csv, 'Parse::CSV' );
	is( $csv->row,    1,  '->row returns 1' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply(
		[ $csv->names ],
		[ qw{a b c d e} ],
		'->names ok',
	);
	# TODO the following is deprecated
	is_deeply(
		[$csv->fields],
		[ qw{a b c d e} ],
		'->fields() before first line and after open $csv returns as expected'
	);

	# Get the first line
	my $fetch1 = $csv->fetch;
	is( $csv->row,    2,  '->row returns 2' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply(
		$fetch1,
		{ a => 'this', b => 'is', c => 'also', d => 'a', e => 'sample' },
		'->fetch returns as expected',
	);

	# TODO the following is deprecated
	my $line = $csv->string;
	chomp($line); # $csv->string has linefeed
	is( $line,"this,is,also,a,sample",'->string() works');
	is_deeply(
		# TODO the following is deprecated
		[ $csv->fields ],
		[ qw{this is also a sample} ],
		'->fields() after first line returns as expected'
	);

	# Get the second line
	my $fetch2 = $csv->fetch;
	is( $csv->row,    3,  '->row returns 3' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply(
		$fetch2,
		{ a => 1, b => 2, c => 3, d => 4.5, e => 5 },
		'->fetch returns as expected',
	);
	is_deeply(
		[ $csv->names ],
		[ qw{a b c d e} ],
		'->colnames() (get) returns as expected',
	);
	is_deeply(
		[ $csv->names(qw{aa b c d e fext}) ],
		[ qw{aa b c d e fext} ],
		'->colnames() (set) returns as expected',
	);

	# Get the line after the end
	my $fetch3 = $csv->fetch;
	is( $fetch3, undef, '->fetch returns undef' );
	is( $csv->row,    3,  '->row returns 3' );
	is( $csv->errstr, '', '->errstr returns ""' );
}

# Ensure back-compatible with 'fields'
SCOPE: {
	my $csv = Parse::CSV->new(
		file   => $readfile,
		fields => 'auto',
	);
	isa_ok( $csv, 'Parse::CSV' );
	is( $csv->row,    1,  '->row returns 1' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply(
		# TODO the following is deprecated
		[$csv->fields],
		[ qw{a b c d e} ],
		'->fields() before first line and after open $csv returns as expected',
	);

	# Get the first line
	my $fetch1 = $csv->fetch;
	is( $csv->row,    2,  '->row returns 2' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply(
		$fetch1,
		{ a => 'this', b => 'is', c => 'also', d => 'a', e => 'sample' },
		'->fetch returns as expected',
	);

	my $line = $csv->string;
	chomp($line);  # $csv->string has linefeed
	is( $line,"this,is,also,a,sample",'->string() works');
	is_deeply(
		# TODO the following is deprecated
		[ $csv->fields ],
		[ qw{this is also a sample} ],
		'->fields() after first line returns as expected',
	);

	# Get the second line
	my $fetch2 = $csv->fetch;
	is( $csv->row,    3,  '->row returns 3' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply(
		$fetch2,
		{ a => 1, b => 2, c => 3, d => 4.5, e => 5 },
		'->fetch returns as expected',
	);
	is_deeply(
		[ $csv->names ],
		[ qw{a b c d e} ],
		'->colnames() (get) returns as expected',
	);
	is_deeply(
		[ $csv->names( qw{aa b c d e fext} ) ],
		[ qw{aa b c d e fext} ],
		'->colnames() (set) returns as expected',
	);

	# Get the line after the end
	my $fetch3 = $csv->fetch;
	is( $csv->row,    3,  '->row returns 3' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is( $fetch3, undef, '->fetch returns undef' );
}





#####################################################################
# Test filters

# Basic filter usage
SCOPE: {
	my $csv = Parse::CSV->new(
		file   => $readfile,
		fields => 'auto',
		filter => sub { bless $_, 'Foo' },
	);
	isa_ok( $csv, 'Parse::CSV' );
	is( $csv->row,    1,  '->row returns 1' );
	is( $csv->errstr, '', '->errstr returns ""' );

	# Get the first line
	my $fetch1 = $csv->fetch;
	is( $csv->row,    2,  '->row returns 2' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply(
		$fetch1,
		bless( { a => 'this', b => 'is', c => 'also', d => 'a', e => 'sample' }, 'Foo' ),
		'->fetch returns as expected',
	);

	# Get the second line
	my $fetch2 = $csv->fetch;
	is( $csv->row,    3,  '->row returns 3' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply(
		$fetch2,
		bless( { a => 1, b => 2, c => 3, d => 4.5, e => 5 }, 'Foo' ),
		'->fetch returns as expected',
	);

	# Get the line after the end
	my $fetch3 = $csv->fetch;
	is( $fetch3, undef, '->fetch returns undef' );
	is( $csv->row,    3,  '->row returns 3' );
	is( $csv->errstr, '', '->errstr returns ""' );
}

# Filtering out of records
SCOPE: {
	my $csv = Parse::CSV->new(
		file   => $readfile,
		fields => 'auto',
		filter => sub { $_->{a} =~ /\d/ ? undef : $_ },
	);
	isa_ok( $csv, 'Parse::CSV' );
	is( $csv->row,    1,  '->row returns 1' );
	is( $csv->errstr, '', '->errstr returns ""' );

	# Get the first line
	my $fetch1 = $csv->fetch;
	is( $csv->row,    2,  '->row returns 2' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply(
		$fetch1,
		bless( { a => 'this', b => 'is', c => 'also', d => 'a', e => 'sample' }, 'Foo' ),
		'->fetch returns as expected',
	);

	# Get the line after the end
	my $fetch2 = $csv->fetch;
	is( $fetch2, undef, '->fetch returns undef' );
	is( $csv->row,    3,  '->row returns 3' );
	is( $csv->errstr, '', '->errstr returns ""' );
}

#####################################################################
# Errors from Text::CSV_XS are properly propagated

SCOPE: {
	my $csv = Parse::CSV->new(
		file => $malformed_file,
	);

	my $fetch1 = $csv->fetch;
	is_deeply( $fetch1, [ qw{1 2 3} ], '->fetch returns non-malformed line' );


	my $fetch2 = $csv->fetch;
	ok !defined($fetch2), "->fetch returns 'undef' on malformed line";
	like $csv->errstr, qr/EIQ - Quoted field not terminated/, "->errstr returns proper error from Text::CSV_XS";
}

#####################################################################
# Test header
# Preserves case
SCOPE: {
	my $csv = Parse::CSV->new(
		file  => $header_file,
		names => 1,
	);
	isa_ok( $csv, 'Parse::CSV' );
	is( $csv->row,    1,  '->row returns 1' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply(
		[ $csv->names ],
		[ qw{Field1 fIeld2 FIELD3 field4} ],
		'->names ok',
	);
	# Get the first line
	my $fetch1 = $csv->fetch;
	is( $csv->row,    2,  '->row returns 2' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply(
		$fetch1,
		{ Field1 => 1, fIeld2 => 2, FIELD3 => 3, field4 => 4 },
		'->fetch returns as expected',
	);

	# Get the line after the end
	my $fetch2 = $csv->fetch;
	is( $fetch2, undef, '->fetch returns undef' );
	is( $csv->row,    2,  '->row returns 2' );
	is( $csv->errstr, '', '->errstr returns ""' );
}
# munge_column_names gets passed through
SCOPE: {
	my $csv = Parse::CSV->new(
		file  => $header_file,
		names => 1,
                munge_column_names => 'lc'
	);
	isa_ok( $csv, 'Parse::CSV' );
	is( $csv->row,    1,  '->row returns 1' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply(
		[ $csv->names ],
		[ qw{field1 field2 field3 field4} ],
		'->names ok',
	);
	# Get the first line
	my $fetch1 = $csv->fetch;
	is( $csv->row,    2,  '->row returns 2' );
	is( $csv->errstr, '', '->errstr returns ""' );
	is_deeply(
		$fetch1,
		{ field1 => 1, field2 => 2, field3 => 3, field4 => 4 },
		'->fetch returns as expected',
	);

	# Get the line after the end
	my $fetch2 = $csv->fetch;
	is( $fetch2, undef, '->fetch returns undef' );
	is( $csv->row,    2,  '->row returns 2' );
	is( $csv->errstr, '', '->errstr returns ""' );
}
