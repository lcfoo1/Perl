/*
 *
 *       *************************************************************
 *       **                                                         **
 *       **        Copyright (C) 2003, Intel Corporation            **
 *       **              PROPRIETARY AND TRADE SECRET               **
 *       **      Published only in a limited, copyright sense.      **
 *       **                                                         **
 *       *************************************************************
 *
 */

#include "OASIS_frame_tt.h"
#ifndef TIMING_H
#include "OAI/core/Timing.h"
#endif
#ifndef TESTCONDITIONGROUP_H
#include "OAI/core/TestConditionGroup.h"
#endif
#ifndef OASISTESTDLLEXPORTS_H
#include "OAI/OASISTestDLLExports.h"
#endif
#ifndef DATALOGMANAGER_H
#include "OAI/datalog/DatalogManager.h"
#endif
#ifndef IDATALOGTYPE_H
#include "OAI/datalog/IDatalogType.h"
#endif
#ifndef DATALOGVALUES_H
#include "OAI/datalog/DatalogValues.h"
#endif
#ifndef OASISDLLINFO_H
# include "OAI/OASISDLLInfo.h"
#endif //  OASISDLLINFO_H
#include "OAI/core/TimingsBlock.h"

using namespace std;
using namespace OASIS;


#define CLASSNAME _T("iCFrameTest")

//
//Initialize the static datalog type for the test class
//
IDatalogType *iCFrameTest::m_spTestClassType = NULL;

/*
 * Start of iCFrameTest datalog events Definition
 * Please define all relevant datalog events in this section
 */
#define TEST_RESULT         1
#define TEST_RESULT_EVENT   _T("TestResult")
#define DUMP_SIGNAL         2
#define DUMP_SIGNAL_EVENT   _T("DumpSignal")
/// End of iCFrameTest datalog events Definition



/*
 * Start of iCFrameTest datalog field names
 * Please define all relevant datalog events in this section
 */
#define RESULT              _T("Result")
#define SIGNAL_INFO         _T("SignalInfo")
/// End of iCFrameTest datalog field names Definition


////DLL Information Holder

class CFrameDLLInfo : public OASIS::IDLLInfo
{
public:

    /// Verifies of DLL can be used with debug version of OASIS
    virtual bool canUseInDebugEnvironment() const
    {
        return true;
    }
    /// Verifies of DLL can be used with release version of OASIS
    virtual bool canUseInReleaseEnvironment() const
    {
        return true;
    }

    /// Returns list of libraries this DLL depends on.
        virtual void getRequiredLibraries(iCOFCWrapperStringArray_t& dllNames)
    {
                dllNames.push_back(_T("OASIS_cortex_utility.dll"));
                dllNames.push_back(_T("OASIS_gen_code.dll"));
                dllNames.push_back(_T("OASIS_code.dll"));
                dllNames.push_back(_T("xerces-c_2_6.dll"));
    }

} gFrameDLLInfo;




/**
 * @brief Constructor.
 *
 * @remarks
 *      sample code
 */

//Constructor for iCFrameTest
//runs the iCOASISCore constructor first.
//The global pointers for CorTeXGlobal of type iCGENGlobal &
//PlatformGlobal of type iCOASISGlobal are obtained in the core constructor
//

iCFrameTest::iCFrameTest()
             :iCOASISCore()
{

    //set the m_sTestClassName of the base class to this test class name.
    m_sTestClassName = "iCFrameTest";

    Test::m_className = _T(m_sTestClassName.c_str());

    //Force verification after construction
    m_tDirtyBit = IT_DIRTYBIT_TRUE;

    // Determine Debug or Release
    m_sGENDLL = "OASIS_GEN_frame_tt.dll";

    m_sGENCreateFunction = "gCreateGENFrameTest";



    ////Start_of_TestClass_Interface_Params_Constructor_Initialization
    ////End_of_TestClass_Interface_Params_Constructor_Initialization

    ////Start_of_AllTestClassParams_Vector_Population
    ////End_of_AllTestClassParams_Vector_Population

    //Msg Handler Server Object Creation and Proxy GUID assignment
    //has been moved to OASIS_core.cpp
}

