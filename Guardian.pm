package Guardian;

use BOSS::Config;
use KBS2::ImportExport;
use KBS2::Util;
use MyFRDCSA;
use PerlLib::SwissArmyKnife;

use Moose;

has 'MyImportExport' =>
  (
   is => 'rw',
   isa => 'KBS2::ImportExport',
   default => sub {
     KBS2::ImportExport->new();
   },
  );

has 'Config' =>
  (
   is => 'rw',
   isa => 'BOSS::Config',
  );

has 'UserData' => (is => 'rw', isa => 'HashRef',default => sub {{}});

sub BUILD {
  my ($self,$args) = @_;
  my %args = %$args;
  my $specification = "
	-u [<host> <port>]	Run as a UniLang agent

	-w			Require user input before exiting
";
  # $UNIVERSAL::systemdir = ConcatDir(Dir("internal codebases"),"app");
  $self->Config
    (BOSS::Config->new
     (Spec => $specification,
      ConfFile => ""));
  my $conf = $self->Config->CLIConfig;
  $UNIVERSAL::agent->DoNotDaemonize(1);
  $UNIVERSAL::systemdir = ConcatDir(Dir("minor codebases"),"guardian");
  if (exists $conf->{'-u'}) {
    $UNIVERSAL::agent->Register
      (Host => defined $conf->{-u}->{'<host>'} ?
       $conf->{-u}->{'<host>'} : "localhost",
       Port => defined $conf->{-u}->{'<port>'} ?
       $conf->{-u}->{'<port>'} : "9000");
  }
}

# Need to create the command and control loops, try to implement stuff
# from manuals here

# There should be a process running with Cyc to see if any rules
# activate for tasks.

# Read more about the cyc query interface.

sub Execute {
  my ($self,%args) = @_;
  my $conf = $self->Config->CLIConfig;
  if (exists $conf->{'-u'}) {
    # enter in to a listening loop
    while (1) {
      $UNIVERSAL::agent->Listen(TimeOut => 10);
    }
  }
  if (exists $conf->{'-w'}) {
    Message(Message => "Press any key to quit...");
    my $t = <STDIN>;
  }
}

sub ProcessMessage {
  my ($self,%args) = @_;
  my $m = $args{Message};
  my $it = $m->Contents;
  if ($it) {
    if ($it =~ /^echo\s*(.*)/) {
      $UNIVERSAL::agent->SendContents
	(Contents => $1,
	 Receiver => $m->{Sender});
    } elsif ($it =~ /^reconsult$/i) {
      $self->ReConsultFiles();
    } elsif ($it =~ /^(quit|exit)$/i) {
      $UNIVERSAL::agent->Deregister;
      exit(0);
    }
  }
  my $d = $m->Data;
  my $replydata;
  if ($d->{Command} eq 'query') {
    my $res = $self->Query(Message => $m);
    $replydata = {
		  Result => $res,
		 };
  } elsif ($d->{Command} eq 'reconfigure') {
    $self->Reconfigure(Message => $m);
  } elsif ($d->{Command} eq 'reload') {
    $self->ReConsultFiles(Message => $m);
  } elsif ($d->{Command} eq 'restart') {
    $self->Restart(Message => $m);
  } elsif ($d->{Command} eq 'list-dates') {
    my @items;
    push @items, @{$self->QueryDates};
    $replydata = {
		  Result => \@items,
		 };
  } elsif ($d->{Command} eq 'list-tasks') {
    my @items;
    push @items, @{$self->QueryTasks};
    $replydata = {
		  Result => \@items,
		 };
  # } elsif ($d->{Command} eq 'what-to-tell-agent') {
  #   my @items;
  #   push @items, @{$self->QueryWhatToTellAgent};
  #   $replydata = {
  # 		  Result => \@items,
  # 		 };
  } elsif ($d->{Command} eq 'new-task') {
    $replydata =
      {
       Result => $self->QueryNewTask
       (
	Task => $d->{Task},
	Importance => $d->{Importance},
       ),
      };
  } elsif ($d->{Command} eq 'new-contingency') {
    $replydata =
      {
       Result => $self->QueryAssert
       (
	AssertionInterlingua => ['planForContingency',$self->ConvertPrologToInterlingua(Text => $d->{Contingency})],
       ),
      };
  } elsif ($d->{Command} eq 'query-unprepared-for-contingencies') {
    my @items;
    push @items, @{$self->QueryUnpreparedForContingencies};
    $replydata = {
		  Result => \@items,
		 };
  } elsif ($d->{Command} eq 'query-all-contingencies') {
    my @items;
    push @items, @{$self->QueryAllContingencies};
    $replydata = {
		  Result => \@items,
		 };
  }
  # UniLang::Agent::Agent
  $UNIVERSAL::agent->QueryAgentReply
    (
     Message => $m,
     Contents => ($args{Contents} || ''),
     Data => ($replydata || {}),
    );
}

