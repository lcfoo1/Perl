Attribute VB_Name = "VBT_PMU_SWREG"
'Attribute VB_Name = "VBT_PMU_SWREG"
' Date     : 20180702
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
Public PMU_MEASURE As String
Public PMU_PatName As String
Public Function Pmu__SwitchRegTests() As Long

On Error GoTo ErrorHandler

    If (gTTT_Enable) Then BCMTestInstance.PreBody
    
    Dim supply_pmu_ldo_pins As String
    LimitSheetEnabled = True
    
'    TurnOffPAMode
'    If TheExec.EnableWord("PMU_POP_EN") Then
'        TheHdw.Digital.applyLevelsTiming True, False, True, tlPowered, , , , , , , "TS_PMU_POP", "", "", ""
'    Else
'        TheHdw.Digital.applyLevelsTiming True, False, True, tlPowered, , , , , , , "TS_PMU", "", "", ""
'    End If
    TurnOnPAMode
    Set AXI = JTAG
    
    TheHdw.Digital.pins("BT_REG_ON_HSD").Disconnect
    
    supply_pmu_ldo_pins = "ASR_VLX, CSR_VLX, VDDOUT_AON, VDDOUT_BT3P3, VDDOUT_RF3P3"
    TheHdw.DCVI.pins(supply_pmu_ldo_pins).BleederResistor = tlDCVIBleederResistorOff    '# Turn off the bleeder resistor
     

    
    If TheExec.EnableWord("PMU_POP_EN") Then
        '***********************************************************************************************************
        '                                               POP ENABLED
        '***********************************************************************************************************

        'Load SwitchReg POP pattern
        PMU_PatName = ".\ExportedFiles\PMU\BCM4362_SWREG_LDO_POP.PAT"
       
        If TheHdw.Digital.Patgen.IsRunning Then TheHdw.Digital.Patgen.Halt     ' Stop any pattern which is previously running.
        TheHdw.Patterns(PMU_PatName).load
        TheHdw.wait 2 * mS
    
        'Load Pattern for PMU measurement
        PMU_MEASURE = ".\ExportedFiles\PMU\BCM43014_PMU_MEASURE.PAT"
        If TheHdw.Digital.Patgen.IsRunning Then TheHdw.Digital.Patgen.Halt     ' Stop any pattern which is previously running.
        TheHdw.Patterns(PMU_MEASURE).load
        TheHdw.wait 2 * mS
               
        '=========================================== Power Down Current ===========================================
        Call PMU__PowerDownCurrent__POP
        If TheExec.Sites.ActiveCount = 0 Then Exit Function
        
        '=============================================== Power Mode ===============================================
        Call ChipInit(PCIe, runClocks:=True)
        If TheExec.Sites.ActiveCount = 0 Then Exit Function
        
        Call PMU__PowerModeTest_PS
        If TheExec.Sites.ActiveCount = 0 Then Exit Function
        
        Call PMU__PowerModeTest_LP      'Don't use POP
        If TheExec.Sites.ActiveCount = 0 Then Exit Function
        
        Call PMU__PowerModeTest_LV
        If TheExec.Sites.ActiveCount = 0 Then Exit Function
    
    '    '=================================================== ASR ==================================================
        'Improve ASR efficiency
    
        Call PMU__SwitchRegTests_ASR_PWM__POP
        If TheExec.Sites.ActiveCount = 0 Then Exit Function
        
        Call PMU__SwitchRegTests_ASR_PFM_LPPFM__POP
        If TheExec.Sites.ActiveCount = 0 Then Exit Function
    
    '    '=================================================== CSR ===================================================
        
        Call PMU__SwitchRegTests_CSR_PWM__POP
        If TheExec.Sites.ActiveCount = 0 Then Exit Function
        
        Call PMU__SwitchRegTests_CSR_PFM_LPPFM__POP
        If TheExec.Sites.ActiveCount = 0 Then Exit Function
 
        '================================================== Q-current =============================================
        Call PMU__SwitchRegTests_Q_current__POP
        If TheExec.Sites.ActiveCount = 0 Then Exit Function
 
    Else
    
        'Load Pattern for PMU measurement
        PMU_MEASURE = ".\ExportedFiles\PMU\BCM43014_PMU_MEASURE.PAT"
        If TheHdw.Digital.Patgen.IsRunning Then TheHdw.Digital.Patgen.Halt     ' Stop any pattern which is previously running.
        TheHdw.Patterns(PMU_MEASURE).load
        TheHdw.wait 2 * mS
        
        '=========================================== Power Down Current ===========================================
        Call PMU__PowerDownCurrent '[A1-A3]
        If TheExec.Sites.ActiveCount = 0 Then Exit Function

        '=============================================== Power Mode ===============================================
'''        Call ChipInit(PCIe, runClocks:=True)
'''        If TheExec.Sites.ActiveCount = 0 Then Exit Function

        Call PMU__PowerModeTest_PS0A '[A4-A6]
        If TheExec.Sites.ActiveCount = 0 Then Exit Function

        Call PMU__PowerModeTest_PS0C '[A7-A9]
        If TheExec.Sites.ActiveCount = 0 Then Exit Function
        
        Call PMU__PowerModeTest_PS1A '[A10-A12]
        If TheExec.Sites.ActiveCount = 0 Then Exit Function
        
        Call PMU__PowerModeTest_PS1C '[A13-A14]
        If TheExec.Sites.ActiveCount = 0 Then Exit Function

        '=================================================== ASR ==================================================

        Call PMU__SwitchRegTests_ASR_PWM
        If TheExec.Sites.ActiveCount = 0 Then Exit Function

        Call PMU__SwitchRegTests_ASR_PFM_LPPFM
        If TheExec.Sites.ActiveCount = 0 Then Exit Function

        '=================================================== CSR ===================================================

        Call PMU__SwitchRegTests_CSR_PWM
        If TheExec.Sites.ActiveCount = 0 Then Exit Function

        Call PMU__SwitchRegTests_CSR_PFM_LPPFM
        If TheExec.Sites.ActiveCount = 0 Then Exit Function

'''''        '================================================== Q-current =============================================
'''''        Call PMU__SwitchRegTests_Q_current
'''''        If TheExec.Sites.ActiveCount = 0 Then Exit Function
        
    End If
    

    If (gTTT_Enable) Then BCMTestInstance.PostBody

Exit Function

ErrorHandler:
    If TheExec.Sites.ActiveCount = 0 Then Exit Function         'If last site failed, exit the test and let IGXL cleanup
    TheExec.ErrorLogMessage "VB Error #" & Trim(Str(err.Number)) & " " & err.Description & " in instance " & TheExec.DataManager.InstanceName
    Resume Next

End Function



Public Function PMU__PowerDownCurrent() As Long

On Error GoTo ErrorHandler
    Dim PWD_I_PMU_VDDIOA_0V As New SiteDouble, PWD_I_PMU_VDDIOA_1V8 As New SiteDouble, PDWN_I_PMU_VDDIO_1p8V As New SiteDouble
    Dim PDWN_I_VBAT_VDDIO_0V As New SiteDouble, PDWN_I_VBAT_VDDIO_1p8V As New SiteDouble, PDWN_I_PMU_VDDIOA_1p8V As New SiteDouble
 
    Dim testTime As Double
    TheHdw.StartStopwatch
        
    igxltb.maintainState "", "BT_REG_ON_HSD, WL_REG_ON", ""
    TheHdw.wait 5 * mS
   
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU System Test - PMU Power-Down Current [A1], [A2], [A3]"
    TheExec.Datalog.WriteComment "================================================================================================"
    
'---------------------------------- Power Down Current from VBAT @ PMU_VDDIO =1.8V (A2), PMU_VDDIO @ PMU_VDDIO =1.8V (A3) ----------------------------------

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200uA"
    TheHdw.wait 5 * mS
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_20uA"
    TheHdw.wait 20 * mS
    
    PDWN_I_PMU_VDDIO_1p8V = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 2 * mS)
    PDWN_I_VBAT_VDDIO_1p8V = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 50, 2 * mS)
   
'---------------------------------- Power Down Current from VBAT @ PMU_VDDIO =0V (A1)----------------------------------

   ' added for power down
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_0V_20mA"
    TheHdw.wait 5 * mS

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200uA"
    TheHdw.wait 2 * mS

    PDWN_I_VBAT_VDDIO_0V = pmutb.Meter_Strobe("PMU_VDDBAT5", 50, 10 * mS)                    'If wait time is >1s, then can bring down the current to typical value of 2uA

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_2mA"                 'revert back to 20 mA
    TheHdw.wait 1 * mS
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_20mA"                'revert back to 20 mA
    TheHdw.wait 1 * mS
    
    Call LimitsTool.TestLimit(PDWN_I_VBAT_VDDIO_0V, "ET_LINREG_VDD_V5P0", "VBAT_PDWN_I_VDDIO_0V")
    Call LimitsTool.TestLimit(PDWN_I_VBAT_VDDIO_1p8V, "ET_LINREG_VDD_V5P0", "VBAT_PDWN_I_VDDIO_1p8V")
    Call LimitsTool.TestLimit(PDWN_I_PMU_VDDIO_1p8V, "PMU_VDDIOP", "PMU_VDDIO_PDWN_I_VDDIO_1p8V")
    'TheExec.Flow.TestLimit PDWN_I_VBAT_VDDIO_0V, 0.2, 15, tlSignGreaterEqual, tlSignLessEqual, , unitNone, "%f", "VBAT_PDWN_I_VDDIO_0V", , , 0#, unitNone, , , tlForceNone
    
    testTime = TheHdw.ReadStopwatch
    TheExec.Datalog.WriteComment ""
    TheExec.Datalog.WriteComment "PMU_PowerDownCurrent Test time:" & testTime
    TheExec.Datalog.WriteComment ""
    
Exit Function
    
ErrorHandler:
    If TheExec.Sites.ActiveCount = 0 Then Exit Function              'If last site failed, exit the test and let IGXL cleanup
    TheExec.ErrorLogMessage "VB Error #" & Trim(Str(err.Number)) & " " & err.Description & " in instance " & TheExec.DataManager.InstanceName
    Resume Next
    
End Function



Public Function PMU__PowerModeTest_PS0A() As Long
On Error GoTo ErrorHandler

    Dim RTime As Double, ElapsedTime As Double
    Dim PWD_I_PMU_VDDIOA_0V As New SiteDouble
    Dim PWD_I_PMU_VDDIOA_1V8 As New SiteDouble
    Dim Sleep_I_VBAT As New SiteDouble
    Dim Sleep_I_VDDIO_PMU As New SiteDouble
    Dim PDWN_I_PMU_VDDIO_1p8V As New SiteDouble
   
    Dim PS0A_Sleep_I_VBAT_SR As New SiteDouble
    Dim PS0A_SLEEP_I_PMU_VDDIO_1p8V As New SiteDouble
    Dim PS0A_SLEEP_I_PMU_VDDIO_1p8V_1 As New SiteDouble
    
    Dim PS0A_LDO_VDD1P22_0mA_3p7V_SLEEP As New SiteDouble
    Dim PS0A_LDO_VDD1P0_0mA_3p7V_SLEEP As New SiteDouble
    Dim PS0A_VDDOUT_RETLDO_0mA_3p7V_SLEEP As New SiteDouble
    Dim PS0A_VDDOUT_AON_0mA_3p7V_SLEEP As New SiteDouble
    Dim PS0A_LDO_VDD_1P22_1mA_3p7V_SLEEP As New SiteDouble
    Dim PS0A_VDDOUT_AON_1mA_3p7V_SLEEP  As New SiteDouble

    Dim Readvals() As New SiteLong
    Dim B5i, B5ii, B5iii, B5iv As String

    Dim Sleep_I_VDDIO As New SiteDouble
    Dim PDWN_I_VBAT_VDDIO_0V As New SiteDouble
    Dim PDWN_I_VBAT_VDDIO_1p8V As New SiteDouble
    Dim PDWN_I_PMU_VDDIOA_1p8V As New SiteDouble
    
    'For LPLDO Test
    Dim BT_REG_ON_VOUT_1mA_1p8V As New SiteDouble
    Dim BT_REG_ON_VOUT_10mA_1p8V As New SiteDouble
    Dim BT_REG_ON_VOUT_10mA_1p62V As New SiteDouble
    Dim BT_REG_ON_VOUT_10mA_1p98V As New SiteDouble
    Dim LPLDO3_VBAT_I_B1_0mA_1p8V As New SiteDouble
    Dim LPLDO3_VBAT_I_B2_0mA_1p8V As New SiteDouble
    Dim LPLDO_Q_current_0mA_1p8V As New SiteDouble
    Dim line_diff As Double

    Dim WRF_VDD3P3_Initial_curr As New SiteDouble
    Dim WRF_VDD1P35_Initial_curr As New SiteDouble
    Dim WRF_VDD1P2_Initial_volt As New SiteDouble
    Dim WRF_VDD1P2_When_WPT_3P3_0V_curr As New SiteDouble
    Dim supply_pmu_ldo_pins As String
    Dim Show_ChipID As Boolean
    Dim trim_enable As Boolean
 
    Dim testTime As Double
    TheHdw.StartStopwatch
    
'''    With TheHdw.DCVI.pins("VDDOUT_MISCLDO")
'''        .BleederResistor = tlDCVIBleederResistorAuto
'''        .Mode = tlDCVIModeCurrent
'''        .Current = -0.5 * mA
'''        .Voltage = 0.7
'''        .Connect tlDCVIConnectDefault
'''        TheHdw.wait 2 * mS
'''        .Gate = True
'''    End With

    
    'igxltb.maintainState "WL_REG_ON, JTAG_TRST_L", "BT_REG_ON", ""
    'Must remember to increase the PMU_VDDIO currange range since we would like to turn on device (WL_REG_ON=High)
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_2mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_2mA"

    Call Pmu_registerSetup__PS0A_Mode                  '# Setup PS Mode
    TheHdw.wait 5 * mS

    With TheHdw.DCVI.pins("CSR_VLX, ASR_VLX, VDDOUT_RETLDO, VDDOUT_AON") 'CSR_VLX = LDO_VDD1P0, ASR_VLX=LDO_VDD_1P22
        .BleederResistor = tlDCVIBleederResistorAuto
        .Disconnect tlDCVIConnectDefault
        .Mode = tlDCVIModeHighImpedance
        .Connect tlDCVIConnectHighSense
    End With
    TheHdw.wait 10 * mS
    
    PS0A_LDO_VDD1P0_0mA_3p7V_SLEEP = pmutb.Meter_Strobe("CSR_VLX", 20, 1 * mS)                '#  Measurement of LDO_VDD1P0
    PS0A_LDO_VDD1P22_0mA_3p7V_SLEEP = pmutb.Meter_Strobe("ASR_VLX", 20, 1 * mS)               '#  Measurement of LDO_VDD_1P22
    PS0A_VDDOUT_RETLDO_0mA_3p7V_SLEEP = pmutb.Meter_Strobe("VDDOUT_RETLDO", 20, 1 * mS)       '#  Measurement of VDDOUT_RETLDO
    PS0A_VDDOUT_AON_0mA_3p7V_SLEEP = pmutb.Meter_Strobe("VDDOUT_AON", 20, 1 * mS)             '#  Measurement of VDDOUT_AON
    
    Call LimitsTool.TestLimit(PS0A_LDO_VDD1P0_0mA_3p7V_SLEEP, "CSR_VLX", "PS0A_LDO_VDD1P0_SLEEP_0mA_3p7V")
    Call LimitsTool.TestLimit(PS0A_LDO_VDD1P22_0mA_3p7V_SLEEP, "ASR_VLX", "PS0A_LDO_VDD1P22_SLEEP_0mA_3p7V")
    Call LimitsTool.TestLimit(PS0A_VDDOUT_RETLDO_0mA_3p7V_SLEEP, "VDDOUT_RETLDO", "PS0A_VDDOUT_RETLDO_SLEEP_0mA_3p7V")
    Call LimitsTool.TestLimit(PS0A_VDDOUT_AON_0mA_3p7V_SLEEP, "VDDOUT_AON", "PS_VDDOUT_AON_SLEEP_0mA_3p7V")
    If TheExec.Sites.ActiveCount = 0 Then Exit Function
    
    With TheHdw.DCVI.pins("CSR_VLX, ASR_VLX, ,VDDOUT_RETLDO, VDDOUT_AON") 'CSR_VLX = LDO_VDD1P0, ASR_VLX=LDO_VDD_1P22
        .Disconnect tlDCVIConnectHighSense
        .Mode = tlDCVIModeHighImpedance
        .BleederResistor = tlDCVIBleederResistorOff
    End With
    TheHdw.wait 2 * mS
    
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200uA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_20uA"
    TheHdw.wait 10 * mS
    '----------------------------------------- A4 & A5 PMU Sleep Mode from VBAT & PMU_VDDIO (when PMU_VDDIO=1.8V)----------------------------------------------------------------------------------------------
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU System Test - PMU Power Mode Test - Sleep (PS0A) Mode [A4]"
    TheExec.Datalog.WriteComment "================================================================================================"

    PS0A_Sleep_I_VBAT_SR = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 100, 1 * mS)                      '# Measurement of PMU_VDDBAT5
    PS0A_SLEEP_I_PMU_VDDIO_1p8V = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 5 * mS, 128, 781.25)       '# Measurement of PMU_VDDIO

    Call LimitsTool.TestLimit(PS0A_Sleep_I_VBAT_SR, "ET_LINREG_VDD_V5P0", "PS0A_VBAT_SLEEP_I_VDDIO_1p8V")
    Call LimitsTool.TestLimit(PS0A_SLEEP_I_PMU_VDDIO_1p8V, "PMU_VDDIOP", "PS0A_PMU_VDDIO_SLEEP_I_VDDIO_1p8V")
    If TheExec.Sites.ActiveCount = 0 Then Exit Function

    '# Restore
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_20mA"

    '-------------------------------------------- PS0A AON Bypass Ron (A5) --------------------------------------------
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU System Test - PMU Power Mode Test - PS0A AON Bypass Ron [A5]"
    TheExec.Datalog.WriteComment "================================================================================================"

    With TheHdw.DCVI.pins("ASR_VLX")
        .BleederResistor = tlDCVIBleederResistorAuto
        .Mode = tlDCVIModeHighImpedance
        .Connect tlDCVIConnectHighSense
    End With
    pmutb.Connect_LDO ("VDDOUT_AON")

    pmutb.Apply_PSET "VDDOUT_AON", "VDDOUT_AON_1mA_2V"                              '# 1mA Load setting at output of VDDOUT_MISCLDO
    TheHdw.wait 5 * mS
    PS0A_LDO_VDD_1P22_1mA_3p7V_SLEEP = pmutb.Meter_Strobe("ASR_VLX", 20, 1 * mS)      '# measure ASR_VLX=LDO_VDD_1P22
    PS0A_VDDOUT_AON_1mA_3p7V_SLEEP = pmutb.Meter_Strobe("VDDOUT_AON", 20, 1 * mS)     '# measure VDDOUT_AON

    With TheHdw.DCVI.pins("ASR_VLX, VDDOUT_AON")
        .Gate = False
        .Disconnect tlDCVIConnectDefault
        .BleederResistor = tlDCVIBleederResistorAuto
        .Mode = tlDCVIModeHighImpedance
    End With

    '---------------
    '# PMU Wake for A6
    '----------------
    Call Pmu_registerSetup__WakeUp     '# WakeUp

    Call LimitsTool.TestLimit(PS0A_LDO_VDD_1P22_1mA_3p7V_SLEEP, "ASR_VLX", "PS0A_LDO_VDD_1P22_SLEEP_1mA_3p7V")
    Call LimitsTool.TestLimit(PS0A_VDDOUT_AON_1mA_3p7V_SLEEP, "VDDOUT_AON", "PS0A_VDDOUT_AON_SLEEP_1mA_3p7V")
    Call LimitsTool.TestLimit(PS0A_LDO_VDD_1P22_1mA_3p7V_SLEEP.Subtract(PS0A_VDDOUT_AON_1mA_3p7V_SLEEP).Divide(1 * mA).Abs, "PS_VDDOUT_AON", "PS_AON_Bypass_RON")

'''    If Show_ChipID Then
'''        For Each Site In TheExec.Sites
'''            TheExec.Datalog.WriteComment "AXI Chip ID (Real Chip ID): " & Hex(AXI.ReadReg("18000000")(Site))
'''        Next Site
'''    End If

    testTime = TheHdw.ReadStopwatch
    TheExec.Datalog.WriteComment ""
    TheExec.Datalog.WriteComment "PMU_PowerModeTest_PS0A Test time:" & testTime
    TheExec.Datalog.WriteComment ""
    Exit Function
    
ErrorHandler:
    If TheExec.Sites.ActiveCount = 0 Then Exit Function              'If last site failed, exit the test and let IGXL cleanup
    TheExec.ErrorLogMessage "VB Error #" & Trim(Str(err.Number)) & " " & err.Description & " in instance " & TheExec.DataManager.InstanceName
    Resume Next
End Function

Public Function PMU__PowerModeTest_PS0C() As Long
On Error GoTo ErrorHandler

    Dim RTime As Double, ElapsedTime As Double
    Dim PWD_I_PMU_VDDIOA_0V As New SiteDouble
    Dim PWD_I_PMU_VDDIOA_1V8 As New SiteDouble
    Dim Sleep_I_VBAT As New SiteDouble
    Dim Sleep_I_VDDIO_PMU As New SiteDouble
    Dim PDWN_I_PMU_VDDIO_1p8V As New SiteDouble
   
    Dim PS0C_Sleep_I_VBAT_SR As New SiteDouble
    Dim PS0C_SLEEP_I_PMU_VDDIO_1p8V As New SiteDouble
    Dim PS0C_SLEEP_I_PMU_VDDIO_1p8V_1 As New SiteDouble
    
    Dim PS0C_LDO_VDD1P22_0mA_3p7V_SLEEP As New SiteDouble
    Dim PS0C_LDO_VDD1P0_0mA_3p7V_SLEEP As New SiteDouble
    Dim PS0C_VDDOUT_RETLDO_0mA_3p7V_SLEEP As New SiteDouble
    Dim PS0C_VDDOUT_AON_0mA_3p7V_SLEEP As New SiteDouble
    Dim PS0C_LDO_VDD_1P22_1mA_3p7V_SLEEP As New SiteDouble
    Dim PS0C_VDDOUT_AON_1mA_3p7V_SLEEP  As New SiteDouble

    Dim Readvals() As New SiteLong
    Dim B5i, B5ii, B5iii, B5iv As String

    Dim Sleep_I_VDDIO As New SiteDouble
    Dim PDWN_I_VBAT_VDDIO_0V As New SiteDouble
    Dim PDWN_I_VBAT_VDDIO_1p8V As New SiteDouble
    Dim PDWN_I_PMU_VDDIOA_1p8V As New SiteDouble
    
    'For LPLDO Test
    Dim BT_REG_ON_VOUT_1mA_1p8V As New SiteDouble
    Dim BT_REG_ON_VOUT_10mA_1p8V As New SiteDouble
    Dim BT_REG_ON_VOUT_10mA_1p62V As New SiteDouble
    Dim BT_REG_ON_VOUT_10mA_1p98V As New SiteDouble
    Dim LPLDO3_VBAT_I_B1_0mA_1p8V As New SiteDouble
    Dim LPLDO3_VBAT_I_B2_0mA_1p8V As New SiteDouble
    Dim LPLDO_Q_current_0mA_1p8V As New SiteDouble
    Dim line_diff As Double

    Dim WRF_VDD3P3_Initial_curr As New SiteDouble
    Dim WRF_VDD1P35_Initial_curr As New SiteDouble
    Dim WRF_VDD1P2_Initial_volt As New SiteDouble
    Dim WRF_VDD1P2_When_WPT_3P3_0V_curr As New SiteDouble
    Dim supply_pmu_ldo_pins As String
    Dim Show_ChipID As Boolean
    Dim trim_enable As Boolean
 
    Dim testTime As Double
    TheHdw.StartStopwatch
    
'''    With TheHdw.DCVI.pins("VDDOUT_MISCLDO")
'''        .BleederResistor = tlDCVIBleederResistorAuto
'''        .Mode = tlDCVIModeCurrent
'''        .Current = -0.5 * mA
'''        .Voltage = 0.7
'''        .Connect tlDCVIConnectDefault
'''        TheHdw.wait 2 * mS
'''        .Gate = True
'''    End With

    
    'igxltb.maintainState "WL_REG_ON, JTAG_TRST_L", "BT_REG_ON", ""
    'Must remember to increase the PMU_VDDIO currange range since we would like to turn on device (WL_REG_ON=High)
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_2mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_2mA"

    Call Pmu_registerSetup__PS0C_Mode                  '# Setup PS Mode
    TheHdw.wait 5 * mS

    With TheHdw.DCVI.pins("CSR_VLX, ASR_VLX, VDDOUT_RETLDO, VDDOUT_AON") 'CSR_VLX = LDO_VDD1P0, ASR_VLX=LDO_VDD_1P22
        .BleederResistor = tlDCVIBleederResistorAuto
        .Disconnect tlDCVIConnectDefault
        .Mode = tlDCVIModeHighImpedance
        .Connect tlDCVIConnectHighSense
    End With
    TheHdw.wait 10 * mS
    
    PS0C_LDO_VDD1P0_0mA_3p7V_SLEEP = pmutb.Meter_Strobe("CSR_VLX", 20, 1 * mS)                '#  Measurement of LDO_VDD1P0
    PS0C_LDO_VDD1P22_0mA_3p7V_SLEEP = pmutb.Meter_Strobe("ASR_VLX", 20, 1 * mS)               '#  Measurement of LDO_VDD_1P22
    PS0C_VDDOUT_RETLDO_0mA_3p7V_SLEEP = pmutb.Meter_Strobe("VDDOUT_RETLDO", 20, 1 * mS)       '#  Measurement of VDDOUT_RETLDO
    PS0C_VDDOUT_AON_0mA_3p7V_SLEEP = pmutb.Meter_Strobe("VDDOUT_AON", 20, 1 * mS)             '#  Measurement of VDDOUT_AON
    
    Call LimitsTool.TestLimit(PS0C_LDO_VDD1P0_0mA_3p7V_SLEEP, "CSR_VLX", "PS0C_LDO_VDD1P0_SLEEP_0mA_3p7V")
    Call LimitsTool.TestLimit(PS0C_LDO_VDD1P22_0mA_3p7V_SLEEP, "ASR_VLX", "PS0C_LDO_VDD1P22_SLEEP_0mA_3p7V")
    Call LimitsTool.TestLimit(PS0C_VDDOUT_RETLDO_0mA_3p7V_SLEEP, "VDDOUT_RETLDO", "PS0C_VDDOUT_RETLDO_SLEEP_0mA_3p7V")
    Call LimitsTool.TestLimit(PS0C_VDDOUT_AON_0mA_3p7V_SLEEP, "VDDOUT_AON", "PS0C_VDDOUT_AON_SLEEP_0mA_3p7V")
    If TheExec.Sites.ActiveCount = 0 Then Exit Function
    
    With TheHdw.DCVI.pins("CSR_VLX, ASR_VLX, ,VDDOUT_RETLDO, VDDOUT_AON") 'CSR_VLX = LDO_VDD1P0, ASR_VLX=LDO_VDD_1P22
        .Disconnect tlDCVIConnectHighSense
        .Mode = tlDCVIModeHighImpedance
        .BleederResistor = tlDCVIBleederResistorOff
    End With
    TheHdw.wait 2 * mS
    
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200uA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_20uA"
    TheHdw.wait 10 * mS
    '----------------------------------------- A7 & A8 PMU Sleep Mode 0C from VBAT & PMU_VDDIO (when PMU_VDDIO=1.8V)----------------------------------------------------------------------------------------------
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU System Test - PMU Power Mode Test - Sleep (PS0C) Mode [A7]"
    TheExec.Datalog.WriteComment "================================================================================================"

    PS0C_Sleep_I_VBAT_SR = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 100, 1 * mS)                      '# Measurement of PMU_VDDBAT5
    PS0C_SLEEP_I_PMU_VDDIO_1p8V = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 5 * mS, 128, 781.25)       '# Measurement of PMU_VDDIO

    Call LimitsTool.TestLimit(PS0C_Sleep_I_VBAT_SR, "ET_LINREG_VDD_V5P0", "PS0C_VBAT_SLEEP_I_VDDIO_1p8V")
    Call LimitsTool.TestLimit(PS0C_SLEEP_I_PMU_VDDIO_1p8V, "PMU_VDDIOP", "PS0C_PMU_VDDIO_SLEEP_I_VDDIO_1p8V")
    If TheExec.Sites.ActiveCount = 0 Then Exit Function

    '# Restore
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_20mA"

    '-------------------------------------------- PS0C AON Bypass Ron (A8) --------------------------------------------
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU System Test - PMU Power Mode Test - PS0C AON Bypass Ron [A8]"
    TheExec.Datalog.WriteComment "================================================================================================"

    With TheHdw.DCVI.pins("ASR_VLX")
        .BleederResistor = tlDCVIBleederResistorAuto
        .Mode = tlDCVIModeHighImpedance
        .Connect tlDCVIConnectHighSense
    End With
    pmutb.Connect_LDO ("VDDOUT_AON")

    pmutb.Apply_PSET "VDDOUT_AON", "VDDOUT_AON_1mA_2V"                              '# 1mA Load setting at output of VDDOUT_MISCLDO
    TheHdw.wait 5 * mS
    PS0C_LDO_VDD_1P22_1mA_3p7V_SLEEP = pmutb.Meter_Strobe("ASR_VLX", 20, 1 * mS)      '# measure ASR_VLX=LDO_VDD_1P22
    PS0C_VDDOUT_AON_1mA_3p7V_SLEEP = pmutb.Meter_Strobe("VDDOUT_AON", 20, 1 * mS)     '# measure VDDOUT_AON

    With TheHdw.DCVI.pins("ASR_VLX, VDDOUT_AON")
        .Gate = False
        .Disconnect tlDCVIConnectDefault
        .BleederResistor = tlDCVIBleederResistorAuto
        .Mode = tlDCVIModeHighImpedance
    End With

    '---------------
    '# PMU Wake for A9
    '----------------
    Call Pmu_registerSetup__WakeUp     '# WakeUp

    Call LimitsTool.TestLimit(PS0C_LDO_VDD_1P22_1mA_3p7V_SLEEP, "ASR_VLX", "PS0C_LDO_VDD_1P22_SLEEP_1mA_3p7V")
    Call LimitsTool.TestLimit(PS0C_VDDOUT_AON_1mA_3p7V_SLEEP, "VDDOUT_AON", "PS0C_VDDOUT_AON_SLEEP_1mA_3p7V")
    Call LimitsTool.TestLimit(PS0C_LDO_VDD_1P22_1mA_3p7V_SLEEP.Subtract(PS0C_VDDOUT_AON_1mA_3p7V_SLEEP).Divide(1 * mA).Abs, "PS0C_VDDOUT_AON", "PS0C_AON_Bypass_RON")

