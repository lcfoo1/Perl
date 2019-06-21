Attribute VB_Name = "VBT_PMU_LDO"
' Date     : 20180702
' Rev      :
' Author   :
' HeadURL  : For BCM43014 WLBGA/FCBGA
' SVN      : N/A

'--------------------------------------------------------------------------------------------------------------------------
'Important: Power Mode Terminology for BCM43430 is defined as below:
'
'   i.      PMU OFF     -> All REG_ONs = 0.
'   ii.     WL Active   -> WL_REG_ON = 1 only. Also refers to host (WL) mode.
'   iii.    BT Active   -> BT_REG_ON =1 only. Also refers to host (BT) mode.
'   iv.     SA_WPT      -> WPT_1P8=1, BT/WL_REG_ON=0. Also refers to standalone Wireless Power Transfer mode.
'   v.      NSA_WPT     -> WPT_1P8=1, either BT_REG_ON or/and WL_REG_ON=1. Also refers to non-standalone WPT mode.
'   vi.     WL Sleep    -> WL_REG_ON = 1, i_sr_cntl < 9 >= 1, i_sr_cntl < 38 >= 0#
'   vii.    BT Sleep    -> BT_REG_ON = 1, i_sr_cntl < 9 >= 1, i_sr_cntl < 38 >= 0#
'--------------------------------------------------------------------------------------------------------------------------

Option Explicit

Private pmutb As New Toolbox_PMU_New

Public PPMU As Boolean
Public supply_pmu_ldo_pins As String
    

Public Function Pmu__LDOTests() As Long

On Error GoTo ErrorHandler

    If (gTTT_Enable) Then BCMTestInstance.PreBody

    LimitSheetEnabled = True
    
'    TurnOffPAMode
'    If TheExec.EnableWord("PMU_POP_EN") Then
'        TheHdw.Digital.applyLevelsTiming True, False, True, tlPowered, , , , , , , "TS_PMU_POP", "", "", ""
'    Else
'        TheHdw.Digital.applyLevelsTiming True, False, True, tlPowered, , , , , , , "TS_PAJTAG", "", "", ""
'    End If
    TurnOnPAMode
    Set AXI = JTAG
    
    Call ChipInit(PMU, runClocks:=False)
    
    'TheHdw.Digital.pins("BT_REG_ON_HSD").Disconnect                                        'Disconnect the HSD
    With TheHdw.DCVI.pins("VDDOUT_1P8_SW2")
        .Gate = False
        .Disconnect tlDCVIConnectDefault
        .Mode = tlDCVIModeHighImpedance
        .Connect (tlDCVIConnectLowSense)
        .Meter.Mode = tlDCVIMeterVoltage
        TheHdw.wait 1 * mS
    End With
    
    supply_pmu_ldo_pins = "ASR_VLX, CSR_VLX, VDDOUT_AON, VDDOUT_BT3P3, VDDOUT_MEMLPLDO, VDDOUT_RETLDO, VDDOUT_RF3P3"
    TheHdw.DCVI.pins(supply_pmu_ldo_pins).Disconnect
    TheHdw.DCVI.pins(supply_pmu_ldo_pins).BleederResistor = tlDCVIBleederResistorOff    '# Turn off the bleeder resistor
    
    '# Initialize the VBAT and PMU_VDDIO
    
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_20mA"
    
    TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Filter.Bypass = False
    TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Filter.Value = 781.25
   
    If TheExec.EnableWord("PMU_POP_EN") Then
        '***********************************************************************************************************
        '                                               POP ENABLED
        '***********************************************************************************************************
'''''        'Load LDO POP pattern
'''''        PMU_PatName = ".\ExportedFiles\PMU\BCM4362_LDO_POP.PAT"
''''
'''''        If TheHdw.Digital.Patgen.IsRunning Then TheHdw.Digital.Patgen.Halt     ' Stop any pattern which is previously running.
'''''        TheHdw.Patterns(PMU_PatName).load
'''''        TheHdw.wait 2 * mS

        Call Pmu__LdoTests__BT_LDO3P3__POP
        If TheExec.Sites.ActiveCount = 0 Then Exit Function
    
        Call Pmu__LdoTests__RF_LDO3P3__POP
        If TheExec.Sites.ActiveCount = 0 Then Exit Function

        Call Pmu__LdoTests__MISCLDO__POP
        If TheExec.Sites.ActiveCount = 0 Then Exit Function
              
        Call Pmu__LdoTests__MEMLPLDO__POP
        If TheExec.Sites.ActiveCount = 0 Then Exit Function

    Else
        Call Pmu__LdoTests__BT_LDO3P3
        If TheExec.Sites.ActiveCount = 0 Then Exit Function
    
        Call Pmu__LdoTests__RF_LDO3P3
        If TheExec.Sites.ActiveCount = 0 Then Exit Function
        
        Call Pmu__LdoTests__RETLDO
        If TheExec.Sites.ActiveCount = 0 Then Exit Function
    
        Call Pmu__LdoTests__HVLLDO1P8
        If TheExec.Sites.ActiveCount = 0 Then Exit Function

        Call Pmu__LdoTests__HVLLDO1P8_EMMC
        If TheExec.Sites.ActiveCount = 0 Then Exit Function
    
    End If
    
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_20mA"
    
    TheHdw.DCVS.pins("VDDOUT_1P8_SW2").Disconnect tlDCVSConnectDefault
    'TheHdw.Digital.pins("BT_REG_ON_HSD").Connect

    If (gTTT_Enable) Then BCMTestInstance.PostBody
    
Exit Function
ErrorHandler:
    If TheExec.Sites.ActiveCount = 0 Then Exit Function    'If last site failed, exit the test and let IGXL cleanup
    TheExec.ErrorLogMessage "VB Error #" & Trim(Str(err.Number)) & " " & err.Description & " in instance " & TheExec.DataManager.InstanceName
    Resume Next

End Function


Public Function Pmu__LdoTests__RF_LDO3P3() As Long

On Error GoTo ErrorHandler
    Dim RF_LDO3P3_VOUT_0mA_3p7V As New SiteDouble, RF_LDO3P3_VOUT_100mA_3p7V As New SiteDouble
    Dim RF_LDO3P3_Q_Curr_0mA_3p7V As New SiteDouble

    Dim VDDOUT_1P8_SW2_VOUT_0mA_3p7V As New SiteDouble, VDDOUT_1P8_SW2_VOUT_1mA_3p7V As New SiteDouble
    Dim VDDOUT_1P8_SW2_VOUT_100mA_3p5V As New SiteDouble, VDDOUT_1P8_SW2_VOUT_100mA_3p7V As New SiteDouble, VDDOUT_1P8_SW2_VOUT_100mA_5p25V As New SiteDouble
    Dim line_diff As Double, load_diff As Double

    Dim testTime As Double
    TheHdw.StartStopwatch
    
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU Regulator Test - RF_LDO3P3 [E1], [E2], [E3], [E4]"
    TheExec.Datalog.WriteComment "================================================================================================"

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_20mA"                           'PMU_VDDIO = 1.8V
    TheHdw.wait 1 * mS

     'Instrument setup of VDDOUT_RF3P3 pin for load variation
     
    TheHdw.DCVI.pins("VDDOUT_RF3P3").BleederResistor = tlDCVIBleederResistorAuto
    With TheHdw.DCVI.pins("VDDOUT_RF3P3")
        .Disconnect tlDCVIConnectDefault
         .Mode = tlDCVIModeCurrent
         .Meter.Mode = tlDCVIMeterVoltage
         .Current = -200 * nA
         .Voltage = -0.5 * v
         .Connect
         .Gate = True
     End With
     TheHdw.wait 1 * mS
     
    'Register Settings - E1
    Call Pmu_registerSetup__rfldo3p3        '# setup rfldo3p3
    TheHdw.wait 5 * mS
    
    '************************************  E2 - LDO Quiscent Current ************************************
    
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_2mA"
    TheHdw.wait 1 * mS
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200uA"
    TheHdw.wait 5 * mS

    'Measure QCurrent directly
    RF_LDO3P3_Q_Curr_0mA_3p7V = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 50, 5 * mS)
    
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"      'Revert to 200mA
    TheHdw.wait 2 * mS

    '************************************* E1 - LDO Output Voltage @ No load *************************************

    '----------------------------------
    'VDDBAT = 3.7V, 0mA load at VOUT3P3
    '----------------------------------
    'Steadily increase the current clamp of power supply
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    TheHdw.wait 2 * mS
    
    'Register Settings - to changed to measure through VDDOUT_1P8_SW2 [E3]
    Call Pmu_registerSetup__Analogmux(muxPin:="rfldo3p3")
    TheHdw.wait 2 * mS
    
    RF_LDO3P3_VOUT_0mA_3p7V = pmutb.Meter_Strobe("VDDOUT_RF3P3", 20, 0 * mS)                            'Measure VDDOUT_RF3P3 output voltage with 0mA Load (VDDBAT=3.7V)
   
     '-----------------------------------------
    'VDDBAT = 3.7V, 1mA load at VDDOUT_RF3P3
    '-----------------------------------------
    
    pmutb.Apply_PSET "VDDOUT_RF3P3", "VDDOUT_RF3P3_1mA_2V"                             '1mA Load setting at output of RF_LDO3P3
    TheHdw.wait 5 * mS
    'BT_REG_ON_VOUT_1mA_3p7V = TheHdw.DCVS.pins("BT_REG_ON_UVS").Meter.Read(tlStrobe, 10, 781.25, tlDCVSMeterReadingFormatAverage)
    VDDOUT_1P8_SW2_VOUT_1mA_3p7V = pmutb.Meter_Strobe("VDDOUT_1P8_SW2", 20, 0 * mS)
   
    '************************************* E1 - LDO Output Voltage @ Max Load (100mA) ***************************************************************************************************************************************************
    Dim lCnt    As Long
    Dim LNR_diff As New SiteDouble
    lCnt = 0

