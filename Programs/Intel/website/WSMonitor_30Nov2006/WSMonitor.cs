//#################################################################################
//#                                                                               #
//#        Foo Lye Cheung                             PDE DPG 		          #
//#        inet 253 6452                              Penang                      #
//#                                                                               #
//#        DESCRIPTION                                                            #
//#        New code in C# to monitor workstation for WinXP SP2	  		  #
//#                                                                               #
//#        DEPENDENCISE:  	                                                  #
//#        - ServerProcess.pl                                           	  #
//#        - quser.exe                                           	  	  #
//#        	                                                               	  #
//#        RELEASES                                                               #
//#        11/28/2006  rev0.0 - Server main code release                          #
//#                                                                               #
//#################################################################################
using System;
using System.Diagnostics;
using System.Data;
using System.IO;
using System.Text;
using System.Collections;
using System.Text.RegularExpressions;
 
public class GetUserProcess
{		
	public static void Main()
    	{
    		int Debug = 0;    		
    		int ServerMachine = 0;
    		string strTmpHostname = "", strHostname = "";
    		string strProcess = "";
    		string strFileName = "";
    		string Active = "", Status = "", Server = "", Team = "", User = "", Logon = "", LastActive = "";
    		string USERNAME = "", SESSIONNAME = "", TEAM= "", STATE = "", LOGONTIME = "";
	    	DateTime Now = DateTime.Now;
    	
    		Process h = new Process();
        	h.StartInfo.FileName = "cmd.exe";
        	h.StartInfo.Arguments = "/c hostname";
        	h.StartInfo.UseShellExecute = false;
        	h.StartInfo.RedirectStandardOutput = true;
        	h.Start();
        
        	strTmpHostname = h.StandardOutput.ReadToEnd();
        	Regex xHostname = new Regex (@"(\S*)\s*");
        	strHostname = xHostname.Replace (strTmpHostname, "$1", 1);
        	
        	strFileName = strHostname + ".tmp";

		// Open config file to check for hostname, team and setup
		// No \n allowed in the end of the file
       		string strLine = "";
       		string ConfigHostname = "", ConfigTeam = "", ConfigSetup = "";
       		FileStream ConfigFile = new FileStream("workstation.cfg",FileMode.Open);
       		StreamReader sr = new StreamReader(ConfigFile);
       		strLine = sr.ReadLine();
       		while(strLine != null)
       		{
               		strLine = sr.ReadLine();
        
        		if (strLine == null)
				continue;               	
               	     	
	        	Regex theRegex = new Regex(" |\t|\n");
           		StringBuilder sBuilder = new StringBuilder();
           		int id = 1;

           		foreach (string subString in theRegex.Split(strLine))
           		{
           			if (id == 1)
           			{
           				ConfigHostname = subString;
           			}
           			else if (id == 2)
           			{
           				ConfigTeam = subString;
           			}
           			else if (id == 3)
           			{
           				ConfigSetup = subString;
           			}
           			else
           			{
           				// No fields 4 allowed
           			}
           			id++;
               		}
               		
               		if (Debug == 1)
               		{
           			Console.WriteLine("{0}, {1}, {2}", ConfigHostname, ConfigTeam, ConfigSetup);
           		}
           		
           		if (String.Compare(strHostname, ConfigHostname, true) == 0)
           		{
           			if((ConfigSetup == "YES") || (ConfigSetup == "NEVER"))
           			{
           				Console.WriteLine ("Client machine ({0}) running...", strHostname);
           				TEAM = ConfigTeam;
           				ServerMachine = 0;
           				break;
           			}
           			else if (ConfigSetup == "SERVER")
           			{
           				Console.WriteLine ("Server machine ({0}) running...", strHostname);
           				TEAM = ConfigTeam;
           				ServerMachine = 1;
           				break;           				
           			}
           			else
           			{           				
           				// For case NO
           				Console.WriteLine ("No machine ({0}) running...", strHostname);
           				TEAM = ConfigTeam;
           				Server = "Server=" + strHostname.ToString();
           				Team = "Team=" + TEAM;
           				
           				StreamWriter sw = new StreamWriter(strFileName);
           				sw.WriteLine("Status=Down");
           				sw.WriteLine(Server);
           				sw.WriteLine(Team);
           				sw.Close();
           				
           				FileInfo pNoFile = new FileInfo(strFileName);
           				string strNoNewFileName = pNoFile.Directory + "\\" + strHostname + ".txt";
           				
           				Console.WriteLine ("Finish processing {0} ... ", strHostname);
           				pNoFile.CopyTo(strNoNewFileName, true);
           				
           				Environment.Exit (0);
           			}
           		}
            	}
            	ConfigFile.Close();
            	sr.Close();
        
        	Process p = new Process();
        	p.StartInfo.FileName = "cmd.exe";
        	p.StartInfo.Arguments = "/c quser ";
        	p.StartInfo.UseShellExecute = false;
        	p.StartInfo.RedirectStandardOutput = true;
        	p.Start();
        
        	strProcess = p.StandardOutput.ReadToEnd();
        
		// USERNAME              SESSIONNAME        ID  STATE   IDLE TIME  LOGON TIME
		//>lfoo1                 rdp-tcp#9           0  Active          .  11/27/2006 9:55 AM

		int SessionActive = 0;
	
    		MatchCollection MatchCollection = Regex.Matches(strProcess, @">(?<USERNAME>\S*)\s*(?<SESSIONNAME>\S*)\s*(?<ID>\S*)\s*(?<STATE>\S*)\s*(?<IDLETIME>\S*)\s*(?<LOGONTIME>.*)");
    	
    		foreach (Match RegMatch in MatchCollection)
		{
			USERNAME = RegMatch.Groups["USERNAME"].Value;
			SESSIONNAME = RegMatch.Groups["SESSIONNAME"].Value;
			STATE = RegMatch.Groups["STATE"].Value;
			LOGONTIME = RegMatch.Groups["LOGONTIME"].Value;
			SessionActive = 1;
		}

		if (SessionActive == 1)
		{		
			string LastActiveFile = "LastActive_" + strHostname + ".txt";
			
			StreamReader reader;
			try
			{
                		reader = File.OpenText(LastActiveFile);
                		reader.Close ();
            		}
            		catch (Exception e)
            		{
            			Console.WriteLine (e.Message);
            			            			
            			StreamWriter swLastActive = new StreamWriter(LastActiveFile);
				swLastActive.WriteLine(Now.ToString());
				swLastActive.Close();				
				LOGONTIME = Now.ToString();	
            		}		
		
			if (STATE == "Active")
			{				
				StreamWriter swLastActive = new StreamWriter(LastActiveFile);
				swLastActive.WriteLine(Now.ToString());
				swLastActive.Close();
				
				LOGONTIME = Now.ToString();	
			}
			else
			{
				StreamReader srLastActive = new StreamReader(LastActiveFile);
       				strLine = srLastActive.ReadLine();
       				srLastActive.Close();				
				
				LOGONTIME = strLine.ToString();			
			}
			
			// To always get the current time
			if (ConfigSetup == "NEVER")
			{
				LOGONTIME = Now.ToString();
			}
			
			DateTime LogonTime = DateTime.Parse(LOGONTIME);	
						
			long TmpDiffTime 	= (Now.Ticks) - (LogonTime.Ticks);
			long DiffTime 		= (long) Math.Ceiling (TmpDiffTime / 10000000);
			long Day 		= (long) Math.Floor (DiffTime / 86400);
			long Hour 		= (long) Math.Floor ((DiffTime - (Day * 86400)) / 3600);
			long Minute 		= (long) Math.Floor ((DiffTime - ((Day * 86400) + (Hour * 3600))) / 60);
			long Second 		= (long) Math.Floor (DiffTime - ((Day * 86400) + (Hour * 3600) + (Minute * 60)));

			// Formating the output		
			//		Status=Active
			//		Server=pgxpw4057
			//		Team=TM
			//		User=lfoo1
			//		Logon=10/30/2006 14:49:37
			//		LastActive=Mon Nov  6 17:23:35 2006
			//		Active=Yes(IDLE=0days, 0hours, 1mins)
		
			Server = "Server=" + strHostname.ToString();
			User = "User=" + USERNAME;			
			Logon = "Logon=" + LogonTime.ToString();
			LastActive = "LastActive=" + Now.ToString();

			if (STATE == "Active")
			{
				Status = "Status=Active";
				Active = "Active=Yes(IDLE=" + Day.ToString() + "days, " + Hour.ToString() + "hrs, " + Minute.ToString() + "mins)";
			}
			else
			{
				if (DiffTime < 86400)
				{
					Status = "Status=Active";
					Active = "Active=Yes(IDLE=" + Day.ToString() + "days, " + Hour.ToString() + "hrs, " + Minute.ToString() + "mins)";
				}
				else
				{	Status = "Status=Active";
					Active = "Active=No(IDLE=" + Day.ToString() + "days, " + Hour.ToString() + "hrs, " + Minute.ToString() + "mins)";
				}
			}
		
			Team = "Team=" + TEAM;
	
			if (Debug == 1)
			{	
				Console.WriteLine(Status);
				Console.WriteLine(Server);
				Console.WriteLine(Team);
				Console.WriteLine(User);
				Console.WriteLine(Logon);
				Console.WriteLine(LastActive);
				Console.WriteLine(Active);
			}
			
			StreamWriter sw = new StreamWriter(strFileName);
			sw.WriteLine(Status);
			sw.WriteLine(Server);
			sw.WriteLine(Team);
			sw.WriteLine(User);
			sw.WriteLine(Logon);
			sw.WriteLine(LastActive);
			sw.WriteLine(Active);
			sw.Close();
		}
		else
		{
			// Status=No User Logon
			// Server=pgxpvmup111
			// Team=TV	
			Team = "Team=" + TEAM;
			Server = "Server=" + strHostname.ToString();
			
			if (Debug == 1)
			{
				Console.WriteLine("Status=No User Logon");
				Console.WriteLine(Server);
				Console.WriteLine(Team);
			}

			StreamWriter sw = new StreamWriter(strFileName);
			sw.WriteLine("Status=No User Logon");
			sw.WriteLine(Server);
			sw.WriteLine(Team);
			sw.Close();		
		}	
		
		FileInfo pFile = new FileInfo(strFileName);
		string strNewFileName = pFile.Directory + "\\" + strHostname + ".txt";
		
		Console.WriteLine ("Finish processing {0} ... ", strHostname);
		pFile.CopyTo(strNewFileName, true);
		
		if (ServerMachine == 1)
		{
			Console.WriteLine ("Server executing the all alive workstation...");
			// Server to execute the process to read combine all the files
			Process ServerRun = new Process();
        		ServerRun.StartInfo.FileName = "cmd.exe";
        		ServerRun.StartInfo.Arguments = "/c perl ServerProcess.pl";
        		ServerRun.StartInfo.UseShellExecute = false;
        		ServerRun.StartInfo.RedirectStandardOutput = true;
        		ServerRun.Start();
        		
        		string strServerRun = ServerRun.StandardOutput.ReadToEnd();
        		
        		Console.WriteLine (strServerRun);
        		ServerMachine = 0;
        	}
	}
}