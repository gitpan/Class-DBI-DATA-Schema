#!/usr/bin/perl -w

use strict;
use Test::More;

use lib 't/testlib';

BEGIN {
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 9);
}

use_ok 'Class::DBI::DATA::Schema';
can_ok 'Class::DBI::DATA::Schema' => 'run_data_sql';

use_ok 'Film';
can_ok Film => 'run_data_sql';

ok Film->run_data_sql, "set up data";

is Film->retrieve_all, 2, "We have two films automatically set up";

is Film->search(title => 'Veronique')->first->rating, 15, "Veronique";
is Film->search(title => 'The Godfather')->first->rating, 18, "Godfather";

eval { Film->run_data_sql };
like $@, qr/already exists/, "Running again causes an error";