RetryRFLDO:
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    TheHdw.wait 3 * mS
    
   '-----------------------------------------
    'VDDBAT = 3.7V, 100mA load at VDDOUT_RF3P3
    '-----------------------------------------
   
    pmutb.Apply_PSET "VDDOUT_RF3P3", "VDDOUT_RF3P3_100mA_2V"                            '100mA Load setting at output of RF_LDO3P3
    TheHdw.wait 2 * mS
        
    RF_LDO3P3_VOUT_100mA_3p7V = pmutb.Meter_Strobe("VDDOUT_RF3P3", 20, 0 * mS)          'Measure RF_LDO3P3 output voltage with 100mA Load (VDDBAT=3.7V)
    'BT_REG_ON_VOUT_100mA_3p7V = TheHdw.DCVS.pins("BT_REG_ON_UVS").Meter.Read(tlStrobe, 10, 781.25, tlDCVSMeterReadingFormatAverage)
    VDDOUT_1P8_SW2_VOUT_100mA_3p7V = pmutb.Meter_Strobe("VDDOUT_1P8_SW2", 20, 0 * mS)
    
    'Steadily decrease load current on VDDOUT_RF3P3 pin
    pmutb.Apply_PSET "VDDOUT_RF3P3", "VDDOUT_RF3P3_100mA_2V"                            '100mA Load setting at output of RF_LDO3P3
    TheHdw.wait 2 * mS
    
    '------------------------------------------
    'VDDBAT = 5.25V, 100mA load at PMU_VDDBAT5V
    '------------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_200mA"
    TheHdw.wait 2 * mS

    'Steadily increase load current on VOUT_CLDO pin
    pmutb.Apply_PSET "VDDOUT_RF3P3", "VDDOUT_RF3P3_100mA_2V"                            '200mA Load setting at output of RF_LDO3P3
    TheHdw.wait 2 * mS
 
    'Measure voltage at BT_REG_ON @ max LDO_VDD1P12
    'BT_REG_ON_VOUT_100mA_5p25V = TheHdw.DCVS.pins("BT_REG_ON_UVS").Meter.Read(tlStrobe, 10, 781.25, tlDCVSMeterReadingFormatAverage)
    VDDOUT_1P8_SW2_VOUT_100mA_5p25V = pmutb.Meter_Strobe("VDDOUT_1P8_SW2", 20, 0 * mS)
    
    
    'Steadily decrease load current on VDDOUT_RF3P3 pin
    pmutb.Apply_PSET "VDDOUT_RF3P3", "VDDOUT_RF3P3_50mA_2V"                                   '50mA Load setting at output of RF_LDO3P3
    TheHdw.wait 1 * mS
    pmutb.Apply_PSET "VDDOUT_RF3P3", "VDDOUT_RF3P3_10mA_2V"                                   '10mA Load setting at output of RF_LDO3P3
    TheHdw.wait 1 * mS

    'Added retry loop to recover failure due to contact
    LNR_diff = VDDOUT_1P8_SW2_VOUT_100mA_5p25V.Subtract(VDDOUT_1P8_SW2_VOUT_100mA_3p7V).Abs.Divide(0.44576)
    If LNR_diff.Compare(GreaterThan, 0.0076).Any(True) And lCnt < 5 Then
        lCnt = lCnt + 1
        GoTo RetryRFLDO
    End If
    
    With TheHdw.DCVI.pins("VDDOUT_RF3P3")
        .Gate = False
        .Disconnect tlDCVIConnectDefault
        .Mode = tlDCVIModeHighImpedance
        .BleederResistor = tlDCVIBleederResistorOff
    End With

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    
    'Clear UDR !!!!
    Call Pmu_registerSetup__clearUDR        '# Clear the UDR registers
  
    '************************************* Limit Check *****************************************************************************************************************************************************
      
    'RFLD3P3 Output Voltage at No Load and Max Load
    Call LimitsTool.TestLimit(RF_LDO3P3_VOUT_0mA_3p7V, "VDDOUT_RF3P3", "PMU_" + "RF_LDO3P3_0mA_3p7V")
    Call LimitsTool.TestLimit(RF_LDO3P3_VOUT_100mA_3p7V, "VDDOUT_RF3P3", "PMU_" + "RF_LDO3P3_100mA_3p7V")
    
    'RFLD3P3 Quiescent Current
    Call LimitsTool.TestLimit(RF_LDO3P3_Q_Curr_0mA_3p7V, "ET_LINREG_VDD_V5P0", "PMU_" + "RF_LDO3P3_Q_Current")

    'RFLD3P3 Output Voltage via BT_REG_ON
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_1mA_3p7V.Divide(0.44576), "VDDOUT_1P8_SW2", "PMU_" + "VDDOUT_1P8_SW2_1mA_3p7V_RFLDO3P3")
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_100mA_3p7V.Divide(0.44576), "VDDOUT_1P8_SW2", "PMU_" + "VDDOUT_1P8_SW2_100mA_3p7V_RFLDO3P3")
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_100mA_5p25V.Divide(0.44576), "VDDOUT_1P8_SW2", "PMU_" + "VDDOUT_1P8_SW2_100mA_5p0V_RFLDO3P3")

    'RFLD3P3 LDR at Min and Max Load
    load_diff = 100 * mA - 1 * mA
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_1mA_3p7V.Subtract(VDDOUT_1P8_SW2_VOUT_100mA_3p7V).Abs.Divide(0.44576), "VDDOUT_1P8_SW2", "PMU_" + "RF_LDO3P3_LDR_Diff")
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_1mA_3p7V.Subtract(VDDOUT_1P8_SW2_VOUT_100mA_3p7V).Divide(0.44576).Divide(load_diff).Abs, "VDDOUT_1P8_SW2", "PMU_" + "RF_LDO3P3_LDR_3p7V")
    
    'RFLD3P3 LNR at Min and Max Load
    line_diff = 5.25 * v - 3.7 * v
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_100mA_5p25V.Subtract(VDDOUT_1P8_SW2_VOUT_100mA_3p7V).Abs.Divide(0.44576), "VDDOUT_1P8_SW2", "PMU_" + "RF_LDO3P3_LNR_Diff")
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_100mA_5p25V.Subtract(VDDOUT_1P8_SW2_VOUT_100mA_3p7V).Divide(0.44576).Multiply(1000).Divide(line_diff).Abs, "VDDOUT_1P8_SW2", "PMU_" + "RF_LDO3P3_LNR_3p7V_5p25V")
    
    testTime = TheHdw.ReadStopwatch
    TheExec.Datalog.WriteComment ""
    TheExec.Datalog.WriteComment "Pmu__LdoTests__RF_LDO3P3 Test time:" & testTime
    TheExec.Datalog.WriteComment ""
    
