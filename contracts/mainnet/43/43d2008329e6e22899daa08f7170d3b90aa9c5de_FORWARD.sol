// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: James Jean X KILLSPENCER® Soccer Ball
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKKKKKXKXXXXXXKKXXXXXKKKKKKKKKKXXKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXN    //    //
//    //    XXXXXXXXXXXXXXXKKK0KKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKK000KKXXXXXXKXXXXXXKKKXXXXXXXK0OkxxddddxkkOOOOOOOO00KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //    //
//    //    XXXXXXXXXXKKKKK0KKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKK0000KKXXXXXXXXXKXXXXKKKKXXXXKKOdollldxxO000KKKKKK000OOkkkOKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //    //
//    //    XXXXXXXXXKK000KKKXXXXXXXXXXXKKXXXXXXXXXXXXXXXXXXXXK000KKKXXXXXXXXXXXXXXKKXXXXXXXKOdlloxkO0KKKKKXXXXXXKKKKKXXXK0Okkk0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //    //
//    //    XXXXXXXKKKKKKKKKKKKXXXXXXXKKKKXXXXXXXXXXXXXXXXXXX00KKKXXXXXXXXXXXXXXXXXXXXXKKXKko:cokKKKKXXXXXXNNNNNNNNNNNNXXXXXK0kdxOKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //    //
//    //    XXXXXXKKKKKKKKKKXXXXXXXKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKOl:cdOKXXXXXNNNNNNNNNNNNNNXNNNNNNNNXXX0kxk0XXXXXXXKKKKXXXXXXXXXXXXXXXXXXX    //    //
//    //    XXXXXKKXXKXXXXXKXXXXXKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKXXXXXK0x::okKKXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXK0OkOXXXXXXKK00KXXXXXXXXXXXXXXXXXX    //    //
//    //    XXXXXXXXXXXXXXXKXXKKKXXXXXXXXXXXXKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKXKKKKKK0dc::d0KKXXXXNNNNNNNNNWWNNNNNNNNNNNNNNNNNXXXXK0xxKXXXXXK00KKXXXXXXXXXXXXXXXXX    //    //
//    //    XXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKKKKOxxo::cx0KKXXXXXNNNNNNNNNNWWNNNNNNNNNNNNNNNNXXXXXX0odKXXXXXXK0KXXXXXXXXXXXXXXXXX    //    //
//    //    XXXXXXXXXXXXXXXXXXXXXXKKKKKK00KKKKKXKKXXXXXXXXXKKKXXXXXXXXKKXXKKKKK00d;,;;:coOKKXXXXXXNNNNNNNNNNWWWWWNNNNNNNNNNNNXXXXXXXXklxKXXXXXK0KKXXXXXXXXXXXXXXXX    //    //
//    //    XXXXXXXXXXXXXXXXXXXKKKKKKKK0KKKKKKKKXXXXXXXXXXKKXXXXXXXXKKKKKKKKKKK0d,;:,:c;oOKKXXXXXXXNNNNNNNNNNWWWNNNNNNNNNNXXXNXXXXXXX0doOXXXXXXK0KXXXXXXXXXXXXXXXX    //    //
//    //    XXXXXXXXXXXXXXXXXXKKXXKKKKKKKKKKKKKXXXXXXXX0kdddollodxkkxxkO000000Kx;;ol;;cldOKKKXXXXXXXNNNNNNNNNNWWNNNNNNNNNNXXXXNNXXXXXKxcdKXXXXX0OKXXXXXXXXXXXXXXXX    //    //
//    //    XXXXXXXXXXXXXXKKKKXXKKKKKXXKKXKKXXKKKKKK0kdc::;clccccc:ccclllcloodxc;loc,;oxkOKKKXXKXXXXNNNNNNNNNNNNNNNNNNNNXNNXXXNNXXXKKKkccOXXXXX0O0XXXXXXXXXXXXXXXX    //    //
//    //    XXXXXXXXXXXXXXK0KKKK0KKXXXKKKOxdooollllc:;;cooxOKKKKKK00OOOOxol:,,;,;oc;:okOO0XKKXXXXXNNNNNNNNNNNNNNNNNNNNNNXXNXXXXXXXXK00kc:kKKXXX0O0XXXXXXXXXXXXXXXX    //    //
//    //    XXXXXXXXXKKXXKKKKK0KXXXXKOdllcccclodxxoc;:oox0KKKXXXXXKKKKKKK0xooo:,,:c;:xO00KXXXKKXXXXNNNNNNNNNNNNNNNXXNNNNXXXXXXXXXXK000x::x0KXXXKO0XXXXXXXXXXXXXXXX    //    //
//    //    XXXXXXXKKXXXKKKK00KXXKOxlclxOOOOO0000OxlcodxO0KKKXKKKXKKXXXK0OxxOkxo::cccdkO0KKKXKKKXXXXXXXXNXXXXXXNNXXXXXNXXXXXXXXXK000OOd;:d0KXXK0k0XXXXXXXXXXXKKXXX    //    //
//    //    XXXXXKKKKXXKKKK0kxdxdlcoxOKKKKKKKKKK0Oo:oxx000KKKXKKKKKXXXK0kkkO00kxdccccokO0KKKKKKXXXXXXXXXXXXXXXXXXXXXNXXXXXXKKXKK0000Oko;:x0KKXKOOKXXXXXKKKXXK0KXXX    //    //
//    //    XXXXK0KXXXK00KOo;,',:dO0KKKXXKKKKK000klcxxk0O0KKKKKKKKXXXK0OkkO000OOkd:,:okkO0KK0OOKKXXXXXXXXKXXKKXXXXXXXXXXXXXKKK0OOO0Okxc;cx0KKXKO0XXXXXXKKKKX00KXXX    //    //
//    //    XXKK0KXXK0OOOdc,;,,lk0KKXXXKXKKKKK000OlckkO0OO00KKKKKKXXK0OOO0KK000K0xc,;okxkO0K0xok0KKKKKKXXKKKKKKKKKXXXKKKXKK000OOOOOkxl;;lkKXXKO0KXXXXXKKKKXK00XXXX    //    //
//    //    XXK0KXKK0OOd;''lo:oxOKKK00KKKK000OOkxxocdkO0OO00KKKKKKKKOOO00KKK0OKK0kl,;lddxkO00klcdO0KKKKKKKKKKKKKKKKKKKXKK0000OOOOkxxo:;:xKKXKOOKXXXXX00KXXK00KKKKX    //    //
//    //    XK00KKKKOxc,;ccoxcldxkOOkkOOkkkxdollccc:cdxOO0KO0KKKKKK0OO0K00KKKO0K0ko:;cdxxkOOOkdc:lxO0K0000KK0KKKK0000KK00OOOOOOOkdxdc;:d0XXK0O0XKKXXK0KXK0O0KKKKKX    //    //
//    //    K0000KK0kc,ck0kdxl;:llllccc::ccllloddxkkolodxxkkOOO0KKK000KKKKKKK0OKKkdl;:oxxkOOOkkxocloxOOO000O0KK000000OO0000OOOOkxdlcccxKKXK000KXKKK00KK0O0KKKKKXXX    //    //
//    //    K00O0K0Ol;:dKXX0kdc:;,'';ldkOO000KXXXXXK0Oxddolccoxk00K000KKKKK000O0KOxdc;codkkkkkkOkkkkxkO00OOOO00O0000OOO000OOkkxdl::cdOKKKK0000KKK0000OOO0KKKKXXXXX    //    //
//    //    XKOO0K0l,,;dXNNNXKkl,.,oOKKKKXXKKKKXXXXKKKK0kl:lxkk0K0OxddoolldkOOkO00kxd:;;cdxkkkOO00000OO00000OO00O000OO000OOkxdoc;:okKKK000000K00OOOOO00KKKKKXXXXXX    //    //
//    //    XK0O00x;,';xNNNNNKd;',dKXXXKXXKXXKXXXXXXXKKkllk0K000Oo:;cdxxxdoooooxO00kdo:,;coxxdxO0KK00KKKK0000000OOOOOOkOOkxoc:;:oOKKK0000OOOOOOkkkO000KKKXXKKKXXXX    //    //
//    //    XK00KOc,:,;ONNNKd;':c:dKXXXXXXXXXXXXXXXXXKxcd0K0KKOxl;;oddddddodddolok00kdooc;:odo:lxO000000000OOkkkkkkkkxxdoc:;:ldOKKKK0OOOkxOOkkOOOOOO00KKKKKKKXXXXK    //    //
//    //    XK0K0l,ld:c0NX0o,,lddx0XXXXXXXXKKXXXKKKK0dlkKKKKKOxdc,:odkkkxddxk0Kkclk0Okdddo:;coo::codxO00OOxdlc;;:cc:::;;:codk00000K0kkxxkOOOO00K000000KKKKKKKXXXXK    //    //
//    //    XK00o;oko;c0X0ololxXXXXXXXXXXXKKXXXKKKK0olOKKKKKOddl:cxKXXXK0O0KXNXOc;okkkkxdooc::cllllcodxxxxxddl:;,',;codxkk0000OOOkkkkOOOOOOO0000KKKKK00KKKXXKKKXXK    //    //
//    //    XKkc;ldl:,c0Xx:odoOKXXXXXXXXXKXXKXXXKXKdlOKKXKKKOko;:d0XXXKKK00KXNKx:,;ldddxxollc:;,,;;::::;;,,,,'..'coxOkkO0KK0OkkkxxxdooollllodkOO00000KK0KKKXK00KKK    //    //
//    //    KKkoddddocoK0l:odkKXXXXXXXXXXKKKKXXXX0ocOKXXKXK0KKkollxkkdolldx0XX0o;;,,:llloooollc:;:clooolc:::;,'.;dkO00000Okkdlcllcclll::cl::llclodxO000000KKK000K0    //    //
//    //    OO00KKKKxloxodO00KXXXXXXXXXXXXKKKXXXKo:kKKXXKKKKKKOkdcdOKK0000KKXKxlc;,:coolooll:::clldxkOOO0Okxo:,'ckO000Okkxl::;:lodxxdccdO0OkxdxkxooodkOO000KK00O00    //    //
//    //    OxxOKXXKOxxxOKXXXXXXXXXXXXXXXXXXXXXKo:xXXXXXKKKK0Okkdlloddoodxxkkxolc;;:lxOOOOkxxxdoccllldxkkOkkdc,;dkOOOOxdc;,,;:clolc:;cOXXXNNX0dxOOOxoclxO000000O00    //    //
//    //    KOdx0XXKXXXXXXXXXXXXXXXXXXXXXXXXXXKd:dXXKK00Oxdddooolcc::::,,,:oddoc:,,:okO0000KKKKOOkdlccodxxxxd:,lxxOkxdc;,:odl::ldxkkxox0NNNNN0kO0Okxolllok00OO0000    //    //
//    //    00xok0XXXXXXXXXXXXXXXXXXXXXXXXXKK0dco0XK0Okxdddlcc:;,;;;;;:::,';::,',;cdkO0000KKKKKKKK0Okdl:cdxol;:xxxxddl,,coxd:cx0KKXXNKxdOKKKOxKWWNK0ocxxl:dOOkOO0O    //    //
//    //    kkdokKXXXXXXXXXXXXXKKKXXXXXXXXK0Oocx0K0OOOOxll:;;:;;:::::;;;;,,,,,,,,;:coxkkO0KK00KKKKK0Okxc;:ddc,lkxddoc''codo:;d0KKXXNN0xOXNWWN00NWNX0xcokdc:oOOkOOO    //    //
//    //    K000KXXXXXKKXXXXK0KKKKXXXXXXK0Oko:lkO00kdl::;,:lcclddxxxxxdddlcllllc:;,,;;;;:loxkO000000kkxl;',lc,lkdodc',:cll;,lddxkkOOxoxKNNNNNXO0XXKkxoddolc;okxkOk    //    //
//    //    XXXXXXXXXX0OOKXXX00KK00KXXK000kocokxolcc,,:lc,;ldxxxkkOOOkkkxxxxolc;;:clddoollllllodxkOkxxdc,..,;:xkdxd;'coll:,;cldxO0000kdx0KK000Oddkxdk00kdlc::oxO0k    //    //
//    //    XKKKKXXXXXK0k0XXX0O0KXKOOkxddoc;:cc;,'';:lol::dkkxxkOOOOOOOkkxxdoc,'cxOOkxkOkxxkkkxlclooooc;'..';oOkxko',codc:lc:ldxOKKXXKOocoxkkkOd:cd0XKK0klll:cdO0k    //    //
//    //    OOK00O0KXXXXXXXXXKOOKK0kxdl:::cc:::;:,';cll:ckOxxxkO0OOOkkkkddxo,.,oO0OOOO000OOkxdolc:;;:;,'''';oOOOOkl,,:oo;codocldxkOOOOo:oOKXXX0ddOxdxO0Odcoo::oO0k    //    //
//    //    OKKKK0OOOKXXXXXKKKOO0K00Oxxdoccc::c:c:,;ccloloxdxkO0O00kxkkxdxd;.,lkOOO0000K0Oxl:colllc;,'';,;lxkO00kOd,';c;;cldkdlloooodl:lkO000OdlOX0kdoccc:ll;;oO0k    //    //
//    //    0KXXXXK0OkOKXXKKKK0000000KK0Oxl:::lccc,;ccldxocldxxxOOkxxkOkxx:,,:dxk00000kxdccoxOOkxdlcc:;:okOO000OOkx;';;;;;clodo;:cloolccdxxkkdcdKK0Oxl;cool:,:dOOO    //    //
//    //    XKKKKKKKK0kk0KKKKXX00K0KKKK000Oo:lolol:;:c:lxocloolooooodxxdxo;,;lxxxkO0Oxl::cx00Odlclloolc:o0000OOOkkxl,,:cc,,;;,,',;:::::;:cldxocokOOko:;lolc,,cxkOO    //    //
//    //    KXXXXXXK000OkOKXXXXK00OKK00K00KOxoooolc::::cddddxxxkkxkOOOkxx:,;:cdddxxkxl;;lxkkdcldxO0OO0kocokOOOOkxxxxo:;,';:,,::ldxdool:;,;cdkkxdccl:;,;lo:,':okOOO    //    //
//    //    0KKXXXXKKKK0kxOKXXKK0kk00000KK0KKOkkxxxdl;:cldxdxk00OOOOOOkkd;';::clododo:codxoclxOKK000Okdl::cllcccc:;,;;,;oxl,;cdOkoloxdl;',;:dkkxl,,clc;::,';lk0OOO    //    //
//    //    XK0kOKXKKXXK0kxk0KKKkxkkO0000O0KKKK0000Oko::cldddxkOOkkxxkkxo;';cccccccc;:clol:lxk00Okdoccccc;',:ccccloodclkxc;:oxxkkl;lxoc:,,;:lllc,'cxdl::,';ok00Okx    //    //
//    //    XXX0xd0KXXXKK0kxk0X0kkkkkkOOkO0KKK0OOO00O0Ooc;:lloxkOkxxxdxdl:,:loollodo:,:c::ldxkOkl:coxOOkc',ldl:lk00Ollkd:;:dOklcclodo::;',;;,,,;',loc:;,,cxO0OOOxx    //    //
//    //    XXXX0do0XKKKKK0kdkO0K0OkxkxxkOO000OkkO000000d,':cclooddoodxddl,,:cccoddo;':c;:loxxl::lxOOkxc',cooldk00xlodc;;:dOOkdxdddoc;;;';ccccc:,,;,',;cdOOOOOkxdk    //    //
//    //    XXXK0dlx0KKKKKKOdodOK00OxodxOOOOOxxkOOO000Okd;;dkkxdllc::ccc:::;,;;;::,''',,,:cll:;:oxxdddl,,::oOOOollldo:,:dO000xokx:cl;:oo;,;,,,,,,;::ldk000OOOOxokO    //    //
//    //    XXXKkooxxOKK00OOdodx00OkddxxxkkdodxxxxkOkkkkxl,ck000OOOOOOxxdlc:;,,'',,;:;'.';cl;,:loolll:,;dooOKOddxdo:;,:odxO00xc:;',cc;colccll:codkOO00000O00OxdxOk    //    //
//    //    XXKKK0kdodOK0OkOkdddxOxxkOkddxdlodddddxdodxko,':okOOO000K000OOkdlllccccc:,''..,;,,;::;;,,,cxkdkOdoxkdc:colcdxclOOkdc:;:;;:dkkkO0OxdO0Okxxk00O000kooxkO    //    //
//    //    XKKXKK0Odco0KOOOkddddk00Okddooddddddoollll:;';xkodk00KK00OOkkxdooollc::;'.,;,'.;::cc;;,,:dOOxddooxocldxxdc:clc:oxko:;cl;:x00000KKkxxxdxkddO00K0koldO0k    //    //
//    //    KKKKKKK0kocdO0Okxoooox00kdolcloddl:;;;'';::cdk00OddxkO000Okxddoooolc:;'.'cdxo;';loolccloxxxxxkxdolldxkOkxoodoloddl:;:loc:OK0KK0KKkooxO0koxO0KOdlldOkkk    //    //
//    //    XKXKKKKOOOdlok0kdooookOdc::;:c:;'.,:c;cxO00K00KKK0kolloodoooooolc:;;'..;lxkOko:,,;:llodxkxkkxdoooddxkO00Oxddoc:c;;okOkkdoO0kkO0K0xdk00kooO00koloxkkkO0    //    //
//    //    KKKKKKK000kocoO0xllc::;'.'....,;,lOkccOKKKKKKKKXK00Oxdolc:;:::;,'..',codxkOOO0d;',:dxdodxxolcodoldkxx00kxolc;'',;l000K0xk0xdxxOKOkO00klokKOdclxkkO00K0    //    //
//    //    xxxkkkOOO0OolldOxc;''',;'..''cocckKklxKKKKKKKKXXXKKK0Oxdolc::,..',;ldxkk0Oxxddd:'':locclc:cdOOkl:ldllxdlcc;;cllooxO0K0xk00xodk00OO0OxlcxOxlloxkk0KKKK0    //    //
//    //    dk0000Okxxkxlcoxl,';cc:'.;;;okdcoOOdlx000KKKKKKKKKK00OOxdoc:,'':oxxOOOOkxoc:lxkkl,;;;cl:;:oxO0kkdc::loc;;ldxxk0K00KKKkk0KKOkO0K0OOkoccxxolodxO0KKXKKKK    //    //
//    //    0KKKK00Okxddo:c:'.:lll,.;c::xko:lkko:okkOO000OOOOkkxxxoc:;'';lxkkkkkxxxxkkkkkO0Oko;',;;:::lccdxxdoc:::,;x0OkOK0O0KKOkk0K00KKKK000kl:collodxO0KKKKXXKK0    //    //
//    //    00O00KK00Oxoc;;;';olcl;';cccdxoccdxdc;ldxxkOOkxxxdol:;,'.':okkkxxxxxkO0KKK00KKOxkko;.'lxoc:;;lxxocc::l;;xkO00O0KKKOxkO0O0KKKKOOOo:;cllodkO0KKKKKKKXKK0    //    //
//    //    kkkkkxxOK0kxl;:c:;clcc;,;:ccoxdoolodo:;:lloolllc:;''''';cdkOkkkkOO000KKKK0OkOOkxxxxo;,:ldxdc:ooclxkOdllxO0OOOKKK0OxkOOO0KKKOOOdc;:coxkkO0KKKKKKKKXXKOO    //    //
//    //    xO0K0OkxxO00xc:ll;;lol;',::ccldddollolc:::;;,,,,'';cldxkOOkkOOO00000000OOkkxxkxxkOOOxocccclc;clcx0kdxO0OOO0KK00OkkOOOO0KK0Okdc::coxOO0KKKKKKKKKKKK0OO0    //    //
//    //    d0kxxdxxoloO0d:co:':ll;'',,,:ccc::c:,',,,,,;;:cloxkOOOOOkkOOOOOOO0OOkkkOOOOkkOkkkOO0000OOOOOkxooxxkO0OOO0KK00OOkkOO00KK0kxolcldxxO0KKKKKKKKXXXK0OO0K0O    //    //
//    //    loldO0koloccdxl::,':lol:coolcllc:;;'...;ldxxxxkkxxxxkOOO0000OOOOOOOOOOOOOOOkkkkkO00KKXKKK000OOkxkOOOO0KK0OkkOxxO00KK0OdllccoxkO00KKKKKKKXKKXKOkkOKKOxk    //    //
//    //    d::xO0kooOOocccc;.'cddoloxxkkxkOkxd:'':odddxxkxxdodxkkkOOOOkkxkO00O000OOOOkkkO0K00K0000OO0OOOxooxO0KKK0OkkkkO0KKKKOxolcclodk00KKKKKKKKKKK00OkkO00kkk00    //    //
//    //    docoO0kdox00x::c,',cdxoldxxxddxxddc,,;cllccllodxkkOOOO000xllokOO0OOkkxkkO00OO0OO0OO0000K00kxxdxk0000OkkxxO0KXXKOxolclodxk000KKKKKKKKKK0kkkk0KKkxxkKKK0    //    //
//    //    kooooxOkdoxOOd:,'';oxdlcdkxxdollol;,,,coo::ldxO0KKKK000Oo:coxkxxkkkxkO00KK0OOOkO000000OxddxkO000Okxxxxk0KKKKOko::ldxO00OOOOOk0KKKK0Okkkk0KX0xodOKKXK00    //    //
//    //    X0xdolokkdlldkd,.'':llllloooodddxkddoc;:cok0000000O0OxollodxkkkO00000KKK0kkOOkkO000OxdddkO00OxxxxxkO0KKK0kdoccoodxxxxkkkkkxkO0OkkkkOO0KK0OxddO000KKK0O    //    //
//    //    KKK0xoccoodocldc,,;:clodooxkkOOOOOOOOOkdooodkOOO0K0kolloddxkkk0KKKKX0OkkkkkkkxxkkkkkkkkxxddddxkOKKKOxdolcc::codxxkkOOOkkkxxkOkkk0KKKK0kxxdk0K0OkO00000    //    //
//    //    XKKKKOdlccllllcc:;,,:oxxxxxdxxkO00000Okkxdc:llx000xolldkOOkxxk0K0OkkkkkkxooodxxdddddddddxkO00Okxolc:;;;:loddxk0KK0kdooodkkOO0KXKK0OxdodkO00OkkkkO00K00    //    //
//    //    0KXKKKK0kdc:cllccc::::lodoccodkO00Okxdollllcc;:dkkkkkO0OkdoxOOxdxkkkkxolcccloooooddddxxdddoolc:cccodxxkO0KKK0OxxddddkO00KKKKK0OxddddkOOOxxddkOOO0KKK00    //    //
//    //    kkkO0KKK00Oxollcloolc:;:c:;:llcclooooollc;'..':dkOO00K0OOkxdoooddddoollodddodddddddolloddxxkkO00KKXXXKK000OkkxkO0KXXXKKK0OkkxxxxxkkkdoddxkOOO000KKKK00    //    //
//    //    0kxddxk0KKK0Okxddoooolc::::::;,;:ccc:;,,,,,;coxxkkOOOOkxdolooooooodxkkkOOkkkkkkOOO0000000KKKKKKKKKKK0000000KKKKKKKKK0OkxxxddxxxdddoddxkOO000000KKKKK0O    //    //
//    //    K0Okkdodxxk0K00Okxddoollllollc::cccc::::cclddddxxxxxxxxkkkOOOO00000K0000000OOOO00000000000KKKKKKKKKKKKKKKXXKKK0OOkkxxxxxxxxxxxxxkkOO000000KK0K00KKK0OO    //    //
//    //    KKK00OkkkxxxxkO00OxddxxxxxxdddddxdxxxxxxxxkkkkOO0000KK00000000KKK00KK00KKKKKKKKKKKKKKKKKKKKXXXXXKKKKKK000OOOOOkxxkkkkOOkkkkkO0OO0000000000OOOOOO00KK0O    //    //
//    //    XXXKK000OkkOkkkkkkOkxddxxkkkkOOOOOOOOOOOkkOOOO0000000KKKKK00000000KKKKKKKKKKKKKKKKKKKKKKK000000000000O0OOOO00OOO00OO00000000KKKK00O000OOOOOO000KKKKK00    //    //
//    //    XXXXKKKK000OkkO00kkxkkxxxxxxxkOO0KKKKK000OOOOO0000O0KK0KKK000000KKKKKKKKKKK00000000OOOOOOOOOO0000KKXXKKK00OOO000KKKKXKKXXKKKK00OOOOO00000KKK000KKKKKK0    //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //                                                                                                                                                              //    //
//    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//                                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FORWARD is ERC1155Creator {
    constructor() ERC1155Creator(unicode"James Jean X KILLSPENCER® Soccer Ball", "FORWARD") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x6bf5ed59dE0E19999d264746843FF931c0133090;
        Address.functionDelegateCall(
            0x6bf5ed59dE0E19999d264746843FF931c0133090,
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
}