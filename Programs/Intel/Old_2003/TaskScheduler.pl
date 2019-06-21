use Win32::TaskScheduler;

my $scheduler = Win32::TaskScheduler->New();

my $TaskDir = 'C:\WINNT\Tasks';

chdir $TaskDir or die "Cant chdir $TaskDir : $!\n";

opendir (DIR, $TaskDir) or die "Cant opendir $TaskDir ;$!\n";
my @Tasks = readdir(DIR);
closedir DIR;

foreach my $Task (@Tasks)
{
	next unless $Task =~ /\.job$/;
	print "$Task is found\n";
	&ActiveTask($Task);
}
$scheduler->End();

sub ActiveTask
{
	my $Task = shift;
	$scheduler->Activate("$Task");

	$runasuser=$scheduler->GetAccountInformation();
	die "Cannot set username\n" if (! $scheduler->SetAccountInformation('GAR\grp_pdqre','automation,123'));
	die "Cannot save changes username\n" if (! $scheduler->Save());
}
