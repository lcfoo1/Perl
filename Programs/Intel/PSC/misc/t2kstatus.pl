#open(T2KSTATUS, "\"t2kctrl status\"|") || die"Cannot run t2kctrl as an system command...\n";

open(T2KSTATUS, "t2kctrl status|") || die "Cannot run t2kctrl as an system command...\n";
while (<T2KSTATUS>)
{
	chomp;
	print "$_\n";
}

close T2KSTATUS;

open(DIR, "dir|") || die "Cannot run dir as an system command...\n";
while (<DIR>)
{
	chomp;
	print "$_\n";
}

close DIR;