Exit Function
ErrorHandler:
    If TheExec.Sites.ActiveCount = 0 Then Exit Function    'If last site failed, exit the test and let IGXL cleanup
    TheExec.ErrorLogMessage "VB Error #" & Trim(Str(err.Number)) & " " & err.Description & " in instance " & TheExec.DataManager.InstanceName
    Resume Next

End Function



Public Function Pmu__LdoTests__BT_LDO3P3() As Long

On Error GoTo ErrorHandler
    Dim BT_LDO3P3_VOUT_0mA_3p7V As New SiteDouble, BT_LDO3P3_VOUT_400mA_3p7V As New SiteDouble
    Dim BT_LDO3P3_Q_Curr_0mA_3p7V As New SiteDouble
    Dim VDDOUT_1P8_SW2_VOUT_0mA_3p7V As New SiteDouble, VDDOUT_1P8_SW2_VOUT_1mA_3p7V As New SiteDouble
    Dim BT_REG_ON_VOUT_400mA_3p5V As New SiteDouble, VDDOUT_1P8_SW2_VOUT_400mA_3p7V As New SiteDouble, VDDOUT_1P8_SW2_VOUT_400mA_5p25V As New SiteDouble
    Dim line_diff As Double, load_diff As Double

    Dim testTime As Double
    TheHdw.StartStopwatch
    
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU Regulator Test - BT_LDO3P3 [D1], [D2], [D3], [D4]"
    TheExec.Datalog.WriteComment "================================================================================================"

    '----------------------------------
    'VDDBAT = 3.7V, 0mA load at VOUT3P3
    '----------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_20mA"
    TheHdw.wait 1 * mS

    'Instrument setup of VDDOUT_BT3P3 pin for load variation
    TheHdw.DCVI.pins("VDDOUT_BT3P3").BleederResistor = tlDCVIBleederResistorAuto
    
    With TheHdw.DCVI.pins("VDDOUT_BT3P3")
        .Disconnect tlDCVIConnectDefault
        .Mode = tlDCVIModeCurrent
        .Meter.Mode = tlDCVIMeterVoltage
        .Current = -200 * nA
        .Voltage = -0.5 * v
        .Connect
        .Gate = True
     End With
     
    'Register Settings - D1
    Call Pmu_registerSetup__btldo3p3                            '# setup BT LDO3p3
    TheHdw.wait 5 * mS
   

    '************************************  D2 - LDO Quiscent Current ************************************
     
    'Instrument setup for low current measurement
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_2mA"
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200uA"
    TheHdw.wait 5 * mS
    
    'Measure QCurrent directly
    BT_LDO3P3_Q_Curr_0mA_3p7V = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 50, 5 * mS)

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"           'Revert to 200mA
    TheHdw.wait 2 * mS
    
     '************************************* D1 - Output Voltage @ No load ************************************

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_650mA"
    TheHdw.wait 2 * mS
    
    'Register Settings - to changed to measure through VDDOUT_1P8_SW2 [D3]
    Call Pmu_registerSetup__Analogmux(muxPin:="btldo3p3")
    TheHdw.wait 2 * mS
     
    BT_LDO3P3_VOUT_0mA_3p7V = pmutb.Meter_Strobe("VDDOUT_BT3P3", 50, 0.5 * mS)                            'Measure VDDOUT_BT3P3 output voltage with 0mA Load (VDDBAT=3.7V)

    '---------------------------------------
    'VDDBAT = 3.7V, 1mA load at VDDOUT_BT3P3
    '---------------------------------------
    pmutb.Apply_PSET "VDDOUT_BT3P3", "VDDOUT_BT3P3_1mA_2V"                             '1mA Load setting at output of BT_LDO3P3
    TheHdw.wait 5 * mS
    
    'BT_REG_ON_VOUT_1mA_3p7V = TheHdw.DCVS.pins("BT_REG_ON_UVS").Meter.Read(tlStrobe, 16, 781.25, tlDCVSMeterReadingFormatAverage) 'pmutb.Meter_Strobe("VDDOUT_BT3P3", 20, 0 * mS)
    VDDOUT_1P8_SW2_VOUT_1mA_3p7V = pmutb.Meter_Strobe("VDDOUT_1P8_SW2", 20, 0 * mS)
    
    '************************************* D1 - LDO Output Voltage @ Max Load 400mA *************************************

    '-----------------------------------------
    'VDDBAT = 3.7V, 400mA load at VDDOUT_BT3P3
    '-----------------------------------------
    'Steadily increase load current
    pmutb.Apply_PSET "VDDOUT_BT3P3", "VDDOUT_BT3P3_100mA_2V"                           '100mA Load setting at output of BT_LDO3P3
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "VDDOUT_BT3P3", "VDDOUT_BT3P3_200mA_2V"                           '200mA Load setting at output of BT_LDO3P3
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "VDDOUT_BT3P3", "VDDOUT_BT3P3_400mA_2V"                           '400mA Load setting at output of BT_LDO3P3
    TheHdw.wait 10 * mS
    
    BT_LDO3P3_VOUT_400mA_3p7V = pmutb.Meter_Strobe("VDDOUT_BT3P3", 50, 0.5 * mS)          'Measure BT_LDO3P3 output voltage with 400mA Load (VDDBAT=3.7V)
    'BT_REG_ON_VOUT_400mA_3p7V = TheHdw.DCVS.pins("BT_REG_ON_UVS").Meter.Read(tlStrobe, 8, 781.25, tlDCVSMeterReadingFormatAverage) 'pmutb.Meter_Strobe("VDDOUT_BT3P3", 20, 0 * mS)
    VDDOUT_1P8_SW2_VOUT_400mA_3p7V = pmutb.Meter_Strobe("VDDOUT_1P8_SW2", 20, 0 * mS)
    
    'Lower Down the Current first
    pmutb.Apply_PSET "VDDOUT_BT3P3", "VDDOUT_BT3P3_200mA_2V"                           '200mA Load setting at output of BT_LDO3P3
    TheHdw.wait 1 * mS
    pmutb.Apply_PSET "VDDOUT_BT3P3", "VDDOUT_BT3P3_100mA_2V"                           '100mA Load setting at output of BT_LDO3P3
    TheHdw.wait 1 * mS
    pmutb.Apply_PSET "VDDOUT_BT3P3", "VDDOUT_BT3P3_20mA_2V"                            '20mA Load setting at output of BT_LDO3P3
    TheHdw.wait 1 * mS

    '-----------------------------------------
    'VDDBAT = 5.25V, 400mA load at PMU_VDDBAT5V
    '-----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_650mA"
    TheHdw.wait 2 * mS
    'Steadily increase load current
    pmutb.Apply_PSET "VDDOUT_BT3P3", "VDDOUT_BT3P3_100mA_2V"                           '100mA Load setting at output of BT_LDO3P3
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "VDDOUT_BT3P3", "VDDOUT_BT3P3_200mA_2V"                           '200mA Load setting at output of BT_LDO3P3
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "VDDOUT_BT3P3", "VDDOUT_BT3P3_400mA_2V"                           '400mA Load setting at output of BT_LDO3P3
    TheHdw.wait 10 * mS

    'BT_REG_ON_VOUT_400mA_5p25V = TheHdw.DCVS.pins("BT_REG_ON_UVS").Meter.Read(tlStrobe, 8, 781.25, tlDCVSMeterReadingFormatAverage) 'pmutb.Meter_Strobe("VDDOUT_BT3P3", 20, 0 * mS)
    VDDOUT_1P8_SW2_VOUT_400mA_5p25V = pmutb.Meter_Strobe("VDDOUT_1P8_SW2", 20, 0 * mS)


    'Steadily decrease load current on VDDOUT_BT3P3 pin
    pmutb.Apply_PSET "VDDOUT_BT3P3", "VDDOUT_BT3P3_200mA_2V"                        '200mA Load setting at output of BT_LDO3P3
    TheHdw.wait 1 * mS
    pmutb.Apply_PSET "VDDOUT_BT3P3", "VDDOUT_BT3P3_20mA_2V"                         '20mA Load setting at output of BT_LDO3P3
    TheHdw.wait 2 * mS

    With TheHdw.DCVI.pins("VDDOUT_BT3P3")
        .Gate = False
        .Disconnect tlDCVIConnectDefault
        .Mode = tlDCVIModeHighImpedance
        .BleederResistor = tlDCVIBleederResistorOff
    End With

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"     '#restore
   

    'Clear UDR !!!!
    Call Pmu_registerSetup__clearUDR        '# Clear the UDR registers
    TheHdw.wait 2 * mS

    '************************************* Limit Check ************************************
     
    'BTLDO3P3 Output Voltage at No load & Max load
    Call LimitsTool.TestLimit(BT_LDO3P3_VOUT_0mA_3p7V, "VDDOUT_BT3P3", "PMU_" + "BT_LDO3P3_0mA_3p7V")
    Call LimitsTool.TestLimit(BT_LDO3P3_VOUT_400mA_3p7V, "VDDOUT_BT3P3", "PMU_" + "BT_LDO3P3_400mA_3p7V")
    
    'BTLDO3P3 Quiescent Current at No load
    Call LimitsTool.TestLimit(BT_LDO3P3_Q_Curr_0mA_3p7V, "ET_LINREG_VDD_V5P0", "PMU_" + "BT_LDO3P3_Q_Current")

    'BTLDO3P3 Output voltage via VDDOUT_1P8_SW2
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_1mA_3p7V.Divide(0.44576), "VDDOUT_1P8_SW2", "PMU_" + "VDDOUT_1P8_SW2_1mA_3p7V_BTLDO3P3")
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_400mA_3p7V.Divide(0.44576), "VDDOUT_1P8_SW2", "PMU_" + "VDDOUT_1P8_SW2_400mA_3p7V_BTLDO3P3")
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_400mA_5p25V.Divide(0.44576), "VDDOUT_1P8_SW2", "PMU_" + "VDDOUT_1P8_SW2_400mA_5p25V_BTLDO3P3")
    
    'BTLDO3P3 LDR via BT_REG_ON
    load_diff = 400 * mA - 1 * mA
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_1mA_3p7V.Subtract(VDDOUT_1P8_SW2_VOUT_400mA_3p7V).Abs.Divide(0.44576), "VDDOUT_1P8_SW2", "PMU_" + "BT_LDO3P3_LDR_Diff")
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_1mA_3p7V.Subtract(VDDOUT_1P8_SW2_VOUT_400mA_3p7V).Divide(0.44576).Divide(load_diff).Abs, "VDDOUT_1P8_SW2", "PMU_" + "BT_LDO3P3_LDR_3p7V")
    
    'BTLDO3P3 LNR via BT_REG_ON
    line_diff = 5.25 * v - 3.7 * v
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_400mA_5p25V.Subtract(VDDOUT_1P8_SW2_VOUT_400mA_3p7V).Abs.Divide(0.44576), "VDDOUT_1P8_SW2", "PMU_" + "BT_LDO3P3_LNR_Diff")
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_400mA_5p25V.Subtract(VDDOUT_1P8_SW2_VOUT_400mA_3p7V).Divide(0.44576).Multiply(1000).Divide(line_diff).Abs, "VDDOUT_1P8_SW2", "PMU_" + "BT_LDO3P3_LNR_3p7V_5p25V")

    testTime = TheHdw.ReadStopwatch
    TheExec.Datalog.WriteComment ""
    TheExec.Datalog.WriteComment "Pmu__LdoTests__BT_LDO3P3 Test time:" & testTime
    TheExec.Datalog.WriteComment ""
    
