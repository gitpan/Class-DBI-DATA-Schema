package Class::DBI::DATA::Schema;

=head1 NAME

Class::DBI::DATA::Schema - Execute Class::DBI SQL from DATA sections

=head1 SYNOPSIS

  package Film.pm;
  use base 'Class::DBI';
	  # ... normal Class::DBI setup

  use 'Class::DBI::DATA::Schema';

  Film->run_data_sql;


	__DATA__
	CREATE TABLE IF NOT EXISTS film (....);
	REPLACE INTO film VALUES (...);
	REPLACE INTO film VALUES (...);

=head1 DESCRIPTION

This is an extension to Class::DBI which injects a method into your class
to find and execute all SQL statements in the DATA section of the package.

=cut

use strict;
use warnings;
use base 'Exporter';

our $VERSION = '0.01';
our @EXPORT  = qw/run_data_sql/;

=head1 METHODS

=head2 run_data_sql

  Film->run_data_sql;

Using this module will export a run_data_sql method into your class.
This method will find SQL statements in the DATA section of the class
it is called from, and execute them against the database that that class
is set up to use.

It is safe to import this method into a Class::DBI subclass being used
as the superclass for a range of classes.

WARNING: this does not do anything fancy to work out what is SQL. It
merely assumes that everything in the DATA section is SQL, and
applies each thing it finds (separated by semi-colons) in turn to your
database. Similarly there is no security checking, or validation of the
DATA in any way.

=cut

{
	my %cache;

	my $statements = sub {
		my $h = shift;
		local $/ = ";";
		chomp(my @sql = <$h>);
		return grep /\S/, @sql;
	};

	sub run_data_sql {
		my $class = shift;
		no strict 'refs';
		$cache{$class} ||= [ $statements->(*{"$class\::DATA"}{IO}) ];
		$class->db_Main->do($_) foreach @{$cache{$class}};
		return 1;
	}

}

=head1 COPYRIGHT

Copyright (C) 2003 Kasei. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Tony Bowden, E<lt>kasei@tmtm.comE<gt>.

=head1 SEE ALSO

L<Class::DBI>. 

=cut

1;
