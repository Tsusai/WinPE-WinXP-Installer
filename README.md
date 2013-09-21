Work-WinXPInstaller
===================

Made to make things easier at work  
Think about this as a XP version of Windows Vista/7 Setup.  
Has ability to apply OEM Info for legal auto activation
WimLauncher is set as the shell in boot.wim  

Example ISO layout (I hope this makes sense) 
ROOT  
L---BOOT (Standard Windows 7 PE)  
L---SOURCES  
  L---OEMFILES  
    L---DELL  
      L---OEMBIOS.BI_  
      L---OEMBIOS.CA_  
      L---OEMBIOS.DA_  
      L---OEMBIOS.SI_  
  L---PARTITIONWIZARD (Works great in WinPE)  
  L---BOOT.WIM (WinPE with WIMLauncher inside)  
  L---BOOTSECT.EXE (Sets partition for NTLDR)  
  L---IMAGEX.EXE (Applies WIM)  
  L---INSTALL.WIM (Contains captured XP WIMS after running something like 
                   D:\i386\winnt32.exe /unattend:J:\i386\unattend.txt /syspart:J: /tempdrive:J: /makelocalsource  
                   from a XP CD within a WIM environment.  Yes, you can totally install XP from a Windows 7 DVD  
                   if you wanted.)  
  L---SETUP.EXE (This program)  
L--- (This Program)  


