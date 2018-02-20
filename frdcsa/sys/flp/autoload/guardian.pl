%% recompile events

%% FINISH THIS TO LIST ALL THE UPCOMING EVENTS FOR AT LEAST THE NEXT
%% DAY (OR SO), PERIODICALLY DO IT FOR LONGER.  IF THERE ARE ITEMS OF
%% MAJOR IMPORTANCE, ANNOUNCE AHEAD OF TIME.  EXACT LOGIC TO BE WORKED
%% OUT.

:- dynamic guardianResults/1.

doHeartbeats :-
	guardianHeartbeat(_),
	mainLoopHeartbeat(_).

guardianHeartbeat(Entries) :-
	updateEventsForGuardian,
	getEventsForGuardian(Items),
	getCurrentDateTime(Now),
	findall(Entry,
		(
		 member([DateTime,Descriptions],Items),
		 englishDescriptionOfTimeUntil(Now,DateTime,EnglishDescription),
		 generateGlossFor(DateTime,Gloss),
		 Entry = [Gloss,EnglishDescription,DateTime,Descriptions]
		),
		Entries),
	view([entries,Entries]),
	prettyPrintEntries(Entries).

prettyPrintEntries(Entries) :-
	findall(String,
		(   
		    member([Gloss,EnglishDescription,DateTime,Descriptions],Entries),
		    atomic_list_concat([EnglishDescription,at,Gloss],' ',Text),
		    with_output_to(atom(String),(write(Text),nl,tab(8),write(Descriptions),nl,nl))
		    %% view([string,String])
		),
		Strings),
	atomic_list_concat(Strings,'',String),
	write_data_to_file(String,'/var/lib/myfrdcsa/codebases/minor/guardian/data-git/todos.txt').

getEventsForGuardian(Items) :-
	guardianResults(Items).

updateEventsForGuardian :-
	listAllPending(Results),
	retractall(guardianResults(_)),
	assertz(guardianResults(Results)).

listAllPending(Results) :-
	view([1]),
	getCurrentDateTime(CurrentTime),
	CurrentTime = [Y1-M1-D1,H1:Mi1:S1],
	StartDateTime = [Y1-M1-D1,0:0:0],	
	consecutiveDates([Y1-M1-D1],[Y2-M2-D2]),
	EndDateTime = [Y2-M2-D2,23:59:59],	
	pendingCategories(PendingCategories),
	view([2]),
	findall([PendingCategory,PendingNotifications],
		(
		 member(PendingCategory,PendingCategories),
		 pending(PendingCategory,CurrentTime,StartDateTime,EndDateTime,PendingNotifications)
		),
		PendingCategoryNotifications),
	view([pendingCategoryNotifications,PendingCategoryNotifications]),
	findall([Description,ActualDateTime],
		(
		 member([Category,Notifications],PendingCategoryNotifications),
		 view([entry,Category,Notifications]),
		 member([Description,ActualDateTime,NotificationateTime,Type],Notifications)
		),
		DescriptionDateTimes),
	view([3,DescriptionDateTimes]),
	sortDescriptionDateTimes(DescriptionDateTimes,SortedDescriptionDateTimes),
	view([4,SortedDescriptionDateTimes]),
	getCurrentDateTime(CurrentDateTime),
	julian:delta_time(CurrentDateTime,s(432000),CutOffDateTime),
	julian:form_time([CurrentDateTime,[Y3-M3-D3,H3:Mi3:S3]]),
	view([5,[Y3-M3-D3,H3:Mi3:S3]]),
	findall(DescriptionDateTime,(member(DescriptionDateTime,SortedDescriptionDateTimes),DescriptionDateTime = [DateTime,Description],view([dateTime,DateTime]),julian:compare_time(>,DateTime,[Y3-M3-D3,H3:Mi3:S3])),Results),
	view([6]),
	view([results,Results]).
	
sortDescriptionDateTimes(DescriptionDateTimes,SortedDescriptionDateTimes) :-
	findall([X,Y],(member(DescriptionDateTime,DescriptionDateTimes),DescriptionDateTime = [X,Y]),List),
	view([list,List]),
	view([a]),
	setof(DateTime,Description^member([Description,DateTime],List),DateTimes),
	view([b,DateTimes]),
	predsort(julian:compare_time,DateTimes,SortedDateTimes),
	view([c]),
	findall([DateTime,Tasks],
		(
		 member(DateTime,SortedDateTimes),
		 julian:form_time([DateTime,[Y-M-D,H:Mi:S]]),
		 DateTime = [Y-M-D,H:Mi:S],
		 findall(Description2,(member([Description2,DateTime2],List),DateTime=DateTime2),Tasks)
		),
		SortedDescriptionDateTimes).

%% fassert('Agent1','Yaswi1',
%% 	atTime(CurrentDateTime,
%% 	       completed(tell(freeLifePlanner,Participant,recurrenceFn([
%% 									action(Action),
%% 									itemDateTime(ItemDateTime),
%% 									recurrenceDateTime(RecurrenceDateTime),
%% 									type(Type)
%% 								       ])))),Results),



%% listPending([types([recurrences,notifications,planSteps]),period([longOverdue,overdue,today,next2Days,thisSecond,thisMinute,thisHour,thisDay,thisWeek,thisMonth,next24Hours])]).