sub Query {
  my ($self,%args) = @_;
  print Dumper({QueryArgs => \%args});

  my @items;

  # if there are urgent items, put those for the user to see

  # if it has been a while since the user saw the short term planning
  # goals, put those to see

  # if a certain number of shell commands have been issued in bash,
  # put the short term planning goals again for the user to see.

  # looking at the commands being issued, try to determine if the user
  # is of course of his objectives, put information in that case.

  my $shell = "";
  $self->UserData->{$shell}->{Count}++;
  my $lastactedondate = $self->UserData->{$shell}->{LastActedOnDate} || 0;
  my $date = DateTimeStamp();
  $self->UserData->{$shell}->{LastSeenDate} = $date;
  $self->UserData->{$shell}->{Dates}->{$date} = 1;

  # also have it query the free life planner to obtain the current
  # plan.

  print "<$lastactedondate,$date>\n";
  # FIXME: do an actual date calculation as this is not correct (it wraps at 60)

  # FIXME: make it color coded for urgency and other things

  # push @items, @{$self->QueryDates()};

  if (($lastactedondate + 300) < $date) {
    $self->UserData->{$shell}->{LastActedOnDate} = $date;
    # push @items, @{$self->QueryTomorrow()};
    # push @items, @{$self->QueryDates()};
    # push @items, @{$self->QueryTasks()};
  } else {
    push @items,
      (

       'Get Guardian working',
       'Watch dmiles\' screenshares',
       # 'BRUSH YOUR TEETH, FLOSS AND MOUTHWASH NOW',
       # 'RECORD MEALS/VITAMIN-D',
       # 'TAKE VITAMIN-D/ANTI-TRIGLYCERIDE MEDICATION',
      );
  }

  return \@items;
}

# FIXME: DropPrologAnnotations is originally from Formalog::UniLangProxy.
# Condense copy pasted code.

sub DropPrologAnnotations {
  my ($self,%args) = @_;
  my $item = $args{Interlingua};
  my $ref = ref($item);
  print ClearDumper
    ({
      Ref => $ref,
      ArgsConversion => \%args,
     }) if $UNIVERSAL::debug;
  if ($ref eq 'ARRAY') {
    if ($item->[0] eq '_prolog_list') {
      shift @$item;
      my @newlist;
      foreach my $subitem (@$item) {
	push @newlist, $self->DropPrologAnnotations(Interlingua => $subitem);
      }
      return \@newlist;
    } else {
      my @newlist;
      foreach my $subitem (@$item) {
	push @newlist, $self->DropPrologAnnotations(Interlingua => $subitem);
      }
      return \@newlist;
    }
  } else {
    return $item;
  }
}

sub QueryTomorrow {
  my ($self,%args) = @_;
  my @items;
  my $res1 = $UNIVERSAL::agent->QueryAgent
    (
     Receiver => 'Agent1',
     Data => {
	      Eval => [['_prolog_list',['_prolog_list',Var('?Y'),Var('?M'),Var('?D')],['tomorrow',['-',['-',Var('?Y'),Var('?M')],Var('?D')]]]],
	     },
    );
  my $res2 = $self->DropPrologAnnotations(Interlingua => $res1->{Data}{Result});
  foreach my $bindings (@$res2) {
    push @items, 'tomorrow('.join("-",@$bindings).')';
  }
  return \@items;
}

sub QueryTasks {
  my ($self,%args) = @_;
  my @items;
  my $res1 = $UNIVERSAL::agent->QueryAgent
    (
     Receiver => 'Agent1',
     Data => {
	      Eval => [['_prolog_list',['task',Var('?TaskID'),Var('?Description'),Var('?Priority')],['task',Var('?TaskID'),Var('?Description'),Var('?Priority')]]],
	     },
    );
  my @list = @{$res1->{Data}{Result}};
  shift @list;
  foreach my $term (@list) {
    my $res3 = $self->MyImportExport->Convert
      (
       Input => [$term],
       InputType => 'Interlingua',
       OutputType => 'Prolog',
      );
    if ($res3->{Success}) {
      my $result = $res3->{Output};
      $result =~ s/\.$//sg;
      chomp $result;
      push @items, $result;
    } else {
      push @items, 'Error retrieving upcoming events.';
    }
  }
  return \@items;
}

