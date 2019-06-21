package GPIBDVLib;

use vars qw(@ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw(initHandler initETC initGPIB connectHandler connectETC connectTester 
	     setTemp getTemp setKtheta getKtheta getActiveSites sendToBin Reprobe 
	     Retract Query GetTopID setOffset getOffset setSoaktime getSoaktime 
	     Write WriteandRead Read Disconnect);


my $GpibCom = "$ENV{DV_TOOL}/DVLib/GpibConnect.exe";

my $add = 0;
my $retracted = 0;

sub initHandler {
   $add = 6;
   connectHandler();
   connectTester();
}


sub initETC {
   $add = 8;
   connectETC();
   connectTester();
}

sub initGPIB {
   $add  = shift;
   connectTester();
}


sub connectHandler {
   @res = `$GpibCom handler identify 2>&1`;
   foreach $line (@res) {
      if (($line =~ "ERROR")||($line =~ "open failed")){
         if ($line =~ "ERROR") {print "Connection to Summit Handler FAILED\n";last;}
         if ($line =~ "open failed") {print "\nERROR: You need to source the TP Environment before using this tool\n";exit;}
      }
      if ($line =~ "BUFFER:") {
         ($x,$softver) = split ("BUFFER: ", $line);
         chomp ($softver);
         if ($softver =~ "Summit") {
            $summit = 1;
            @res = `$GpibCom handler write "all clearstats"`;
            print "Connection to Summit handler Successful\n";
            print "All stats cleared! \n";
         }
         else {
            print "Connection to Summit Handler FAILED\n";
            exit;
         }
      }
   } 
   #print "$retracted\n";
}



sub connectETC {
   @res = `$GpibCom etc2k write "*IDN?"`;
   @res = `$GpibCom etc2k read 100`;
   foreach $line (@res) {
   print "$line\n";
   if ($line =~ "BUFFER:"){
         ($x, $a) = split (" ", $line);
         if($a =~ "ETC") {
#   	 	print "Connection to ETC2k Successful\n";
	 }
         else {
#		print "Connection to ETC2k FAILED\n";
#		exit;
   	}
   }
   }
   @res = `$GpibCom etc2k write "STARTPROFILE"`;
}

sub connectTester {
   @res = `$GpibCom tester status 2>&1`;
   foreach $line (@res) {
      if ($line =~ "ERROR") {
         print "$line";
      }
      if ($line =~ "STATUS: PROGRAM") {
         ($a,$program) = split (": PROGRAM                 : ",$line);
         if ($line =~ "NOT") {
            print "ERROR: TP not loaded!!!!\n";
         }
      }
   }
}

sub setTemp {
   if($add == 8) {
   
   my $temp = shift;
   my $offs= shift;
   $currentTemp = getTemp();
   @res = `$GpibCom etc2k settemp $temp $offs`;
   while(abs($temp - $currentTemp) > 5.0) {	
        print "Waiting to get to $temp. The temperature is now $currentTemp.\n";
        sleep(3);
        $currentTemp = getTemp();
   }
   }
   if($add == 6) {
   my $offs = shift;
      my $currentTemp = getTemp();
      @res = `$GpibCom handler write "setpoint $offs"`;
      while(abs($offs - $currentTemp) > 0.01*$currentTemp) {
         print "Waiting to get to $offs. The temperature is now $currentTemp.\n";
         sleep(3);
         $currentTemp = getTemp();
      }
	}
    sleep(5);
}

sub getTemp {
if($add == 8) {
   @res = `$GpibCom etc2k write "READTEMP 0"`;
   @res = `$GpibCom etc2k read 100`;
   foreach $line (@res){
   
      if ($line =~ "BUFFER:"){
         ($x, $a, $b, $temp, $offset) = split (" ", $line);
         if($a eq "NULL") {
         	print "error";
         	exit(0);
         }
    	 chomp ($temp);
         $temp = $temp + 0.0;
         print "ETC Temperature is $temp C\n";
         return $temp;
      }
   }
   }  
   if($add == 6) {
     @res = `$GpibCom handler write "setpoint?"`;
      @res = `$GpibCom handler read 100`;
      foreach $line (@res){
         if ($line =~ "BUFFER:"){
            ($x,$offset) = split ("BUFFER: ", $line);
            chomp ($offset);
            $offset = $offset + 0.0;
            print "ATC Temperature is $offset\n";
            return $offset;
         }
      }  
}
   
}

sub setKtheta {
   my $offs = shift; 	
   $offs = $offs + 0.0;
   if ($offs > 2.0)  {
   	print "Error in ktheta\n";
   	print "Defaulting to 0.08";
   	$offs = 0.08;
   }
   if($add == 8) {
   @res = `$GpibCom etc2k write "SETKTHETA" $offs`;
     }  
   if($add == 6) {
   @res = `$GpibCom handler write "ktheta" $offs`;
   }
}

sub getKtheta {

if($add == 6) {
   @res = `$GpibCom handler write "ktheta?"`;
   @res = `$GpibCom handler read 100`;
   foreach $line (@res){
      if ($line =~ "BUFFER:"){
         ($x,$offset) = split ("BUFFER: ", $line);
         chomp ($offset);
         $offset = $offset + 0.0;
         print "ATC Ktheta is $offset\n";
         return $offset;
      }
  }   
  }
}

sub getActiveSites {
if($add == 6) {
   my $sitesloaded = 0;
   @res = `$GpibCom handler testpartsready`;
   foreach $line (@res){
      if ($line =~ "BUFFER:"){
         ($x,$sitesloaded) = split ("BUFFER: ", $line);
         chomp ($sitesloaded);
         if ($sitesloaded =~ "Full"){
            ($a,$b) = split (" ",$sitesloaded);
            $sitesloaded = $b + 0;
            if ($sitesloaded == 11){$sitesloaded = 3;}
            if ($sitesloaded == 10){$sitesloaded = 2;}
         }
         if ($sitesloaded !~ /[0-3]/) {
            print "Unknown Response\n"; 
            return (0);
         }
      }
   }
   return($sitesloaded);
   }
}

sub sendToBin {
if($add == 6) {
   my $site1b = shift;
   my $site2b= shift;
   my $sitesloaded = getActiveSites();
   if($sitesloaded == 0) {
      print "No Sites socketed\n";
      return;
   }
   if (($sitesloaded == 1)||($sitesloaded == 3)) {
      if (!($site1b cmp "")) {
         $site1b = 8;
      }
   }
   if (($sitesloaded == 2)||($sitesloaded == 3)) {
      if (!($site2b cmp "")) {
         $site2b = 8;
      }
   }
   @res = `$GpibCom handler result $site1b,$site2b`;
   }
}

sub Reprobe {
if($add == 6) {
   my $sitesloaded = getActiveSites();
   @res = `$GpibCom handler reprobe $sitesloaded`;
   foreach $line (@res){
      if ($line =~ "ERROR:"){
         chop ($line);
         print "$line";
         return;
      }  
   }
   }
}

sub Retract {
if($add == 6) {
my $sitesloaded = getActiveSites();

if ($retracted == 0){
   if (($sitesloaded == 0)||($sitesloaded == 99)) {
      return;     
   }
   @res = `$GpibCom handler retract`;
   
   foreach $line (@res) {
      if ($line =~ "ERROR:"){
         chop ($line);
         print "$line";
         return;
      }
   }
   $retracted = 1;
  }
 else{
    $retracted = 0;
    @res = `$GpibCom handler contact $sitesloaded`;
    foreach $line (@res){
          if ($line =~ "ERROR:"){
             chop ($line);
             print "$line";
             return;
          }
    }
    $sitesloaded = getActiveSites();
    }
    }
}
 
  
sub Query {  
#print $add;
if($add == 6) {
   my $varinfo = shift;
   @res = `$GpibCom handler $varinfo`;
      
   foreach $line (@res){
      if ($line =~ "ERROR:"){
         print "$line";
         return;
      }
      if ($line =~ "R00"){
         $errortext = "$line\nHandler Communication is Failing...\nPlease Restart the Handler.";
         return;
      }
      if ($line =~ "BUFFER:"){
         ($x,$buffer) = split ("BUFFER: ", $line);
         chomp ($buffer);
         if ($varinfo =~ "chuckid"){
            print "Chuck Id is $buffer \n";
            return;     
         }
         if ($varinfo =~ "chuckdetail"){
            (@siteschuckinfo) = split(":",$buffer);
            $chuckbuffer = "";
  	    if($siteschuckinfo[0] =~ /ERROR/){
               $chuckbuffer = "Chuck Detail: $buffer";
               print "Chuck Detail is $buffer \n";
               return;     
            }
  	    if(($siteschuckinfo[0] =~ /\,/)&&($siteschuckinfo[1] !~ /\,/)){
               ($cchuckid,$csite,$csetpoint,$cktheta,$cheater_t,$cdut_t,$clid_t,$cchuckoffset,$cdevoffset) = split (/\,/,$siteschuckinfo[0]);
               $chuckbuffer = "Chuck Detail:\t\t\t\nChuckID:       \t$cchuckid\t\n";
               $chuckbuffer =   $chuckbuffer."Site:	    \t$csite    \t\n";
               $chuckbuffer =   $chuckbuffer."K-Theta:       \t$cktheta\t\n";
               $chuckbuffer =   $chuckbuffer."Setpoint:      \t$csetpoint\t\n"; 
               $chuckbuffer =   $chuckbuffer."Heater Temp:   \t$cheater_t\t\n";
               $chuckbuffer =   $chuckbuffer."Chuck Offset:  \t$cchuckoffset\t\n";
               $chuckbuffer =   $chuckbuffer."Device Offset: \t$cdevoffset\t\n";
            }
  	    if(($siteschuckinfo[0] =~ /\,/)&&($siteschuckinfo[1] =~ /\,/)){
               ($cchuckid,$csite,$csetpoint,$cktheta,$cheater_t,$cdut_t,$clid_t,$cchuckoffset,$cdevoffset) = split (/\,/,$siteschuckinfo[0]);
               ($csite2,$csetpoint2,$cktheta2,$cheater_t2,$cdut_t,$clid_t2,$cchuckoffset2,$cdevoffset2) = split (/\,/,$siteschuckinfo[1]);
               $chuckbuffer = "Chuck Detail:\t\t\t\nChuckID:        \t$cchuckid\t\t\n";
               $chuckbuffer =   $chuckbuffer."Site:	    \t$csite  \t$csite2    \t\n";
               $chuckbuffer =   $chuckbuffer."K-Theta:       \t$cktheta\t$cktheta2\t\n";
               $chuckbuffer =   $chuckbuffer."Setpoint:      \t$csetpoint\t$csetpoint2\t\n"; 
               $chuckbuffer =   $chuckbuffer."Heater Temp:   \t$cheater_t\t$cheater_t2\t\n";
               $chuckbuffer =   $chuckbuffer."Chuck Offset:  \t$cchuckoffset\t$cchuckoffset2\t\n";
               $chuckbuffer =   $chuckbuffer."Device Offset: \t$cdevoffset\t$cdevoffset2\t\n";
            }
   	    return;     
         }
         if ($varinfo =~ "systemmode"){
            if ($buffer == 0){$buffer = "System Mode: Normal"}
            if ($buffer == 1){$buffer = "System Mode: Drycycle"}
            if ($buffer == 2){$buffer = "System Mode: Wetcycle"}
            if ($buffer == 3){$buffer = "System Mode: Manual"}
            if ($buffer == 4){$buffer = "System Mode: Semi-Automatic"}
            if ($buffer == 5){$buffer = "System Mode: Flush"}
            print "System Mode is $buffer \n";
            return;     
         }
         if ($varinfo =~ "testpartsready"){
            $sitesloaded = $buffer;
            if ($buffer == 0){$buffer = "No sites socketed!!!!\n"}
            if ($buffer == 1){$buffer = "Site 1 socketed\n"}
            if ($buffer == 2){$buffer = "Site 2 socketed\n"}
            if ($buffer == 3){$buffer = "Both Sites socketed\n"}
            print "$buffer";
            return;     
         }
         if ($varinfo =~ "status"){
            if (length($buffer) == 2){$buffer = "0$buffer";}
            @byteinfo = split("",$buffer);
            if (length($buffer) == 2){$byteinfo[1] = $byteinfo[0];$byteinfo[0] = 0;}
            if (length($buffer) == 4){$byteinfo[0] = $byteinfo[1];$byteinfo[1] = $byteinfo[2];}
            $hjam=$hstop=$hnew=$hopen=$htestercontrol=$hleftdoor=$hrightdoor=$hnew3=0;
            if ((!($byteinfo[0] cmp '1'))||(!($byteinfo[0] cmp '3'))||(!($byteinfo[0] cmp '5'))||(!($byteinfo[0] cmp '7'))||(!($byteinfo[0] cmp '9'))||(!($byteinfo[0] cmp 'b'))||(!($byteinfo[0] cmp 'd'))||(!($byteinfo[0] cmp 'f'))){$hjam =1}
            if ((!($byteinfo[0] cmp '2'))||(!($byteinfo[0] cmp '3'))||(!($byteinfo[0] cmp '6'))||(!($byteinfo[0] cmp '7'))||(!($byteinfo[0] cmp 'a'))||(!($byteinfo[0] cmp 'b'))||(!($byteinfo[0] cmp 'e'))||(!($byteinfo[0] cmp 'f'))){$hstop =1}
            if ((!($byteinfo[0] cmp '4'))||(!($byteinfo[0] cmp '5'))||(!($byteinfo[0] cmp '6'))||(!($byteinfo[0] cmp '7'))||(!($byteinfo[0] cmp 'c'))||(!($byteinfo[0] cmp 'd'))||(!($byteinfo[0] cmp 'e'))||(!($byteinfo[0] cmp 'f'))){$hnew =1}
            if ((!($byteinfo[0] cmp '8'))||(!($byteinfo[0] cmp '9'))||(!($byteinfo[0] cmp 'a'))||(!($byteinfo[0] cmp 'b'))||(!($byteinfo[0] cmp 'c'))||(!($byteinfo[0] cmp 'd'))||(!($byteinfo[0] cmp 'e'))||(!($byteinfo[0] cmp 'f'))){$hopen =1}
            
            if ((!($byteinfo[1] cmp '1'))||(!($byteinfo[1] cmp '3'))||(!($byteinfo[1] cmp '5'))||(!($byteinfo[1] cmp '7'))||(!($byteinfo[1] cmp '9'))||(!($byteinfo[1] cmp 'b'))||(!($byteinfo[1] cmp 'd'))||(!($byteinfo[1] cmp 'f'))){$htestercontrol =1}
            if ((!($byteinfo[1] cmp '2'))||(!($byteinfo[1] cmp '3'))||(!($byteinfo[1] cmp '6'))||(!($byteinfo[1] cmp '7'))||(!($byteinfo[1] cmp 'a'))||(!($byteinfo[1] cmp 'b'))||(!($byteinfo[1] cmp 'e'))||(!($byteinfo[1] cmp 'f'))){$hleftdoor =1}
            if ((!($byteinfo[1] cmp '4'))||(!($byteinfo[1] cmp '5'))||(!($byteinfo[1] cmp '6'))||(!($byteinfo[1] cmp '7'))||(!($byteinfo[1] cmp 'c'))||(!($byteinfo[1] cmp 'd'))||(!($byteinfo[1] cmp 'e'))||(!($byteinfo[1] cmp 'f'))){$hrightdoor =1}
            if ((!($byteinfo[1] cmp '8'))||(!($byteinfo[1] cmp '9'))||(!($byteinfo[1] cmp 'a'))||(!($byteinfo[1] cmp 'b'))||(!($byteinfo[1] cmp 'c'))||(!($byteinfo[1] cmp 'd'))||(!($byteinfo[1] cmp 'e'))||(!($byteinfo[1] cmp 'f'))){$hnew3 =1}
            $buffer = "$buffer = $hjam$hstop$hnew$hopen $htestercontrol$hleftdoor$hrightdoor$hnew3";
            
            if ($htestercontrol)  {
               print "Status: Handler in Tester Control Mode\n";
            }
            else {
               print "Status: Handler in Local Control Mode\n";
            }
  	  
            if ($hleftdoor)    {print "Status: Handler Left Door Open\n";}
            if ($hrightdoor)   {print "Status: Handler Right Door Open\n";}
            if ($hjam)         {print "$Status: Handler Jammed\n";}
            if ($hstop)        {print "Status: Handler Stopped\n";}
            return;     
         }
         if (($varinfo =~ "start")&&($buffer =~ "NO_ERROR")){
            print "Handler Started \n"  ;
            return;    
         }
         if (($varinfo =~ "stop")&&($buffer =~ "NO_ERROR")){
            print "Handler Stopped \n";  
            return;    
         }
         @info = split (" ", $buffer);
         print "@info \n"  ;
      }
   }
   }
}


sub GetTopID { 
if($add == 6) {
   @res = `$GpibCom handler write "materialid?"`;
   @res = `$GpibCom handler read 100`;
   foreach $line (@res){
      if ($line =~ "ERROR:"){
         print $line;
	 return;
      }
      if ($line =~ "R00"){
         print "$line\nHandler Communication is Failing...\nPlease Restart the Handler.\n";
         return;	
      }
      if ($line =~ "BUFFER:"){
         ($x,$materialid) = split ("BUFFER: ", $line);
         chomp ($materialid);
         ($site1ID,$site2ID,$site3ID,$site4ID) = split (":",$materialid);
         print ("Top Id Units: $site1ID,$site2ID \n");	  
         return $site1ID;
      }
   }
   }
}

sub setOffset {
if($add == 6) {
   my $offs = shift;
   @res = `$GpibCom handler write "atcchilleroffset $offs"`;
   sleep(3);
   getOffset();
   }
}

sub getOffset {
if($add == 6) {
   @res = `$GpibCom handler write "atcchilleroffset?"`;
   @res = `$GpibCom handler read 100`;
   foreach $line (@res){
      if ($line =~ "BUFFER:"){
         ($x,$offset) = split ("BUFFER: ", $line);
         chomp ($offset);
         print "ATC Offset is $offset\n";
         $offset = $offset + 0.0;
         return $offset;
      }
   }
   }
}

sub setSoaktime { 
if($add == 6) {
   my $offs = shift; 
   @res = `$GpibCom handler write "atcsoaktime $offs"`;
   sleep(3);
   getSoaktime();
   }
}

sub getSoaktime {
if($add == 6) {
   @res = `$GpibCom handler write "atcsoaktime?"`;
   @res = `$GpibCom handler read 100`;
   foreach $line (@res){
      if ($line =~ "BUFFER:"){
         ($x,$offset) = split ("BUFFER: ", $line);
         chomp ($offset);
         print "ATC Soaktime is $offset\n";
         $offset = $offset + 0.0;
         return $offset;
      }
   }
   }
}

sub Write {
   my $temp = shift;
   @res = `$GpibCom gen write $add $temp`;
}

sub WriteandRead {
   my $temp = shift;
   @res = `$GpibCom gen write $add $temp`;
   @res = `$GpibCom gen read $add`;
   foreach $line (@res){
      if ($line =~ "BUFFER:"){
         ($x, $temp) = split ("BUFFER: ", $line);
         chomp($temp);
         return $temp;
      }
}

}
sub Read {
   @res = `$GpibCom gen read $add`;
   foreach $line (@res){
         if ($line =~ "BUFFER:"){
      	 ($x, $temp) = split (" ", $line);
            chomp ($temp);
            return $temp;
   	  }
    }
}

sub Disconnect {
  $add = 0;
}

1;

__END__
= GPIBDVLib =
== Summary ==
This is a DVLib perl module to enable communication with the GPIB Devices including ATC and ETC. 

== Functions ==
{|border="1" cellpadding="3" cellspacing="0" 
|- style="font-weight:bold"  valign="bottom"
| width="145.5" Height="12.75" | FUNCTION
| width="293.25" | DESCRIPTION
| width="457.5" | INPUTS/OUTPUTS
|- 
| initETC ()
| initializes connection to the ETC
| 
  i: 
  o: 
  ex: initETC();
|}

== Examples ==
<pre>
use lib "$ENV{DV_TOOL}/DVLib/";
use GPIBDVLib;

initETC();

setTemp(55.0,45.0);
setKtheta(0.09);
my $temp = getTemp();
print ("Temperature is $temp\n");

</pre>
