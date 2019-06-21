#ifndef __GEN_FRAME_TT_H__
#define __GEN_FRAME_TT_H__

#include <GEN_core.h>
#include <GEN_global.h>

//This #define sequence is needed to handle the exporting
//of classes from a windows DLL
#ifdef WIN32
#pragma warning( disable : 4251 4275 )
#ifdef __GEN_FRAME_TEST__
#define GEN_FRAME_EXPORT __declspec(dllexport)
#else
#define GEN_FRAME_EXPORT __declspec(dllimport)
#endif
#else
#define GEN_FRAME_EXPORT
#endif

class  GEN_FRAME_EXPORT iCGENFrameTest  : public iCGENCore
{
public:
    iCGENFrameTest ();
    virtual ~iCGENFrameTest();

    void m_zCleanUp();
    void m_zLocalCleanUp();


    //Interface methods from iCGENCoreIfc though iCGENCore is inherited
    //they are overridden here to ensure iCGENFrameTest specific implementations are used
    virtual iTStatus iC_tPGContinueOnFullCheck(const iCGENMultiSiteRslt& oExecRslt,
                                               const iCGENMultiSiteCaptureData* pCaptureData);
    virtual iTStatus iC_tVerify();
    virtual iTStatus iC_tExecute();
    virtual iTStatus iC_tSetTpParam(const iCGENTpParam& oTpParam);
    virtual iTStatus iC_tGetTpParam(iCGENTpParam& oTpParam);
    //end of iCGENCoreIfc methods


    ////Begin_Test_Class_Specific_Enums

    ////End_Test_Class_Specific_Enums


    ////Begin_Test_Class_Specific_Enum_Functions

    ////End_Test_Class_Specific_Enum_Functions


    //Other Public Methods


protected:

    ////Begin_Test_Class_Interface_Attributes

    ////End_Test_Class_Interface_Attributes


    //Other Private Attributes if any


    //Other Private Methods if any
};

////Begin_Inline_Enum_Functions

////End_Inline_Enum_Functions


#endif //__GEN_FRAME_TT_H__

/***********************************************************
  NOTE: Please do not modify Revision History Directly via your editor.
  Please only modify via CVS tools.

  Revision History
  $Log: GEN_frame_tt.h,v $
  Revision 2.3  2004/09/02 21:16:25  dhchen
  CHANGE_ID: TES00001682
   CHANGE_DESCRIPTION:
    New release    REG_TEST:


 ***********************************************************/