Exit Function
ErrorHandler:
    If TheExec.Sites.ActiveCount = 0 Then Exit Function    'If last site failed, exit the test and let IGXL cleanup
    TheExec.ErrorLogMessage "VB Error #" & Trim(Str(err.Number)) & " " & err.Description & " in instance " & TheExec.DataManager.InstanceName
    Resume Next

End Function


Public Function Pmu__LdoTests__RETLDO() As Long

On Error GoTo ErrorHandler
    Dim RETLDO_VOUT_0mA_1p0V As New SiteDouble, RETLDO_VOUT_1mA_1p0V As New SiteDouble, RETLDO_VOUT_10mA_1p0V As New SiteDouble
    
    Dim VDDOUT_1P8_SW2_VOUT_0mA_1p0V As New SiteDouble, VDDOUT_1P8_SW2_VOUT_1mA_1p0V As New SiteDouble, VDDOUT_1P8_SW2_VOUT_10mA_1p0V As New SiteDouble
    Dim VDDOUT_1P8_SW2_VOUT_10mA_0p95V As New SiteDouble, VDDOUT_1P8_SW2_VOUT_10mA_1p05V As New SiteDouble
    Dim RETLDO_Q_current_0mA_1p0V As New SiteDouble
    Dim line_diff As Double, load_diff
    
    Dim testTime As Double
    TheHdw.StartStopwatch
    
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU Regulator Test - RETLDO [F1], [F2], [F3], [F4]"
    TheExec.Datalog.WriteComment "================================================================================================"
        
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_20mA"                           'PMU_VDDIO = 1.8V
    TheHdw.wait 2 * mS

    'Register Settings - F1
    Call Pmu_registerSetup__retldo         '# setup retldo
    TheHdw.wait 2 * mS
    
    'Instrument setup of VDDOUT_RETLDO pin for load variation
    TheHdw.DCVI.pins("VDDOUT_RETLDO").BleederResistor = tlDCVIBleederResistorAuto
    
    With TheHdw.DCVI.pins("VDDOUT_RETLDO")
        .Disconnect tlDCVIConnectDefault
         .Mode = tlDCVIModeCurrent
         .Meter.Mode = tlDCVIMeterVoltage
         .Current = -200 * nA
         .Voltage = -1 * v
         .Connect
         .Gate = True
     End With
     TheHdw.wait 2 * mS
     
    '--------------------------------------------------------------------------
    'The VDDOUT_RETLDO is active during PMU sleep mode when CBUCK and WPTLDO are OFF -
    '--------------------------------------------------------------------------

    TheHdw.DCVI.pins("CSR_VLX").BleederResistor = tlDCVIBleederResistorAuto
    With TheHdw.DCVI.pins("CSR_VLX")
        .Mode = tlDCVIModeVoltage
        .Voltage = 1#
        .Current = 0.02
        .Connect tlDCVIConnectDefault
        .Gate = True
    End With
    TheHdw.wait 10 * mS
    '************************************* F2 - Quiescent Current *************************************
    
    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_1p0V_200uA"        '# reduce the current range to 200uA before Q current Measurement
    TheHdw.wait 20 * mS
    
    'Measure QCurrent directly
    RETLDO_Q_current_0mA_1p0V = TheHdw.DCVI.pins("CSR_VLX").Meter.Read(tlStrobe, 30, 100 * kHz, tlDCVIMeterReadingFormatAverage)
 
    '************************************* F1 - LDO Output Voltage @ No Load ************************************

    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_1p0V_20mA"        '# revert back the current range to 20mA at the end of Q current Measurement
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_1p0V_200mA"
    TheHdw.wait 10 * mS
    RETLDO_VOUT_0mA_1p0V = TheHdw.DCVI.pins("VDDOUT_RETLDO").Meter.Read(tlStrobe, 30, 100 * kHz, tlDCVIMeterReadingFormatAverage)
    
    '************************************  F3 - Load Regulation LDR via BT_REG_ON @ 1mA ************************************
    
    pmutb.Apply_PSET "VDDOUT_RETLDO", "VDDOUT_RETLDO_1mA_2V"                                            '1mA Load setting at output of VDDOUT_RETLDO__P30
    TheHdw.wait 10 * mS
  
    'BT_REG_ON_VOUT_10mA_1p0V = TheHdw.DCVS.pins("BT_REG_ON_UVS").Meter.Read(tlStrobe, 10, 781.25, tlDCVSMeterReadingFormatAverage)
    VDDOUT_1P8_SW2_VOUT_10mA_1p0V = pmutb.Meter_Strobe("VDDOUT_1P8_SW2", 20, 0 * mS)
        
    '************************************* F1 - LDO Output Voltage @ Max Load 10mA ************************************
    '-----------------------------------------------------------
    'VDDBAT = 3.7V, 10mA load at VDDOUT_RETLDO
    '-----------------------------------------------------------
    Dim lCnt As Long
    lCnt = 0
    
