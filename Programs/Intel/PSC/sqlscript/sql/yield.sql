SELECT ats.lot,
       ats.operation,
       ats.devrevstep,
       ats.program_name,
substr ((alo.total_good + alo.total_bad),1,6) TOTAL_TESTED,
substr (alo.total_good,1,6) TOTAL_GOOD,
substr (sum( decode(interface_bin, 1, 1, null)),1,5) Bin_1,
substr (sum( decode(interface_bin, 2, 1, null)),1,5) Bin_2,
substr (sum( decode(interface_bin, 3, 1, null)),1,5) Bin_3,
substr (sum( decode(interface_bin, 4, 1, null)),1,5) Bin_4,
substr (sum( decode(interface_bin, 5, 1, null)),1,5) Bin_5,
substr (sum( decode(interface_bin, 6, 1, null)),1,5) Bin_6,
substr (sum( decode(functional_bin, 9086, 1, null)),1,5) Bin_9086
FROM a_testing_session ats,
     a_device_testing adt,
     a_lot_at_operation alo
WHERE  adt.latest_flag = 'Y'
AND ats.latest_flag = 'Y'
AND ats.lao_start_ww = adt.lao_start_ww
AND ats.ts_id = adt.ts_id
AND alo.lot = ats.lot
AND alo.lao_start_ww = ats.lao_start_ww
AND alo.operation = ats.operation
AND alo.lao_start_ww = adt.lao_start_ww
AND (devrevstep LIKE '8%S' or devrevstep LIKE '8%R')
AND ats.operation IN ('7251')
AND (ats.program_name LIKE 'PSC2M%K_' or ats.program_name LIKE 'NOC2M%K_')
--AND (ats.lot LIKE 'M%' or ats.lot LIKE '4%' or ats.lot LIKE 'P%')
--AND ats.test_end_date_time between '01-SEP-02' and '30-SEP-02'
GROUP BY ats.lot, ats.operation, ats.devrevstep, ats.program_name, alo.total_good, alo.total_bad
ORDER BY operation
