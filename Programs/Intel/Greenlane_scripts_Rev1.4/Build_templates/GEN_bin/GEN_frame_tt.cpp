//GEN_frame_tt.cpp

#include <GEN_frame_tt.h>

iCGENFrameTest::iCGENFrameTest()
{
    ////Begin_test_template_intefrace_attribute_initialization

    ////End_test_template_intefrace_attribute_initialization

}

iCGENFrameTest::~iCGENFrameTest()
{
    m_zCleanUp();
}

void iCGENFrameTest::m_zCleanUp()
{
    m_zLocalCleanUp();
}

void iCGENFrameTest::m_zLocalCleanUp()
{
	////Clean up variable and object

}

iTStatus iCGENFrameTest::iC_tSetTpParam(const iCGENTpParam& oTpParam)
{
    iTStatus tRetVal;

    tRetVal = iCGENCore::iC_tSetTpParam(oTpParam);
    if (IT_FAIL == tRetVal)
    {
        ////Begin_test_template_set_param

        ////End_test_template_set_param
        else
        {
            return IT_FAIL;
        }
    }
    return IT_PASS;
}


iTStatus iCGENFrameTest::iC_tGetTpParam(iCGENTpParam& oTpParam)
{
    iTStatus tRetVal;

    tRetVal = iCGENCore::iC_tGetTpParam(oTpParam);
    if (IT_FAIL == tRetVal)
    {
        ////Begin_test_template_get_param

        ////End_test_template_get_param
        else
        {
            return IT_FAIL;
        }
    }
    return IT_PASS;
}

iTStatus iCGENFrameTest::iC_tPGContinueOnFullCheck(const iCGENMultiSiteRslt& oExecRslt,
                                                   const iCGENMultiSiteCaptureData* pCaptureData)
{
    return IT_PASS;
}


iTStatus iCGENFrameTest::iC_tVerify()
{
    int nErrorFlag = 0;
    iTStatus tRetVal = IT_FAIL;
    iCString sEnumString = "";
    int nPosition1 = 0;
    int nPosition2 = 0;
    iCString sExecuteStatus = "";

    m_sErrorMsg = "";

    if (m_tDebugMode != IT_DEBUG_DISABLED)
    {
        m_sErrorMsg = iCString::toString("iCGENFrameTest::iC_tVerify of instance \"%s\" is running\n",
                                         m_sInstanceName.c_str());
        m_pCoreIfcParent->iC_zPrint(m_sErrorMsg);
    }

    //Verifies all the params defined in the base class
    tRetVal = iCGENCore::iC_tVerify();

    if (IT_PASS != tRetVal)
    {
        nErrorFlag++;
        if(IT_BYPASS == tRetVal)//HSD1371
        {
            m_vActiveSites.clear();
            tRetVal = ms_pCorTeXGlobal->m_tGetActiveSites(m_vActiveSites);
            if (IT_PASS != tRetVal)
            {
                m_sErrorMsg = "iC_tVerify() Getting Active Sites failed! ";
                m_oException.m_zSet(__FILE__,__LINE__,tRetVal,m_sErrorMsg);
                return m_tExceptionHandler(m_oException);
            }

            ms_pCorTeXGlobal->m_zSetSitePort(m_vActiveSites[0], iTPort(m_oBypassGlobalParam.m_nIntValue));
            m_oException.m_zSet(__FILE__,__LINE__,IT_BYPASS,
                                iCString::toString("Test Instance \"%s\" Verify is Bypassed to port %d....",
                                                   m_sInstanceName.c_str(),m_oBypassGlobalParam.m_nIntValue));
            return m_tExceptionHandler(m_oException);
        }
    }

    //continue verifying the parameters defined locally in this class
    ////Begin_test_template_parameter_verification

    ////End_test_template_parameter_verification

    //HSD 1376 Move iVal post verify user function to Gen core
    /******************************************************************************
    //HSD1225. An implementation for iVal validation purpose
    //Allow post instance execution for capturing FAIL condition of the iC_tVerify
    *******************************************************************************/
    if (nErrorFlag)
    {
        //Updated HSD 1376 Moved iVal code to gen_core - removed repetition in test classes
        m_sErrorMsg = iCString::toString("iCGENInitTest::iC_tVerify of instance \"%s\" FAILED!",
            m_sInstanceName.c_str());
        m_zPrint(IT_ERROR_MSG,"iC_tVerify",m_sErrorMsg, __FILE__, __LINE__);
        return m_tValidateVerifyResult(nErrorFlag);
    }
    else
    {
        m_tPrintVerifyStatus();
        return (IT_PASS);
    }
}

