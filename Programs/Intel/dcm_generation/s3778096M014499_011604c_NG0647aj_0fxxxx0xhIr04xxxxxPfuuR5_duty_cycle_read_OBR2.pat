# ASCII Created with Prism 6.9e0434 # and Perseus 0.1_mrm_1
# By eoh@pglc4416, running Linux 2.4.9-45lxset37enterprise
# Mon Jan 29 18:27:44 2007
# Conversion Tool :	Prism Rev Unknown!
# State-Eqns Used :	/nfs/site/proj/cwma/tvpv01/eng/tvpv/state_eq/rel/CWMA-CKT/revQC3.1/bin_linux/
# Generated On :	Mon_01/29/07_18:27:40
# Diag Name :		s3778096M014499_011604c_NG0647aj_0fxxxx0xhIr04xxxxxPfuuR5_duty_cycle_read_OBR2
Version 1.0;

#---------------------------
# Main Pattern Definition
#---------------------------
MainPattern
{
  CommonSection
  {
    #-----------------------------
    # Timing File
    #-----------------------------
    Timing "cwma.tim:sdr_timing";

    #-----------------------------
    # Pin Description File
    #-----------------------------
    PinDescription "cwma.pin";

    #-----------------------------
    # Setup file specification
    #-----------------------------
    Pxr "cwma_com_vrevR5_P_011616_c_N_G0_647a_j_f_x_0_I_0_f1_regunf_0.pxr";

    Domain default
    {
      $include "s3778096M014499_011604c_NG0647aj_0fxxxx0xhIr04xxxxxPfuuR5_duty_cycle_read_OBR2.pat.data";
    }
  }
}