/**
 * @brief Destructor
 *
 * @remarks
 *      sample code
 */
iCFrameTest::~iCFrameTest()
{
    if (m_spItuffType)
    {
        m_spItuffType->removeSource(m_sLocalInstanceName.c_str());
    }
    if (m_spRasterType)
    {
        m_spRasterType->removeSource(m_sLocalInstanceName.c_str());
    }
    if (m_spScanfiType)
    {
        m_spScanfiType->removeSource(m_sLocalInstanceName.c_str());
    }
    if (m_spTestClassType)
    {
        m_spTestClassType->removeSource(m_sLocalInstanceName.c_str());

        if (0 == m_spTestClassType->getNumOfSources())
        {   // if all instances of this type were removed, delete the pointer and free the memory
            delete m_spTestClassType;
            m_spTestClassType = NULL;
        }
    }
    //Delete the GEN Object
    iCOASISCore::m_zDeleteTIObject();
}
/**
 * @brief
 *     Retrieves the type the source resides in.
 */
IDatalogType* iCFrameTest::getDatalogType() const
{
    return m_spTestClassType;
}

/**
 * @brief
 *     Initializes the test.
 */
void iCFrameTest::init()
{
  	//hsd#3975; this variable is not used  
	//unsigned i = 0;

    iCString sStr = "";



    iCGENTpParam oTpParam;

    if (m_bInitialized == false)
    {
    //It is very critical that Core Init is run.
    //This is needed for initializing all the datalog types and cortex globals
    iCOASISCore::init();


    //Intialize Test Class Engineering Datalog Types
    if (NULL == m_spTestClassType)
    {
        //Create a new datalog type with a fully qualified string which will uniquely

        m_spTestClassType = ms_pDatalogMgr->getType(_T("com.intel.oai.Testclasses.iCFrameTest"));

        //Register the events     Un Implemented currently
        //m_spTestClassType->addEvent(IC_ITUFF_EVENT, IC_ITUFF_EVENT_ID);
    }



    //Let the instance name be known to the tester independent object
    //Pass the instance name as a parameter
    oTpParam.m_sName = "instance";
    oTpParam.m_tType = IT_STRING;
    oTpParam.m_sStrValue = m_sLocalInstanceName;
    m_pCoreIfcTIObject->iC_tSetTpParam(oTpParam);


    //Let the test class name be known to the tester independent object
    //Pass the test class name as a parameter
    oTpParam.m_sName = "testclass";
    oTpParam.m_tType = IT_STRING;
    oTpParam.m_sStrValue = m_sTestClassName;
    m_pCoreIfcTIObject->iC_tSetTpParam(oTpParam);


    // Production Datalog Type & Source registration
    if (NULL != m_spItuffType)
    {
        //Register Self as a source of ItuffType
        m_spItuffType->addSource(this);
    }
    if (NULL != m_spRasterType)
    {
        //Register Self as a source of RasterType
        m_spRasterType->addSource(this);
    }
    if (NULL != m_spScanfiType)
    {
        //Register Self as a source of ScanfiType
        m_spScanfiType->addSource(this);
    }
    if (NULL != m_spTestClassType)
    {
        //NOTE:: Engineering Datalog Events is currently unimplemented
        //Register Self as a source of TestClassType
        m_spTestClassType->addSource(this);
        }
    }
}

bool iCFrameTest::postInit()
{
    bool bStatus = false;
    iCString sStr;

    bStatus = iCOASISCore::postInit();
    if (false == bStatus)
    {
        if (IT_DEBUG_DISABLED != m_tDebugMode)
        {
            sStr = iCString::toString("Instance \"%s\" iCFrameTest::verify returned an error condition...\n",
                                      m_sLocalInstanceName.c_str());
            m_zPrintLite(IT_ERROR_MSG,sStr);
        }
        ////SetPassFailStatusToFail
        m_zTSSWrapperSetPassFailStatus(ITest::FAIL);
    }
    else
    {
        if (IT_DEBUG_DISABLED != m_tDebugMode)
        {
            sStr = iCString::toString("Instance \"%s\" iCFrameTest::verify passed...\n",
                                      m_sLocalInstanceName.c_str());
            m_zPrintLite(IT_INFO_MSG,sStr);
        }
        ////SetPassFailStatusToPass
        m_zTSSWrapperSetPassFailStatus(ITest::PASS);
    }
    return bStatus;
}


