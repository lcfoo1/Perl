#!/usr/bin/perl



print "nGroovyweb.f2s.com, groovyhack.cjb.net by the@womble.co.ukn";

print "Perl crypt() function cracker (messege boards etc. use this)n";



#Most of the code was ripped from Tyler Lu's Unix password cracker at  http://web.refute.org

#Because it was a quick rip, some bits aren't needed

#Email the@womble.co.uk with corrections/additions to the code

######################  Usage  ##########################

if($#ARGV<1)

{

    print "nUsage: perlcrack passwd_file dictionary_filean";

    exit;

}



##################### Filenames #########################



$passwd=$ARGV[0];

$dict=$ARGV[1];



###################  Do subroutines ######################



dictionary();

passwords();



################## Dictionary Subroutine #################

sub dictionary

{

    open(DICT, $dict) or die ("nERROR: unable to open $dictan");

    while()

    {

	@_words=split;

	push @words, [@_words];

    }

    print "ngot dictionary file: $dict";

    close(DICT);

    print "n";

}

################## Passwords Subroutine ###################



sub passwords

{

    open(PASSWD, $passwd) or die ("nERROR: unable to open $passwdan");

    print "got passwd file: $passwdn";

    print "nbrute forcing...nn";



    while()

    {

	($user, $encrypt, $uid, $gid, $gecos, $home, $shell)=split(/:/);



print "Encrypted password:-- ";

print $encrypt;

	    $crk="no";

	    crack();                  # execute crack subroutine

	    if($crk eq "no")

            {

		$status="unable to crack";

		$password="X";

		write;

			}

}

close(PASSWD);

print "n";

}





##################### Crack Subroutine ##################



sub crack

{

    for $pass(@words)

    {

	$try=crypt(@$pass[0], aa);

###print "nPassword trying:-- ";

###print @$pass[0];

###print "nEncrypted:-- ";

###print $try;

###print "nn";

	if($try eq $encrypt)

        {

	    $status="FOUND";

	    $password=@$pass[0];

	    print"a";

	    write;

	    $crk="yes";

	    last;

	}

    }



}



#################### Output Format ########################



format STDOUT =

@<<<<<<<<<<<<<<<<<  @<<<<<<<<<<<<<<<<<

$status, $password

.





format STDOUT_TOP =

     status             password

++++++++++++++++++   ++++++++++++++++