sub QueryDates {
  my ($self,%args) = @_;
  my @items;
  my $res1 = $UNIVERSAL::agent->QueryAgent
    (
     Receiver => 'Agent1',
     Data => {
	      Eval => [['_prolog_list',Var('?Events'),['getEvents',Var('?Events'),'<']]],
	      # Eval => [['_prolog_list',['deadline',Var('?Constant'),Var('?Description'),Var('?Days')],['upcomingEvent',Var('?Constant'),Var('?Description'),Var('?Days')]]],
	     },
    );
  my @list = @{$res1->{Data}{Result}};
  shift @list;
  foreach my $term (@list) {
    my $res3 = $self->MyImportExport->Convert
      (
       Input => [$term],
       InputType => 'Interlingua',
       OutputType => 'Prolog',
      );
    if ($res3->{Success}) {
      my $result = $res3->{Output};
      $result =~ s/\.$//sg;
      chomp $result;
      push @items, $result;
    } else {
      push @items, 'Error retrieving upcoming events.';
    }
  }
  return \@items;
}

sub QueryNewTask {
  my ($self,%args) = @_;
  my $res1 = $UNIVERSAL::agent->QueryAgent
    (
     Receiver => 'Agent1',
     Data => {
	      Eval => [['_prolog_list',['_prolog_list',Var('?TaskID'),Var('?Result')],['newTask','Agent1','Yaswi1',$self->ConvertPrologToInterlingua(Text => $args{Task}),$args{Importance},Var('?TaskID'),Var('?Result')]]],
	     },
    );
  print Dumper({MyRes1Res1 => $res1});
  return $self->DropPrologAnnotations(Interlingua => $res1->{Data}{Result})
}

sub ConvertPrologToInterlingua {
  my ($self,%args) = @_;
  my $res0 = $self->MyImportExport->Convert
    (
     Input => $args{Text},
     InputType => 'Prolog',
     OutputType => 'Interlingua',
    );
  if ($res0->{Success}) {
    return $res0->{Output}[0];
  } else {
    # FIXME: throw error
  }
}

sub QueryAssert {
  my ($self,%args) = @_;
  my $res1 = $UNIVERSAL::agent->QueryAgent
    (
     Receiver => 'Agent1',
     Data => {
	      Eval => [['_prolog_list',Var('?Result'),['newAssertion','Agent1','Yaswi1',$args{AssertionInterlingua},Var('?Result')]]],
	     },
    );
  print Dumper({MyRes1Res1 => $res1});
  return $self->DropPrologAnnotations(Interlingua => $res1->{Data}{Result})
}

# sub QueryWhatToTellAgent {
#   my ($self,%args) = @_;
#   my @items;

#   # [['_prolog_list',['_prolog_list',Var('?Patient'),Var('?Doctor'),Var('?List')],
#   # ['ask',['oneOf',['frdcsaAgentFn',Var('Patient')]],['akahige'],Var('?Patient')]]]

#   my $res1 = $UNIVERSAL::agent->QueryAgent
#     (
#      Receiver => 'Agent1',
#      Data => {
# 	      Eval => [
# 		       [
# 			"_prolog_list",
# 			[
# 			 \*{'::?Patient'},
# 			 \*{'::?Doctor'},
# 			 \*{'::?Communication'}
# 			],
# 			[
# 			 "ask",
# 			 [
# 			  "oneOf",
# 			  [
# 			   "frdcsaAgentFn",
# 			   "akahige"
# 			  ],
# 			  \*{'::?Patient'}
# 			 ],
# 			 \*{'::?Doctor'},
# 			 \*{'::?Communication'}
# 			]
# 		       ]
# 		      ],
# 	     },
#     );
#   my $res2 = $self->DropPrologAnnotations(Interlingua => $res1->{Data}{Result});
#   return $res2;
# }