RetryMISCLDO:

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "VDDOUT_RETLDO", "VDDOUT_RETLDO_10mA_2V"                                           '100mA Load setting at output of VDDOUT_RETLDO__P30
    TheHdw.wait 5 * mS
    
    RETLDO_VOUT_10mA_1p0V = TheHdw.DCVI.pins("VDDOUT_RETLDO").Meter.Read(tlStrobe, 30, 100 * kHz, tlDCVIMeterReadingFormatAverage)

    If RETLDO_VOUT_10mA_1p0V.Compare(LessThan, 0.9).Any(True) And lCnt < 3 Then
        lCnt = lCnt + 1
        GoTo RetryMISCLDO
    End If
    
    '************************************  F3 - Load Regulation LDR via BT_REG_ON @ 10mA ************************************
    'BT_REG_ON_VOUT_10mA_1p0V = TheHdw.DCVS.pins("BT_REG_ON_UVS").Meter.Read(tlStrobe, 10, 781.25, tlDCVSMeterReadingFormatAverage)
    VDDOUT_1P8_SW2_VOUT_10mA_1p0V = pmutb.Meter_Strobe("VDDOUT_1P8_SW2", 20, 0 * mS)
  
    
    '************************************  F4 - Line Regulation LNR via BT_REG_ON ****************************************************************************************************************************************
    '-------------------------------------------------------------------------
    'VDDBAT = 3.7V, LDO_VDD1P0 = 0.95V, Max 10mA load at VDDOUT_RETLDO
    '-------------------------------------------------------------------------
    pmutb.Apply_PSET "VDDOUT_RETLDO", "VDDOUT_RETLDO_60mA_2V"                                            'reduce to 60mA load
    TheHdw.wait 2 * mS
    
    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_0P95V_200mA"
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "VDDOUT_RETLDO", "VDDOUT_RETLDO_10mA_2V"                                           '10mA Load setting at output of VDDOUT_RETLDO__P30
    TheHdw.wait 5 * mS
   
    'BT_REG_ON_VOUT_10mA_0p95V = TheHdw.DCVS.pins("BT_REG_ON_UVS").Meter.Read(tlStrobe, 10, 781.25, tlDCVSMeterReadingFormatAverage)
    VDDOUT_1P8_SW2_VOUT_10mA_0p95V = pmutb.Meter_Strobe("VDDOUT_1P8_SW2", 20, 0 * mS)

    '-------------------------------------------------------------------------
    'VDDBAT = 3.7V, LDO_VDD1P0 = 1.05V, Max 10mA load at VDDOUT_RETLDO
    '-------------------------------------------------------------------------
    pmutb.Apply_PSET "VDDOUT_RETLDO", "VDDOUT_RETLDO_60mA_2V"                                            'reduce to 60mA load
    TheHdw.wait 2 * mS
    
    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_1P05V_200mA"
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "VDDOUT_RETLDO", "VDDOUT_RETLDO_10mA_2V"                                           '10mA Load setting at output of VDDOUT_RETLDO__P30
    TheHdw.wait 5 * mS
   
    'BT_REG_ON_VOUT_10mA_1p05V = TheHdw.DCVS.pins("BT_REG_ON_UVS").Meter.Read(tlStrobe, 10, 781.25, tlDCVSMeterReadingFormatAverage)
    VDDOUT_1P8_SW2_VOUT_10mA_1p05V = pmutb.Meter_Strobe("VDDOUT_1P8_SW2", 20, 0 * mS)


    'Steadily decrease load current on VDDOUT_RETLDO pin
    pmutb.Apply_PSET "VDDOUT_RETLDO", "VDDOUT_RETLDO_60mA_2V"                                 '100mA Load setting at output of VDDOUT_RETLDO__P30
    TheHdw.wait 1 * mS
    pmutb.Apply_PSET "VDDOUT_RETLDO", "VDDOUT_RETLDO_5mA_2V"                                   '5mA Load setting at output of VDDOUT_RETLDO__P30
    TheHdw.wait 1 * mS
    
    With TheHdw.DCVI.pins("VDDOUT_RETLDO")
        .Gate = False
        .Disconnect tlDCVIConnectDefault
        .Mode = tlDCVIModeHighImpedance
        .BleederResistor = tlDCVIBleederResistorOff
    End With
    
    'Clear UDR !!!!
    Call Pmu_registerSetup__clearUDR        '# Clear the UDR registers
    TheHdw.wait 2 * mS

    With TheHdw.DCVI.pins("CSR_VLX")
        .Gate = False
        .Disconnect tlDCVIConnectDefault
        .Mode = tlDCVIModeHighImpedance
        .BleederResistor = tlDCVIBleederResistorOff
    End With

    '************************************* Limit Check *****************************************************************************************************************************************************
      
    'RETLDO Output Voltage at No load & Max load
    Call LimitsTool.TestLimit(RETLDO_VOUT_0mA_1p0V, "VDDOUT_RETLDO", "PMU_" + "RETLDO_0mA_1p0V")
    Call LimitsTool.TestLimit(RETLDO_VOUT_10mA_1p0V, "VDDOUT_RETLDO", "PMU_" + "RETLDO_10mA_1p0V")
    
    'RETLDO Quiescent Current
    Call LimitsTool.TestLimit(RETLDO_Q_current_0mA_1p0V, "CSR_VLX", "PMU_" + "RETLDO_Q_Current")
    
    'RETLDO LDR & LNR via VDDOUT_1P8_SW2
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_1mA_1p0V, "VDDOUT_1P8_SW2", "PMU_" + "VDDOUT_1P8_SW2_VOUT_1mA_1p0V_RETLDO")
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_10mA_1p0V, "VDDOUT_1P8_SW2", "PMU_" + "VDDOUT_1P8_SW2_VOUT_10mA_1p0V_RETLDO")
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_10mA_0p95V, "VDDOUT_1P8_SW2", "PMU_" + "VDDOUT_1P8_SW2_VOUT_10mA_0p95V_RETLDO")
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_10mA_1p05V, "VDDOUT_1P8_SW2", "PMU_" + "VDDOUT_1P8_SW2_VOUT_10mA_1p05V_RETLDO")
    
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_1mA_1p0V.Subtract(VDDOUT_1P8_SW2_VOUT_10mA_1p0V).Abs, "VDDOUT_1P8_SW2", "PMU_" + "VDDOUT_1P8_SW2_LDR_Diff_RETLDO")
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_10mA_1p05V.Subtract(VDDOUT_1P8_SW2_VOUT_10mA_0p95V).Abs, "VDDOUT_1P8_SW2", "PMU_" + "VDDOUT_1P8_SW2_LNR_Diff_RETLDO")
        
    testTime = TheHdw.ReadStopwatch
    TheExec.Datalog.WriteComment ""
    TheExec.Datalog.WriteComment "Pmu__LdoTests__RETLDO Test time:" & testTime
    TheExec.Datalog.WriteComment ""
    
