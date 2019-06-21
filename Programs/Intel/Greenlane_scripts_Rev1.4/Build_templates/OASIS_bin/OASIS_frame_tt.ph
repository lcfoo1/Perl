Version 1.0;
#OASIS PRE_HEADER FILE FOR iCFrame Test Class.
# All CorTeX Test Classes would need to import from this common ph file
Import OASIS_tt.ph;
TestClass = iCFrameTest; # The name of this test class

# CorTeX standards require these to be set directly in C++ section of this file
# rather than here. But OCC requires this so that test class 
# parameters defined in OASIS_tt.ph will be visible to this class
# Note:: CorTeX standards require public bases to be explicitly declared in the C++ section
PublicBases = iCOASISCore;

#iCFrameTest has the following parameters on top of what is inherited from OASIS_tt.ph
Parameters
{



}


#Begin of C++ Section
#
#
# The section below is part of the Pre-Header which is an escape
# into C++ code.
#
# Everything in this section will be reproduced verbatim in the 
# generated header file, except for symbols starting with a $.
#
# Note that no comments beginning with the ÅEÅEcharacter are supported
# within the following section.
#
CPlusPlusBegin

#ifndef $ClassName_H
#define $ClassName_H

//Begin CorTeX Specific Includes
#include <cortex.h>

//OASIS specific CorTeX defines and typedefs
#include "OASIS_cortex_defs.h"  

//OASIS Implementation of iCGENCoreIfc Interface Class
#include <OASIS_core.h>        


$ImportDeclarations

namespace OASIS
{
    
    /** Forward declaration of OASIS Classes */

    class $ClassName :public iCOASISCore   //PublicBases
    {
    public:

        //Constructor
        $ClassName();
        
        //Destructor
        virtual ~$ClassName();

        //All Test Class Param Set Functions are required to be "virtual void" 
        //CorTeX Requires Explicit Declaration of Test Class Param Function
        //Note:: ParamFunctionDeclaration OCC Auto Generation Keyword  
        //is not allowed under CorTex usage.
        ////Begin_CorTeX_Test_Class_Param_Set_Function_Declaration
        ////End_CorTeX_Test_Class_Param_Set_Function_Declaration


        //Virtual Functions which are inherited from Test which in turn is inherited from iTest and other interface classes of OASIS 
        //Provides the critical "execute" and "postInit" methods which are nherited from iTest through  Test
        virtual bool execute();
        virtual bool postInit();
        //Init() is called as a post constructor function for handling one type initialization of test class objects
        //this is needed for Datalog Type creation.
        virtual void init();
        virtual IDatalogType *getDatalogType() const;
        //Provides Set Functionality for the proxy (GUI enabler)
        virtual OFCStatus setValues( const OFCArray<OFCString>&, const bool);
        //Provides Get Functionality for the proxy (GUI enabler)
        virtual void getValues( OFCArray<OFCString>& );

        //Override functions to enable Test Instance Editor like GUI tools to use proper field types and data types.
        virtual bool getAllowedValues(const OFCString& param, const OFCString& field, OFCArray<OFCString>& values) const;
    	virtual bool getGuiType(const OFCString& param, const OFCString& field, OFCString& guiType) const;
    	virtual bool getParamType(const OFCString& param, const OFCString& field, OFCString& paramType) const;
    	virtual bool getParamValue(const OFCString& param, const OFCString& field, OFCString& guiType) const;

        //XML Related Functions
        virtual void addParamDescriptions(XMLParamsDescriptor& pd) const;
        virtual OFCString getXMLDescription() const;

        //OTPL set defaults function
        virtual void setDefaults();
	    virtual OFCString getType(const OFCString& paramName, const OFCString& fieldName) const;
        //End of Virtual functions from Test.
        
        //virtual functions from OASISCore
        //Local methods for Set and Get
        virtual iTStatus m_tGenericSet(const iCString& sParamName, const iCString& sValue);
        //Removed as it is not used anywhere
        //virtual iTStatus m_tGenericSet(const iCGENTpParam& oParamValue);
        virtual iTStatus m_tGenericGet(const iCString& sParamName, iCString& sValue);
        virtual iTStatus m_tGenericGet(iCGENTpParam& oParamValue);
        
