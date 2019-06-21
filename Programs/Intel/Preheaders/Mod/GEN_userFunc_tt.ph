Version 1.0;
Import TestBase.ph;
TestClass = iCGENUserFuncTest;
PublicBases = TestBase;

Parameters
{
    ## tmm; 09/03/2009; sp; hsd 7604; Test template parameters ordering: fix ordering of seemingly random parameter order in tss gui
    ## we will keep [level, patlist, timing] at top of TSS GUI, for end users since these are heavily accessed.
    ## eo hsd 7604

    String function_name #AVATOR FUNCTION; #CMTP FUNCTION;
    {
        Cardinality = 1;
        Attribute = m_oFuncNameParam;
        Description = "Function name: Format for CMT: dll name!function name";
   }
   String function_parameter #AVATOR STRING; #CMTP STRING;
   {
        Cardinality = 0-1;
        Attribute = m_sUserFuncParam;
        Description = "String of parameters expected by the user function";
   }
}

#BEGIN_AVATOR_PORT_DESCRIPTIONS;
#AVATOR_PORT  -2  "FAIL"    "PORT FOR ANY ALARM CONDITION";
        #CMTP_MODE = "ALL_MODE" CMTP_VALUE = "FAIL_DPS_ALARM";
#AVATOR_PORT  -1  "ERROR"    "PORT FOR ANY ERROR CONDITION";
        #CMTP_MODE = "ALL_MODE" CMTP_VALUE = "FAIL_SYSTEM_SOFTWARE";
#AVATOR_PORT 0 "FAIL" "FAIL PORT";
        #CMTP_MODE = "ALL_MODE" CMTP_VALUE = "FAIL_USER_FUNC";
#AVATOR_PORT 1 "PASS" "PASS PORT";
        #CMTP_MODE = "ALL_MODE" CMTP_VALUE = "PASS";
#AVATOR_PORT 2 "FAIL" "FAIL PORT";
        #CMTP_MODE = "ALL_MODE" CMTP_VALUE = "FAIL_USER_FUNC";
#AVATOR_PORT 3 "FAIL" "FAIL PORT";
        #CMTP_MODE = "ALL_MODE" CMTP_VALUE = "FAIL_USER_FUNC";
#AVATOR_PORT 4 "FAIL" "FAIL PORT";
        #CMTP_MODE = "ALL_MODE" CMTP_VALUE = "FAIL_USER_FUNC";
#AVATOR_PORT 5 "FAIL" "FAIL PORT";
        #CMTP_MODE = "ALL_MODE" CMTP_VALUE = "FAIL_USER_FUNC";
#AVATOR_PORT 6 "FAIL" "FAIL PORT";
        #CMTP_MODE = "ALL_MODE" CMTP_VALUE = "FAIL_USER_FUNC";
#AVATOR_PORT 7 "FAIL" "FAIL PORT";
        #CMTP_MODE = "ALL_MODE" CMTP_VALUE = "FAIL_USER_FUNC";
#AVATOR_PORT 8 "FAIL" "FAIL PORT";
        #CMTP_MODE = "ALL_MODE" CMTP_VALUE = "FAIL_USER_FUNC";
#AVATOR_PORT 9 "FAIL" "FAIL PORT";
        #CMTP_MODE = "ALL_MODE" CMTP_VALUE = "FAIL_USER_FUNC";
#AVATOR_PORT 10 "FAIL" "FAIL PORT";
        #CMTP_MODE = "ALL_MODE" CMTP_VALUE = "FAIL_USER_FUNC";
#AVATOR_PORT >= 11 "FAIL" "FAIL PORT";
        #CMTP_MODE = "ALL_MODE" CMTP_VALUE = "FAIL_USER_FUNC";
#
#END_AVATOR_PORT_DESCRIPTIONS;
