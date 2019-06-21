#! /usr/intel/bin/perl 


use Getopt::Long;   # to parse command line options

$MODULE_NAME= "CalculateSIGconnectivity.pl";
  

	if (!GetOptions("sigctl=s","h|help"))
	{
		print stderr "\nUnrecognized options encountered!\n";
	}
	if (defined $opt_h) 
	{
		&print_help;
		exit 0;
	}
	if (!defined $opt_sigctl)
	{
		&print_help;
		exit 0;
	}

	&InitMuxes;	

	#Calculate Scanout Connectivity. 
	$Chain1 = &ConnectChain("B7mux");	#Chain1 ends on B7mux
	&validate_sub_chain_order($Chain1);

	$Chain2 = &ConnectChain("C7mux");	#Chain2 ends on C7mux
	&validate_sub_chain_order($Chain2);
	print "Chain1 is: $Chain1 \t Chain2 is: $Chain2\n";

exit 0;


sub InitMuxes {
	$hex_sigctl = &hex2bin($opt_sigctl,36);
	@muxes = split(//,$hex_sigctl);
	$sig_now = pop(@muxes);
	$sig_ads = pop(@muxes);
	$sig_bp3 = pop(@muxes);
	$sig_maskbp3 = pop(@muxes);
	$X1mux = pop(@muxes);
	$X2mux = pop(@muxes);
	$sec_chain = pop(@muxes);
	$master_checker = pop(@muxes);
	
	$A1mux = pop(@muxes);
	$A2mux = pop(@muxes);
	$A3mux = pop(@muxes);
	$A4mux = pop(@muxes);
	$A5mux = pop(@muxes);
	$A6mux = pop(@muxes);
	$A7mux = pop(@muxes);
	$A8mux = pop(@muxes);

	$B1mux = pop(@muxes);
	$B2mux = pop(@muxes);
	$B3mux = pop(@muxes);
	$B4mux = pop(@muxes);
	$B5mux = pop(@muxes);
	$B6mux = pop(@muxes);
	$B7mux = pop(@muxes);
	$B8mux = pop(@muxes);

	$C1mux = pop(@muxes);
	$C2mux = pop(@muxes);
	$C3mux = pop(@muxes);
	$C4mux = pop(@muxes);
	$C5mux = pop(@muxes);
	$C6mux = pop(@muxes);
	$C7mux = pop(@muxes);
	$C8mux = pop(@muxes);

	$T1_0mux = pop(@muxes);
	$T1_1mux = pop(@muxes);
	$T2_0mux = pop(@muxes);
	$T2_1mux = pop(@muxes);

}



sub print_help 
{
   print "\nUsage: $MODULE_NAME -sigctl <sigctl_value>  [-h] \n";
   print "sigctl_value value is value from feed file, switch SIGNATUREMODE=....\n";
}


sub hex2bin {
    local($value,$width) = @_;
    local($b,$r);
    local(%hb) = (  '0','0000','1','0001','2','0010','3','0011',
                    '4','0100','5','0101','6','0110','7','0111',
                    '8','1000','9','1001','a','1010','b','1011',
                    'c','1100','d','1101','e','1110','f','1111');

    $value =~ tr/A-F/a-f/;
    if (!defined($width) || ($width eq '')) { $width = length($value) * 4; }

    $r = '';
    while ($value ne '') {
        $b = chop($value);
        $r = $hb{$b} . $r;
    }

    if ($width > length($r)) { $r = 0 x ($width - length($r)) . $r; }

    substr($r,-$width);

}



sub ConnectChain {
	local ($end_mux_name)=@_;
	local ($CurrentChain,$prev_mux,$prev_mux_name,$end_mux_value);

	#Calculate Scanout Connectivity. 
	$CurrentChain = "";

	if($end_mux_name eq "B7mux")
	{
		$end_mux_value = $B7mux;
	}
	else
	{
		$end_mux_value = $C7mux;
	}

	if($end_mux_value == 0) {
		$CurrentChain = "core1_" . $CurrentChain;
		if($A7mux) {
			$prev_mux = $B6mux;
			$prev_mux_name = "B6mux";
		}
		else {
			$prev_mux = $C6mux;
			$prev_mux_name = "C6mux";
		}
	}
	else {
		if($end_mux_name eq "B7mux")
		{
			$prev_mux = $B6mux;
			$prev_mux_name = "B6mux";
		}
		else
		{
			$prev_mux = $C6mux;
			$prev_mux_name = "C6mux";
		}
	}
	if($prev_mux == 0) {
		$CurrentChain = "core0_" . $CurrentChain;
		if($A6mux) {
			$prev_mux = $B5mux;
			$prev_mux_name = "B5mux";
		}
		else {
			$prev_mux = $C5mux;
			$prev_mux_name = "C5mux";
		}
	}
	else {
		if($prev_mux_name eq "B6mux")
		{
			$prev_mux = $B5mux;
			$prev_mux_name = "B5mux";
		}
		else
		{
			$prev_mux = $C5mux;
			$prev_mux_name = "C5mux";
		}
	}
	if($prev_mux == 0) {
		$CurrentChain = "frc1_" . $CurrentChain;
		if($A5mux) {
			$prev_mux = $B4mux;
			$prev_mux_name = "B4mux";
		}
		else {
			$prev_mux = $C4mux;
			$prev_mux_name = "C4mux";
		}
	}
	else {
		if($prev_mux_name eq "B5mux")
		{
			$prev_mux = $B4mux;
			$prev_mux_name = "B4mux";
		}
		else
		{
			$prev_mux = $C4mux;
			$prev_mux_name = "C4mux";
		}
	}
	if($prev_mux == 0) {
		$CurrentChain = "frc0_" . $CurrentChain;
		if($A4mux) {
			$prev_mux = $B3mux;
			$prev_mux_name = "B3mux";
		}
		else {
			$prev_mux = $C3mux;
			$prev_mux_name = "C3mux";
		}
	}
	else {
		if($prev_mux_name eq "B4mux")
		{
			$prev_mux = $B3mux;
			$prev_mux_name = "B3mux";
		}
		else
		{
			$prev_mux = $C3mux;
			$prev_mux_name = "C3mux";
		}
	}
	if($prev_mux == 0) {
		$CurrentChain = "l2_" . $CurrentChain;
		if($A3mux) {
			$prev_mux = $B2mux;
			$prev_mux_name = "B2mux";
		}
		else {
			$prev_mux = $C2mux;
			$prev_mux_name = "C2mux";
		}
	}
	else {
		if($prev_mux_name eq "B3mux")
		{
			$prev_mux = $B2mux;
			$prev_mux_name = "B2mux";
		}
		else
		{
			$prev_mux = $C2mux;
			$prev_mux_name = "C2mux";
		}
	}
	if($prev_mux == 0) {
		$CurrentChain = "bls_" . $CurrentChain;
		if($A2mux) {
			$prev_mux = $B1mux;
			$prev_mux_name = "B1mux";
		}
		else {
			$prev_mux = $C1mux;
			$prev_mux_name = "C1mux";
		}
	}
	else {
		if($prev_mux_name eq "B2mux")
		{
			$prev_mux = $B1mux;
			$prev_mux_name = "B1mux";
		}
		else
		{
			$prev_mux = $C1mux;
			$prev_mux_name = "C1mux";
		}
	}
	if($prev_mux == 0) {
		$CurrentChain = "bus_" . $CurrentChain;
	}

	$CurrentChain =~ s/_$//;

	return($CurrentChain);
}

sub validate_sub_chain_order {
	#validate if chain is defined correctly
	local ($sub_chain_name)=@_;
	@chain_order=split(/_/,$sub_chain_name);        #divide string to sub_chains;
	$prev_sub_chain = "";
	foreach $sub_chain (@chain_order)
	{
		$found_chain=0;
		foreach $exist_chains ("bus","bls","l2","frc0","frc1","core0","core1")
		{
			if($sub_chain eq $exist_chains)
			{
				#verify a correct order of sub-chains
				if($prev_sub_chain ne "")
				{
					foreach $exist_chains_ordered ("core1","core0","frc1","frc0","l2","bls","bus")
					{
						if($prev_sub_chain eq $exist_chains_ordered)
						{
							&p6error("Incorrect sub-chain order: sub-chain $sub_chain is after sub-chain $prev_sub_chain in SO_CHAIN: $sub_chain_name");
						}
						if($sub_chain eq $exist_chains_ordered)
						{
							last;   #correct order
						}
					}
				}
				$found = 1;
				last;
			}
		}
		if(!$found){
			&p6error("Incorrect sub-chain name $sub_chain in SO_CHAIN: $sub_chain_name");
		}
		$prev_sub_chain = $sub_chain;
	}
}
