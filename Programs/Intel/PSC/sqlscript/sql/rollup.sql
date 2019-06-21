SELECT btr.package_id,
       btr.devrevstep,
       btr.program_name,
       btr.operation,
--       btr.lot,
--       adt.socket_id,
       count(*) TOTAL,
       trunc(sum(Decode(adt.interface_bin,'1',1))*100/sum(Decode(adt.goodbad_flag,'G',1)),2) BS_Bin1,
       trunc(sum(Decode(adt.interface_bin,'2',1))*100/sum(Decode(adt.goodbad_flag,'G',1)),2) BS_Bin2,
       trunc(sum(Decode(adt.interface_bin,'3',1))*100/sum(Decode(adt.goodbad_flag,'G',1)),2) BS_Bin3,
       trunc(sum(Decode(adt.interface_bin,'4',1))*100/sum(Decode(adt.goodbad_flag,'G',1)),2) BS_Bin4,
       trunc(sum(Decode(adt.interface_bin,'5',1))*100/sum(Decode(adt.goodbad_flag,'G',1)),2) BS_Bin5,
       trunc(sum(Decode(adt.interface_bin,'6',1))*100/sum(Decode(adt.goodbad_flag,'G',1)),2) BS_Bin6,
       trunc(count(Decode(adt.goodbad_flag,'G',1))*100/count(*),2) YIELD,
       trunc(Avg(Decode(adt.goodbad_flag,'G',test_time)),2) TTG,
       trunc(Avg(Decode(adt.goodbad_flag,'B',test_time)),2) TTB

-- Remove coments below for testtime per good bin
      ,trunc(Avg(Decode(adt.interface_bin,'1',test_time)),2) TT1,
       trunc(Avg(Decode(adt.interface_bin,'2',test_time)),2) TT2,
       trunc(Avg(Decode(adt.interface_bin,'3',test_time)),2) TT3,
       trunc(Avg(Decode(adt.interface_bin,'4',test_time)),2) TT4,
       trunc(Avg(Decode(adt.interface_bin,'5',test_time)),2) TT5,
       trunc(Avg(Decode(adt.interface_bin,'6',test_time)),2) TT6

  FROM a_bunch_of_test_results btr,
       a_device_testing adt

 WHERE btr.lao_start_ww = adt.lao_start_ww
   AND btr.btr_sequence_in_ww = adt.btr_sequence_in_ww
   AND btr.lao_start_ww > 200514
   AND btr.program_name LIKE 'NOC2M%KD' 
   AND btr.devrevstep LIKE '%S'
--   AND btr.lot LIKE 'M%'
--   AND btr.operation IN ('7011')
   AND latest_flag = 'Y'
--   AND adt.functional_bin like '_00'

 GROUP BY btr.package_id, btr.devrevstep, btr.program_name, btr.operation --, btr.lot --, adt.socket_id
 ORDER BY 1,2,3,4

