Attribute VB_Name = "VBT_PMU_RegisterSetup"
Option Explicit

Public Sub Pmu_registerSetup__clearUDR()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__clearUDR__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        
        'Clear register
        Call UDR_WriteReg(UserDR_3, "0")
        Call UDR_WriteReg(UserDR_4, "0")
        Call UDR_WriteReg(UserDR_6, "0")
        Call UDR_WriteReg(UserDR_5, "0")
        Call UDR_WriteReg(UserDR_7, "0")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub

Public Sub Pmu_registerSetup__Analogmux(Optional muxPin As String = "btldo3p3|rfldo3p3|memlpldo|miscldo|clear")

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__Analogmux__" & muxPin & "__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        If (muxPin = "btldo3p3") Then
            'Register Settings - D3
            Call UDR_WriteReg(UserDR_3, "00000005000000000000000000000000")                '43014
            Call UDR_WriteReg(UserDR_4, "000000000000A80004000F0101000000")
            'Call UDR_WriteReg(UserDR_5, "000000000000000000004000002A0008")
            'Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
        ElseIf (muxPin = "rfldo3p3") Then
            'Register Settings - E3
            Call UDR_WriteReg(UserDR_3, "00000005000000000000000000000000")                '43014
            Call UDR_WriteReg(UserDR_4, "000000000000A80004000D0001000000")
            'Call UDR_WriteReg(UserDR_5, "000000000000000000004000002A0008")
            'Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")

        ElseIf (muxPin = "clear") Then
            Call UDR_WriteReg(UserDR_8, "0")
        Else
        
        End If
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub

Public Sub Pmu_registerSetup__memlpldo__Q1()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__memlpldo__Q1__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        
        'Register Settings - G1
        Call UDR_WriteReg(UserDR_0, "400000000000000000000")
        'Call UDR_WriteReg(UserDR_8, "D800000000000005F03000000")
        'Call UDR_WriteReg(UserDR_10, "800000000000000000000000")
        Call UDR_WriteReg(UserDR_8, "D800000000000005E03000000")
        Call UDR_WriteReg(UserDR_10, "80000000000000000000000")
        Call UDR_WriteReg(UserDR_11, "0")
    
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait
    
End Sub

Public Sub Pmu_registerSetup__memlpldo__Q2()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__memlpldo__Q2__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        
        Call UDR_WriteReg(UserDR_8, "D800000000000005E02040000")
    
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait
    
End Sub

Public Sub Pmu_registerSetup__retldo()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__retldo__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        
        'Register Settings - F1
        Call UDR_WriteReg(UserDR_3, "00080005000000000000000000000000")                '43014
        Call UDR_WriteReg(UserDR_4, "070000000000A8100400050000000000")
        Call UDR_WriteReg(UserDR_5, "000000000000000000004000002A0008")
        Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
    
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait
    
End Sub

Public Sub Pmu_registerSetup__miscldo()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__miscldo__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        
        Call UDR_WriteReg(UserDR_0, "400000000000000000000")                    '4362
        Call UDR_WriteReg(UserDR_8, "3E0000D800000000040004F82040000")
        'Call UDR_WriteReg(UserDR_10, "800000000000000000000000")
        Call UDR_WriteReg(UserDR_10, "80000000000000000000000")
        Call UDR_WriteReg(UserDR_11, "0")
    
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait
    
End Sub


Public Sub Pmu_registerSetup__hvlldo1p8()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__hvlldo1p8__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        
        'Register Settings - G1
        Call UDR_WriteReg(UserDR_3, "00000005000000000000000000000000")                '43014
        Call UDR_WriteReg(UserDR_4, "000000000000A8000400000000000000")
        Call UDR_WriteReg(UserDR_5, "000000000000000000004000002A0008")
        Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
        
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait
    
End Sub

Public Sub Pmu_registerSetup__hvlldo1p8_emmc()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__hvlldo1p8_emmc__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        
        'Register Settings - G1
        Call UDR_WriteReg(UserDR_3, "00000005000000000000000000000000")                '43014
        Call UDR_WriteReg(UserDR_4, "000000000000A8000400000000800000")
        Call UDR_WriteReg(UserDR_5, "000000000000000000004000002A0008")
        Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
        
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait
    
End Sub

