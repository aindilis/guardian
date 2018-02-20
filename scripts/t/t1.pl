#!/usr/bin/perl -w

use KBS2::Util;
use PerlLib::SwissArmyKnife;
use UniLang::Util::TempAgent;

my $tempagent = UniLang::Util::TempAgent->new();

my $res1 = $tempagent->MyAgent->QueryAgent
  (
   Receiver => 'Agent1',
   Data => {
	    # Eval => [['_prolog_list',Var('?X'),['completed',Var('?X')]]],
	    Eval => [['_prolog_list',['_prolog_list',Var('?Constant'),Var('?Description'),Var('?Days')],['upcomingEvent',Var('?Constant'),Var('?Description'),Var('?Days')]]],
	   },
  );
print Dumper($res1);
