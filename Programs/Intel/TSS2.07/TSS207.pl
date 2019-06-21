use strict;
use warnings;

use Cwd;
use Getopt::Std;
use File::Find;
use File::Copy;


my $OASISTemplatesDir = 'C:\Development\intel\tpapps\Greenlane\OASIS\GLN_Rev4.12.4_TSS207C1_PG7.0\templates';
&AddTSS207Param();

sub AddTSS207Param
{
	my %GrepUnVerTSSFiles = ();
	my %GrepVerTSSFiles = ();
	my @GrepVerFounds = qx(findstr /N /S /P /D:${OASISTemplatesDir} _TSS_VER *.h);
	my @GrepUnVerFounds = qx(findstr /N /S /P /D:${OASISTemplatesDir} [^_TSS_VER] *.h);

	foreach my $Found (@GrepUnVerFounds)
	{
		chomp ($Found);
		#print "$Found\n";
		next if (($Found =~ /\.svn/iog) || ($Found =~ /\_tmp/ig) || ($Found =~ /\:$/ig) || ($Found =~ /ncb/ig));
		$Found =~ s/\/\/|\\/\//ig;
		no warnings;
		$Found =~ s/$OASISTemplatesDir//ig;
		my @Path_Line = split (/:/, $Found, 3);
		$GrepUnVerTSSFiles{$Path_Line[0]} = $Path_Line[0];
	}

	foreach my $Found (@GrepVerFounds)
	{
		chomp ($Found);
		#print "$Found\n";
		next if (($Found =~ /\.svn/iog) || ($Found =~ /\_tmp/ig) || ($Found =~ /\:$/ig) || ($Found =~ /ncb/ig));
		$Found =~ s/\/\/|\\/\//i;
		no warnings;
		$Found =~ s/$OASISTemplatesDir//ig;
		my @Path_Line = split (/:/, $Found, 3);
		$GrepVerTSSFiles{$Path_Line[0]} = $Path_Line[0];
	}

	my @UnVerTSSFiles = ();
	my @RawVerTSSFiles = keys %GrepVerTSSFiles;
	my @RawUnVerTSSFiles = keys %GrepUnVerTSSFiles;

	foreach my $RawUnVerTSSFile (@RawUnVerTSSFiles)
	{
		next unless ($RawUnVerTSSFile =~ /OASIS/);
		my $MatchFlag = 0;
		foreach my $RawVerTSSFile (@RawVerTSSFiles)
		{
			if ($RawUnVerTSSFile =~ /$RawVerTSSFile/)
			{
				$MatchFlag = 1;
			}
		}

		if (!$MatchFlag)
		{
			#print "Found $RawUnVerTSSFile\n";
			push (@UnVerTSSFiles, $RawUnVerTSSFile); 
		}
	}

	foreach my $File (@UnVerTSSFiles)
	{
		my $TSS207Flag = 0;
		print "Converting to add param for TSS2.07 $File\n";
		$File = $OASISTemplatesDir . '/' . $File;
		my $TmpFile = $File . "_tmp";

		open (NEWFILE, ">$TmpFile") || die "Cant open $TmpFile : $!\n";
		open (FILE, $File) || die "Cant open $File : $!\n";
		{
			while (<FILE>)
			{
				chomp;

				my ($OrigLine, $TmpLine, $NewData) = ("", "", "");
				if (/pd.addParam/)
				{
					for (my $Cnt = 0; $Cnt < 10; $Cnt++)
					{
						chomp;
						$OrigLine .= "$_\n";
						if (!(($Cnt == 7) || ($Cnt == 8)))
						{
							$TmpLine .= "$_\n";
						}
						elsif (($Cnt == 7) && ($_ =~ /\);/))
						{
							print "No need conversion TSS, still TSS2.07 format\n";
							$TSS207Flag = 1;
						}
						$_ = <FILE>;
					}

					if (!$TSS207Flag)
					{
						$NewData = "#if defined (_TSS_VER)\n";
						$NewData .= "\t#if _TSS_VER >= 20800\n";
						$NewData .= "\t    " . $OrigLine;
						$NewData .= "\t#elif _TSS_VER >= 20700\n";
						$NewData .= "\t    " . $TmpLine;
						$NewData .= "\t#else\n";
						$NewData .= "\t\t#error _TSS_VER has an illegal value.\n";
						$NewData .= "\t#endif\n";
						$NewData .= "#else\n";
						$NewData .= "\t#error _TSS_VER is a required preProcessor item. This should be automatic without an expicite definition in preProcessor item in vcproj file.\n";
						$NewData .= "#endif\n";
					}
					else
					{
						$NewData = $OrigLine;
					}

					print NEWFILE "$NewData\n";
					print NEWFILE "$_\n";			
				}
				else
				{
					print NEWFILE "$_\n";
				}
			}
		}
		close FILE;
		close NEWFILE;
	
		move ($TmpFile, $File) or die "Cant copy from $TmpFile to $File - failed: $!";
	}
}