Public Sub Pmu_registerSetup__rfldo3p3()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__rfldo3p3__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        
        'Register Settings - E1
        Call UDR_WriteReg(UserDR_3, "00000005000000000000000000000000")                '43014
        Call UDR_WriteReg(UserDR_4, "000000000000A8000400000001000000")
        Call UDR_WriteReg(UserDR_5, "000000000000000000004000002A0008")
        Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait
    
End Sub

Public Sub Pmu_registerSetup__btldo3p3()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__btldo3p3__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        
        'Register Settings - D1
        Call UDR_WriteReg(UserDR_3, "00000005000000000000000000000000")                '43014
        Call UDR_WriteReg(UserDR_4, "000000000000A8000400000100000000")
        Call UDR_WriteReg(UserDR_5, "000000000000000000004000002A0008")
        Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait
    
End Sub

Public Sub Pmu_registerSetup__PSMode_memlpldo_pd()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__PSMode_memlpldo_pd__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        Call UDR_WriteReg(UserDR_8, "D800000000000000020000000")      '4362
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub

Public Sub Pmu_registerSetup__PSMode()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__PSMode__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then

        '''0x100000 0x0 0x40000 0x0
        Call UDR_WriteReg(UserDR_0, "400000000000000100000")                '4362 -> A4
        Call UDR_WriteReg(UserDR_8, "D800000000000000000000000")
        Call UDR_WriteReg(UserDR_10, "0") '4362 -> A4
        Call UDR_WriteReg(UserDR_11, "0") '4362
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub

Public Sub Pmu_registerSetup__PS0A_Mode()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__PS0A_Mode__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        Call UDR_WriteReg(UserDR_3, "00080005000000000000000000000000")                '43014 -> A4
        Call UDR_WriteReg(UserDR_4, "00000000000080100400000000000000")
        Call UDR_WriteReg(UserDR_5, "000000000000000000004000002A0008")
        Call UDR_WriteReg(UserDR_6, "000000000000013000000000002A0008")
        Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub

Public Sub Pmu_registerSetup__PS0C_Mode()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__PS0C_Mode__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        Call UDR_WriteReg(UserDR_3, "00080005000000000000000000000000")                '43014 -> A7
        Call UDR_WriteReg(UserDR_4, "00000000000048100400000000000000")
        Call UDR_WriteReg(UserDR_5, "000000000000000000004000002A0008")
        Call UDR_WriteReg(UserDR_6, "000000000000013000000000002A0008")
        Call UDR_WriteReg(UserDR_7, "0000000000000A000000000000000000")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub

Public Sub Pmu_registerSetup__PS1A_Mode()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__PS1A_Mode__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        Call UDR_WriteReg(UserDR_3, "00080005000000000000000000000000")                '43014 -> A10
        Call UDR_WriteReg(UserDR_4, "00000000000000000400000000000000")
        Call UDR_WriteReg(UserDR_5, "000000000000801000004000002A0008")
        Call UDR_WriteReg(UserDR_6, "000000000000013000000000002A0008")
        Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub

Public Sub Pmu_registerSetup__PS1C_Mode()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__PS1C_Mode__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        Call UDR_WriteReg(UserDR_3, "00080005000000000000000000000000")                '43014 -> A13
        Call UDR_WriteReg(UserDR_4, "00000000000000000400000000000000")
        Call UDR_WriteReg(UserDR_5, "000000000000481000004000002A0008")
        Call UDR_WriteReg(UserDR_6, "000000000000013000000000002A0008")
        Call UDR_WriteReg(UserDR_7, "0000000000000A000000000000000000")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub

Public Sub Pmu_registerSetup__LPMode()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__LPMode__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        Call UDR_WriteReg(UserDR_0, "400000000000000000000")
        Call UDR_WriteReg(UserDR_8, "C00000FD800000000400000100000000")
        Call UDR_WriteReg(UserDR_10, "C000000000000000000000000000")
        Call UDR_WriteReg(UserDR_11, "3000")

        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub

Public Sub Pmu_registerSetup__WakeUp_4362()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__LPLVMode_WakeUp__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        
        Call UDR_WriteReg(UserDR_0, "400000000000000000000")
        Call UDR_WriteReg(UserDR_8, "D800000000000000000000000")
        Call UDR_WriteReg(UserDR_10, "0")
        Call UDR_WriteReg(UserDR_11, "0")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait
End Sub

Public Sub Pmu_registerSetup__WakeUp()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__LPLVMode_WakeUp__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        Call UDR_WriteReg(UserDR_3, "00080005000000000000000000000000")                '43014
        Call UDR_WriteReg(UserDR_4, "000000000000A8100400000000000000")
        Call UDR_WriteReg(UserDR_5, "000000000000001000004000002A0008")
        Call UDR_WriteReg(UserDR_6, "000000000000003000000000002A0008")
        Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait
End Sub

Public Sub Pmu_registerSetup__LV1Mode()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__LV1Mode__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        '-----------------------------------------
        'Low Voltage Mode (srbg_ref_sel=1) for A10
        '-----------------------------------------
        Call UDR_WriteReg(UserDR_0, "400000000000000000000")
        Call UDR_WriteReg(UserDR_8, "C00000FD8C0000000440000100EC0FA4")
        Call UDR_WriteReg(UserDR_10, "780C00000000000000000F001E00000")
        Call UDR_WriteReg(UserDR_11, "3")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait
End Sub

Public Sub Pmu_registerSetup__LV0Mode()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__LV0Mode__PAModule"
    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        
    '-----------------------------------------
    'Low Voltage Mode (srbg_ref_sel=0) for A12
    '-----------------------------------------
    Call UDR_WriteReg(UserDR_0, "400000000000000000000")
    Call UDR_WriteReg(UserDR_8, "C00000FD8C0000000040000100EC0FA4")
    Call UDR_WriteReg(UserDR_10, "780800000000000000000F001E00000")
    Call UDR_WriteReg(UserDR_11, "3")
    TheHdw.wait 5 * mS
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait
End Sub

Public Sub Pmu_registerSetup__CSR_PWM_Mode()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__CSR_PWM_Mode__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        
        '----------------------------------
        'Output Voltage in PWM Mode for C1
        '----------------------------------
        Call UDR_WriteReg(UserDR_3, "00080005000000000000000000000000")                '43014
        Call UDR_WriteReg(UserDR_4, "000000000000A8500400000000000000")
        Call UDR_WriteReg(UserDR_5, "000000000000000000004000002A0008")
        Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub

Public Sub Pmu_registerSetup__CSR_PFM_Mode()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__CSR_PFM_Mode__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        
        '-------------------------------------
        'Output Voltage in PFM Mode for C6
        '-------------------------------------
        Call UDR_WriteReg(UserDR_3, "00080005000000000000000000000000")                '43014
        Call UDR_WriteReg(UserDR_4, "000010800000A8700400000000000000")
        Call UDR_WriteReg(UserDR_5, "000000000000000000004000002A0008")
        Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub


Public Sub Pmu_registerSetup__CSR_LPPFM_Mode()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__CSR_LPPFM_Mode"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        
        '---------------------------------------
        'Output Voltage in LPPFM Mode for C11
        '---------------------------------------
    
        Call UDR_WriteReg(UserDR_3, "00080005000000000000000000000000")                '43014
        Call UDR_WriteReg(UserDR_4, "000010800000A8F00400000000000000")
        Call UDR_WriteReg(UserDR_5, "000000000000000000004000002A0008")
        Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub

Public Sub Pmu_registerSetup__ASR_PWM_Mode()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__ASR_PWM_Mode__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        
        '---------------------------------
        'Output Voltage in PWM Mode for B1
        '---------------------------------
        Call UDR_WriteReg(UserDR_3, "00080005000000000000000000000000")                '43014
        Call UDR_WriteReg(UserDR_4, "000000000000A8000400000000000000")
        Call UDR_WriteReg(UserDR_5, "000000000000005000004000002A0008")
        Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub

Public Sub Pmu_registerSetup__ASR_PFM_Mode()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__ASR_PFM_Mode__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        
        '----------------------------------
        'Output Voltage in PFM Mode for B6
        '----------------------------------
        Call UDR_WriteReg(UserDR_3, "00080005000000000000000000000000")                '43014
        Call UDR_WriteReg(UserDR_4, "000000000000A8000400000000000000")
        Call UDR_WriteReg(UserDR_5, "000010800000007000004000002A0008")
        Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub


Public Sub Pmu_registerSetup__ASR_LPPFM_Mode()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__ASR_LPPFM_Mode__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        
        '-----------------------------------------
        'Output Voltage in Low Power Mode for B11
        '-----------------------------------------
        Call UDR_WriteReg(UserDR_3, "00080005000000000000000000000000")                '43014
        Call UDR_WriteReg(UserDR_4, "000000000000A8000400000000000000")
        Call UDR_WriteReg(UserDR_5, "00001080000000F000004000002A0008")
        Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub

Public Sub Pmu_registerSetup__turnON__bppll_4362()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__turnON__bppll__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        
        Call UDR_WriteReg(UserDR_0, "3FFFFFFF800000")
        JTAG.wait 5 / 2 * mS
        Call AXI.WriteReg("180001e0", "42")
        JTAG.wait 5 / 2 * mS
    
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait
    
End Sub

Public Sub Pmu_registerSetup__turnON__bppll()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__turnON__bppll__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        Call UDR_WriteReg(UserDR_0, "3FFFFFFF800000")
        JTAG.wait 5 / 2 * mS
        Call AXI.WriteReg("180001e0", "42")
        JTAG.wait 5 / 2 * mS
    
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait
    
End Sub

Public Sub Pmu_registerSetup__ClockOut_4362(Optional clkOut As String = "ck500kOsc_beforeCal|ck500kOsc_afterCal|SWR3p2MOsc_beforeCal|SWR3p2MOsc_afterCal|clear")

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__Analogmux__" & clkOut & "__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
    
        If (clkOut = "ck500kOsc_beforeCal") Then                            '# 500kHz Oscillator before cal
            'Register Settings - H1
            Call UDR_WriteReg(UserDR_0, "40000003FFFFFFF800000")
            Call UDR_WriteReg(UserDR_8, "D800003000001C98000000000")
            'Call UDR_WriteReg(UserDR_8, "D800003000001D98000000000")       '# Muxing out 16MHz calibration clock as reference clock for calibration
            Call UDR_WriteReg(UserDR_10, "0")
            Call UDR_WriteReg(UserDR_11, "0")
            JTAG.wait 2 * mS
            AXI.WriteReg &H18010040, &H0
            AXI.WriteReg &H18010200, &H90000000
            AXI.WriteReg &H18010040, &H7
            AXI.WriteReg &H18010200, &H40036400
            
        ElseIf (clkOut = "ck500kOsc_afterCal") Then                         '# 500kHz Oscillator after cal
            Call UDR_WriteReg(UserDR_10, "4C00000000000000000000000")
        
        ElseIf (clkOut = "SWR3p2MOsc_beforeCal") Then
        
            'Register Settings - H3
            Call UDR_WriteReg(UserDR_0, "40000003FFFFFFF800000")
            Call UDR_WriteReg(UserDR_8, "D8000000000000F8000000000")
            Call UDR_WriteReg(UserDR_10, "3006C000000000000000000")
            Call UDR_WriteReg(UserDR_11, "0")
            JTAG.wait 2 * mS
            AXI.WriteReg &H18010040, &H0
            AXI.WriteReg &H18010200, &H90000000
            AXI.WriteReg &H18010040, &H7
            AXI.WriteReg &H18010200, &H40036400
        
        ElseIf (clkOut = "SWR3p2MOsc_afterCal") Then
        
            'Register Settings - H4
            Call UDR_WriteReg(UserDR_10, "C3106C000000000000000000")       'Waiting to observe from digital
        Else
            Stop
        End If
        JTAG.wait 5 * mS
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub

Public Sub Pmu_registerSetup__ClockOut(Optional clkOut As String = "ck500kOsc_beforeCal|ck500kOsc_afterCal|SWR3p2MOsc_beforeCal|SWR3p2MOsc_afterCal|clear")

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__Analogmux__" & clkOut & "__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
    
        If (clkOut = "ck500kOsc_beforeCal") Then                            '# 500kHz Oscillator before cal
            'Register Settings - I1
            Call UDR_WriteReg(UserDR_3, "00080005000000000000000000000000")                '43014
            Call UDR_WriteReg(UserDR_4, "000000000000A8100400000000000000")
            Call UDR_WriteReg(UserDR_5, "000000000000001000004000002A0008")
            Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
            'JTAG.wait 2 * mS
        ElseIf (clkOut = "ck500kOsc_afterCal") Then                         '# 500kHz Oscillator after cal
            'Register Settings - I2
            Call UDR_WriteReg(UserDR_8, "00000000641800000000000000000000")    '43014
        
        ElseIf (clkOut = "SWR3p2MOsc_beforeCal") Then
            'Register Settings - I3
            Call UDR_WriteReg(UserDR_3, "00080005000000000000000000000000")                '43014
            Call UDR_WriteReg(UserDR_4, "000000000000A8100400000000000000")
            Call UDR_WriteReg(UserDR_5, "000000000000001000004000002A0008")
            Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
            'JTAG.wait 2 * mS
        ElseIf (clkOut = "SWR3p2MOsc_afterCal") Then
            'Register Settings - I4
            Call UDR_WriteReg(UserDR_8, "00000000641836000000000000000000")    '43014
        Else
            Stop
        End If
        JTAG.wait 5 * mS
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub


Public Sub Pmu_registerSetup__VDDOUT_1P2_SW_Mode()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__VDDOUT_1P2_SW_Mode__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        'H1
        Call UDR_WriteReg(UserDR_3, "01080005000000000000000000000000")                '43014
        Call UDR_WriteReg(UserDR_4, "000000000000A8100400000000000000")
        Call UDR_WriteReg(UserDR_5, "000000000000001000004000002A0008")
        Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub

Public Sub Pmu_registerSetup__VDDOUT_VDDIO_Mode()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__VDDOUT_VDDIO_Mode__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        'H2
        Call UDR_WriteReg(UserDR_3, "00080005000000000000000000000000")                '43014
        Call UDR_WriteReg(UserDR_4, "000000000000A8100400000000000000")
        Call UDR_WriteReg(UserDR_5, "000000000000001000004000002A0008")
        Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub


Public Sub Pmu_registerSetup__VDDOUT_1P8_SW1_Mode()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__VDDOUT_1P8_SW1_Mode__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        'H3
        Call UDR_WriteReg(UserDR_3, "04080005000000000000000000000000")                '43014
        Call UDR_WriteReg(UserDR_4, "000000000000A8100400000000000000")
        Call UDR_WriteReg(UserDR_5, "000000000000001000004000002A0008")
        Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub


Public Sub Pmu_registerSetup__VDDOUT_1P8_SW2_Mode()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__VDDOUT_1P8_SW2_Mode__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        'H4
        Call UDR_WriteReg(UserDR_3, "10080005000000000000000000000000")                '43014
        Call UDR_WriteReg(UserDR_4, "000000000000A8100400000000000000")
        Call UDR_WriteReg(UserDR_5, "000000000000001000004000002A0008")
        Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub


Public Sub Pmu_registerSetup__VDDOUT_3P3_SW1_Mode()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__VDDOUT_3P3_SW1_Mode__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        'H5
        Call UDR_WriteReg(UserDR_3, "00080005000000000000000000000000")                '43014
        Call UDR_WriteReg(UserDR_4, "000000000000A8100400000000800010")
        Call UDR_WriteReg(UserDR_5, "000000000000001000004000002A0008")
        Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub


Public Sub Pmu_registerSetup__VDDOUT_3P3_SW2_Mode()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__VDDOUT_3P3_SW2_Mode__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        'H6
        Call UDR_WriteReg(UserDR_3, "00080005000000000000000000000000")                '43014
        Call UDR_WriteReg(UserDR_4, "000000000000A8100400000000800100")
        Call UDR_WriteReg(UserDR_5, "000000000000001000004000002A0008")
        Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub


Public Sub Pmu_registerSetup__VDDOUT_3P3_SW3_Mode()

    Dim moduleName As String
    moduleName = "Pmu_registerSetup__VDDOUT_3P3_SW3_Mode__PAModule"

    If Not TheHdw.Protocol.Ports(JTAG_PORT).Modules.IsRecorded(moduleName, True, False) Then
        'H7
        Call UDR_WriteReg(UserDR_3, "00080005000000000000000000000000")                '43014
        Call UDR_WriteReg(UserDR_4, "000000000000A8100400000000801000")
        Call UDR_WriteReg(UserDR_5, "000000000000001000004000002A0008")
        Call UDR_WriteReg(UserDR_7, "00000000000002000000000000000000")
        TheHdw.Protocol.Ports(JTAG_PORT).Modules.StopRecording
    End If
    Call TheHdw.Protocol.Ports(JTAG_PORT).Modules(moduleName).Start
    Call TheHdw.Protocol.Ports(JTAG_PORT).IdleWait

End Sub
