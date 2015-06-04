////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                              OpenCollar - garble                               //
//                                 version 3.988                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

//original by Joy Stipe

//OpenCollar MESSAGE MAP
// messages for authenticating users
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
//integer COMMAND_EVERYONE = 504;
//integer COMMAND_OBJECT = 506; 
//integer COMMAND_RLV_RELAY = 507;
integer COMMAND_SAFEWORD = 510;
//integer COMMAND_BLACKLIST = 520;
//integer COMMAND_WEARERLOCKEDOUT = 521;

// messages for storing and retrieving values in the settings script
integer LM_SETTING_SAVE = 2000;
integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
integer LM_SETTING_EMPTY = 2004;


// messages for creating OC menu structure
integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

// messages for RLV commands
integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

string g_sParentMenu = "Apps";
string GARBLE = "☐ Garble";
string UNGARBLE = "☒ Garble";

string WEARERNAME;

string SAFE = "RED";
key g_kWearer;
string gsPref;
string gsFir;
integer giCRC;
integer giGL;
integer bOn;
integer g_iBinder;
key g_kBinder;

/*
integer g_iProfiled;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to 
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}
*/

Notify(key _k, string _m, integer NotifyWearer)
{
    if (_k == g_kWearer) llOwnerSay(_m);
    else
    {
        if (llGetAgentSize(_k)) llRegionSayTo(_k, 0, _m);
        else llInstantMessage(_k, _m);
        if (NotifyWearer) llOwnerSay(_m);
    }
}

string GetScriptID()
{
    // strip away "OpenCollar - " leaving the script's individual name
    list parts = llParseString2List(llGetScriptName(), ["-"], []);
    return llStringTrim(llList2String(parts, 1), STRING_TRIM) + "_";
}

string PeelToken(string in, integer slot)
{
    integer i = llSubStringIndex(in, "_");
    if (!slot) return llGetSubString(in, 0, i);
    return llGetSubString(in, i + 1, -1);
}

SetPrefix(string in)
{
    if (in != "auto") gsPref = in;
    else
    {
        string sName = llKey2Name(g_kWearer);
        integer i = llSubStringIndex(sName, " ") + 1;
        string init = llGetSubString(sName, 0, 0) + llGetSubString(sName, i, i);
        gsPref = llToLower(init);
    }
    //Debug("Prefix set to: " + gsPref);
}

string garble(string _i)
{
    // return punctuations unharmed
    if (_i == "." || _i == "," || _i == ";" || _i == ":" || _i == "?") return _i;
    if (_i == "!" || _i == " " || _i == "(" || _i == ")") return _i;
    // phonetically garble letters that have a rather consistent sound through a gag
    if (_i == "a" || _i == "e" || _i == "i" || _i == "o" || _i == "u" || _i == "y") return "eh";
    if (_i == "c" || _i == "k" || _i == "q") return "k";
    if (_i == "m") return "w";
    if (_i == "s" || _i == "z") return "shh";
    if (_i == "b" || _i == "p" || _i == "v") return "f";
    if (_i == "x") return "ek";
    // randomly garble everything else
    if (llFloor(llFrand(10.0) < 1)) return _i;
    return "nh";
}

bind(key _k, integer auth)
{
    bOn = TRUE;
    g_iBinder = auth;
    g_kBinder = _k;
    llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + UNGARBLE, "");
    llMessageLinked(LINK_SET, MENUNAME_REMOVE, g_sParentMenu + "|" + GARBLE, "");
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, GetScriptID() + "Binder=" + (string)_k + "," + (string)auth, "");
    // Garbler only listen to the wearer, as a failsafe
    giGL = llListen(giCRC, "", g_kWearer, "");
    llMessageLinked(LINK_SET, RLV_CMD, "redirchat:" + (string)giCRC + "=add,chatshout=n,sendim=n", NULL_KEY);
    if (llGetAgentSize(_k) != ZERO_VECTOR)
    {
        if (_k != g_kWearer) llOwnerSay(llKey2Name(_k) + " ordered you to be quiet");
        Notify(_k, WEARERNAME + "'s speech is now garbled", FALSE);
    }
    llMessageLinked(LINK_THIS, auth, "menu "+g_sParentMenu, _k);
}

release(key _k ,integer auth)
{
    bOn = g_iBinder = FALSE;
    g_kBinder = NULL_KEY;
    llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + GARBLE, "");
    llMessageLinked(LINK_SET, MENUNAME_REMOVE, g_sParentMenu + "|" + UNGARBLE, "");
    llMessageLinked(LINK_SET, LM_SETTING_DELETE, GetScriptID() + "Binder", "");
    llListenRemove(giGL);
    llMessageLinked(LINK_SET, RLV_CMD, "chatshout=y,sendim=y,redirchat:" + (string)giCRC + "=rem", NULL_KEY);
    if (llGetAgentSize(_k) != ZERO_VECTOR)
    {
        if (_k != g_kWearer) llOwnerSay("You are free to speak again");
        Notify(_k, WEARERNAME + " is allowed to talk again", FALSE);
    }
    llMessageLinked(LINK_THIS, auth, "menu "+g_sParentMenu, _k);
}

