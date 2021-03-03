//
//  UFCom_Help.ipf 
// 
#pragma rtGlobals=1							// Use modern global access method.

#pragma IndependentModule=UFCom_
#include "UFCom_Constants"

//  HELP FILES
// This example uses the topic[subtopic] form.
// DisplayHelpTopic "Waves[Waveform Arithmetic and Assignment]"
//	Checking Links	chapter 1 volume II-18
//	You can get Igor to check your links as follows:
//	1. Open your Igor help file and any other help files that you link to.
//	2. Activate your help window and click at the very start of the help text.
//	3. Press shift-option-command-H ) or Ctrl+Alt+H ). Igor will check your links from where you clicked to the 
//	    end of the file and note any problems by writing diagnostics to the history area of the command window.
//	4. When Igor finishes checking, if it found bad links, kill the help file and open it as a notebook.
//	5. Use the diagnostics that Igor has written in the history to find and fix any link errors.
//	6. Save the notebook and kill it.
//	7. Open the notebook as a help file. Igor will compile it.
//	8. Repeat the check by going back to step 1 until you have no bad links.
//	You can abort the check by pressing command-period ) or Ctrl-Break ) and holding it for a second.
//	The diagnostic that Igor writes to the history in case of a bad link is in the form:
//		Notebook $nb selection={(33,292), (33,334)} …
//	This is set up so that you can execute it to find the bad link. At this point, you have opened
//	the help file as a notebook. Assuming that it is named Notebook0, execute
//		string /G nb = "Notebook0"
//	Now, you can execute the diagnostic commands to find the bad link and activate the notebook.
//	Fix the bad link and then proceed to the next diagnostic. It is best to do this in reverse order, 
//		starting with the last diagnostic and cutting it from the history when you have fixed the problem.
//	When fixing a bad link, check the following:
//		A link is the name of a topic or subtopic in a currently open help file. Check spelling.
//		There are no extraneous blue/underlined characters, such as tabs or spaces, before or after the link. 
//		(You can not identify the text format of spaces and tabs by looking at them. 
//		Check them by selecting them and then using the Set Text Format dialog.)
//		There are no duplicate topics. If you specify a link in topic[subtopic] form and there
//		are two topics with the same topic name, Igor may not find the subtopic.
 

//===============================================================================================================================
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//===============================================================================================================================
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
