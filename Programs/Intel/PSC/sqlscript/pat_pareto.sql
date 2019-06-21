select btr.sort_lot,
       btr.sort_wafer_id,
       adt.sort_x,
       adt.sort_y,
       test.program_name,
       btr.operation,
       btr.devrevstep,
       adt.functional_bin,
       test_name,
       pattern_name
from   a_bunch_of_test_results      btr,
       a_device_testing             adt,
       a_pattern_failure            apf,
       a_pattern_name               apn,
       a_test                       test
where  btr.btr_sequence_in_ww    = adt.btr_sequence_in_ww
and    btr.lao_start_ww          = adt.lao_start_ww
and    btr.program_name          = apf.pattern_program_name
and    btr.btr_sequence_in_ww    = apf.btr_sequence_in_ww
and    btr.lao_start_ww          = apf.lao_start_ww
and    btr.program_name          = test.program_name
and    btr.devrevstep            = test.devrevstep
and    adt.btr_sequence_in_ww    = apf.btr_sequence_in_ww
and    adt.ts_id                 = apf.ts_id
and    adt.dt_id                 = apf.dt_id
and    adt.latest_flag           = apf.latest_flag
and    adt.lao_start_ww          = apf.lao_start_ww
and    continuation_sequence     = 0
and    adt.latest_flag           = 'Y'
and    apf.pattern_name_id       = apn.pattern_name_id
and    apf.t_id                  = test.t_id
and    apf.pattern_program_name  = test.program_name
and    btr.devrevstep like '%H'
and    test.program_name like 'PSC%H2%81%B%'
and    test_name like '%PSMI%MAX%'
and    btr.operation in ('7251')
and    adt.lao_start_ww > 200436