# sub QueryUnpreparedForContingencies {
#   my ($self,%args) = @_;
#   my @items;
#   my $res1 = $UNIVERSAL::agent->QueryAgent
#     (
#      Receiver => 'Agent1',
#      Data => {
# 	      Eval => [['_prolog_list',Var('?Contingency'),['declassified',['unpreparedForContingency',Var('?Contingency')]]]],
# 	     },
#     );
#   print Dumper({Res1 => $res1});
#   # my $res2 = $self->DropPrologAnnotations(Interlingua => $res1->{Data}{Result});
#   # print Dumper({MyRes2 => $res2});
#   # foreach my $result (@{$res2}) {
#   my @list = @{$res1->{Data}{Result}};
#   shift @list;
#   foreach my $result (@list) {
#     my $res3 = $self->MyImportExport->Convert
#       (
#        Input => [$result],
#        InputType => 'Interlingua',
#        OutputType => 'Prolog',
#       );
#     print Dumper({MyRes3 => $res3});
#     if ($res3->{Success}) {
#       my $result = $res3->{Output};
#       $result =~ s/\.$//sg;
#       chomp $result;
#       push @items, $result;
#     } else {
#       push @items, 'Error retrieving upcoming events.';
#     }
#   }
#   return \@items;
# }

# sub QueryAllContingencies {
#   my ($self,%args) = @_;
#   my @items;
#   my $res1 = $UNIVERSAL::agent->QueryAgent
#     (
#      Receiver => 'Agent1',
#      Data => {
# 	      Eval => [['_prolog_list',Var('?Contingency'),['declassified',['planForContingency',Var('?Contingency')]]]],
# 	     },
#     );
#   print Dumper({Res1 => $res1});
#   # my $res2 = $self->DropPrologAnnotations(Interlingua => $res1->{Data}{Result});
#   # print Dumper({MyRes2 => $res2});
#   # foreach my $result (@{$res2}) {
#   my @list = @{$res1->{Data}{Result}};
#   shift @list;
#   foreach my $result (@list) {
#     my $res3 = $self->MyImportExport->Convert
#       (
#        Input => [$result],
#        InputType => 'Interlingua',
#        OutputType => 'Prolog',
#       );
#     print Dumper({MyRes3 => $res3});
#     if ($res3->{Success}) {
#       my $result = $res3->{Output};
#       $result =~ s/\.$//sg;
#       chomp $result;
#       push @items, $result;
#     } else {
#       push @items, 'Error retrieving upcoming events.';
#     }
#   }
#   return \@items;
# }

sub ReConsultFiles {
  my ($self,%args) = @_; 
  my @items;
  my $res1 = $UNIVERSAL::agent->QueryAgent
    (
     Receiver => 'Agent1',
     Data => {
	      Eval => [['_prolog_list',[],['consult','/var/lib/myfrdcsa/codebases/minor/free-life-planner/free_life_planner']]],
	     },
    );
}

sub Reconfigure {
  my ($self,%args) = @_;
  # have the ability to reconfigure properties of the system while it
  # is running.
  my $res1 = $UNIVERSAL::agent->QueryAgent
    (
     Receiver => 'Agent1',
     Data => {
	      Command => 'restart',
	     },
    );
  my $res2 = $UNIVERSAL::agent->QueryAgentReply
    (
     Message => $args{Message},
     Data => {
	      Result => $res1,
	     },
    );

}

sub Restart {
  my ($self,%args) = @_;
  my $res1 = $UNIVERSAL::agent->QueryAgentReply
    (
     Message => $args{Message},
     Contents => 'Attempting to restart...',
    );
  my $res2 = $UNIVERSAL::agent->SendContents
    (
     Receiver => 'Test',
     Data => {
	      Command => 'restart',
	     },
    );
  my $res3 = $UNIVERSAL::agent->SendContents
    (
     Receiver => 'UniLang',
     Contents => 'Deregister',
    );
  my $cli = GetCommandLineForCurrentProcess();
  system "(sleep 1; cd /var/lib/myfrdcsa/codebases/minor/guardian && $cli) &";
  exit(0);
}

# sub CleanUpResult {
#   my ($self,%args) = @_;
#   my @items;
#   my $res1 = $self->DropPrologAnnotations(Interlingua => $args{Result}->{Data}{Result});
#   foreach my $bindings (@$res1) {
#     my $res2 = $self->MyImportExport->Convert
#     	(
#     	 Input => [['deadline',$bindings->[2],$bindings->[1],$bindings->[0]]],
#     	 InputType => 'Interlingua',
#     	 OutputType => 'Prolog',
#     	);
#     if ($res2->{Success}) {
#       my $result = $res2->{Output};
#       $result =~ s/\.$//sg;
#       chomp $result;
#       push @items, $result;
#     } else {
#       push @items, 'Error retrieving upcoming events.';
#     }
#   }
#   return \@items;
# }

1;