        virtual iTStatus m_tGetInstanceParam(iCGENTpParam& oParamValue);
        virtual iTStatus m_tSetInstanceParam(const iCGENTpParam& oParamValue);
        
        virtual void m_zPopulatePListMap();
        virtual void m_zPopulateTCMap();
        
        //End of Local methods for Set and Get
        //End of Virtual functions from OASISCore
        
        //Local Helper Functions
        iTStatus m_tCreateTIObject();  //Creates Tester Independent (GEN) object if needed.
        //End of Local Helper Functions
        
    private:
        //Datalog Type unique to the test class
        static IDatalogType *m_spTestClassType;        

        //Needed for Auto XML for variables of 0-N or 1-N cardinality.
        typedef std::vector<double> DoubleArray;
        typedef std::vector<int> IntegerArray;
        typedef std::vector<OFCString> StringArray;
        static OFCString toXML(const DoubleArray& a);
        static OFCString toXML(const IntegerArray& a);
        static OFCString toXML(const StringArray& a);

    protected:
        //All should be declared as Protected members
        //This allows inheriting classes to access the member variables
        //CorTeX requires all test class parameters to be of the type iCGENTpParam
        //The only types we would be using in the ph file are String, Integer (or Enum), Double
        //
        //Note:: ParamArrayTypes & ParamAttributes OCC Auto Generation Keywords is not allowed under CorTex usage.
        //CorTeX build_OASIS_cpp_and_ph script handles creating the appropriate member variables for 
        //each test class parameter.  For each test class parameter attribute declared in the .ph file, there is a 
        //shadow member variable which is always of the type  iCGENTpParam. TSS member variables are of
        //the types String, Integer or Double, whereas CorTeX shadow attributes are always of the type iCGENTpParam
        ////Begin_Attribute_declaration_for_all_the_test_class_parameters
        ////End_Attribute_declaration_for_all_the_test_class_parameters

    };
} // End namespace OASIS

// Following is the set of inline functions (for XML related funtions) which are auto implemented
// by OCC translation.
$ParamFunctionImplementations

#endif $ClassName_H
CPlusPlusEnd

#***********************************************************
# NOTE: Please do not modify Revision History Directly via your editor.
# Please only modify via CVS tools.
#
# Revision History
# $Log: OASIS_frame_tt.ph,v $
# Revision 2.3.16.1.18.3  2007/01/08 20:11:48  amr\kpalli
# HSD_ID:3572
#
# CHANGE_DESCRIPTION: update the setValues signature for TSS2.05
#
# REG_TEST:
#
# Revision 2.3.16.1.18.2  2006/10/12 17:36:46  amathur1
# HSD_ID:3238
#
# CHANGE_DESCRIPTION:
# Removing Preprocessor _PRE_TSS201A_ code from cvs since building 4.8 only on TSS204 onwards TSS
#
# REG_TEST:
#
# Revision 2.3.16.1.18.1  2006/10/12 17:11:16  amr\kpalli
# HSD_ID:3238
#
# CHANGE_DESCRIPTION: DatalogType changes for TSS2.04_beta
#
# REG_TEST:
#
# Revision 2.3.16.1  2005/12/13 19:58:20  mmohan3
# HSD_ID:1042
#
# CHANGE_DESCRIPTION:TSS 201B support
#
# REG_TEST:
#
# Revision 2.3  2005/01/18 23:34:51  rflore2
# Merge 3.0.0 branch in main trunk
#
# Revision 2.1.4.1  2005/01/03 05:12:27  svpathy
# CHANGE_ID: OVERRIDED by svpathy - NO BUGID
#  CHANGE_DESCRIPTION:(Type the desc on the next line)
#  Update to the scripts to enable autoXML feature from TSS
#  REG_TEST:(Type on the next line)
#
# Revision 2.1  2004/09/02 22:40:28  dhchen
# CHANGE_ID: TES00001682
#  CHANGE_DESCRIPTION:
#   New release
#  REG_TEST:
#
#***********************************************************