'''    If Show_ChipID Then
'''        For Each Site In TheExec.Sites
'''            TheExec.Datalog.WriteComment "AXI Chip ID (Real Chip ID): " & Hex(AXI.ReadReg("18000000")(Site))
'''        Next Site
'''    End If

    testTime = TheHdw.ReadStopwatch
    TheExec.Datalog.WriteComment ""
    TheExec.Datalog.WriteComment "PMU_PowerModeTest_PS0C Test time:" & testTime
    TheExec.Datalog.WriteComment ""
    Exit Function
    
ErrorHandler:
    If TheExec.Sites.ActiveCount = 0 Then Exit Function              'If last site failed, exit the test and let IGXL cleanup
    TheExec.ErrorLogMessage "VB Error #" & Trim(Str(err.Number)) & " " & err.Description & " in instance " & TheExec.DataManager.InstanceName
    Resume Next
End Function

Public Function PMU__PowerModeTest_PS1A() As Long
On Error GoTo ErrorHandler

    Dim RTime As Double, ElapsedTime As Double
    Dim PWD_I_PMU_VDDIOA_0V As New SiteDouble
    Dim PWD_I_PMU_VDDIOA_1V8 As New SiteDouble
    Dim Sleep_I_VBAT As New SiteDouble
    Dim Sleep_I_VDDIO_PMU As New SiteDouble
    Dim PDWN_I_PMU_VDDIO_1p8V As New SiteDouble
   
    Dim PS1A_Sleep_I_VBAT_SR As New SiteDouble
    Dim PS1A_SLEEP_I_PMU_VDDIO_1p8V As New SiteDouble
    Dim PS1A_SLEEP_I_PMU_VDDIO_1p8V_1 As New SiteDouble
    
    Dim PS1A_LDO_VDD1P22_0mA_3p7V_SLEEP As New SiteDouble
    Dim PS1A_LDO_VDD1P0_0mA_3p7V_SLEEP As New SiteDouble
    Dim PS1A_VDDOUT_RETLDO_0mA_3p7V_SLEEP As New SiteDouble
    Dim PS1A_VDDOUT_AON_0mA_3p7V_SLEEP As New SiteDouble
    Dim PS1A_LDO_VDD_1P22_1mA_3p7V_SLEEP As New SiteDouble
    Dim PS1A_VDDOUT_AON_1mA_3p7V_SLEEP  As New SiteDouble

    Dim Readvals() As New SiteLong
    Dim B5i, B5ii, B5iii, B5iv As String

    Dim Sleep_I_VDDIO As New SiteDouble
    Dim PDWN_I_VBAT_VDDIO_0V As New SiteDouble
    Dim PDWN_I_VBAT_VDDIO_1p8V As New SiteDouble
    Dim PDWN_I_PMU_VDDIOA_1p8V As New SiteDouble
    
    'For LPLDO Test
    Dim BT_REG_ON_VOUT_1mA_1p8V As New SiteDouble
    Dim BT_REG_ON_VOUT_10mA_1p8V As New SiteDouble
    Dim BT_REG_ON_VOUT_10mA_1p62V As New SiteDouble
    Dim BT_REG_ON_VOUT_10mA_1p98V As New SiteDouble
    Dim LPLDO3_VBAT_I_B1_0mA_1p8V As New SiteDouble
    Dim LPLDO3_VBAT_I_B2_0mA_1p8V As New SiteDouble
    Dim LPLDO_Q_current_0mA_1p8V As New SiteDouble
    Dim line_diff As Double

    Dim WRF_VDD3P3_Initial_curr As New SiteDouble
    Dim WRF_VDD1P35_Initial_curr As New SiteDouble
    Dim WRF_VDD1P2_Initial_volt As New SiteDouble
    Dim WRF_VDD1P2_When_WPT_3P3_0V_curr As New SiteDouble
    Dim supply_pmu_ldo_pins As String
    Dim Show_ChipID As Boolean
    Dim trim_enable As Boolean
 
    Dim testTime As Double
    TheHdw.StartStopwatch
    
'''    With TheHdw.DCVI.pins("VDDOUT_MISCLDO")
'''        .BleederResistor = tlDCVIBleederResistorAuto
'''        .Mode = tlDCVIModeCurrent
'''        .Current = -0.5 * mA
'''        .Voltage = 0.7
'''        .Connect tlDCVIConnectDefault
'''        TheHdw.wait 2 * mS
'''        .Gate = True
'''    End With

    
    'igxltb.maintainState "WL_REG_ON, JTAG_TRST_L", "BT_REG_ON", ""
    'Must remember to increase the PMU_VDDIO currange range since we would like to turn on device (WL_REG_ON=High)
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_2mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_2mA"

    Call Pmu_registerSetup__PS1A_Mode                  '# Setup PS Mode
    TheHdw.wait 5 * mS

    With TheHdw.DCVI.pins("CSR_VLX, ASR_VLX, VDDOUT_RETLDO, VDDOUT_AON") 'CSR_VLX = LDO_VDD1P0, ASR_VLX=LDO_VDD_1P22
        .BleederResistor = tlDCVIBleederResistorAuto
        .Disconnect tlDCVIConnectDefault
        .Mode = tlDCVIModeHighImpedance
        .Connect tlDCVIConnectHighSense
    End With
    TheHdw.wait 10 * mS
    
    PS1A_LDO_VDD1P0_0mA_3p7V_SLEEP = pmutb.Meter_Strobe("CSR_VLX", 20, 1 * mS)                '#  Measurement of LDO_VDD1P0
    PS1A_LDO_VDD1P22_0mA_3p7V_SLEEP = pmutb.Meter_Strobe("ASR_VLX", 20, 1 * mS)               '#  Measurement of LDO_VDD_1P22
    PS1A_VDDOUT_RETLDO_0mA_3p7V_SLEEP = pmutb.Meter_Strobe("VDDOUT_RETLDO", 20, 1 * mS)       '#  Measurement of VDDOUT_RETLDO
    PS1A_VDDOUT_AON_0mA_3p7V_SLEEP = pmutb.Meter_Strobe("VDDOUT_AON", 20, 1 * mS)             '#  Measurement of VDDOUT_AON
    
    Call LimitsTool.TestLimit(PS1A_LDO_VDD1P0_0mA_3p7V_SLEEP, "CSR_VLX", "PS1A_LDO_VDD1P0_SLEEP_0mA_3p7V")
    Call LimitsTool.TestLimit(PS1A_LDO_VDD1P22_0mA_3p7V_SLEEP, "ASR_VLX", "PS1A_LDO_VDD1P22_SLEEP_0mA_3p7V")
    Call LimitsTool.TestLimit(PS1A_VDDOUT_RETLDO_0mA_3p7V_SLEEP, "VDDOUT_RETLDO", "PS1A_VDDOUT_RETLDO_SLEEP_0mA_3p7V")
    Call LimitsTool.TestLimit(PS1A_VDDOUT_AON_0mA_3p7V_SLEEP, "VDDOUT_AON", "PS1A_VDDOUT_AON_SLEEP_0mA_3p7V")
    If TheExec.Sites.ActiveCount = 0 Then Exit Function
    
    With TheHdw.DCVI.pins("CSR_VLX, ASR_VLX, ,VDDOUT_RETLDO, VDDOUT_AON") 'CSR_VLX = LDO_VDD1P0, ASR_VLX=LDO_VDD_1P22
        .Disconnect tlDCVIConnectHighSense
        .Mode = tlDCVIModeHighImpedance
        .BleederResistor = tlDCVIBleederResistorOff
    End With
    TheHdw.wait 2 * mS
    
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200uA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_20uA"
    TheHdw.wait 10 * mS
    '----------------------------------------- A10 & A11 PMU Sleep Mode from VBAT & PMU_VDDIO (when PMU_VDDIO=1.8V)----------------------------------------------------------------------------------------------
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU System Test - PMU Power Mode Test - Sleep (PS1A) Mode [A10]"
    TheExec.Datalog.WriteComment "================================================================================================"

    PS1A_Sleep_I_VBAT_SR = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 100, 1 * mS)                      '# Measurement of PMU_VDDBAT5
    PS1A_SLEEP_I_PMU_VDDIO_1p8V = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 5 * mS, 128, 781.25)       '# Measurement of PMU_VDDIO

    Call LimitsTool.TestLimit(PS1A_Sleep_I_VBAT_SR, "ET_LINREG_VDD_V5P0", "PS1A_VBAT_SLEEP_I_VDDIO_1p8V")
    Call LimitsTool.TestLimit(PS1A_SLEEP_I_PMU_VDDIO_1p8V, "PMU_VDDIOP", "PS1A_PMU_VDDIO_SLEEP_I_VDDIO_1p8V")
    If TheExec.Sites.ActiveCount = 0 Then Exit Function


    '# Restore
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_20mA"

    '-------------------------------------------- PS1A AON Bypass Ron (A11) --------------------------------------------
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU System Test - PMU Power Mode Test - PS1A AON Bypass Ron [A11]"
    TheExec.Datalog.WriteComment "================================================================================================"

    With TheHdw.DCVI.pins("ASR_VLX")
        .BleederResistor = tlDCVIBleederResistorAuto
        .Mode = tlDCVIModeHighImpedance
        .Connect tlDCVIConnectHighSense
    End With
    pmutb.Connect_LDO ("VDDOUT_AON")

    pmutb.Apply_PSET "VDDOUT_AON", "VDDOUT_AON_1mA_2V"                              '# 1mA Load setting at output of VDDOUT_MISCLDO
    TheHdw.wait 5 * mS
    PS1A_LDO_VDD_1P22_1mA_3p7V_SLEEP = pmutb.Meter_Strobe("ASR_VLX", 20, 1 * mS)      '# measure ASR_VLX=LDO_VDD_1P22
    PS1A_VDDOUT_AON_1mA_3p7V_SLEEP = pmutb.Meter_Strobe("VDDOUT_AON", 20, 1 * mS)     '# measure VDDOUT_AON

    With TheHdw.DCVI.pins("ASR_VLX, VDDOUT_AON")
        .Gate = False
        .Disconnect tlDCVIConnectDefault
        .BleederResistor = tlDCVIBleederResistorAuto
        .Mode = tlDCVIModeHighImpedance
    End With

    '---------------
    '# PMU Wake for A12
    '----------------
    Call Pmu_registerSetup__WakeUp     '# WakeUp

    Call LimitsTool.TestLimit(PS1A_LDO_VDD_1P22_1mA_3p7V_SLEEP, "ASR_VLX", "PS1A_LDO_VDD_1P22_SLEEP_1mA_3p7V")
    Call LimitsTool.TestLimit(PS1A_VDDOUT_AON_1mA_3p7V_SLEEP, "VDDOUT_AON", "PS1A_VDDOUT_AON_SLEEP_1mA_3p7V")
    Call LimitsTool.TestLimit(PS1A_LDO_VDD_1P22_1mA_3p7V_SLEEP.Subtract(PS1A_VDDOUT_AON_1mA_3p7V_SLEEP).Divide(1 * mA).Abs, "PS1A_VDDOUT_AON", "PS1A_AON_Bypass_RON")

'''    If Show_ChipID Then
'''        For Each Site In TheExec.Sites
'''            TheExec.Datalog.WriteComment "AXI Chip ID (Real Chip ID): " & Hex(AXI.ReadReg("18000000")(Site))
'''        Next Site
'''    End If

    testTime = TheHdw.ReadStopwatch
    TheExec.Datalog.WriteComment ""
    TheExec.Datalog.WriteComment "PMU_PowerModeTest_PS1A Test time:" & testTime
    TheExec.Datalog.WriteComment ""
    Exit Function
    
ErrorHandler:
    If TheExec.Sites.ActiveCount = 0 Then Exit Function              'If last site failed, exit the test and let IGXL cleanup
    TheExec.ErrorLogMessage "VB Error #" & Trim(Str(err.Number)) & " " & err.Description & " in instance " & TheExec.DataManager.InstanceName
    Resume Next
End Function

Public Function PMU__PowerModeTest_PS1C() As Long
On Error GoTo ErrorHandler

    Dim RTime As Double, ElapsedTime As Double
    Dim PWD_I_PMU_VDDIOA_0V As New SiteDouble
    Dim PWD_I_PMU_VDDIOA_1V8 As New SiteDouble
    Dim Sleep_I_VBAT As New SiteDouble
    Dim Sleep_I_VDDIO_PMU As New SiteDouble
    Dim PDWN_I_PMU_VDDIO_1p8V As New SiteDouble
   
    Dim PS1C_Sleep_I_VBAT_SR As New SiteDouble
    Dim PS1C_SLEEP_I_PMU_VDDIO_1p8V As New SiteDouble
    Dim PS1C_SLEEP_I_PMU_VDDIO_1p8V_1 As New SiteDouble
    
    Dim PS1C_LDO_VDD1P22_0mA_3p7V_SLEEP As New SiteDouble
    Dim PS1C_LDO_VDD1P0_0mA_3p7V_SLEEP As New SiteDouble
    Dim PS1C_VDDOUT_RETLDO_0mA_3p7V_SLEEP As New SiteDouble
    Dim PS1C_VDDOUT_AON_0mA_3p7V_SLEEP As New SiteDouble
    Dim PS1C_LDO_VDD_1P22_1mA_3p7V_SLEEP As New SiteDouble
    Dim PS1C_VDDOUT_AON_1mA_3p7V_SLEEP  As New SiteDouble

    Dim Readvals() As New SiteLong
    Dim B5i, B5ii, B5iii, B5iv As String

    Dim Sleep_I_VDDIO As New SiteDouble
    Dim PDWN_I_VBAT_VDDIO_0V As New SiteDouble
    Dim PDWN_I_VBAT_VDDIO_1p8V As New SiteDouble
    Dim PDWN_I_PMU_VDDIOA_1p8V As New SiteDouble
    
    'For LPLDO Test
    Dim BT_REG_ON_VOUT_1mA_1p8V As New SiteDouble
    Dim BT_REG_ON_VOUT_10mA_1p8V As New SiteDouble
    Dim BT_REG_ON_VOUT_10mA_1p62V As New SiteDouble
    Dim BT_REG_ON_VOUT_10mA_1p98V As New SiteDouble
    Dim LPLDO3_VBAT_I_B1_0mA_1p8V As New SiteDouble
    Dim LPLDO3_VBAT_I_B2_0mA_1p8V As New SiteDouble
    Dim LPLDO_Q_current_0mA_1p8V As New SiteDouble
    Dim line_diff As Double

    Dim WRF_VDD3P3_Initial_curr As New SiteDouble
    Dim WRF_VDD1P35_Initial_curr As New SiteDouble
    Dim WRF_VDD1P2_Initial_volt As New SiteDouble
    Dim WRF_VDD1P2_When_WPT_3P3_0V_curr As New SiteDouble
    Dim supply_pmu_ldo_pins As String
    Dim Show_ChipID As Boolean
    Dim trim_enable As Boolean
 
    Dim testTime As Double
    TheHdw.StartStopwatch
    
'''    With TheHdw.DCVI.pins("VDDOUT_MISCLDO")
'''        .BleederResistor = tlDCVIBleederResistorAuto
'''        .Mode = tlDCVIModeCurrent
'''        .Current = -0.5 * mA
'''        .Voltage = 0.7
'''        .Connect tlDCVIConnectDefault
'''        TheHdw.wait 2 * mS
'''        .Gate = True
'''    End With

    
    'igxltb.maintainState "WL_REG_ON, JTAG_TRST_L", "BT_REG_ON", ""
    'Must remember to increase the PMU_VDDIO currange range since we would like to turn on device (WL_REG_ON=High)
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_2mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_2mA"

    Call Pmu_registerSetup__PS1C_Mode                  '# Setup PS Mode
    TheHdw.wait 5 * mS

    With TheHdw.DCVI.pins("CSR_VLX, ASR_VLX, VDDOUT_RETLDO, VDDOUT_AON") 'CSR_VLX = LDO_VDD1P0, ASR_VLX=LDO_VDD_1P22
        .BleederResistor = tlDCVIBleederResistorAuto
        .Disconnect tlDCVIConnectDefault
        .Mode = tlDCVIModeHighImpedance
        .Connect tlDCVIConnectHighSense
    End With
    TheHdw.wait 10 * mS
    
    PS1C_LDO_VDD1P0_0mA_3p7V_SLEEP = pmutb.Meter_Strobe("CSR_VLX", 20, 1 * mS)                '#  Measurement of LDO_VDD1P0
    PS1C_LDO_VDD1P22_0mA_3p7V_SLEEP = pmutb.Meter_Strobe("ASR_VLX", 20, 1 * mS)               '#  Measurement of LDO_VDD_1P22
    PS1C_VDDOUT_RETLDO_0mA_3p7V_SLEEP = pmutb.Meter_Strobe("VDDOUT_RETLDO", 20, 1 * mS)       '#  Measurement of VDDOUT_RETLDO
    PS1C_VDDOUT_AON_0mA_3p7V_SLEEP = pmutb.Meter_Strobe("VDDOUT_AON", 20, 1 * mS)             '#  Measurement of VDDOUT_AON
    
    Call LimitsTool.TestLimit(PS1C_LDO_VDD1P0_0mA_3p7V_SLEEP, "CSR_VLX", "PS1C_LDO_VDD1P0_SLEEP_0mA_3p7V")
    Call LimitsTool.TestLimit(PS1C_LDO_VDD1P22_0mA_3p7V_SLEEP, "ASR_VLX", "PS1C_LDO_VDD1P22_SLEEP_0mA_3p7V")
    Call LimitsTool.TestLimit(PS1C_VDDOUT_RETLDO_0mA_3p7V_SLEEP, "VDDOUT_RETLDO", "PS1C_VDDOUT_RETLDO_SLEEP_0mA_3p7V")
    Call LimitsTool.TestLimit(PS1C_VDDOUT_AON_0mA_3p7V_SLEEP, "VDDOUT_AON", "PS1C_VDDOUT_AON_SLEEP_0mA_3p7V")
    If TheExec.Sites.ActiveCount = 0 Then Exit Function
    
    With TheHdw.DCVI.pins("CSR_VLX, ASR_VLX, ,VDDOUT_RETLDO, VDDOUT_AON") 'CSR_VLX = LDO_VDD1P0, ASR_VLX=LDO_VDD_1P22
        .Disconnect tlDCVIConnectHighSense
        .Mode = tlDCVIModeHighImpedance
        .BleederResistor = tlDCVIBleederResistorOff
    End With
    TheHdw.wait 2 * mS
    
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200uA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_20uA"
    TheHdw.wait 10 * mS
    '----------------------------------------- A13 & A14 PMU Sleep Mode from VBAT & PMU_VDDIO (when PMU_VDDIO=1.8V)----------------------------------------------------------------------------------------------
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU System Test - PMU Power Mode Test - Sleep (PS1C) Mode [A13]"
    TheExec.Datalog.WriteComment "================================================================================================"

    PS1C_Sleep_I_VBAT_SR = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 100, 1 * mS)                      '# Measurement of PMU_VDDBAT5
    PS1C_SLEEP_I_PMU_VDDIO_1p8V = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 5 * mS, 128, 781.25)       '# Measurement of PMU_VDDIO

    Call LimitsTool.TestLimit(PS1C_Sleep_I_VBAT_SR, "ET_LINREG_VDD_V5P0", "PS1C_VBAT_SLEEP_I_VDDIO_1p8V")
    Call LimitsTool.TestLimit(PS1C_SLEEP_I_PMU_VDDIO_1p8V, "PMU_VDDIOP", "PS1C_PMU_VDDIO_SLEEP_I_VDDIO_1p8V")
    If TheExec.Sites.ActiveCount = 0 Then Exit Function

    '# Restore
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_20mA"

    '-------------------------------------------- PS1C AON Bypass Ron (A14) --------------------------------------------
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU System Test - PMU Power Mode Test - PS1C AON Bypass Ron [A14]"
    TheExec.Datalog.WriteComment "================================================================================================"

    With TheHdw.DCVI.pins("ASR_VLX")
        .BleederResistor = tlDCVIBleederResistorAuto
        .Mode = tlDCVIModeHighImpedance
        .Connect tlDCVIConnectHighSense
    End With
    pmutb.Connect_LDO ("VDDOUT_AON")

    pmutb.Apply_PSET "VDDOUT_AON", "VDDOUT_AON_1mA_2V"                              '# 1mA Load setting at output of VDDOUT_MISCLDO
    TheHdw.wait 5 * mS
    PS1C_LDO_VDD_1P22_1mA_3p7V_SLEEP = pmutb.Meter_Strobe("ASR_VLX", 20, 1 * mS)      '# measure ASR_VLX=LDO_VDD_1P22
    PS1C_VDDOUT_AON_1mA_3p7V_SLEEP = pmutb.Meter_Strobe("VDDOUT_AON", 20, 1 * mS)     '# measure VDDOUT_AON

    With TheHdw.DCVI.pins("ASR_VLX, VDDOUT_AON")
        .Gate = False
        .Disconnect tlDCVIConnectDefault
        .BleederResistor = tlDCVIBleederResistorAuto
        .Mode = tlDCVIModeHighImpedance
    End With

    '---------------
    '# PMU Wake for A15
    '----------------
    'Call Pmu_registerSetup__WakeUp     '# WakeUp

    Call LimitsTool.TestLimit(PS1C_LDO_VDD_1P22_1mA_3p7V_SLEEP, "ASR_VLX", "PS1C_LDO_VDD_1P22_SLEEP_1mA_3p7V")
    Call LimitsTool.TestLimit(PS1C_VDDOUT_AON_1mA_3p7V_SLEEP, "VDDOUT_AON", "PS1C_VDDOUT_AON_SLEEP_1mA_3p7V")
    Call LimitsTool.TestLimit(PS1C_LDO_VDD_1P22_1mA_3p7V_SLEEP.Subtract(PS1C_VDDOUT_AON_1mA_3p7V_SLEEP).Divide(1 * mA).Abs, "PS1C_VDDOUT_AON", "PS1C_AON_Bypass_RON")

