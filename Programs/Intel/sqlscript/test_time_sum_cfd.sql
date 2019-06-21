select ats.lao_start_ww, 
       program_name,
       devrevstep,
       --ats.operation,
       substr(trunc(avg(decode(goodbad_flag,'G',test_time,null))*1000)/1000,1,6) TTG,
       substr(count(decode(goodbad_flag,'G',1,null)),1,8) Volume,
       substr(trunc(avg(decode(goodbad_flag,'B',test_time,null))*1000)/1000,1,6) TTB,
       substr(count(decode(goodbad_flag,'B',1,null)),1,8) Volume
	
from a_testing_session ats,
     a_device_testing  adt
	 
where ats.ts_id	       = adt.ts_id
and   ats.lao_start_ww = adt.lao_start_ww
and   ats.latest_flag  = 'Y'
and   adt.latest_flag  = 'Y'

and   (program_name like 'CFD%') -- or program_name like 'NOC____H___8____')
--and   ats.devrevstep like '8%'
--and   ats.operation in ('7011','7251')
--and   (ats.lot like '6%' or ats.lot like 'M%' or ats.lot like 'T%' or ats.lot like '9%' or ats.lot like '4%' or ats.lot like 'N%' or ats.lot like 'V%')
--and   ats.eng_id not like 'X_'
--and   ats.lao_start_ww > 200452

group by ats.lao_start_ww, program_name, devrevstep
order by ats.lao_start_ww
