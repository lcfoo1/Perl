package LCFOO::Crypt;
use strict;
############################################################
# Author  :  Foo Lye Cheung
# Created :  03June2005
#
# Usage:
# ----------------------------------------------------------
#	use LCFOO::Crypt;
#
#	$crypt = LCFOO::Crypt->new( debug => 0 );
#	$enc   = $crypt->encrypt('myguess', 'secret');
#	print "encrypted = '$enc'\n";
#	$dec = $crypt->decrypt($enc, 'secret');
#	print "'$enc' is decrypted: '$dec'\n";
############################################################

my $package = __PACKAGE__;
require MIME::Base64;

my $VERSION = '0.82.01';

# GLOBAL VARIABLES
my $contentType = "";
my $priv = ""; # challenge key
my $debug = 0;

#-----  FORWARD DECLARATIONS & PROTOTYPING
sub iso2hex($);
sub hex2iso($);
sub Error($);
sub Debug($);

sub new {
	my $type = shift;
	my %params = @_;
	my $self = {};

	$params{'encoding'} ||= 'base64'; # base64 || hex8
	$params{'debug'   } ||= 0;

	$self->{'debug'   } = $debug = $params{'debug'};
	$self->{'encoding'} = $params{'encoding'};

	$debug = $params{'debug'};

	bless $self, $type;
}

sub encrypt {
	my $self = shift;

	my $text = shift;
	   $priv = shift;
	
	# Make sure to encrypt similar or equal text to different strings
	my $scramble_left  = sprintf("%04d", substr(1048576 * rand(), 0, 4));
	my $scramble_right = sprintf("%04d", substr(1048576 * rand(), 0, 4));

	my $text_scrambled = "$scramble_left\t$text\t$priv\t$scramble_right";

	my $bin_text = &atob($text_scrambled);
	my $bin_priv = &atob($priv);

	Debug "N1000: Scrambling '$text' with '$priv'...";
	
	#####  Make test
	# my $check1 = '1010';
	# my $check2 = '0111';
	# my $check = &bin_add($check1, $check2);
	# Debug "BEGIN TEST"; Debug $check1; Debug $check2; Debug $check; Debug "END TEST";
	
	my $encryp = &bin_add($bin_text, $bin_priv);
	
	if ($self->{'debug'}) {
		Debug "$bin_text \t<- text";
		Debug "$bin_priv \t<- challenge";
		Debug "$encryp \t<- result";
	}
	
	my $encryp_pack = "";

	for (my $i = 0; $i < length($encryp); $i += 8) {
		my $elem = substr($encryp, $i, 8);
		# X my $elemp =  pack('C', $elem); # cannot be used on RH8.0
		$encryp_pack .= pack('B8', $elem);
	}

	Debug "N1003: encryp_pack -----> '$encryp_pack'\n";

	my $encrypted = '';

	if ($self->{'encoding'} eq 'hex8') {
		$encrypted = iso2hex $encryp_pack;
	}
	else {
		# base64
		$encrypted = MIME::Base64::encode($encryp_pack);
		chomp $encrypted;
	}

	$encrypted;
}

sub decrypt {
	my $self = shift;

	my $encryp_base64 = shift;
	   $priv = shift;
	   
	Debug 'N1002: Decrypting (' . $self->{'encoding'} . ") '$encryp_base64' with '$priv'...";
	
	my $bin_priv = &atob($priv);
	
	my $base64toplain = '';

	if ($self->{'encoding'} eq 'hex8') {
		$base64toplain = hex2iso $encryp_base64;
		Debug "hex8 -> '$encryp_base64' = '$base64toplain'" if $self->{'debug'};
	}
	else {
		$base64toplain = MIME::Base64::decode($encryp_base64);
	}

	Debug "N1004: -> base64toplain = '$base64toplain'...";

	my $encryp_pack = "";
	for (my $i = 0; $i < length($base64toplain); $i++) {
		my $elem = substr($base64toplain, $i, 1);
		my $bin  = unpack('B8', $elem);

		$encryp_pack .= $bin;
	}

	my $bin_new = &bin_add($encryp_pack, $bin_priv);

	$encryp_pack = "";
	for (my $i = 0; $i < length($bin_new); $i += 8) {
        	my $elem = substr($bin_new, $i, 8);
		print "'$elem' = ", pack('B8', $elem), "...\n" if $debug;
        	$encryp_pack .= pack('B8', $elem);
	}

	Debug "N1001: =====> '$encryp_pack' !!!";

	my ($rand1, $result, $priv_wrapped, $rand2) = split /\t/, $encryp_pack;
	return '' if $rand1 =~ /\D/;
	return '' if $rand2 =~ /\D/;
	return '' unless $priv eq $priv_wrapped;

	$result; # return middle element of array only
}

################################################
#	LOCAL SUB ROUTINES
################################################

sub atob ($) {
	my $str = shift;
	my $bin = "";
	for (my $i = 0; $i < length($str); $i++) { $bin .= unpack('B8', substr($str, $i, 1)); }
	$bin;
}

sub bin_add ($$) {
	my $a = shift;
	my $b = shift;

	my $i = my $j = 0;
	for ($j = 0; $j < length($a); $j++) {
		substr($a, $j, 1) += substr($b, $i, 1);
		substr($a, $j, 1) = 0 if substr($a, $j, 1) == 2;
		$i = 0 if ++$i > length($priv);
	}
	$a;
}

sub iso2hex ($) {
	my $string = $_[0];
	my $hex_string = '';

	for (my $i = 0; $i < length($string); $i++) {
		# print substr($string, $i, 1);
		$hex_string .= unpack('H8',  substr($string, $i, 1));
	}
	$hex_string;
}

sub hex2iso ($) {
	my $hex_string = $_[0];
	my $iso_string = '';

	for (my $i = 0; $i < length($hex_string); $i += 2) {
		my $char = substr(pack('H8',  substr($hex_string, $i, 2)), 0, 1); # 1 char
		$iso_string .= $char;
	}
	$iso_string;
}

sub Error ($) {
	print "Content-type: text/html\n\n" unless $contentType;
	print "<b>ERROR</b> ($package): $_[0]\n";
	exit(1);
}

sub Debug ($)  { return unless $debug; print "<b>[$package]</b> $_[0]<br>\n"; }

1;

####  Used Warning / Error Codes  ##########################
#	Next free W Code: 1000
#	Next free E Code: 1000
#	Next free N Code: 1005