/**
 * execute method for the test class iCFrameTest
 *      Execute a function test.
 *
 * Please add commments on "execute" behaviour and return
 * values in this section.
 *
 *
 */
bool iCFrameTest::execute()
{
    bool bStatus = false;
    iTPort tPort;
    iCString sPortStatus;
    iCString sPortInfo;
    iCString sStr;

    ROUTINE("iCFrameTest::execute()");

    //Note This means that DirtyBit check is executed completely within
    //OASISCore and as a result only the OASISCore postInit is called.
    //if you add anything else to this test class's post Init, then you have to
    //be careful in using the approach outline below.
    bStatus = iCOASISCore::execute();


    //Retrieve the exit port number for the instance
    tPort = ms_pPlatformGlobal->m_tGetSitePort(0);

    if (false == bStatus)
    {
        if (IT_DEBUG_DISABLED != m_tDebugMode)
        {
            sStr = iCString::toString("Instance \"%s\" iCFrameTest::execute returned an error condition...Exiting on Port %d...\n",
                                      m_sLocalInstanceName.c_str(), (int)tPort);
            m_zPrintLite(IT_INFO_MSG,sStr);
        }
        setStatus((int)tPort);
        ////SetPassFailStatusToFail
        m_zTSSWrapperSetPassFailStatus(ITest::FAIL);
        //HSD673
        return true;
    }
    else
    {
        //Check if the instance was bypassed. If so set the status accordingly
        //m_bBypassStatus is a protected member of the OASISCore class.
        //This section will be uncommented only for TSS 1.04, only then there will be
        //a true BYPASS status available.
        if (true == m_bBypassStatus)
        {
            if (IT_DEBUG_DISABLED != m_tDebugMode)
            {
                sStr = iCString::toString("Instance \"%s\" iCFrameTest::execute was bypassed...Exiting on Port %d...\n",
                                            m_sLocalInstanceName.c_str(), (int)tPort);
                m_zPrintLite(IT_INFO_MSG,sStr);
            }
            setStatus((int)tPort);
            ////SetPassFailStatusToOther
            m_zTSSWrapperSetPassFailStatus(ITest::OTHER);
            return true;
        }


        //Else based on the ph file exit port information
        //set the ports and the pass fail status.


        ////Start_of_Test_Class_Specific_Port_and_Status_Setting
        ////End_of_Test_Class_Specific_Port_and_Status_Setting
        if (IT_DEBUG_DISABLED != m_tDebugMode)
        {
            sStr = iCString::toString("Instance \"%s\" exiting on Port %d...\nPort Status \"%s\" Port Info:- \"%s\"\n",
                                      m_sLocalInstanceName.c_str(),(int)tPort,sPortStatus.c_str(),sPortInfo.c_str());
            m_zPrintLite(IT_INFO_MSG,sStr);
        }
        setStatus((int)tPort);
        return true;
    }
}



////Start_of_Test_Class_Specific_Instance_Parameter_Set_Functions
////End_of_Test_Class_Specific_Instance_Parameter_Set_Functions


////Start_of_PopulatePListMap
////End_of_PopulatePListMap

////Start_of_PopulateTCMap
////End_of_PopulateTCMap


bool iCFrameTest::getAllowedValues(const OFCString& sParam, const OFCString& sField, OFCArray<OFCString>& vListItems) const
{
    bool bStatus = false;
    iCOASISCore* pBasePtr = NULL;
    vListItems.clear();
    bStatus = iCOASISCore::getAllowedValues(sParam,sField,vListItems);
    if (false == bStatus)
    {
        //Needed to workaround the const "this"
        pBasePtr = (iCOASISCore*)this;
        ////Start_of_Test_Class_Specific_Instance_Parameter_Allowed_Values
        ////End_of_Test_Class_Specific_Instance_Parameter_Allowed_Values
        return false;
    }
    else
    {
        return true;
    }
}