'''    If Show_ChipID Then
'''        For Each Site In TheExec.Sites
'''            TheExec.Datalog.WriteComment "AXI Chip ID (Real Chip ID): " & Hex(AXI.ReadReg("18000000")(Site))
'''        Next Site
'''    End If

    testTime = TheHdw.ReadStopwatch
    TheExec.Datalog.WriteComment ""
    TheExec.Datalog.WriteComment "PMU_PowerModeTest_PS1C Test time:" & testTime
    TheExec.Datalog.WriteComment ""
    Exit Function
    
ErrorHandler:
    If TheExec.Sites.ActiveCount = 0 Then Exit Function              'If last site failed, exit the test and let IGXL cleanup
    TheExec.ErrorLogMessage "VB Error #" & Trim(Str(err.Number)) & " " & err.Description & " in instance " & TheExec.DataManager.InstanceName
    Resume Next
End Function

Public Function PMU__SwitchRegTests_CSR_PWM() As Long

On Error GoTo ErrorHandler

    Dim PWM_ABUCK_V_250mA_5p0_Before_trim As New SiteDouble

    Dim PWM_VDDLDO_V_10mA_3p0 As New SiteDouble, PWM_VDDLDO_V_10mA_3p7 As New SiteDouble, PWM_VDDLDO_V_10mA_5p25 As New SiteDouble
    
    Dim PWM_VDDLDO_V_60mA_3p0 As New SiteDouble, PWM_VDDLDO_V_60mA_3p7 As New SiteDouble, PWM_VDDLDO_V_60mA_5p25 As New SiteDouble
    Dim PWM_VDDBAT_I_60mA_3p0 As New SiteDouble, PWM_VDDBAT_I_60mA_3p7 As New SiteDouble, PWM_VDDBAT_I_60mA_5p25 As New SiteDouble
    Dim PWM_VDDLDO_V_80mA_3p0 As New SiteDouble, PWM_VDDLDO_V_80mA_3p7 As New SiteDouble, PWM_VDDLDO_V_80mA_5p25 As New SiteDouble
    Dim PWM_VDDBAT_I_80mA_3p0 As New SiteDouble, PWM_VDDBAT_I_80mA_3p7 As New SiteDouble, PWM_VDDBAT_I_80mA_5p25 As New SiteDouble
    Dim PWM_VDDLDO_V_100mA_3p0 As New SiteDouble, PWM_VDDLDO_V_100mA_3p7 As New SiteDouble, PWM_VDDLDO_V_100mA_5p25 As New SiteDouble
    Dim PWM_VDDBAT_I_100mA_3p0 As New SiteDouble, PWM_VDDBAT_I_100mA_3p7 As New SiteDouble, PWM_VDDBAT_I_100mA_5p25 As New SiteDouble
        
    Dim PWM_Eff_60mA_3p0 As New SiteDouble, PWM_Eff_60mA_3p7 As New SiteDouble, PWM_Eff_60mA_5p25 As New SiteDouble
    Dim PWM_Eff_80mA_3p0 As New SiteDouble, PWM_Eff_80mA_3p7 As New SiteDouble, PWM_Eff_80mA_5p25 As New SiteDouble
    Dim PWM_Eff_100mA_3p0 As New SiteDouble, PWM_Eff_100mA_3p7 As New SiteDouble, PWM_Eff_100mA_5p25 As New SiteDouble
    
    Dim PWM_PMUVDDIOA_I_60mA_3p0 As New SiteDouble, PWM_PMUVDDIOA_I_60mA_3p7 As New SiteDouble, PWM_PMUVDDIOA_I_60mA_5p25 As New SiteDouble
    Dim PWM_PMUVDDIOA_I_80mA_3p0 As New SiteDouble, PWM_PMUVDDIOA_I_80mA_3p7 As New SiteDouble, PWM_PMUVDDIOA_I_80mA_5p25 As New SiteDouble
    Dim PWM_PMUVDDIOA_I_100mA_3p0 As New SiteDouble, PWM_PMUVDDIOA_I_100mA_3p7 As New SiteDouble, PWM_PMUVDDIOA_I_100mA_5p25 As New SiteDouble
       
    Dim PWM_Eff_60mA_3p0_INC_PMUVDDIO As New SiteDouble, PWM_Eff_60mA_3p7_INC_PMUVDDIO As New SiteDouble, PWM_Eff_60mA_5p25_INC_PMUVDDIO As New SiteDouble
    Dim PWM_Eff_80mA_3p0_INC_PMUVDDIO As New SiteDouble, PWM_Eff_80mA_3p7_INC_PMUVDDIO As New SiteDouble, PWM_Eff_80mA_5p25_INC_PMUVDDIO As New SiteDouble
    Dim PWM_Eff_100mA_3p0_INC_PMUVDDIO As New SiteDouble, PWM_Eff_100mA_3p7_INC_PMUVDDIO As New SiteDouble, PWM_Eff_100mA_5p25_INC_PMUVDDIO As New SiteDouble
    
    Dim Show_ChipID As Boolean, trim_enable As Boolean
    If TheExec.EnableWord("PMU_TRIM_EN") Then
        trim_enable = True
    Else
        trim_enable = False
    End If
 
    Dim testTime As Double
    TheHdw.StartStopwatch
    
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU SwitchReg Tests - CSR PWM [C1], [C2], [C3], [C4i], [C4ii], [C5i], [C5ii]"
    TheExec.Datalog.WriteComment "================================================================================================"
    '----------------------------------------- ABUCK in PWM mode (C1) ----------------------------------------------------
    
    '---------------------------------------------------------------------
    'Must remember to reset from sleep mode & Strapping Option if needed -
    '---------------------------------------------------------------------
    'ChipInit CORE_RESET
    
    'Must remember to increase the PMU_VDDIO currange range since we would like to turn on device (WL_REG_ON=High)
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_2mA"
    TheHdw.wait 5 * mS

    '---------------------------------
    'Output Voltage in PWM Mode for C1
    '---------------------------------
    Call Pmu_registerSetup__CSR_PWM_Mode            '# setup PWM Mode
    TheHdw.wait 2 * mS

    'For loading purposes through LD0_VDD1P22 'CSR_VLX = LDO_VDD1P0, ASR_VLX=LD0_VDD1P22
    
    TheHdw.DCVI.pins("CSR_VLX").BleederResistor = tlDCVIBleederResistorAuto
    With TheHdw.DCVI.pins("CSR_VLX")
        .Disconnect (tlDCVIConnectDefault)
        .Mode = tlDCVIModeCurrent
        .Meter.Mode = tlDCVIMeterVoltage
        .Current = -200 * nA
        .Voltage = -1 * v
        .Connect
        .Gate = True
    End With
    TheHdw.wait 2 * mS
 
    '************************************* 10mA Load condition *************************************
    '----------------------------------------
    'VDDBAT = 3.0V, 10mA load at LDO_VDD1P0
    '----------------------------------------
    
    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_10mA_2V"                                    '10mA Load setting at "LDO_VDD1P0"(output of cbuck regulator)
    TheHdw.wait 2 * mS

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_20mA"
    TheHdw.wait 3 * mS

    PWM_VDDLDO_V_10mA_3p0 = pmutb.Meter_Strobe("CSR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 10mA Load (VDDBAT=3.0V)

    '----------------------------------------
    'VDDBAT = 3.7V, 10mA load at LDO_VDD1P0
    '----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    TheHdw.wait 5 * mS

    PWM_VDDLDO_V_10mA_3p7 = pmutb.Meter_Strobe("CSR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 10mA Load (VDDBAT=3.7V)
   
    '----------------------------------------
    'VDDBAT = 5.25V, 10mA load at LDO_VDD1P0
    '----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_20mA"
    TheHdw.wait 5 * mS

    PWM_VDDLDO_V_10mA_5p25 = pmutb.Meter_Strobe("CSR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 10mA Load (VDDBAT=5.25V)
    

    '************************************* Reset 60mA, 80mA, 100mA Load condition *************************************
    '----------------------------------------
    'VDDBAT = 3.0V, 3.7V, 5.25V with 200mA load at LDO_VDD1P0
    '----------------------------------------
    'Ramp down
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    
    ' Common on DCVS setup
    TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Filter.Bypass = False                           'Measure PMU_VDDIO current (required for efficiency calculation)
    TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Filter.Value = 781.25
    
    '************************************* 60mA Load condition *************************************
    
    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_60mA_2V"                                   '60mA Load setting at "LDO_VDD1P0"(output of cbuck regulator)
    TheHdw.wait 2 * mS

    
    '----------------------------------------
    'VDDBAT = 3.0V, 60mA load at LDO_VDD1P0
    '----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_200mA"
    TheHdw.wait 5 * mS

    PWM_VDDLDO_V_60mA_3p0 = pmutb.Meter_Strobe("CSR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 60mA Load (VDDBAT=3.0V)
    PWM_VDDBAT_I_60mA_3p0 = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 20, 0.5 * mS)            'Measure VDDBAT current(required for efficiency calculation)
    PWM_PMUVDDIOA_I_60mA_3p0 = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 20 * mS, 128, 781.25)
    
    '----------------------------------------
    'VDDBAT = 3.7V, 60mA load at LDO_VDD1P0
    '----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    TheHdw.wait 5 * mS

    PWM_VDDLDO_V_60mA_3p7 = pmutb.Meter_Strobe("CSR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 60mA Load (VDDBAT=3.7V)
    PWM_VDDBAT_I_60mA_3p7 = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 20, 0.5 * mS)            'Measure VDDBAT current(required for efficiency calculation)
    PWM_PMUVDDIOA_I_60mA_3p7 = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 20 * mS, 128, 781.25)
   
    '----------------------------------------
    'VDDBAT = 5.25V, 60mA load at LDO_VDD1P0
    '----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_200mA"
    TheHdw.wait 5 * mS

    PWM_VDDLDO_V_60mA_5p25 = pmutb.Meter_Strobe("CSR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 60mA Load (VDDBAT=5.25V)
    PWM_VDDBAT_I_60mA_5p25 = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 20, 0.5 * mS)            'Measure VDDBAT current(required for efficiency calculation)
    PWM_PMUVDDIOA_I_60mA_5p25 = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 20 * mS, 128, 781.25)
    
    
    '************************************* 80mA Load condition *************************************
    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_80mA_2V"                                   '200mA Load setting at "LDO_VDD1P0"(output of cbuck regulator)
    TheHdw.wait 2 * mS
 
    '----------------------------------------
    'VDDBAT = 3.0V, 80mA load at LDO_VDD1P0
    '----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_200mA"
    TheHdw.wait 5 * mS

    PWM_VDDLDO_V_80mA_3p0 = pmutb.Meter_Strobe("CSR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 80mA Load (VDDBAT=3.0V)
    PWM_VDDBAT_I_80mA_3p0 = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 20, 0.5 * mS)            'Measure VDDBAT current(required for efficiency calculation)
    PWM_PMUVDDIOA_I_80mA_3p0 = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 20 * mS, 128, 781.25)
    
    '----------------------------------------
    'VDDBAT = 3.7V, 80mA load at LDO_VDD1P0
    '----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    TheHdw.wait 5 * mS

    PWM_VDDLDO_V_80mA_3p7 = pmutb.Meter_Strobe("CSR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 80mA Load (VDDBAT=3.7V)
    PWM_VDDBAT_I_80mA_3p7 = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 20, 0.5 * mS)            'Measure VDDBAT current(required for efficiency calculation)
    PWM_PMUVDDIOA_I_80mA_3p7 = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 20 * mS, 128, 781.25)
   
    '----------------------------------------
    'VDDBAT = 5.25V, 80mA load at LDO_VDD1P0
    '----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_200mA"
    TheHdw.wait 5 * mS

    PWM_VDDLDO_V_80mA_5p25 = pmutb.Meter_Strobe("CSR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 80mA Load (VDDBAT=5.25V)
    PWM_VDDBAT_I_80mA_5p25 = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 20, 0.5 * mS)            'Measure VDDBAT current(required for efficiency calculation)
    PWM_PMUVDDIOA_I_80mA_5p25 = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 20 * mS, 128, 781.25)
    
    '************************************* 100mA Load condition *************************************
    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_100mA_2V"                                   '200mA Load setting at "LDO_VDD1P0"(output of cbuck regulator)
    TheHdw.wait 2 * mS
 
    '----------------------------------------
    'VDDBAT = 3.0V, 100mA load at LDO_VDD1P0
    '----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_200mA"
    TheHdw.wait 5 * mS

    PWM_VDDLDO_V_100mA_3p0 = pmutb.Meter_Strobe("CSR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 100mA Load (VDDBAT=3.0V)
    PWM_VDDBAT_I_100mA_3p0 = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 20, 0.5 * mS)            'Measure VDDBAT current(required for efficiency calculation)
    PWM_PMUVDDIOA_I_100mA_3p0 = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 20 * mS, 128, 781.25)
    
    '----------------------------------------
    'VDDBAT = 3.7V, 100mA load at LDO_VDD1P0
    '----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    TheHdw.wait 5 * mS

    PWM_VDDLDO_V_100mA_3p7 = pmutb.Meter_Strobe("CSR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 100mA Load (VDDBAT=3.7V)
    PWM_VDDBAT_I_100mA_3p7 = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 20, 0.5 * mS)            'Measure VDDBAT current(required for efficiency calculation)
    PWM_PMUVDDIOA_I_100mA_3p7 = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 20 * mS, 128, 781.25)
   
    '----------------------------------------
    'VDDBAT = 5.25V, 100mA load at LDO_VDD1P0
    '----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_200mA"
    TheHdw.wait 5 * mS

    PWM_VDDLDO_V_100mA_5p25 = pmutb.Meter_Strobe("CSR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 100mA Load (VDDBAT=5.25V)
    PWM_VDDBAT_I_100mA_5p25 = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 20, 0.5 * mS)            'Measure VDDBAT current(required for efficiency calculation)
    PWM_PMUVDDIOA_I_100mA_5p25 = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 20 * mS, 128, 781.25)
    
    
    
    '************************************* Efficiency Calculation *************************************
    
    pmutb.Calc_Eff 3#, 60 * mA, PWM_VDDLDO_V_60mA_3p0, PWM_VDDBAT_I_60mA_3p0, PWM_Eff_60mA_3p0
    pmutb.Calc_Eff 3.7, 60 * mA, PWM_VDDLDO_V_60mA_3p7, PWM_VDDBAT_I_60mA_3p7, PWM_Eff_60mA_3p7
    pmutb.Calc_Eff 5.25, 60 * mA, PWM_VDDLDO_V_60mA_5p25, PWM_VDDBAT_I_60mA_5p25, PWM_Eff_60mA_5p25

    pmutb.Calc_Eff 3#, 80 * mA, PWM_VDDLDO_V_80mA_3p0, PWM_VDDBAT_I_80mA_3p0, PWM_Eff_80mA_3p0
    pmutb.Calc_Eff 3.7, 80 * mA, PWM_VDDLDO_V_80mA_3p7, PWM_VDDBAT_I_80mA_3p7, PWM_Eff_80mA_3p7
    pmutb.Calc_Eff 5.25, 80 * mA, PWM_VDDLDO_V_80mA_5p25, PWM_VDDBAT_I_80mA_5p25, PWM_Eff_80mA_5p25

    pmutb.Calc_Eff 3#, 100 * mA, PWM_VDDLDO_V_100mA_3p0, PWM_VDDBAT_I_100mA_3p0, PWM_Eff_100mA_3p0
    pmutb.Calc_Eff 3.7, 100 * mA, PWM_VDDLDO_V_100mA_3p7, PWM_VDDBAT_I_100mA_3p7, PWM_Eff_100mA_3p7
    pmutb.Calc_Eff 5.25, 100 * mA, PWM_VDDLDO_V_100mA_5p25, PWM_VDDBAT_I_100mA_5p25, PWM_Eff_100mA_5p25

    'Include the PMU_VDDIO current
    pmutb.Calc_Eff_INC_PMU_VDDIO 3#, 60 * mA, PWM_VDDLDO_V_60mA_3p0, PWM_VDDBAT_I_60mA_3p0, 1.8, PWM_PMUVDDIOA_I_60mA_3p0, PWM_Eff_60mA_3p0_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 3.7, 60 * mA, PWM_VDDLDO_V_60mA_3p7, PWM_VDDBAT_I_60mA_3p7, 1.8, PWM_PMUVDDIOA_I_60mA_3p7, PWM_Eff_60mA_3p7_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 5.25, 60 * mA, PWM_VDDLDO_V_60mA_5p25, PWM_VDDBAT_I_60mA_5p25, 1.8, PWM_PMUVDDIOA_I_60mA_5p25, PWM_Eff_60mA_5p25_INC_PMUVDDIO

 
    pmutb.Calc_Eff_INC_PMU_VDDIO 3#, 80 * mA, PWM_VDDLDO_V_80mA_3p0, PWM_VDDBAT_I_80mA_3p0, 1.8, PWM_PMUVDDIOA_I_80mA_3p0, PWM_Eff_80mA_3p0_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 3.7, 80 * mA, PWM_VDDLDO_V_80mA_3p7, PWM_VDDBAT_I_80mA_3p7, 1.8, PWM_PMUVDDIOA_I_80mA_3p7, PWM_Eff_80mA_3p7_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 5.25, 80 * mA, PWM_VDDLDO_V_80mA_5p25, PWM_VDDBAT_I_80mA_5p25, 1.8, PWM_PMUVDDIOA_I_80mA_5p25, PWM_Eff_80mA_5p25_INC_PMUVDDIO

    pmutb.Calc_Eff_INC_PMU_VDDIO 3#, 100 * mA, PWM_VDDLDO_V_100mA_3p0, PWM_VDDBAT_I_100mA_3p0, 1.8, PWM_PMUVDDIOA_I_100mA_3p0, PWM_Eff_100mA_3p0_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 3.7, 100 * mA, PWM_VDDLDO_V_100mA_3p7, PWM_VDDBAT_I_100mA_3p7, 1.8, PWM_PMUVDDIOA_I_100mA_3p7, PWM_Eff_100mA_3p7_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 5.25, 100 * mA, PWM_VDDLDO_V_100mA_5p25, PWM_VDDBAT_I_100mA_5p25, 1.8, PWM_PMUVDDIOA_I_100mA_5p25, PWM_Eff_100mA_5p25_INC_PMUVDDIO

    
    '************************************* Limit Check *************************************
    'CSR Output Voltage in PWM Mode [C1]
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_60mA_3p0, "CSR_VLX", "PMU_CSR_" + "PWM_LDO_V_60mA_3p0")
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_60mA_3p7, "CSR_VLX", "PMU_CSR_" + "PWM_LDO_V_60mA_3p7")
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_60mA_5p25, "CSR_VLX", "PMU_CSR_" + "PWM_LDO_V_60mA_5p25")
    
    Call LimitsTool.TestLimit(PWM_VDDBAT_I_60mA_3p0, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "PWM_VBAT_I_60mA_3p0")
    Call LimitsTool.TestLimit(PWM_VDDBAT_I_60mA_3p7, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "PWM_VBAT_I_60mA_3p7")
    Call LimitsTool.TestLimit(PWM_VDDBAT_I_60mA_5p25, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "PWM_VBAT_I_60mA_5p25")
    
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_80mA_3p0, "CSR_VLX", "PMU_CSR_" + "PWM_LDO_V_80mA_3p0")
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_80mA_3p7, "CSR_VLX", "PMU_CSR_" + "PWM_LDO_V_80mA_3p7")
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_80mA_5p25, "CSR_VLX", "PMU_CSR_" + "PWM_LDO_V_80mA_5p25")
    
    Call LimitsTool.TestLimit(PWM_VDDBAT_I_80mA_3p0, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "PWM_VBAT_I_80mA_3p0")
    Call LimitsTool.TestLimit(PWM_VDDBAT_I_80mA_3p7, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "PWM_VBAT_I_80mA_3p7")
    Call LimitsTool.TestLimit(PWM_VDDBAT_I_80mA_5p25, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "PWM_VBAT_I_80mA_5p25")
    
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_100mA_3p0, "CSR_VLX", "PMU_CSR_" + "PWM_LDO_V_100mA_3p0")
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_100mA_3p7, "CSR_VLX", "PMU_CSR_" + "PWM_LDO_V_100mA_3p7")
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_100mA_5p25, "CSR_VLX", "PMU_CSR_" + "PWM_LDO_V_100mA_5p25")
    
    Call LimitsTool.TestLimit(PWM_VDDBAT_I_100mA_3p0, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "PWM_VBAT_I_100mA_3p0")
    Call LimitsTool.TestLimit(PWM_VDDBAT_I_100mA_3p7, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "PWM_VBAT_I_100mA_3p7")
    Call LimitsTool.TestLimit(PWM_VDDBAT_I_100mA_5p25, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "PWM_VBAT_I_100mA_5p25")
       
    'CSR PWM Load Regulation [C2]
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_10mA_3p0.Subtract(PWM_VDDLDO_V_100mA_3p0).Abs, "CSR_VLX", "PMU_CSR_" + "PWM_LoadReg_3p0_10mA_100mA")
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_10mA_3p7.Subtract(PWM_VDDLDO_V_100mA_3p7).Abs, "CSR_VLX", "PMU_CSR_" + "PWM_LoadReg_3p7_10mA_100mA")
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_10mA_5p25.Subtract(PWM_VDDLDO_V_100mA_5p25).Abs, "CSR_VLX", "PMU_CSR_" + "PWM_LoadReg_5p25_10mA_100mA")
    
    'CSR PWM Line Regulation [C3]
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_100mA_5p25.Subtract(PWM_VDDLDO_V_100mA_3p0).Abs, "CSR_VLX", "PMU_CSR_" + "PWM_LineReg_100mA")
    
    'CSR PWM Efficiency [C4i], [C5i], [C6i]
    Call LimitsTool.TestLimit(PWM_Eff_60mA_3p0, "CSR_VLX", "PMU_CSR_" + "PWM_Eff_60mA_3p0")
    Call LimitsTool.TestLimit(PWM_Eff_60mA_3p7, "CSR_VLX", "PMU_CSR_" + "PWM_Eff_60mA_3p7")
    Call LimitsTool.TestLimit(PWM_Eff_60mA_5p25, "CSR_VLX", "PMU_CSR_" + "PWM_Eff_60mA_5p25")
    
    Call LimitsTool.TestLimit(PWM_Eff_80mA_3p0, "CSR_VLX", "PMU_CSR_" + "PWM_Eff_80mA_3p0")
    Call LimitsTool.TestLimit(PWM_Eff_80mA_3p7, "CSR_VLX", "PMU_CSR_" + "PWM_Eff_80mA_3p7")
    Call LimitsTool.TestLimit(PWM_Eff_80mA_5p25, "CSR_VLX", "PMU_CSR_" + "PWM_Eff_80mA_5p25")
    
    Call LimitsTool.TestLimit(PWM_Eff_100mA_3p0, "CSR_VLX", "PMU_CSR_" + "PWM_Eff_100mA_3p0")
    Call LimitsTool.TestLimit(PWM_Eff_100mA_3p7, "CSR_VLX", "PMU_CSR_" + "PWM_Eff_100mA_3p7")
    Call LimitsTool.TestLimit(PWM_Eff_100mA_5p25, "CSR_VLX", "PMU_CSR_" + "PWM_Eff_100mA_5p25")
    
    'CSR PWM Efficiency with PMU_VDDIO [C4ii], [C5ii], [C6ii]
    Call LimitsTool.TestLimit(PWM_Eff_60mA_3p0_INC_PMUVDDIO, "CSR_VLX", "PMU_CSR_" + "PWM_Eff_60mA_3p0_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(PWM_Eff_60mA_3p7_INC_PMUVDDIO, "CSR_VLX", "PMU_CSR_" + "PWM_Eff_60mA_3p7_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(PWM_Eff_60mA_5p25_INC_PMUVDDIO, "CSR_VLX", "PMU_CSR_" + "PWM_Eff_60mA_5p25_INC_PMU_VDDIO")
    
    Call LimitsTool.TestLimit(PWM_Eff_80mA_3p0_INC_PMUVDDIO, "CSR_VLX", "PMU_CSR_" + "PWM_Eff_80mA_3p0_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(PWM_Eff_80mA_3p7_INC_PMUVDDIO, "CSR_VLX", "PMU_CSR_" + "PWM_Eff_80mA_3p7_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(PWM_Eff_80mA_5p25_INC_PMUVDDIO, "CSR_VLX", "PMU_CSR_" + "PWM_Eff_80mA_5p25_INC_PMU_VDDIO")
    
    Call LimitsTool.TestLimit(PWM_Eff_100mA_3p0_INC_PMUVDDIO, "CSR_VLX", "PMU_CSR_" + "PWM_Eff_100mA_3p0_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(PWM_Eff_100mA_3p7_INC_PMUVDDIO, "CSR_VLX", "PMU_CSR_" + "PWM_Eff_100mA_3p7_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(PWM_Eff_100mA_5p25_INC_PMUVDDIO, "CSR_VLX", "PMU_CSR_" + "PWM_Eff_100mA_5p25_INC_PMU_VDDIO")
    
    If TheExec.Sites.ActiveCount = 0 Then Exit Function
    
    '-----------------------------------------------------------------------
    'Must reduce to 50mA and ramp down or else FS Splot Lot measuring 0kHz -
    '-----------------------------------------------------------------------
    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_50mA_2V"                                  '50mA Load setting at "LDO_VDD1P0"(output of cbuck regulator)
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_0mA_2V"
    TheHdw.wait 2 * mS

    With TheHdw.DCVI.pins("CSR_VLX")
        .Gate = False
        .Disconnect (tlDCVIConnectDefault)
        .Mode = tlDCVIModeHighImpedance
        .BleederResistor = tlDCVIBleederResistorOff
    End With
    
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    TheHdw.wait 2 * mS

    testTime = TheHdw.ReadStopwatch
    TheExec.Datalog.WriteComment ""
    TheExec.Datalog.WriteComment "PMU_SwitchRegTests_CSR_PWM Test time:" & testTime
    TheExec.Datalog.WriteComment ""
    
Exit Function

ErrorHandler:
    If TheExec.Sites.ActiveCount = 0 Then Exit Function              'If last site failed, exit the test and let IGXL cleanup
    TheExec.ErrorLogMessage "VB Error #" & Trim(Str(err.Number)) & " " & err.Description & " in instance " & TheExec.DataManager.InstanceName
    Resume Next

End Function

Public Function PMU__SwitchRegTests_ASR_PWM() As Long

On Error GoTo ErrorHandler

    Dim PWM_ABUCK_V_250mA_5p0_Before_trim As New SiteDouble

    Dim PWM_VDDLDO_V_10mA_3p0 As New SiteDouble, PWM_VDDLDO_V_10mA_3p7 As New SiteDouble, PWM_VDDLDO_V_10mA_5p25 As New SiteDouble
    
    Dim PWM_VDDLDO_V_100mA_3p0 As New SiteDouble, PWM_VDDLDO_V_100mA_3p7 As New SiteDouble, PWM_VDDLDO_V_100mA_5p25 As New SiteDouble
    Dim PWM_VDDBAT_I_100mA_3p0 As New SiteDouble, PWM_VDDBAT_I_100mA_3p7 As New SiteDouble, PWM_VDDBAT_I_100mA_5p25 As New SiteDouble
    Dim PWM_VDDLDO_V_150mA_3p0 As New SiteDouble, PWM_VDDLDO_V_150mA_3p7 As New SiteDouble, PWM_VDDLDO_V_150mA_5p25 As New SiteDouble
    Dim PWM_VDDBAT_I_150mA_3p0 As New SiteDouble, PWM_VDDBAT_I_150mA_3p7 As New SiteDouble, PWM_VDDBAT_I_150mA_5p25 As New SiteDouble
    Dim PWM_VDDLDO_V_200mA_3p0 As New SiteDouble, PWM_VDDLDO_V_200mA_3p7 As New SiteDouble, PWM_VDDLDO_V_200mA_5p25 As New SiteDouble
    Dim PWM_VDDBAT_I_200mA_3p0 As New SiteDouble, PWM_VDDBAT_I_200mA_3p7 As New SiteDouble, PWM_VDDBAT_I_200mA_5p25 As New SiteDouble
        
    Dim PWM_Eff_100mA_3p0 As New SiteDouble, PWM_Eff_100mA_3p7 As New SiteDouble, PWM_Eff_100mA_5p25 As New SiteDouble
    Dim PWM_Eff_150mA_3p0 As New SiteDouble, PWM_Eff_150mA_3p7 As New SiteDouble, PWM_Eff_150mA_5p25 As New SiteDouble
    Dim PWM_Eff_200mA_3p0 As New SiteDouble, PWM_Eff_200mA_3p7 As New SiteDouble, PWM_Eff_200mA_5p25 As New SiteDouble
    
    Dim PWM_PMUVDDIOA_I_100mA_3p0 As New SiteDouble, PWM_PMUVDDIOA_I_100mA_3p7 As New SiteDouble, PWM_PMUVDDIOA_I_100mA_5p25 As New SiteDouble
    Dim PWM_PMUVDDIOA_I_150mA_3p0 As New SiteDouble, PWM_PMUVDDIOA_I_150mA_3p7 As New SiteDouble, PWM_PMUVDDIOA_I_150mA_5p25 As New SiteDouble
    Dim PWM_PMUVDDIOA_I_200mA_3p0 As New SiteDouble, PWM_PMUVDDIOA_I_200mA_3p7 As New SiteDouble, PWM_PMUVDDIOA_I_200mA_5p25 As New SiteDouble
       
    Dim PWM_Eff_100mA_3p0_INC_PMUVDDIO As New SiteDouble, PWM_Eff_100mA_3p7_INC_PMUVDDIO As New SiteDouble, PWM_Eff_100mA_5p25_INC_PMUVDDIO As New SiteDouble
    Dim PWM_Eff_150mA_3p0_INC_PMUVDDIO As New SiteDouble, PWM_Eff_150mA_3p7_INC_PMUVDDIO As New SiteDouble, PWM_Eff_150mA_5p25_INC_PMUVDDIO As New SiteDouble
    Dim PWM_Eff_200mA_3p0_INC_PMUVDDIO As New SiteDouble, PWM_Eff_200mA_3p7_INC_PMUVDDIO As New SiteDouble, PWM_Eff_200mA_5p25_INC_PMUVDDIO As New SiteDouble
    
    Dim Show_ChipID As Boolean, trim_enable As Boolean
    If TheExec.EnableWord("PMU_TRIM_EN") Then
        trim_enable = True
    Else
        trim_enable = False
    End If
 
    Dim testTime As Double
    TheHdw.StartStopwatch
    
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU SwitchReg Tests - ASR PWM [B1], [B2], [B3], [B4i], [B4ii], [B5i], [B5ii]"
    TheExec.Datalog.WriteComment "================================================================================================"
    '----------------------------------------- ABUCK in PWM mode (B1) ----------------------------------------------------
    
    '---------------------------------------------------------------------
    'Must remember to reset from sleep mode & Strapping Option if needed -
    '---------------------------------------------------------------------
    'ChipInit CORE_RESET
    
    'Must remember to increase the PMU_VDDIO currange range since we would like to turn on device (WL_REG_ON=High)
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_2mA"
    TheHdw.wait 5 * mS

    '---------------------------------
    'Output Voltage in PWM Mode for B1
    '---------------------------------
    Call Pmu_registerSetup__ASR_PWM_Mode            '# setup PWM Mode
    TheHdw.wait 2 * mS

    'For loading purposes through LD0_VDD1P22 'CSR_VLX = LDO_VDD1P0, ASR_VLX=LD0_VDD1P22
    
    TheHdw.DCVI.pins("ASR_VLX").BleederResistor = tlDCVIBleederResistorAuto
    With TheHdw.DCVI.pins("ASR_VLX")
        .Disconnect (tlDCVIConnectDefault)
        .Mode = tlDCVIModeCurrent
        .Meter.Mode = tlDCVIMeterVoltage
        .Current = -200 * nA
        .Voltage = -1 * v
        .Connect
        .Gate = True
    End With
    TheHdw.wait 2 * mS
 
    '************************************* 10mA Load condition *************************************
    '----------------------------------------
    'VDDBAT = 3.0V, 10mA load at LD0_VDD1P22
    '----------------------------------------
    
    pmutb.Apply_PSET "ASR_VLX", "VDDLDO_10mA_2V"                                    '10mA Load setting at "LD0_VDD1P22"(output of cbuck regulator)
    TheHdw.wait 2 * mS

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_20mA"
    TheHdw.wait 3 * mS

    PWM_VDDLDO_V_10mA_3p0 = pmutb.Meter_Strobe("ASR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 10mA Load (VDDBAT=3.0V)

    '----------------------------------------
    'VDDBAT = 3.7V, 10mA load at LD0_VDD1P22
    '----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    TheHdw.wait 5 * mS

    PWM_VDDLDO_V_10mA_3p7 = pmutb.Meter_Strobe("ASR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 10mA Load (VDDBAT=3.7V)
   
    '----------------------------------------
    'VDDBAT = 5.25V, 10mA load at LD0_VDD1P22
    '----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_20mA"
    TheHdw.wait 5 * mS

    PWM_VDDLDO_V_10mA_5p25 = pmutb.Meter_Strobe("ASR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 10mA Load (VDDBAT=5.25V)
    

    '************************************* Reset 100mA, 150mA, 200mA Load condition *************************************
    '----------------------------------------
    'VDDBAT = 3.0V, 3.7V, 5.25V with 200mA load at LD0_VDD1P22
    '----------------------------------------
    'Ramp down
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    
    ' Common on DCVS setup
    TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Filter.Bypass = False                           'Measure PMU_VDDIO current (required for efficiency calculation)
    TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Filter.Value = 781.25
    
    '************************************* 100mA Load condition *************************************
    
    pmutb.Apply_PSET "ASR_VLX", "VDDLDO_50mA_2V"                                    '50mA Load setting at "LD0_VDD1P22"(output of cbuck regulator)
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "ASR_VLX", "VDDLDO_100mA_2V"                                   '100mA Load setting at "LD0_VDD1P22"(output of cbuck regulator)
    TheHdw.wait 2 * mS
    
    '----------------------------------------
    'VDDBAT = 3.0V, 100mA load at LD0_VDD1P22
    '----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_200mA"
    TheHdw.wait 5 * mS

    PWM_VDDLDO_V_100mA_3p0 = pmutb.Meter_Strobe("ASR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 100mA Load (VDDBAT=3.0V)
    PWM_VDDBAT_I_100mA_3p0 = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 20, 0.5 * mS)            'Measure VDDBAT current(required for efficiency calculation)
    PWM_PMUVDDIOA_I_100mA_3p0 = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 20 * mS, 128, 781.25)
    
    '----------------------------------------
    'VDDBAT = 3.7V, 100mA load at LD0_VDD1P22
    '----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    TheHdw.wait 5 * mS

    PWM_VDDLDO_V_100mA_3p7 = pmutb.Meter_Strobe("ASR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 100mA Load (VDDBAT=3.7V)
    PWM_VDDBAT_I_100mA_3p7 = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 20, 0.5 * mS)            'Measure VDDBAT current(required for efficiency calculation)
    PWM_PMUVDDIOA_I_100mA_3p7 = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 20 * mS, 128, 781.25)
   
    '----------------------------------------
    'VDDBAT = 5.25V, 100mA load at LD0_VDD1P22
    '----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_200mA"
    TheHdw.wait 5 * mS

    PWM_VDDLDO_V_100mA_5p25 = pmutb.Meter_Strobe("ASR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 100mA Load (VDDBAT=5.25V)
    PWM_VDDBAT_I_100mA_5p25 = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 20, 0.5 * mS)            'Measure VDDBAT current(required for efficiency calculation)
    PWM_PMUVDDIOA_I_100mA_5p25 = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 20 * mS, 128, 781.25)
    
    
    '************************************* 150mA Load condition *************************************
    pmutb.Apply_PSET "ASR_VLX", "VDDLDO_150mA_2V"                                   '200mA Load setting at "LD0_VDD1P22"(output of cbuck regulator)
    TheHdw.wait 2 * mS
 
    '----------------------------------------
    'VDDBAT = 3.0V, 150mA load at LD0_VDD1P22
    '----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_200mA"
    TheHdw.wait 5 * mS

    PWM_VDDLDO_V_150mA_3p0 = pmutb.Meter_Strobe("ASR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 150mA Load (VDDBAT=3.0V)
    PWM_VDDBAT_I_150mA_3p0 = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 20, 0.5 * mS)            'Measure VDDBAT current(required for efficiency calculation)
    PWM_PMUVDDIOA_I_150mA_3p0 = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 20 * mS, 128, 781.25)
    
    '----------------------------------------
    'VDDBAT = 3.7V, 150mA load at LD0_VDD1P22
    '----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    TheHdw.wait 5 * mS

    PWM_VDDLDO_V_150mA_3p7 = pmutb.Meter_Strobe("ASR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 150mA Load (VDDBAT=3.7V)
    PWM_VDDBAT_I_150mA_3p7 = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 20, 0.5 * mS)            'Measure VDDBAT current(required for efficiency calculation)
    PWM_PMUVDDIOA_I_150mA_3p7 = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 20 * mS, 128, 781.25)
   
    '----------------------------------------
    'VDDBAT = 5.25V, 150mA load at LD0_VDD1P22
    '----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_200mA"
    TheHdw.wait 5 * mS

    PWM_VDDLDO_V_150mA_5p25 = pmutb.Meter_Strobe("ASR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 150mA Load (VDDBAT=5.25V)
    PWM_VDDBAT_I_150mA_5p25 = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 20, 0.5 * mS)            'Measure VDDBAT current(required for efficiency calculation)
    PWM_PMUVDDIOA_I_150mA_5p25 = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 20 * mS, 128, 781.25)
    
    '************************************* 200mA Load condition *************************************
    pmutb.Apply_PSET "ASR_VLX", "VDDLDO_200mA_2V"                                   '200mA Load setting at "LD0_VDD1P22"(output of cbuck regulator)
    TheHdw.wait 2 * mS
 
    '----------------------------------------
    'VDDBAT = 3.0V, 200mA load at LD0_VDD1P22
    '----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_200mA"
    TheHdw.wait 5 * mS

    PWM_VDDLDO_V_200mA_3p0 = pmutb.Meter_Strobe("ASR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 200mA Load (VDDBAT=3.0V)
    PWM_VDDBAT_I_200mA_3p0 = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 20, 0.5 * mS)            'Measure VDDBAT current(required for efficiency calculation)
    PWM_PMUVDDIOA_I_200mA_3p0 = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 20 * mS, 128, 781.25)
    
    '----------------------------------------
    'VDDBAT = 3.7V, 200mA load at LD0_VDD1P22
    '----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    TheHdw.wait 5 * mS

    PWM_VDDLDO_V_200mA_3p7 = pmutb.Meter_Strobe("ASR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 200mA Load (VDDBAT=3.7V)
    PWM_VDDBAT_I_200mA_3p7 = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 20, 0.5 * mS)            'Measure VDDBAT current(required for efficiency calculation)
    PWM_PMUVDDIOA_I_200mA_3p7 = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 20 * mS, 128, 781.25)
   
    '----------------------------------------
    'VDDBAT = 5.25V, 200mA load at LD0_VDD1P22
    '----------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_200mA"
    TheHdw.wait 5 * mS

    PWM_VDDLDO_V_200mA_5p25 = pmutb.Meter_Strobe("ASR_VLX", 20, 0.5 * mS)            'Measure cbuck output voltage with 200mA Load (VDDBAT=5.25V)
    PWM_VDDBAT_I_200mA_5p25 = pmutb.Meter_Strobe("ET_LINREG_VDD_V5P0", 20, 0.5 * mS)            'Measure VDDBAT current(required for efficiency calculation)
    PWM_PMUVDDIOA_I_200mA_5p25 = pmutb.Meter_Strobe_VS256("PMU_VDDIOP", 1, 20 * mS, 128, 781.25)
    
    
    
    '************************************* Efficiency Calculation *************************************
    
    pmutb.Calc_Eff 3#, 100 * mA, PWM_VDDLDO_V_100mA_3p0, PWM_VDDBAT_I_100mA_3p0, PWM_Eff_100mA_3p0
    pmutb.Calc_Eff 3.7, 100 * mA, PWM_VDDLDO_V_100mA_3p7, PWM_VDDBAT_I_100mA_3p7, PWM_Eff_100mA_3p7
    pmutb.Calc_Eff 5.25, 100 * mA, PWM_VDDLDO_V_100mA_5p25, PWM_VDDBAT_I_100mA_5p25, PWM_Eff_100mA_5p25

    pmutb.Calc_Eff 3#, 150 * mA, PWM_VDDLDO_V_150mA_3p0, PWM_VDDBAT_I_150mA_3p0, PWM_Eff_150mA_3p0
    pmutb.Calc_Eff 3.7, 150 * mA, PWM_VDDLDO_V_150mA_3p7, PWM_VDDBAT_I_150mA_3p7, PWM_Eff_150mA_3p7
    pmutb.Calc_Eff 5.25, 150 * mA, PWM_VDDLDO_V_150mA_5p25, PWM_VDDBAT_I_150mA_5p25, PWM_Eff_150mA_5p25

    pmutb.Calc_Eff 3#, 200 * mA, PWM_VDDLDO_V_200mA_3p0, PWM_VDDBAT_I_200mA_3p0, PWM_Eff_200mA_3p0
    pmutb.Calc_Eff 3.7, 200 * mA, PWM_VDDLDO_V_200mA_3p7, PWM_VDDBAT_I_200mA_3p7, PWM_Eff_200mA_3p7
    pmutb.Calc_Eff 5.25, 200 * mA, PWM_VDDLDO_V_200mA_5p25, PWM_VDDBAT_I_200mA_5p25, PWM_Eff_200mA_5p25

    'Include the PMU_VDDIO current
    pmutb.Calc_Eff_INC_PMU_VDDIO 3#, 100 * mA, PWM_VDDLDO_V_100mA_3p0, PWM_VDDBAT_I_100mA_3p0, 1.8, PWM_PMUVDDIOA_I_100mA_3p0, PWM_Eff_100mA_3p0_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 3.7, 100 * mA, PWM_VDDLDO_V_100mA_3p7, PWM_VDDBAT_I_100mA_3p7, 1.8, PWM_PMUVDDIOA_I_100mA_3p7, PWM_Eff_100mA_3p7_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 5.25, 100 * mA, PWM_VDDLDO_V_100mA_5p25, PWM_VDDBAT_I_100mA_5p25, 1.8, PWM_PMUVDDIOA_I_100mA_5p25, PWM_Eff_100mA_5p25_INC_PMUVDDIO

 
    pmutb.Calc_Eff_INC_PMU_VDDIO 3#, 150 * mA, PWM_VDDLDO_V_150mA_3p0, PWM_VDDBAT_I_150mA_3p0, 1.8, PWM_PMUVDDIOA_I_150mA_3p0, PWM_Eff_150mA_3p0_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 3.7, 150 * mA, PWM_VDDLDO_V_150mA_3p7, PWM_VDDBAT_I_150mA_3p7, 1.8, PWM_PMUVDDIOA_I_150mA_3p7, PWM_Eff_150mA_3p7_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 5.25, 150 * mA, PWM_VDDLDO_V_150mA_5p25, PWM_VDDBAT_I_150mA_5p25, 1.8, PWM_PMUVDDIOA_I_150mA_5p25, PWM_Eff_150mA_5p25_INC_PMUVDDIO

    pmutb.Calc_Eff_INC_PMU_VDDIO 3#, 200 * mA, PWM_VDDLDO_V_200mA_3p0, PWM_VDDBAT_I_200mA_3p0, 1.8, PWM_PMUVDDIOA_I_200mA_3p0, PWM_Eff_200mA_3p0_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 3.7, 200 * mA, PWM_VDDLDO_V_200mA_3p7, PWM_VDDBAT_I_200mA_3p7, 1.8, PWM_PMUVDDIOA_I_200mA_3p7, PWM_Eff_200mA_3p7_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 5.25, 200 * mA, PWM_VDDLDO_V_200mA_5p25, PWM_VDDBAT_I_200mA_5p25, 1.8, PWM_PMUVDDIOA_I_200mA_5p25, PWM_Eff_200mA_5p25_INC_PMUVDDIO

    
    '************************************* Limit Check *************************************
    'ASR Output Voltage in PWM Mode [B1]
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_100mA_3p0, "ASR_VLX", "PMU_ASR_" + "PWM_LDO_V_100mA_3p0")
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_100mA_3p7, "ASR_VLX", "PMU_ASR_" + "PWM_LDO_V_100mA_3p7")
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_100mA_5p25, "ASR_VLX", "PMU_ASR_" + "PWM_LDO_V_100mA_5p25")
    
    Call LimitsTool.TestLimit(PWM_VDDBAT_I_100mA_3p0, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "PWM_VBAT_I_100mA_3p0")
    Call LimitsTool.TestLimit(PWM_VDDBAT_I_100mA_3p7, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "PWM_VBAT_I_100mA_3p7")
    Call LimitsTool.TestLimit(PWM_VDDBAT_I_100mA_5p25, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "PWM_VBAT_I_100mA_5p25")
    
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_150mA_3p0, "ASR_VLX", "PMU_ASR_" + "PWM_LDO_V_150mA_3p0")
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_150mA_3p7, "ASR_VLX", "PMU_ASR_" + "PWM_LDO_V_150mA_3p7")
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_150mA_5p25, "ASR_VLX", "PMU_ASR_" + "PWM_LDO_V_150mA_5p25")
    
    Call LimitsTool.TestLimit(PWM_VDDBAT_I_150mA_3p0, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "PWM_VBAT_I_150mA_3p0")
    Call LimitsTool.TestLimit(PWM_VDDBAT_I_150mA_3p7, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "PWM_VBAT_I_150mA_3p7")
    Call LimitsTool.TestLimit(PWM_VDDBAT_I_150mA_5p25, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "PWM_VBAT_I_150mA_5p25")
    
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_200mA_3p0, "ASR_VLX", "PMU_ASR_" + "PWM_LDO_V_200mA_3p0")
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_200mA_3p7, "ASR_VLX", "PMU_ASR_" + "PWM_LDO_V_200mA_3p7")
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_200mA_5p25, "ASR_VLX", "PMU_ASR_" + "PWM_LDO_V_200mA_5p25")
    
    Call LimitsTool.TestLimit(PWM_VDDBAT_I_200mA_3p0, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "PWM_VBAT_I_200mA_3p0")
    Call LimitsTool.TestLimit(PWM_VDDBAT_I_200mA_3p7, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "PWM_VBAT_I_200mA_3p7")
    Call LimitsTool.TestLimit(PWM_VDDBAT_I_200mA_5p25, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "PWM_VBAT_I_200mA_5p25")
       
    'ASR PWM Load Regulation [B2]
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_10mA_3p0.Subtract(PWM_VDDLDO_V_200mA_3p0).Abs, "ASR_VLX", "PMU_ASR_" + "PWM_LoadReg_3p0_10mA_200mA")
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_10mA_3p7.Subtract(PWM_VDDLDO_V_200mA_3p7).Abs, "ASR_VLX", "PMU_ASR_" + "PWM_LoadReg_3p7_10mA_200mA")
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_10mA_5p25.Subtract(PWM_VDDLDO_V_200mA_5p25).Abs, "ASR_VLX", "PMU_ASR_" + "PWM_LoadReg_5p25_10mA_200mA")
    
    'ASR PWM Line Regulation [B3]
    Call LimitsTool.TestLimit(PWM_VDDLDO_V_200mA_5p25.Subtract(PWM_VDDLDO_V_200mA_3p0).Abs, "ASR_VLX", "PMU_ASR_" + "PWM_LineReg_200mA")
    
    'ASR PWM Efficiency [B4i], [B5i], [B6i]
    Call LimitsTool.TestLimit(PWM_Eff_100mA_3p0, "ASR_VLX", "PMU_ASR_" + "PWM_Eff_100mA_3p0")
    Call LimitsTool.TestLimit(PWM_Eff_100mA_3p7, "ASR_VLX", "PMU_ASR_" + "PWM_Eff_100mA_3p7")
    Call LimitsTool.TestLimit(PWM_Eff_100mA_5p25, "ASR_VLX", "PMU_ASR_" + "PWM_Eff_100mA_5p25")
    
    Call LimitsTool.TestLimit(PWM_Eff_150mA_3p0, "ASR_VLX", "PMU_ASR_" + "PWM_Eff_150mA_3p0")
    Call LimitsTool.TestLimit(PWM_Eff_150mA_3p7, "ASR_VLX", "PMU_ASR_" + "PWM_Eff_150mA_3p7")
    Call LimitsTool.TestLimit(PWM_Eff_150mA_5p25, "ASR_VLX", "PMU_ASR_" + "PWM_Eff_150mA_5p25")
    
    Call LimitsTool.TestLimit(PWM_Eff_200mA_3p0, "ASR_VLX", "PMU_ASR_" + "PWM_Eff_200mA_3p0")
    Call LimitsTool.TestLimit(PWM_Eff_200mA_3p7, "ASR_VLX", "PMU_ASR_" + "PWM_Eff_200mA_3p7")
    Call LimitsTool.TestLimit(PWM_Eff_200mA_5p25, "ASR_VLX", "PMU_ASR_" + "PWM_Eff_200mA_5p25")
    
    'ASR PWM Efficiency with PMU_VDDIO [B4ii], [B5ii], [B6ii]
    Call LimitsTool.TestLimit(PWM_Eff_100mA_3p0_INC_PMUVDDIO, "ASR_VLX", "PMU_ASR_" + "PWM_Eff_100mA_3p0_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(PWM_Eff_100mA_3p7_INC_PMUVDDIO, "ASR_VLX", "PMU_ASR_" + "PWM_Eff_100mA_3p7_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(PWM_Eff_100mA_5p25_INC_PMUVDDIO, "ASR_VLX", "PMU_ASR_" + "PWM_Eff_100mA_5p25_INC_PMU_VDDIO")
    
    Call LimitsTool.TestLimit(PWM_Eff_150mA_3p0_INC_PMUVDDIO, "ASR_VLX", "PMU_ASR_" + "PWM_Eff_150mA_3p0_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(PWM_Eff_150mA_3p7_INC_PMUVDDIO, "ASR_VLX", "PMU_ASR_" + "PWM_Eff_150mA_3p7_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(PWM_Eff_150mA_5p25_INC_PMUVDDIO, "ASR_VLX", "PMU_ASR_" + "PWM_Eff_150mA_5p25_INC_PMU_VDDIO")
    
    Call LimitsTool.TestLimit(PWM_Eff_200mA_3p0_INC_PMUVDDIO, "ASR_VLX", "PMU_ASR_" + "PWM_Eff_200mA_3p0_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(PWM_Eff_200mA_3p7_INC_PMUVDDIO, "ASR_VLX", "PMU_ASR_" + "PWM_Eff_200mA_3p7_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(PWM_Eff_200mA_5p25_INC_PMUVDDIO, "ASR_VLX", "PMU_ASR_" + "PWM_Eff_200mA_5p25_INC_PMU_VDDIO")
    
    If TheExec.Sites.ActiveCount = 0 Then Exit Function
    
    

    '-----------------------------------------------------------------------
    'Must reduce to 50mA and ramp down or else FS Splot Lot measuring 0kHz -
    '-----------------------------------------------------------------------
    pmutb.Apply_PSET "ASR_VLX", "VDDLDO_200mA_2V"                                 '200mA Load setting at "LDO_VDD_1P22"(output of cbuck regulator)
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "ASR_VLX", "VDDLDO_50mA_2V"                                  '50mA Load setting at "LDO_VDD_1P22"(output of cbuck regulator)
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "ASR_VLX", "VDDLDO_0mA_2V"
    TheHdw.wait 2 * mS

    With TheHdw.DCVI.pins("ASR_VLX")
        .Gate = False
        .Disconnect (tlDCVIConnectDefault)
        .Mode = tlDCVIModeHighImpedance
        .BleederResistor = tlDCVIBleederResistorOff
    End With
    
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    TheHdw.wait 2 * mS

    testTime = TheHdw.ReadStopwatch
    TheExec.Datalog.WriteComment ""
    TheExec.Datalog.WriteComment "PMU_SwitchRegTests_ASR_PWM Test time:" & testTime
    TheExec.Datalog.WriteComment ""
    
Exit Function

ErrorHandler:
    If TheExec.Sites.ActiveCount = 0 Then Exit Function              'If last site failed, exit the test and let IGXL cleanup
    TheExec.ErrorLogMessage "VB Error #" & Trim(Str(err.Number)) & " " & err.Description & " in instance " & TheExec.DataManager.InstanceName
    Resume Next

End Function


Public Function PMU__SwitchRegTests_ASR_PFM_LPPFM() As Long

On Error GoTo ErrorHandler

    Dim PFM_VDDLDO_V_0mA_3p0 As New SiteDouble, PFM_VDDLDO_V_0mA_3p7 As New SiteDouble, PFM_VDDLDO_V_0mA_5p25 As New SiteDouble
    Dim PFM_VDDBAT_I_0mA_3p0 As New SiteDouble, PFM_VDDBAT_I_0mA_3p7 As New SiteDouble, PFM_VDDBAT_I_0mA_5p25 As New SiteDouble
    Dim PFM_VDDLDO_V_10mA_3p0 As New SiteDouble, PFM_VDDLDO_V_10mA_3p7 As New SiteDouble, PFM_VDDLDO_V_10mA_5p25 As New SiteDouble
    Dim PFM_VDDBAT_I_10mA_3p0 As New SiteDouble, PFM_VDDBAT_I_10mA_3p7 As New SiteDouble, PFM_VDDBAT_I_10mA_5p25 As New SiteDouble
    Dim PFM_VDDLDO_V_30mA_3p0 As New SiteDouble, PFM_VDDLDO_V_30mA_3p7 As New SiteDouble, PFM_VDDLDO_V_30mA_5p25 As New SiteDouble
    Dim PFM_VDDBAT_I_30mA_3p0 As New SiteDouble, PFM_VDDBAT_I_30mA_3p7 As New SiteDouble, PFM_VDDBAT_I_30mA_5p25 As New SiteDouble
    Dim PFM_VDDLDO_V_40mA_3p0 As New SiteDouble, PFM_VDDLDO_V_40mA_3p7 As New SiteDouble, PFM_VDDLDO_V_40mA_5p25 As New SiteDouble
    Dim PFM_VDDBAT_I_40mA_3p0 As New SiteDouble, PFM_VDDBAT_I_40mA_3p7 As New SiteDouble, PFM_VDDBAT_I_40mA_5p25 As New SiteDouble
    Dim PFM_VDDLDO_V_50mA_3p0 As New SiteDouble, PFM_VDDLDO_V_50mA_3p7 As New SiteDouble, PFM_VDDLDO_V_50mA_5p25 As New SiteDouble
    Dim PFM_VDDBAT_I_50mA_3p0 As New SiteDouble, PFM_VDDBAT_I_50mA_3p7 As New SiteDouble, PFM_VDDBAT_I_50mA_5p25 As New SiteDouble
    
    Dim PFM_Eff_10mA_3p0 As New SiteDouble, PFM_Eff_10mA_3p7 As New SiteDouble, PFM_Eff_10mA_5p25 As New SiteDouble
    Dim PFM_Eff_30mA_3p0 As New SiteDouble, PFM_Eff_30mA_3p7 As New SiteDouble, PFM_Eff_30mA_5p25 As New SiteDouble
    Dim PFM_Eff_50mA_3p0 As New SiteDouble, PFM_Eff_50mA_3p7 As New SiteDouble, PFM_Eff_50mA_5p25 As New SiteDouble
    Dim PFM_PMUVDDIOA_I_10mA_3p0 As New SiteDouble, PFM_PMUVDDIOA_I_10mA_3p7 As New SiteDouble, PFM_PMUVDDIOA_I_10mA_5p25 As New SiteDouble
    Dim PFM_PMUVDDIOA_I_30mA_3p0 As New SiteDouble, PFM_PMUVDDIOA_I_30mA_3p7 As New SiteDouble, PFM_PMUVDDIOA_I_30mA_5p25 As New SiteDouble
    Dim PFM_PMUVDDIOA_I_40mA_3p0 As New SiteDouble, PFM_PMUVDDIOA_I_40mA_3p7 As New SiteDouble, PFM_PMUVDDIOA_I_40mA_5p25 As New SiteDouble
    Dim PFM_PMUVDDIOA_I_50mA_3p0 As New SiteDouble, PFM_PMUVDDIOA_I_50mA_3p7 As New SiteDouble, PFM_PMUVDDIOA_I_50mA_5p25 As New SiteDouble
        
    Dim PFM_Eff_10mA_3p0_INC_PMUVDDIO As New SiteDouble, PFM_Eff_10mA_3p7_INC_PMUVDDIO As New SiteDouble, PFM_Eff_10mA_5p25_INC_PMUVDDIO As New SiteDouble
    Dim PFM_Eff_30mA_3p0_INC_PMUVDDIO As New SiteDouble, PFM_Eff_30mA_3p7_INC_PMUVDDIO As New SiteDouble, PFM_Eff_30mA_5p25_INC_PMUVDDIO As New SiteDouble
    Dim PFM_Eff_40mA_3p0_INC_PMUVDDIO As New SiteDouble, PFM_Eff_40mA_3p7_INC_PMUVDDIO As New SiteDouble, PFM_Eff_40mA_5p25_INC_PMUVDDIO As New SiteDouble
    Dim PFM_Eff_50mA_3p0_INC_PMUVDDIO As New SiteDouble, PFM_Eff_50mA_3p7_INC_PMUVDDIO As New SiteDouble, PFM_Eff_50mA_5p25_INC_PMUVDDIO As New SiteDouble
    
    Dim LPPFM_VDDLDO_V_0mA_3p0 As New SiteDouble, LPPFM_VDDLDO_V_0mA_3p7 As New SiteDouble, LPPFM_VDDLDO_V_0mA_5p25 As New SiteDouble
    Dim LPPFM_VDDBAT_I_0mA_3p0 As New SiteDouble, LPPFM_VDDBAT_I_0mA_3p7 As New SiteDouble, LPPFM_VDDBAT_I_0mA_5p25 As New SiteDouble
    Dim LPPFM_VDDLDO_V_1mA_3p0 As New SiteDouble, LPPFM_VDDLDO_V_1mA_3p7 As New SiteDouble, LPPFM_VDDLDO_V_1mA_5p25 As New SiteDouble
    Dim LPPFM_VDDBAT_I_1mA_3p0 As New SiteDouble, LPPFM_VDDBAT_I_1mA_3p7 As New SiteDouble, LPPFM_VDDBAT_I_1mA_5p25 As New SiteDouble
    
    Dim LPPFM_PMUVDDIOA_I_1mA_3p0 As New SiteDouble, LPPFM_PMUVDDIOA_I_1mA_3p7 As New SiteDouble, LPPFM_PMUVDDIOA_I_1mA_5p25 As New SiteDouble
    
    Dim LPPFM_VDDLDO_V_20mA_3p0 As New SiteDouble, LPPFM_VDDLDO_V_20mA_3p7 As New SiteDouble, LPPFM_VDDLDO_V_20mA_5p25 As New SiteDouble
    Dim LPPFM_VDDBAT_I_20mA_3p0 As New SiteDouble, LPPFM_VDDBAT_I_20mA_3p7 As New SiteDouble, LPPFM_VDDBAT_I_20mA_5p25 As New SiteDouble
    Dim LPPFM_PMUVDDIOA_I_20mA_3p0 As New SiteDouble, LPPFM_PMUVDDIOA_I_20mA_3p7 As New SiteDouble, LPPFM_PMUVDDIOA_I_20mA_5p25 As New SiteDouble
    
    Dim LPPFM_VDDLDO_V_50mA_3p0 As New SiteDouble, LPPFM_VDDLDO_V_50mA_3p7 As New SiteDouble, LPPFM_VDDLDO_V_50mA_5p25 As New SiteDouble
    Dim LPPFM_VDDBAT_I_50mA_3p0 As New SiteDouble, LPPFM_VDDBAT_I_50mA_3p7 As New SiteDouble, LPPFM_VDDBAT_I_50mA_5p25 As New SiteDouble
    Dim LPPFM_PMUVDDIOA_I_50mA_3p0 As New SiteDouble, LPPFM_PMUVDDIOA_I_50mA_3p7 As New SiteDouble, LPPFM_PMUVDDIOA_I_50mA_5p25 As New SiteDouble
    
    Dim LPPFM_Eff_1mA_3p0 As New SiteDouble, LPPFM_Eff_1mA_3p7 As New SiteDouble, LPPFM_Eff_1mA_5p25 As New SiteDouble
    Dim LPPFM_Eff_20mA_3p0 As New SiteDouble, LPPFM_Eff_20mA_3p7 As New SiteDouble, LPPFM_Eff_20mA_5p25 As New SiteDouble
    Dim LPPFM_Eff_50mA_3p0 As New SiteDouble, LPPFM_Eff_50mA_3p7 As New SiteDouble, LPPFM_Eff_50mA_5p25 As New SiteDouble
    
    Dim LPPFM_Eff_1mA_3p0_INC_PMUVDDIO As New SiteDouble, LPPFM_Eff_1mA_3p7_INC_PMUVDDIO As New SiteDouble, LPPFM_Eff_1mA_5p25_INC_PMUVDDIO As New SiteDouble
    Dim LPPFM_Eff_20mA_3p0_INC_PMUVDDIO As New SiteDouble, LPPFM_Eff_20mA_3p7_INC_PMUVDDIO As New SiteDouble, LPPFM_Eff_20mA_5p25_INC_PMUVDDIO As New SiteDouble
    Dim LPPFM_Eff_50mA_3p0_INC_PMUVDDIO As New SiteDouble, LPPFM_Eff_50mA_3p7_INC_PMUVDDIO As New SiteDouble, LPPFM_Eff_50mA_5p25_INC_PMUVDDIO As New SiteDouble
    
    Dim Show_ChipID As Boolean

    Dim testTime As Double
    TheHdw.StartStopwatch
    
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU SwitchReg Tests - ASR PFM [B6], [B7], [B8i], [B8ii], [B9i], [B9ii], [B10i], [B10ii]"
    TheExec.Datalog.WriteComment "================================================================================================"
    
    TheHdw.DCVI.pins("ASR_VLX").BleederResistor = tlDCVIBleederResistorAuto
    With TheHdw.DCVI.pins("ASR_VLX")
        .Disconnect tlDCVIConnectDefault
         .Mode = tlDCVIModeCurrent
         .Meter.Mode = tlDCVIMeterVoltage
         .Current = -200 * nA
         .Voltage = -0.5 * v
         .Connect
         .Gate = True
     End With
     TheHdw.wait 1 * mS
    '----------------------------------------- ABUCK in PFM mode (B6) -------------------------------------------------------------------------------------------------------------------------------------------------------
    
    '---------------------------------------------------------------------
    'Must remember to reset from sleep mode & Strapping Option if needed -
    '---------------------------------------------------------------------
    'ChipInit CORE_RESET
    
    'Must remember to increase the PMU_VDDIO currange range since we would like to turn on device (WL_REG_ON=High)
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_2mA"
    TheHdw.wait 5 * mS

    '----------------------------------
    'Output Voltage in PFM Mode for B6
    '----------------------------------
    Call Pmu_registerSetup__ASR_PFM_Mode        '# setup PFM Mode
    TheHdw.wait 10 * mS 'test time reduction 10 to 5
    
    '********************************************* 0mA Load condition *************************************
    pmutb.Apply_PSET "ASR_VLX", "VDDLDO_0mA_2V"                                      '0mA Load setting at "LDO_VDD1P22__P3_SENSE"(output of cbuck regulator)
    
    '# Measure Q Current
    
    TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Filter.Value = 10000
    TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Filter.Bypass = False
    TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Filter.Bypass = False
    TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Filter.Value = 781.25
    
    TheHdw.DCVI("ET_LINREG_VDD_V5P0").Alarm(tlDCVIAlarmOverRange Or tlDCVIAlarmMode) = tlAlarmOff      '# Turn OFF mode alarm @0mA load - spike issue

    '--------------------------------------
    'VDDBAT = 3.0V, 0mA load at LDO_VDD1P22
    '--------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_2mA"
    TheHdw.wait 10 * mS
    PFM_VDDBAT_I_0mA_3p0 = pmu__PFM_LPPFM__QCurrent__IgnoreSpkie("ET_LINREG_VDD_V5P0", 5, 0, 40 * uA)
    PFM_VDDLDO_V_0mA_3p0 = pmutb.Meter_Strobe("ASR_VLX", 20, 0.5 * mS)

    '--------------------------------------
    'VDDBAT = 3.7V, 0mA load at LDO_VDD1P22
    '--------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_2mA"
    TheHdw.wait 5 * mS 'test time reduction 10 to 5
    PFM_VDDBAT_I_0mA_3p7 = pmu__PFM_LPPFM__QCurrent__IgnoreSpkie("ET_LINREG_VDD_V5P0", 5, 0, 40 * uA)
    PFM_VDDLDO_V_0mA_3p7 = pmutb.Meter_Strobe("ASR_VLX", 20, 0.5 * mS)

    '--------------------------------------
    'VDDBAT = 5.25V, 0mA load at LDO_VDD2P22
    '--------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_2mA"
    TheHdw.wait 5 * mS 'test time reduction 10 to 5
    PFM_VDDBAT_I_0mA_5p25 = pmu__PFM_LPPFM__QCurrent__IgnoreSpkie("ET_LINREG_VDD_V5P0", 5, 0, 40 * uA)
    PFM_VDDLDO_V_0mA_5p25 = pmutb.Meter_Strobe("ASR_VLX", 20, 0.5 * mS)

    TheHdw.DCVI("ET_LINREG_VDD_V5P0").Alarm(tlDCVIAlarmOverRange Or tlDCVIAlarmMode) = tlAlarmDefault      '# Turn ON mode alarm at the end of @0mA load
   
    '************************************* 10mA Load condition *************************************
    
    '---------------------------------------
    'VDDBAT = 3.0V, 10mA load at LDO_VDD1P22
    '---------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    pmutb.Apply_PSET "ASR_VLX", "VDDLDO_10mA_2V"                                    '10mA Load setting at "LDO_VDD1P22__P3_SENSE"(output of cbuck regulator)
    TheHdw.wait 2 * mS

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_20mA"
    TheHdw.wait 5 * mS
    
    'Where to get this pattern???
    'Measure PMU_VDDBAT5 and LDO_VDD1P22 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_ASR_LOOP20")
    TheHdw.Digital.Patgen.HaltWait

    PFM_VDDLDO_V_10mA_3p0 = TheHdw.DCVI.pins("ASR_VLX").Meter.Read(tlNoStrobe, 20)
    PFM_VDDBAT_I_10mA_3p0 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 20)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIOP_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    PFM_PMUVDDIOA_I_10mA_3p0 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    '---------------------------------------
    'VDDBAT = 3.7V, 10mA load at LDO_VDD1P22
    '---------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    TheHdw.wait 5 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P12 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_ASR_LOOP20")
    TheHdw.Digital.Patgen.HaltWait

    PFM_VDDLDO_V_10mA_3p7 = TheHdw.DCVI.pins("ASR_VLX").Meter.Read(tlNoStrobe, 20)
    PFM_VDDBAT_I_10mA_3p7 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 20)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIOP_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    PFM_PMUVDDIOA_I_10mA_3p7 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    

    '---------------------------------------
    'VDDBAT = 5.25V, 10mA load at LDO_VDD1P22
    '---------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_20mA"
    TheHdw.wait 5 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P12 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_ASR_LOOP20")
    TheHdw.Digital.Patgen.HaltWait

    PFM_VDDLDO_V_10mA_5p25 = TheHdw.DCVI.pins("ASR_VLX").Meter.Read(tlNoStrobe, 20)
    PFM_VDDBAT_I_10mA_5p25 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 20)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIOP_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    PFM_PMUVDDIOA_I_10mA_5p25 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)

    
    '************************************* 30mA Load condition *************************************
    '---------------------------------------
    'VDDBAT = 3.0V, 30mA load at LDO_VDD1P22
    '---------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    pmutb.Apply_PSET "ASR_VLX", "VDDLDO_30mA_2V"                                    '30mA Load setting at "LDO_VDD1P22__P3_SENSE"(output of cbuck regulator)
    TheHdw.wait 3 * mS

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_20mA"
    TheHdw.wait 5 * mS
    
    'Measure PMU_VDDBAT5 and LDO_VDD1P12 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_ASR_LOOP20")
    TheHdw.Digital.Patgen.HaltWait

    PFM_VDDLDO_V_30mA_3p0 = TheHdw.DCVI.pins("ASR_VLX").Meter.Read(tlNoStrobe, 20)
    PFM_VDDBAT_I_30mA_3p0 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 20)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIOP_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    PFM_PMUVDDIOA_I_30mA_3p0 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    '---------------------------------------
    'VDDBAT = 3.7V, 30mA load at LDO_VDD1P22
    '---------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    TheHdw.wait 5 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P12 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_ASR_LOOP20")
    TheHdw.Digital.Patgen.HaltWait

    PFM_VDDLDO_V_30mA_3p7 = TheHdw.DCVI.pins("ASR_VLX").Meter.Read(tlNoStrobe, 20)
    PFM_VDDBAT_I_30mA_3p7 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 20)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIOP_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    PFM_PMUVDDIOA_I_30mA_3p7 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
        
    '---------------------------------------
    'VDDBAT = 5.25V, 30mA load at LDO_VDD1P22
    '---------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_20mA"
    TheHdw.wait 5 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P12 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_ASR_LOOP20")
    TheHdw.Digital.Patgen.HaltWait

    PFM_VDDLDO_V_30mA_5p25 = TheHdw.DCVI.pins("ASR_VLX").Meter.Read(tlNoStrobe, 20)
    PFM_VDDBAT_I_30mA_5p25 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 20)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIOP_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    PFM_PMUVDDIOA_I_30mA_5p25 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
        
    
    '************************************* 50mA Load condition *************************************
    '---------------------------------------
    'VDDBAT = 3.0V, 50mA load at LDO_VDD1P22
    '---------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    
    pmutb.Apply_PSET "ASR_VLX", "VDDLDO_50mA_2V"                                    '50mA Load setting at "LDO_VDD1P22__P3_SENSE"(output of cbuck regulator)
    TheHdw.wait 3 * mS

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_200mA"
    TheHdw.wait 5 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P22 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_ASR_LOOP20")
    TheHdw.Digital.Patgen.HaltWait

    PFM_VDDLDO_V_50mA_3p0 = TheHdw.DCVI.pins("ASR_VLX").Meter.Read(tlNoStrobe, 20)
    PFM_VDDBAT_I_50mA_3p0 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 20)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIOP_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    PFM_PMUVDDIOA_I_50mA_3p0 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    '---------------------------------------
    'VDDBAT = 3.7V, 50mA load at LDO_VDD1P22
    '---------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    TheHdw.wait 5 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P12 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_ASR_LOOP20")
    TheHdw.Digital.Patgen.HaltWait

    PFM_VDDLDO_V_50mA_3p7 = TheHdw.DCVI.pins("ASR_VLX").Meter.Read(tlNoStrobe, 20)
    PFM_VDDBAT_I_50mA_3p7 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 20)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIOP_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    PFM_PMUVDDIOA_I_50mA_3p7 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    
    '---------------------------------------
    'VDDBAT = 5.25V, 50mA load at LDO_VDD1P22
    '---------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_200mA"
    TheHdw.wait 5 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P12 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_ASR_LOOP20")
    TheHdw.Digital.Patgen.HaltWait

    PFM_VDDLDO_V_50mA_5p25 = TheHdw.DCVI.pins("ASR_VLX").Meter.Read(tlNoStrobe, 20)
    PFM_VDDBAT_I_50mA_5p25 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 20)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIOP_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    PFM_PMUVDDIOA_I_50mA_5p25 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)

    '------------------------------------
    'Must reduce to 10mA and ramp down  -
    '------------------------------------
    
    pmutb.Apply_PSET "ASR_VLX", "VDDLDO_10mA_2V"                                    '10mA Load setting at "LDO_VDD1P22__P3_SENSE"(output of cbuck regulator)
    TheHdw.wait 2 * mS

    pmutb.Apply_PSET "ASR_VLX", "VDDLDO_0mA_2V"                                     '0mA Load setting at "LDO_VDD1P22__P3_SENSE"(output of cbuck regulator)
    TheHdw.wait 1 * mS
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    TheHdw.wait 1 * mS
    
    'Clear register
    Call Pmu_registerSetup__clearUDR            '# Clear UDR register

    '************************************* Efficiency Calculation *************************************
    pmutb.Calc_Eff 3#, 10 * mA, PFM_VDDLDO_V_10mA_3p0, PFM_VDDBAT_I_10mA_3p0, PFM_Eff_10mA_3p0
    pmutb.Calc_Eff 3.7, 10 * mA, PFM_VDDLDO_V_10mA_3p7, PFM_VDDBAT_I_10mA_3p7, PFM_Eff_10mA_3p7
    pmutb.Calc_Eff 5.25, 10 * mA, PFM_VDDLDO_V_10mA_5p25, PFM_VDDBAT_I_10mA_5p25, PFM_Eff_10mA_5p25

    pmutb.Calc_Eff 3#, 30 * mA, PFM_VDDLDO_V_30mA_3p0, PFM_VDDBAT_I_30mA_3p0, PFM_Eff_30mA_3p0
    pmutb.Calc_Eff 3.7, 30 * mA, PFM_VDDLDO_V_30mA_3p7, PFM_VDDBAT_I_30mA_3p7, PFM_Eff_30mA_3p7
    pmutb.Calc_Eff 5.25, 30 * mA, PFM_VDDLDO_V_30mA_5p25, PFM_VDDBAT_I_30mA_5p25, PFM_Eff_30mA_5p25

    pmutb.Calc_Eff 3#, 50 * mA, PFM_VDDLDO_V_50mA_3p0, PFM_VDDBAT_I_50mA_3p0, PFM_Eff_50mA_3p0
    pmutb.Calc_Eff 3.7, 50 * mA, PFM_VDDLDO_V_50mA_3p7, PFM_VDDBAT_I_50mA_3p7, PFM_Eff_50mA_3p7
    pmutb.Calc_Eff 5.25, 50 * mA, PFM_VDDLDO_V_50mA_5p25, PFM_VDDBAT_I_50mA_5p25, PFM_Eff_50mA_5p25
    
    'Include the PMU_VDDIO current
    pmutb.Calc_Eff_INC_PMU_VDDIO 3#, 10 * mA, PFM_VDDLDO_V_10mA_3p0, PFM_VDDBAT_I_10mA_3p0, 1.8, PFM_PMUVDDIOA_I_10mA_3p0, PFM_Eff_10mA_3p0_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 3.7, 10 * mA, PFM_VDDLDO_V_10mA_3p7, PFM_VDDBAT_I_10mA_3p7, 1.8, PFM_PMUVDDIOA_I_10mA_3p7, PFM_Eff_10mA_3p7_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 5.25, 10 * mA, PFM_VDDLDO_V_10mA_5p25, PFM_VDDBAT_I_10mA_5p25, 1.8, PFM_PMUVDDIOA_I_10mA_5p25, PFM_Eff_10mA_5p25_INC_PMUVDDIO

    pmutb.Calc_Eff_INC_PMU_VDDIO 3#, 30 * mA, PFM_VDDLDO_V_30mA_3p0, PFM_VDDBAT_I_30mA_3p0, 1.8, PFM_PMUVDDIOA_I_30mA_3p0, PFM_Eff_30mA_3p0_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 3.7, 30 * mA, PFM_VDDLDO_V_30mA_3p7, PFM_VDDBAT_I_30mA_3p7, 1.8, PFM_PMUVDDIOA_I_30mA_3p7, PFM_Eff_30mA_3p7_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 5.25, 30 * mA, PFM_VDDLDO_V_30mA_5p25, PFM_VDDBAT_I_30mA_5p25, 1.8, PFM_PMUVDDIOA_I_30mA_5p25, PFM_Eff_30mA_5p25_INC_PMUVDDIO

    pmutb.Calc_Eff_INC_PMU_VDDIO 3#, 50 * mA, PFM_VDDLDO_V_50mA_3p0, PFM_VDDBAT_I_50mA_3p0, 1.8, PFM_PMUVDDIOA_I_50mA_3p0, PFM_Eff_50mA_3p0_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 3.7, 50 * mA, PFM_VDDLDO_V_50mA_3p7, PFM_VDDBAT_I_50mA_3p7, 1.8, PFM_PMUVDDIOA_I_50mA_3p7, PFM_Eff_50mA_3p7_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 5.25, 50 * mA, PFM_VDDLDO_V_50mA_5p25, PFM_VDDBAT_I_50mA_5p25, 1.8, PFM_PMUVDDIOA_I_50mA_5p25, PFM_Eff_50mA_5p25_INC_PMUVDDIO

    '************************************* Limit Check *************************************
    
    'ASR PFM Mode [B6]
    '0mA Load [B6]
If (Device.Flow <> QUAL) Then
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_0mA_3p0, "ASR_VLX", "PMU_ASR_" + "PFM_LDO_V_0mA_3p0")
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_0mA_3p7, "ASR_VLX", "PMU_ASR_" + "PFM_LDO_V_0mA_3p7")
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_0mA_5p25, "ASR_VLX", "PMU_ASR_" + "PFM_LDO_V_0mA_5p25")
End If

    'ASR PFM Quiescent current [B7]
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_0mA_3p0, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "PFM_QCurrent_3p0")
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_0mA_3p7, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "PFM_Qcurrent_3p7")
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_0mA_5p25, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "PFM_Qcurrent_5p25")
        
    '10mA Load [B6]
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_10mA_3p0, "ASR_VLX", "PMU_ASR_" + "PFM_LDO_V_10mA_3p0")
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_10mA_3p7, "ASR_VLX", "PMU_ASR_" + "PFM_LDO_V_10mA_3p7")
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_10mA_5p25, "ASR_VLX", "PMU_ASR_" + "PFM_LDO_V_10mA_5p25")
    
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_10mA_3p0, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "PFM_VBAT_I_10mA_3p0")
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_10mA_3p7, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "PFM_VBAT_I_10mA_3p7")
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_10mA_5p25, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "PFM_VBAT_I_10mA_5p25")
    
    Call LimitsTool.TestLimit(PFM_PMUVDDIOA_I_10mA_3p0, "PMU_VDDIOP", "PMU_ASR_" + "PFM_PMUVDDIO_I_10mA_3p0")
    Call LimitsTool.TestLimit(PFM_PMUVDDIOA_I_10mA_3p7, "PMU_VDDIOP", "PMU_ASR_" + "PFM_PMUVDDIO_I_10mA_3p7")
    Call LimitsTool.TestLimit(PFM_PMUVDDIOA_I_10mA_5p25, "PMU_VDDIOP", "PMU_ASR_" + "PFM_PMUVDDIO_I_10mA_5p25")
    
    '30mA Load [B6]
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_30mA_3p0, "ASR_VLX", "PMU_ASR_" + "PFM_LDO_V_30mA_3p0")
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_30mA_3p7, "ASR_VLX", "PMU_ASR_" + "PFM_LDO_V_30mA_3p7")
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_30mA_5p25, "ASR_VLX", "PMU_ASR_" + "PFM_LDO_V_30mA_5p25")
    
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_30mA_3p0, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "PFM_VBAT_I_30mA_3p0")
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_30mA_3p7, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "PFM_VBAT_I_30mA_3p7")
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_30mA_5p25, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "PFM_VBAT_I_30mA_5p25")
    
    Call LimitsTool.TestLimit(PFM_PMUVDDIOA_I_30mA_3p0, "PMU_VDDIOP", "PMU_ASR_" + "PFM_PMUVDDIO_I_30mA_3p0")
    Call LimitsTool.TestLimit(PFM_PMUVDDIOA_I_30mA_3p7, "PMU_VDDIOP", "PMU_ASR_" + "PFM_PMUVDDIO_I_30mA_3p7")
    Call LimitsTool.TestLimit(PFM_PMUVDDIOA_I_30mA_5p25, "PMU_VDDIOP", "PMU_ASR_" + "PFM_PMUVDDIO_I_30mA_5p25")
    
    '50mA Load [B6]
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_50mA_3p0, "ASR_VLX", "PMU_ASR_" + "PFM_LDO_V_50mA_3p0")
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_50mA_3p7, "ASR_VLX", "PMU_ASR_" + "PFM_LDO_V_50mA_3p7")
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_50mA_5p25, "ASR_VLX", "PMU_ASR_" + "PFM_LDO_V_50mA_5p0")
    
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_50mA_3p0, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "PFM_VBAT_I_50mA_3p0")
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_50mA_3p7, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "PFM_VBAT_I_50mA_3p7")
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_50mA_5p25, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "PFM_VBAT_I_50mA_5p25")
    
    Call LimitsTool.TestLimit(PFM_PMUVDDIOA_I_50mA_3p0, "PMU_VDDIOP", "PMU_ASR_" + "PFM_PMUVDDIO_I_50mA_3p0")
    Call LimitsTool.TestLimit(PFM_PMUVDDIOA_I_50mA_3p7, "PMU_VDDIOP", "PMU_ASR_" + "PFM_PMUVDDIO_I_50mA_3p7")
    Call LimitsTool.TestLimit(PFM_PMUVDDIOA_I_50mA_5p25, "PMU_VDDIOP", "PMU_ASR_" + "PFM_PMUVDDIO_I_50mA_5p25")
    
    
    'ASR PFM Efficiency
    Call LimitsTool.TestLimit(PFM_Eff_10mA_3p0, "ASR_VLX", "PMU_ASR_" + "PFM_Eff_10mA_3p0")     '[B8i]
    Call LimitsTool.TestLimit(PFM_Eff_10mA_3p7, "ASR_VLX", "PMU_ASR_" + "PFM_Eff_10mA_3p7")
    Call LimitsTool.TestLimit(PFM_Eff_10mA_5p25, "ASR_VLX", "PMU_ASR_" + "PFM_Eff_10mA_5p25")
    
    Call LimitsTool.TestLimit(PFM_Eff_30mA_3p0, "ASR_VLX", "PMU_ASR_" + "PFM_Eff_30mA_3p0")     '[B9i]
    Call LimitsTool.TestLimit(PFM_Eff_30mA_3p7, "ASR_VLX", "PMU_ASR_" + "PFM_Eff_30mA_3p7")
    Call LimitsTool.TestLimit(PFM_Eff_30mA_5p25, "ASR_VLX", "PMU_ASR_" + "PFM_Eff_30mA_5p25")
    
    Call LimitsTool.TestLimit(PFM_Eff_50mA_3p0, "ASR_VLX", "PMU_ASR_" + "PFM_Eff_50mA_3p0")     '[B10i]
    Call LimitsTool.TestLimit(PFM_Eff_50mA_3p7, "ASR_VLX", "PMU_ASR_" + "PFM_Eff_50mA_3p7")
    Call LimitsTool.TestLimit(PFM_Eff_50mA_5p25, "ASR_VLX", "PMU_ASR_" + "PFM_Eff_50mA_5p25")
    
    Call LimitsTool.TestLimit(PFM_Eff_10mA_3p0_INC_PMUVDDIO, "PMU_VDDIOP", "PMU_ASR_" + "PFM_Eff_10mA_3p0_INC_PMU_VDDIO")      '[B8ii]
    Call LimitsTool.TestLimit(PFM_Eff_10mA_3p7_INC_PMUVDDIO, "PMU_VDDIOP", "PMU_ASR_" + "PFM_Eff_10mA_3p7_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(PFM_Eff_10mA_5p25_INC_PMUVDDIO, "PMU_VDDIOP", "PMU_ASR_" + "PFM_Eff_10mA_5p25_INC_PMU_VDDIO")
    
    Call LimitsTool.TestLimit(PFM_Eff_30mA_3p0_INC_PMUVDDIO, "PMU_VDDIOP", "PMU_ASR_" + "PFM_Eff_30mA_3p0_INC_PMU_VDDIO")      '[B9ii]
    Call LimitsTool.TestLimit(PFM_Eff_30mA_3p7_INC_PMUVDDIO, "PMU_VDDIOP", "PMU_ASR_" + "PFM_Eff_30mA_3p7_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(PFM_Eff_30mA_5p25_INC_PMUVDDIO, "PMU_VDDIOP", "PMU_ASR_" + "PFM_Eff_30mA_5p25_INC_PMU_VDDIO")
    
    Call LimitsTool.TestLimit(PFM_Eff_50mA_3p0_INC_PMUVDDIO, "PMU_VDDIOP", "PMU_ASR_" + "PFM_Eff_50mA_3p0_INC_PMU_VDDIO")      '[B10ii]
    Call LimitsTool.TestLimit(PFM_Eff_50mA_3p7_INC_PMUVDDIO, "PMU_VDDIOP", "PMU_ASR_" + "PFM_Eff_50mA_3p7_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(PFM_Eff_50mA_5p25_INC_PMUVDDIO, "PMU_VDDIOP", "PMU_ASR_" + "PFM_Eff_50mA_5p25_INC_PMU_VDDIO")

    If TheExec.Sites.ActiveCount = 0 Then Exit Function

'''    If Show_ChipID Then
'''        For Each Site In TheExec.Sites
'''            TheExec.Datalog.WriteComment "AXI Chip ID (Real Chip ID): " & Hex(AXI.ReadReg("18000000")(Site))
'''        Next Site
'''    End If

    testTime = TheHdw.ReadStopwatch
    TheExec.Datalog.WriteComment ""
    TheExec.Datalog.WriteComment "PMU_SwitchRegTests_ASR_PFM Test time:" & testTime
    TheExec.Datalog.WriteComment ""
    
