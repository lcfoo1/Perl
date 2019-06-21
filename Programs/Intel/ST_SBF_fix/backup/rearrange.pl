
use File::Copy;
#my $Dir = 'C:\intel\Perl\Programs\datalog\P6300360_7721';
my $Dir = $ARGV[0];
print "$Dir\n";
my $OrigDir = $Dir . "_backup_all";
#my $Command = "cp -Rf $Dir $OrigDir";

mkdir $OrigDir, 0777 || die "Cant create $OrigDir\n";
chdir $Dir || die "Can't change $Dir : $!\n";
foreach my $File (<*>)
{
     	next unless (-f $File);   
	my $File1 = $Dir . '/' .$File;
	my $File2 = $OrigDir . '/' . $File;
	copy($File1, $File2) || die "Cant copy file the directory to $File1 to $File2 : $!\n";
}

qx/chmod -R 555 $OrigDir/;
chdir $OrigDir || die "Can't change $OrigDir : $!\n";

foreach my $File (<*>)
{
	my $Out = $Dir . "/" . $File ;
	print "$Out\n";

	my $ST = "";
	my $Line = "";
	open (OUT, ">$Out") || die "Cant open $Out : $!\n";
	open (FILE, $File) || die "Cant open $File : $!\n";
	while (<FILE>)
	{
		chomp;
		if (/2_comnt_tname_SBF_LD(\S+)/ig)
		{
			$_ = <FILE>;
			$_ = <FILE>;
			chomp;
			if (/comnt_rawnhex_msbF_0_0/ig)
			{
				$_ = <FILE>;
			}
		}
		elsif (/2_tname_SBF_LD(\S+)/ig)
		{
			$_ = <FILE>;
			$_ = <FILE>;
			chomp;
			if (/rawnhex_msbF_0_0/ig)
			{
				$_ = <FILE>;
			}
		}		
		#2_comnt_DFF_Data_LD1_ST_BINARY=00001,Thermal_Sensor_Cat_String=100110101101,Thermal_Sensor_String=0110000010101101101010101110
		elsif (/(2_comnt_DFF_Data_LD1_)(ST_BINARY=\d+,)(\S+)/ig)
		{
			$ST = $2;
			$_ = $1 . $3;
			print OUT "$_\n";
		}
		elsif (/(2_comnt_DFF_Data_PKG_.*,)(TIME\S+)/ig)
		{
			$Line =  $1 . $ST . $2;
			print OUT "$Line\n";
			
		}
		else
		{
			print OUT "$_\n";
		}	
	}
	close FILE;
	close OUT;
}

