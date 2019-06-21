Attribute VB_Name = "VBT_PMU_Frequency"
'Attribute VB_Name = "VBT_PMU_Frequency"
' Date     : 20181115
' Rev      :
' Author   :
' HeadURL  : For BCM43014 WLBGA/FCBGA
' SVN      : N/A

'--------------------------------------------------------------------------------------------------------------------------
'Important: Power Mode Terminology for BCM43457 is defined as below::
'
'   i.      PMU OFF     -> All REG_ONs = 0.
'   ii.     WL Active   -> WL_REG_ON = 1 only. Also refers to host (WL) mode.
'   iii.    BT Active   -> BT_REG_ON =1 only. Also refers to host (BT) mode.
'   iv.     SA_WPT      -> WPT_1P8=1, BT/WL_REG_ON=0. Also refers to standalone Wireless Power Transfer mode.
'   v.      NSA_WPT     -> WPT_1P8=1, BT/WL_REG_ON=1. Also refers to non-standalone WPT mode.
'   vi.     WL Sleep    -> WL_REG_ON = 1, i_sr_cntl < 9 >= 1, i_sr_cntl < 38 >= 0#
'   vii.    BT Sleep    -> BT_REG_ON = 1, i_sr_cntl < 9 >= 1, i_sr_cntl < 38 >= 0#
'--------------------------------------------------------------------------------------------------------------------------

Option Explicit

Private pmutb As New Toolbox_PMU_New
Public PPMU As Boolean
Public Function Pmu__FrequencyTests() As Long

On Error GoTo ErrorHandler

    If (gTTT_Enable) Then BCMTestInstance.PreBody
    
    Dim measured_freq As New PinListData
    Dim measured_freq_ck500kHz_BeforeCal As New PinListData
    Dim measured_freq_ck500kHz_AfterCal As New PinListData
    Dim measured_freq_3MHz_BeforeCal As New PinListData
    Dim measured_freq_3MHz_AfterCal As New PinListData
    Dim PinToMeasure As String
    
    Call ChipInit(chipId, runClocks:=True)
    Set AXI = JTAG
    
    PinToMeasure = "GPIO_7"
    TheHdw.pins(PinToMeasure).Digital.InitState = chInitoff
    TheHdw.pins(PinToMeasure).Digital.StartState = chstartNone
    TheHdw.PinLevels.pins(PinToMeasure).ModifyLevel chVoh, 1.8 * 0.6
    TheHdw.PinLevels.pins(PinToMeasure).ModifyLevel chVol, 1.8 * 0.6
    
    '************************************* CBUCK PWM Frequency measurement ***************************************************************************************************************************************

    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU Frequency Test - BT_LDO3P3 [I1], [I2], [I3], [I4]"
    TheExec.Datalog.WriteComment "================================================================================================"

    'Settings: VDDBAT=3.7V, 50mA load at CSR_VLX
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_650mA"
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_200mA"
    TheHdw.wait 2 * mS

    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_250mA_2V"                                 '250mA Load setting at "LDO_VDD1P12"(output of cbuck regulator)
    TheHdw.wait 5 * mS

    'Clear UDR !!!!
    Call Pmu_registerSetup__clearUDR        '# Clear the UDR registers
    TheHdw.wait 2 * mS

