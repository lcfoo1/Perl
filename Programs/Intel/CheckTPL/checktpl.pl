
use strict;
use warnings;
use File::Find;

my $Debug = 0;
#my $Dir = 'C:\Development\intel\cmtprogs\LYN\Engineering\lyn_ax_class_sim_6g8m\CMTP_Outputs\OTPL_loadables\lyn_ax_class_sim_6g8m';
my $Dir = 'C:\Development\intel\cmtprogs\GNS\Production\b1040r13J02S050_cclass_gns_lfoo1\CMTP_Outputs\OTPL_loadables';
my @TPLFiles = ();
my %TestTemplates = ();
finddepth(\&GetTPLFiles, $Dir);
&Screen();
	
	
# Get all .tpl files
sub GetTPLFiles
{
	if ((-f $File::Find::name) && (($File::Find::name =~ /\.tpl$/i) || ($File::Find::name =~ /\.txt$/i)))
	{
		my $File = $File::Find::name;
		$File =~ s/\\/\//g;
		print "Found $File\n" if ($Debug == 1);
		#print "Found $File\n" if ($File::Find::name =~ /\.txt$/i);
		push (@TPLFiles, $File);
	}
}

#Screen tpl files
sub Screen
{
	my $OutFile = 'Output.csv';
	
	open (OUTFILE, ">$OutFile") || die "Can't open $OutFile : $!\n";
	foreach my $TPLFile (@TPLFiles)
	{
		#print "Found $TPLFile\n" if ($TPLFile =~ /\.txt$/i);
			
		open (TPL, $TPLFile) || die "Cant open $TPLFile : $!\n";
		while (<TPL>)
		{
			$TPLFile = $1 if ($TPLFile =~ /(Modules\/\w+\/).*/);
			$TPLFile = $1 if ($TPLFile =~ /(Base\/\w+.*)/);

			if (/Import\s+(\w+)\.ph/)
			{
				my $TestTemplate = $1;
				$TestTemplates{$TestTemplate}{$TPLFile} = 1;
				
			}
			elsif (/pre_searchset_userfunc\s*\"(\S+)\"/)
			{
				my $TestTemplate = $1;
				$TestTemplates{$TestTemplate}{$TPLFile} = 1;
			}
			elsif (/post_searchset_userfunc\s*\"(\S+)\"/)
			{
				my $TestTemplate = $1;
				$TestTemplates{$TestTemplate}{$TPLFile} = 1;
			}
		
			if ((/Test\s+(\w+)\s+(\w+)/i) && ($_ !~ /#\s*Test\s+(\w+)\s+(\w+)/i))
			{
				my $Template = $1;
				my $Test = $2;
				
				my ($Timing, $Level, $Patlist) = ("", "", "");
				$_ = <TPL>;
				if (/\{/)
				{
					do 
					{
						chomp;
						$_ = <TPL>;
						if (/timings\s*=\s*\"(\S+\:\:\S+)\"/)
						{
							$Timing = $1;						
						}
						elsif (/level\s*=\s*\"(\S+\:\:\S+)\"/)
						{
							$Level = $1;						
						}						
						elsif (/preinstance\s*=\s*\"(.*)\"/)
						{
							$TestTemplates{$1}{$TPLFile} = 1;						
						}
						elsif (/postinstance\s*=\s*\"(.*)\"/)
						{
							$TestTemplates{$1}{$TPLFile} = 1;						
						}
						elsif (/function_name\s*=\s*\"(\S+)\"/)
						{
							$TestTemplates{$1}{$TPLFile} = 1;						
						}
						elsif (/preplist\s*=\s*\"(\S+\!\S+)\"/)
						{
							$TestTemplates{$1}{$TPLFile} = 1;						
						}
						elsif (/postplist\s*=\s*\"(\S+\!\S+)\"/)
						{
							$TestTemplates{$1}{$TPLFile} = 1;						
						}
						elsif (/patlist\s*=\s*\"(\S+)\"/)
						{
							$Patlist = $1;						
						}
					} while ($_ !~ /\}/);
					print "$Test - $Timing and $Level :: $TPLFile\n" if ($Debug == 1);
					print OUTFILE "$Test,$Timing,$Level,$TPLFile,$Patlist\n";					
				}
			}
		}
		close TPL;
	}
	close OUTFILE;

	foreach my $TestTemplate (sort {keys %{$TestTemplates{$a}} cmp keys %{$TestTemplates{$b}}} keys %TestTemplates) 
	{
		#print "$TestTemplate,";

	  	for my $Module (sort keys %{$TestTemplates{$TestTemplate}}) 
		{
			#	print "$Module; ";
		}
		#print "\n";
	}
	
	
}