Exit Function
ErrorHandler:
    If TheExec.Sites.ActiveCount = 0 Then Exit Function    'If last site failed, exit the test and let IGXL cleanup
    TheExec.ErrorLogMessage "VB Error #" & Trim(Str(err.Number)) & " " & err.Description & " in instance " & TheExec.DataManager.InstanceName
    Resume Next

End Function

' HVLLDO1P8
Public Function Pmu__LdoTests__HVLLDO1P8() As Long

On Error GoTo ErrorHandler
    Dim VDDOUT_HVLDO1P8_0mA_3p7V As New SiteDouble, VDDOUT_HVLDO1P8_100mA_3p7V As New SiteDouble
    Dim VDDOUT_HVLDO1P8_Q_Curr_0mA_3p7V As New SiteDouble
    Dim VDDOUT_1P8_SW2_VOUT_0mA_3p7V As New SiteDouble, VDDOUT_1P8_SW2_VOUT_1mA_3p7V As New SiteDouble
    Dim VDDOUT_1P8_SW2_VOUT_100mA_3p5V As New SiteDouble, VDDOUT_1P8_SW2_VOUT_100mA_3p7V As New SiteDouble, VDDOUT_1P8_SW2_VOUT_100mA_5p25V As New SiteDouble
    Dim line_diff As Double, load_diff As Double

    Dim testTime As Double
    TheHdw.StartStopwatch
    
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU Regulator Test - HVLLDO1P8 [G1], [G2], [G3], [G4]"
    TheExec.Datalog.WriteComment "================================================================================================"

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_20mA"                           'PMU_VDDIO = 1.8V
    TheHdw.wait 1 * mS

     'Instrument setup of VDDOUT_1P8_2 pin for load variation
    TheHdw.DCVI.pins("VDDOUT_1P8_2").BleederResistor = tlDCVIBleederResistorAuto
    With TheHdw.DCVI.pins("VDDOUT_1P8_2")
        .Disconnect tlDCVIConnectDefault
         .Mode = tlDCVIModeCurrent
         .Meter.Mode = tlDCVIMeterVoltage
         .Current = -200 * nA
         .Voltage = -0.5 * v
         .Connect
         .Gate = True
     End With
     TheHdw.wait 1 * mS
     
    'Register Settings - G1
    Call Pmu_registerSetup__hvlldo1p8        '# setup hvlldo1p8
    TheHdw.wait 5 * mS
    
    '************************************  G2 - LDO Quiscent Current ************************************
    
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_2mA"
    TheHdw.wait 1 * mS
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200uA"
    TheHdw.wait 5 * mS

    'Measure QCurrent directly
    VDDOUT_HVLDO1P8_Q_Curr_0mA_3p7V = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 50, 5 * mS)
    
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"      'Revert to 200mA
    TheHdw.wait 2 * mS

    '************************************* G1 - LDO Output Voltage @ No load *************************************

    '----------------------------------
    'VDDBAT = 3.7V, 0mA load at VDDOUT_1P8_EMMC
    '----------------------------------
    'Steadily increase the current clamp of power supply
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    TheHdw.wait 2 * mS
    
    'Register Settings - to changed to measure through BT_REG_ON [G3]
    Call Pmu_registerSetup__Analogmux(muxPin:="hvlldo1p8")
    TheHdw.wait 2 * mS
    
    VDDOUT_HVLDO1P8_0mA_3p7V = pmutb.Meter_Strobe("VDDOUT_1P8_2", 20, 0 * mS)                            'Measure VDDOUT_1P8_2 output voltage with 0mA Load (VDDBAT=3.7V)
   
     '-----------------------------------------
    'VDDBAT = 3.7V, 1mA load at VDDOUT_1P8_EMMC
    '-----------------------------------------
    
    pmutb.Apply_PSET "VDDOUT_1P8_2", "VDDOUT_HVLDO1P8_1mA_2V"                             '1mA Load setting at output of HVLDO1P8_EMMC
    TheHdw.wait 5 * mS
    'BT_REG_ON_VOUT_1mA_3p7V = TheHdw.DCVS.pins("BT_REG_ON_UVS").Meter.Read(tlStrobe, 10, 781.25, tlDCVSMeterReadingFormatAverage)
    VDDOUT_1P8_SW2_VOUT_1mA_3p7V = pmutb.Meter_Strobe("VDDOUT_1P8_SW2", 20, 0 * mS)
 
    '************************************* G1 - LDO Output Voltage @ Max Load (100mA) ***************************************************************************************************************************************************
    Dim lCnt    As Long
    Dim LNR_diff As New SiteDouble
    lCnt = 0

