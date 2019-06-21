select TID,sum(util)/7 Percent from (
select * from (
select
lao_start_ww ww
,tester_id TID
,program_name PROG
,lot LOT
,decode(substr(program_name,10,2)
  ,'JS','ST1-ST'
  ,'JP','ST1-ST'
  ,'DS','ST2-ST'
  ,'DP','ST2-ST'
  ,'IF','S9K-FT'
  ,'IM','S9K-FT'
  ,'RC','S9K-FT'
  ,'MF','CMT-FT'
  ,'MS','CMT-ST'
  ,'C0','S9K-CF'
  ,null) Tester_Type
,(test_end_date_time-test_start_date_time) util
,(total_good+total_bad) total_tested
from a_testing_session ats
where lao_start_ww between 200447 and 200447
and tester_id is not null
)
where tester_type in ('S9K-FT')
and   (prog like 'NOC%' or prog like 'PSC%')
)
group by TID
