#!/usr/bin/perl -w
use Test::More;
use strict;

BEGIN {
	$|++;
	plan tests => 2;
	use_ok('Mac::Glue');
}

use Mac::Glue 1.10;
use Mac::Glue ':all';

ok(1, "Just use'ing is a significant test :-)");
