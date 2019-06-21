use Net::SMTP;

&SendMail();


sub SendMail 
{
	my($Subject, $Body) = ("Testing", "LCFOO");
	my @To = ('lye.cheung.foo@intel.com');
	my $MailHost = 'mail.intel.com';
	my $From = 'asblds@intel.com';
	my $Tos = join('; ', @To);

	my $smtp = Net::SMTP->new($MailHost);
	$smtp->mail($From);
	$smtp->to(@To);
	$smtp->data();
	$smtp->datasend("To: $Tos\n");
	$smtp->datasend("Subject: $Subject\n");
	$smtp->datasend("$Body");
	$smtp->dataend();
	$smtp->quit();
}