iTStatus iCGENFrameTest::iC_tExecute()
{
    m_sErrorMsg = "";
    iTStatus tRetVal = IT_FAIL;
    m_oException.m_zReset();   //Always reset exception object at the start of method.

    try
    {
        if (m_tDebugMode != IT_DEBUG_DISABLED)
        {
            m_sErrorMsg = iCString::toString("iCGENFrameTest::iC_tExecute of instance \"%s\" is running\n",
                                             m_sInstanceName.c_str());
            m_pCoreIfcParent->iC_zPrint(m_sErrorMsg);
        }

        //Clear the Alternate Instance Name;
        m_sAltInstanceName = "";

        // Call Pre Execute Routine from the base class
        tRetVal = m_tPreExecuteRoutine();
        if (IT_BYPASS == tRetVal)
        { //Instance is meant to be bypassed.
            m_oException.m_zSet(__FILE__,__LINE__,IT_BYPASS,
                                iCString::toString("Test Instance \"%s\" Execution is Bypassed to port %d....",
                                                   m_sInstanceName.c_str(),m_oBypassGlobalParam.m_nIntValue));
            throw m_oException;
        }
        else if (IT_PASS != tRetVal)
        {
            m_oException.m_zSet(__FILE__,__LINE__,tRetVal,"m_tPreExecuteRoutine returned a fail...");
            throw m_oException;
        }
        ////Beginning of Test Class specific execute details

        ////End of Test Class specific execute details

        // Call Post Execute Routine from the base class
        tRetVal = m_tPostExecuteRoutine();
        if (IT_PASS != tRetVal)
        {
            m_oException.m_zSet(__FILE__,__LINE__,tRetVal,"m_tPostExecuteRoutine returned a fail...");
            throw m_oException;
        }
        m_oException.m_zSet(__FILE__,__LINE__,IT_PASS,
                            iCString::toString("Test Instance \"%s\" Execution is Passed...",m_sInstanceName.c_str()));
        throw m_oException;
    }
    catch (iCException& oException)
    {
        switch (oException.m_tStatus)
        {
            case IT_ALARM:
            {
                //This is needed to override the port information from previous setting
                for (int i = 0; i< (int) m_vActiveSites.size(); i++)
                {
                    ms_pCorTeXGlobal->m_zSetSitePort(m_vActiveSites[i],IT_STD_ALARM_PORT);
                }
                m_zPrint(IT_ERROR_MSG,"iC_tExecute",oException);
                ms_pCorTeXGlobal->m_zGetAlarmMsgs(m_sErrorMsg);
                m_zPrint(IT_ERROR_MSG,"iC_tExecute",m_sErrorMsg,__FILE__,__LINE__);
                //Reset Alarm Data including clamp,spike,other flags.
                ms_pCorTeXGlobal->iC_zClearAlarmData();
                break;
            }
            case IT_BYPASS:
            {
                if (m_tDebugMode != IT_DEBUG_DISABLED)
                {
                    m_zPrintLite(IT_INFO_MSG,oException.m_sErrorMsg);
                }
                m_tPrintExecuteStatus();
                break;
            }
            case IT_PASS:
            {
                m_tPrintExecuteStatus();
                break;
            }
            default:
            {
                m_zPrint(IT_ERROR_MSG,"iC_tExecute",oException);
                break;
            }
        }
        m_tTestClassReturn();
        return oException.m_tStatus;
    }
}



