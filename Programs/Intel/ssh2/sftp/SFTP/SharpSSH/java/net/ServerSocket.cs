using System;
using System.Net;
using System.Net.Sockets;

namespace SharpSsh.java.net
{
	/// <summary>
	/// Summary description for ServerSocket.
	/// </summary>
	public class ServerSocket : TcpListener
	{
		public ServerSocket(int port, int arg, InetAddress addr) : base(addr.addr, port)
		{
			this.Start();
		}

		public SharpSsh.java.net.Socket accept()
		{
			return new SharpSsh.java.net.Socket( this.AcceptSocket() );
		}

		public void close()
		{
			this.Stop();
		}
	}
}
