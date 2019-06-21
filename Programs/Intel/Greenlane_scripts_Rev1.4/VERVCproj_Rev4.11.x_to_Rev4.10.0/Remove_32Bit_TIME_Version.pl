# To convert version CorTeX and TSS baseline
use Cwd;
my $Dir = getcwd;

my $Org = $Dir . "/original/";
my $Mod = $Dir . "/modified/";

chdir $Org || die "Can't open $Org : $!\n";
foreach my $vcprog (<*.vcproj>)
{
	my $OrgFile = $Org . $vcprog;
	my $ModFile = $Mod . $vcprog;
	open (MOD, ">$ModFile") || die "Cant open $ModFile : $!\n";
	open (ORG, $OrgFile) || die "Cant open $OrgFile : $!\n";
	while(<ORG>)
	{
		chomp;
		s/;_USE_32BIT_TIME_T//g;
#PreprocessorDefinitions="WIN32;_DEBUG;_WINDOWS;_USRDLL;MESSAGE_DATABASE_AVAILABLE;_CRT_SECURE_NO_DEPRECATE;_SECURE_SCL;_SECURE_SCL_THROWS;_USE_32BIT_TIME_T;_DMEM_VER=41000;_DFF_VER=41000;_FUSE_PNUMCIPHER=41000;_TSS_VER=20600;_VER_CTX=41000"
#PreprocessorDefinitions="WIN32;_DEBUG;_LIB;_WINDOWS;_USRDLL;CODE_EXPORTS;_CRT_SECURE_NO_DEPRECATE;_SECURE_SCL;_SECURE_SCL_THROWS;__ACCESSULTFORDFF_DLL__;HAVE_STRING_H;REGEX_MALLOC;__STDC__;STDC_HEADERS;_TSS206_;_POST_CORTEX_3_7_0_"
		s/_TSS206_;_POST_CORTEX_3_7_0_/_USE_32BIT_TIME_T;_DMEM_VER=41100;_DFF_VER=41100;_FUSE_PNUMCIPHER=41100;_TSS_VER=20700;_VER_CTX=41100/g;
		print MOD "$_\n";
	}
	close ORG;
	close MOD;
}