extern "C"
{
    void GEN_FRAME_EXPORT gCreateGENFrameTest(iCGENCoreIfc* &pCoreIfcTest)
    {
        iCGENFrameTest* pTmp = NULL;
        pTmp = new (iCGENFrameTest);  //This is dynamic cast down to the Core Interface of test class object
        pCoreIfcTest = dynamic_cast<iCGENCoreIfc*>(pTmp);
    }
}


/***********************************************************
  NOTE: Please do not modify Revision History Directly via your editor.
  Please only modify via CVS tools.

  Revision History
  $Log: GEN_frame_tt.cpp,v $
  Revision 2.6.8.1.4.1.24.3  2007/04/10 17:22:11  acasti3
  HSD_ID:1371

  CHANGE_DESCRIPTION:changed tabs to spaces

  REG_TEST:

  Revision 2.6.8.1.4.1.24.2  2007/03/19 23:32:57  amathur1
  HSD_ID:3349

  CHANGE_DESCRIPTION:
  Updating the GEN test class generation script to allign with changes done for HSD1376: Moved validation code to GEN core.

  REG_TEST:

  Revision 2.6.8.1.4.1.24.1  2007/03/01 16:15:00  csromei
  HSD_ID:3642

  CHANGE_DESCRIPTION:Added bypass code to frame file to correctly bypass verify as per HSD 1371 for any new templates built

  REG_TEST:

  Revision 2.6.8.1.4.1  2006/04/03 21:58:56  rflore2
  HSD_ID:1413

  CHANGE_DESCRIPTION:
  Declare i iterator used in exception handling

  REG_TEST:

  Revision 2.6.8.1  2005/11/24 04:33:11  gar\hchong
  HSD_ID:1225

  CHANGE_DESCRIPTION:support Post-instance implementation at the end of the iC_tVerify function. This will enable iVal validation for better result monitoring


  REG_TEST:test-case created in iVal

  Revision 2.6  2005/06/23 18:25:10  amr\rflore2
  HSD_ID:N/A

  CHANGE_DESCRIPTION:
  Merge 3.3.0 Changes

  REG_TEST:

  Revision 2.5.4.1  2005/06/09 21:01:10  pjkransd
  GE_ID: OVERRIDED by dhchen - NO BUGID
   CHANGE_DESCRIPTION:(Type the desc on the next line)
   Bug fix
   REG
  Revision 2.5  2005/03/07 23:00:05  rflore2
  HSD_ID: N/A

  CHANGE_DESCRIPTION:
  Merge 3.1.0 Branch

  REG_TEST:

  Revision 2.4.4.2  2005/02/20 15:41:53  svpathy
  HSD_ID: 265
   CHANGE_DESCRIPTION:
   Updated the try/catch block in iC_tExecute of all test classes to move the m_tTestClassReturn() as the last statement instead of the first statement (which wipes out m_vActiveSites and prevents proper exit port from being assigned for ALARM exceptions).

   REG_TEST:

  Revision 2.4.4.1  2005/02/18 22:37:23  svpathy
  HSD_ID: 263
   CHANGE_DESCRIPTION:
   Updated GEN_frame_tt.cpp to include IT_ALARM case in the catch section
   REG_TEST:

  Revision 2.4  2004/09/02 22:03:47  dhchen
  CHANGE_ID: OVERRIDED by dhchen - NO BUGID
   CHANGE_DESCRIPTION:(Type the desc on the next line)
   Bug fix
   REG_TEST:(Type on the next line)

  Revision 2.3  2004/09/02 21:16:23  dhchen
  CHANGE_ID: TES00001682
   CHANGE_DESCRIPTION:
    New release

   REG_TEST:


 ***********************************************************/