'----------------------------------------- ABUCK in LPPFM mode -------------------------------------------------------------------------------------------------------------------------------------------------------
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU SwitchReg Tests - ASR LPPFM [B11], [B12], [B13i], [B13ii], [B14i], [B14ii], [B15i], [B15ii]"
    TheExec.Datalog.WriteComment "================================================================================================"
    
'''    TheHdw.DCVI.pins("ASR_VLX").BleederResistor = tlDCVIBleederResistorAuto
'''    With TheHdw.DCVI.pins("ASR_VLX")
'''         .mode = tlDCVIModeCurrent
'''         .Meter.mode = tlDCVIMeterVoltage
'''         .Current = -200 * nA
'''         .Voltage = -0.5 * v
'''         .Connect
'''         .Gate = True
'''     End With
'''     TheHdw.wait 1 * mS
    
    '---------------------------------------------------------------------
    'Must remember to reset from sleep mode & Strapping Option if needed -
    '---------------------------------------------------------------------
    
    'Must remember to increase the PMU_VDDIO currange range since we would like to turn on device (WL_REG_ON=High)
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_2mA"
    TheHdw.wait 5 * mS
    '-----------------------------------------
    'Output Voltage in Low Power Mode for B11
    '-----------------------------------------
    Call Pmu_registerSetup__ASR_LPPFM_Mode      '# setup LPPFM Mode
    TheHdw.wait 10 * mS 'test time reduction 10 to 5
    
    '********************************************* 0mA Load condition *************************************
 
    pmutb.Apply_PSET "ASR_VLX", "VDDLDO_0mA_2V"                                     '0mA Load setting at "LDO_VDD1P22__P3_SENSE"(output of cbuck regulator)
    TheHdw.wait 2 * mS
    
    '# Q Current Meassurement
    TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Filter.Value = 10000
    TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Filter.Bypass = False
    TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Filter.Bypass = False
    TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Filter.Value = 781.25
    
    TheHdw.DCVI("ET_LINREG_VDD_V5P0").Alarm(tlDCVIAlarmOverRange Or tlDCVIAlarmMode) = tlAlarmOff      '# Turn OFF mode alarm @0mA load - spike issue
   '--------------------------------------
    'VDDBAT = 3.0V, 0mA load at LDO_VDD1P22
    '--------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_2mA"
    TheHdw.wait 5 * mS
    LPPFM_VDDBAT_I_0mA_3p0 = pmu__PFM_LPPFM__QCurrent__IgnoreSpkie("ET_LINREG_VDD_V5P0", 5, 0, 40 * uA)
    LPPFM_VDDLDO_V_0mA_3p0 = pmutb.Meter_Strobe("ASR_VLX", 20, 0.5 * mS)


    '--------------------------------------
    'VDDBAT = 3.7V, 0mA load at LDO_VDD1P22
    '--------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_2mA"
    TheHdw.wait 5 * mS
    LPPFM_VDDBAT_I_0mA_3p7 = pmu__PFM_LPPFM__QCurrent__IgnoreSpkie("ET_LINREG_VDD_V5P0", 5, 0, 40 * uA)
    LPPFM_VDDLDO_V_0mA_3p7 = pmutb.Meter_Strobe("ASR_VLX", 20, 0.5 * mS)
        
    '--------------------------------------
    'VDDBAT = 5.25V, 0mA load at LDO_VDD1P22
    '--------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_2mA"
    TheHdw.wait 5 * mS
    LPPFM_VDDBAT_I_0mA_5p25 = pmu__PFM_LPPFM__QCurrent__IgnoreSpkie("ET_LINREG_VDD_V5P0", 5, 0, 40 * uA)
    LPPFM_VDDLDO_V_0mA_5p25 = pmutb.Meter_Strobe("ASR_VLX", 20, 0.5 * mS)
   
    TheHdw.DCVI("ET_LINREG_VDD_V5P0").Alarm(tlDCVIAlarmOverRange Or tlDCVIAlarmMode) = tlAlarmDefault      '# Turn ON mode alarm at the end of @0mA load
    
    '************************************* 1mA Load condition *************************************
    
    '-------------------------------------------------
    'VDDBAT = 3.0V, 1mA load at LDO_VDD1P22__P3_SENSE
    '-------------------------------------------------

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "ASR_VLX", "VDDLDO_1mA_2V"                                     '1mA Load setting at "LDO_VDD1P22__P3_SENSE"(output of cbuck regulator)
    TheHdw.wait 2 * mS

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_20mA"
    TheHdw.wait 5 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P22 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_VDD1P12_LOOP100")
    TheHdw.Digital.Patgen.HaltWait

    LPPFM_VDDLDO_V_1mA_3p0 = TheHdw.DCVI.pins("ASR_VLX").Meter.Read(tlNoStrobe, 100)
    LPPFM_VDDBAT_I_1mA_3p0 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 100)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIO_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    LPPFM_PMUVDDIOA_I_1mA_3p0 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    '-------------------------------------------------
    'VDDBAT = 3.7V, 1mA load at LDO_VDD1P22__P3_SENSE
    '-------------------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    TheHdw.wait 5 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P22 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_VDD1P12_LOOP100")
    TheHdw.Digital.Patgen.HaltWait

    LPPFM_VDDLDO_V_1mA_3p7 = TheHdw.DCVI.pins("ASR_VLX").Meter.Read(tlNoStrobe, 100)
    LPPFM_VDDBAT_I_1mA_3p7 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 100)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIO_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    LPPFM_PMUVDDIOA_I_1mA_3p7 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    '-------------------------------------------------
    'VDDBAT = 5.25V, 1mA load at LDO_VDD1P22__P3_SENSE
    '-------------------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_20mA"
    TheHdw.wait 5 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P22 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_VDD1P12_LOOP100")
    TheHdw.Digital.Patgen.HaltWait

    LPPFM_VDDLDO_V_1mA_5p25 = TheHdw.DCVI.pins("ASR_VLX").Meter.Read(tlNoStrobe, 100)
    LPPFM_VDDBAT_I_1mA_5p25 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 100)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIO_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    LPPFM_PMUVDDIOA_I_1mA_5p25 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    
    '************************************* 20mA Load condition *************************************
    
    '-------------------------------------------------
    'VDDBAT = 3.0V, 20mA load at LDO_VDD1P22__P3_SENSE
    '-------------------------------------------------
    'Ramp down
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "ASR_VLX", "VDDLDO_20mA_2V"                                     '20mA Load setting at "LDO_VDD1P22__P3_SENSE"(output of cbuck regulator)
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_20mA"
    TheHdw.wait 2 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P22 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_VDD1P12_LOOP100")
    TheHdw.Digital.Patgen.HaltWait

    LPPFM_VDDLDO_V_20mA_3p0 = TheHdw.DCVI.pins("ASR_VLX").Meter.Read(tlNoStrobe, 100)
    LPPFM_VDDBAT_I_20mA_3p0 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 100)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIO_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    LPPFM_PMUVDDIOA_I_20mA_3p0 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    '-------------------------------------------------
    'VDDBAT = 3.7V, 20mA load at LDO_VDD1P22__P3_SENSE
    '-------------------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    TheHdw.wait 2 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P22 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_VDD1P12_LOOP100")
    TheHdw.Digital.Patgen.HaltWait

    LPPFM_VDDLDO_V_20mA_3p7 = TheHdw.DCVI.pins("ASR_VLX").Meter.Read(tlNoStrobe, 100)
    LPPFM_VDDBAT_I_20mA_3p7 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 100)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIO_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    LPPFM_PMUVDDIOA_I_20mA_3p7 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    '-------------------------------------------------
    'VDDBAT = 5.25V, 20mA load at LDO_VDD1P22__P3_SENSE
    '-------------------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_20mA"
    TheHdw.wait 2 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P22 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_VDD1P12_LOOP100")
    TheHdw.Digital.Patgen.HaltWait

    LPPFM_VDDLDO_V_20mA_5p25 = TheHdw.DCVI.pins("ASR_VLX").Meter.Read(tlNoStrobe, 100)
    LPPFM_VDDBAT_I_20mA_5p25 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 100)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIO_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    LPPFM_PMUVDDIOA_I_20mA_5p25 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    '************************************* 50mA Load condition *************************************
    
    '-------------------------------------------------
    'VDDBAT = 3.0V, 50mA load at LDO_VDD1P22__P3_SENSE
    '-------------------------------------------------
    'Ramp down
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "ASR_VLX", "VDDLDO_50mA_2V"                                     '20mA Load setting at "LDO_VDD1P22__P3_SENSE"(output of cbuck regulator)
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_20mA"
    TheHdw.wait 2 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P22 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_VDD1P12_LOOP100")
    TheHdw.Digital.Patgen.HaltWait

    LPPFM_VDDLDO_V_50mA_3p0 = TheHdw.DCVI.pins("ASR_VLX").Meter.Read(tlNoStrobe, 100)
    LPPFM_VDDBAT_I_50mA_3p0 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 100)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIO_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    LPPFM_PMUVDDIOA_I_50mA_3p0 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    '-------------------------------------------------
    'VDDBAT = 3.7V, 50mA load at LDO_VDD1P22__P3_SENSE
    '-------------------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_50mA"
    TheHdw.wait 2 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P12 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_VDD1P12_LOOP100")
    TheHdw.Digital.Patgen.HaltWait

    LPPFM_VDDLDO_V_50mA_3p7 = TheHdw.DCVI.pins("ASR_VLX").Meter.Read(tlNoStrobe, 100)
    LPPFM_VDDBAT_I_50mA_3p7 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 100)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIO_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    LPPFM_PMUVDDIOA_I_50mA_3p7 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    '-------------------------------------------------
    'VDDBAT = 5.25V, 50mA load at LDO_VDD1P22__P3_SENSE
    '-------------------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_50mA"
    TheHdw.wait 2 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P12 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_VDD1P12_LOOP100")
    TheHdw.Digital.Patgen.HaltWait

    LPPFM_VDDLDO_V_50mA_5p25 = TheHdw.DCVI.pins("ASR_VLX").Meter.Read(tlNoStrobe, 100)
    LPPFM_VDDBAT_I_50mA_5p25 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 100)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIO_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    LPPFM_PMUVDDIOA_I_50mA_5p25 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    

    
    'Clear register
    Call Pmu_registerSetup__clearUDR        '# Clear UDR register
    TheHdw.wait 1 * mS
   
    
    '************************************* Efficiency Calculation *************************************
    pmutb.Calc_Eff 3#, 1 * mA, LPPFM_VDDLDO_V_1mA_3p0, LPPFM_VDDBAT_I_1mA_3p0, LPPFM_Eff_1mA_3p0
    pmutb.Calc_Eff 3.7, 1 * mA, LPPFM_VDDLDO_V_1mA_3p7, LPPFM_VDDBAT_I_1mA_3p7, LPPFM_Eff_1mA_3p7
    pmutb.Calc_Eff 5.25, 1 * mA, LPPFM_VDDLDO_V_1mA_5p25, LPPFM_VDDBAT_I_1mA_5p25, LPPFM_Eff_1mA_5p25

    pmutb.Calc_Eff 3#, 20 * mA, LPPFM_VDDLDO_V_20mA_3p0, LPPFM_VDDBAT_I_20mA_3p0, LPPFM_Eff_20mA_3p0
    pmutb.Calc_Eff 3.7, 20 * mA, LPPFM_VDDLDO_V_20mA_3p7, LPPFM_VDDBAT_I_20mA_3p7, LPPFM_Eff_20mA_3p7
    pmutb.Calc_Eff 5.25, 20 * mA, LPPFM_VDDLDO_V_20mA_5p25, LPPFM_VDDBAT_I_20mA_5p25, LPPFM_Eff_20mA_5p25

    pmutb.Calc_Eff 3#, 20 * mA, LPPFM_VDDLDO_V_50mA_3p0, LPPFM_VDDBAT_I_50mA_3p0, LPPFM_Eff_50mA_3p0
    pmutb.Calc_Eff 3.7, 20 * mA, LPPFM_VDDLDO_V_50mA_3p7, LPPFM_VDDBAT_I_50mA_3p7, LPPFM_Eff_50mA_3p7
    pmutb.Calc_Eff 5.25, 20 * mA, LPPFM_VDDLDO_V_50mA_5p25, LPPFM_VDDBAT_I_50mA_5p25, LPPFM_Eff_50mA_5p25

    'Include the PMU_VDDIO current
    pmutb.Calc_Eff_INC_PMU_VDDIO 3#, 1 * mA, LPPFM_VDDLDO_V_1mA_3p0, LPPFM_VDDBAT_I_1mA_3p0, 1.8, LPPFM_PMUVDDIOA_I_1mA_3p0, LPPFM_Eff_1mA_3p0_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 3.7, 1 * mA, LPPFM_VDDLDO_V_1mA_3p7, LPPFM_VDDBAT_I_1mA_3p7, 1.8, LPPFM_PMUVDDIOA_I_1mA_3p7, LPPFM_Eff_1mA_3p7_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 5.25, 1 * mA, LPPFM_VDDLDO_V_1mA_5p25, LPPFM_VDDBAT_I_1mA_5p25, 1.8, LPPFM_PMUVDDIOA_I_1mA_5p25, LPPFM_Eff_1mA_5p25_INC_PMUVDDIO

    pmutb.Calc_Eff_INC_PMU_VDDIO 3#, 20 * mA, LPPFM_VDDLDO_V_20mA_3p0, LPPFM_VDDBAT_I_20mA_3p0, 1.8, LPPFM_PMUVDDIOA_I_20mA_3p0, LPPFM_Eff_20mA_3p0_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 3.7, 20 * mA, LPPFM_VDDLDO_V_20mA_3p7, LPPFM_VDDBAT_I_20mA_3p7, 1.8, LPPFM_PMUVDDIOA_I_20mA_3p7, LPPFM_Eff_20mA_3p7_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 5.25, 20 * mA, LPPFM_VDDLDO_V_20mA_5p25, LPPFM_VDDBAT_I_20mA_5p25, 1.8, LPPFM_PMUVDDIOA_I_20mA_5p25, LPPFM_Eff_20mA_5p25_INC_PMUVDDIO

    pmutb.Calc_Eff_INC_PMU_VDDIO 3#, 50 * mA, LPPFM_VDDLDO_V_50mA_3p0, LPPFM_VDDBAT_I_50mA_3p0, 1.8, LPPFM_PMUVDDIOA_I_50mA_3p0, LPPFM_Eff_50mA_3p0_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 3.7, 50 * mA, LPPFM_VDDLDO_V_50mA_3p7, LPPFM_VDDBAT_I_50mA_3p7, 1.8, LPPFM_PMUVDDIOA_I_50mA_3p7, LPPFM_Eff_50mA_3p7_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 5.25, 50 * mA, LPPFM_VDDLDO_V_50mA_5p25, LPPFM_VDDBAT_I_50mA_5p25, 1.8, LPPFM_PMUVDDIOA_I_50mA_5p25, LPPFM_Eff_50mA_5p25_INC_PMUVDDIO


    '************************************* Limit Check *************************************
    'ASR LPPFM Mode
    