bool iCFrameTest::getGuiType(const OFCString& sParam, const OFCString& sField, OFCString& sGuiType) const
{
    bool bStatus = false;
    sGuiType = "";
    bStatus = iCOASISCore::getGuiType(sParam,sField,sGuiType);
    if (false == bStatus)
    {
        ////Start_of_Test_Class_Specific_Instance_Parameter_GUI_Type
        ////End_of_Test_Class_Specific_Instance_Parameter_GUI_Type
        return false;
    }
    else
    {
        return true;
    }
}

bool iCFrameTest::getParamType(const OFCString& sParam, const OFCString& sField, OFCString& sParamType) const
{
    bool bStatus = false;
    sParamType = "";
    bStatus = iCOASISCore::getParamType(sParam,sField,sParamType);
    if (false == bStatus)
    {
        ////Start_of_Test_Class_Specific_Instance_Parameter_Param_Type
        ////End_of_Test_Class_Specific_Instance_Parameter_Param_Type
        return false;
    }
    else
    {
        return true;
    }
}

bool iCFrameTest::getParamValue(const OFCString& sParam, const OFCString& sField, OFCString& sParamValue) const
{
    bool bStatus = false;
    sParamValue = "";
    bStatus = iCOASISCore::getParamValue(sParam,sField,sParamValue);
    if (false == bStatus)
    {
        ////Start_of_Test_Class_Specific_Instance_Parameter_Param_Value
        ////End_of_Test_Class_Specific_Instance_Parameter_Param_Value
        return false;
    }
    else
    {
        return true;
    }
}

//Generic Set which takes both the parameter name and value  as a string
//Converts the string value into appropriate data type and then calls the particular set method
iTStatus iCFrameTest::m_tGenericSet(const iCString& sParamName, const iCString& sValue)
{
    //hsd#3975; this variable is not used
	//int nIntValue = 0;
    //double dDblValue = 0.0;
	//bool bFlag = false;
    iTStatus tStatus = IT_FAIL;
    

    tStatus = iCOASISCore::m_tGenericSet(sParamName, sValue);

    if (IT_FAIL == tStatus)
    {//if the Set failed on the core then check locally

        ////Start_of_Two_Param_Test_Class_Specific_Generic_Set
        ////End_of_Two_Param_Test_Class_Specific_Generic_Set
        m_tDirtyBit = IT_DIRTYBIT_TRUE;
        return IT_PASS;
    }
    else
    {
        m_tDirtyBit = IT_DIRTYBIT_TRUE;
        return IT_PASS;
    }
}

//Generic Get which takes both the parameter name and value  as a string
//Converts the local member object into string value and returns it in the output parameter sValue
iTStatus iCFrameTest::m_tGenericGet(const iCString& sParamName, iCString& sValue)
{
    iTStatus tStatus = IT_FAIL;

    sValue = "";

    tStatus = iCOASISCore::m_tGenericGet(sParamName, sValue);

    if (IT_FAIL == tStatus)
    {//if the Get failed on the core then check locally
        ////Start_of_Two_Param_Test_Class_Specific_Generic_Get
        ////End_of_Two_Param_Test_Class_Specific_Generic_Get
        return IT_PASS;
    }
    else
    {
        return IT_PASS;
    }

}

//Overload Generic Get which takes a single object of iCGENTpParam which has the parameter name as well.
//copies the local member object to the output param oParamValue
iTStatus iCFrameTest::m_tGenericGet(iCGENTpParam& oParamValue)
{
    iTStatus tStatus = IT_FAIL;
    OFCString sParamName = oParamValue.m_sName.c_str();

    tStatus = iCOASISCore::m_tGenericGet(oParamValue);
    if (IT_FAIL == tStatus)
    {//if the Get failed on the core then check locally
        ////Start_of_One_Param_Test_Class_Specific_Generic_Get
        ////End_of_One_Param_Test_Class_Specific_Generic_Get
        return IT_PASS;
    }
    else
    {
        return IT_PASS;
    }
}

//Implement the pure virtual m_tGetInstanceParam
//copies the local member object to the output param oParamValue
iTStatus iCFrameTest::m_tGetInstanceParam(iCGENTpParam& oParamValue)
{
    iTStatus tStatus = IT_FAIL;
    tStatus = m_tGenericGet(oParamValue);
    return tStatus;
}


