// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: famorie and friends
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                      //
//                                                                                                                                      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk,';lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl.okc':OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl.oXXOc'cKWWMMMMMMMMMMN0OKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl.l0KXXk,':xNMMMMMMMMNo'',c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd.c000XNK:..oXMMMMMMMO':0k;'dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMx.:0000KNX0o.cKMMMMMWo.dXXKl.cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO:;cox0XWMMMMMMMMMMx.;OK000KXNNx';KMMMMX;'kK0KXd.:KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd.,ol::::ldOXWMMMMMx.;OK000000XNk';0MMMk.:KK00XNd.cXMMMMMMNXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.:0KKKOxoc:;:oONMMk.,OK0000000KNk',OWWo.dX0000XXo.lNMMMMO:,;lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0',k0000KKXK0xc,;xNO',kK00000000KNk',0K;,0K0000KNXc.xWMMX:'xk;'kWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc.l00000000KXX0o';l.,kK000000000KXk';:.lXK00000KN0,,0MWd.lNWK:'xWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk',k0000000000KXO:. ,kK0000000000KXx. ,OX000K000KNx.lXx':KXKN0,,0MMMMMXKNMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMNl.l000000000000K0l'cOK00000000000KKd;dKK0K000000XXc.,'lKXK0XWx.lNMMM0;.oNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNx:::cclodkO0XWMMMMM0,.x00000000000000OO0000000000000000KKK0000000000XOc:kXK0K0KNK;,0MMX:...xMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMK;.lxddoolc::::clxOXWx.;k00000000000000000K000OOOOkkkkOOO0000KK0000000KKKKK0000KNWl.xMXc.dx.cNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWd.;O00KKKXXK0kxoc:;:c'.cO00000000000Oxdlc:;;;;;;;;;;;;;;;;;:cldxO0KK00000K00000XWd.ck;,xNX;'0MMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMXc.c0000000000KKXKOdl,..o000000kdl:;,;:cloxkO000KKKKKK00Okxdlc;;,;coxO0K00000K0KNx..'l0XXNl.xMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMK:.l000000000000000K0xok00ko:,,,:ldO0XXNNNNNNNNWWWWWWWWWWWWWWNXOxo:,,:lxO0K0000XOllOKK0KNd.oWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWOloONMMK;.o000000000000000000xl;',:ok0KKKKKKKKKKKKKKXXXXXNNNNWWWWWWWWWWWNKOo:,,cdOKK00KKK0000KNx.lWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMO'':,:kNM0;.o00000000000000kl,';lx0KKKKKKKKKKKKKKKKKKKKKKKKKKXXXNNNWWWWWWWWWWNKxc,,cx0K0000000KNx.lWMMMMNKXWMMMMMMM    //
//    MMMMMMMMMMWo.lX0l,;d0O;.o00000000000d:',lk0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXNNWWWWWWWWWWKx:';oO0000K0KNd.oWMMM0:',oXMMMMMM    //
//    MMMMMMMMMMNc.l0KX0d:,:;..lO0000000d;.;d0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXNNWWWWWWWWNOl',lO0000XNl.xMMWO,,kl.dWMMMMM    //
//    MMMMMMMMMMWl.l0000KX0xl;..oO0000x;.;d0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKXNNNXKKKKKKKKKKKKKXXNNWWWWWWWWKo,'lOK0X0,;KXkc':ON0,;KMMMMM    //
//    MMMMMMMMMMMd.:0000000KKKOxk000kc.,d0KKKKKKKKK000000KKKKKKKKKKKKKKKXNWWWNXKKKKKKKKKKKKKKKXXNWWWWWWWWKo',d0Ko.':;;ckK0KXc.kMMMMM    //
//    MMMMMMMMMMMO',k00000000000000d,.cOKKK000000OOOOOOOOO0000000KKKKKKKKXXNXXKKKKKXXNNXXXKKKKKKKXNWWWWWWWN0:.:kd:cok0K00KKXl.dMMMMM    //
//    MMMMMMMMMMMX:.o000000000000Ol.,d00000OOOOOOOOOOOOOOOOOOOOOOO00000KKKKKKKKKKKNWWWWWWWNXKKKKKKKXNWWWWWWWXd''d0KK000KK0KXl.xMMMMM    //
//    MMMMMMMMMMMMk.,k0000000000k:.;k0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO000KKKKKKKNWWWWWWWWWWNXKKKKKKKXNWWWWWWWO;.l0K000KK0KK:.OMMWWW    //
//    MMMMMMMMMMMMNl.cO00000000k;.:kOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00KKKKKNWWWWWWWWWWWWNKKKKKKKKNNWWWWWWK:.cO0000K0Kk.'ooc:;:    //
//    MMMMMMMMMMMMMK:.o0000000k;.cOOO00000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO000KKXNWWWWWWWWWWWNXKKKKKKKKXNWWWWWWKc.c0K000K0c.':lxx,.    //
//    MMWNX0OOkkkOO0x'.d00000k;..:c::cccccllloddxkkOOO00OOOOOOOOOOOOOOOOOOOOOOO00KXNWWWWWWWWWWWNKKKKKKKKKXNWWWWWNo..l000000Ok0KXKo.;    //
//    oc::::::c::::::'.,x000Oc.':::::::::;;;,,,,,,,,;;clodxOOOOOOOOOOOOOOOOOOOOOO00KXNWWWWWWWWWNKKKKKKKKKKKNWWWNx'''.dK0000000KKo.;0    //
//     ,dO0KKXXKKKK0OkddO000o.,x0OOO000OOOOOOOOkkxdolc:;,,,,;:ldkO0OOOOOOOOOOOOOOOO00KXNNNNWNNXKKKKKKKKKKKKKXNNx',Ox.,kK000K0KKo.:KM    //
//    l',oO0000000000000000x'.oOOOOOOOOOOOOOOOOOOOOOOO0OOkxol:,'',:lxkOOOOOOOOOOOOOOO00KKKXXXKKKKKKKKKKKKKKKK0o.:0WXc.l00000K0c.lXMM    //
//    W0l',lk0000000000000Oc.:OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkdl:,'',:okOOOOOOOOOOOO00KKKKKK0OOOOO00KKKKK0d,'oXWWWO''kK0KKk;'xNMMM    //
//    MMWKo,'cx00000000000x'.dOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00Oxol;'':okOOOOOOOOOOxdol:;,''....',;cdkd;.;kNWWWWXc.o00Kx..,lloxO    //
//    MMMMWXd;':dO00000000c.;kOOOOOOOOOOOOOOOOOOOOOOOOkxddxxkOOOOOOOOO0Oko;''cdOO0Oxl:'..               ...;x0KNWWWWWd.:OKKOdddooc..    //
//    MMMWNXKkc..,d000000k,.lOOOOOOOOOOOOOOOOOOOOkdc;,,,,,,,,,:okOOOO0OOOOOxl,.;ll,.                      .:OKKXNWWWWO',kK00KKXXO:.;    //
//    Xd::::::::clx000000x.'x0OOOOOOOOOOOOOOOOOxc'';coxkkkkxdl:'':xOOOOOOOOO0Od;.                          .oKKKNWWWW0,'xK00KKk:':kN    //
//    0:.'oO0KKKK00000000o.,k0OOOOOOOOOOOOOOOkl.'cxOOOOOOOOOOOOkl'.lk0OOOOOOOO0x'                           c0KKXWWWWK;.xK0Kk:';kNMM    //
//    MNk;.;dO00000000000l.;kOOOOOOOOOOOOOOOk:.;xOOOOOO00OOOOOOO0x;.:xkOOOOOOOOOc.                         .c0KKXNWWW0,.xKkc.;kNMMMM    //
//    MMMNk:.;dO000000000l.;OOOOOOOOOOOOOOOOl.,k0OOkxolc:;;,,;;::c:...lOOOOOOOOOOl.                        .dKKKXNWWWO',dl',dXMMMMMM    //
//    MMMMMNO:.;dO0000000l.;kOOOOOOOOOOOOOOk,.lkdc;'..          'c:,. ,k0OOOOOOOOOd,.                      :OKKKKNWWWx..',dXMMMMMMMM    //
//    MMMMMMMNO:.;dO00000o.,k0OOOOOOOOOOOO0x'.,,';od'           ;0Xx' 'x0OOOOOOOOOOko,.                   ,kKKKKKNWWXc.'dXMMMMMMMMMM    //
//    MMMMMMMMMWO:.;dO000x''dOOOOOOOOOOOOOOk; 'ok0XXl.         .cKNx. ,k0OOOOOOOOOOOOko;.               .;kKKKKKKNWWk.'OWMMMMMMMMMMM    //
//    MMMMMMMMMMMNO:.;dO0O;.lOOOOOOOOOOOOOOOo.,kOkKXKo..      .l0Xx,.,lOOOOOOOOOOOOOOOOOxl;..         ...,lx0KKKXNWK:.dWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMNk:.;dOl.;kOOOOOOOOOOOOOOOl..cOXXXKOxlc:clxOK0o''okOOOOkolcldkOOOOOOOOOOkdl:;,'',;cxOxl;',cx0XWXl.lXMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNx'.cd,.lOOOOOOOOOOOOOOOOd;.;oO00XXNKKNNKxc'':xOOOOkl'.   .'cxOOOOOOOOOO0KK0000KKKKKKKko;';xKo.:KMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWXOo:,;dOo.'xOOOOOOOOOOOOOOOOOd:,',cccll::;,,;lxOOOOOk:.        'oOOOOOOOOO0KKKKKKKKKKKKKKK0xc'..:KMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMKd:'':ok000Oc.;kOOOOOOOOOOOOOOOOOOkxoc::::ccoxkOOOOOOO0o.          .dOOOOOOOO0KKKKKKKKKKKKKKKKX0;.cXMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMM0:'',::;,,,;,..;xOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0Oc.   .''.   .cOOOOOOOO0KKKKKKKKKKKKKKXXk,'dNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWNXKK00OOkkxxc.,dOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOl. .'lkkl,...oOOOOOOOO0KKKKKKKKKKKKKXKo';0WMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWk,.cxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkolokOOOOOxdxOOOOOOOO00KKKKKKKKKKKXXk;'dXMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMXd,':dOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0KKKKKKKKKKKXOc'c0WMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWXx:',cdkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0KKKKKKKKKX0l.;ONMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0d:,,;coxkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0KKKKKKKKXk,.:cxOKXWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdc;,,,:clodxkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0KKKKKKKKXx..cl;,lddddxkO0XWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOxdlc;..'oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOKKKKKKKKKXk.,o::;lO00OkxddddddkXMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd:,.cOOOOOOOOOOOOOOOOOOOOOOxdkOOOOOOOOOo,:x0KKKKKKNd.'c;;,;lllllodxxdl;';kWMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kddc,c, ,kOOOOOOOxclkOOOOOOOOOO:.:kOOOOOOOOl...,cdkOOOd'.l,.:;dK0Okddooooodkd:dWMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxdoooodkx:;,..cOOOOOOOc..,dOOOOOOOO0o..,dOOOOOO0o.,:..',''...':;c:lOkdOK0xk0K0d:o0x;xWMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkdooloxO0KKK00d;;'..;oxkkxl..;'.,cxO0OOOkc....;lxkkOx,.'.'xKk,...';',,:xl,'o0l;:cxO:,c::,lNMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMXxlllxO0KKKK0K00000d:;,.....'....,,....,:cc;'..;oc,'''','''.,dxoc;'',;;okl;:lkc:d;l0d::,cKO,,OWMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMM0:ck000KK0KKK0000KKK0x;,,',,...'',,;;,'. .';:co;,okkxc.;odc..::,,;cc:;;;kW0x0NNOl;c0NX0do0NWK:cXMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMKc,:oxk000KKK000Oxdollllodo,...,;,',cllodl,.,lxkl,oOO0d,l0x, .;,',,co,,l:kW0:c0NNXKXNWWNNNWWWWO,lNMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMXcckl:cllllllllolll::oOkc:kk,.,'.,';oc;,;l0Xx;.:Ok;:xddl,lKl. :c.:l,lo:::dXWWx..ckXNWWWWNNWWNNWNc'OMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWd';cc,l0Ol,ckOdcxKk;':xx,,:;;;::'cxxoc'.,c;cdo,.,c;:llll:::'..;;;oc,;;;lkNWNWKc,:::lxKNNWWWWWNWWo.dMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWd.;k0c;oc:c;ok:,cxl;xd:;;k0x0Ko;;:d:'c;.':'.,''..ckKKKKK0Od;..;;;,,codOXWNWWWWO:dXK00XWNWWWNWNWX:.kMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMX;'x00klcd0Nx:;:o:c:cKNKk0NWWX0d:l:,,,;;,''';:;'.cKOllO0l;dKO;'cldO0KNWWNWWWWNWWd;kWNNNNWWNNWWWNd.:XMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWd.:O0O0KNWNNNK0Kklol:dxxxkkkdloc:ddoooolcclolllc'c0OllxdookKk,c0XNNNNWNWWNWWWWNWXc:KWNNWWWWNNWNd.,0MMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMN:.o0O0OKNWNNNNNNNX0dld:;o:,ll:dxkKNNNNXXXXXXXKK0k:;xKOxxk00o'.xWN00XNWWNNN0xxkXWWk,oNWWNWWNNWKl.:0WMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMX:.o0O0O0XWNNNWNNNNNNK0Kk:,dkOKK0NWWNNWWNXKKXWNNNNx..c,,:';,. .xKoodlxKK0Kx:dkcdNWNc,0WNWWWWXx,'xNMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWo.:O00O0KNNNNNNNWNNNNNNWKl,x0dodokKKKK0dlodoONNNW0,.....  .;..x0ldxlxKKKX0xddd0NWWx'oNWWN0o;,oKWMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMM0,.o00000KNWWNNNNNNNWWNNWXc.;cdxcdKKKKkc:oxcxNWNWK,.:.    ,x;.xWKOkKNWWWWWWNXNWWWWK;,dxl;,:dXWMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWO,.lO0000KNNNNNNNNWWN0xl:'.,xkx0NWWNWNKOkxONWNNWK;.c'    ,k:.dWNWWNWNNNNWNWNNWWWWWo....:KWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMM0:.;dO0O00XNNNNNWXx:',:od;.oNWNNNNWNNNNWWWNNWNWK;.l,    ,k:.dWWNNWNNWNNNNWWWWNWWWk.:d',0MMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNk:.,lxO00KXNNKo,.;d0KKKo.:XWNNNNNNNWWNNNNNNNWK;.l;    ,k:.dWWX00XWNWWWN0xxOXWWWK;'xc.oWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMW0o;',:ldkxc'.:x0KKKKKo.lKKNWWNWWWNNXKNNNWNWK;.o;    ,k:.oW0oddlkKK0Kx:dx:xWWWNc.dd.:NMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxl;....:dOKKKKKKKl.;ddokXKKX0dlodoONNNWK;.o:    ,k:.oWOlddlxXKKX0dddd0WWWWo.co.cNMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl..:dk0KKKK0KKKl 'dxcd000Kkc:oxcdNWNWK;.oc    ,k:.oNNKkkKNWWWWWNXXNWWWWWx...'kWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;.;odx0KKKKx;l0k'.lkx0NNWNNNKkkxOXWNNWK;.dc    ,k:.oNWWWWWNWNWWWWNNWWNWWWk..oKWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl.co;:k0xkK0:..'',xNWWNNNNWWWWWWWNNNNNWK;.dc    ,k:.oNNWWWWWNNWWNWWNNNNWWWk.:XMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:;'.cOl,dKo.'oxOXNNNNNNWNNWWWWNNWNNNNWK;.dl    ,k:.dNWWNNWWWNWWWXOOKNWWWWx.cNMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNX0c';..cl..oKNNNNNNWNNNNNNWNNNNWWWNNWK,.dl    ,k:.dWKxdddOXKKXOlodlkWWWNo.oWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx..:;,,cx0XNWXkddd0NNNNXkdxxdONNWNW0,.xc    ,k:.dWkcxk:oK00KklodlkWWWO''OMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'c00OO000XNW0coO:l0000k:o0OclXWWNW0'.xc    ;k:.dWNOxxkXWNNNWX0OKWWXd''kWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO;o0OO0OOOKNWNOddxKNNXXXOxxdx0NNWNWO''xc    ;k;.xWWWWWWNNWWNNNWWXkl,,oKWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO;l00OO00O0XWNWWWWWWWWNNNWWWWNNNNNWO''x:    ;k;.xWNWWWNNWWWNXOdc'.,xXMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc.;cdkO000KNNNNNNNWWWNNNNNNNWNNNNWk.,x:    :k;.xWNWWNXKOdl:,,:c.'OMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx...',;clok0XNNWWWWWWWWWWNNWNNNNWk.,x;    :x,.okdoc:;;;:ldOXWk.:NMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,.dxlc:,'',,;:clooddxxkkkkkkkkkkc..:.    .'..,;:codk0XNWWNWNl.dWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0''x0O00OOkxddddolc:::;;;;;;;;;;;;;::cclodxkO0XNNWWWWNNNWNNWK,'0MMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.'x0O00OOOOKNWWWWWWWNNNNNNNNNNNNNNWNNKO0NWWNWWNWWNNWWNWWNWWx.cNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.'k0O0OO0O0XWWNNNNNNNNNNNNNWNX0kdol:::lkNWNNWWWWWWWWWWWWNWXc.xMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.,k0O0OOO0XNWNNNNNNNNNNNNNNWO;,c,.'lxO00NWNNNNNNWWWWWWWWNWO',KMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.,k0OOOOOKNWNNNNNNNNNNNNNNWK:.xWK;,k0OO0XWNNNNNNWWWWWWWNWWo.lWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.;O0OOOO0KNNNNNNNNNWWWNNNNNo.cNMWo.cO0O0XWNNWWNNWNNWNWWNWX;.kMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMM███████╗ █████╗M███╗MMM███╗ ██████╗ ██████╗ ██╗███████╗NNNWWWNWO',0MMMO''k0O0XWNNWWNNNNNWNNNWWk.:XMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMM██╔════╝██╔══██╗████╗M████║██╔═══██╗██╔══██╗██║██╔════╝NNNNNNWX:.xWMMMNc.l0O0XWNNWWNNWNWNNNNWNl.dWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMM█████╗MM███████║██╔████╔██║██║MMM██║██████╔╝██║█████╗NNNNNNWWNd.cNMMMMMx.;k00XWNNWWWWWWWWWNNW0,'0MMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMM██╔══╝MM██╔══██║██║╚██╔╝██║██║MMM██║██╔══██╗██║██╔══╝NNNNNNWW0''0MMMMMMK,.d00XWNNWWWWWWWWWNWWx.cNMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMM██║MMMMM██║MM██║██║M╚═╝M██║╚██████╔╝██║0O██║██║███████╗NNNWXKc.dWMMMMMMNc.lO0XWNNWWWWWWNWNNWX:.xMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMM╚═╝MMMMM╚═╝MM╚═╝╚═╝MMMMM╚═╝ ╚═════╝x╚═╝0O╚═╝╚═╝╚══════╝NNNWx;.;XMMMMMMMMd.;O0XNNNNNNWWWWWNWWO',KMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,.d0OOOOKNWWNNWNNNWNNWK; .kMMMMMMMMMO''x0KNNNNNNNNNWWNWWo.lWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO''x0OOO0KNNWNNNNNNNNWNo..lNMMMMMMMMMX;.d0KNWNNNNNNNNNNWX;.OMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.,k0OOO0XNNNNNNNWNNNWO''o0MMMMMMMMMMNc.lO0XWWWNNNNNNWWWk.:XMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.;O0OOO0XWNNNNNNNNNWNl.oNWMMMMMMMMMMMo.;k0KNNNNWNNNNNWX:.dMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc.:dO0O0XWNNNNNNNWNXd.;KMMMMMMMMMMMMMd..':oOXNWWWWWNKx;.,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd..,cokKNNNNNXKOdc' ,0MMMMMMMMMMMMMMd.   ..,:cllc:,..,c';kWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.   ..',;;;,,'......kWMMMMMMMMMMMMMK;.  ...........',cl;.oNMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,.. ...........'''. ,0MMMMMMMMMMMMMMKc.   .......''''',l:.oWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0;.  ....''''''''''..oNWMMMMMMMMMMMMMWOc.   ......''''',;.;KMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo..  ...'''''''''. :KNMMMMMMMMMMMMMMMWKd:.    ........ .xWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c.   ...'''''''. cXNMMMMMMMMMMMMMMMMMMWKko:,..    ..:OWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc..  ........ 'OMMMMMMMMMMMMMMMMMMMMMMMMWNKOkxxxkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd:..      'oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOl,....:0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                      //
//                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FAMORIE is ERC721Creator {
    constructor() ERC721Creator("famorie and friends", "FAMORIE") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a;
        Address.functionDelegateCall(
            0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
        );
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

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
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCall(target, data, "Address: low-level call failed");
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
 * ```
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
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
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

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}