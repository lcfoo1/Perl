#################################################################################################
#												#
#	DESCRIPTION										#
#	Written to replace the asp's that were running ineffectively on pdqre5. Connects to	#
#	MARS, gets latest entries in A11 and A12. Looks for ID's by device only and updates	#
#	what it has found to the Production SQL server						#
#												#
#	Justin Devanandan Allegakoen				PCO PDQRE Datamation Penang	#
#	08/21/2001										#
#												#
#	Modified 04/26/2002									#
#	Re wrote the whole thing, after I found out that it wasnt inserting.			#
#												#
#################################################################################################
#use strict;
#use warnings;

require "C:/Perl/programs/Common1.pl";

my $db2 = &OpenServer;
my $TempFile = "C:/Temp/F_PRODUCTTempFile.txt";
my $Now = localtime(time);
$Now =~ s/(\w+)\s+(\w+)\s+(\w+)\s+(\S+)\s+(\w+)/$2 $3 $5 $4/;

sub GetData
{
	my ($LastInsertTime);
	my $db = &OpenMARS;

	# When's the last time this ran?
	my $sql2 = "SELECT LastInsertTime FROM F_PRODUCTUpdate";

	if($db2->Sql($sql2))
	{
		&ifSQL($db2, $sql2);
	}
	else
	{
		while($db2->FetchRow())
		{
			my %Temp = $db2->DataHash();
			$LastInsertTime = $Temp{LastInsertTime};
		}
	}

	$LastInsertTime =~ s/\.000$//;
	print "\n\nLast update was run at $LastInsertTime\n";

	# Stick it in a file because I need to terminate the MARS connection ASAP
	open(FILE, ">$TempFile") || die "$TempFile:- $!\n";

	# Whats new then - only take non marketing names
	my $sql = "SELECT * FROM A11_PROD_5.F_PRODUCT WHERE SRC_SENT_DATE >= " .
		"TO_DATE('$LastInsertTime', 'yyyy-mm-dd hh24:mi:ss') AND FACILITY = 'A01' " .
		"AND LENGTH(PRODUCT) >= 21";
	
	print "$sql\n";

	if($db->Sql($sql))
	{
		&ifSQL($db, $sql);
	}
	else
	{
		while($db->FetchRow())
		{
			my %Temp = $db->DataHash();

			foreach my $Title(keys %Temp)
			{
				print FILE "$Title\t$Temp{$Title}\t";
			}
			print FILE "\n";
		}
	}
	
	# Check the other schema too
	$sql = "SELECT * FROM A12_PROD_0.F_PRODUCT WHERE SRC_SENT_DATE >= " .
		"TO_DATE('$LastInsertTime', 'yyyy-mm-dd hh24:mi:ss') AND FACILITY = 'A01' " .
		"AND LENGTH(PRODUCT) >= 21";
	
	print "$sql\n";

	if($db->Sql($sql))
	{
		&ifSQL($db, $sql);
	}
	else
	{
		while($db->FetchRow())
		{
			my %Temp = $db->DataHash();

			foreach my $Title(keys %Temp)
			{
				print FILE "$Title\t$Temp{$Title}\t";
			}
			print FILE "\n";
		}
	}
	$db->Close();
	close FILE;
	print "Done with MARS connection\n";
}

