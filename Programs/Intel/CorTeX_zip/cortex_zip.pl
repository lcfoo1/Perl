#################################################################################################################
#														#
#	Foo Lye Cheung					PDE CPU (TMM)						#
#	30 March 2006												#
#	604-2536452												#
#														#
#	This script is to archived files to into compressed file (.zip)						#
#														#
#	Usage: $0 [-h] [-s <Source Dir>] [-f <Zipfile Dir/Filename>] [-r <CorTeX Rev>]			#
#	-h        		: This (help) message								#
#	-s <Source Dir>		: Source directory of files to zipped						#
#	-f <Zipfile>		: zip filename									#
#	-r <CorTeX Rev>		: CorTeX revision								#
#	Example: $0 [-h] [-s <Source Dir>] [-f <Zipfile Dir/Filename>] [-r <CorTeX Rev>]			#
#	   													#
#	Rev 0.0													#
#														#
#################################################################################################################
#cortex_zip.pl -s C:\intel\IDC_CorTeX -r Rev3.7.0v8p0e1p2 -f C:\Perl\Programs\CorTeX_zip\Rev3.7.0v8p0e1p2.zip
use Getopt::Std;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use File::Find;

my %opt = ();
my @Files = ();
getopts("hf:r:s:", \%opt) or Usage();

&Usage() if defined ($opt_h || $opt{h});
my $SrcDir = $opt_s || $opt{s} || "";
my $ZipFileName = $opt_f || $opt{f} || "";
my $Rev = $opt_r || $opt{r} || "";
my $SetupFile = $opt_i || $opt{i} || "";

if ((-e $SrcDir) && ($SrcDir ne ""))
{
	$SrcDir =~ s/\\/\//g;
	print "Main source directory: $SrcDir\n";
}
else 
{
	&Usage();
}
&Usage() if ($ZipFileName eq "");

# Ensure the CorTeX Revision is enterred
if ($Rev ne "")
{
	finddepth(\&GetFiles, $SrcDir);
	&ZipFiles();
}
else
{
	&Usage();
}

# Get all the files
sub GetFiles
{
	if ((-f $File::Find::name) && ($File::Find::name =~ /\/$Rev\//g))
	{
		my $File = $File::Find::name;
		$File =~ s/\\/\//g;
		$File =~ s/$SrcDir\///g;
		print "Found $File\n";
		push (@Files, $File);
	}
}

# Zip the files now
sub ZipFiles
{
	chdir $SrcDir || die "Cant change directory $SrcDir : $!\n";
	print "Zipping files at $SrcDir\n";
	my $Zip = Archive::Zip->new();
	foreach my $MemberName (map {glob} @Files)
	{
		if (-d $MemberName )
		{
			warn "Can't add tree $MemberName\n" if $Zip->addTree($MemberName, $MemberName) != AZ_OK;
		}
		else
		{
			$Zip->addFile($MemberName) or warn "Can't add file $MemberName\n";
		}
	}
	
	my $Status = $Zip->writeToFileNamed($ZipFileName);
	exit $Status;
}


# Display help message
sub Usage
{
	my $Help = "\nHelp:\n=====
Usage: $0 [-h] [-s <Source Dir>] [-f <Zipfile Dir/Filename>] [-r <CorTeX Rev>]
-h        		: This (help) message								
-s <Source Dir>		: Source directory of files to zipped						
-f <Zipfile>		: zip filename									
-r <CorTeX Rev>		: CorTeX revision								
	
Example: $0 [-h] [-s <Source Dir>] [-f <Zipfile Dir/Filename>] [-r <CorTeX Rev>]\n";

	print "$Help\n";
	exit 0;
}