'    'Make sure turn on the BBPLL first before testing.
'    'The 16MHz clk needed for PMU cal comes from BBPLL (160MHz/10), just after POR BBPLL will be OFF, s include turns ON BBPLL
'    'This was set in the PA_Module in the following routine
    Call Pmu_registerSetup__turnON__bppll
    
    'Measure Frequency at GPIO_7
    '-----------------------------------------------------
    'I1 - Frequency ck500k oscillator Before calibration
    '-----------------------------------------------------
    Call Pmu_registerSetup__ClockOut("ck500kOsc_beforeCal")
    Call Pmu__FreqMeas(PinToMeasure, measured_freq_ck500kHz_BeforeCal)
   
    '-----------------------------------------------------
    'I2 - Frequency ck500k oscillator After calibration
    '-----------------------------------------------------
    Call Pmu_registerSetup__ClockOut("ck500kOsc_afterCal")
    Call Pmu__FreqMeas(PinToMeasure, measured_freq_ck500kHz_AfterCal)

    'reset ck500k cal
    'Call UDR_WriteReg(UserDR_10, "C00000000000000000000000000")    '4369
    'Call UDR_WriteReg(UserDR_10, "30000000000000000000")           '4362 - Do we need this for 4362?
    
    '-----------------------------------------------------
    'I3 - Frequency SWR3p2M oscillator Before calibration
    '-----------------------------------------------------
    Call Pmu_registerSetup__ClockOut("SWR3p2MOsc_beforeCal")
    Call Pmu__FreqMeas(PinToMeasure, measured_freq_3MHz_BeforeCal)
    
    '-----------------------------------------------------
    'I4 - Frequency SWR3p2M oscillator After calibration
    '-----------------------------------------------------
    Call Pmu_registerSetup__ClockOut("SWR3p2MOsc_afterCal")
    Call Pmu__FreqMeas(PinToMeasure, measured_freq_3MHz_AfterCal)
      
    Call LimitsTool.TestLimit(measured_freq_ck500kHz_BeforeCal, PinToMeasure, "PMU_Freq_ck500kHz_BeforeCal")
    Call LimitsTool.TestLimit(measured_freq_ck500kHz_AfterCal, PinToMeasure, "PMU_Freq_ck500kHz_AfterCal")
    Call LimitsTool.TestLimit(measured_freq_3MHz_BeforeCal, PinToMeasure, "PMU_Freq_OscSwr3MHz_BeforeCal")
    Call LimitsTool.TestLimit(measured_freq_3MHz_AfterCal, PinToMeasure, "PMU_Freq_OscSwr3MHz_AfterCal")

    '************************************* Restore Voltages to nominal *******************************************************************************************************************************************
    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_0mA_2V"
    TheHdw.wait 2 * mS

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    TheHdw.wait 2 * mS
    
    If (gTTT_Enable) Then BCMTestInstance.PostBody
    
Exit Function

ErrorHandler:
    If TheExec.Sites.ActiveCount = 0 Then Exit Function         'If last site failed, exit the test and let IGXL cleanup
    TheExec.ErrorLogMessage "VB Error #" & Trim(Str(err.Number)) & " " & err.Description & " in instance " & TheExec.DataManager.InstanceName
    Resume Next

End Function

Public Sub Pmu__FreqMeas(PinToMeasure As String, MeasFreq As PinListData)

On Error GoTo ErrorHandler
    
    Dim ReadFreqCnt As New PinListData
    Dim TimeInterval As Double
    
    TimeInterval = 1 * mS
    
    TheHdw.pins(PinToMeasure).Digital.InitState = chInitoff
    TheHdw.pins(PinToMeasure).Digital.StartState = chstartNone
    
    '------------------------------------------- Frequency counter setting ---------------------------------------------------------------------------------------------------------------------
    Call TheHdw.Digital.pins(PinToMeasure).FreqCtr.Clear
    With TheHdw.Digital.pins(PinToMeasure).FreqCtr
        .EventSource = VOH
        .EventSlope = Positive
        .enable = IntervalEnable
        .Interval = TimeInterval
    End With
    
    '------------------------------------------- Starting Frequency counter and Read measurements for all sites ---------------------------------------------------------------------------------
    'Start the frequency counter and read measurements for all sites.
    TheHdw.Digital.pins(PinToMeasure).FreqCtr.Start
    TheHdw.wait 5 * mS
    ReadFreqCnt = TheHdw.Digital.pins(PinToMeasure).FreqCtr.Read
    
    '------------------------------------------- Read back the time interval from HW to account for resolution rounding error -------------------------------------------------------------------
    TimeInterval = TheHdw.Digital.pins(PinToMeasure).FreqCtr.Interval
    
    '------------------------------------------- Divide count by time interval to calculate frequency -------------------------------------------------------------------------------------------
    MeasFreq = ReadFreqCnt.Math.Divide(TimeInterval)
    
    Exit Sub
ErrorHandler:
    If TheExec.Sites.ActiveCount = 0 Then Exit Sub         'If last site failed, exit the test and let IGXL cleanup
    TheExec.ErrorLogMessage "VB Error #" & Trim(Str(err.Number)) & " " & err.Description & " in instance " & TheExec.DataManager.InstanceName
    Resume Next
    
End Sub