//Implement the pure virtual m_tSetInstanceParam
//copies the oParamValue to the local member object
iTStatus iCFrameTest::m_tSetInstanceParam(const iCGENTpParam& oParamValue)
{
    iTStatus tStatus = IT_FAIL;
    if (IT_INTEGER == oParamValue.m_tType)
    {
        tStatus = m_tGenericSet(oParamValue.m_sName,iCString::toString(oParamValue.m_nIntValue));
    }
    else if (IT_DOUBLE == oParamValue.m_tType)
    {
        tStatus = m_tGenericSet(oParamValue.m_sName,iCString::toString(oParamValue.m_dDblValue));
    }
    else
    {
        tStatus = m_tGenericSet(oParamValue.m_sName,oParamValue.m_sStrValue);
    }
    return tStatus;
}



/**
 * @brief
 *      set values to an iCFrameTest
 * @remarks
 *
 */
OFCStatus iCFrameTest::setValues( const OFCArray<OFCString>& values, const bool)
{
    ROUTINE(__FUNCTION__);
    iCString sParamName;
    iCString sParamValue;
    iTStatus tStatus;
    int nError = 0;
    int nNumValues = 0;
    for (size_t pindex=0; pindex < values.size(); pindex++)
    {
        TestParamParser param( values[pindex] );
        sParamName = (param.getParameter()).c_str();
        param.parseValArray();
        nNumValues = (int) param.size();

        if (nNumValues > 0)
        {
            for (size_t vindex=0; (int) vindex < nNumValues; vindex++)
            {
                sParamValue = (param.getValue(vindex)).c_str();
                tStatus = m_tGenericSet(sParamName,sParamValue);
                if (IT_FAIL == tStatus)
                {
                    nError++;
                }
            }
        }
        else
        {
            sParamValue = "";
            tStatus = m_tGenericSet(sParamName,sParamValue);
            if (IT_FAIL == tStatus)
            {
                nError++;
            }
        }
    }
    if (nError)
    {
        OFCStatus err;
        SET_ERROR(err,ERR_TESTCLASS_USERERR);
        err.addParam(_T("Msg"),getName()+_T(":")+
                     _T("Can't find at least one of the parameter "));
        return err;
    }
    else
    {
        return OASIS::OFCStatus();
    }
}

/**
 * @brief
 *      get values from iCFrameTest
 * @remarks
 */
void iCFrameTest::getValues( OFCArray<OFCString>& values )
{
    iCString sStr;
    iCString sParam;
    iCString sValue;
    TestParamPackager *pPackager = NULL;


    //First Call the Core getValues to get all the common parameters
    iCOASISCore::getValues(values);

    //Then get all the parameters defined locally in this test class
    ////Start_of_Test_Class_Specific_getValues
    ////End_of_Test_Class_Specific_getValues
}


//
//
// I/F for remote communication.
// Has been moved to OASIS_core.cpp
//
//





//
//
// I/F for TestPlanServer integration.
//
//

#if defined (_MSC_VER) &&  _MSC_VER >= 1200
# pragma warning (push)
# pragma warning (disable : 4190) // 'oasisCreateTest' has C-linkage specified,
// but returns UDT 'OASIS::OFCStatus' which
// is incompatible with C. This is fine provided
// that we call the function from C++ code
#endif // defined (_MSC_VER) &&  _MSC_VER >= 1200

