// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CDB: LOST LEGENDS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//    WWNXO, ;KWNNKc .kWNNXd..lNWNXk, ;KWNNKc.                                                         :0XNWX: 'kXNWNd..oXNNWO' :0NNWX: 'kXNWNo.                //
//    WXo';dO0NWx,'lk0XW0:':xOKWXl';dO0NWx,'lkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOko,'dNNKOx;.cKWXOkc';OWN0Oo,'dNNKOd;'cKWXOOOOOOOOOOOOO    //
//    lllcdKWKdllclOWXxllllxNWOollcdKWKdllclOWXxllllllllllllllllllllllllllllllllllllllllllllllllllllxXW0ocllo0WXdclllkNNklcllxXW0ocllo0WXdccllllllllllllllll    //
//    .,kWNKOd,.oNWK0x:.:0WX0Ol.,kWNKOd,.oNWK0k:....................................................;x0KNNd''oOKNWO,.ck0XWKc.;x0KWNd''oO0NWO;...............    //
//    XXNW0;.;OXXNXl.'xXXNNx..lKXNW0;.;OXXNXl.'xXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXk,.cKWXX0:.,OWNXKo..dNNXXk'.cKWXX0:.,OWNXKKKKKKKKKKKKKKK    //
//    WXd;:odONWk:;ldkXWKl;cdx0WXd;:odONWk:;ldkXW0l;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;c0WXkdl::xNNOxo:;oXWKxdc;c0WXkdl::xNNOdo:;;;;;;;;;;;;;;;;;;    //
//    ddc;l0WXkdl;:kWNOdo:;dXW0xdc;l0WXkdl;:kWNOdo:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:odkXWOc;ldxKWKl;cox0NNx;:ldkXWOc;ldxKWKo;;;;;;;;;;;;;;;;;;    //
//    ..xNNXXx'.lXWXXO;.;0WNXKl..xNNXXx'.lXWNXO;.;0WNKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXWK:.,kXXNNo..dKXNWk'.c0XNWK:.,kXXNNo..dKKKKKKKKKKKKKKKKKKKKK    //
//    O0XWK:.:x0XWNo.,dOKNWk,.lO0XW0:.:k0KWNo.,dOKNWk,........................................'xWNK0d,.lXWX0k:.;0WN0Ol''xWNK0d,.lXWX0k:.....................    //
//    WNxllllxXWOlclldKWKdccloOWNxccllxXWOlclldKWKdccllllllllllllllllllllllllllllllllllllllllllcco0WKdllclOWNklllcxXW0ollco0WKdllclONNklllllllllllllllllllll    //
//    Ox:':0WX0kl',xWN0Od;'lXWKOx:.:0WX0kl',xWN0Od;'lXWKOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOKWNo',oO0NWk;'lkOXWKc':xOKWNo',oO0NWk,'lkOOOOOOOOOOOOOOOOOOOOOOO    //
//    ..dXXNNk'.cKXNN0:.,OXNNXo..dXXNNx'.cKXNN0;.,OXNNXo....................................cXNNXO;.;0NNXKl..xNNNXx'.cXNNXO;.;ONNXKl........................    //
//    xkKWKl,:dx0WNd;;oxONWO:,lxkKWKl,:dx0WNd;;oxONWO:,lxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl;;kWNOxo:,oXWKkdc,c0WXkxl;;kWNOxo:,oXWKkxxxxxxxxxxxxxxxxxxxxxxx    //
//    WNOdoc:dXW0doc:l0WXxol::kNNOdoc:dXW0doc:l0WXxol::kNNOddddddddddddddddddddddddddddddkNWOc:loxKWKl:cod0WNd:codkNWOc:loxKWKl:codddddddddddddddddddddddddd    //
//    KO:.,OWNXKo..dNNXKx,.cXWXKO:.,OWNK0o..dNNXKx,.cXWXKO:..............................;OKXWXl.'dKXNNx'.l0KNW0;.;OKXWXl.'dKXNWx'..........................    //
//    .'o0KNWk,.cOKXWKc.;x0XWNo.'o0KNWk,.cOKXWKc.;x0XWNo.'o000000000000000000000000000000d'.lXWX0k;.:0WNK0l.'xWNK0d'.oNWX0k;.:0WNK00000000000000000000000000    //
//     .dWKdccloONNkccloxXW0lclod0WXd:cooONNkccloxXW0lclod0WXd::c::cc:::::::::::cc::c:oKWKdolclOWXkolccxNWOooc:oKWKdolclOWXkolccc::::c::::::::::::c:ccc:cxNW    //
//     .dWO' ,KWKkxc':OWXOko,,xNN0kd:'lXWKkxc':OWXOko,,xNN0kd:'''''''''''''''''''''''';ok0NWx;,lkOXW0c'cxkKWXo';dk0NWk;,lkOXW0c'''''''''''''''''''''''.  ;KW    //
//     .dWO' ,KNo..oXNNNk'.:KNNNK:.'kNNNXo..oXNNNk,.:KNNNK:.,kNXXXXXXXXXXXXXXXXXXXXXXNO,.;0NNNKc.'xNNNNd..lXNNNO,.;0NNNKc .xNXXXXXXXXXXXXXXXXXXXXXKXXNx. ;KW    //
//     .dWO' ,KNo  oNXl':dk0NNx,,okOXWO:'cxkKWXl':dk0NNx,,okOXWO:'''''''''''''''''';kWN0ko;,dNWKkd:'cKWXOkl,;kWN0ko;,dNX:  .''''''''''''''''''''''':OWk. ;KW    //
//     .dWO' ,KNo  oWK, 'OW0dolcl0WXxolcckNNOolc:dXWKdolcl0WXxolcc:c:::::::::c::ccccloxKW0occod0WXdcclokNNkccloxXWx. :XNkcc::c:::::::::cc::c::cc:. .xWk. ;KW    //
//     .dWO' ,KNo  oWK, 'OWd. lNWX0x;.cKWXKOc.,OWNK0o'.dNNX0x;.cKWXK000000000000XNWXl.,x0KNNd..l0KNWO;.:OKXWK; .kWx. ;O00000000000000000000000XWX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, '0Wd. cNXc.,xKXNNd..o0XNWO,.:OKXWXc.,xKXNNd.............oXNWXKk,.:KWNK0c.,kWNXKo..oNK; .kWx.  ........................lNX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, '0Wd. lNK; .kW0l:cod0WXd:codONNk::loxXW0l:coddoodoodoodol::cOWXkol::xNNOdoc:oKWd. lNK; .kWKxoddoooddddoddddddddddod:  :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XWWW0, '0WKkxc,:OWNOxo;;dNWWWWWWWWWWWNx:;;lxOXW0:,cdkKWK, 'OWd. lNK; .cxxxxxxxxxxxxxxxxxxxxxxxOXWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XWNXO; ,0Wd. lXNNXO,.;0NWWWWWWWWWWWWWWWNNK:.'kXNNNo..oN0, 'OWd. lNX:  ......................  .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XNo',oO0NWd. lNXl';dO0NWWWWWWWWWWWWWWWWWWNKOd;.cKNo  oN0, 'OWd. lNNKOOOOOOOOOOOOOOOOOOOOOOOx' .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XX: .xWKdllclOWK; .;lxXWWWWWWWWWKdlllllllo0W0' ,0Wo  oN0, 'OWd. 'clllllllllllllllllllllloOWK; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XX: .xWk. ;KWX0x'  ..;x0KWWWWNK0o.  .....'o0d. ,0No  oWK, 'OWk,........................  lNK; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XX: .xWk. ;XNo.   .xXd..cXWWWK;.   ,OXXXX0:.   ,KNo  oNK, 'OWNKKKKKKKKKKKKKKKKKKKKKKXKl. lNK; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XX: .xWk. ;KNl    .kWx. .,:kWK,    ;KWWWWX;    ,0No  oW0, 'OWOc;;;;;;;;;;;;;;;;;;;;oKWd. lNK; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XX: .xWk. ;KNx:,. .cd:  .,:kWXo;'  .odddddc;'  ,0No  oW0, .cdl:;;;;;;;;;;;;;;;;;,. '0Wd. lNK; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XX: .xWO,.:0XNWK;   .   ;0XNWWWWO, .......xNO' ,0No  oN0,   .cKWXKKKKKKKKKKKKKNW0, 'OWd. lNX; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XX: .xWN0Oo''dNK; .o0l.  .'xNWWWN0OOOOOOO0XWO' ,0No  oN0, .d0KNNd............'xW0, 'OWd. lNX; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XNkllccdXWd. lNK; .kWKdlllo0WWWWWWWWWWWWWWWWO' ,0No  oNXxlxXW0oclllllllllll'  oW0, 'OWd. lNX; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWO;'ckOXWK, 'OWd. lNK; .oOOOOOOOOOOOOOOOKNWWWWWWWO' ,KNo  :k0XWN0ko,'dNNKOOOO0NNo  oN0, '0Wd. lNX; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oWK, 'OWd. lNX: .kNNXXo..dNK, 'OWd. cNK;   ...............cXWWWWWWWO' ,KWo.  .'kNO,.:0XNNK:..  ;KNo  oW0, 'OWd. lNX; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oWK, 'OWd. lNN0xd:,oXNo  oNK, 'OWd. lNK; .cxxxxxxxxxxxxxxx0NWWWWWWWO' ,KWKkxxxd:,:ox0NNx;;lxl. ,0Wo  oW0, 'OWd. lNX; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,KNo  oW0, 'OWOc:loxKWO' ,KWo  oWK, 'OWd. lNK; .kWWWWWWWWWWWWXxdONW0ddxKW0' .cdodoodoc:oKWKxol:cOWO' ,0No  oW0, 'OWd. lNX; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,0No  oWK:.,kKXNNl .dWO' ,KWo  oNK, 'OWd. lNK; .kWWWWWWWWWWWWk. ;KNl. .dW0'  .......'dKKKKo..oNWXKk,.:KNo  oWK, 'OWd. lNK; .kWx. :XX: .xWk. ;KW    //
//     .dWO' ,0No  oNNK0x,.cXNl .dWO' ,KWo  oNK, 'OWd. lNX; .kWWWWWWWWWWWWk. ;XNc  .dWO' 'x000000k;....:kKXWXc.,x0KNNo  oN0, '0Wd. lNK; .kWx. :XX: .xWk. ;KW    //
//     .dW0' ,0W0dlc:l0Wk. ;XNl .dWO' ,KWo  oNK, 'OWd. lNX; .kWWWWWWWWWWWWk. ;XNc. .dWXxokXWOc:cc;. .:okNNkc;. .kW0lccld0W0, 'OWd. lNK; .kWx. :XX: .xWk. ;KW    //
//     .dWKc':dkKWX: .xWk. ;KNl .dWO' ,KWo  oNK, 'OWd. lNX; .kWWWWWWWWWN0ko;'oXNx;,,okOXWWWNx,'''''':dk0NNx,'. .kWx. :XWKkd:'cKWd. lNK; .kWx. :XX: .xWk. ;KW    //
//     .dXNNNx. cXX: .xWk. ;KNl .dWO' ,KWo  oNK, 'OWd. lNX: .kNNWWWWWWWK; 'kXXWWNXXO; 'OWWWWNNNNNNNNk'.:KNXXO; 'OWx. :XXc .xNNNNd..lNK; .kWx. :XX: .xWk. ;KW    //
//    kxc'c0Wx. :XX: .xWk. ;KNl .dWO' ,KWo  oWK, 'OWd. lNN0kd:'lXWWWWWW0,  .'oXNx;,.  .kWWWWWWWWWWWWXOko,''',okOXWx. :XX: .xW0:'cxkKWK; .kWx. :XX: .xWk. ;KW    //
//    WX; .kWx. :XX: .xWk. ;KNl .dWO' ,KWo  oWK, 'OW0lclod0WO' ,0WWWWWWXdc,  .cl'   ':oKWWWWWWWWWWWWWWWd. .:l0WXxolcckNX: .xWk. ;KWOolc:oKWx. :XX: .xWk. ;KW    //
//    WK; .kWx. :XX: .xWk. ;KNl .dWO' ,KWo  oWK:.;x0XWNl .dW0:.;k0XWWWWWWWO;.......'xWWWWWWWWWWWWWWWWWWd. cNWX0x;.cKWXKOc.,kWk. ;XNl .dWNK0d'.lNX: .xWk. ;KW    //
//    WK; .kWx. :XX: .xWk. ;KNl .dWO' ,0Wo  oNNXKx,.cXNl .dNNXKd'.lXWWWWWWNXKKKKKKKKNWWWWWWWWWWWWWWWWWNd. lNXc.,xKXNNd..o0KNWk. ;KNl .dW0;.;kKXWX: .xWk. ;KW    //
//    WK; .kWx. :XX: .xWk. ;KNl .dWO' ,0W0doc:l0Wk. ;KW0doc:lKWx. :XWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWKl:cod0WK; .kW0l:cod0WXd:codONNl .dW0' ,0WOc:loxKWk. ;KW    //
//    WK; .kWx. :XX: .xWk. ;KNl .dWKl,:dx0WX: .xW0c,cdkKWX; .kWO:,cdxxxxxxxxxxxxxxxkKWWWWWWWKkxxxxxxo:,oXWKxdc,c0Wx. :XW0kd:,lKWKkxl;:OWO' ,KWo  oNNOxo:,oXW    //
//    WK; .kWx. :XX: .xWk. ;KNl..dXNNNx. cXX: .xWWNNd. lNX: 'kXXNNo.  ..    ........dXNNWNNXo.......;ONNXKl..xNNNXx..cXXc .xNNNXd..oXNNXk, ;KWo  oWK, 'ONNXX    //
//    WK; .kWx. :XX: .xWk. ;XWKOx:.:0Wx. :XX: .xWWWWd. lNNKOx;.cKNo  :kd. .oOOOOOOOx:.:0WO;'ckOOOOOO0NWk,'ckOXWKc.:xOKWX: .xW0:':xOKWXl';dO0NWo  oW0, 'OWk,.    //
//    WK; .kWx. :XX: .xWKdccloONK; .kWx. :XX: .xWKdllclONNkllccxXNo  oW0, 'OWWWWWWWK; .kWx. :XNkllllllllclONNkllccxXW0ollco0Wk. ;XWOolccdKWKdllclOW0, 'OWd.     //
//    WK; .kWx. :XNo.,dOKNWd. lNK; .kWx. :XX: .xWk. ;KWX0k:.;0WN0O:  oW0, 'OWWWWX00x' .kWx. :XX:  .....lXWX0k:.;0WN0Ol''xWNK0d,.lXNl .dWNKOd,.oNWK0k;.:KWd.     //
//    WK; .kWx. :XWXXO;.;0Wd. lNX; .kWx. :XX: .xWk. ;KNo..oKXNWk'.   oW0, 'OWWWXo...  .kWx. :XX: .dXXKKXNNo..dKXNWk'.c0XNWK:.,kXXNXl .dW0;.;OXXNXl.'xXXNNd.     //
//    WK; .kWXkdl;:kWK, 'OWd. lNK; .kWx. :XX: .xWk. ;KNl .dWKl;codddxKWK, 'OWO:;ldddddkXWx. :XX: .xW0l;;;;ldxKWKo;cox0NNx;:ldkXWO:;ldxKW0' ,KWk:;ldkXWKl;cdd    //
//    WXd;:odONNo  oW0, 'OWd. lNK; .kWx. :XX: .xWk. ;KNl .dWKl;coddddddoc;lKWOc;lddxdddddo:;xNX: .xWk. .,:xNNOxo:;oXWKxdc;c0WXkdl::xWNOxo:;oXNo  oWNOdo:;dXW    //
//    XXNWO' ,KNo  oNK, 'OWd. lNK; .kWx. :XX: .xWk. ;KNo..dKXNNk'......'kNNXXXNNo........:KWNX0c.'kWk. ;KNNX0:.,OWNXKo..dNNXXk,.cKWNX0:.,OWNXKo..dWK, 'OWNXX    //
//    .,kWO' ,KNo  oN0, 'OWd. lNK; .kWx. :XX: .xWk. ;KWX0k:.;0WX0O0OO0O0NW0;.lXWX0000000OKNWx''lO0XWO. ;KNd''oO0NWO,.ck0XWKc.;x0KWNd''oO0NWO;.ck0XWK, 'OWk,.    //
//     .dWO' ,KWo  oN0, 'OWd. lNK; .kWx. :XX: .xWKdllclONNkllcccccccccccccclllccccccccccccccllo0WXxclllkNNl .dWXdccllkNNklcllxXW0ocllo0WXdclllkNNkllllxXWd.     //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :XNo',oO0NWk,'lkOXWKc............cKWk,............'oNWKOx:.cKWXOkl',kWO' ,KWXOkc';OWN0Oo,'dNNKOd;.lKWXOkc';OWN0Oo,'    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWx. :KNNXO;.;0NNXKl..xNNXKKKKKKKKXXKKXNNXXKKKXKKXKXKKKKXNXc.'xXNNNx..lKXNNO' ,KWd..oXNNNO,.:0XNNK:.'kXNNNo..oXNNNO,.:0X    //
//     .dWO' ,KNo  oW0, 'OWd. lNK; .kWXkxl;;kWNOxo:,oXWKkdc,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;lxkXW0c,cdkKWXo,:oxONWo  oNXo,:dx0NNx;;lxOXW0c,cdkKWXo,:dx0NW    //
//     .dWO' ,0No  oWK, 'OWd. lNNd:clokNWOc:loxKWKl:cod0WNd:::::::::::::::::::::::::::::::::::cOWNkdoc:dXW0doc:lKWKxol:cOW0, '0WKxol:cOWXkolc:xNNOdoc:oKWKxo    //
//     .dWO' ,KNo  oNK, 'OWx'.l0KNW0;.;OKXWXl.'dKXNWx'.l0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk;.;0WNK0l.'xWNXKd'.lXWXKk;.;0Wd. lNNXKk,.:KWNK0c.,kWNXKo..    //
//     .dWO' ,KNo  oNK, 'OWXKOl.'kWNK0d'.oXWXKk;.:0WNKOl.........................................'d0KNWk'.lOKNW0:.;kKXWNo.'d0KNWd. lNXc.,x0KNNx'.l0KNWO;.:O0    //
//     .dWO' ,KNo  oNNkolccxNWOolc:oKWKdolccOWXkolccxNWOooooooooooooooooooooooooooooooooooooooooodKWKoccooOWNxcclokXWOlclodKWKo:cloOWK; .kW0oclod0WXdcclokNW    //
//     .dWO' ,KWk;,lkOXW0:'cxkKWXo';dk0NWk;,lkOXW0:'cxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkd;'oXWKkxc'c0WXOkl,;kWN0kd;'oXWKkxc'c0Wx. :XWKkd:'cKWXOk    //
//     .dW0, ,0NNNKc.'xNNNNd..lXNNNO,.;0NNNKc.'xNNNNd...............................................,ONNNXl..dNNNNx'.cKNNN0;.,ONNNXl..dNNNNx. cXXc .xNNNXd..    //
//     .dWN0ko;,dNWKkd:'cKWXOxl,;kWN0ko;,dNWKkd:'cKWXOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk0NWk;,lxOXWKc':dkKWNd,;ok0NWk;,lxOXWKc':dkKWX: .xW0c'cxk    //
//    ccloxKW0lccod0WXdcclokNNkccloxKW0l:lod0WXdccloooooooooooooooooooooooooooooooooooooooooooooooooooolcckNNkolccdXW0dol:l0WKxolcckNNkolccdXW0dolcl0Wk. ;KW    //
//    WXc.,x0KNWx..l0KNWO;.:OKXWXc.,x0KNNx'.l0KNWO;....................................................lXWXKO:.;OWNK0l.'xNNK0x,.cXWXKO:.;OWNK0l.'dNNK0x,.cXW    //
//    WNXKk,.:KWNK0c.'kWNXKo..oNNXKk,.:KWXK0c.'kWNKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXWNo..oKKNWk'.c0KNWK:.,kKXNNo..oKXNWk'.c0KXWK:.,kKXNW    //
//    :cOWXkol::xNNOdoc:oKWKxol:cOWXkol::xNNOdoc::::::::::::::::::::::::::::::::::::::::::::::::::::::::::loxKWKo:codONNx::ldkXWOc:loxKWKo:codONNx::lokXWOc:    //
//     .dWWWWx. :XWWWK, '0WWWNl .dWWWWx. :XWWWK,                                                          lNWWW0' ,KWWWX: .xWWWWd. lNWWW0' ,KWWWX: .xWWWWd.     //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CDBLL is ERC721Creator {
    constructor() ERC721Creator("CDB: LOST LEGENDS", "CDBLL") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1;
        Address.functionDelegateCall(
            0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1,
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