sub ProcessFile
{
	open(FILE, $TempFile) || die "$TempFile:- $!\n";
	while(<FILE>)
	{
		my (%Title);
		chomp;
		s/'//g;
		my @Line = split("\t", $_);

		for(my $i = 0; $i <= $#Line; $i += 2)
		{
			$Title{$Line[$i]} = $Line[$i + 1];
		}
		&SQL(%Title);
	}
	close FILE;
}

sub SQL
{
	my %Title = @_;
	my $Pkg = substr($Title{PRODUCT}, 0, 2);
	my $Device = substr($Title{PRODUCT}, 2, 6);
	my $Rev = substr($Title{PRODUCT}, 9, 1);
	my $Step = substr($Title{PRODUCT}, 11, 1); 
	my $ROM = substr($Title{PRODUCT}, 12, 1);
	my $Eng = substr($Title{PRODUCT}, 13, 2);
	my $Fab = substr($Title{PRODUCT}, 15, 1);
	my $Spec = substr($Title{PRODUCT}, 16, 4);
	my $Ass = substr($Title{PRODUCT}, 20, 1);
	my $Bin = substr($Title{PRODUCT}, 21, 4);

	$Title{PRODGROUP1} =~ s/2\/6TRILLIUM/2TRILLIUM/;
	$Title{PRODGROUP1} =~ s/2LTX/2TRILLIUM/;
	$Title{PRODGROUP1} =~ s/2MCT/2J941/;
	$Title{PRODGROUP1} =~ s/2Q8K/2J941/;
	$Title{PRODGROUP1} =~ s/370S/8S9K/;
	$Title{PRODGROUP1} =~ s/495S/8S9K/;
	$Title{PRODGROUP1} =~ s/567S/8S9K/;
	$Title{PRODGROUP1} =~ s/615S/8S9K/;
	$Title{PRODGROUP1} =~ s/6S9K/6S9K/;
	$Title{PRODGROUP1} =~ s/ADT/--/;
	$Title{PRODGROUP1} =~ s/ATPO/8S9K/;
	$Title{PRODGROUP1} =~ s/FV-296/7S9K/;
	$Title{PRODGROUP1} =~ s/FW-241/6S9K/;
	$Title{PRODGROUP1} =~ s/FW-324/6S9K/;
	$Title{PRODGROUP1} =~ s/FW-360/6S9K/;
	$Title{PRODGROUP1} =~ s/FW-421/6S9K/;
	$Title{PRODGROUP1} =~ s/FW-492/6S9K/;
	$Title{PRODGROUP1} =~ s/FW-544/6S9K/;
	$Title{PRODGROUP1} =~ s/FX/6S9K/;
	$Title{PRODGROUP1} =~ s/GC-496/7S9K/;
	$Title{PRODGROUP1} =~ s/GC-540/7S9K/;
	$Title{PRODGROUP1} =~ s/GENATPO/8S9K/;
	$Title{PRODGROUP1} =~ s/GP-540/7S9K/;
	$Title{PRODGROUP1} =~ s/GR-540/7S9K/;
	$Title{PRODGROUP1} =~ s/IX/8S9K/;
	$Title{PRODGROUP1} =~ s/KB-387/7S9K/;
	$Title{PRODGROUP1} =~ s/KE-296/7S9K/;
	$Title{PRODGROUP1} =~ s/KF-296/7S9K/;
	$Title{PRODGROUP1} =~ s/KM-387/7S9K/;
	$Title{PRODGROUP1} =~ s/KP-387/7S9K/;
	$Title{PRODGROUP1} =~ s/KT-528/7S9K/;
	$Title{PRODGROUP1} =~ s/KV-296/7S9K/;
	$Title{PRODGROUP1} =~ s/KV-320/7S9K/;
	$Title{PRODGROUP1} =~ s/KV-387/7S9K/;
	$Title{PRODGROUP1} =~ s/NW-387/7S9K/;
	$Title{PRODGROUP1} =~ s/PG-370/7S9K/;
	$Title{PRODGROUP1} =~ s/PIECE PART/8S9K/;
	$Title{PRODGROUP1} =~ s/^S9K/7S9K/;
	$Title{PRODGROUP1} =~ s/VV-370/7S9K/;
	$Title{PRODGROUP1} =~ s/^HP94k/6HP94K/;

	my $Building = substr($Title{PRODGROUP1}, 0, 1);
	my $Tester = substr($Title{PRODGROUP1}, 1, (length($Title{PRODGROUP1}) - 1));

	$Title{USAGE_RATE} = 0 if($Title{USAGE_RATE} eq "");
	$Title{MIN_STOCK_LEVEL} = 0 if($Title{MIN_STOCK_LEVEL} eq "");
	$Title{MAX_STOCK_LEVEL} = 0 if($Title{MAX_STOCK_LEVEL} eq "");
	$Title{REORDER_POINT} = 0 if($Title{REORDER_POINT} eq "");
	$Title{ORDER_QUANTITY} = 0 if($Title{ORDER_QUANTITY} eq "");
	$Title{NOROUTES} = 0 if($Title{NOROUTES} eq "");
	$Title{NOOPERATIONS} = 0 if($Title{NOOPERATIONS} eq "");
	$Title{YIELD} = 0 if($Title{YIELD} eq "");
	$Title{PLAN_YIELD} = 0 if($Title{PLAN_YIELD} eq "");
	$Title{CYCLE_TIME} = 0 if($Title{CYCLE_TIME} eq "");
	$Title{FAST_CYCLE_TIME_PCNT} = 0 if($Title{FAST_CYCLE_TIME_PCNT} eq "");

	# We have all we need for an UPDATE so try that first
	my $sql2 = "UPDATE F_PRODUCT SET ";

	foreach my $Key(keys %Title)
	{
		next if($Key eq "FACILITY");
		$sql2 .= $Key . " = " . "'$Title{$Key}', ";
	}
	$sql2 .= "ACTIVE = 1 WHERE PRODUCT = '$Title{PRODUCT}'";

	if($db2->Sql($sql2))
	{
		&ifSQL($db2, $sql2);
	}
	else
	{
		if($db2->RowCount() <= 0)
		{
			my ($Header, $Value, %Temp);

			# So lets insert the data then - this sql doesnt cater for existing generic names but no PE
			my $sql2 = "SELECT DISTINCT PEID, DelegateID, QREID, NOBI, " .
				"(SELECT TOP 1 GenericName FROM F_PRODUCT WHERE PKG = '$Pkg' " .
				"AND DEVICE = '$Device' AND REV = '$Rev' AND STEP = '$Step') AS GenericName " .
				"FROM F_PRODUCT WHERE DEVICE = '$Device' AND (PEID IS NOT NULL OR PEID != '')";

			if($db2->Sql($sql2))
			{
				&ifSQL($db2, $sql2);
			}
			else
			{
				while($db2->FetchRow())
				{
					%Temp = $db2->DataHash();
				}

				my $sql2 = "INSERT INTO F_PRODUCT(";

				foreach my $Key(keys %Title)
				{
					next if($Key eq "FACILITY");
					$Header .= "$Key, ";
					$Value .= "'$Title{$Key}', ";
				}
				$sql2 .= $Header . "PEID, DelegateID, QREID, NOBI, GenericName, BUILDING, TESTER, " .
					"PKG, DEVICE, REV, STEP, ROM, ENGID, FAB, SPEC, ASSM, BIN, ACTIVE) " .
					"VALUES($Value'$Temp{PEID}', '$Temp{DelegateID}', '$Temp{QREID}', " .
					"'$Temp{NOBI}', '$Temp{GenericName}', '$Building', '$Tester', '$Pkg', " .
					"'$Device', '$Rev', '$Step', '$ROM', '$Eng', '$Fab', '$Spec', '$Ass', '$Bin', 1)";

				if($db2->Sql($sql2))
				{
					&ifSQL($db2, $sql2);
				}
				else
				{
					print "$sql2\n";
				}
			}
		}
		else
		{
			print "$sql2\n";
		}
	}
}

&GetData;
&ProcessFile;

my $sql2 = "UPDATE F_PRODUCTUpdate SET LastInsertTime = '$Now'";

if($db2->Sql($sql2))
{
	&ifSQL($db2, $sql2);
}
else
{
	print "$sql2\n";
}
$db2->Close();

