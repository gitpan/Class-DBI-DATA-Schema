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

our $VERSION = '0.02';

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


sub import { 
	my ($self, %args) = @_;
	my $caller = caller();

	my $translating = 0;
	if ($args{translate}) { 
		eval "use SQL::Translator";
		die "Cannot translate with SQL::Translator" if $@;
		$translating = 1;
	}

	my $translate = sub { 
		my $sql = shift;
		if (my ($from, $to) = @{ $args{translate} || [] }) { 
			my $translator = SQL::Translator->new(no_comments => 1, trace => 0);
			# Ahem.
			local $SIG{__WARN__} = sub {};
			local *Parse::RecDescent::_error = sub ($;$) {};
			$sql = eval { $translator->translate(
				parser => $from,
				producer   => $to,
				data => \$sql,
			)} || $sql;
		}
		$sql;
	};

	my $transform = sub { 
		my $sql = shift;
		return join ";", map $translate->("$_;"), grep /\S/, split /;/, $sql;
	};

	my $get_statements = sub {
		my $h = shift;
		local $/ = undef;
		chomp(my $sql = <$h>);
		return grep /\S/, split /;/, $translating ? $transform->($sql) : $sql;
	};

	my %cache;

	no strict 'refs';
	*{"$caller\::run_data_sql"} = sub { 
		my $class = shift;
		no strict 'refs';
		$cache{$class} ||= [ $get_statements->(*{"$class\::DATA"}{IO}) ];
		$class->db_Main->do($_) foreach @{$cache{$class}};
		return 1;
	}

}

=head1 COPYRIGHT

Copyright (C) 2003-2004 Kasei. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Tony Bowden, E<lt>kasei@tmtm.comE<gt>.

=head1 SEE ALSO

L<Class::DBI>. 

=cut

1;
