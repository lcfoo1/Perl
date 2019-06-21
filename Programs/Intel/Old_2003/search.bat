@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S %0 %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
#!perl
#line 15

# Search script wrote by Foo Lye Cheung to enable search for debugging TP
use strict;
use warnings;
use File::Find;
use Getopt::Std;
use Cwd;
   
our($opt_c, $opt_h, $opt_o, $opt_p) = (0, 0, 0, "");
my $Dir = getcwd();
my @Files = ();
getopts('hocp:');

if (($opt_o) && ($opt_p))
{
	print "Search at $Dir ... $opt_p\n";
	find(\&GetFiles, $Dir);
	&Search($opt_p);
}
elsif ((!$opt_o) && ($opt_p))
{
	print "Search from $Dir ... $opt_p\n";
	find(\&GetFiles, $Dir);
	&Search($opt_p);
}
elsif ($opt_h)
{
	&HelpInfo();
}
else
{
	print "No option entered...\n";
	&HelpInfo();
}

sub HelpInfo
{
	print "Help:\n";
	print "-p <pat>\tSearch pattern (no case sensitive) from current directory\n";
	print "-c -p <pat>\tSearch pattern (no case sensitive) from current directory/no C++ files\n";
	print "-o -p <pat>\tSearch pattern (no case sensitive) at current directory\n";
	print "-c -o -p <pat>\tSearch pattern (no case sensitive) at current directory/no C++ files\n";
	print "-h\t\tHelp\n";
	exit;
}

sub GetFiles
{
	if ((!$opt_o) && (-f $File::Find::name))
	{
		if (!$opt_c)
		{
			push (@Files, $File::Find::name);
			print "$File::Find::name\n";
		}
		else
		{
			if ($File::Find::name =~ /(tcg|cpp|h|org|lcfoo|vsprog|sln)$/)
			{
				push (@Files, $File::Find::name);
				print "$File::Find::name\n";
			}
		}
	}
	elsif (($opt_o) && (-f $File::Find::name) && ($File::Find::name !~ /$Dir\/\S+\/.*$/))
	{
		if (!$opt_c)
		{
			push (@Files, $File::Find::name);
			print "$File::Find::name\n";
		}
		else
		{
			if ($File::Find::name =~ /(tcg|cpp|h|org|lcfoo|vsprog|sln)$/)
			{
				push (@Files, $File::Find::name);
				print "$File::Find::name\n";
			}
		}
	}
}

sub Search
{
	my ($Pattern) = shift;

	foreach my $File (@Files)
	{
		open (FILE, $File) or die "Cann't open file $File :$!\n";
		while (<FILE>)
		{
			if (/$Pattern/)
			{
				print "$File::Find::name found $Pattern\n";
			} 
		}
		close FILE;
	}
}


__END__
:endofperl