If (Device.Flow <> QUAL) Then
    '0mA Load
    Call LimitsTool.TestLimit(LPPFM_VDDLDO_V_0mA_3p0, "ASR_VLX", "PMU_ASR_" + "LPPFM_LDO_V_0mA_3p0")
    Call LimitsTool.TestLimit(LPPFM_VDDLDO_V_0mA_3p7, "ASR_VLX", "PMU_ASR_" + "LPPFM_LDO_V_0mA_3p7")
    Call LimitsTool.TestLimit(LPPFM_VDDLDO_V_0mA_5p25, "ASR_VLX", "PMU_ASR_" + "LPPFM_LDO_V_0mA_5p25")
End If

    'Quiescent current [B12]
    Call LimitsTool.TestLimit(LPPFM_VDDBAT_I_0mA_3p0, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "LPPFM_QCurrent_3p0")
    Call LimitsTool.TestLimit(LPPFM_VDDBAT_I_0mA_3p7, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "LPPFM_Qcurrent_3p7")
    Call LimitsTool.TestLimit(LPPFM_VDDBAT_I_0mA_5p25, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "LPPFM_Qcurrent_5p25")
 
If (Device.Flow <> QUAL) Then
    '1mA [B11]
    Call LimitsTool.TestLimit(LPPFM_VDDLDO_V_1mA_3p0, "ASR_VLX", "PMU_ASR_" + "LPPFM_LDO_V_1mA_3p0")
    Call LimitsTool.TestLimit(LPPFM_VDDLDO_V_1mA_3p7, "ASR_VLX", "PMU_ASR_" + "LPPFM_LDO_V_1mA_3p7")
    Call LimitsTool.TestLimit(LPPFM_VDDLDO_V_1mA_5p25, "ASR_VLX", "PMU_ASR_" + "LPPFM_LDO_V_1mA_5p25")
