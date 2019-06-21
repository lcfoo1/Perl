use strict;
use Data::Dumper;
use Win32::Process::Info;

$| = 1;

my $Server = 'pgw2vmup112';
my $ProcessInfo = Win32::Process::Info->new ($Server);
#$ProcessInfo->Set(elapsed_as_seconds => 0);

foreach my $Process ($ProcessInfo->ListPids()) 
{
	$Process = ${$ProcessInfo->GetProcInfo ($Process)}[0] unless ref $Process;
	if ($Process->{'Owner'} =~ /^\w{3}\\(\w+)/)
	{
		print "$Process->{'Owner'}\n";
		#last;
	}
	print "\n$Process->{ProcessId}\n", map {"    $_ => @{[defined $Process->{$_} ? $Process->{$_} : '']}\n"} sort keys %$Process;
}
