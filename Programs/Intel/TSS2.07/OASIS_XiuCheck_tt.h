

#ifndef iCXiuCheckTest_H
#define iCXiuCheckTest_H

//Begin CorTeX Specific Includes
#include <cortex.h>

//OASIS specific CorTeX defines and typedefs
#include "OASIS_cortex_defs.h"  

//OASIS Implementation of iCGENCoreIfc Interface Class
#include <OASIS_core.h>        


#include "OASIS_tt_ph.h"
#include "OAI/core/XMLParamsDescriptor.h"
#include "OAI/OFC/OFCStringUtils.h"


namespace OASIS
{
    
    /** Forward declaration of OASIS Classes */

    class iCXiuCheckTest :public iCOASISCore   //PublicBases
    {
    public:

        //Constructor
        iCXiuCheckTest();
        
        //Destructor
        virtual ~iCXiuCheckTest();

        //All Test Class Param Set Functions are required to be "virtual void" 
        //CorTeX Requires Explicit Declaration of Test Class Param Function
        //Note:: ParamFunctionDeclaration OCC Auto Generation Keyword  
        //is not allowed under CorTex usage.
        ////Begin_CorTeX_Test_Class_Param_Set_Function_Declaration
        virtual void m_zSetBypassXiuTestParam(const OFCString& x);
        virtual void m_zSetXiuCalCheckParam(const OFCString& x);
        virtual void m_zSetXiuValidNameParam(const OFCString& x);
        virtual void m_zSetXiuCalPinGroupsParam(const OFCString& x);
        virtual void m_zSetXiuIgnoreChannelsParam(const OFCString& x);
        virtual void m_zSetLevelParam(const OFCString& x);
        virtual void m_zSetVccPindefParam(const OFCString& x);
        virtual void m_zSetVccForceVoltageParam(const OFCString& x);
        virtual void m_zSetVccLowerLimitParam(const OFCString& x);
        virtual void m_zSetVccUpperLimitParam(const OFCString& x);
        virtual void m_zSetManualMeasureRangeParamVccParam(const OFCString& x);
        virtual void m_zSetClampLowValueParamVccParam(const OFCString& x);
        virtual void m_zSetClampHighValueParamVccParam(const OFCString& x);
        virtual void m_zSetLeakPingroupNameParam(const OFCString& x);
        virtual void m_zSetLeakForceVoltageParam(const OFCString& x);
        virtual void m_zSetLeakLowerLimitParam(const OFCString& x);
        virtual void m_zSetLeakUpperLimitParam(const OFCString& x);
        virtual void m_zSetManualMeasureRangeParamLeakParam(const OFCString& x);
        virtual void m_zSetClampLowValueParamLeakParam(const OFCString& x);
        virtual void m_zSetClampHighValueParamLeakParam(const OFCString& x);
        virtual void m_zSetResistanceLowerLimitParam(const OFCString& x);
        virtual void m_zSetResistanceUpperLimitParam(const OFCString& x);
        virtual void m_zSetResistancePinsParam(const OFCString& x);
        virtual void m_zSetResistanceForceParam(const OFCString& x);
        virtual void m_zSetResistanceLevelParam(const OFCString& x);
        virtual void m_zSetResistancePrePauseParam(double x);
        virtual void m_zSetReadEepromModeParam(const OFCString& x);
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
        OFCString    m_sBypassXiuTestParam;                //Param Attribute for testclass parameter "bypassXiuTest"
        iCGENTpParam m_oBypassXiuTestParam;                //Shadow Param Attribute for testclass parameter "bypassXiuTest"
        OFCString    m_sXiuCalCheckParam;                  //Param Attribute for testclass parameter "xiuCalChoices"
        iCGENTpParam m_oXiuCalCheckParam;                  //Shadow Param Attribute for testclass parameter "xiuCalChoices"
        OFCString    m_sXiuValidNameParam;                 //Param Attribute for testclass parameter "xiuValidName"
        iCGENTpParam m_oXiuValidNameParam;                 //Shadow Param Attribute for testclass parameter "xiuValidName"
        OFCString    m_sXiuCalPinGroupsParam;              //Param Attribute for testclass parameter "xiuCalPins"
        iCGENTpParam m_oXiuCalPinGroupsParam;              //Shadow Param Attribute for testclass parameter "xiuCalPins"
        OFCString    m_sXiuIgnoreChannelsParam;            //Param Attribute for testclass parameter "xiuIgnoreChannels"
        iCGENTpParam m_oXiuIgnoreChannelsParam;            //Shadow Param Attribute for testclass parameter "xiuIgnoreChannels"
        OFCString    m_sLevelParam;                        //Param Attribute for testclass parameter "level"
        iCGENTpParam m_oLevelParam;                        //Shadow Param Attribute for testclass parameter "level"
        OFCString    m_sVccPindefParam;                    //Param Attribute for testclass parameter "vccPindefName"
        iCGENTpParam m_oVccPindefParam;                    //Shadow Param Attribute for testclass parameter "vccPindefName"
        OFCString    m_sVccForceVoltageParam;              //Param Attribute for testclass parameter "vccForceVoltage"
        iCGENTpParam m_oVccForceVoltageParam;              //Shadow Param Attribute for testclass parameter "vccForceVoltage"
        OFCString    m_sVccLowerLimitParam;                //Param Attribute for testclass parameter "vccLowerLimit"
        iCGENTpParam m_oVccLowerLimitParam;                //Shadow Param Attribute for testclass parameter "vccLowerLimit"
        OFCString    m_sVccUpperLimitParam;                //Param Attribute for testclass parameter "vccUpperLimit"
        iCGENTpParam m_oVccUpperLimitParam;                //Shadow Param Attribute for testclass parameter "vccUpperLimit"
        OFCString    m_sManualMeasureRangeParamVccParam;   //Param Attribute for testclass parameter "vcc_measure_range"
        iCGENTpParam m_oManualMeasureRangeParamVccParam;   //Shadow Param Attribute for testclass parameter "vcc_measure_range"
        OFCString    m_sClampLowValueParamVccParam;        //Param Attribute for testclass parameter "vcc_clamp_lo"
        iCGENTpParam m_oClampLowValueParamVccParam;        //Shadow Param Attribute for testclass parameter "vcc_clamp_lo"
        OFCString    m_sClampHighValueParamVccParam;       //Param Attribute for testclass parameter "vcc_clamp_hi"
        iCGENTpParam m_oClampHighValueParamVccParam;       //Shadow Param Attribute for testclass parameter "vcc_clamp_hi"
        OFCString    m_sLeakPingroupNameParam;             //Param Attribute for testclass parameter "leakPingroupName"
        iCGENTpParam m_oLeakPingroupNameParam;             //Shadow Param Attribute for testclass parameter "leakPingroupName"
        OFCString    m_sLeakForceVoltageParam;             //Param Attribute for testclass parameter "leakForceVoltage"
        iCGENTpParam m_oLeakForceVoltageParam;             //Shadow Param Attribute for testclass parameter "leakForceVoltage"
        OFCString    m_sLeakLowerLimitParam;               //Param Attribute for testclass parameter "leakLowerLimit"
        iCGENTpParam m_oLeakLowerLimitParam;               //Shadow Param Attribute for testclass parameter "leakLowerLimit"
        OFCString    m_sLeakUpperLimitParam;               //Param Attribute for testclass parameter "leakUpperLimit"
        iCGENTpParam m_oLeakUpperLimitParam;               //Shadow Param Attribute for testclass parameter "leakUpperLimit"
        OFCString    m_sManualMeasureRangeParamLeakParam;  //Param Attribute for testclass parameter "leak_measure_range"
        iCGENTpParam m_oManualMeasureRangeParamLeakParam;  //Shadow Param Attribute for testclass parameter "leak_measure_range"
        OFCString    m_sClampLowValueParamLeakParam;       //Param Attribute for testclass parameter "leak_clamp_lo"
        iCGENTpParam m_oClampLowValueParamLeakParam;       //Shadow Param Attribute for testclass parameter "leak_clamp_lo"
        OFCString    m_sClampHighValueParamLeakParam;      //Param Attribute for testclass parameter "leak_clamp_hi"
        iCGENTpParam m_oClampHighValueParamLeakParam;      //Shadow Param Attribute for testclass parameter "leak_clamp_hi"
        OFCString    m_sResistanceLowerLimitParam;         //Param Attribute for testclass parameter "resistance_lower_limits"
        iCGENTpParam m_oResistanceLowerLimitParam;         //Shadow Param Attribute for testclass parameter "resistance_lower_limits"
        OFCString    m_sResistanceUpperLimitParam;         //Param Attribute for testclass parameter "resistance_upper_limits"
        iCGENTpParam m_oResistanceUpperLimitParam;         //Shadow Param Attribute for testclass parameter "resistance_upper_limits"
        OFCString    m_sResistancePinsParam;               //Param Attribute for testclass parameter "resistance_pins"
        iCGENTpParam m_oResistancePinsParam;               //Shadow Param Attribute for testclass parameter "resistance_pins"
        OFCString    m_sResistanceForceParam;              //Param Attribute for testclass parameter "resistance_force"
        iCGENTpParam m_oResistanceForceParam;              //Shadow Param Attribute for testclass parameter "resistance_force"
        OFCString    m_sResistanceLevelParam;              //Param Attribute for testclass parameter "resistance_levels"
        iCGENTpParam m_oResistanceLevelParam;              //Shadow Param Attribute for testclass parameter "resistance_levels"
        double       m_dResistancePrePauseParam;           //Param Attribute for testclass parameter "resistance_prepause"
        iCGENTpParam m_oResistancePrePauseParam;           //Shadow Param Attribute for testclass parameter "resistance_prepause"
        OFCString    m_sReadEepromModeParam;               //Param Attribute for testclass parameter "readEepromMode"
        iCGENTpParam m_oReadEepromModeParam;               //Shadow Param Attribute for testclass parameter "readEepromMode"
        ////End_Attribute_declaration_for_all_the_test_class_parameters

    };
} // End namespace OASIS

