use strict;
use warnings;
use Test::More tests => 2;
use ExtUtils::testlib;
BEGIN { use_ok('credsman')};

note("Open Credentian GUI");
pass(credsman::GuiCredentials( 'credsman','This is a test only, Close This Window','Credsman Example', 0 ));
done_testing;