End If
    
    Call LimitsTool.TestLimit(LPPFM_VDDBAT_I_1mA_3p0, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "LPPFM_VBAT_I_1mA_3p0")
    Call LimitsTool.TestLimit(LPPFM_VDDBAT_I_1mA_3p7, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "LPPFM_VBAT_I_1mA_3p7")
    Call LimitsTool.TestLimit(LPPFM_VDDBAT_I_1mA_5p25, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "LPPFM_VBAT_I_1mA_5p25")
    
    Call LimitsTool.TestLimit(LPPFM_PMUVDDIOA_I_1mA_3p0, "PMU_VDDIOP", "PMU_ASR_" + "LPPFM_PMUVDDIO_I_1mA_3p0")
    Call LimitsTool.TestLimit(LPPFM_PMUVDDIOA_I_1mA_3p7, "PMU_VDDIOP", "PMU_ASR_" + "LPPFM_PMUVDDIO_I_1mA_3p7")
    Call LimitsTool.TestLimit(LPPFM_PMUVDDIOA_I_1mA_5p25, "PMU_VDDIOP", "PMU_ASR_" + "LPPFM_PMUVDDIO_I_1mA_5p25")
    
    '20mA
    Call LimitsTool.TestLimit(LPPFM_VDDLDO_V_20mA_3p0, "ASR_VLX", "PMU_ASR_" + "LPPFM_LDO_V_20mA_3p0")
    Call LimitsTool.TestLimit(LPPFM_VDDLDO_V_20mA_3p7, "ASR_VLX", "PMU_ASR_" + "LPPFM_LDO_V_20mA_3p7")
    Call LimitsTool.TestLimit(LPPFM_VDDLDO_V_20mA_5p25, "ASR_VLX", "PMU_ASR_" + "LPPFM_LDO_V_20mA_5p25")
    
    Call LimitsTool.TestLimit(LPPFM_VDDBAT_I_20mA_3p0, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "LPPFM_VBAT_I_20mA_3p0")
    Call LimitsTool.TestLimit(LPPFM_VDDBAT_I_20mA_3p7, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "LPPFM_VBAT_I_20mA_3p7")
    Call LimitsTool.TestLimit(LPPFM_VDDBAT_I_20mA_5p25, "ET_LINREG_VDD_V5P0", "PMU_ASR_" + "LPPFM_VBAT_I_20mA_5p25")
    
    Call LimitsTool.TestLimit(LPPFM_PMUVDDIOA_I_20mA_3p0, "PMU_VDDIOP", "PMU_ASR_" + "LPPFM_PMUVDDIO_I_20mA_3p0")
    Call LimitsTool.TestLimit(LPPFM_PMUVDDIOA_I_20mA_3p7, "PMU_VDDIOP", "PMU_ASR_" + "LPPFM_PMUVDDIO_I_20mA_3p7")
    Call LimitsTool.TestLimit(LPPFM_PMUVDDIOA_I_20mA_5p25, "PMU_VDDIOP", "PMU_ASR_" + "LPPFM_PMUVDDIO_I_20mA_5p25")
    
    'ASR LPPFM Power efficiency
If (Device.Flow <> QUAL) Then
    Call LimitsTool.TestLimit(LPPFM_Eff_1mA_3p0, "ASR_VLX", "PMU_ASR_" + "LPPFM_Eff_1mA_3p0")       ' [B13i]
    Call LimitsTool.TestLimit(LPPFM_Eff_1mA_3p7, "ASR_VLX", "PMU_ASR_" + "LPPFM_Eff_1mA_3p7")
    Call LimitsTool.TestLimit(LPPFM_Eff_1mA_5p25, "ASR_VLX", "PMU_ASR_" + "LPPFM_Eff_1mA_5p25")
End If

    Call LimitsTool.TestLimit(LPPFM_Eff_20mA_3p0, "ASR_VLX", "PMU_ASR_" + "LPPFM_Eff_20mA_3p0")      '[B14i]
    Call LimitsTool.TestLimit(LPPFM_Eff_20mA_3p7, "ASR_VLX", "PMU_ASR_" + "LPPFM_Eff_20mA_3p7")
    Call LimitsTool.TestLimit(LPPFM_Eff_20mA_5p25, "ASR_VLX", "PMU_ASR_" + "LPPFM_Eff_20mA_5p25")
    
    Call LimitsTool.TestLimit(LPPFM_Eff_50mA_3p0, "ASR_VLX", "PMU_ASR_" + "LPPFM_Eff_50mA_3p0")      '[B15i]
    Call LimitsTool.TestLimit(LPPFM_Eff_50mA_3p7, "ASR_VLX", "PMU_ASR_" + "LPPFM_Eff_50mA_3p7")
    Call LimitsTool.TestLimit(LPPFM_Eff_50mA_5p25, "ASR_VLX", "PMU_ASR_" + "LPPFM_Eff_50mA_5p25")
    
    
    'ASR LPPFM Power efficiency with PMU_VDDIO
If (Device.Flow <> QUAL) Then
    Call LimitsTool.TestLimit(LPPFM_Eff_1mA_3p0_INC_PMUVDDIO, "ASR_VLX", "PMU_ASR_" + "LPPFM_Eff_1mA_3p0_INC_PMU_VDDIO")     '[B13ii]
    Call LimitsTool.TestLimit(LPPFM_Eff_1mA_3p7_INC_PMUVDDIO, "ASR_VLX", "PMU_ASR_" + "LPPFM_Eff_1mA_3p7_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(LPPFM_Eff_1mA_5p25_INC_PMUVDDIO, "ASR_VLX", "PMU_ASR_" + "LPPFM_Eff_1mA_5p25_INC_PMU_VDDIO")
End If

    Call LimitsTool.TestLimit(LPPFM_Eff_20mA_3p0_INC_PMUVDDIO, "ASR_VLX", "PMU_ASR_" + "LPPFM_Eff_20mA_3p0_INC_PMU_VDDIO")   '[B14ii]
    Call LimitsTool.TestLimit(LPPFM_Eff_20mA_3p7_INC_PMUVDDIO, "ASR_VLX", "PMU_ASR_" + "LPPFM_Eff_20mA_3p7_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(LPPFM_Eff_20mA_5p25_INC_PMUVDDIO, "ASR_VLX", "PMU_ASR_" + "LPPFM_Eff_20mA_5p25_INC_PMU_VDDIO")

    Call LimitsTool.TestLimit(LPPFM_Eff_50mA_3p0_INC_PMUVDDIO, "ASR_VLX", "PMU_ASR_" + "LPPFM_Eff_50mA_3p0_INC_PMU_VDDIO")   '[B15ii]
    Call LimitsTool.TestLimit(LPPFM_Eff_50mA_3p7_INC_PMUVDDIO, "ASR_VLX", "PMU_ASR_" + "LPPFM_Eff_50mA_3p7_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(LPPFM_Eff_50mA_5p25_INC_PMUVDDIO, "ASR_VLX", "PMU_ASR_" + "LPPFM_Eff_50mA_5p25_INC_PMU_VDDIO")

    If (TheExec.Sites.Active.count = 0) Then Exit Function
    '------------------------------------
    'Must reduce to 10mA and ramp down  -
    '------------------------------------
    pmutb.Apply_PSET "ASR_VLX", "VDDLDO_10mA_2V"
    TheHdw.wait 1 * mS
    pmutb.Apply_PSET "ASR_VLX", "VDDLDO_0mA_2V"
    
    '************************************* Restore Voltages to nominal ***********************************************************************************************************************************************
    'Disconnect LDO_VDD1P22__P3_SENSE
    With TheHdw.DCVI.pins("ASR_VLX")
        .Gate = False
        .Disconnect tlDCVIConnectDefault
        .Mode = tlDCVIModeHighImpedance
        .BleederResistor = tlDCVIBleederResistorOff
    End With
    
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_20mA"

    TheExec.Datalog.WriteComment ""
    TheExec.Datalog.WriteComment "PMU_SwitchRegTests_ASR_LPPFM Test time:" & testTime
    TheExec.Datalog.WriteComment ""
    
Exit Function

ErrorHandler:
    If TheExec.Sites.ActiveCount = 0 Then Exit Function         'If last site failed, exit the test and let IGXL cleanup
    TheExec.ErrorLogMessage "VB Error #" & Trim(Str(err.Number)) & " " & err.Description & " in instance " & TheExec.DataManager.InstanceName
    Resume Next

End Function

Public Function PMU__SwitchRegTests_CSR_PFM_LPPFM() As Long

On Error GoTo ErrorHandler

    Dim PFM_VDDLDO_V_0mA_3p0 As New SiteDouble, PFM_VDDLDO_V_0mA_3p7 As New SiteDouble, PFM_VDDLDO_V_0mA_5p25 As New SiteDouble
    Dim PFM_VDDBAT_I_0mA_3p0 As New SiteDouble, PFM_VDDBAT_I_0mA_3p7 As New SiteDouble, PFM_VDDBAT_I_0mA_5p25 As New SiteDouble
    Dim PFM_VDDLDO_V_10mA_3p0 As New SiteDouble, PFM_VDDLDO_V_10mA_3p7 As New SiteDouble, PFM_VDDLDO_V_10mA_5p25 As New SiteDouble
    Dim PFM_VDDBAT_I_10mA_3p0 As New SiteDouble, PFM_VDDBAT_I_10mA_3p7 As New SiteDouble, PFM_VDDBAT_I_10mA_5p25 As New SiteDouble
    Dim PFM_VDDLDO_V_30mA_3p0 As New SiteDouble, PFM_VDDLDO_V_30mA_3p7 As New SiteDouble, PFM_VDDLDO_V_30mA_5p25 As New SiteDouble
    Dim PFM_VDDBAT_I_30mA_3p0 As New SiteDouble, PFM_VDDBAT_I_30mA_3p7 As New SiteDouble, PFM_VDDBAT_I_30mA_5p25 As New SiteDouble
    Dim PFM_VDDLDO_V_40mA_3p0 As New SiteDouble, PFM_VDDLDO_V_40mA_3p7 As New SiteDouble, PFM_VDDLDO_V_40mA_5p25 As New SiteDouble
    Dim PFM_VDDBAT_I_40mA_3p0 As New SiteDouble, PFM_VDDBAT_I_40mA_3p7 As New SiteDouble, PFM_VDDBAT_I_40mA_5p25 As New SiteDouble
    Dim PFM_VDDLDO_V_50mA_3p0 As New SiteDouble, PFM_VDDLDO_V_50mA_3p7 As New SiteDouble, PFM_VDDLDO_V_50mA_5p25 As New SiteDouble
    Dim PFM_VDDBAT_I_50mA_3p0 As New SiteDouble, PFM_VDDBAT_I_50mA_3p7 As New SiteDouble, PFM_VDDBAT_I_50mA_5p25 As New SiteDouble
    
    Dim PFM_Eff_10mA_3p0 As New SiteDouble, PFM_Eff_10mA_3p7 As New SiteDouble, PFM_Eff_10mA_5p25 As New SiteDouble
    Dim PFM_Eff_30mA_3p0 As New SiteDouble, PFM_Eff_30mA_3p7 As New SiteDouble, PFM_Eff_30mA_5p25 As New SiteDouble
    Dim PFM_Eff_50mA_3p0 As New SiteDouble, PFM_Eff_50mA_3p7 As New SiteDouble, PFM_Eff_50mA_5p25 As New SiteDouble
    Dim PFM_PMUVDDIOA_I_10mA_3p0 As New SiteDouble, PFM_PMUVDDIOA_I_10mA_3p7 As New SiteDouble, PFM_PMUVDDIOA_I_10mA_5p25 As New SiteDouble
    Dim PFM_PMUVDDIOA_I_30mA_3p0 As New SiteDouble, PFM_PMUVDDIOA_I_30mA_3p7 As New SiteDouble, PFM_PMUVDDIOA_I_30mA_5p25 As New SiteDouble
    Dim PFM_PMUVDDIOA_I_40mA_3p0 As New SiteDouble, PFM_PMUVDDIOA_I_40mA_3p7 As New SiteDouble, PFM_PMUVDDIOA_I_40mA_5p25 As New SiteDouble
    Dim PFM_PMUVDDIOA_I_50mA_3p0 As New SiteDouble, PFM_PMUVDDIOA_I_50mA_3p7 As New SiteDouble, PFM_PMUVDDIOA_I_50mA_5p25 As New SiteDouble
        
    Dim PFM_Eff_10mA_3p0_INC_PMUVDDIO As New SiteDouble, PFM_Eff_10mA_3p7_INC_PMUVDDIO As New SiteDouble, PFM_Eff_10mA_5p25_INC_PMUVDDIO As New SiteDouble
    Dim PFM_Eff_30mA_3p0_INC_PMUVDDIO As New SiteDouble, PFM_Eff_30mA_3p7_INC_PMUVDDIO As New SiteDouble, PFM_Eff_30mA_5p25_INC_PMUVDDIO As New SiteDouble
    Dim PFM_Eff_40mA_3p0_INC_PMUVDDIO As New SiteDouble, PFM_Eff_40mA_3p7_INC_PMUVDDIO As New SiteDouble, PFM_Eff_40mA_5p25_INC_PMUVDDIO As New SiteDouble
    Dim PFM_Eff_50mA_3p0_INC_PMUVDDIO As New SiteDouble, PFM_Eff_50mA_3p7_INC_PMUVDDIO As New SiteDouble, PFM_Eff_50mA_5p25_INC_PMUVDDIO As New SiteDouble
    
    Dim LPPFM_VDDLDO_V_0mA_3p0 As New SiteDouble, LPPFM_VDDLDO_V_0mA_3p7 As New SiteDouble, LPPFM_VDDLDO_V_0mA_5p25 As New SiteDouble
    Dim LPPFM_VDDBAT_I_0mA_3p0 As New SiteDouble, LPPFM_VDDBAT_I_0mA_3p7 As New SiteDouble, LPPFM_VDDBAT_I_0mA_5p25 As New SiteDouble
    Dim LPPFM_VDDLDO_V_1mA_3p0 As New SiteDouble, LPPFM_VDDLDO_V_1mA_3p7 As New SiteDouble, LPPFM_VDDLDO_V_1mA_5p25 As New SiteDouble
    Dim LPPFM_VDDBAT_I_1mA_3p0 As New SiteDouble, LPPFM_VDDBAT_I_1mA_3p7 As New SiteDouble, LPPFM_VDDBAT_I_1mA_5p25 As New SiteDouble
    
    Dim LPPFM_PMUVDDIOA_I_1mA_3p0 As New SiteDouble, LPPFM_PMUVDDIOA_I_1mA_3p7 As New SiteDouble, LPPFM_PMUVDDIOA_I_1mA_5p25 As New SiteDouble
    
    Dim LPPFM_VDDLDO_V_20mA_3p0 As New SiteDouble, LPPFM_VDDLDO_V_20mA_3p7 As New SiteDouble, LPPFM_VDDLDO_V_20mA_5p25 As New SiteDouble
    Dim LPPFM_VDDBAT_I_20mA_3p0 As New SiteDouble, LPPFM_VDDBAT_I_20mA_3p7 As New SiteDouble, LPPFM_VDDBAT_I_20mA_5p25 As New SiteDouble
    Dim LPPFM_PMUVDDIOA_I_20mA_3p0 As New SiteDouble, LPPFM_PMUVDDIOA_I_20mA_3p7 As New SiteDouble, LPPFM_PMUVDDIOA_I_20mA_5p25 As New SiteDouble
    
    Dim LPPFM_VDDLDO_V_50mA_3p0 As New SiteDouble, LPPFM_VDDLDO_V_50mA_3p7 As New SiteDouble, LPPFM_VDDLDO_V_50mA_5p25 As New SiteDouble
    Dim LPPFM_VDDBAT_I_50mA_3p0 As New SiteDouble, LPPFM_VDDBAT_I_50mA_3p7 As New SiteDouble, LPPFM_VDDBAT_I_50mA_5p25 As New SiteDouble
    Dim LPPFM_PMUVDDIOA_I_50mA_3p0 As New SiteDouble, LPPFM_PMUVDDIOA_I_50mA_3p7 As New SiteDouble, LPPFM_PMUVDDIOA_I_50mA_5p25 As New SiteDouble
    
    Dim LPPFM_Eff_1mA_3p0 As New SiteDouble, LPPFM_Eff_1mA_3p7 As New SiteDouble, LPPFM_Eff_1mA_5p25 As New SiteDouble
    Dim LPPFM_Eff_20mA_3p0 As New SiteDouble, LPPFM_Eff_20mA_3p7 As New SiteDouble, LPPFM_Eff_20mA_5p25 As New SiteDouble
    Dim LPPFM_Eff_50mA_3p0 As New SiteDouble, LPPFM_Eff_50mA_3p7 As New SiteDouble, LPPFM_Eff_50mA_5p25 As New SiteDouble
    
    Dim LPPFM_Eff_1mA_3p0_INC_PMUVDDIO As New SiteDouble, LPPFM_Eff_1mA_3p7_INC_PMUVDDIO As New SiteDouble, LPPFM_Eff_1mA_5p25_INC_PMUVDDIO As New SiteDouble
    Dim LPPFM_Eff_20mA_3p0_INC_PMUVDDIO As New SiteDouble, LPPFM_Eff_20mA_3p7_INC_PMUVDDIO As New SiteDouble, LPPFM_Eff_20mA_5p25_INC_PMUVDDIO As New SiteDouble
    Dim LPPFM_Eff_50mA_3p0_INC_PMUVDDIO As New SiteDouble, LPPFM_Eff_50mA_3p7_INC_PMUVDDIO As New SiteDouble, LPPFM_Eff_50mA_5p25_INC_PMUVDDIO As New SiteDouble
    
    Dim Show_ChipID As Boolean

    Dim testTime As Double
    TheHdw.StartStopwatch
    
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU SwitchReg Tests - CSR PFM [C6], [C7], [C8i], [C8ii], [C9i], [C9ii], [C10i], [C10ii]"
    TheExec.Datalog.WriteComment "================================================================================================"
    
    TheHdw.DCVI.pins("CSR_VLX").BleederResistor = tlDCVIBleederResistorAuto
    With TheHdw.DCVI.pins("CSR_VLX")
        .Disconnect tlDCVIConnectDefault
         .Mode = tlDCVIModeCurrent
         .Meter.Mode = tlDCVIMeterVoltage
         .Current = -200 * nA
         .Voltage = -0.5 * v
         .Connect
         .Gate = True
     End With
     TheHdw.wait 1 * mS
    '----------------------------------------- CBUCK in PFM mode (C6) -------------------------------------------------------------------------------------------------------------------------------------------------------
    
    '---------------------------------------------------------------------
    'Must remember to reset from sleep mode & Strapping Option if needed -
    '---------------------------------------------------------------------
    'ChipInit CORE_RESET
    
    'Must remember to increase the PMU_VDDIO currange range since we would like to turn on device (WL_REG_ON=High)
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_2mA"
    TheHdw.wait 5 * mS

    '----------------------------------
    'Output Voltage in PFM Mode for B6
    '----------------------------------
    Call Pmu_registerSetup__CSR_PFM_Mode        '# setup PFM Mode
    TheHdw.wait 10 * mS 'test time reduction 10 to 5
    
    '********************************************* 0mA Load condition *************************************
    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_0mA_2V"                                      '0mA Load setting at "LDO_VDD1P0__P3_SENSE"(output of cbuck regulator)
    
    '# Measure Q Current
    
    TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Filter.Value = 10000
    TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Filter.Bypass = False
    TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Filter.Bypass = False
    TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Filter.Value = 781.25
    
    TheHdw.DCVI("ET_LINREG_VDD_V5P0").Alarm(tlDCVIAlarmOverRange Or tlDCVIAlarmMode) = tlAlarmOff      '# Turn OFF mode alarm @0mA load - spike issue

    '--------------------------------------
    'VDDBAT = 3.0V, 0mA load at LDO_VDD1P0
    '--------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_2mA"
    TheHdw.wait 10 * mS
    PFM_VDDBAT_I_0mA_3p0 = pmu__PFM_LPPFM__QCurrent__IgnoreSpkie("ET_LINREG_VDD_V5P0", 5, 0, 40 * uA)
    PFM_VDDLDO_V_0mA_3p0 = pmutb.Meter_Strobe("CSR_VLX", 20, 0.5 * mS)

    '--------------------------------------
    'VDDBAT = 3.7V, 0mA load at LDO_VDD1P0
    '--------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_2mA"
    TheHdw.wait 5 * mS 'test time reduction 10 to 5
    PFM_VDDBAT_I_0mA_3p7 = pmu__PFM_LPPFM__QCurrent__IgnoreSpkie("ET_LINREG_VDD_V5P0", 5, 0, 40 * uA)
    PFM_VDDLDO_V_0mA_3p7 = pmutb.Meter_Strobe("CSR_VLX", 20, 0.5 * mS)

    '--------------------------------------
    'VDDBAT = 5.25V, 0mA load at LDO_VDD1P0
    '--------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_2mA"
    TheHdw.wait 5 * mS 'test time reduction 10 to 5
    PFM_VDDBAT_I_0mA_5p25 = pmu__PFM_LPPFM__QCurrent__IgnoreSpkie("ET_LINREG_VDD_V5P0", 5, 0, 40 * uA)
    PFM_VDDLDO_V_0mA_5p25 = pmutb.Meter_Strobe("CSR_VLX", 20, 0.5 * mS)

    TheHdw.DCVI("ET_LINREG_VDD_V5P0").Alarm(tlDCVIAlarmOverRange Or tlDCVIAlarmMode) = tlAlarmDefault      '# Turn ON mode alarm at the end of @0mA load
   
    '************************************* 10mA Load condition *************************************
    
    '---------------------------------------
    'VDDBAT = 3.0V, 10mA load at LDO_VDD1P0
    '---------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_10mA_2V"                                    '10mA Load setting at "LDO_VDD1P0__P3_SENSE"(output of cbuck regulator)
    TheHdw.wait 2 * mS

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_20mA"
    TheHdw.wait 5 * mS
    
    'Where to get this pattern???
    'Measure PMU_VDDBAT5 and LDO_VDD1P0 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_CSR_LOOP20")
    TheHdw.Digital.Patgen.HaltWait

    PFM_VDDLDO_V_10mA_3p0 = TheHdw.DCVI.pins("CSR_VLX").Meter.Read(tlNoStrobe, 20)
    PFM_VDDBAT_I_10mA_3p0 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 20)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIOP_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    PFM_PMUVDDIOA_I_10mA_3p0 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    '---------------------------------------
    'VDDBAT = 3.7V, 10mA load at LDO_VDD1P0
    '---------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    TheHdw.wait 5 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P0 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_CSR_LOOP20")
    TheHdw.Digital.Patgen.HaltWait

    PFM_VDDLDO_V_10mA_3p7 = TheHdw.DCVI.pins("CSR_VLX").Meter.Read(tlNoStrobe, 20)
    PFM_VDDBAT_I_10mA_3p7 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 20)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIOP_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    PFM_PMUVDDIOA_I_10mA_3p7 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    

    '---------------------------------------
    'VDDBAT = 5.25V, 10mA load at LDO_VDD1P0
    '---------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_20mA"
    TheHdw.wait 5 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P0 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_CSR_LOOP20")
    TheHdw.Digital.Patgen.HaltWait

    PFM_VDDLDO_V_10mA_5p25 = TheHdw.DCVI.pins("CSR_VLX").Meter.Read(tlNoStrobe, 20)
    PFM_VDDBAT_I_10mA_5p25 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 20)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIOP_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    PFM_PMUVDDIOA_I_10mA_5p25 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)

    
    '************************************* 30mA Load condition *************************************
    '---------------------------------------
    'VDDBAT = 3.0V, 30mA load at LDO_VDD1P0
    '---------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_30mA_2V"                                    '30mA Load setting at "LDO_VDD1P0__P3_SENSE"(output of cbuck regulator)
    TheHdw.wait 3 * mS

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_20mA"
    TheHdw.wait 5 * mS
    
    'Measure PMU_VDDBAT5 and LDO_VDD1P0 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_CSR_LOOP20")
    TheHdw.Digital.Patgen.HaltWait

    PFM_VDDLDO_V_30mA_3p0 = TheHdw.DCVI.pins("CSR_VLX").Meter.Read(tlNoStrobe, 20)
    PFM_VDDBAT_I_30mA_3p0 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 20)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIOP_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    PFM_PMUVDDIOA_I_30mA_3p0 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    '---------------------------------------
    'VDDBAT = 3.7V, 30mA load at LDO_VDD1P0
    '---------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    TheHdw.wait 5 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P0 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_CSR_LOOP20")
    TheHdw.Digital.Patgen.HaltWait

    PFM_VDDLDO_V_30mA_3p7 = TheHdw.DCVI.pins("CSR_VLX").Meter.Read(tlNoStrobe, 20)
    PFM_VDDBAT_I_30mA_3p7 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 20)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIOP_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    PFM_PMUVDDIOA_I_30mA_3p7 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
        
    '---------------------------------------
    'VDDBAT = 5.25V, 30mA load at LDO_VDD1P0
    '---------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_20mA"
    TheHdw.wait 5 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P0 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_CSR_LOOP20")
    TheHdw.Digital.Patgen.HaltWait

    PFM_VDDLDO_V_30mA_5p25 = TheHdw.DCVI.pins("CSR_VLX").Meter.Read(tlNoStrobe, 20)
    PFM_VDDBAT_I_30mA_5p25 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 20)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIOP_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    PFM_PMUVDDIOA_I_30mA_5p25 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
        
    
    '************************************* 50mA Load condition *************************************
    '---------------------------------------
    'VDDBAT = 3.0V, 50mA load at LDO_VDD1P0
    '---------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    
    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_50mA_2V"                                    '50mA Load setting at "LDO_VDD1P0__P3_SENSE"(output of cbuck regulator)
    TheHdw.wait 3 * mS

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_200mA"
    TheHdw.wait 5 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P0 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_CSR_LOOP20")
    TheHdw.Digital.Patgen.HaltWait

    PFM_VDDLDO_V_50mA_3p0 = TheHdw.DCVI.pins("CSR_VLX").Meter.Read(tlNoStrobe, 20)
    PFM_VDDBAT_I_50mA_3p0 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 20)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIOP_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    PFM_PMUVDDIOA_I_50mA_3p0 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    '---------------------------------------
    'VDDBAT = 3.7V, 50mA load at LDO_VDD1P0
    '---------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    TheHdw.wait 5 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P0 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_CSR_LOOP20")
    TheHdw.Digital.Patgen.HaltWait

    PFM_VDDLDO_V_50mA_3p7 = TheHdw.DCVI.pins("CSR_VLX").Meter.Read(tlNoStrobe, 20)
    PFM_VDDBAT_I_50mA_3p7 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 20)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIOP_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    PFM_PMUVDDIOA_I_50mA_3p7 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    
    '---------------------------------------
    'VDDBAT = 5.25V, 50mA load at LDO_VDD1P0
    '---------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_200mA"
    TheHdw.wait 5 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P0 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_CSR_LOOP20")
    TheHdw.Digital.Patgen.HaltWait

    PFM_VDDLDO_V_50mA_5p25 = TheHdw.DCVI.pins("CSR_VLX").Meter.Read(tlNoStrobe, 20)
    PFM_VDDBAT_I_50mA_5p25 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 20)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIOP_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    PFM_PMUVDDIOA_I_50mA_5p25 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)

    '------------------------------------
    'Must reduce to 10mA and ramp down  -
    '------------------------------------
    
    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_10mA_2V"                                    '10mA Load setting at "LDO_VDD1P22__P3_SENSE"(output of cbuck regulator)
    TheHdw.wait 2 * mS

    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_0mA_2V"                                     '0mA Load setting at "LDO_VDD1P22__P3_SENSE"(output of cbuck regulator)
    TheHdw.wait 1 * mS
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    TheHdw.wait 1 * mS
    
    'Clear register
    Call Pmu_registerSetup__clearUDR            '# Clear UDR register

    '************************************* Efficiency Calculation *************************************
    pmutb.Calc_Eff 3#, 10 * mA, PFM_VDDLDO_V_10mA_3p0, PFM_VDDBAT_I_10mA_3p0, PFM_Eff_10mA_3p0
    pmutb.Calc_Eff 3.7, 10 * mA, PFM_VDDLDO_V_10mA_3p7, PFM_VDDBAT_I_10mA_3p7, PFM_Eff_10mA_3p7
    pmutb.Calc_Eff 5.25, 10 * mA, PFM_VDDLDO_V_10mA_5p25, PFM_VDDBAT_I_10mA_5p25, PFM_Eff_10mA_5p25

    pmutb.Calc_Eff 3#, 30 * mA, PFM_VDDLDO_V_30mA_3p0, PFM_VDDBAT_I_30mA_3p0, PFM_Eff_30mA_3p0
    pmutb.Calc_Eff 3.7, 30 * mA, PFM_VDDLDO_V_30mA_3p7, PFM_VDDBAT_I_30mA_3p7, PFM_Eff_30mA_3p7
    pmutb.Calc_Eff 5.25, 30 * mA, PFM_VDDLDO_V_30mA_5p25, PFM_VDDBAT_I_30mA_5p25, PFM_Eff_30mA_5p25

    pmutb.Calc_Eff 3#, 50 * mA, PFM_VDDLDO_V_50mA_3p0, PFM_VDDBAT_I_50mA_3p0, PFM_Eff_50mA_3p0
    pmutb.Calc_Eff 3.7, 50 * mA, PFM_VDDLDO_V_50mA_3p7, PFM_VDDBAT_I_50mA_3p7, PFM_Eff_50mA_3p7
    pmutb.Calc_Eff 5.25, 50 * mA, PFM_VDDLDO_V_50mA_5p25, PFM_VDDBAT_I_50mA_5p25, PFM_Eff_50mA_5p25
    
    'Include the PMU_VDDIO current
    pmutb.Calc_Eff_INC_PMU_VDDIO 3#, 10 * mA, PFM_VDDLDO_V_10mA_3p0, PFM_VDDBAT_I_10mA_3p0, 1.8, PFM_PMUVDDIOA_I_10mA_3p0, PFM_Eff_10mA_3p0_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 3.7, 10 * mA, PFM_VDDLDO_V_10mA_3p7, PFM_VDDBAT_I_10mA_3p7, 1.8, PFM_PMUVDDIOA_I_10mA_3p7, PFM_Eff_10mA_3p7_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 5.25, 10 * mA, PFM_VDDLDO_V_10mA_5p25, PFM_VDDBAT_I_10mA_5p25, 1.8, PFM_PMUVDDIOA_I_10mA_5p25, PFM_Eff_10mA_5p25_INC_PMUVDDIO

    pmutb.Calc_Eff_INC_PMU_VDDIO 3#, 30 * mA, PFM_VDDLDO_V_30mA_3p0, PFM_VDDBAT_I_30mA_3p0, 1.8, PFM_PMUVDDIOA_I_30mA_3p0, PFM_Eff_30mA_3p0_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 3.7, 30 * mA, PFM_VDDLDO_V_30mA_3p7, PFM_VDDBAT_I_30mA_3p7, 1.8, PFM_PMUVDDIOA_I_30mA_3p7, PFM_Eff_30mA_3p7_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 5.25, 30 * mA, PFM_VDDLDO_V_30mA_5p25, PFM_VDDBAT_I_30mA_5p25, 1.8, PFM_PMUVDDIOA_I_30mA_5p25, PFM_Eff_30mA_5p25_INC_PMUVDDIO

    pmutb.Calc_Eff_INC_PMU_VDDIO 3#, 50 * mA, PFM_VDDLDO_V_50mA_3p0, PFM_VDDBAT_I_50mA_3p0, 1.8, PFM_PMUVDDIOA_I_50mA_3p0, PFM_Eff_50mA_3p0_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 3.7, 50 * mA, PFM_VDDLDO_V_50mA_3p7, PFM_VDDBAT_I_50mA_3p7, 1.8, PFM_PMUVDDIOA_I_50mA_3p7, PFM_Eff_50mA_3p7_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 5.25, 50 * mA, PFM_VDDLDO_V_50mA_5p25, PFM_VDDBAT_I_50mA_5p25, 1.8, PFM_PMUVDDIOA_I_50mA_5p25, PFM_Eff_50mA_5p25_INC_PMUVDDIO

    '************************************* Limit Check *************************************
    
    'CSR PFM Mode [C6]
    '0mA Load [C6]
