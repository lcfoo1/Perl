SELECT DISTINCT ats.lot,
       ats.operation,
       ats.devrevstep,
       ats.program_name,
       alo.total_good,
       alo.total_bad,
       ats.s_spec
FROM a_testing_session ats,
     a_lot_at_operation alo
WHERE ats.latest_flag = 'Y'
AND alo.lot = ats.lot
AND alo.lao_start_ww = ats.lao_start_ww
AND alo.operation = ats.operation
AND (ats.program_name like 'CFD%' or ats.program_name like 'NOC%')
AND ats.devrevstep like '%L'
--and ats.s_spec in ('L7ZR','L7ZZ')
--and ats.operation in ('7252')
--and ats.lao_start_ww = 200505
