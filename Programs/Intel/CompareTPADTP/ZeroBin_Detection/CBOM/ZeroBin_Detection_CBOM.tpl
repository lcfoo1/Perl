
# Module Revision: rev1.0
Version 1.0;

ProgramStyle = Modular;

TestPlan ZeroBin_Detection;

Import ZeroBin_Detection_CBOM_bf_broadside_lvl_MOD.tcg;
Import ZeroBin_Detection_CBOM_broadside333_timing_MOD.tcg;
Import OAITcHlmTest.xml;

#Test Counter Definition
Counters
{
	n90980094_fail_zero_bin_detection,
	n90990094_fail_zero_bin_detection
} # End of Test Counter Definition

Test OAITcHlmTest Zero_Bin_Detection
{
    flow_def_file = "..\\Modules\\ZeroBin_Detection\\Input_Files\\ACT_Zero_Bin_Detection_flow.xlsx";
    datasheet_def_file = "..\\Modules\\ZeroBin_Detection\\Input_Files\\ACT_Zero_Bin_Detection_datasheet.xlsx";
}

DUTFlow ZeroBin_Detection
{
	DUTFlowItem Zero_Bin_Detection_eos0 Zero_Bin_Detection
	{
		Result -2
		{
			Property PassFail = "Fail";
			IncrementCounters ZeroBin_Detection::n90990094_fail_zero_bin_detection;
			SetBin SoftBins.b90999994_fail_zero_bin_detection;
			Return -2;
		}
		Result -1
		{
			Property PassFail = "Fail";
			IncrementCounters ZeroBin_Detection::n90980094_fail_zero_bin_detection;
			SetBin SoftBins.b90989894_fail_zero_bin_detection;
			Return -1;
		}
		Result 0
		{
			Property PassFail = "Fail";
			Return -99;
		}
		Result 1
		{
			Property PassFail = "Pass";
			Return 1;
		}
		Result 2
		{
			Property PassFail = "Fail";
			Return 0;
		}
		Result 3
		{
			Property PassFail = "Fail";
			Return 0;
		}
	}
} # End of DUTFlow ZeroBin_Detection

