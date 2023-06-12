// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Overthink
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    logo                                                                                                                                                                                                                                                                                                            //
//    ENDEES                                                                                                                                                                                                                                                                                                          //
//    HOMEPRIVACYCONTACTDONATE                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    Result                                                                                                                                                                                                                                                                                                          //
//    Download result: banner.txt (46.15 KB)                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                    //
//    Remember to use a monospaced font to show this banner.                                                                                                                                                                                                                                                          //
//    Preview                                                                                                                                                                                                                                                                                                         //
//    WNKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKx'.lOXXKkxdxxd;.,xOOOOOOOOOOKXNXKOkOx:.'loooooooooooooooooooooooooooooooooooooooooolloooooooloooooloooodddddddddddddddddddddooooood0XkoooooooooddddxOXKOkkkkkkkkkkkxdddddddddddddxdddddddddddddddddddddddddddddddddddddddxxddddxkOOOOOOOOkkO0XNNKOkxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    WXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0xok00kxddddddo;.;dOOOOOO0KXXK0OOOOOOx;.,cooooooooooooooooooooooooooooooooooooooooooloooooolooooolloooodddddddddddddddddddddooooodOKOooooooooooodxxOXXOkkkkkkkkkkkkxxddddddddddddddddddddddddddddddddddddddddddddddddddddddddddxkOOOOOOOO0KXXK0Okxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    NXKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXNNXd,:dddddddddd:.,dOOKKXXK0OOOOOOOOOOkc.'coooooooooooollooooooooooooooooooooooooooooooooooololc,..,:lddddddddddddddddddddddoooodOXOoloooolooooddk0XXOkkkkkkkkkkkkkkxddddddddddddddddddddddddddddddddddddddddddddddddddddddddddxkkOOOO0KXXK0kkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    NKKKKKKKKKKKKKKKKKKKKKKKKKKXXNNXXKKOc.,odddddddddl:d0XKK0OOOOOOOOOOOOOOko'.:looooooooooooooooooooooooooooooooooooooooooolloolc,.;;..,,;coddddddddddddddddddoooodOXkoooooooooddddx0XKOkkkkkkkkkkkkkkkkxddddddddddddddddddddddddddddddddddddddddddddddddddddddddddxO0KXXXKOkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    XKKKKKKKKKKKKKKKKKKKKKKKXXNNXXKKKKKK0l.'ldxxxdxO0KKkclxOOOOOOOOOOOOOOOOOOd,.;loooooooooooooooooooooooooooooooooooooooloooolc,':kNK:;OOl;,;codddddddddddddddoood0Kkoooooodddddddx0XKkkkkkkkkkkkkkkkkkkxxdddddddddddddddddddddddddddddddddddddddddddddddddddddddxk0XXK0Okxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    XKKKKKKKKKKKKKKKKKKKKXXNNXXKKKKKKKKKK0d'.cdkO0KK0Oxo;.;xOOOOOOOOOOOOOOOOOOx;.,coooooooooooooooooooooloooooooooooolloooool:,,lONWWWk,oNWXOo:,,codddddddddddoood0Kkoooodddddddddx0XOxxkkkkkkkkkkkkkkkkkkxdddddddddddddddddddddddddddddddddddddddddddddddxdddxxO0KK00Oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    KKKKKKKKKKKKKKKKKKXXNNXXKKKKKKKKKKKKKKKkcoOKKOkxdxxdd:.,dOOOOOOOOOOOOOOOOOOkc.'cooooooloolooooooooooooloooooooooooooool;',l0NWWWMMXl,OWWWWNOo;,,coddddddddood0KkoodddddddddddkKXOxdxkkkkkkkkkkkkkkkkkkxxdddddddddddddddddddddddddddddddddddddddddddddddxkOKKK0kdddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    KKKKKKKKKKKKKKKXXNNXXKKKKKKKKKKKKKKKKXXNN0l:odddxxddddc''lkOOOOOOOOOOOOOOOOOko'.:loooooooooooooooooooooooolloooooooll;',oKWWWWWWWWW0;cXWWWWMWNOo:,,codddddod0XkddddddddddddxkKXOdddxxkkkkkkkkkkkkkkkkkkxxdddddddddddddddddddddddddddddddddddddddddddxk0KK0Oxdoooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    KKKKKKKKKKKKKXNNNXKKKKKKKKKKKKKKKKXNNNXXK0o.'ldddddddddl,.cxOOOOOOOOOOOOOOOOOOd,.;loolooooooooooooooooooooolloloool;';oKWWWWWWWWWWMWd,xWWWWWMWWWN0o:,,:cloxKXkxdddddddddddxkKKkxddddxkkkkkkkkkkkkkkkkkkkxdddddddddddddddddddddddddddddddddddddddxxO0KK0Oxdoooooooddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    KKKKKKKKKXXNNXXKKKKKKKKKKKKKKKKXNNNXKKKKKK0d,.cdddddddddo;.;xOOOOOOOOOOOOOOOOOOx;.'cooooolooooooooooooooooooolooc;':xXWWWWWNWWMWWWWWK:;0WWWWWMMWWWWN0oc:;l0KkddddddddddddxOXKkxddddddxkkkkkkkkkkkkkkkkkkxxdddddddddddddddddddddddddddddddddddxxOKKK0kdoooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    KKKKKKXXNNXXKKKKKKKKKKKKKKKXXNNXXKKKKKKKKKKKk;.;odddddddxd:.,oOOOOOOOOOOOOkOOOOOkc..coooooooooooooooooooolloolc,':kNWWWWWKd:lKWWWWWWWk,lNMMMWXkxKNWWWWWNKK0l,:odddddddddxOXKxdddddddddxkkkkkkkkkkkkkkkkkkxddddddddddddddddddddddddddddddddxk0KK0Oxdooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    KKKXXNNXXKKKKKKKKKKKKKKKXXNNXXKKKKKKKKKKKKKKKOc.,odddddxxxdc''lkOOOOOOOOOOOOOOOOOko'.:looooooooooooooooooool:''cONWWWWWKo,''.lNWWWWWWNl,kWWWWK:.':d0NWWWWWN0d:,,:ldddddx0X0xddddddddddxkkkkkkkkkkkkkkkkkkkxddddddddddddddddddddddddddddxO0KK0Oxdoooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    XXNNXXKKKKKKKKKKKKKKXXNNNXKKKKKKKKKKKKKKKKKKKK0o''lddddxxdddl,.cxOOOOOOOOOOOOOOOOOkd,.,loooooooooooooooool:',cONMWWWW0o,':ll,'kWWWWWWW0;cKWWWWk',:;,cONNWWWWWNKdc,,:ldx0X0xddddddddddddxkkkkkkkkkkkkkkkkkkxxdddddddddddddddddddddddxkO0KK0kddooooooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    NXXKKKKKKKKKKKKKKXXNNXXKKKKKKKKKKKKKKKKKKKKKKKK0d,.cdddddddddo;.;xOOOOOOOOOOOOOOOOOOx:.'colloolloooooool:,,o0WWWWWNOl,,:lddoc.:XMMWWWWWd,dWMWWNl'lxdx0XkloONWWWWWKxc,cOXOxdddddddddddddxxkkkkkkkkkkkkkkkkkkxxdddddddddddddddxxddxk0KKKOxdooooooooooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    KKKKKKKKKKKKKKXNNNXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk;.;dxxxddddxd:.,dOOOOOOOOOOOOOOOOOOkc..:lolooooooloc;';dKWWWWWNOc',:oxkOOdl;'dWWWWWWWXc;0WWWW0;,d0XOdoc;,;oOXWMWWWKKKo,:ldddddddddddddxxkkkkkkkkkkkkkkkkkkxdddddddddddddddxxO0KK0kxdoooooooooooooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdo    //
//    KKKKKKKKKKKXNNNXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOc.,oxxxxddl:,..'lkOOOOOOOOOOOOOOOOOko'.;loooooooc,.;xXWWWWWXx;',coxO0000koc',0WMWWWWWO;lNMWWWd,dXk;',;clc;,;lkXWWWWWKxc;,;ldddddddddddxxkkkkkkkkkkkkkkkkkxxdddddddddddxkO0KK0kxdooooooooooooooooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo;.    //
//    KKKKKKKXXNNNXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0o''ldoc;',:okx;.cxOOOOOOOOOOOOOOOOOOd,.,looooc,';xXWWWWWXx;',coxO000000Odo:.lNWWWWWWNo,kWWWWXO00x:'...,:clc;,:kNNWWWMWXxc;,;lddddddddxxkkkkkkkkkkkkkkkkkkxddddddddxk0KK0Okddoooooooooooooooooooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdc..c    //
//    KKKKXNNNXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0d,.'',cdO0KKKOc.;xOOOOOOOOOOOOOOOOOOx:.'clc,'ckNWWWWWXd;';coxO000000000kdo,'kWWWWWWWK::KWWWWNdcdl:,.....';clx0kcckKWMMWWXkl;,;lodddddxxkkkkkkkkkkkkkkkkkxxddddxk0KK0Oxdoooooooooooooooooooooooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo..o0    //
//    KXNNNXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKkoox0KKKKKKKK0o',dOOOOOOOOOOOOOOOOOOkl..',lONWWWWWKo;';ldkO000000000000xdl':KWWWWWWWx,dNWWWNo'cdo:'......'dKkoc;,;cxKNWWMWXkl;,;codddxkkkkkkkkkkkkkkkkkkxxdddxkOkxdooooooooooooooooooooooooooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxc.,k0    //
//    NNXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0d,'lkOOOOOOOOOOOOOOOOkl''l0WMWWWN0l,':ldk000000000000000Odo;'dWWWWWWMXc;OWWWWK;'odo;.....,d0o'',:ll:,,:dKNWWWWXkl;,;cddxkkkkkkkkkkkkkkkkkkxxdddddooooooooooooooooooooooooooooooooooooooooooooxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl..d0    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk;'ckOOOOOOOOOOOOOxl,,oKWWWWWNOc'':odxO00000000000000000kdl,;0WWWWWWWO:xWWWWWx';odc'...,d0l'....';cll:,,:d0NWWWWXOl;,;cdkkkkkkkkkkkkkkkkkkxdooooooooooooooooooooooooooooooooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:.'d    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOc.;xOOOOOOOOOOxc,;dKWWWWWNOc'':oxk00000000000000000000Oxdc'lNWWWWWWNK0XWWWWXc',cd:..;xOc'........',:ll:,,:d0NWWWWXOo;,:lxkkkkkkkkkkkkkxxdoooooooooooooooooooooooooooooooooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdc'.    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0o',dkOOOOOkdc,:xXWWWWWNk:..coxO00000000000000000000000Oxo,'kWWWWWWWNocKWWWWO,.,ol,;kO:.............',:ll:,,:oONWWWWNOo:,;ldkkkkkkxxxxddddooooooooooooooooooooooooooooooooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdl    //
//    XKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0d,'lkOOkd:,:kNWWWWWXx:,;''oO00000000000000000000000000kdl':XWWWWWWWk,oNWWWNd'.:ddOk:.................',:llc;,;oONWWWWNOo:,;ldxxxxdddddddoooooooooooooooooooooooooooooooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    NKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk;'cxo;,cONWWWMWKd;,cxOkxk000000000000000000000000000Oxd;'dWMMWWWWXc,OWWWMKk:'xXk;.....................',:llc,,;lOXWWWWNOo:,;codxdddddddooooooooooooooooooooooooooooooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    NKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOc.',lONWWWWWKo,,lxO0KKK0O000000000000000000000000000kxl';0WWWWWWWO;cXWWWWWOd00o,........................',;clc;,;lkXWWWWN0o:,;codddddddoooooooooooooooooooooooooooooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    NXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0d;,oKWWWWWW0o,,lkO00KK0KK0OO00000000000000000000000000kd:'oNWWWWWWNd,xWWWWWWXdldc'...........................';coc;',lkXWWMWN0d:,,:odxddoooooooooooooooooooooooooooooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    WNKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOo;;dKWWWWWNOl,;okO00KKKKKKKK0OO0000000000000000000000000OxolONWWWWWWWK::KWMWWWK;'oo;.............................',;:c:,,;cxKWWWWN0d:,,:oddoooooooooooooooooooooooooooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    dollllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllc,;dXWWWWWNOc,:okO0KKKKKKKKKKKK00O00000000000000000000000K0kkKkxXWWWWWWWk,oNMMMMWd';dc'................................';:cc:,,cxKNWMMN0dc,,:looooooooooooooooooooooooooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    lllcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc,..;xXWWWWWXx:..lk00KKKKKKKKKKKKKKKK0OO00000000000000000000000KXKc'dWWWWWWWNocKMWWWMXc.cd:...................................';:ll:,,:d0NWWWNKdc,,;cooooooooooooooooooooooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    WWNXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0kc;ckNWWWWWXx:,cc;lOKKKKKKKKKKKKKKKKKKK0OO000000000000000000000KNKko';0WWMWWWWXKKNWWWWWO,,ol,.....................................';cll:,,:d0NWWWNKxc,';coooooooooooooooooooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    WWWXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0x:;lONWMWWWXd;;lkK0OO00KKKKKKKKKKKKKKKKKKK0OO0000000000000000000XNN0kd:.lNMWWWWWW0cxWWWWWNo.:dc'.....................................'.';cll:,,:oONWMWWKxc,,;coooooooooooooooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    WWWNXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0d;,l0WWWWWWKo;;oOKKKKK00O0KKKKKKKKKKKKKKKKKKK00O00000000000000000XNXK0Oxo,'kWWWWWWWXc;0WWWWWK;'lo;..........................................',:llc;,:oONWWWWKxc,';cloooooooooooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    WWWWNKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOo;;oKWWWWWN0l;;dOKKKKKKKK00O0KKKKKKKKKKKKKKKKKKKK0OO00000000000000XNXK000kdl'cXWWWWWWWk,oKNWWWWx';dl,......................................'.....',:loc;,;oOXWWWWKxc,',cloooooooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    WWWWNXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOo;;dKWWWWWNOc';d0KKKKKKKKKKK00000KKKKKKKKKKKKKKKKKKK000000000000000XNXK0000Oxd;'dWWWWWWWNo,ckWMWWXl.cd:'..............................................';:llc;,;lkXWWWWXkl;',cloooooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    WWWWWNKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0kl;:xXWWMWWNOc,.'dKKKKKKKKKKKKKKK00O0KKKKKKKKKKKKKKKKKKK00O0000000000XNXK0K0000kxl':KWWWWWWW0;.:XMWWW0,'oo;.................................................',:llc;,;lkXWMMWXkl;',clooooooooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    WWWWWWXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0kc,:kNWWWWWNkc,cxlckKKKKKKKKKKKKKKKK00O0KKKKKKKKKKKKKKKKKKK00O0000000KXNXK00K0000OxdokXWWWWWWWWd,,dWWWMNd.;oc'...................................................',;:cc;',cxKWWMWXkl;',:looooooooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    WWWWWWNXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0x:,ckNWWWWWXx:;lkKKOO0KKKKKKKKKKKKKKKKK00O00KKKKKKKKKKKKKKKKKKK0O00000KXNXK000000000OkKOlOWWWWWWMXOc;0WWWMK:.cl;...................................................'...,;clc;',cxKWWMWXOl;,,:looooooodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    WWWWWWWNXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0d:;lONWWWWWKd;,lOKKKK0O0KKKKKKKKKKKKKKKKKKK0O00KKKKKKKKKKKKKKKKKKK0OO00KXNXK000000000KKXKo.:XWWWWWWWWO,lNWWWWk',lc,.....................................................'..',;:cc;,,cd0NWWWXOl;',:loooddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    WWWWWWWWNXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOd:;o0WMWWWWKo;;oOKKKKK00O0KKKKKKKKKKKKKKKKKKKK0000KKKKKKKKKKKKKKKKKKK00O0XNXK000000000KXNXko;'xWWWWWWWWNo,kWWWWNl.;l:'..........................................''...............',:cc;,,:d0NWWWNOo:,,:ldxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    WWWWWWWWWNXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOo;;dKWWWWWW0o,;oOKKKKKK000O0KKKKKKKKKKKKKKKKKKKKK00O0KKKKKKKKKKKKKKKKKKK00XNXK000000000KXNX0koc';0WWWWWWWWK;:KWWWW0;'cl;..........................................''''................',:cc;,':o0NWWWNOo;,;cdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    WWWWWWWWWWNXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOl,;xXWWWWWN0l;:d0KKKKKKKKKK0O0KKKKKKKKKKKKKKKKKKKKKK00O0KKKKKKKKKKKKKKKKKKKNNK0000000000KXNXK0Odl;.lNWWWWWWWWx,oNWWWWx';lc'................................................................',:cc:,';oONWWWNOo:,,coxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    WWWWWWWWWWWNXKKKKKKKKKKKKKKKKKKKKKKKKKKK0kl;:xXWWWWWNOc;cx0KKKKKKKKKKKK0O0KKKKKKKKKKKKKKKKKKKKKKKK0O00KKKKKKKKKKKKKKKKNNX00O0000000KNNXK000xl:.'OWWWWWWWWXc;OWWWWXc.cl;'..................................................................',:cc:,,;oOXWMWN0o:,,cdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    WWWWWWWWWWWWNKKKKKKKKKKKKKKKKKKKKKKKKK0xc;cONWWWWWXk:,ck0KKKKKKKKKKKKKK0O0K0KKKKKKKKKKKKKKKKKKKKKKK0000KKKKKKKKKKKKKKNNXKK00O00000KNNXK0000Ooc;.cXWWWWWWWWO;cXWWWWO,,ll,.....................................................................',;cc:,,;lkXWWWN0:.cxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    NNNNNNNNNNNNNXK000000000000000000000Od:;lONWWWWWXx:':x0KKKKKKK000000KK00O0000KKKKKK00KKKKKKKK0KK00KK00O0KKKKKKKKKKKKNNXKKKK00O000KNNK0000000kl:'.dWWWWMWWWNo,xWWWWNo.;l:'......................................'................................',:llc;,;lkXWWK;'oxxddddddxxxxxdxxddddxxddxxdddddddddddxxxxd    //
//    oooooooooooooollcccccccccccccccccc:,',l0WMWWWWXx:'.;lxO0000000000000000OO00000000000000000000000000000OO00KKKKKKKKKNNKKKKKKKK0OOKNNK00000000Ol,'.;0WWWMWWWWK::KWWWWK;.,;'..........................................................................',,;;,'.cKWWx',:ccccccccccccccccccccccccccccccccccccccccc    //
//    KXKKKKXKKKKKKKKK0OOOOOOOOOOOOOOOxc',oKWWWWWWKd::okOOO000KK0000000000K000O0000000000000000000K00000000000O0KKKKKKKXNNKKKKKKKKKK0KNNKKK0KKK0K00Okxc'oNWWWWWWMWk,oNWWWWk';xd;'....'''.........'..''.''..''...................................''...........,oOl'dNMXc'd00000000000000000000000000000000000000000    //
//    WWWWWWWWWWWWWWWWWNXKXKKKKKKKKKOo;:dKWWWWWW0l;:d0KKKKKKKKKKKKKKKKKKKKKKK0O0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0O00KKKKXNNKKKKKKKKKKKXNX00KKKKKKKKKKKK0k;'kWWWWWWWMXl,OWWWWNl'oOd,.''''''..''''''''''''''''''''..''''''.................'''''....''''..........:O0;;0WWO,:0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    WWWWWWWWWWWWWWWWWWNXKKKXKKKKOl;:xXWWWWWN0l,:x0KKKKKKKKKKKKKKKKKKKKKKKKK0O0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0OO0KKXNNKKKKKKKKKKKXNXK0O0KKKKKKKKKKKK0o'cXWWWWWWWW0;cXWWMW0;;kkc'''...''''''''..''''''''''..''''''.'''........'........''...''''''...........'dKd'lNWNo'dKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    WWWWWWWMMWWWWWWWWWWNXXKKXKkc,:kNWWWWWNOc,:xKKKKKKKKKKKKKKKKKKKKKKKKKKKK0O0KKKKKKKKKKKKKKKKKKKKKKKKKKKK                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract THINK is ERC721Creator {
    constructor() ERC721Creator("Overthink", "THINK") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x5133522ea5A0494EcB83F26311A095DDD7a9D4b6;
        (bool success, ) = 0x5133522ea5A0494EcB83F26311A095DDD7a9D4b6.delegatecall(abi.encodeWithSignature("initialize(string,string)", name, symbol));
        require(success, "Initialization failed");
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}