integer UserCommand(integer iNum, string sStr, key kID)
{
    if (iNum < COMMAND_OWNER || iNum > COMMAND_WEARER) return FALSE;
    if (llToLower(sStr) == "settings")
    {
        if (bOn) Notify(kID, "Garbled.", FALSE);
        else Notify(kID, "Not Garbled.", FALSE);
    }
    else if (sStr == "menu " + GARBLE || llToLower(sStr) == "garble on")
    {
        if (bOn && g_kBinder == kID) Notify(kID, "I can't garble 'er any more, Jim! She's only a subbie!", FALSE);
        else if (iNum > g_iBinder) bind(kID, iNum);
    }
    else if (sStr == "menu " + UNGARBLE || llToLower(sStr) == "garble off")
    {
        if (iNum <= g_iBinder) release(kID,iNum);
        else Notify(kID, "Sorry, " + llKey2Name(kID) + ", the garbler can only be released by someone with an equal or higher rank than the person who set it.", FALSE);
    }
    else return FALSE;
    return TRUE;
}

default {
    on_rez(integer _r) {
        if (llGetOwner() != g_kWearer) llResetScript();
    }
    
    state_entry() {
        //llSetMemoryLimit(65536);  //this script needs to be profiled, and its memory limited
        g_kWearer = llGetOwner();
        WEARERNAME = llKey2Name(g_kWearer);  //quick and dirty default, will get replaced by value from settings
        
        giCRC = llRound(llFrand(499) + 1);
        if (bOn) release(g_kWearer,0);
        llMessageLinked(LINK_THIS, LM_SETTING_REQUEST, "listener_safeword", "");
        llMessageLinked(LINK_THIS, LM_SETTING_REQUEST, GetScriptID() + "Binder", "");
        //Debug("Starting");
    }
    listen(integer _c, string _n, key _k, string _m)
    {
        if (_c == giCRC)
        {
            if (_k == g_kWearer)
            {
                string sw = _m;
                integer i = llStringLength(WEARERNAME);
                if (llGetSubString(sw, 0, 1) == "((" && llGetSubString(sw, -2, -1) == "))")
                    sw = llGetSubString(sw, 2, -3);
                if (llSubStringIndex(sw, gsPref) == 0)
                {
                    integer i = llStringLength(sw);
                    sw = llGetSubString(sw, i, -1);
                }
                if (sw == SAFE) // Wearer used the safeword
                {
                    llMessageLinked(LINK_SET, COMMAND_SAFEWORD, "", "");
                    llOwnerSay("You used your safeword, your owner will be notified you did.");
                    return;
                }
            }
            string sOut;
            integer iL;
            integer iR;
            for (iL = 0; iL < llStringLength(_m); ++iL)
                sOut += garble(llToLower(llGetSubString(_m, iL, iL)));
            string sMe = llGetObjectName();
            llSetObjectName("");
            llWhisper(0, "/me " +WEARERNAME+" mumbles: " + sOut);
            llSetObjectName(sMe);
            return;
        }
    }
    link_message(integer iL, integer iM, string sM, key kM)
    {
        if (UserCommand(iM, sM, kM)) return;
        if (iM == MENUNAME_REQUEST && sM == g_sParentMenu)
        {
            if (bOn) llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + UNGARBLE, "");
            else llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + GARBLE, "");
        }
        else if (iM == RLV_REFRESH)
        {
            if (bOn) llMessageLinked(LINK_SET, RLV_CMD, "redirchat:" + (string)giCRC + "=add,chatshout=n,sendim=n", NULL_KEY);
            else llMessageLinked(LINK_SET, RLV_CMD, "chatshout=y,sendim=y,redirchat:" + (string)giCRC + "=rem", NULL_KEY);
        }
        else if (iM == RLV_CLEAR) release(kM,iL);
        else if (iM == LM_SETTING_RESPONSE)
        {
            list lP = llParseString2List(sM, ["="], []);
            string sT = llList2String(lP, 0);
            string sV = llList2String(lP, 1);
            if (sT == GetScriptID() + "Binder")
            {
                lP = llParseString2List(sV, [","], []);
                g_kBinder = (key)llList2String(lP, 0);
                g_iBinder = (integer)llList2String(lP, 1);
                bind(g_kBinder, g_iBinder);
            }
            else if (sT == "listener_safeword") SAFE = sV;
            else if (sT == "Global_prefix")
            {
                if (sV == "") sV = "auto";
                SetPrefix(sV);
            } else if (sT=="Global_WearerName") WEARERNAME=sV;
        }
        else if (iM == LM_SETTING_EMPTY && sM == GetScriptID() + "Binder") release(kM,iL);
        else if (iM == LM_SETTING_SAVE) // Have to update the safeword if it is changed between resets
        {
            integer iS = llSubStringIndex(sM, "=");
            string tok = llGetSubString(sM, 0, iS - 1);
            string val = llGetSubString(sM, iS + 1, -1);
            if (tok == "listener_safeword") SAFE = val;
            else if (tok == "Global_prefix")
            {
                if (val == "") val = "auto";
                SetPrefix(val);
            }
        }
        if (iM == COMMAND_SAFEWORD) release(kM,iL);
    }
    
/*
    changed(integer iChange) {
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled) {
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
    }
*/
}
