// Rev. 09/07/2003
divs = new Array();
divs[0] = "PGTMM";
divs[1] = "TVPV";
divs[2] = "TP1";
divs[3] = "LIM";
divs[4] = "Int";
divs[5] = "TP2";

tls = new Array();
tls[0] = "BS";
tls[1] = "IL";
tls[2] = "CT";
tls[3] = "SK";
tls[4] = "Anna";
tls[5] = "EY";

function Toggle(item) {
   obj=document.getElementById(item);
   visible=(obj.style.display!="none")
   key=document.getElementById("x" + item);
   if (visible) {
     obj.style.display="none";
     key.innerHTML="<img src='images/folder.gif' width='16' height='16' hspace='0' vspace='0' border='0'>";
   } else {
      obj.style.display="block";
      key.innerHTML="<img src='images/textfolder.gif' width='16' height='16' hspace='0' vspace='0' border='0'>";
   }
}

function Expand() {
//   divs=document.getElementsByTagName("DiV");
   pde = new Array();
   pde[0] = "PDE";
   pde[1] = "EJ";
   for (i=0;i<pde.length;i++) {
     div=document.getElementById(pde[i]);
     div.style.display="block";
     key=document.getElementById("x" + pde[i]);
     key.innerHTML="<img src='images/textfolder.gif' width='16' height='16' hspace='0' vspace='0' border='0'>";
   }
   for (i=0;i<divs.length;i++) {
     tl =document.getElementById(tls[i]);
     tl.style.display="block";
     key=document.getElementById("x" + tls[i]);
     key.innerHTML="<img src='images/textfolder.gif' width='16' height='16' hspace='0' vspace='0' border='0'>";
     div=document.getElementById(divs[i]);
     div.style.display="block";
     key=document.getElementById("x" + divs[i]);
     key.innerHTML="<img src='images/textfolder.gif' width='16' height='16' hspace='0' vspace='0' border='0'>";
   }
}

function Collapse() {
//   divs=document.getElementsByTagName("DiV");
   for (i=0;i<divs.length;i++) {
     tl =document.getElementById(tls[i]);
     tl.style.display="none";
     key=document.getElementById("x" + tls[i]);
     key.innerHTML="<img src='images/folder.gif' width='16' height='16' hspace='0' vspace='0' border='0'>";
     div=document.getElementById(divs[i]);
     div.style.display="none";
     key=document.getElementById("x" + divs[i]);
     key.innerHTML="<img src='images/folder.gif' width='16' height='16' hspace='0' vspace='0' border='0'>";
   }
}

