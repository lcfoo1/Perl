#################################################################################################################
#														#
#	Foo Lye Cheung					PDE CPU (TMM)						#
#	28 Feb 2006												#
#	604-2536452												#
#														#
#	This script is to archived files to into compressed file (tar and gz)					#
#														#
#	Usage: $0 [-h] [-s <Source Dir>] [-d <Destination Dir>] [-o <TargetFile>] 				#
#	-h        	: This (help) message									#
#	-s <Source Dir>		: Source directory of files to TAR						#
#	-o <TargetFile>		: TAR filename									#
#	-d <Destination Dir>	: Destination directory where the tar and gz,	OR				#
#	-i <Setup file>		: Setup file is used if have multiple destination directory to tar and gz	#
#	Example: $0 [-h] [-s <Source Dir>] [-o <TargetFile>] [-d <Destination Dir>]|[-i <Setup file>]		#
#	   													#
#	Rev 0.0													#
#														#
#################################################################################################################
use Getopt::Std;
use Archive::TarGzip qw(parse_header tar untar);
use File::Package;
use File::AnySpec;
use File::Find;

my %opt = ();
my @Files = ();
my @DestDirs = ();
getopts("d:i:ho:s:", \%opt ) or Usage();

&Usage() if defined ($opt_h || $opt{h});
my $DestDir = $opt_d || $opt{d} || "";
my $SrcDir = $opt_s || $opt{s} || "";
my $TarGzFile = $opt_o || $opt{o} || "";
my $SetupFile = $opt_i || $opt{i} || "";

#my $SrcDir = 'P:/tpapps/IDC_CorTeX';
if ((-e $SrcDir) && ($SrcDir ne ""))
{
	$SrcDir =~ s/\\/\//g;
	print "Main source directory: $SrcDir\n";
}
else 
{
	print "Your source destination $SrcDir do not exist\n";
	&Usage();
}

#my $TarGzFile = 'P:\tpapps\files2.tar.gz';
&Usage() if ($TarGzFile eq "");

#my @DestDirs = ('P:\tpapps\IDC_CorTeX\OASIS\Rev3.7.0v8p0e1', 'P:\tpapps\IDC_CorTeX\UFs\Rev3.7.0v8p0e1');
if (($DestDir ne "") && ($SetupFile eq ""))
{
	if (-e $DestDir)
	{
		push (@DestDirs, $DestDir);
	}
	else
	{
		print "Your destination directory $DestDir do not exist\n";
		&Usage();
	}
}
elsif (($DestDir eq "") && ($SetupFile ne ""))
{
	if (-e $SetupFile)
	{
		open (SETUP, $SetupFile) || die "Cant open $SetupFile : $!\n";
		while (<SETUP>)
		{
			chomp;
			my $Dir = $_;
			if (-e $Dir)
			{
				push (@DestDirs, $Dir);
			}
			else
			{
				print "Can't find directory: $Dir\n";
				&Usage();
			}
		}
		close SETUP;
	}
	else
	{
		print "Your setup file do not exist!!!\n";
		&Usage();
	}
}
else
{
	print "Please enter either -d <destination directory> or -i <setup file>\n";
	&Usage();
}

chdir $SrcDir || die "Cant change directory $SrcDir : $!\n";
finddepth(\&GetFiles, @DestDirs);

# To get all the files to be tar and gzip
sub GetFiles
{
	if (-f $File::Find::name)
	{
		my $File = $File::Find::name;
		$File =~ s/\\/\//g;
		$File =~ s/$SrcDir\///g;
		print "Found $File\n";
		push (@Files, $File);
	}
}

if ($#Files > 0)
{
	# Tar the files
	print "Starting to TAR and GZIP\n";
	my $TARGZResult = Archive::TarGzip->tar(@Files, {src_dir=> $SrcDir, tar_file => $TarGzFile, compress => 1});
	if ($TARGZResult)
	{
		print "Successful to tar and gzip the files!!!\n";
	}
	else 
	{
		print "Fail to tar and gzip the files!!!\n";
	}
}
else
{
	print "No files found to be tar and gz!!!\n";
}



# Display help message
sub Usage
{
	my $Help = "\nHelp:\n=====
Usage: $0 [-h] [-s <Source Dir>] [-d <Destination Dir>] [-o <TargetFile>]

-h        		: This (help) message
-s <Source Dir>		: Source directory of files to TAR
-d <Destination Dir>	: Destination directory where the TAR file going to place
-o <TargetFile>		: TAR filename
-d <Destination Dir>	: Destination directory where the tar and gz,	OR		
-i <Setup file>		: Setup file is used if have multiple destination directory to tar and gz

Example: $0 [-h] [-s <Source Dir>] [-o <TargetFile>] [-d <Destination Dir>]|[-i <Setup file>]\n";

	print "$Help\n";
	exit 0;
}
 
