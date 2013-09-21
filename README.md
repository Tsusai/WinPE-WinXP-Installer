Work-WinXPInstaller
===================

Made to make things easier at work  
Think about this as a XP version of Windows Vista/7 Setup.  
Has ability to apply OEM Info for legal auto activation
WimLauncher is set as the shell in boot.wim  
Just the core code here as to not anger corporate entities

Example ISO layout (I hope this makes sense) 
\BOOT\ (Standard Windows 7 PE boot folder)  
\SOURCES\  
\SOURCES\OEMFILES\DELL\OEMBIOS.BI_  
\SOURCES\OEMFILES\DELL\OEMBIOS.CA_  
\SOURCES\OEMFILES\DELL\OEMBIOS.DA_  
\SOURCES\OEMFILES\DELL\OEMBIOS.SI_  
\SOURCES\PARTITIONWIZARD\ (Minitool Partition wizard works great in WinPE)  
\SOURCES\BOOT.WIM (WinPE with WIMLauncher inside.  See winpeshl.ini)  
\SOURCES\BOOTSECT.EXE (Sets partition for NTLDR)  
\SOURCES\IMAGEX.EXE (Applies WIM)  
\SOURCES\INSTALL.WIM (Contains captured XP WIMS after running something like 
                   D:\i386\winnt32.exe /unattend:J:\i386\unattend.txt /syspart:J: /tempdrive:J: /makelocalsource  
                   from a XP CD within a WIM environment.  Yes, you can totally install XP from a Windows 7 DVD  
                   if you wanted.)  
\SOURCES\SETUP.EXE (This program)  
\SETUP.EXE(This Program)  


