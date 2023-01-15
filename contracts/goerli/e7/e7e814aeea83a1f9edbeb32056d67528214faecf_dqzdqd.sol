// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: zqdqd
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOKNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXK0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxoONNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXKXN0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkdxkxkOOOOOOOOOOOOOOOOOOOOOOOO000OOOOOOO00OOOOOOOOOO00OOOOO0OOOOOOOOolkOkOOOOkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkdxOOOOOOOOOkkOOOk0NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNX0XXkxOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOkkOOOOOOOOOOOOOOOOOOxdoodOOOOOOOOOOOOOOOOOOOO00O00OOOOOOOOO00OOOOOOOOOOOOO0OOOOOOOOOkkOolkkxkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkOOOOOOOOOOddOOOOKNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNX0XNkoxOOOOOOOOOOOOOOdlllllllllllllllllccllllldOOOOOOxdkOOOOOOOOOOOOxxkkkOOxocoOOO00KKKOkOO000O0KXXXKKOOOO0OOO0KK0OOOOOOOOOOOOOOOOOOOOOOOkOOolkxxkOOkOOkkkOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxkOOOOxxkOOOkkOOOk0NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNX0XXkooxkOOOOOOOOOOOOoccccccccllllccccc:ccccccdOOOOOOOOOOOOOOOOOOOOOxxkxxOkxxdok0KXNN000okXNNNXXNX0OKKOOOOOOOO000O0000OOOOkkO000OOO000OOOOOOolddkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxkOOOkkOOOOOkkkxkkkkOOOOKNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKxddONNNNNNNNNX0XXkoooxkOOOOOOOOOOkoccccccldkOOxoddoccccccccdOOOOOOOOdoooooooxOOOOOOO0KXKOkO0KXNNN0;;c;kNNNNNNNNXK0OO00KK00OOO0KKK00KK0OO0KK000KK00KKOOOOOxdxkOkOOOOOOOOkkOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxOOOOOOOOOOOOOOOkodkOolxxxOOkx0NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXOkkKNNNNNNNNNX0XXkooooddddddddkOOkocccccclodollllllccccccccdkOOOOOkkxoc;;;;;;:oOOOO0XNNNNNNNNNNNNXx,,xXNNNNNNNNNXKKXNNNNNNKKXNNNNXKKXXKXNX0OOO0K0OKK00KXXXXNNXXK0OOOOOOOOOOOOOxxOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxOOOOOOkdokOOOOOx:;clc;cdxkkkx0NNNNNNNNNNNKOOkOOOOkkOKNNNNNNNNNNNNNNNXK000000000000KNNNNNX0XXkooooooooooodkOOkoccccccccccccccccccccccccoxddddxdddol;.....;okOOOKNNNNNNNNNNNNNN0x0NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNX0OOO0KXXNNNNNNNNNNNNNXKOOOOOOOOOOOxxOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOkOOOOOOOOOOOOOOxl:loodoc;:;;:;;;:cllo0NNNNNNNNNNNX0kkkOOO000XNNNNNNNNNNNNNNNXkxxxxxxxxxxxxOXNNNNKkOk:'''',:ooooodkOOkoccccccccccccccccccccccccoooooooooooooc,.,clodxxdkKNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNK00XNNNNNNNNNNNNNNNNNNK0OOO00OOOkkOOOOOOOOOkkOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOxxOOOOOOOOOOOOOOko:;;;;;;;,,:;;;;;;;:ONNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNOoxl.     ,ooooodkOOkoccccccccodxxxkxxxxxxxxxxkkxxxxxxxxxxxxdolllooooooONNNNNNNNNNNNNNNNNNNNNX0OOOO00KXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXNNNNNNNNNNNNNKOO000000kxkkOOOOOOOkkOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkOOOOOOOOkd:;;;::;;:::::;;;;;cONNXKKKKKKKKKKKKKKXNXKKKKKKKKKKKKKKKKKKXNXKKKKKKKKKKKKKKXNNOoxc.     ,ooooodkOOkocccccclkKKKKKKKKKKKKKKKKOk0KK00000000000OOd:cooooONNNNNNNNNNNNNNNNNNNNNXOkkOO00KXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXKKK0KNNNNNNNNNNNNKO00000OOOOkOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOkdkOOOOOkkdc;;;;;;;;;;:;;,,;;;cONNXKKKKKKKKKKKKKKXNXKKKKK00KKKKKKKKK0KXNXKKKKKKKKKKKKKKXNNOodc.     ,ooooodkOOkoccccccxKK000000000kk0OkkxxkkO0000000000OO0Kl':::ckNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXX000KXNNNNNNNNNNNNXXNNNXXXKOOkkkOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkdc:::;;;;;;;,;;;:;cONNXKKKKKKKKKKKKKKXNXKKKKKKKKKKKKKKKKKKXNXKKKKKKKKKKKKKKXNNOodc.     ,ooooodkOOkoccccclOX000000000OllOOddooodk00000000000O0Kd,.  .dNNNNXKKKKKKKKKKKKKKKKKXNXKKKKKKKKXXXXXXXXNNNNNXXXXXNNNNNNNXXKK00XNNNNNNNNNNNNNKOkkO0XXXXKOkkkOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxdxxdl::::;;;,,;;,;;;:;cONNXKKKKKKKKKKKKKKXNNKKKKKKKKKKKKKKKKKKXNXKKKKKKKKKKKKKKXNNOodc.     ,ooooodkkkkolllllo0X0000000000OO00K0kk000000000000000KKo,.  .dNNNNNKKKKKKKKKKKKKKKKKXNXKKKKKKXXXXXXXXXXNNNNNNXXXXNNNNNNNNXXKKXNNNNNNXXXXKKXNX0xddxkKXKX0OOOkOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkOOOOOxoool:;::;,;;,,,,,,;;;;cONNXKKKKKKKKKKKKKKXNXKKKKKKKKKKKKKKKK0KXNXKKKKKKKKKKKKKKXNNOodc.     ,oooooooooooooooodKOc,,,,,,,,;;;;;;;;::::::::::::::::k0l,.  .dNNNNXKKXXXKKKKKKKKKKKKXNXKKKKKKXXXKXXXXXXXNNNXXXXXNNNNNXNNXXXXXNNNNXXXKKKKKKKXNKkddddk0XX0OOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOkdkOOOkxOOOOOOOOOOkxl;,;;,;;,,',,,;;cONNXKKKKKKKKKKKKKKXNXKKKKKKKKKKKKKKKKKKXNXKKKKKKKKKKKKKKXNN0dxc.     ,oooooddoooooooook0o.                               .okc'.  .xNNNNXKKKKKNXKKKKKKKKKKXNXKKXKKXKKXXK0KXNNNNNNNNNNNNNNNNNNXKXXNNNNNNXXKK00KXXXNNNKkxxxxOKKOOO00OOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOkOOOOOOOOkkOOOOOkxdl;,,;;;;;,,;;;;;cOWNXKKKKKKKKKKKKKKXNXKKKKKKKKKKKKKKKKKKNNXKKKKKKKKKKKKKKXNN0dxc.     ,oooox0OdooooooooOO:.                               .kx;'.  .xNNNNXKKXKXNNK0KK00000KXNK0KXXKKXXXXXKXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXK000OOOO0KX0kddOK00KKKKKKOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkOOOOkxdl:;;;;;;od:;;::;;cOWNXKKKKKKKKKKKKKKXNXKKKKKKKKKKKKKKKKKKNNXKKKKKKKKKKKKKKXNNOdxc.     ,ooodkOOxdooooood0k,.                               ,Od;.   .xWNNNXKKKKKKKKKKKKKKKKKXNNNNNNNXKKKKKKNNNNNXXKKKKKKXNNNNNNNNNNNNNNNNNNNNNNXKOkxxxxOX0dx00OKKxodOX0OOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOkl;;,,,;dd;,;:;;,c0WNX00000000000000KNXK0000000000000000KXNXKK000000000000XNNOdx:      ,ooooooooooooooox0d.            .........'.         :Ol;.   .kWNNNXKKKKKKKKKXXXXXXXXNNX0OO0XX0KKKKXNNNNNNNXKKK000KNNNNNNNXXXXXNNNNNNNNNNNNX0kxkkK0xkOOO0Kkxk0K0OOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOkOOOOOOOkkOOOOOOxc,'''';dd;,::;,':OWNXKKKKKKKKKKKKKKXNXK0KK000KKKKKK0000KNNK0K0O000000000KXNNOod:      ,oooooooooooooook0l.             ..........        .okc,.   .kNNNNXK0KKKK00000000000XNKkxx0XKKKKKXNNNNNNNNNNNNXXXXXNNNNXXKKKKKXXNNNNNXXXXXNNKOkkK0xxkOOO00000OOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOkOOOOOOOOOOOOOOOOOOOOOOOxol:,.'',:x0xdxxc,.;ONNXKKKKKKKKKKK000XNXK0000000000000000KXKOkOOkO000000000XNNOoo;      ,oooooooooooooooOO:.                               .xx;'    .kWNNNXKKKKKKKKXNXXXXKK0OOKKOOOOO00XWNNNNXK0000000KXNNNNNNXKKXXXNNNNNNNNNNXKKKKXX0O0KKK0KK0OOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOkkOOOOOOOOOOOOOOOxxOOOOOOxxkkl;;;;;xXXXXXd'':0WNXKKKKKKKKKKKKKKXNXKKKKKKKKKKKKKKKKK0xlccx0KKKKKKKKKKKXNNOoo;      ,ooodxxdoooodddd0k,.                               'kd;.    .kWNNNXKKKKKKKKXNXOxxOKNN0kO0OkdxO0XNNKOkxdddddddddxk0XNNNXXXNNXXXXXXXXXXXXKKK0KX0xxkO0KXNNXK0OOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxxOOOOOOOOOxc,,;,,d0xxdo:;,c0NNXKKKKKKKKKKKKKKXNXKKKKKKKKKKKKKKKK0xl:,cOKKKKKKKKKKKKXNNOod:      ,oooxkkdoooxOkdkKd'                   .,,,,,,,,,,,,okl;.  ..'OWNNNXKKKKKKKKNNkccccxXNN0kOOOOKKKNKkddddooddddxddddddk0XNNXXXXXXXXXXXKKKK00000KK0KXNNNNNNNNK0OOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOxdkOOOOkxkOxddddddddddoddddxkOOo,,,,,lo;;;;;;':0NNXKKKKK00OO0KKKKXNXKKKKKKKKK00K0000xl:,ckKKKKK0000KKKKXNN0dx:      ,ooodxdoooo00ocoOo.                   'oooooolcccclOk:,.....,ONNNXKKXXNNNXXK0xooox0NX0O0KKKK0O0KxddoddkO0KKXXXKK0Oxoox0KXXKKKKKKXXXXK000OOO0XNNNNXXXKKXNNN0OOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOkkOOOOOxdkOdcccccccccccccccokOOd;,,,,;;,,,;,,':0WNX0OOkxkxk0K00K0XNXK0K0KKK00000KKKkl:,:kK000000000K00KXNNOxx:      ;oooooooooxK0olOOc.                   ,ooooolcccccokl,'.  ..,0NKOO00KXXKOkO0KXKKKKK0OkOXNNNNNXNX0kdxOKNNNNNNNNNNNNX0dccdkOOOOO0OOO0XXK00OOKNNNNNXXKK0KKKXNKOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOkoccc:cc::c::::ccokOOx:,,,,,'',,,,,':0WNKxccclxk00000KKXNXKKKKK000KXXXXXOo:,c0XKKKKKKKKKKKKKKXNN0xx:      ;oooooooook0l;:kk;.                   ,ooooolcccccdk:.,,;;,.;0Kx0KxoddoookKKKKKK0KXXXXO0NNNNXK00KXKXNNNNNNXKXXXXXXNN0c,;lxOkkO0OkxxkOKKK0KNNXXXXXXKKKXXKXX0OOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOkocc'.:;.';.....:okOOkxddodoc:::::c:l0NNX000OkOKKK00000XNX0000O0KXXKOxoc::;c0NXKKKKKKKKKKKKKKXNN0xkl,'''';d0kxxO0OxxKKdlxKx,.      .'.          ;ooooolcccccxOclO0KXOoo0OxXKolk0KXXX0xxkOOO0XXKKKXNNKkddoox0NNNNNNX00XNNNNXKXNNd',:dkkkkkkxxxxk0XNXNNNXXXXKKKK00KXXKOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOkxxkolc..:;..,..:'.,okkxOOOOOOkdoooooooxKNNXKKKKK00000000000O0XNNWNKkdocc:,;:ckXNXKKKKKKKKKKKKKKXNN0xkdcccccoKKdlcx0dolxkdclOo'      .,::,..      .;olllllcccccxxoddO0KKOdokOO00OOKKKK0kxkkO00KXNXXKKNKxdodddOXNNNNNKOkKNNNNNXKKXNk;,:oddxxxxdk0XNNNNNXKKKXX0OO0OkkkOKX0OOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOdooooxkolc..:;..,..'..;lxkkOOOOOOkdoooooooxKNNXK0KKKKKKKKKKOddk0XNNX0kdlc::c;,:oO0KXKKKKK0KKKKKKKKKXNN0kkdcccccdXXxlo00dod00dlxOc.      .;;,'..      .;cccccccccccxdddloxk0XklxkkOOOOOO0000K0kxOKXNNKkxxKOdddddkXNNNNN0kkk0XNNNNK00KXd,,::clooodOXNXXXNNXK00OO00kkkkkxxxkKXOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOxkkOOOkoc:..:;..,.....:clxkOkddkOkdoooooooxKNNX00000000K0kdxOXNNX0kxoc::;,;,;ok0KKXXKKKKKKKKKKKKK0KXNN0kkocccccxXkdlo0kolx0kolOO;.      ...          .;cccccccccclxlo0xoolcxxxXX00000000KXXXXX0OXNNXkddxKKKKKK0XNK0XNKkxkxkO0K00Okk0Ko;;,..,:cokXNKKKKKXKOOOkkkkkxxkxdddxKX0kOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOkxkOOkoc:..:;..,..:'.;ccokOxocclooollooooxKNNXKKKKKKK0Okk0NNNKOxdo:,cdxo:,:xKK0Okkkkkkkxdox0KKKK0KXNN0kkocccclOXxolkKxodO0dooOx,.                   .',''''''',':xl,:::codl:kNNNNXK0OxkkkO00kxOXNNKkx0XNNX0OOOXXkxOXKkxddxkxxxxO0KNNXXKOd;'',:kXX00KKKK00kkxddxxxxdddddxKKOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOkoc:..'..,;.....:ccokOkoool:,,;cooooxKNNXKKKKK0xxOXNNNKkxdoccoOXKkl;:ddlcccloooolc:;,lkO00KKKXNN0kkocccco0XkddOOdooO0dok0d'                                ,xl,...','.,ONNNNX0KX00XXNNXKKXX0kxxKNNNKkdddxK0xdxk0Odddxxxxk0XXXXXXXNNNXx:,,oKXOOOO0K0OxxxdodddddoooxKX0OOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOkocc:;,;:cc:;;;:cccokOkool::::::coooxXNNX0000kk0XNNNXOddoccx0KOkdc::llc:;:odxkOOOOOOOOkxxxxkOKNN0kkoccccdX0dookxlccxdc:lkl.                                ;o,'. .....;OWNNNNNKKX00XKOkx0KOxdoONNNN0xxdod00ddddxkxxxxdxkKXK00KKKXXXNNNO;';o0KOkkkOkxddddoddoooodOKKOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOkocccccccccccccccccokOkoolclooolclooxXNNX00OxkXNNNNKkddl:okxdol:,';:cll;';ccccoxxkkkOOOOOOOOOXNN0kkocccckX0xd0Kklo0XxcdKOc.                                cl,,. .....;0WNNNNNNXKKK0kx00KKOkxoOKOkO0kddoox0kdddddxddxxkKKO0XXXXXXXKKXNXl..;lk00OOkxdddoddxxxkk0XX0OOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOxdddddddddddddddddxkOkoooooooooooooxXNNK0xd0NNNNNXkdoc;col:;;:ldO00KK0OkkxdollldxkkO00000000XNN0kkocccl0Oodcoddlckxdoo0k;.                               .ll,'.  ....,x0OOOOOOO00OxoONNNNXKK0OOxoddkkdoooxOkdddddddxdOKO0K0OkO0XXK00XNd..';cokO0000000KKKKKK000KK0OOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkooooolcloooooxXNN0xkXNNNNNN0doc,;;;:lokKNNKkdxxxxxxxkkkxdooddkO00OOOO0XNN0kkoccco0KxdxOxoox0dood0x,.                               .oc,'.  ....,looooooooooocckXKOOO0XNNXK0kxdxxkO0KXXK0OkxddddkOOK0xkkkkOXOkOKNo..':ccodddxkOOK000Okkkxdd0X0OOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkOOOOOOOOxoooooolooooooxXNOdONNNNNNNKxxxdodxOKNNNX0kdc;;;;::c::::cclc:ldddxxxxO0XNNOxkoccclxOOOOOOkkOOOxxOOo'   ..,;:;..                     'o:,.  .....,loooooooooooook0O0XNNNXKKKXNXOk0XK0OkkkkO00OkdddxxO0Okxxk00kxOXO,...,;lddoodxkkkOOOOOkdooodKX0OOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOkdoooooooddddoxOOOOOOOOkoool:cooooooox0xxKNNNNNNNNXKXNNWWWNNXKOxdl:;;;;;cllodo:;clc;;lddxxxk00XNN0kkocccccccccccccccclcccc'..;lxkkxlcc:;'.                 ;l,'.  .....;oooooooooolodoxKXNNX0kxxddxkKNNKkdddddddddxkOkdddddxOkkkOOxxOKk,....,:loooodxkOOOO0OxolllloOX0OOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOkxxkkdooooxk00KKK0kxkOOkOOOxoo:...,cooooolokXNNNNNNNNNNNNNNXNNKOxdo:,,;:c;,;;:::cl;;olcccoododxO0KXNN0kkdccccccccccccccc::;;;,';lxkkkd:;c:;clc:;,.             :l,'.  .....;ooooooolllcddldKNX0kddddddddOX0dddddddddddddxkxddddddxxxxkO0Ol.....',:oodddxdoxO00xollllllo0X0OOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOkdooxkdoodOKNN0OOKNXOddxkOOOxool,..,coooocl0NNNNNNNNNNNNKOKK00Odlc:;,;looolloodoc::::oxxddddxxxxxkkOKXOxkoccccccccccccc:;;:cccc:;;:cclc:cc;cddlllcc:;'.        .cc''.   ....;odddddooooloolo0N0xddddddddd0Xkoddddddddddddddddddxkkkkkkxo;.  .;;,,,:ldkkdlloodOKxcccccllxXKOOOOkOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOkdodOXNXkdod0NNOooodxkOxooooccooool:dKNNNNNNNNNNNNNN0kkkoc;,:cllc::looodxkOOkxolddddddddddddxxkO0Oxkoccccccccccc;;;:cccccccclc:;;;;:;:oxxkkxolccc::;'.    .l:'.........:dOKK0kddoooolc:xXOddddddddddOXkoddxxdddddddddddddkk:'','..    ..,clooddddocllllodOOl:ccccdKKOOOOOkOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOkdoxKNXkdk0XNXOdoooooodoooooooooocckNNNNNNNNNNNNNNNNNXOdc',clllcc:;,;;;;:;,;cooldddddddxxxxdxxk00xodocccccccc:;;;ccccccccccccccccccc:;;::codxkkxolccc:;,'..:;'.........:d0K00OkOxoooolclk0Odddddddddx00xdddxkxxddddddxkOko;'''''''..  ..,;:looolcclolloloOOl:::oOKKOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOkdoOXNXKKNNXKOkxdooooooooooooool:o0NNNNNNNNNNNNNNNNX0ko:'.;odl::loooood0K0l;::;:cooodxxxxxxxxkO0Kxcllcccccc:cdkdlcloolccclllccccccclol:.   .,:ldxxxdocccc::;,'........'codkkkxxxoooooldkddkOOkxxxxxddxO0kddddxkkkkkkkxdl;;;:::::c::;.  .;ccllllccclllllodOkcoxOKK0OOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOkdok0000KXNNNNNXOdoooooooooooolcxXNNNNNNNNNNNNNNNXKkdc:;;:;co:;cloodO0xxO0l':llllodddxkkkkkkkkOKKdcccccc:;cd0XOdoooooc:cclllccccllol;.     ..  .,:coddddlccc:;;;,''',,;lolloolloooooooxKOolooolclkkddddxkxxxdooooooolcccllollllooolo:. .,lollllllccclclx0X00KK0OOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOkdoooooodxkO0XNNKxooool;,,,',oO0NNNNNNNNNNNNNNXKOkdoccooodolcldkOO00kkxl;'';lloodddxxkkkkkkkkkkO0dccccc;,;loddlcloolll;,:ccc:cllc:'     ....   .,;,',:lddxdolclc:;;:;;:loooooooooooooodOKkolc:,''lOkddddookOdoooodddooooodddddddddoko.  .'lkkkxxdoddkO0KK00OOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOkdooooodxkO0XNX0xooooo:.    .oNNNNNNNNNXXKKKKKKOxoodk0XXNNXXKXNKKKOkoc;'':loodddxxxkkkkkkkkkxxxxxdccccc,',,;:ccccllc:;;'';ccol;.      ...... .,;,;;::,'',:ldddddlccc:;:ccccoooooooooooodOKKOxdlccccoddxxxddOOxddddddddddddxxkxdddddOo. ...,d00KK0KKK000OOOOOOOOkOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOkdooooldOXNX0kxxdooooo:.    .oNNNNNNNNX0000KXXNXKKKNNNNNNNNNXKKxlllc;;;clooodddxxxkkkkkkkkkkxdddo::ccc:,col::;,,;:ccc::c::cc,.      ..'.... .;;'dOxlc:;;;,'';codooddlccc:::cccloooooooooodkO0OOkd:,'.',,''.,d0kddxdddddxxxxkxdddddOO;   ..;dOOOOOOOOOOOOOOxookkxOOOOOOOkOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOkdooccc,:kKXKKK0kdoooo:.    .oNNNNNNNNXK00KNNNNNNNNNNXK0OOOkkxol:,,;:clooooodddxxxxkkkkkxxkkkxddl';ccl:,okkkkxol:;;,,;:cc:'.       .'.  .. .,,,xXXNKOxolc:::;,'',:ldddddccc:::ccclooooooooooooodko:;'''....'.:xOkxdddddxxdddddddxOx,.                                                     //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract dqzdqd is ERC721Creator {
    constructor() ERC721Creator("zqdqd", "dqzdqd") {}
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