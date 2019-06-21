SELECT ats.program_name prog,
--       ats.operation oper,
       ats.devrevstep,
       ats.lao_start_ww ww,
       (sum(ats.TOTAL_GOOD) + sum(ats.TOTAL_BAD)) total
FROM   a_testing_session ats
WHERE  ats.latest_flag = 'Y'
AND    ats.operation = '7251'
AND    ats.program_name LIKE '___2M%'
AND    (ats.lot  like '6%' or ats.lot like 'M%' or ats.lot like 'T%' or ats.lot like '9%' or ats.lot like '4%')
AND    ats.devrevstep LIKE '%S'
AND    ats.lao_start_ww LIKE '2005%'
GROUP BY ats.program_name, ats.devrevstep, ats.lao_start_ww 
