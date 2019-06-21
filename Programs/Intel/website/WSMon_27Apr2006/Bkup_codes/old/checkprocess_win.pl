use strict;
use Data::Dumper;
use Win32::Process::Info;

$| = 1;

my $Server = @ARGV[0];
my $ProcessInfo = Win32::Process::Info->new ($Server);
#$ProcessInfo->Set(elapsed_as_seconds => 0);
my $Out = 'c:\Intel\Perl\Programs\pgxpw4035.txt';

open (OUT, ">$Out\n") || die "Cant open $Out : $!\n";
foreach my $Process ($ProcessInfo->ListPids()) 
{
	$Process = ${$ProcessInfo->GetProcInfo ($Process)}[0] unless ref $Process;
	if ($Process->{'Owner'} =~ /^(\.*)/)
	{
		print "$Process->{'Owner'}\n";
		print OUT "$Process->{'Owner'}\n";
	}
}
close OUT;