extern "C"
{
    //
    // @brief
    //      creation of Test instance
    // @param strTestName[in]:
    //      Name of Test class
    // @param ppTest[out]:
    //      pointer to Test instance
    // @return
    //      status
    // @remarks
    //      TPS loads the DLL created from this code and searches this function.
    //      This function creates iCFrameTest instance and returns as
    //      ITest pointer. ITest is the I/F class which TPS knows about.
    //
    __declspec(dllexport) OASIS::OFCStatus
    OASIS_TEST_DLL_CREATE_TEST(const OASIS::OFCString& strTestName, OASIS::ITest **ppTest)
    {
        try
        {
            ROUTINE("OASIS_TEST_DLL_CREATE_TEST(iCFrameTest)");

            // reset output parameter
            *ppTest = NULL;
            OASIS::ITest *pTest = NULL;

            // do actual initialization
            if ( strTestName == _T("iCFrameTest") )
            {
                pTest = new iCFrameTest;
            }
            // set the output parameter
            *ppTest = pTest;
        }
        catch (OFCException& e)
        {
            return e.getStatus();
        }
        return OASIS::OFCStatus();
    }

    //
    // @brief
    //      Tell TPS which test is created from this DLL
    // @param vecTests[out]:
    //      Name of supported Test class
    // @return
    //      status
    //
    __declspec(dllexport) OASIS::OFCStatus
    OASIS_TEST_DLL_GET_TEST_NAMES(iCOFCWrapperStringArray_t& vecTests)
    {
        // clear vector just in case
        vecTests.clear();
        // name must match to test template name
        // specified in OTPL.
        vecTests.push_back(_T("iCFrameTest"));
        return OASIS::OFCStatus();
    }


    __declspec(dllexport) void
    OASIS_GET_DLL_INFO_METHOD(OASIS::IDLLInfo **ppDLLInfo)
    {
        try
        {
            *ppDLLInfo = &gFrameDLLInfo;
        }
        catch (...)
        {

        }
    }

} // end of extern "C"

#if defined (_MSC_VER) &&  _MSC_VER >= 1200
# pragma warning (pop)
#endif // (_MSC_VER) &&  _MSC_VER >= 1200