If (Device.Flow <> QUAL) Then
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_0mA_3p0, "CSR_VLX", "PMU_CSR_" + "PFM_LDO_V_0mA_3p0")
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_0mA_3p7, "CSR_VLX", "PMU_CSR_" + "PFM_LDO_V_0mA_3p7")
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_0mA_5p25, "CSR_VLX", "PMU_CSR_" + "PFM_LDO_V_0mA_5p25")
End If

    'CSR PFM Quiescent current [C7]
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_0mA_3p0, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "PFM_QCurrent_3p0")
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_0mA_3p7, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "PFM_Qcurrent_3p7")
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_0mA_5p25, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "PFM_Qcurrent_5p25")
        
    '10mA Load [C6]
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_10mA_3p0, "CSR_VLX", "PMU_CSR_" + "PFM_LDO_V_10mA_3p0")
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_10mA_3p7, "CSR_VLX", "PMU_CSR_" + "PFM_LDO_V_10mA_3p7")
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_10mA_5p25, "CSR_VLX", "PMU_CSR_" + "PFM_LDO_V_10mA_5p25")
    
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_10mA_3p0, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "PFM_VBAT_I_10mA_3p0")
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_10mA_3p7, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "PFM_VBAT_I_10mA_3p7")
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_10mA_5p25, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "PFM_VBAT_I_10mA_5p25")
    
    Call LimitsTool.TestLimit(PFM_PMUVDDIOA_I_10mA_3p0, "PMU_VDDIOP", "PMU_CSR_" + "PFM_PMUVDDIO_I_10mA_3p0")
    Call LimitsTool.TestLimit(PFM_PMUVDDIOA_I_10mA_3p7, "PMU_VDDIOP", "PMU_CSR_" + "PFM_PMUVDDIO_I_10mA_3p7")
    Call LimitsTool.TestLimit(PFM_PMUVDDIOA_I_10mA_5p25, "PMU_VDDIOP", "PMU_CSR_" + "PFM_PMUVDDIO_I_10mA_5p25")
    
    '30mA Load [C6]
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_30mA_3p0, "CSR_VLX", "PMU_CSR_" + "PFM_LDO_V_30mA_3p0")
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_30mA_3p7, "CSR_VLX", "PMU_CSR_" + "PFM_LDO_V_30mA_3p7")
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_30mA_5p25, "CSR_VLX", "PMU_CSR_" + "PFM_LDO_V_30mA_5p25")
    
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_30mA_3p0, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "PFM_VBAT_I_30mA_3p0")
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_30mA_3p7, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "PFM_VBAT_I_30mA_3p7")
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_30mA_5p25, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "PFM_VBAT_I_30mA_5p25")
    
    Call LimitsTool.TestLimit(PFM_PMUVDDIOA_I_30mA_3p0, "PMU_VDDIOP", "PMU_CSR_" + "PFM_PMUVDDIO_I_30mA_3p0")
    Call LimitsTool.TestLimit(PFM_PMUVDDIOA_I_30mA_3p7, "PMU_VDDIOP", "PMU_CSR_" + "PFM_PMUVDDIO_I_30mA_3p7")
    Call LimitsTool.TestLimit(PFM_PMUVDDIOA_I_30mA_5p25, "PMU_VDDIOP", "PMU_CSR_" + "PFM_PMUVDDIO_I_30mA_5p25")
    
    '50mA Load [C6]
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_50mA_3p0, "CSR_VLX", "PMU_CSR_" + "PFM_LDO_V_50mA_3p0")
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_50mA_3p7, "CSR_VLX", "PMU_CSR_" + "PFM_LDO_V_50mA_3p7")
    Call LimitsTool.TestLimit(PFM_VDDLDO_V_50mA_5p25, "CSR_VLX", "PMU_CSR_" + "PFM_LDO_V_50mA_5p0")
    
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_50mA_3p0, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "PFM_VBAT_I_50mA_3p0")
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_50mA_3p7, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "PFM_VBAT_I_50mA_3p7")
    Call LimitsTool.TestLimit(PFM_VDDBAT_I_50mA_5p25, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "PFM_VBAT_I_50mA_5p25")
    
    Call LimitsTool.TestLimit(PFM_PMUVDDIOA_I_50mA_3p0, "PMU_VDDIOP", "PMU_CSR_" + "PFM_PMUVDDIO_I_50mA_3p0")
    Call LimitsTool.TestLimit(PFM_PMUVDDIOA_I_50mA_3p7, "PMU_VDDIOP", "PMU_CSR_" + "PFM_PMUVDDIO_I_50mA_3p7")
    Call LimitsTool.TestLimit(PFM_PMUVDDIOA_I_50mA_5p25, "PMU_VDDIOP", "PMU_CSR_" + "PFM_PMUVDDIO_I_50mA_5p25")
    
    
    'CSR PFM Efficiency
    Call LimitsTool.TestLimit(PFM_Eff_10mA_3p0, "CSR_VLX", "PMU_CSR_" + "PFM_Eff_10mA_3p0")     '[C8i]
    Call LimitsTool.TestLimit(PFM_Eff_10mA_3p7, "CSR_VLX", "PMU_CSR_" + "PFM_Eff_10mA_3p7")
    Call LimitsTool.TestLimit(PFM_Eff_10mA_5p25, "CSR_VLX", "PMU_CSR_" + "PFM_Eff_10mA_5p25")
    
    Call LimitsTool.TestLimit(PFM_Eff_30mA_3p0, "CSR_VLX", "PMU_CSR_" + "PFM_Eff_30mA_3p0")     '[C9i]
    Call LimitsTool.TestLimit(PFM_Eff_30mA_3p7, "CSR_VLX", "PMU_CSR_" + "PFM_Eff_30mA_3p7")
    Call LimitsTool.TestLimit(PFM_Eff_30mA_5p25, "CSR_VLX", "PMU_CSR_" + "PFM_Eff_30mA_5p25")
    
    Call LimitsTool.TestLimit(PFM_Eff_50mA_3p0, "CSR_VLX", "PMU_CSR_" + "PFM_Eff_50mA_3p0")     '[C10i]
    Call LimitsTool.TestLimit(PFM_Eff_50mA_3p7, "CSR_VLX", "PMU_CSR_" + "PFM_Eff_50mA_3p7")
    Call LimitsTool.TestLimit(PFM_Eff_50mA_5p25, "CSR_VLX", "PMU_CSR_" + "PFM_Eff_50mA_5p25")
    
    Call LimitsTool.TestLimit(PFM_Eff_10mA_3p0_INC_PMUVDDIO, "PMU_VDDIOP", "PMU_CSR_" + "PFM_Eff_10mA_3p0_INC_PMU_VDDIO")      '[C8ii]
    Call LimitsTool.TestLimit(PFM_Eff_10mA_3p7_INC_PMUVDDIO, "PMU_VDDIOP", "PMU_CSR_" + "PFM_Eff_10mA_3p7_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(PFM_Eff_10mA_5p25_INC_PMUVDDIO, "PMU_VDDIOP", "PMU_CSR_" + "PFM_Eff_10mA_5p25_INC_PMU_VDDIO")
    
    Call LimitsTool.TestLimit(PFM_Eff_30mA_3p0_INC_PMUVDDIO, "PMU_VDDIOP", "PMU_CSR_" + "PFM_Eff_30mA_3p0_INC_PMU_VDDIO")      '[C9ii]
    Call LimitsTool.TestLimit(PFM_Eff_30mA_3p7_INC_PMUVDDIO, "PMU_VDDIOP", "PMU_CSR_" + "PFM_Eff_30mA_3p7_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(PFM_Eff_30mA_5p25_INC_PMUVDDIO, "PMU_VDDIOP", "PMU_CSR_" + "PFM_Eff_30mA_5p25_INC_PMU_VDDIO")
    
    Call LimitsTool.TestLimit(PFM_Eff_50mA_3p0_INC_PMUVDDIO, "PMU_VDDIOP", "PMU_CSR_" + "PFM_Eff_50mA_3p0_INC_PMU_VDDIO")      '[C10ii]
    Call LimitsTool.TestLimit(PFM_Eff_50mA_3p7_INC_PMUVDDIO, "PMU_VDDIOP", "PMU_CSR_" + "PFM_Eff_50mA_3p7_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(PFM_Eff_50mA_5p25_INC_PMUVDDIO, "PMU_VDDIOP", "PMU_CSR_" + "PFM_Eff_50mA_5p25_INC_PMU_VDDIO")

    If TheExec.Sites.ActiveCount = 0 Then Exit Function

'''    If Show_ChipID Then
'''        For Each Site In TheExec.Sites
'''            TheExec.Datalog.WriteComment "AXI Chip ID (Real Chip ID): " & Hex(AXI.ReadReg("18000000")(Site))
'''        Next Site
'''    End If

    testTime = TheHdw.ReadStopwatch
    TheExec.Datalog.WriteComment ""
    TheExec.Datalog.WriteComment "PMU_SwitchRegTests_CSR_PFM Test time:" & testTime
    TheExec.Datalog.WriteComment ""
    
'----------------------------------------- CBUCK in LPPFM mode -------------------------------------------------------------------------------------------------------------------------------------------------------
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU SwitchReg Tests - CSR LPPFM [C11], [C12], [C13i], [C13ii], [C14i], [C14ii], [C15i], [C15ii]"
    TheExec.Datalog.WriteComment "================================================================================================"
    
'''    TheHdw.DCVI.pins("CSR_VLX").BleederResistor = tlDCVIBleederResistorAuto
'''    With TheHdw.DCVI.pins("CSR_VLX")
'''         .mode = tlDCVIModeCurrent
'''         .Meter.mode = tlDCVIMeterVoltage
'''         .Current = -200 * nA
'''         .Voltage = -0.5 * v
'''         .Connect
'''         .Gate = True
'''     End With
'''     TheHdw.wait 1 * mS
    
    '---------------------------------------------------------------------
    'Must remember to reset from sleep mode & Strapping Option if needed -
    '---------------------------------------------------------------------
    
    'Must remember to increase the PMU_VDDIO currange range since we would like to turn on device (WL_REG_ON=High)
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_2mA"
    TheHdw.wait 5 * mS
    '-----------------------------------------
    'Output Voltage in Low Power Mode for C11
    '-----------------------------------------
    Call Pmu_registerSetup__CSR_LPPFM_Mode      '# setup LPPFM Mode
    TheHdw.wait 10 * mS 'test time reduction 10 to 5
    
    '********************************************* 0mA Load condition *************************************
 
    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_0mA_2V"                                     '0mA Load setting at "LDO_VDD1P0__P3_SENSE"(output of cbuck regulator)
    TheHdw.wait 2 * mS
    
    '# Q Current Meassurement
    TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Filter.Value = 10000
    TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Filter.Bypass = False
    TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Filter.Bypass = False
    TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Filter.Value = 781.25
    
    TheHdw.DCVI("ET_LINREG_VDD_V5P0").Alarm(tlDCVIAlarmOverRange Or tlDCVIAlarmMode) = tlAlarmOff      '# Turn OFF mode alarm @0mA load - spike issue
   '--------------------------------------
    'VDDBAT = 3.0V, 0mA load at LDO_VDD1P0
    '--------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_2mA"
    TheHdw.wait 5 * mS
    LPPFM_VDDBAT_I_0mA_3p0 = pmu__PFM_LPPFM__QCurrent__IgnoreSpkie("ET_LINREG_VDD_V5P0", 5, 0, 40 * uA)
    LPPFM_VDDLDO_V_0mA_3p0 = pmutb.Meter_Strobe("CSR_VLX", 20, 0.5 * mS)


    '--------------------------------------
    'VDDBAT = 3.7V, 0mA load at LDO_VDD1P0
    '--------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_2mA"
    TheHdw.wait 5 * mS
    LPPFM_VDDBAT_I_0mA_3p7 = pmu__PFM_LPPFM__QCurrent__IgnoreSpkie("ET_LINREG_VDD_V5P0", 5, 0, 40 * uA)
    LPPFM_VDDLDO_V_0mA_3p7 = pmutb.Meter_Strobe("CSR_VLX", 20, 0.5 * mS)
        
    '--------------------------------------
    'VDDBAT = 5.25V, 0mA load at LDO_VDD1P0
    '--------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_2mA"
    TheHdw.wait 5 * mS
    LPPFM_VDDBAT_I_0mA_5p25 = pmu__PFM_LPPFM__QCurrent__IgnoreSpkie("ET_LINREG_VDD_V5P0", 5, 0, 40 * uA)
    LPPFM_VDDLDO_V_0mA_5p25 = pmutb.Meter_Strobe("CSR_VLX", 20, 0.5 * mS)
   
    TheHdw.DCVI("ET_LINREG_VDD_V5P0").Alarm(tlDCVIAlarmOverRange Or tlDCVIAlarmMode) = tlAlarmDefault      '# Turn ON mode alarm at the end of @0mA load
    
    '************************************* 1mA Load condition *************************************
    
    '-------------------------------------------------
    'VDDBAT = 3.0V, 1mA load at LDO_VDD1P0
    '-------------------------------------------------

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_1mA_2V"                                     '1mA Load setting at "LDO_VDD1P0__P3_SENSE"(output of cbuck regulator)
    TheHdw.wait 2 * mS

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_20mA"
    TheHdw.wait 5 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P0 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_VDD1P12_LOOP100")
    TheHdw.Digital.Patgen.HaltWait

    LPPFM_VDDLDO_V_1mA_3p0 = TheHdw.DCVI.pins("CSR_VLX").Meter.Read(tlNoStrobe, 100)
    LPPFM_VDDBAT_I_1mA_3p0 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 100)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIO_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    LPPFM_PMUVDDIOA_I_1mA_3p0 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    '-------------------------------------------------
    'VDDBAT = 3.7V, 1mA load at LDO_VDD1P0
    '-------------------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    TheHdw.wait 5 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P0 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_VDD1P12_LOOP100")
    TheHdw.Digital.Patgen.HaltWait

    LPPFM_VDDLDO_V_1mA_3p7 = TheHdw.DCVI.pins("CSR_VLX").Meter.Read(tlNoStrobe, 100)
    LPPFM_VDDBAT_I_1mA_3p7 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 100)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIO_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    LPPFM_PMUVDDIOA_I_1mA_3p7 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    '-------------------------------------------------
    'VDDBAT = 5.25V, 1mA load at LDO_VDD1P0
    '-------------------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_20mA"
    TheHdw.wait 5 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P0 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_VDD1P12_LOOP100")
    TheHdw.Digital.Patgen.HaltWait

    LPPFM_VDDLDO_V_1mA_5p25 = TheHdw.DCVI.pins("CSR_VLX").Meter.Read(tlNoStrobe, 100)
    LPPFM_VDDBAT_I_1mA_5p25 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 100)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIO_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    LPPFM_PMUVDDIOA_I_1mA_5p25 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    
    '************************************* 20mA Load condition *************************************
    
    '-------------------------------------------------
    'VDDBAT = 3.0V, 20mA load at LDO_VDD1P0
    '-------------------------------------------------
    'Ramp down
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_20mA_2V"                                     '20mA Load setting at "LDO_VDD1P0__P3_SENSE"(output of cbuck regulator)
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_20mA"
    TheHdw.wait 2 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P0 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_VDD1P12_LOOP100")
    TheHdw.Digital.Patgen.HaltWait

    LPPFM_VDDLDO_V_20mA_3p0 = TheHdw.DCVI.pins("CSR_VLX").Meter.Read(tlNoStrobe, 100)
    LPPFM_VDDBAT_I_20mA_3p0 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 100)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIO_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    LPPFM_PMUVDDIOA_I_20mA_3p0 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    '-------------------------------------------------
    'VDDBAT = 3.7V, 20mA load at LDO_VDD1P0
    '-------------------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    TheHdw.wait 2 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P0 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_VDD1P12_LOOP100")
    TheHdw.Digital.Patgen.HaltWait

    LPPFM_VDDLDO_V_20mA_3p7 = TheHdw.DCVI.pins("CSR_VLX").Meter.Read(tlNoStrobe, 100)
    LPPFM_VDDBAT_I_20mA_3p7 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 100)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIO_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    LPPFM_PMUVDDIOA_I_20mA_3p7 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    '-------------------------------------------------
    'VDDBAT = 5.25V, 20mA load at LDO_VDD1P0
    '-------------------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_20mA"
    TheHdw.wait 2 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P22 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_VDD1P12_LOOP100")
    TheHdw.Digital.Patgen.HaltWait

    LPPFM_VDDLDO_V_20mA_5p25 = TheHdw.DCVI.pins("CSR_VLX").Meter.Read(tlNoStrobe, 100)
    LPPFM_VDDBAT_I_20mA_5p25 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 100)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIO_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    LPPFM_PMUVDDIOA_I_20mA_5p25 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    '************************************* 50mA Load condition *************************************
    
    '-------------------------------------------------
    'VDDBAT = 3.0V, 50mA load at LDO_VDD1P0
    '-------------------------------------------------
    'Ramp down
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_20mA"
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_50mA_2V"                                     '20mA Load setting at "LDO_VDD1P0__P3_SENSE"(output of cbuck regulator)
    TheHdw.wait 2 * mS
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p0V_20mA"
    TheHdw.wait 2 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P0 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_VDD1P12_LOOP100")
    TheHdw.Digital.Patgen.HaltWait

    LPPFM_VDDLDO_V_50mA_3p0 = TheHdw.DCVI.pins("CSR_VLX").Meter.Read(tlNoStrobe, 100)
    LPPFM_VDDBAT_I_50mA_3p0 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 100)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIO_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    LPPFM_PMUVDDIOA_I_50mA_3p0 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    '-------------------------------------------------
    'VDDBAT = 3.7V, 50mA load at LDO_VDD1P0
    '-------------------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_50mA"
    TheHdw.wait 2 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P0 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_VDD1P12_LOOP100")
    TheHdw.Digital.Patgen.HaltWait

    LPPFM_VDDLDO_V_50mA_3p7 = TheHdw.DCVI.pins("CSR_VLX").Meter.Read(tlNoStrobe, 100)
    LPPFM_VDDBAT_I_50mA_3p7 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 100)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIO_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    LPPFM_PMUVDDIOA_I_50mA_3p7 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    
    '-------------------------------------------------
    'VDDBAT = 5.25V, 50mA load at LDO_VDD1P0
    '-------------------------------------------------
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_5p25V_50mA"
    TheHdw.wait 2 * mS

    'Measure PMU_VDDBAT5 and LDO_VDD1P12 through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDBAT_VDD1P12_LOOP100")
    TheHdw.Digital.Patgen.HaltWait

    LPPFM_VDDLDO_V_50mA_5p25 = TheHdw.DCVI.pins("CSR_VLX").Meter.Read(tlNoStrobe, 100)
    LPPFM_VDDBAT_I_50mA_5p25 = TheHdw.DCVI.pins("ET_LINREG_VDD_V5P0").Meter.Read(tlNoStrobe, 100)
    
    TheHdw.wait 20 * mS
    'Measure PMU_VDDIO through pattern
    TheHdw.Patterns(PMU_MEASURE).Start ("VDDIO_LOOP1")
    TheHdw.Digital.Patgen.HaltWait
    
    LPPFM_PMUVDDIOA_I_50mA_5p25 = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlNoStrobe, 1, 781.25)
    

    
    'Clear register
    Call Pmu_registerSetup__clearUDR        '# Clear UDR register
    TheHdw.wait 1 * mS
   
    
    '************************************* Efficiency Calculation *************************************
    pmutb.Calc_Eff 3#, 1 * mA, LPPFM_VDDLDO_V_1mA_3p0, LPPFM_VDDBAT_I_1mA_3p0, LPPFM_Eff_1mA_3p0
    pmutb.Calc_Eff 3.7, 1 * mA, LPPFM_VDDLDO_V_1mA_3p7, LPPFM_VDDBAT_I_1mA_3p7, LPPFM_Eff_1mA_3p7
    pmutb.Calc_Eff 5.25, 1 * mA, LPPFM_VDDLDO_V_1mA_5p25, LPPFM_VDDBAT_I_1mA_5p25, LPPFM_Eff_1mA_5p25

    pmutb.Calc_Eff 3#, 20 * mA, LPPFM_VDDLDO_V_20mA_3p0, LPPFM_VDDBAT_I_20mA_3p0, LPPFM_Eff_20mA_3p0
    pmutb.Calc_Eff 3.7, 20 * mA, LPPFM_VDDLDO_V_20mA_3p7, LPPFM_VDDBAT_I_20mA_3p7, LPPFM_Eff_20mA_3p7
    pmutb.Calc_Eff 5.25, 20 * mA, LPPFM_VDDLDO_V_20mA_5p25, LPPFM_VDDBAT_I_20mA_5p25, LPPFM_Eff_20mA_5p25

    pmutb.Calc_Eff 3#, 20 * mA, LPPFM_VDDLDO_V_50mA_3p0, LPPFM_VDDBAT_I_50mA_3p0, LPPFM_Eff_50mA_3p0
    pmutb.Calc_Eff 3.7, 20 * mA, LPPFM_VDDLDO_V_50mA_3p7, LPPFM_VDDBAT_I_50mA_3p7, LPPFM_Eff_50mA_3p7
    pmutb.Calc_Eff 5.25, 20 * mA, LPPFM_VDDLDO_V_50mA_5p25, LPPFM_VDDBAT_I_50mA_5p25, LPPFM_Eff_50mA_5p25

    'Include the PMU_VDDIO current
    pmutb.Calc_Eff_INC_PMU_VDDIO 3#, 1 * mA, LPPFM_VDDLDO_V_1mA_3p0, LPPFM_VDDBAT_I_1mA_3p0, 1.8, LPPFM_PMUVDDIOA_I_1mA_3p0, LPPFM_Eff_1mA_3p0_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 3.7, 1 * mA, LPPFM_VDDLDO_V_1mA_3p7, LPPFM_VDDBAT_I_1mA_3p7, 1.8, LPPFM_PMUVDDIOA_I_1mA_3p7, LPPFM_Eff_1mA_3p7_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 5.25, 1 * mA, LPPFM_VDDLDO_V_1mA_5p25, LPPFM_VDDBAT_I_1mA_5p25, 1.8, LPPFM_PMUVDDIOA_I_1mA_5p25, LPPFM_Eff_1mA_5p25_INC_PMUVDDIO

    pmutb.Calc_Eff_INC_PMU_VDDIO 3#, 20 * mA, LPPFM_VDDLDO_V_20mA_3p0, LPPFM_VDDBAT_I_20mA_3p0, 1.8, LPPFM_PMUVDDIOA_I_20mA_3p0, LPPFM_Eff_20mA_3p0_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 3.7, 20 * mA, LPPFM_VDDLDO_V_20mA_3p7, LPPFM_VDDBAT_I_20mA_3p7, 1.8, LPPFM_PMUVDDIOA_I_20mA_3p7, LPPFM_Eff_20mA_3p7_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 5.25, 20 * mA, LPPFM_VDDLDO_V_20mA_5p25, LPPFM_VDDBAT_I_20mA_5p25, 1.8, LPPFM_PMUVDDIOA_I_20mA_5p25, LPPFM_Eff_20mA_5p25_INC_PMUVDDIO

    pmutb.Calc_Eff_INC_PMU_VDDIO 3#, 50 * mA, LPPFM_VDDLDO_V_50mA_3p0, LPPFM_VDDBAT_I_50mA_3p0, 1.8, LPPFM_PMUVDDIOA_I_50mA_3p0, LPPFM_Eff_50mA_3p0_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 3.7, 50 * mA, LPPFM_VDDLDO_V_50mA_3p7, LPPFM_VDDBAT_I_50mA_3p7, 1.8, LPPFM_PMUVDDIOA_I_50mA_3p7, LPPFM_Eff_50mA_3p7_INC_PMUVDDIO
    pmutb.Calc_Eff_INC_PMU_VDDIO 5.25, 50 * mA, LPPFM_VDDLDO_V_50mA_5p25, LPPFM_VDDBAT_I_50mA_5p25, 1.8, LPPFM_PMUVDDIOA_I_50mA_5p25, LPPFM_Eff_50mA_5p25_INC_PMUVDDIO


    '************************************* Limit Check *************************************
    'CSR LPPFM Mode
    
If (Device.Flow <> QUAL) Then
    '0mA Load
    Call LimitsTool.TestLimit(LPPFM_VDDLDO_V_0mA_3p0, "CSR_VLX", "PMU_CSR_" + "LPPFM_LDO_V_0mA_3p0")
    Call LimitsTool.TestLimit(LPPFM_VDDLDO_V_0mA_3p7, "CSR_VLX", "PMU_CSR_" + "LPPFM_LDO_V_0mA_3p7")
    Call LimitsTool.TestLimit(LPPFM_VDDLDO_V_0mA_5p25, "CSR_VLX", "PMU_CSR_" + "LPPFM_LDO_V_0mA_5p25")
End If

    'Quiescent current [C12]
    Call LimitsTool.TestLimit(LPPFM_VDDBAT_I_0mA_3p0, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "LPPFM_QCurrent_3p0")
    Call LimitsTool.TestLimit(LPPFM_VDDBAT_I_0mA_3p7, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "LPPFM_Qcurrent_3p7")
    Call LimitsTool.TestLimit(LPPFM_VDDBAT_I_0mA_5p25, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "LPPFM_Qcurrent_5p25")
 
If (Device.Flow <> QUAL) Then
    '1mA [C11]
    Call LimitsTool.TestLimit(LPPFM_VDDLDO_V_1mA_3p0, "CSR_VLX", "PMU_CSR_" + "LPPFM_LDO_V_1mA_3p0")
    Call LimitsTool.TestLimit(LPPFM_VDDLDO_V_1mA_3p7, "CSR_VLX", "PMU_CSR_" + "LPPFM_LDO_V_1mA_3p7")
    Call LimitsTool.TestLimit(LPPFM_VDDLDO_V_1mA_5p25, "CSR_VLX", "PMU_CSR_" + "LPPFM_LDO_V_1mA_5p25")
End If
    
    Call LimitsTool.TestLimit(LPPFM_VDDBAT_I_1mA_3p0, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "LPPFM_VBAT_I_1mA_3p0")
    Call LimitsTool.TestLimit(LPPFM_VDDBAT_I_1mA_3p7, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "LPPFM_VBAT_I_1mA_3p7")
    Call LimitsTool.TestLimit(LPPFM_VDDBAT_I_1mA_5p25, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "LPPFM_VBAT_I_1mA_5p25")
    
    Call LimitsTool.TestLimit(LPPFM_PMUVDDIOA_I_1mA_3p0, "PMU_VDDIOP", "PMU_CSR_" + "LPPFM_PMUVDDIO_I_1mA_3p0")
    Call LimitsTool.TestLimit(LPPFM_PMUVDDIOA_I_1mA_3p7, "PMU_VDDIOP", "PMU_CSR_" + "LPPFM_PMUVDDIO_I_1mA_3p7")
    Call LimitsTool.TestLimit(LPPFM_PMUVDDIOA_I_1mA_5p25, "PMU_VDDIOP", "PMU_CSR_" + "LPPFM_PMUVDDIO_I_1mA_5p25")
    
    '20mA
    Call LimitsTool.TestLimit(LPPFM_VDDLDO_V_20mA_3p0, "CSR_VLX", "PMU_CSR_" + "LPPFM_LDO_V_20mA_3p0")
    Call LimitsTool.TestLimit(LPPFM_VDDLDO_V_20mA_3p7, "CSR_VLX", "PMU_CSR_" + "LPPFM_LDO_V_20mA_3p7")
    Call LimitsTool.TestLimit(LPPFM_VDDLDO_V_20mA_5p25, "CSR_VLX", "PMU_CSR_" + "LPPFM_LDO_V_20mA_5p25")
    
    Call LimitsTool.TestLimit(LPPFM_VDDBAT_I_20mA_3p0, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "LPPFM_VBAT_I_20mA_3p0")
    Call LimitsTool.TestLimit(LPPFM_VDDBAT_I_20mA_3p7, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "LPPFM_VBAT_I_20mA_3p7")
    Call LimitsTool.TestLimit(LPPFM_VDDBAT_I_20mA_5p25, "ET_LINREG_VDD_V5P0", "PMU_CSR_" + "LPPFM_VBAT_I_20mA_5p25")
    
    Call LimitsTool.TestLimit(LPPFM_PMUVDDIOA_I_20mA_3p0, "PMU_VDDIOP", "PMU_CSR_" + "LPPFM_PMUVDDIO_I_20mA_3p0")
    Call LimitsTool.TestLimit(LPPFM_PMUVDDIOA_I_20mA_3p7, "PMU_VDDIOP", "PMU_CSR_" + "LPPFM_PMUVDDIO_I_20mA_3p7")
    Call LimitsTool.TestLimit(LPPFM_PMUVDDIOA_I_20mA_5p25, "PMU_VDDIOP", "PMU_CSR_" + "LPPFM_PMUVDDIO_I_20mA_5p25")
    
    'CSR LPPFM Power efficiency
If (Device.Flow <> QUAL) Then
    Call LimitsTool.TestLimit(LPPFM_Eff_1mA_3p0, "CSR_VLX", "PMU_CSR_" + "LPPFM_Eff_1mA_3p0")       ' [C13i]
    Call LimitsTool.TestLimit(LPPFM_Eff_1mA_3p7, "CSR_VLX", "PMU_CSR_" + "LPPFM_Eff_1mA_3p7")
    Call LimitsTool.TestLimit(LPPFM_Eff_1mA_5p25, "CSR_VLX", "PMU_CSR_" + "LPPFM_Eff_1mA_5p25")
End If

    Call LimitsTool.TestLimit(LPPFM_Eff_20mA_3p0, "CSR_VLX", "PMU_CSR_" + "LPPFM_Eff_20mA_3p0")      '[C14i]
    Call LimitsTool.TestLimit(LPPFM_Eff_20mA_3p7, "CSR_VLX", "PMU_CSR_" + "LPPFM_Eff_20mA_3p7")
    Call LimitsTool.TestLimit(LPPFM_Eff_20mA_5p25, "CSR_VLX", "PMU_CSR_" + "LPPFM_Eff_20mA_5p25")
    
    Call LimitsTool.TestLimit(LPPFM_Eff_50mA_3p0, "CSR_VLX", "PMU_CSR_" + "LPPFM_Eff_50mA_3p0")      '[C15i]
    Call LimitsTool.TestLimit(LPPFM_Eff_50mA_3p7, "CSR_VLX", "PMU_CSR_" + "LPPFM_Eff_50mA_3p7")
    Call LimitsTool.TestLimit(LPPFM_Eff_50mA_5p25, "CSR_VLX", "PMU_CSR_" + "LPPFM_Eff_50mA_5p25")
    
    
    'CSR LPPFM Power efficiency with PMU_VDDIO
If (Device.Flow <> QUAL) Then
    Call LimitsTool.TestLimit(LPPFM_Eff_1mA_3p0_INC_PMUVDDIO, "CSR_VLX", "PMU_CSR_" + "LPPFM_Eff_1mA_3p0_INC_PMU_VDDIO")     '[C13ii]
    Call LimitsTool.TestLimit(LPPFM_Eff_1mA_3p7_INC_PMUVDDIO, "CSR_VLX", "PMU_CSR_" + "LPPFM_Eff_1mA_3p7_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(LPPFM_Eff_1mA_5p25_INC_PMUVDDIO, "CSR_VLX", "PMU_CSR_" + "LPPFM_Eff_1mA_5p25_INC_PMU_VDDIO")
End If

    Call LimitsTool.TestLimit(LPPFM_Eff_20mA_3p0_INC_PMUVDDIO, "CSR_VLX", "PMU_CSR_" + "LPPFM_Eff_20mA_3p0_INC_PMU_VDDIO")   '[C14ii]
    Call LimitsTool.TestLimit(LPPFM_Eff_20mA_3p7_INC_PMUVDDIO, "CSR_VLX", "PMU_CSR_" + "LPPFM_Eff_20mA_3p7_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(LPPFM_Eff_20mA_5p25_INC_PMUVDDIO, "CSR_VLX", "PMU_CSR_" + "LPPFM_Eff_20mA_5p25_INC_PMU_VDDIO")

    Call LimitsTool.TestLimit(LPPFM_Eff_50mA_3p0_INC_PMUVDDIO, "CSR_VLX", "PMU_CSR_" + "LPPFM_Eff_50mA_3p0_INC_PMU_VDDIO")   '[C15ii]
    Call LimitsTool.TestLimit(LPPFM_Eff_50mA_3p7_INC_PMUVDDIO, "CSR_VLX", "PMU_CSR_" + "LPPFM_Eff_50mA_3p7_INC_PMU_VDDIO")
    Call LimitsTool.TestLimit(LPPFM_Eff_50mA_5p25_INC_PMUVDDIO, "CSR_VLX", "PMU_CSR_" + "LPPFM_Eff_50mA_5p25_INC_PMU_VDDIO")

    If (TheExec.Sites.Active.count = 0) Then Exit Function
    '------------------------------------
    'Must reduce to 10mA and ramp down  -
    '------------------------------------
    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_10mA_2V"
    TheHdw.wait 1 * mS
    pmutb.Apply_PSET "CSR_VLX", "VDDLDO_0mA_2V"
    
    '************************************* Restore Voltages to nominal ***********************************************************************************************************************************************
    'Disconnect LDO_VDD1P0
    With TheHdw.DCVI.pins("CSR_VLX")
        .Gate = False
        .Disconnect tlDCVIConnectDefault
        .Mode = tlDCVIModeHighImpedance
        .BleederResistor = tlDCVIBleederResistorOff
    End With
    
    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_200mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_20mA"

    TheExec.Datalog.WriteComment ""
    TheExec.Datalog.WriteComment "PMU_SwitchRegTests_CSR_LPPFM Test time:" & testTime
    TheExec.Datalog.WriteComment ""
    
Exit Function

ErrorHandler:
    If TheExec.Sites.ActiveCount = 0 Then Exit Function         'If last site failed, exit the test and let IGXL cleanup
    TheExec.ErrorLogMessage "VB Error #" & Trim(Str(err.Number)) & " " & err.Description & " in instance " & TheExec.DataManager.InstanceName
    Resume Next

End Function

Public Sub PMU_ApplyLevelsTimingEnableJTAGPA()

    TheHdw.Protocol.Ports(JTAG_PORT).Halt
    TheHdw.Digital.applyLevelsTiming True, False, True, tlPowered
    TheHdw.Protocol.Ports(JTAG_PORT).Enabled = True
    TheHdw.Protocol.ModuleRecordingEnabled = True

End Sub

Public Sub PMU_ApplyLevelsTimingDisableJTAGPA()

    TheHdw.Protocol.Ports(JTAG_PORT).Halt
    TheHdw.Protocol.Ports(JTAG_PORT).Enabled = False
    TheHdw.Protocol.ModuleRecordingEnabled = False

End Sub

Public Sub PMU_ApplyLevelsTimingEnablePOP()

    TheHdw.Protocol.Ports(JTAG_PORT).Halt
    TheHdw.Protocol.Ports(JTAG_PORT).Enabled = False
    TheHdw.Protocol.ModuleRecordingEnabled = False
    
    TheHdw.Digital.applyLevelsTiming True, False, True, tlPowered
End Sub

Public Function PMU__PowerSwitches() As Long
On Error GoTo ErrorHandler

    Dim RTime As Double, ElapsedTime As Double
    
    Dim PS_LDO_VDD_1P22_5mA_3p7V As New SiteDouble
    Dim PS_VDDOUT_1P2_SW_5mA_3p7V As New SiteDouble
    
    Dim PS_PMU_VDDIO_60mA_3p7V As New SiteDouble
    Dim PS_VDDOUT_VDDIO_60mA_3p7V As New SiteDouble
    
    Dim PS_PMU_VDDIO_20mA_3p7V As New SiteDouble
    Dim PS_VDDOUT_1P8_SW1_20mA_2V As New SiteDouble
    
    Dim PS_PMU_VDDIO_1mA_3p7V As New SiteDouble
    Dim PS_VDDOUT_1P8_SW2_1mA_2V As New SiteDouble
 
    Dim PS_VDDOUT_BTLDO3P3_100mA_3p7V As New SiteDouble
    Dim PS_VDDOUT_BT3P3_SW1_100mA_3p7V As New SiteDouble

    Dim PS_VDDOUT_BTLDO3P3_20mA_3p7V As New SiteDouble
    Dim PS_VDDOUT_BT3P3_SW2_20mA_3p7V As New SiteDouble

    Dim PS_VDDOUT_BT3P3_SW3_20mA_3p7V As New SiteDouble

 
    Dim testTime As Double
    TheHdw.StartStopwatch
    
'''    With TheHdw.DCVI.pins("VDDOUT_MISCLDO")
'''        .BleederResistor = tlDCVIBleederResistorAuto
'''        .Mode = tlDCVIModeCurrent
'''        .Current = -0.5 * mA
'''        .Voltage = 0.7
'''        .Connect tlDCVIConnectDefault
'''        TheHdw.wait 2 * mS
'''        .Gate = True
'''    End With

    pmutb.Apply_PSET "ET_LINREG_VDD_V5P0", "VDDBAT_3p7V_2mA"
    pmutb.Apply_PSET_VS256 "PMU_VDDIOP", "PMUVDDIO_1p8V_2mA"

    With TheHdw.DCVI.pins("CSR_VLX, ASR_VLX, VDDOUT_RETLDO, VDDOUT_AON") 'CSR_VLX = LDO_VDD1P0, ASR_VLX=LDO_VDD_1P22
        .BleederResistor = tlDCVIBleederResistorAuto
        .Disconnect tlDCVIConnectDefault
        .Mode = tlDCVIModeHighImpedance
        .Connect tlDCVIConnectHighSense
    End With
    TheHdw.wait 10 * mS
       

    '-------------------------------------------- VDDOUT_1P2_SW Bypass Ron (H1) --------------------------------------------
    Call Pmu_registerSetup__VDDOUT_1P2_SW_Mode
    TheHdw.wait 5 * mS
 
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU System Test - PMU Power Switches Test - VDDOUT_1P2_SW Bypass Ron [H1]"
    TheExec.Datalog.WriteComment "================================================================================================"

    With TheHdw.DCVI.pins("ASR_VLX")
        .BleederResistor = tlDCVIBleederResistorAuto
        .Mode = tlDCVIModeHighImpedance
        .Connect tlDCVIConnectHighSense
    End With
    pmutb.Connect_LDO ("VDDOUT_1P2_SW")

    pmutb.Apply_PSET "VDDOUT_1P2_SW", "VDDOUT_1P2_SW_5mA_2V"                              '# 5mA Load setting at output of VDDOUT_1P2_SW
    TheHdw.wait 5 * mS
    PS_LDO_VDD_1P22_5mA_3p7V = pmutb.Meter_Strobe("ASR_VLX", 20, 1 * mS)      '# measure ASR_VLX=LDO_VDD_1P22
    PS_VDDOUT_1P2_SW_5mA_3p7V = pmutb.Meter_Strobe("VDDOUT_1P2_SW", 20, 1 * mS)     '# measure VDDOUT_1P2_SW

    With TheHdw.DCVI.pins("ASR_VLX, VDDOUT_1P2_SW")
        .Gate = False
        .Disconnect tlDCVIConnectDefault
        .BleederResistor = tlDCVIBleederResistorAuto
        .Mode = tlDCVIModeHighImpedance
    End With

    Call LimitsTool.TestLimit(PS_LDO_VDD_1P22_5mA_3p7V, "ASR_VLX", "PMU_" + "PS_LDO_VDD_1P22_5mA_3p7V")
    Call LimitsTool.TestLimit(PS_VDDOUT_1P2_SW_5mA_3p7V, "VDDOUT_1P2_SW", "PMU_" + "PS_VDDOUT_1P2_SW_5mA_3p7V")
    Call LimitsTool.TestLimit(PS_LDO_VDD_1P22_5mA_3p7V.Subtract(PS_VDDOUT_1P2_SW_5mA_3p7V).Divide(5 * mA).Abs, "PS_VDDOUT_1P2_SW", "PMU_" + "PS_VDDOUT_1P2_SW_Bypass_RON")

   '-------------------------------------------- VDDOUT_VDDIO Bypass Ron (H2) --------------------------------------------
    Call Pmu_registerSetup__VDDOUT_VDDIO_Mode
    TheHdw.wait 5 * mS
 
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU System Test - PMU Power Switches Test - VDDOUT_VDDIO Bypass Ron [H2]"
    TheExec.Datalog.WriteComment "================================================================================================"

    pmutb.Connect_LDO ("VDDOUT_VDDIO")
    pmutb.Apply_PSET "VDDOUT_VDDIO", "VDDOUT_VDDIO_60mA_2V"                              '# 60mA Load setting at output of VDDOUT_VDDIO
    TheHdw.wait 5 * mS
    
    PS_PMU_VDDIO_60mA_3p7V = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlStrobe, 10, 781.25, tlDCVSMeterReadingFormatAverage)
    PS_VDDOUT_VDDIO_60mA_3p7V = pmutb.Meter_Strobe("VDDOUT_VDDIO", 20, 1 * mS)     '# measure VDDOUT_VDDIO

    With TheHdw.DCVI.pins("VDDOUT_VDDIO")
        .Gate = False
        .Disconnect tlDCVIConnectDefault
        .BleederResistor = tlDCVIBleederResistorAuto
        .Mode = tlDCVIModeHighImpedance
    End With

    Call LimitsTool.TestLimit(PS_PMU_VDDIO_60mA_3p7V, "PMU_VDDIOP", "PMU_" + "PS_PMU_VDDIO_60mA_3p7V")
    Call LimitsTool.TestLimit(PS_VDDOUT_VDDIO_60mA_3p7V, "VDDOUT_VDDIO", "PMU_" + "PS_VDDOUT_VDDIO_60mA_3p7V")
    Call LimitsTool.TestLimit(PS_PMU_VDDIO_60mA_3p7V.Subtract(PS_VDDOUT_VDDIO_60mA_3p7V).Divide(60 * mA).Abs, "PS_PMU_VDDIO", "PMU_" + "PS_VDDOUT_VDDIO_Bypass_RON")
    
    
    '-------------------------------------------- VDDOUT_1P8_SW1 Bypass Ron (H3) --------------------------------------------
    Call Pmu_registerSetup__VDDOUT_1P8_SW1_Mode
    TheHdw.wait 5 * mS
 
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU System Test - PMU Power Switches Test - VDDOUT_1P8_SW1 Bypass Ron [H3]"
    TheExec.Datalog.WriteComment "================================================================================================"

    pmutb.Connect_LDO ("VDDOUT_1P8_SW1")
    pmutb.Apply_PSET "VDDOUT_1P8_SW1", "VDDOUT_1P8_SW1_20mA_2V"                              '# 20mA Load setting at output of VDDOUT_1P8_SW1
    TheHdw.wait 5 * mS
    
    PS_PMU_VDDIO_20mA_3p7V = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlStrobe, 10, 781.25, tlDCVSMeterReadingFormatAverage)
    PS_VDDOUT_1P8_SW1_20mA_2V = pmutb.Meter_Strobe("VDDOUT_1P8_SW1", 20, 1 * mS)     '# measure VDDOUT_1P8_SW1

    With TheHdw.DCVI.pins("VDDOUT_1P8_SW1")
        .Gate = False
        .Disconnect tlDCVIConnectDefault
        .BleederResistor = tlDCVIBleederResistorAuto
        .Mode = tlDCVIModeHighImpedance
    End With

    Call LimitsTool.TestLimit(PS_PMU_VDDIO_20mA_3p7V, "PMU_VDDIOP", "PMU_" + "PS_PMU_VDDIO_20mA_3p7V_SW1")
    Call LimitsTool.TestLimit(PS_VDDOUT_1P8_SW1_20mA_2V, "VDDOUT_1P8_SW1", "PMU_" + "PS_VDDOUT_1P8_SW1_20mA_2V")
    Call LimitsTool.TestLimit(PS_PMU_VDDIO_20mA_3p7V.Subtract(PS_VDDOUT_1P8_SW1_20mA_2V).Divide(20 * mA).Abs, "PS_PMU_VDDIO", "PMU_" + "PS_VDDOUT_1P8_SW1_Bypass_RON")
    
    '-------------------------------------------- VDDOUT_1P8_SW2 Bypass Ron (H4) --------------------------------------------
    Call Pmu_registerSetup__VDDOUT_1P8_SW2_Mode
    TheHdw.wait 5 * mS
 
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU System Test - PMU Power Switches Test - VDDOUT_1P8_SW2 Bypass Ron [H4]"
    TheExec.Datalog.WriteComment "================================================================================================"

    pmutb.Connect_LDO ("VDDOUT_1P8_SW2")
    pmutb.Apply_PSET "VDDOUT_1P8_SW2", "VDDOUT_1P8_SW2_1mA_2V"                              '# 1mA Load setting at output of VDDOUT_1P8_SW2
    TheHdw.wait 5 * mS
    
    PS_PMU_VDDIO_1mA_3p7V = TheHdw.DCVS.pins("PMU_VDDIOP").Meter.Read(tlStrobe, 10, 781.25, tlDCVSMeterReadingFormatAverage)
    PS_VDDOUT_1P8_SW2_1mA_2V = pmutb.Meter_Strobe("VDDOUT_1P8_SW2", 20, 1 * mS)     '# measure VDDOUT_1P8_SW2

    With TheHdw.DCVI.pins("VDDOUT_1P8_SW2")
        .Gate = False
        .Disconnect tlDCVIConnectDefault
        .BleederResistor = tlDCVIBleederResistorAuto
        .Mode = tlDCVIModeHighImpedance
    End With

    Call LimitsTool.TestLimit(PS_PMU_VDDIO_1mA_3p7V, "PMU_VDDIOP", "PMU_" + "PS_PMU_VDDIO_1mA_3p7V_SW2")
    Call LimitsTool.TestLimit(PS_VDDOUT_1P8_SW2_1mA_2V, "VDDOUT_1P8_SW2", "PMU_" + "PS_VDDOUT_1P8_SW2_1mA_2V")
    Call LimitsTool.TestLimit(PS_PMU_VDDIO_1mA_3p7V.Subtract(PS_VDDOUT_1P8_SW2_1mA_2V).Divide(1 * mA).Abs, "PS_PMU_VDDIO", "PMU_" + "PS_VDDOUT_1P8_SW2_Bypass_RON")
    
    '-------------------------------------------- VDDOUT_3P3_SW1 Bypass Ron (H5) --------------------------------------------
    Call Pmu_registerSetup__VDDOUT_3P3_SW1_Mode
    TheHdw.wait 5 * mS
 
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU System Test - PMU Power Switches Test - VDDOUT_3P3_SW1 Bypass Ron [H5]"
    TheExec.Datalog.WriteComment "================================================================================================"

    With TheHdw.DCVI.pins("VDDOUT_BT3P3")
        .BleederResistor = tlDCVIBleederResistorAuto
        .Mode = tlDCVIModeHighImpedance
        .Connect tlDCVIConnectHighSense
    End With
    pmutb.Connect_LDO ("VDDOUT_BT3P3_SW1")

    pmutb.Apply_PSET "VDDOUT_BT3P3_SW1", "VDDOUT_3P3_SW1_100mA_2V"                              '# 100mA Load setting at output of VDDOUT_BT3P3_SW1
    TheHdw.wait 5 * mS
    PS_VDDOUT_BTLDO3P3_100mA_3p7V = pmutb.Meter_Strobe("VDDOUT_BT3P3", 20, 1 * mS)      '# measure VDDOUT_BT3P3
    PS_VDDOUT_BT3P3_SW1_100mA_3p7V = pmutb.Meter_Strobe("VDDOUT_BT3P3_SW1", 20, 1 * mS)     '# measure VDDOUT_BT3P3_SW1

    With TheHdw.DCVI.pins("VDDOUT_BT3P3, VDDOUT_BT3P3_SW1")
        .Gate = False
        .Disconnect tlDCVIConnectDefault
        .BleederResistor = tlDCVIBleederResistorAuto
        .Mode = tlDCVIModeHighImpedance
    End With

    Call LimitsTool.TestLimit(PS_VDDOUT_BTLDO3P3_100mA_3p7V, "VDDOUT_BT3P3", "PMU_" + "PS_VDDOUT_BTLDO3P3_100mA_3p7V_SW1")
    Call LimitsTool.TestLimit(PS_VDDOUT_BT3P3_SW1_100mA_3p7V, "VDDOUT_BT3P3_SW1", "PMU_" + "PS_VDDOUT_BT3P3_SW1_100mA_3p7V")
    Call LimitsTool.TestLimit(PS_VDDOUT_BTLDO3P3_100mA_3p7V.Subtract(PS_VDDOUT_BT3P3_SW1_100mA_3p7V).Divide(100 * mA).Abs, "PS_VDDOUT_BTLDO3P3_100mA_3p7V", "PMU_" + "PS_VDDOUT_BT3P3_SW1_Bypass_RON")

    '-------------------------------------------- VDDOUT_3P3_SW2 Bypass Ron (H6) --------------------------------------------
    Call Pmu_registerSetup__VDDOUT_3P3_SW2_Mode
    TheHdw.wait 5 * mS
 
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU System Test - PMU Power Switches Test - VDDOUT_3P3_SW2 Bypass Ron [H6]"
    TheExec.Datalog.WriteComment "================================================================================================"

    ' ##### Connect Relay
    TheHdw.Utility.pins("K3").state = tlUtilBitOn
    
    With TheHdw.DCVI.pins("VDDOUT_BT3P3")
        .BleederResistor = tlDCVIBleederResistorAuto
        .Mode = tlDCVIModeHighImpedance
        .Connect tlDCVIConnectHighSense
    End With
    pmutb.Connect_LDO ("VDDOUT_1P2_SW")

    pmutb.Apply_PSET "VDDOUT_1P2_SW", "VDDOUT_3P3_SW2_20mA_2V"                              '# 20mA Load setting at output of VDDOUT_1P2_SW
    TheHdw.wait 5 * mS
    PS_VDDOUT_BTLDO3P3_20mA_3p7V = pmutb.Meter_Strobe("VDDOUT_BT3P3", 20, 1 * mS)      '# measure VDDOUT_BT3P3
    PS_VDDOUT_BT3P3_SW2_20mA_3p7V = pmutb.Meter_Strobe("VDDOUT_1P2_SW", 20, 1 * mS)     '# measure VDDOUT_1P2_SW

    With TheHdw.DCVI.pins("VDDOUT_BT3P3, VDDOUT_1P2_SW")
        .Gate = False
        .Disconnect tlDCVIConnectDefault
        .BleederResistor = tlDCVIBleederResistorAuto
        .Mode = tlDCVIModeHighImpedance
    End With

    ' ##### Disconnect Relay
    TheHdw.Utility.pins("K3").state = tlUtilBitOff
    
    Call LimitsTool.TestLimit(PS_VDDOUT_BTLDO3P3_20mA_3p7V, "VDDOUT_BT3P3", "PMU_" + "PS_VDDOUT_BTLDO3P3_20mA_3p7V_SW2")
    Call LimitsTool.TestLimit(PS_VDDOUT_BT3P3_SW2_20mA_3p7V, "VDDOUT_1P2_SW", "PMU_" + "PS_VDDOUT_BT3P3_SW2_20mA_3p7V")
    Call LimitsTool.TestLimit(PS_VDDOUT_BTLDO3P3_20mA_3p7V.Subtract(PS_VDDOUT_BT3P3_SW2_20mA_3p7V).Divide(100 * mA).Abs, "PS_VDDOUT_BTLDO3P3_20mA_3p7V", "PMU_" + "PS_VDDOUT_BT3P3_SW2_Bypass_RON")


    '-------------------------------------------- VDDOUT_3P3_SW3 Bypass Ron (H7) --------------------------------------------
    Call Pmu_registerSetup__VDDOUT_3P3_SW3_Mode
    TheHdw.wait 5 * mS
 
    TheExec.Datalog.WriteComment "================================================================================================"
    TheExec.Datalog.WriteComment "PMU System Test - PMU Power Switches Test - VDDOUT_3P3_SW3 Bypass Ron [H7]"
    TheExec.Datalog.WriteComment "================================================================================================"

    ' ##### Connect Relay
    TheHdw.Utility.pins("K3").state = tlUtilBitOn
    
    With TheHdw.DCVI.pins("VDDOUT_BT3P3")
        .BleederResistor = tlDCVIBleederResistorAuto
        .Mode = tlDCVIModeHighImpedance
        .Connect tlDCVIConnectHighSense
    End With
    pmutb.Connect_LDO ("VDDOUT_BT3P3_SW1")

    pmutb.Apply_PSET "VDDOUT_BT3P3_SW1", "VDDOUT_3P3_SW3_20mA_2V"                              '# 20mA Load setting at output of VDDOUT_BT3P3_SW1
    TheHdw.wait 5 * mS
    PS_VDDOUT_BTLDO3P3_20mA_3p7V = pmutb.Meter_Strobe("VDDOUT_BT3P3", 20, 1 * mS)      '# measure VDDOUT_BT3P3
    PS_VDDOUT_BT3P3_SW3_20mA_3p7V = pmutb.Meter_Strobe("VDDOUT_BT3P3_SW1", 20, 1 * mS)     '# measure VDDOUT_1P2_SW

    With TheHdw.DCVI.pins("VDDOUT_BT3P3, VDDOUT_BT3P3_SW1")
        .Gate = False
        .Disconnect tlDCVIConnectDefault
        .BleederResistor = tlDCVIBleederResistorAuto
        .Mode = tlDCVIModeHighImpedance
    End With

    ' ##### Disconnect Relay
    TheHdw.Utility.pins("K3").state = tlUtilBitOff
    
    Call LimitsTool.TestLimit(PS_VDDOUT_BTLDO3P3_20mA_3p7V, "VDDOUT_BT3P3", "PMU_" + "PS_VDDOUT_BTLDO3P3_20mA_3p7V_SW3")
    Call LimitsTool.TestLimit(PS_VDDOUT_BT3P3_SW3_20mA_3p7V, "VDDOUT_BT3P3_SW1", "PMU_" + "PS_VDDOUT_BT3P3_SW3_20mA_3p7V")
    Call LimitsTool.TestLimit(PS_VDDOUT_BTLDO3P3_20mA_3p7V.Subtract(PS_VDDOUT_BT3P3_SW3_20mA_3p7V).Divide(20 * mA).Abs, "PS_VDDOUT_BTLDO3P3_20mA_3p7V", "PMU_" + "PS_VDDOUT_BT3P3_SW3_Bypass_RON")

    
    testTime = TheHdw.ReadStopwatch
    TheExec.Datalog.WriteComment ""
    TheExec.Datalog.WriteComment "PMU_PowerModeTest_PowerSwitches Test time:" & testTime
    TheExec.Datalog.WriteComment ""
    Exit Function
    
ErrorHandler:
    If TheExec.Sites.ActiveCount = 0 Then Exit Function              'If last site failed, exit the test and let IGXL cleanup
    TheExec.ErrorLogMessage "VB Error #" & Trim(Str(err.Number)) & " " & err.Description & " in instance " & TheExec.DataManager.InstanceName
    Resume Next
End Function


