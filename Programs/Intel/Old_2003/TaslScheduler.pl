        #################################################
        # Example 1. How to get/set account information for a task  
        #
        use Win32::TaskScheduler;

        $scheduler = Win32::TaskScheduler->New();
        $scheduler->Activate("My scheduled job");

        $runasuser=$scheduler->GetAccountInformation();
        die "Cannot set username\n" if (! $scheduler->SetAccountInformation('administrator','secret'));
        die "Cannot save changes username\n" if (! $scheduler->Save());

        #Release COM stuff (Optional)
        $scheduler->End();

        #################################################
        # Example 2. Create a task.
        #
        use Win32::TaskScheduler;

        $scheduler = Win32::TaskScheduler->New();

        #
        # This adds a daily schedule.
        #
        #%trig=(
        #       'BeginYear' => 2001,
        #       'BeginMonth' => 10,
        #       'BeginDay' => 20,
        #       'StartHour' => 14,
        #       'StartMinute' => 10,
        #       'TriggerType' => $scheduler->TASK_TIME_TRIGGER_DAILY,
        #       'Type'=>{
        #               'DaysInterval' => 3,
        #       },
        #);

        #
        # And this a monthly one, for first and last week.
        #
        %trig=(
                'BeginYear' => 2001,
                'BeginMonth' => 10,
                'BeginDay' => 20,
                'StartHour' => 14,
                'StartMinute' => 10,
                'TriggerType' => $scheduler->TASK_TIME_TRIGGER_MONTHLYDOW,
                'Type'=>{
                        'WhichWeek' => $scheduler->TASK_FIRST_WEEK | $scheduler->TASK_LAST_WEEK,
                        'DaysOfTheWeek' => $scheduler->TASK_FRIDAY | $scheduler->TASK_MONDAY,
                        'Months' => $scheduler->TASK_JANUARY | $scheduler->TASK_APRIL | $scheduler->TASK_JULY | $scheduler->TASK_OCTOBER,
                },
        );

        #
        # Execute this task every 10th of january,april,july,october
        #
        # Please note that days are given in the conventional form 1,2,30,25 not
        # what m$ says in theyr APIs. This is the only exception to m$ APIs.
        #
        #%trig=(
        #       'BeginYear' => 2001,
        #       'BeginMonth' => 10,
        #       'BeginDay' => 20,
        #       'StartHour' => 14,
        #       'StartMinute' => 10,
        #       'TriggerType' => $scheduler->TASK_TIME_TRIGGER_MONTHLYDATE,
        #       'Type'=>{
        #               'Months' => $scheduler->TASK_JANUARY | $scheduler->TASK_APRIL | $scheduler->TASK_JULY | $scheduler->TASK_OCTOBER,
        #               'Days' => 10,
        #       },
        #);

        $tsk="alfred";

        foreach $k (keys %trig) {print "$k=" . $trig{$k} . "\n";}

        $scheduler->NewWorkItem($tsk,\%trig);
        $scheduler->SetApplicationName("winword.exe");

        $scheduler->Save();