// Following is the set of inline functions (for XML related funtions) which are auto implemented
// by OCC translation.
inline void
iCXiuCheckTest::addParamDescriptions(OASIS::XMLParamsDescriptor& pd) const
{
// Call XMLParamsDescriptor::addParam
// Parameters are:
//     paramName
//     guiType
//     paramDataType
//     cardinality
//     paramValue
//     tooltips
//     paramType
//     dutSpecific
//     choiceItems

OASIS::ChoiceItemsArr choiceItems;

choiceItems.push_back("NO_BYPASS");
choiceItems.push_back("BYPASS_INSTANCE");
choiceItems.push_back("BYPASS_CALCHECK");
choiceItems.push_back("BYPASS_DC");
choiceItems.push_back("BYPASS_VCC_LEAK_CALCHECK");
pd.addParam("bypassXiuTest",
            "list",
            "String",
            "0-1",
            stringToXML(m_sBypassXiuTestParam),
            "No Bypass,Bypass instance,Bypass CalCheck, Bypass Dctests, Bypass Vcc cont and leakage and calcheck",
            "String",
            "False",
            "False",
            choiceItems);
choiceItems.clear();

choiceItems.push_back("CALCHECK_ONCE");
choiceItems.push_back("CALCHECK_ALWAYS");
pd.addParam("xiuCalChoices",
            "list",
            "String",
            "0-1",
            stringToXML(m_sXiuCalCheckParam),
            "Cal Check Once,Cal Check Always",
            "String",
            "False",
            "False",
            choiceItems);
choiceItems.clear();

pd.addParam("xiuValidName",
            "value",
            "String",
            "1",
            stringToXML(m_sXiuValidNameParam),
            "XIU Name[s] space separated string. E.g CMN CPN ",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("xiuCalPins",
            "value",
            "String",
            "0-1",
            stringToXML(m_sXiuCalPinGroupsParam),
            "space separated Pins/Pingroups to perform Calibration.",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("xiuIgnoreChannels",
            "value",
            "String",
            "0-1",
            stringToXML(m_sXiuIgnoreChannelsParam),
            "Tester Channel Numbers to Skip Cal Check(a space seperated string) [Not used in CMT]",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("level",
            "value",
            "String",
            "1",
            stringToXML(m_sLevelParam),
            "The Levels Test Condition parameter",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("vccPindefName",
            "value",
            "String",
            "1",
            stringToXML(m_sVccPindefParam),
            "XIU Vcc Test - power supply pin name[s] space separated",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("vccForceVoltage",
            "value",
            "String",
            "1",
            stringToXML(m_sVccForceVoltageParam),
            "XIU Vcc Test - force voltage value[s] space separated",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("vccLowerLimit",
            "value",
            "String",
            "1",
            stringToXML(m_sVccLowerLimitParam),
            "XIU Vcc Test - lower current limit[s] space separated",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("vccUpperLimit",
            "value",
            "String",
            "1",
            stringToXML(m_sVccUpperLimitParam),
            "XIU Vcc Test - upper current limit[s] space separated",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("vcc_measure_range",
            "value",
            "String",
            "0-1",
            stringToXML(m_sManualMeasureRangeParamVccParam),
            "User-defined measurement range values (LCDPS:5uA,50uA,500uA,5mA,50mA,500mA,4A; HCDPS:50mA,500mA,16A)",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("vcc_clamp_lo",
            "value",
            "String",
            "0-1",
            stringToXML(m_sClampLowValueParamVccParam),
            "Optional - vcc Lower Clamp (Total) Value",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("vcc_clamp_hi",
            "value",
            "String",
            "0-1",
            stringToXML(m_sClampHighValueParamVccParam),
            "Optional - vcc Upper Clamp (Total) Value",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("leakPingroupName",
            "value",
            "String",
            "1",
            stringToXML(m_sLeakPingroupNameParam),
            "XIU Leakage Test - pin/pingroup name[s] space separated",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("leakForceVoltage",
            "value",
            "String",
            "1",
            stringToXML(m_sLeakForceVoltageParam),
            "XIU Leakage Test - force voltage value[s] space separated",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("leakLowerLimit",
            "value",
            "String",
            "1",
            stringToXML(m_sLeakLowerLimitParam),
            "XIU Leakage Test - lower current limit[s] space separated",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("leakUpperLimit",
            "value",
            "String",
            "1",
            stringToXML(m_sLeakUpperLimitParam),
            "XIU Leakage Test - upper current limit[s] space separated",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("leak_measure_range",
            "value",
            "String",
            "0-1",
            stringToXML(m_sManualMeasureRangeParamLeakParam),
            "User-defined measurement range values (auto,6uA,60uA,600uA,6mA,128mA)",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("leak_clamp_lo",
            "value",
            "String",
            "0-1",
            stringToXML(m_sClampLowValueParamLeakParam),
            "Optional - leak Lower Clamp (Total) Value",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("leak_clamp_hi",
            "value",
            "String",
            "0-1",
            stringToXML(m_sClampHighValueParamLeakParam),
            "Optional - leak Upper Clamp (Total) Value",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("resistance_lower_limits",
            "value",
            "String",
            "0-1",
            stringToXML(m_sResistanceLowerLimitParam),
            " XIU Resistance test - The lower limits space separated specified in ohm  ",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("resistance_upper_limits",
            "value",
            "String",
            "0-1",
            stringToXML(m_sResistanceUpperLimitParam),
            " XIU Resistance test - The upper limits space separated specified in ohm ",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("resistance_pins",
            "value",
            "String",
            "0-1",
            stringToXML(m_sResistancePinsParam),
            " XIU Resistance test - The pins/pingroups to force voltage space separated ",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("resistance_force",
            "value",
            "String",
            "0-1",
            stringToXML(m_sResistanceForceParam),
            " XIU Resistance test - The voltages to force to the pins/pingroup specified space separated ",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("resistance_levels",
            "value",
            "String",
            "0-1",
            stringToXML(m_sResistanceLevelParam),
            "XIU Resistance test - The resistance test condition levels parameter ",
            "String",
            "False",
            "False",
            choiceItems);

pd.addParam("resistance_prepause",
            "value",
            "Double",
            "0-1",
            OASIS::OFCString::toString(m_dResistancePrePauseParam),
            "XIU Resistance test - setting time before measurement in miliseconds ",
            "Double",
            "False",
            "False",
            choiceItems);

choiceItems.push_back("READ_XIU_NAME");
choiceItems.push_back("READ_ALL");
pd.addParam("readEepromMode",
            "list",
            "String",
            "0-1",
            stringToXML(m_sReadEepromModeParam),
            "Read the XIU Name from EEPROM, or all the data fields. ",
            "String",
            "False",
            "False",
            choiceItems);
choiceItems.clear();

// Call addParamDescription for each of the public bases
iCOASISCore::addParamDescriptions(pd);
}    // addParamDescriptions

inline OASIS::OFCString
iCXiuCheckTest::getXMLDescription() const
{
    OASIS::XMLParamsDescriptor pd("iCXiuCheckTest", this);
    addParamDescriptions(pd);
    return pd.getDescription();
}

inline void iCXiuCheckTest::setDefaults()
{
OASIS::OFCArray<OASIS::OFCString> values;

// Set defaults for bypassXiuTest
getAllowedValues("bypassXiuTest", "", values);
if (values.size() > 0)
{
    m_zSetBypassXiuTestParam(values[0]);
}
else
{
    m_zSetBypassXiuTestParam("NO_BYPASS");
}

// Set defaults for leak_measure_range
getAllowedValues("leak_measure_range", "", values);
if (values.size() > 0)
{
    m_zSetManualMeasureRangeParamLeakParam(values[0]);
}
else
{
    m_zSetManualMeasureRangeParamLeakParam("auto");
}

// Set defaults for readEepromMode
getAllowedValues("readEepromMode", "", values);
if (values.size() > 0)
{
    m_zSetReadEepromModeParam(values[0]);
}
else
{
    m_zSetReadEepromModeParam("READ_ALL");
}

// Set defaults for resistance_prepause
getAllowedValues("resistance_prepause", "", values);
if (values.size() > 0)
{
    m_zSetResistancePrePauseParam(OASIS::OFCStringUtils::toDouble(values[0]));
}
else
{
    m_zSetResistancePrePauseParam(OASIS::OFCStringUtils::toDouble("1.0"));
}

// Set defaults for vcc_measure_range
getAllowedValues("vcc_measure_range", "", values);
if (values.size() > 0)
{
    m_zSetManualMeasureRangeParamVccParam(values[0]);
}
else
{
    m_zSetManualMeasureRangeParamVccParam("auto");
}

// Set defaults for xiuCalChoices
getAllowedValues("xiuCalChoices", "", values);
if (values.size() > 0)
{
    m_zSetXiuCalCheckParam(values[0]);
}
else
{
    m_zSetXiuCalCheckParam("CALCHECK_ONCE");
}

// Set defaults for xiuCalPins
getAllowedValues("xiuCalPins", "", values);
if (values.size() > 0)
{
    m_zSetXiuCalPinGroupsParam(values[0]);
}
else
{
    m_zSetXiuCalPinGroupsParam("CALPINs");
}

// Call setDefaults() for each of the public bases
iCOASISCore::setDefaults();
} // setDefaults

inline OASIS::OFCString
iCXiuCheckTest::getType
    (const OASIS::OFCString& paramName,
     const OASIS::OFCString& fieldName) const
{
OASIS::OFCString typeName;
bool fieldNameIsEmpty = fieldName.empty();

if (fieldNameIsEmpty && paramName.empty()) return "";

if (fieldNameIsEmpty && (paramName == "bypassXiuTest"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "leakForceVoltage"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "leakLowerLimit"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "leakPingroupName"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "leakUpperLimit"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "leak_clamp_hi"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "leak_clamp_lo"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "leak_measure_range"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "level"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "readEepromMode"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "resistance_force"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "resistance_levels"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "resistance_lower_limits"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "resistance_pins"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "resistance_prepause"))
{
    return "Double";
}

if (fieldNameIsEmpty && (paramName == "resistance_upper_limits"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "vccForceVoltage"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "vccLowerLimit"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "vccPindefName"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "vccUpperLimit"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "vcc_clamp_hi"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "vcc_clamp_lo"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "vcc_measure_range"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "xiuCalChoices"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "xiuCalPins"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "xiuIgnoreChannels"))
{
    return "String";
}

if (fieldNameIsEmpty && (paramName == "xiuValidName"))
{
    return "String";
}

// Call getType() for each of the public bases
typeName = iCOASISCore::getType(paramName, fieldName);
if (!typeName.empty()) return typeName;
return "";
} // getType

 

#endif iCXiuCheckTest_H