/*********************************************************
  NOTE: Please do not modify Revision History Directly via your editor.
  Please only modify via CVS tools.

  Revision History
  $Log: OASIS_frame_tt.cpp,v $
  Revision 2.8.2.1.6.3.2.1.12.3.2.1.2.1  2007/05/17 23:54:23  zrouf
  HSD_ID:3975

  CHANGE_DESCRIPTION:commented out some unused variable decalration

  REG_TEST:

  Revision 2.8.2.1.6.3.2.1.12.3.2.2  2007/05/17 23:49:46  zrouf
  HSD_ID:3975

  CHANGE_DESCRIPTION:commented out some unused variable decalration

  REG_TEST:

  Revision 2.8.2.1.6.3.2.1.12.3.2.1  2007/02/12 17:13:07  dvsingh
  HSD_ID:3621

  CHANGE_DESCRIPTION: The init() function in the framework file was modified with the following new lines

     if (m_bInitialized == false)
     {


     }

  This is added so that the modular test programs work properly when the init() function is called multiple times from different test plans


  REG_TEST: none

  Revision 2.8.2.1.6.3.2.1.12.3  2007/01/08 20:11:48  amr\kpalli
  HSD_ID:3572

  CHANGE_DESCRIPTION: update the setValues signature for TSS2.05

  REG_TEST:

  Revision 2.8.2.1.6.3.2.1.12.2  2006/10/12 17:38:52  amathur1
  HSD_ID:3238

  CHANGE_DESCRIPTION:
  Removing Preprocessor _PRE_TSS201A_ code from cvs since building 4.8 only on TSS204 onwards TSS

  REG_TEST:

  Revision 2.8.2.1.6.3.2.1.12.1  2006/10/12 17:11:16  amr\kpalli
  HSD_ID:3238

  CHANGE_DESCRIPTION: DatalogType changes for TSS2.04_beta

  REG_TEST:

  Revision 2.8.2.1.6.3.2.1  2006/04/05 23:46:39  mmohan3
  HSD_ID:1948

  CHANGE_DESCRIPTION:Update to clean up _D.dll convention no longer applicable in 4.X branch

  REG_TEST:

  Revision 2.8.2.1.6.3  2006/02/02 18:06:48  rflore2
  HSD_ID:1715

  CHANGE_DESCRIPTION:
  Changed references to xerces-c release libraries on frame files.
  Populate lib_debug with xerces-c release libraries and remove distribution of debug libraries on builds

  REG_TEST:

  Revision 2.8.2.1.6.2  2006/01/06 00:46:37  PJKRANSD
  HSD_ID:1517

  CHANGE_DESCRIPTION: Fixed test class destructor to delete the static memory pointer and free memory if all instances have been removed

  REG_TEST:

  Revision 2.8.2.1.6.1  2005/12/13 19:57:25  mmohan3
  HSD_ID:1048

  CHANGE_DESCRIPTION:TSS 201B update

  REG_TEST:

  Revision 2.8.2.1  2005/08/26 00:59:49  svpathy
  ID: N/A

  CHANGE_DESCRIPTION:
  Merge 3.3.0 branch

  REG_TEST:
  @
  text
  @d336 4
  a339 1
          return false;
  d751 8
  @


  2.6
  log
  @HSD_ID: N/A

  CHANGE_DESCRIPTION:
  Merge 3.3.0 branch

  REG_TEST:
  @
  text
  @@


  2.6.2.1
  log
  @HSD_ID: ?

  CHANGE_DESCRIPTION:
  Updated files to work with 1.0.5A

  REG_TEST:
  n/a
  @
  text
  @d91 1
  a91 1
      virtual void getRequiredLibraries(OASIS::OFCStringArray_t& dllNames)
  d165 1
  a165 1
          m_spItuffType->removeSource(m_sLocalInstanceName.c_str())umber = 0;
      topo_mapper_func = "iAPP_userfunc!RRLTopoFuncForPBIST";
      lya_cellselect_func = "iAPP_userfunc!RRLLYACellSelectFunc";
      capture_limit = 34000;
      max_lya_count = 34000;
  }


  Test iCRRLTest RRL_PBIST_UNC_BACKSLASH
  {
      debug_mode = "VERBOSE";
      patlist = "PBIST_CTV_Plist";
      timings = "iAppTimings50MHz";
      level  = "iAppLevelMin";
      raster_setup = "RRL.cfg!UL1";
      rrl_mode  = "RASTER_ONLY";
      rrl_access  = "PBIST_TRIGGER_CAPTURE";
      eng_destinations = "STDIO_ONLY";
      eng_outfile = "\\\\azea1pub04\\temp\\abc.txt";
      base_number = 0;
      topo_mapper_func = "iAPP_userfunc!RRLTopoFuncForPBIST";
      lya_cellselect_func = "iAPP_userfunc!RRLLYACellSelectFunc";
      capture_limit = 34000;
      max_lya_count = 34000;
  }

  Revision 2.8  2005/06/23 18:25:15  amr\rflore2
  HSD_ID: N/A

  CHANGE_DESCRIPTION:
  Merge 3.3.0 branch

  REG_TEST:

  Revision 2.7  2005/06/03 00:35:56  rflore2
  HSD_ID: N/A

  CHANGE_DESCRIPTION:
  Merge 3.3.0 branch

  REG_TEST:

  Revision 2.5.6.1  2005/05/23 17:49:44  rflore2
  HSD_ID: 473

  CHANGE_DESCRIPTION:
  Load xercesc XML dll along with cortex_utility.dll

  REG_TEST:

  Revision 2.5  2005/01/18 23:34:51  rflore2
  Merge 3.0.0 branch in main trunk

  Revision 2.3.4.1  2005/01/03 05:12:14  svpathy
  CHANGE_ID: OVERRIDED by svpathy - NO BUGID
   CHANGE_DESCRIPTION:(Type the desc on the next line)
   Update to the scripts to enable autoXML feature from TSS
   REG_TEST:(Type on the next line)

  Revision 2.3  2004/11/08 17:59:18  svpathy
  CHANGE_ID: OVERRIDED by svpathy - NO BUGID
   CHANGE_DESCRIPTION:(Type the desc on the next line)
   Updated frame tt.cpp to use new handles for constructor initiliazation for test template interface parameters
   updated the port handling information display in execute()
   REG_TEST:(Type on the next line)

  Revision 2.2  2004/09/07 21:12:30  dhchen
  CHANGE_ID: OVERRIDED by dhchen - NO BUGID
   CHANGE_DESCRIPTION:(Type the desc on the next line)
   DLL load and unload update - Sundar
   REG_TEST:(Type on the next line)

  Revision 2.1  2004/09/02 22:40:26  dhchen
  CHANGE_ID: TES00001682
   CHANGE_DESCRIPTION:
    New release

   REG_TEST:

**********************************************************/