RetryRFLDO:
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    TheHdw.wait 3 * mS
    
   '-----------------------------------------
    'VDDBAT = 3.7V, 100mA load at VDDOUT_1P8_EMMC
    '-----------------------------------------
   
    pmutb.Apply_PSET "VDDOUT_1P8_2", "VDDOUT_HVLDO1P8_100mA_2V"                            '100mA Load setting at output of HVLDO1P8
    TheHdw.wait 2 * mS
        
    VDDOUT_HVLDO1P8_100mA_3p7V = pmutb.Meter_Strobe("VDDOUT_1P8_2", 20, 0 * mS)          'Measure VDDOUT_1P8_2 output voltage with 100mA Load (VDDBAT=3.7V)
    
    'BT_REG_ON_VOUT_100mA_3p7V = TheHdw.DCVS.pins("BT_REG_ON_UVS").Meter.Read(tlStrobe, 10, 781.25, tlDCVSMeterReadingFormatAverage)
    VDDOUT_1P8_SW2_VOUT_100mA_3p7V = pmutb.Meter_Strobe("VDDOUT_1P8_SW2", 20, 0 * mS)
 
    
    'Steadily decrease load current on VDDOUT_RF3P3 pin
    pmutb.Apply_PSET "VDDOUT_1P8_2", "VDDOUT_HVLDO1P8_100mA_2V"                            '100mA Load setting at output of HVLDO1P8
    TheHdw.wait 2 * mS
    
    '------------------------------------------
    'VDDBAT = 5.25V, 100mA load at PMU_VDDBAT5V
    '------------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_200mA"
    TheHdw.wait 2 * mS

    'Steadily increase load current on VOUT_CLDO pin
    pmutb.Apply_PSET "VDDOUT_1P8_2", "VDDOUT_HVLDO1P8_100mA_2V"                            '100mA Load setting at output of HVLDO1P8
    TheHdw.wait 2 * mS
 
    'Measure voltage at VDDOUT_1P8_SW2 @ max
    'BT_REG_ON_VOUT_100mA_5p25V = TheHdw.DCVS.pins("BT_REG_ON_UVS").Meter.Read(tlStrobe, 10, 781.25, tlDCVSMeterReadingFormatAverage)
    VDDOUT_1P8_SW2_VOUT_100mA_5p25V = pmutb.Meter_Strobe("VDDOUT_1P8_SW2", 20, 0 * mS)
     
    'Steadily decrease load current on VDDOUT_1P8_EMMC pin
    pmutb.Apply_PSET "VDDOUT_1P8_2", "VDDOUT_HVLDO1P8_50mA_2V"                                   '50mA Load setting at output of HVLDO1P8_EMMC
    TheHdw.wait 1 * mS
    pmutb.Apply_PSET "VDDOUT_1P8_2", "VDDOUT_HVLDO1P8_10mA_2V"                                   '10mA Load setting at output of HVLDO1P8_EMMC
    TheHdw.wait 1 * mS

    'Added retry loop to recover failure due to contact
    LNR_diff = VDDOUT_1P8_SW2_VOUT_100mA_5p25V.Subtract(VDDOUT_1P8_SW2_VOUT_100mA_3p7V).Abs.Divide(0.44576)
    If LNR_diff.Compare(GreaterThan, 0.0076).Any(True) And lCnt < 5 Then
        lCnt = lCnt + 1
        GoTo RetryRFLDO
    End If
    
    With TheHdw.DCVI.pins("VDDOUT_1P8_2")
        .Gate = False
        .Disconnect tlDCVIConnectDefault
        .Mode = tlDCVIModeHighImpedance
        .BleederResistor = tlDCVIBleederResistorOff
    End With

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    
    'Clear UDR !!!!
    Call Pmu_registerSetup__clearUDR        '# Clear the UDR registers
  
    '************************************* Limit Check *****************************************************************************************************************************************************
      
    'VDDOUT_1P8_2 Output Voltage at No Load and Max Load
    Call LimitsTool.TestLimit(VDDOUT_HVLDO1P8_0mA_3p7V, "VDDOUT_1P8_2", "PMU_" + "VDDOUT_HVLDO1P8_0mA_3p7V")
    Call LimitsTool.TestLimit(VDDOUT_HVLDO1P8_100mA_3p7V, "VDDOUT_1P8_2", "PMU_" + "VDDOUT_HVLDO1P8_100mA_3p7V")
    
    'VDDOUT_1P8_2 Quiescent Current
    Call LimitsTool.TestLimit(VDDOUT_HVLDO1P8_Q_Curr_0mA_3p7V, "ET_LINREG_VDD_V5P0", "PMU_" + "VDDOUT_HVLDO1P8_Q_Current")

    'VDDOUT_1P8_2 Output Voltage via VDDOUT_1P8_SW2
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_1mA_3p7V.Divide(0.44576), "VDDOUT_1P8_SW2", "PMU_" + "VDDOUT_1P8_SW2_1mA_3p7V_HVLDO1P8")
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_100mA_3p7V.Divide(0.44576), "VDDOUT_1P8_SW2", "PMU_" + "VDDOUT_1P8_SW2_100mA_3p7V_HVLDO1P8")
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_100mA_5p25V.Divide(0.44576), "VDDOUT_1P8_SW2", "PMU_" + "VDDOUT_1P8_SW2_100mA_5p0V_HVLDO1P8")

    'VDDOUT_1P8_2 LDR at Min and Max Load
    load_diff = 100 * mA - 1 * mA
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_1mA_3p7V.Subtract(VDDOUT_1P8_SW2_VOUT_100mA_3p7V).Abs.Divide(0.44576), "VDDOUT_1P8_SW2", "PMU_" + "HVLDO1P8_LDR_Diff")
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_1mA_3p7V.Subtract(VDDOUT_1P8_SW2_VOUT_100mA_3p7V).Divide(0.44576).Divide(load_diff).Abs, "VDDOUT_1P8_SW2", "PMU_" + "HVLDO1P8_LDR_3p7V")
    
    'VDDOUT_1P8_2 LNR at Min and Max Load
    line_diff = 5.25 * v - 3.7 * v
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_100mA_5p25V.Subtract(VDDOUT_1P8_SW2_VOUT_100mA_3p7V).Abs.Divide(0.44576), "VDDOUT_1P8_SW2", "PMU_" + "HVLDO1P8_LNR_Diff")
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_100mA_5p25V.Subtract(VDDOUT_1P8_SW2_VOUT_100mA_3p7V).Divide(0.44576).Multiply(1000).Divide(line_diff).Abs, "VDDOUT_1P8_SW2", "PMU_" + "HVLDO1P8_LNR_3p7V_5p25V")
    
    testTime = TheHdw.ReadStopwatch
    TheExec.Datalog.WriteComment ""
    TheExec.Datalog.WriteComment "Pmu__LdoTests__HVLDO1P8 Test time:" & testTime
    TheExec.Datalog.WriteComment ""
    
Exit Function
ErrorHandler:
    If TheExec.Sites.ActiveCount = 0 Then Exit Function    'If last site failed, exit the test and let IGXL cleanup
    TheExec.ErrorLogMessage "VB Error #" & Trim(Str(err.Number)) & " " & err.Description & " in instance " & TheExec.DataManager.InstanceName
    Resume Next

End Function



Public Function Pmu__LdoTests__HVLLDO1P8_EMMC() As Long

On Error GoTo ErrorHandler
    Dim VDDOUT_HVLDO1P8_EMMC_0mA_3p7V As New SiteDouble, VDDOUT_HVLDO1P8_EMMC_100mA_3p7V As New SiteDouble
    Dim VDDOUT_HVLDO1P8_EMMC_Q_Curr_0mA_3p7V As New SiteDouble
    
    Dim VDDOUT_1P8_SW2_VOUT_0mA_3p7V As New SiteDouble, VDDOUT_1P8_SW2_VOUT_1mA_3p7V As New SiteDouble
    Dim VDDOUT_1P8_SW2_VOUT_100mA_3p5V As New SiteDouble, VDDOUT_1P8_SW2_VOUT_100mA_3p7V As New SiteDouble, VDDOUT_1P8_SW2_VOUT_100mA_5p25V As New SiteDouble
    Dim line_diff As Double, load_diff As Double

    Dim testTime As Double
    TheHdw.StartStopwatch
    
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU Regulator Test - HVLLDO1P8_EMMC [G1], [G2], [G3], [G4]"
    TheExec.Datalog.WriteComment "================================================================================================"

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_20mA"                           'PMU_VDDIO = 1.8V
    TheHdw.wait 1 * mS

     'Instrument setup of VDDOUT_1P8_EMMC pin for load variation
    TheHdw.DCVI.pins("VDDOUT_1P8_EMMC").BleederResistor = tlDCVIBleederResistorAuto
    With TheHdw.DCVI.pins("VDDOUT_1P8_EMMC")
        .Disconnect tlDCVIConnectDefault
         .Mode = tlDCVIModeCurrent
         .Meter.Mode = tlDCVIMeterVoltage
         .Current = -200 * nA
         .Voltage = -0.5 * v
         .Connect
         .Gate = True
     End With
     TheHdw.wait 1 * mS
     
    'Register Settings - G1
    Call Pmu_registerSetup__hvlldo1p8_emmc        '# setup hvlldo1p8
    TheHdw.wait 5 * mS
    
    '************************************  G2 - LDO Quiscent Current ************************************
    
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_2mA"
    TheHdw.wait 1 * mS
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200uA"
    TheHdw.wait 5 * mS

    'Measure QCurrent directly
    VDDOUT_HVLDO1P8_EMMC_Q_Curr_0mA_3p7V = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 50, 5 * mS)
    
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"      'Revert to 200mA
    TheHdw.wait 2 * mS

    '************************************* G1 - LDO Output Voltage @ No load *************************************

    '----------------------------------
    'VDDBAT = 3.7V, 0mA load at VDDOUT_1P8_EMMC
    '----------------------------------
    'Steadily increase the current clamp of power supply
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    TheHdw.wait 2 * mS
    
    'Register Settings - to changed to measure through BT_REG_ON [G3]
    Call Pmu_registerSetup__Analogmux(muxPin:="hvlldo1p8_emmc")
    TheHdw.wait 2 * mS
    
    VDDOUT_HVLDO1P8_EMMC_0mA_3p7V = pmutb.Meter_Strobe("VDDOUT_1P8_EMMC", 20, 0 * mS)                            'Measure VDDOUT_RF3P3 output voltage with 0mA Load (VDDBAT=3.7V)
   
     '-----------------------------------------
    'VDDBAT = 3.7V, 1mA load at VDDOUT_1P8_EMMC
    '-----------------------------------------
    
    pmutb.Apply_PSET "VDDOUT_1P8_EMMC", "VDDOUT_HVLDO1P8_EMMC_1mA_2V"                             '1mA Load setting at output of HVLDO1P8_EMMC
    TheHdw.wait 5 * mS
    'BT_REG_ON_VOUT_1mA_3p7V = TheHdw.DCVS.pins("BT_REG_ON_UVS").Meter.Read(tlStrobe, 10, 781.25, tlDCVSMeterReadingFormatAverage)
    VDDOUT_1P8_SW2_VOUT_1mA_3p7V = pmutb.Meter_Strobe("VDDOUT_1P8_SW2", 20, 0 * mS)
   
    '************************************* E1 - LDO Output Voltage @ Max Load (100mA) ***************************************************************************************************************************************************
    Dim lCnt    As Long
    Dim LNR_diff As New SiteDouble
    lCnt = 0

