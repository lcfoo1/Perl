#################################################################
# 								#
# 	Foo Lye Cheung				11 June 2005	#
# 	PDE DPG CPU Penang Malaysia				#
# 								#
# 	Search script for finding pattern for debugging TP	#
# 								#
#################################################################
use strict;
use warnings;
use File::Find;
use Getopt::Std;
use Cwd;
   
our($opt_c, $opt_h, $opt_o, $opt_s, $opt_p) = (0, 0, 0, 0, "");
my $Dir = getcwd();
my @Files = ();
getopts('chosp:');

if ($opt_o && $opt_p && !$opt_h)
{
	print "Search pat at current dir: $opt_p\n";
	find(\&GetFiles, $Dir);
	&Search($opt_p);
}
elsif (!$opt_o && $opt_p && !$opt_h)
{
	print "Search pat from current dir: $opt_p\n";
	find(\&GetFiles, $Dir);
	&Search($opt_p);
}
else
{
	&HelpInfo();
}

sub HelpInfo
{
	print "Usage:\n";
	print "======\n";
	print "-p <pat>\t\tSearch pat from current dir\n";
	print "-s -p <pat>\t\tSearch pat from current dir (case)\n";
	print "-c -p <pat>\t\tSearch pat from current dir/no C++ files\n";
	print "-s -c -p <pat>\t\tSearch pat from current dir/no C++ files (case)\n";
	print "-o -p <pat>\t\tSearch pat at current dir\n";
	print "-s -o -p <pat>\t\tSearch pat at current dir (case)\n";
	print "-c -o -p <pat>\t\tSearch pat at current dir/no C++ files\n";
	print "-s -c -o -p <pat>\tSearch pat at current dir/no C++ files (case)\n";
	print "-h\t\t\tHelp\n";
	exit;
}

sub GetFiles
{
	if ((!$opt_o) && (-f $File::Find::name))
	{
		if (!$opt_c)
		{
			push (@Files, $File::Find::name);
		}
		else
		{
			if ($File::Find::name !~ /(ncb|suo|tcg|cpp|h|org|lcfoo|vcproj|obj|sln|bak|~)$/i)
			{
				push (@Files, $File::Find::name);
			}
		}
	}
	elsif (($opt_o) && (-f $File::Find::name) && ($File::Find::name !~ /$Dir\/\S+\/.*$/))
	{
		if (!$opt_c)
		{
			push (@Files, $File::Find::name);
		}
		else
		{
			if ($File::Find::name !~ /(ncb|suo|tcg|cpp|h|org|lcfoo|vcproj|obj|sln|bak|~)$/i)
			{
				push (@Files, $File::Find::name);
			}
		}
	}
}

sub Search
{
	my $Pattern = shift;
	foreach my $File (@Files)
	{
		open (FILE, $File) or die "Cann't open file $File :$!\n";
		while (<FILE>)
		{
			chomp;
			if ($opt_s)
			{
				if (/$Pattern/)
				{
					$File =~ s/\//\\/g;
					print "$File found\n";
					last;
				}
			}
			else
			{	
				if (/$Pattern/i)
				{
					$File =~ s/\//\\/g;
					print "$File found\n";
					last;
				}
			}
		}
		close FILE;
	}
}
