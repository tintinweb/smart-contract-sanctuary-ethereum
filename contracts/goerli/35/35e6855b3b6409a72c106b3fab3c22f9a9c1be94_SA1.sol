// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Splat Act I
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    dddddddddddddddddddddddddoooooooooddddddddddddddddddddddddddddooodddddddddddddddoooooooooooooooooddddooooolllooooooooooooooooooolloooooooooollllllllllllooooooooooooooolllllllooooolllllllllloooooooooooooooooollcccccclloooooooolccccllollllllccccclllllllllllllllccclllllllllcccccccccccccllllllllllllllll    //
//    0000000KKKK00000000000000OOOOOOO0000000000000000000000000000OOOO00000000000000OOOkkkkkkkkkkkOOOOOO00OOOOkkkkOOOOOOOOOOOOOOOOOOkkkOOOOOOOOOkkkkkkkkkkkkOOOOOOOOOOOOOOOkkxxxxxkOOOOkkxxxxxxxkkOOOOOOOOOOOOOOOOOkkxxxxxxxxkkOkkkkkkxxddxxkkkkkkkxdddxxkkkkkkkkkkkkkxxxxxkkxxxkkxxddddddddddddxxkkkxxxkkkkkkkxdd    //
//    000000000000000000000OOOOOOOOO000000000000000000000000000OOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkOOOOOOOOOOOkkkkkOOOOOOOOOOOOOOOOOOkkkOOOOOOOOOkkkkkkkkkkkkOOOOOOOOOOOOOOOkkxxxxxkkOOOkkxxxxxxxkkOOOOOOOOOOOOOOOOkkxxxxxxxxkkkkkkkkkxxdddxxkkkkkkxxddxxkkkkkkkkkkkkxxddxxxxxxxxxxxddddddddddddxxxkkxxxxxxkxxxxxddod    //
//    0000000000000000000OOOOOOOOO000000000000000000000000000OOOOO000000OO00O00OOOkkkkkkkkkkkkOOOOOOOOOOOOkkkkOOOOOOOOOOOOOOOOOOkkkkOOOOOOOOkkkkkkkkkkkOOOOOOOOOOOOOOOOkkxxxxxkkOOOkkxxxxxxkkOOOOOOOOOOOOOOOOOkkxxxxxxxxkkkkkkkkkxxdddxxkkkkkkkxxxxkkkkkkkkkkkkxxdxxxkkxxxxxxxxddddddddddddxxkkkxxxxxxxkkkxxddoddd    //
//    00000000000000000000000OO0000000000000000000000000000OOOO0000000000000OOOOkkkkkkkkkkkkOOOOOOOOOOOkkkkOOOOOOOOOOOOOOOOOOOkkkkOOOOOOOOkkkkkkkkkkkOOOOOOOOOOOOOOOkkkxxxxkkOOOOkkxxxxxkkkOOOOOOOOOOOOOOOOkkxxxxxxxxkkOOOOOkkxxxddxxkkkkkkkkxxxkkkkkkkkkkkkxxxxxxkkkxxxxxkxddddddddddddxxkkxxxxxxxkkkkkxxddoddddd    //
//    KKKK00000000000000000000000000000000000000000000000OOOO00000000000000OOOkkOkkkkkkkkOOOOOOOO0OOOkkkOOOOOOOOOOOOOOOOOOOOkkkOOOOOOOOOOkkkkkkkkkkOOOOOOOOOOOOOOOkkkxxxxkkOOOOkkxxxxxkkOOOOOOOOOOOOOOOOOkkxxxxxxxkkOOOOOOkkxxxxdxxkkkkkkkkxxkkkkkkkkkkkkkxxxxxkkkxxxxkkxxdddddddddddxxxkkxxddxxkkkkkxxddooooddddd    //
//    KKKK000000000000000000000000000000000000000000000OOO000000000000000OOOOOOOOOOOOkkOOO00OOO0OOOkkkOOOOOOOOOOOOOOOOOOOkkkkOOOOOOOOOOkkkkkkkkkOOOOOOOOOOOOOOOOkkkkkxkkkOOOOkkxxxxkkkOOOOOOOOOOOOOOOOkkxxxxxxxkkkOOOOOOkkxxxxxxxkkOkkOkkkkkkkkkkkkkkkkxxxxxkkkxxxxxkxxddddddddddddxxkkxxxddxxxkkkkxxddddoooddddxx    //
//    KKKKK0000000000000000000000000000000000000000000O0000000000000000OOOOOOOOOOOOOOOOO0000000OOkkOOO000000000000000OOOkkkOO000000OOkkkkkkkkkOOOOOO0OOOOOOOOOkkkkkkkkOOOOkkkxxxkkkOOOOOOOOOOOOOOOOOkkxxxxxxxkkOOOOOOOkxxxxxxxxkkOOOOOOkkkkkkkkkkkkkxxxxkkkkkxxxxkkxxdddddddddddxxkkkxxdddxxkkkkkxxdddddodddxxxxkx    //
//    KKKKKKK00000000000000000000000000000000000000000000000000000000OOOOOOOOOOOOOOOO00000000OOkkOOO000000000O00000OOOkkkOO0000000OOkkkkkkkOOO0OOOOO00OOOOOkkkkkkkkkOOOOkkkxkdoxOOOOOOOOOOOOOOOOOOkkxxxxxxkkOOOOOOOkkxxxxxxxxkOOOOOOOOOOkkkkkkkkkxxxxkkkkkxxxxkkkxdddddddddddxxxkkkxxdddxkkkkkkxxdddddddxxxkxkkkkx    //
//    KKKKK00000000000000000000000000000000000000000000000000000000OOOOOOOOOOOOOOO000000000OOOOOO0000000000000000OOOkkkOO0000000OOkkkkkkkOOO000000O000OOOkkkkkkkkkOOOOkkxkxo:..oOOOOOOOOOOOOOOOkkxxxxxxkkOOOOOOOOkxxxxxxxxkkOOOOOOOOOOOOOOOkkkkxxxkkkkkkxxxkkkxxdddddddddddxxkkkxxdddxxkkkkkkxxddddddxxxkkxxkxkkkx    //
//    KKKK00000000000000000000000000000000000000000000000000000000OOOOOOOOOOOOOO00000000OOOOOO00000000000000000OOOkkkOO0000000OOkkkkkkOOO00000OO00000OOkkkkkkkkkOOOOkkkkxo;.   l0OOOOOOOOOOOOkkxxxxxxkkOOOOOOOkkxxxxxxxxkkOOOOOOOOOOOOOOOOkkkxxkkOkkkxxxkkkkxxddddddddddxxxkkkxxdddxxkkkkkxxdddddxxxxkxkkkkkkxkkxx    //
//    KKK00000000000K0000000000000000000000000000000000000000000OOOOOOOOOOOOOO000000000OOOOO00000000000000000OOOkOOOO0000000OOkkkkkkOO00000000kodO0OOkkkkkkkkOOOOOOkkkko,.  '. cOOOOOOOOOOOkkxxxxxkkOOOOOOOOkkxxxxxxxxkkOOOOOOOOOOOOOOOOkkxxkkOOkkxxxxkkkkxxddddddddddxxkkkkxddddxkkkkkkxxddddxxkkkkkkkkkkxxkxxkkk    //
//    K0000000000KKKKKKKK0000000000000000000000000000000000000OOOOOOOOOOOOOO00000000OOOOOO00000000000000000OOOOOOOO00000000OOkkkkOOO00000000000d:okkkkkkkkOO000OOkkkkd:.   .:. :OOOOOOOOkkxxxxxxkOOOOOOOOOkxxxxxxxxxkkOOOOOOOOOOOOOOOkkkkkkOOOkkxxxxkkxxxxdddddddddxxkkkkxxddddxkkkkkkxxdddxxkkkkkkkkkkkkkkkkxxkkk    //
//    000000000KKKKKKKKKK00000000000000000000000000000000000OOOOOOOOOOOOO0000000000OOOO000000000000000000OOOOOOOO00000000OOkkkkOOO0000000000000Ol,okkkkkOO000OOkkkkx:. ....;c. l0OOOOOkkxxxxxkkOOOOOOOOkkxxxxxxxxxkkOOOOOOOOOOOOOOkkkkkkOOOkdl:;,,'....;dxddddddxxxkkkkxxddddxkkkkkkxxxxxkkkkkkkkkkkkkkkkkkxxkkkxx    //
//    0000000KKKKKKKKKK00000000000000000000000000000000000OOOOOOOOOOOOO0000000000OOOO000000000000000000OOOOOOOO00000000OOOOOOOO00000kk0000000OOkx:,okkOO00OOkkkkkxc. .':..'cc..l0OOOkkxxxxkkOOOOOOOOOkxxxxxxxxxxkkOOOOOOOOOOOOOOkkxkkOOOxl:'.     .'. .:dxxxddxxkkkkkxddddxxkkkkkkkkxxkkkkkkkkkkkkkkkkkkkkkxkkkkkx    //
//    0000KKKKKKKKKKK0000000K0000000000000000000000000000OOOOOOOOOOOO0000000000OOO00000000000000000000OOOOOOO00000000OOOOOOOO0000000kddk000OOkkkkx,:O000OOkkkkkxc. .':c,..:ol..oOkkkkkkkkkOOOOOOOOkkkxxxxxxxxxkOOOOOOOOOOOOOOkkkkkOOxo:'.  ..',;cox:. ,dxxxxxkkkkkkxddddxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkx    //
//    KKKKKKKKKKKKKK000000KKK00000000000000000000000000OOOOOOOOOOO00000000000OOO00000000000000000000OOOOOOO00000000OOOOOOOO0000000000OdcoOOkkkkkkOo;xKOOkkkOOkl. .':cl:..;lxl..okkkkkkkOOOOOOOOOkkxxxxxxxxxxkOOOOOOOOOOOOOkkkkkOkdc,.   .,;;coxOKKc  'oxxxxkkOkkkxdddxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxkkkkkxd    //
//    KKKKKKKKKKKK000000KKKKKK000000000000000000000000OOOOOOOOOO00000000000OOO00000000000000000000OOOOOOO000000000OOOOOOO00000000000000xc:okkkkkO0Ocl0OkkOkl;. .':cccl, .cdOc .okkkkkOOOOOOOOOkkxxxxxxxxxxkOOOOOOOOOOOOOkkkkOkd:'.  .,::;;:lk0KXKc  'oxxkkkOkkxxdddxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxdddd    //
//    KKKKKKKKKKK00000KKKKKKK0000000K000000000000000O00000OOO000000000000OO000000000000000000000OOOOOOO000000000OOOOOO0000000000000000OOko;:dkOO000dlk0OOo'  .cllclll:. ,okO: 'dkkOO0OOOOOOOkkxxkxxxxxxkkOOOOOOOOOOOOkkkkOkd:'   .,cc:,,cx0KKKXKc  .okkOOOkkxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkxxxkkkkkkkkkkxxxddddxx    //
//    KKKKKKKKK0000KKKKKKKKK000KK0000000000000000000000000O000000000000OO000000000000000000000OOOOOOO0000000000OOOOO0000000000000000OOkOkkxl;ck0OOkkodKk:  ;ok0dclllc' .cdkO; ,kOO00000OOkkkkkkkxxxxxkkOOOOOOOOOOOOkkkOkd:'   .,cl:,,:dOKKKKKXXo. .okOOOkkxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxkkkkkkkkxxxdddddxkkk    //
//    KKKKKKK00K0KKKKKKKKK000KKKK00KKK0000000000000000000000000000000000000000000000000000000OOOOOO0000000000OOOO00000000000000000OOOOOOkOO0x:,okOO0kdkc .o0KK0dcllc, .,oxOk' :O0000OOOkkkkkkkkkkxxkkOOOOOOOOOOOkkkkkd:.   .'clc,,:dOKKKKKKKKXk. .lOOOkkxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkxxxxxkkkkkkkkxxxdddddxxxkkkx    //
//    KKKKKKKK0KKKKKKKKKK0KKKKKKKKKKKKK0000000000000000000000000000O00000000000000000000000OOOOOO0000000000OOOO00000000000000000OOOOOOOOO0000kl,o000OccxcdKK0KOoccl:. .cdk0x. :O00OOOkkkkkkkkkkkkkkOOOOOOOOOOOkkkko:.   ..;ll;,;oOKKKKKKKKKKX0,  :kOkkxxxxxxkkOOkkkOkkkkkkkkkkkkkkkxxxxxkkkkkkkkkxxdddddxxxkkxkxxd    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000000000000000000000000000000000000000000000000OOOOOO0000000000OOOO00000000000000000OOOOOOOOO0000OOOOxco0O:..dXK0KKKklclc. .;oxk0x. l0OOkkkkkkkkkkkkkkkOOOOOOOOOOOkkko:'   ..;cc;'.:x0KKKKKKKKKKKXKc  ,xkxxxxxxkkOOOOOOOOOkkkkkkkkkkkkkxxxxkkkkkkkkkxxddddddxxkkkkkxxddd    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0000000000000000000000000000000000000000000000000OOOOOO0000000000OOOO00000000000000000OOOOOOOOO0000Okk0K00kcll..cdKX0KK0xlcl,  'lxxO0d..dOkkkkkkkkkkkkkkOOO00OOOOOOkkkd:'   .';cl:'.'ck0KKKKKKKKKKKKXXl. .oxxxxxxkkOOOkOOOOkkkkkkkkkkkkkxxxxkkkkkkkkkxxdddddddxxkkkkkxxddxxx    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000000000000000000000000000000000000000000000000000000000000000OOO00000000000000000OOOOOOOOO0000OOOOdlkK0x;.;ok0xOXKKKOocl:. .:oxkO0l.'dkkkkkkkkkkkkkOOO0000OOOOkOxl,.  .';col;..,oOKKKKKKKKKKKKKKXXo. .lxxxxxdollcccokkkkkkkkkkkkkkxxxxxkkkkkkkkkxxddddddxxxkkkkxxxxxxxkkk    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000000000000KKKKK00000000000000000000000000000000000000K0000000OOO00000000000000000OOOOOOOOO0000OOO0000dclkc.';dXk:oXKKKklcc' .,lxxk0O; ;kkkkkkkkkkkkOO000000OOkkOxc.  ..,:lol,..;x0KKKKKKKKKKKKKKKXXd.  ,ccccllccloodxkkkkOOOOkkkkkxxxkkkkkkkkkkxxdddddddxxkkkkkkkxxkkkkkkkk    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKK0000000000000KKKKKKK0000000KKKKKK00000KKK00K000000000000KKK0KK000O0000KK0000000000000OOOOOOOO00000O00000000d..cd0xcO0cl0X0Odcl;. 'cdxkO0x'.ckkkkkkkkkOO0000000OOkkko;.  .':lodl,..:x0KKKKKKKKKKKKKKK0kdc. .,clodxkOOOOOkkkOOOOOOOOkkxxxxkkkkkkkkkkxxdddddddxkkkkkkkkkkkkkkkkkkxx    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKK000000000000KKKKKKKK00000KKKKKKK000000KKKKKK00000000000KKKKKK00000000000K00000K00000OOOOOOO000000O0Okkkkkxd:. .':O0cdOcckKxocc:. .;ldxO00x,'dkkkkkkO000000000OOkOkl'  ..;cldxo,..ck0KKKKKKKKKK0KK0xocc:'  .lOOOOOOOOkxollcccldxOOkkxxxkkkkkkkkkkxxdddddddxxkkkkkkkkkkkkkkkkkkxxdd    //
//    KKKKKKKKKKKKKKKKKKKKKKKKK000000000000KKKKKKK000000KKKKKKKK0000KKKKKKK00000000000KKKKKK000O000KKK00KKKKKK0K000OOOOOOO0000000000x;........... ;kdxOolxkl::;'..;:cdkO0Ok;.cxxkOOOkOK0KK00OkkOkl.  .';codxo;..:x0KKKKKKKKKKKK0xlcclx0d. .lOkxdoc:;;;;;;::cloxkkxxxkkkkkkkkkkxxxdddddddxxkkkkkkkkkkkkkkkkkkxxdddx    //
//    KKKKKKKKKKKKKKKKKKKKKKKK0000000000KKKKKKKKK00000KKKKKKKK0000KKKKKKK00000000000KKKKKKK000000KKKKKKKKKKKKK000OOOOOOO0000000000000Odl:'..'lddolokOOOkxkkkkxxxddoloxxkOOko;,,',;::;okOX0OOOOxc. ..,:loxxd:..;x0KKKKKKKKKKKkdooodO0XXd.  .:;;;;;:cldxkOOOOOOkxxxkkOOOkkkkkkxxdddddddxxkkkkkkkkkkkkkkkkkkkxxdddxxk    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKK000KKKKKKKKKKK0000KKKKKKKK0000KKKKKKK00000000000KKKKKKKK00000KKKKKKKKKKKKKK00OOOOOOO00KK0000KKK000000KO:..;dkkkkkxxkkxxxkkkkxkOkkOkxxkkkkkxxolllc;cooko'',;,. ..;:cdxxo;..;x0KKXXXXKKKKOollok0K0Oxo:. .,:coxkOOOOOOOOOOOkkxxkkOOOOOOkkkkxxdddddddxxkkkkkkkkkkkkkkkkkkkkxddxxkkkk    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK000KKKKKKKKKK000KKKKKKKK0000000000KKKKKKKK00000KKKKKKKKKKKKKK000OOOOOO00KK00000KKKK0000KOo' 'cdkkkkkkkkkkxxkkkkkkO0KK0kkkkxxkkkOkxkOkk0OO0dolc:;;;:::cdxxc..,x0KKXXXKK0KKxoodOKKOdc:;,.  .lOOOOOOOOOOOOOOkkxxkkOOOOOOOOkkxxxdddddddxxkkkkkkkkkkkkkkkkkkkxxxxxxkkkkkk    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK000KKKKKKKKKK000KKKKKKKKK000000000KKKKKKKK0000KKKKKKKKKKKKKKK000OOOOO000KK0000KKKKKKK0000Kk, .,okkkkkkkkkkkkkkkkkkkkOKX000OxkO000K00K0kkkkxxxkkkkkkxxdodxd; .lOKKXXKKKKKKkllkK0xl:;;cxOc. .oOOOOOOOOOOOOOkxxxkOOOOOOOOOkkxxxxxxxxdxxkkkkkkkkkkkkkkkkkkkkkxxxkkkkkkkxxd    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00KKKKKKKKKK000KKKKKKKKK0000000000KKKKKKKK000KKKKKKKKKKKKKKKK00OO0OO000KK0000KKKKKKKKKKK0K0o..,lxkkkkkkkkkkkkkkkkkkkkkO0XX0kkOKXXXXXXKkxxxkkkkkkkkkkkxxkkkxl;,;dOk0KKKKOxxxkOxl:clxO0X0c  'dOOOOOOOOOOOkkxxkkOOOOOOOOOkkxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkxxkkkkkkkxxddd    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00KKKKKKKKK000000000KKKKKKKKK000KKKKKKKKKKKKKKKK0000000000KK0000KKKKKKKKKKKKKK0o. ,lxkkkkkkkkkkkkkkkkkkkkkkkkO0Ok0XXXXXXXKkxkO0KX0kkkkkkxxxxxkkkkxxkkl''o00kdk0xl:cdOKXXXXO;  ;x0OOOOOOOOOkxxkkOOOOOOOOOOkxxxxxxxxxxxkkkkkkkkkkkkxxxxkkkkkkkkkkkkkkkxxdddddd    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00KKKKKKKKKK00000000KKKKKKKKKK00KKKKKKK00KKKKKKK0000000000KKK000KKKKKKKKKKKKKK00d. 'lxkkkkkkkkkkkkkkkkkkkkkkkkkkkk0XXXXXXXX0O0KXXXXX0OkkkxxxxkkkkkxxkkkkdlldkkxoloxxxxxOKXXd. .lOOOOOOOOOkkxkkkOOOOOOOOOkkxxxxxxxxxxxkkkkkkkkkkkxxxxkkkkkkkkkkkkkkkkxxddddddxx    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK000000000KKKKKKKKKKKKKKKKKKK0KKKKKKKK000000000KKKK0KKKKKKKKKKKKKKKK0Ol. .cdkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOKXXXXXXXXXXXXXXXXKOkxkkkkkkkkkkkkkkkOOxxdc:codolloxOK0l. 'dOOOOOOOkkxxkOOOOOOOOOOOkkxxxxxxxxxxxkkOOkkkkkkkxxxxkkkkkkkkkkkkkkkxxdddddddxxxd    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000000KKKKKKKKKKKKKKKKKKKKKKKKKKKK000000000KKKKKKKKKKKKKKKKKKKKK00Oc. 'cdkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk0XXXXXXXXXXXXXXXXKOkkkkkkkkkkkkkkkkkkkkkx;..o0KKKKX0;  :k0OOOOOkkxkkOOOOOOOOOOOkkxxxxxxxxxkkkkOOkOOkkkxxddxkkkkkkkkkkkkkkkxxddddddxxkxddd    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK000000000KKKKKKKKKKKKKKKKKKKKK00Ok:  ':okkkxdoolllodkkkkkkkkkkkkkkkkkkkkkkk0XXXXXXXXXXXXXXXXK0kkkkkkkkkkkkkkkkkkkkkx:..l0KKXO; .lOOOOOOkxkkkOOOOOOOOOOOkkxxxxxxxxxkkOOOOOOOOkkkxxxxxkkkkkkkkkkkkkxxddddddxxxxxddddd    //
//    XKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK000000000KKKKKKKKKKKKKKKKKKKKK00OOk;  .:ldlccc:::cc:;,,okkkkkkkkkkkkkkkkkkkkkk0XXXXXXXXXXXXXXXXX0kkkkkkkkkkkkkkkkkkkkkkc..xKXk, .oOOOOkkxkkOOOOOOOOOOOkkxxxxxxxxxkkOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkxxddddddxkkxxddddddd    //
//    XXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000000KKKKKKKKKKKKKKKKKKKKK00000O:  .:c::codxxdollldd:',coxkkkkkkkkkkkkkkkkkkkk0000KXXXXXXXXXXXX0kkkkkkkkkkkkkkkkkkOkkxc.;Ox. .d0OOkkkkOOOOOOOOOOOOkkxxxxxxxxkkOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkxxxddddxxxkkxdddddddddd    //
//    XXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000000KKKKKKKKKKKKKKKKKKKKKK0000K0c  .;codxo:,........'clc;,,,cxkkkkkkkkkkkkkd;,;:lodOKK00KXXXXXXXX0kkkkkkkkkkkkkkkkO00Okx,... 'dOkkkkkOO00OOOOOOOOkkxxxxxxxkkOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkxxdddddxxkkkxdddddddddddd    //
//    XXXKXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0000000KKKKKKKKKKKKKKKKKKKKKK0000KK0l. .;:od:....,;:clllc;'.;oxd:.'cdkkkkkkkxl:;,:dkkkxoc,....';::cld0X0kkkkkkkkkkkkkkkk0KKOk:   ;xkkkkOOOOO0OOOOOOOkkxxxxxxkkkOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkxxddddxxxkkxxdddddddddddddd    //
//    XXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000KKKKKKKKKKKKKKKKKKKKKKK000KKKKKo.  ',,,. .;loooddxxxxdoc..ckk:. :kkkkkkl,,codoc;'....,;::;;,,''...cO0kkkkkkkkkkkkkkkOKKOkc  ;xkkkOO000OO00OOOkkkxxkxxkkOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkxxxdddxxkkkkxxdddddddddddddddx    //
//    XXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000KKKKKKKKKKKKKKKKKKKKKKK000KKKK0kl.   ....,:looodxkOOOOOkxdl..lOl. ;kkkkd;'cdo;....,;clooooooooooooc. .dOOkkkkkkkkkkkkk0KKOx' .dkOO000000O000OkkkxkkxkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkxxxxxxxxkkkkxxddddddddddddddxxkk    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000KKKKKKKKKKKKKKKKKKKKKKK000KKKKOl,...,;::clooooooodkOOOO0KK0xd;.;Od. ;kkkd''ol' .':looooooddxxxdddooool;..:kkkkkkkkkkkkkO0K0k:  cO000000000OOOkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkxxxxxxxkkkkxxdddddddddddddxxxkkkkk    //
//    XXXXXXXXXKXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0K00KKKKKKKKKKKKKKKKKKKKKKK000KKKKOl...;coooooooooooooooxkOOOXWWKOxc.,OKxokKKKxcc, .,looooooodxkOOOOOOOO0Oxoo:. :kkkkkkkkkkkkOKK0o. 'x000000000OOkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkxxxxxxxkkkkxxddddddddddddxxxkkkkkkkk    //
//    XXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0KKKKKKx' .:oooooooooooooooooooxOOO0KK0Okc.,0NXXXXXXO:..,cooooooooodkOOOOOOO0XWN0xoo; .oOkkkkkkkkkO0KKk' .o00000000OOkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkxxxxxxxkkkkkxxdddddddddddxxxkkkkkkkkkkk    //
//    XXXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKd. ,looooooooooooooooodkO0K0OOOOOOk; cKXXXXX0l. 'cooooooooooodkOOOOOOOOKKKOOxdl' ,O0kkkkkkkk0KK0c  ;O000000OOkkkkkkkOOOOOO0OOOOOOOOOOOOOOOOOOOOOOOOOkkxxxxxxkkOkkkxxdxxxddddddxxkkkkkkkkkkkkkkx    //
//    XXXXXXXXXXXXXXXXXKKKXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKd. ,loooooooooooooooodOXWWMWN0OOOOOl.'OXXXXKx' .:oooooooooooooodkOO0KXXK0OOOOkdo:..xXOkkkkkkO0K0o. .d00000OOkkkkkkOO000OOOO0OOOOOOOOOOOOOOOOOO                                                      //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SA1 is ERC721Creator {
    constructor() ERC721Creator("Splat Act I", "SA1") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xEB067AfFd7390f833eec76BF0C523Cf074a7713C;
        Address.functionDelegateCall(
            0xEB067AfFd7390f833eec76BF0C523Cf074a7713C,
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