RetryRFLDO:
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    TheHdw.wait 3 * mS
    
   '-----------------------------------------
    'VDDBAT = 3.7V, 100mA load at VDDOUT_1P8_EMMC
    '-----------------------------------------
   
    pmutb.Apply_PSET "VDDOUT_1P8_EMMC", "VDDOUT_HVLDO1P8_EMMC_100mA_2V"                            '100mA Load setting at output of HVLDO1P8_EMMC
    TheHdw.wait 2 * mS
        
    VDDOUT_HVLDO1P8_EMMC_100mA_3p7V = pmutb.Meter_Strobe("VDDOUT_1P8_EMMC", 20, 0 * mS)          'Measure VDDOUT_HVLDO1P8_EMMC output voltage with 100mA Load (VDDBAT=3.7V)
    'BT_REG_ON_VOUT_100mA_3p7V = TheHdw.DCVS.pins("BT_REG_ON_UVS").Meter.Read(tlStrobe, 10, 781.25, tlDCVSMeterReadingFormatAverage)
    VDDOUT_1P8_SW2_VOUT_100mA_3p7V = pmutb.Meter_Strobe("VDDOUT_1P8_SW2", 20, 0 * mS)
    
    'Steadily decrease load current on VDDOUT_RF3P3 pin
    pmutb.Apply_PSET "VDDOUT_1P8_EMMC", "VDDOUT_HVLDO1P8_EMMC_100mA_2V"                            '100mA Load setting at output of HVLDO1P8_EMMC
    TheHdw.wait 2 * mS
    
    '------------------------------------------
    'VDDBAT = 5.25V, 100mA load at PMU_VDDBAT5V
    '------------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_200mA"
    TheHdw.wait 2 * mS

    'Steadily increase load current on VOUT_CLDO pin
    pmutb.Apply_PSET "VDDOUT_1P8_EMMC", "VDDOUT_HVLDO1P8_EMMC_100mA_2V"                            '100mA Load setting at output of HVLDO1P8_EMMC
    TheHdw.wait 2 * mS
 
    'Measure voltage at BT_REG_ON @ max
    'BT_REG_ON_VOUT_100mA_5p25V = TheHdw.DCVS.pins("BT_REG_ON_UVS").Meter.Read(tlStrobe, 10, 781.25, tlDCVSMeterReadingFormatAverage)
    VDDOUT_1P8_SW2_VOUT_100mA_5p25V = pmutb.Meter_Strobe("VDDOUT_1P8_SW2", 20, 0 * mS)
    
    'Steadily decrease load current on VDDOUT_1P8_EMMC pin
    pmutb.Apply_PSET "VDDOUT_1P8_EMMC", "VDDOUT_HVLDO1P8_EMMC_50mA_2V"                                   '50mA Load setting at output of HVLDO1P8_EMMC
    TheHdw.wait 1 * mS
    pmutb.Apply_PSET "VDDOUT_1P8_EMMC", "VDDOUT_HVLDO1P8_EMMC_10mA_2V"                                   '10mA Load setting at output of HVLDO1P8_EMMC
    TheHdw.wait 1 * mS

    'Added retry loop to recover failure due to contact
    LNR_diff = VDDOUT_1P8_SW2_VOUT_100mA_5p25V.Subtract(VDDOUT_1P8_SW2_VOUT_100mA_3p7V).Abs.Divide(0.44576)
    If LNR_diff.Compare(GreaterThan, 0.0076).Any(True) And lCnt < 5 Then
        lCnt = lCnt + 1
        GoTo RetryRFLDO
    End If
    
    With TheHdw.DCVI.pins("VDDOUT_1P8_EMMC")
        .Gate = False
        .Disconnect tlDCVIConnectDefault
        .Mode = tlDCVIModeHighImpedance
        .BleederResistor = tlDCVIBleederResistorOff
    End With

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    
    'Clear UDR !!!!
    Call Pmu_registerSetup__clearUDR        '# Clear the UDR registers
  
    '************************************* Limit Check *****************************************************************************************************************************************************
      
    'VDDOUT_1P8_EMMC Output Voltage at No Load and Max Load
    Call LimitsTool.TestLimit(VDDOUT_HVLDO1P8_EMMC_0mA_3p7V, "VDDOUT_1P8_EMMC", "PMU_" + "VDDOUT_HVLDO1P8_EMMC_0mA_3p7V")
    Call LimitsTool.TestLimit(VDDOUT_HVLDO1P8_EMMC_100mA_3p7V, "VDDOUT_1P8_EMMC", "PMU_" + "VDDOUT_HVLDO1P8_EMMC_100mA_3p7V")
    
    'VDDOUT_1P8_EMMC Quiescent Current
    Call LimitsTool.TestLimit(VDDOUT_HVLDO1P8_EMMC_Q_Curr_0mA_3p7V, "ET_LINREG_VDD_V5P0", "PMU_" + "VDDOUT_HVLDO1P8_EMMC_Q_Current")

    'VDDOUT_1P8_EMMC Output Voltage via BT_REG_ON
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_1mA_3p7V.Divide(0.44576), "VDDOUT_1P8_SW2", "PMU_" + "VDDOUT_1P8_SW2_1mA_3p7V_HVLDO1P8_EMMC")
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_100mA_3p7V.Divide(0.44576), "VDDOUT_1P8_SW2", "PMU_" + "VDDOUT_1P8_SW2_100mA_3p7V_HVLDO1P8_EMMC")
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_100mA_5p25V.Divide(0.44576), "VDDOUT_1P8_SW2", "PMU_" + "VDDOUT_1P8_SW2_100mA_5p0V_HVLDO1P8_EMMC")

    'VDDOUT_1P8_EMMC LDR at Min and Max Load
    load_diff = 100 * mA - 1 * mA
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_1mA_3p7V.Subtract(VDDOUT_1P8_SW2_VOUT_100mA_3p7V).Abs.Divide(0.44576), "VDDOUT_1P8_SW2", "PMU_" + "HVLDO1P8_EMMC_LDR_Diff")
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_1mA_3p7V.Subtract(VDDOUT_1P8_SW2_VOUT_100mA_3p7V).Divide(0.44576).Divide(load_diff).Abs, "VDDOUT_1P8_SW2", "PMU_" + "HVLDO1P8_EMMC_LDR_3p7V")
    
    'VDDOUT_1P8_EMMC LNR at Min and Max Load
    line_diff = 5.25 * v - 3.7 * v
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_100mA_5p25V.Subtract(VDDOUT_1P8_SW2_VOUT_100mA_3p7V).Abs.Divide(0.44576), "VDDOUT_1P8_SW2", "PMU_" + "HVLDO1P8_EMMC_LNR_Diff")
    Call LimitsTool.TestLimit(VDDOUT_1P8_SW2_VOUT_100mA_5p25V.Subtract(VDDOUT_1P8_SW2_VOUT_100mA_3p7V).Divide(0.44576).Multiply(1000).Divide(line_diff).Abs, "VDDOUT_1P8_SW2", "PMU_" + "HVLDO1P8_EMMC_LNR_3p7V_5p25V")
    
    testTime = TheHdw.ReadStopwatch
    TheExec.Datalog.WriteComment ""
    TheExec.Datalog.WriteComment "Pmu__LdoTests__HVLDO1P8_EMMC Test time:" & testTime
    TheExec.Datalog.WriteComment ""
    
Exit Function
ErrorHandler:
    If TheExec.Sites.ActiveCount = 0 Then Exit Function    'If last site failed, exit the test and let IGXL cleanup
    TheExec.ErrorLogMessage "VB Error #" & Trim(Str(err.Number)) & " " & err.Description & " in instance " & TheExec.DataManager.InstanceName
    Resume Next

End Function

