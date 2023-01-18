// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fine art by Marlon Pruz
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    NNNXXNNNKd,.,kKXKOOO0KXXNXKd'                                          ....                      ....                                ,ooc::dKWWWWWWWWWWWMMMMWWWWWWNKx:cxKXKx                                //
//    ;;cxOKXKOxl;;:ldOXNWWWWWNNNNNNXXXXNNKd,.c0X0x:'';clooc;.                 ...........                                       ....                                  ,dxd:.;ONWWWWWWWWWWWMMMWWWWWWWWXkdk0K0o    //
//    dlcccc:::::cdOKXNNWWWWWNNNNNNNXXXXXXOl;;oOOo,.    ...    ...          ..:lddddoooooll:;'..                               .....                                   ,okko,'o0NWWWWWWWWWWWWWWWWWWWWWWNNNNX0k    //
//    NNX0kdodxOKNNWWWWWWWNNNNNNNNNNNXNNXOl':x0Od,             ..         .;ok0KKKKK000KKKXXKOxl:,..                         ......                                    .;dOko,'cONWWWWWWWWWWWWWWWWWWWWWWWWWWNN    //
//    NWWNNNNNNWWWWWWWWWNNNNNNWWWWNNNNNXOl''oKKkc.                     .'lx00Oxo::::::::cd0XWWNXK0xc'                       .....                   .....';::::;,'..    .:k0ko''dKNWWWWWWWWWWWWWWWWWWWWWWWWWWM    //
//    OXNWWWWWWWWWWNNWWWWWNNWWWWWNNNNX0d:':k0Kkc.                    .,oOKKOl,.',;cclc:,.';d0NWWWWXOo.                                           .,cdxkkO0KKXXKK0Okdl:'. 'lkK0d;,c0NMMWWWWWWWMMWWNNNWWWWWWWWWW    //
//    lONWWWWWWWWWWWWWWWWWWWWWWWNNWNXOl,,oONXkc.                   .'lkKKOl'..:x0XXNNNXKkl,'lkKNWWWXk:.                                       ..:d0XNNXXXXXXXXXNNNNNX0xc. 'oKX0o''o0NWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    ;xKWWWWWWWWWWWWWWWWWWWWWWWWWNKx:,ckKXKk:.                   .ckKX0o'..lkKNWWWWWWWWWKxc,:xXWWWN0d:.                                    .;ok0XXX0kolc::::;:lxOXNWWXk:. :0NXOl.'o0WWWWWWWWWWWWWWWWWWWWWWMMM    //
//    ,ckXWWWWWWWWWWWWWWWWWWWWWNNKxc',o0XKkc'.                   'lONN0o'.:xKWWWWWWWWWWWMWXk;'l0NWWWXkl.                                  .;oOKK0xc;,'.';:::;;;,'':d0NNKd,.,xKNXk;.'dKNWMWWWWWWWWWWWWWWWWWWWWW    //
//    ',oONWWWWWWWWWWWWWWWWWWWX0d:''ckKX0o,.                    'o0XXO:',o0NWWWWWWWWWWWWWWN0l.;xKNWWKxc.  .                          .   'lOK0Oo;...;cok0KKKKK0ko;..;xXXOl'.cOXNXk:.,dKWWWWWWWWWWWWNWWWWWWWWWW    //
//    ollkKNWWWWWWWWWWWWWWWWXOo:',ckXNN0o'                     'lOXKx:.,dKNMMWNXKKXNWMWWWWNKd;,lONWN0o,.  .                            .:x0KOl'..:dk0KKXNNNNNNNNN0d,.c0XKx,..o0WWXx,.,kXWWNNNNWWWWWWWWWWWMMMMW    //
//    Kkld0NWWWWWWWWWWWWWNKxl;,;oOXWNKkc'                     .ckKXO;.,dKWMWN0xoccokXWWWWWNKx;,lONNXx;.                               'lkK0o,..cxKNNWWWNNNNNNNNNWNKx:cx00k:. ,xXWW0o..oKNWWNNNWWWWWWWWWWWWWWWW    //
//    ko;;d0NWWWWWWWWWNXOd;',cx0NNN0xc'.                      ,xKX0o'.o0WWN0xoodol;cOXWWWWN0o,,dKWNOl.                              .,o0KOl..;dKNWMWNXXNNWWWWWNNNNXOocoxOkl. .ckXWXk:':kXWWWWWWWWWWWWWWWWWWWWW    //
//    dl;,cxXWWWWWWWNKxc'.,lOXNNXOo;.                        .cONXkc,cOXNKxllxKX0xclONWWWNXO:.:kXNKx:.                             .:xKX0c..ckXWWWX0koodOXNWWWWWNNXOlldkOx:.  .:ONNXd,.:ONWWWWWWWWWWWWWWWWWWWW    //
//    KklclkXWWWWNKOo;'.,oOXNNKkl'.                          ,o0N0o;;xXNXkloONWXkookXWWWWN0o'.o0XXO:.                             .;xXX0o'.cONWWXOdooolclx0NWWWWWN0d;ck00x,    'o0NN0l..oKNWWWWWWWWWWWWWWWWMMW    //
//    kdlokXWMWXKkl,.,cxKNNXOd:.                     ....   .:xKNO:.:ONNKkdONMN0l:d0NMMWNKd,.:kXN0d'                             .;xKX0l..cONWWKkllxKX0dcd0NWWWWWXx;.:OK0d,    .,dKNNOl';xKWWWWWWWWWWWWWWMMMMM    //
//    lox0XNNKko:,,:oOXNNXkl'.                       ....   .lOXXk'.c0WNKkx0NWXkllkXWWMWXO:.;xXWXOl.                  ....       'd0K0d'.:kXWWXxlokXNKxodOXNWWWNXk:.,dKX0o'      ;kXWNk:.,kNWMMMWWWWWWWWWMMWWW    //
//    0XXXKko:,,;lkKNWNKkc'                          ...    .d0XXd..o0WWKkx0NW0xldKWWMWN0d,'o0NWXx:.                   ...      .:kXKd,.;xXWWXkooOXNKdco0XWWWWN0d;':xXWNOl.      .lONWKo'.oKNWMWWWWWWWWWWWMMMM    //
//    X0xl:,...ckXWWN0xc.              ...            ..    ,xKX0o';xXWWX0OKNNOookXWMWWKx;,cOXWN0l'      ......',;:cc::::::::;'';o0X0:..oKWMN0xdkXWKkod0NWWWWXOc..ckXWN0o,.       ,o0NXOl';xKWMWWWWWWWWWWWWMMM    //
//    c,.,cooc;lOXNKd;.               ....                 .:OXX0l,ckXWWWNNWWXkooONMMWN0c.;xXWWXkl,,;::clddxxxxkOKKXXXXXXXKXKKOkOKNNO, ,xNMMWX0KXWWKOk0NWMWWXk:',o0NWWKx;          :ONWXx,.:kNMWWWWWWWWWWWWWWW    //
//    ;:lkKXKx,,x00k;                ...                   .:ONX0l,ckXWMWWMMMNOdokXWMWXk:'lONMWNKOkO0KKKKKKKKKK00OOOOOOkkkOO0KKKXXNKx'.cONMWWWWWWWWNNNNWWMWKkc,:kKWWWKx:.          'xXWW0l..dXWMMWWWWWWWMMWWWW    //
//    KXXXXXXkc;okOx;                                      .cONXkc,lOXWWWWWMMWKklo0WMWKd,'oKWMWNNXK0Oxolllcccc::;,,;;;;;;;;;;;::ccc:'..ckXWWWWWWWWWWWWWWWWXkc;lkXWWNKx:.           .lONWXk:'l0NWMMWWWWWWWWWWWW    //
//    WWWNXXX0xoloxd:.                                 ....'l0NKx:;dKNWMWWWWMWN0xxKNMWKd,'o0XX0xolccc;;;;:::::::clddxxxxkxxdoc::;::;,'':dKNWWWWWWWWWWWWWWN0l':kXWWN0o;.             'l0NNKd;:xKWMWWWWWWWWWWWWM    //
//    WWWNXXXX0d::dkdc'                                ..'',l0NKxc;dKNWMWWWWWWWWNNWWMWXx;.,clc;,,;cdxO0KKXXXXXXNNNNNNNNNWWNNNNXXXXXX0kxxOXWWWWWWWWWWMWWMWXk:'l0NWXkc.                ,kXWNk:,l0NMWWWWWWWWWWWWW    //
//    WWWWNNNX0d,;d00k:                                .';:;cOXXOl,cOXWMWWWWWWWWMMMWWXOo,  .';cdOKNNWWWWWMMMWWWWWWWWWWWWWWWWMMWMMMMMWWWWWWMMMMWWWWWWWWWMWXx;.l0NXOc.                 .dKWNO:.;kNMMMWWWWWWWWWWW    //
//    NWWWWNNXKx:;dO0k:                                ..;:,;d0XXd'.o0WMMWWWWWWMMWWN0d;..':dOKXNWWMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMWNXK00KXNWWWWMWXOc':xKXOl'                 .lOXN0c.'xXWWWMMWWMWWWWWM    //
//    WWWWWNNXXOocoxkx:.                                .;;..:xKXk. ;kNWMMWWMMWMMWWXklclx0XNWMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNKxl:;;:lxKNWMMWWXk:''lOK0x;.               .,dKN0l.'dXWWWWWWWMMWWWWM    //
//    WWWWWWWWNKkocldxc'.                                ...'cx0Kd. .oKNWMWWMMMMMWWWNXXNWWWMMMMMWWWWWMMWWWWWWMMMWWWWWWWWWWWWWWWWWWWMMWWWXOo,':lc:',oONWWWWWN0o''ckKKOo'               'l0X0o..dXWWWWWWWWWWMMWW    //
//    WWWWWWWWNX0d;;ldo:.                                .,lxOOdc;'':xKNWMWWMMMMMWMMMMMMMMWWWWWNX00KXNWMMWWWWWWWMMMMMMMMWWWMMMWWWWMMMMMWKl',l0XX0o;;l0NWMWWWWKk:,ckXNKd,.             'l0NKd,.oKWWWWWWWWWMMMWX    //
//    WWWWWWNWWNKx,'cddl,                               ,oO0Od;',lk0KNWWMMWWWWWMMMMWWMMMWWWWMWXkl;',lxKNWMMWWWWWMMMWWWWWWWWWWWWWWWMMMMMWO;.;xXWWNKd;,dKWMWWWMWXkc,ckXNKx,             .c0XKd,.oXWMMWWWMWMMWXOo    //
//    WWWWWWWWWWXk;'cdxo,                             .cxOOd:',lOXWWWWWWWWWWWWWWWWWWWWWWWWWWWXx:;::;,,l0NWMMWWWMMWWWWWWWWWWWWWWWWWWWWMMW0:..o0XXKkc..lONMWWWWWWXk:'cOXNKd,.            ;OX0d''dXWMWWWWWWWWKd:;    //
//    WWWWWWWWWWN0l;lxkd;                           .cdkko;',oOXWWMMWWWWWWWMMMMWWWWWWWWWWWMWNOc'cOKKx;,lONWWWWWWWMWWWWWWWWMMMWWWWWWWWWWWKd,.,oxkx:. .ckXWMWWWWWNKo',o0NN0o'            ;OX0o''dXWWWWWWWWN0d::x    //
//    WWWWWWWWWWNKdcoxkx:.                        .;oOOd:';d0NWWMMWWMMMWWNNNWWWWWWWWWWWWWMMWKx;'oKWWXx:'l0XNWMMWWMMMMMWWNWWWMMMWWWWWWMMWN0o'.:dkkl'..cxXWMMWWWWWN0l;;dKNXOc.          .:OX0o..dXWMWWWWWWKd::xK    //
//    NWWWWWWWWWWXkoldkkl'.                      .:xkxc,,o0NWMMMMMWWWMMWNKxdxO0KKXNWWWWWWMMN0o:cxXNWX0o;:xOKNMMMMMMMWN0xddOXXNXXXNWWWMMMWNO:.;xKNX0dccdKWMMMWWWMWNOl':kXNKd;.         'l0X0l..dNMMMWMMMW0c':kX    //
//    WWWWWWWWWWWNOdccxOxc'                     ,dkko;'ckKNWWWWMMMMMMMMMW0o::clodkKNWMWWWMMNOocoxOkxk0OoclokXWMMWMMWXOl'.';;::;:cx0NWMMMMWKd;;oKWMNOl:o0NMMMWWWMMWXkc;lONNOl'         ,o0NOc.'xNMMMMMMMWKl,:xX    //
//    WWWWWWWWWWMWKd;;x00x;                   .cx00o;;o0NWWWWWMMMMMMMMMMWX0kkO000KNWWWWWWMMWKxlcoxl;lOOxl::dKWMMWMMWKk:';c:;;;,'.,xXWMMMMMN0d;;oOK0o;:dKWMMWWWWWWMWXx:,lKNKx;        .;dKNOc.,xNMMWNXK0KOo::xX    //
//    WWWWWWWWWWWWXx;;kKKkc.                 .l0KOl',xKWMMMMMMMMWWWWMMMMWWWWWWMMMWMMMMMMWWMWXkc,ckkxOK0kc''c0WMMWWMWN0o''cx0K0xc.,xXWMMMMMWN0l,',;::cxKNWMWWWWWWWWMN0l';kXN0o'       .ckXNOc':ONWN0dllllc,';dX    //
//    WWWWWWWWWWWWXk;;xKKOc.                'oOX0o,,oKWMWWWMMWWWWWWWMMWWWWWWWWWWWMMMMMMMWWMMN0l';x0XWWXkc..:ONMMMWMMWNk:.'lxkxl,:dKWMMWWWMMMNKko::lx0NWWWMWWWWWWWWMWXx:;o0NXkc.      .lOXXkc;l0NXxc;cxOko;.'o0    //
//    MMWWWWWWNWWWXk;,d0KOc.               .c0X0d;,o0NWWWWWWWWWWMMWWWWWWWWWWWWWWWWWWWWMMMMMMWNOl;;oKNWXk:..:ONWMMMMMMWX0dc:;'',ckXWMMWWWWWWMMWWNXXXNWWWWWWWWWWWWWWWWN0o;:dKXOo'      .o0XXk::dKN0c,ckNWWX0xc:o    //
//    WNNNNNWWWWMWXk;,dKKOc.              .ckXKd;'cONWMMMMMWWWWWWWWWWWWMWWWWWWWWWWWWWMMMMWWWMWN0l..;oxdc'.,l0NWMWWWWWWWWNKOdlokKNWWWWMMMWWWWWMMMMMMWWWWNK00XNWWWWWWWWXk:'c0X0x;      .xKNKd:ckKXOc:d0NWWWWN0dl    //
//    xolldk0XNWMWXx;,xKX0l.              :OKKx:,oONWMWWWWMWWWWWWWWWWWWWWWWWWWMMWWWWWMMWWWWWMMWN0d:'';;;cdk0NWMWWWWWWWMMMWWNXXNWWWWWWMMMMWWWWWWWWWWWWWN0dloOXWWWWWWWWN0l':OXXOc.     ,kXXOl,lOXKkcckKWWWWWWWNK    //
//    ;,,;;::oOXWWKd,,xKX0l.             .dKXkc,c0NWMMWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMWWWMMMMMWWWNKOkkO0XNNWWMWWWWWWWWWWWWWWX00KNWMWWWWWWWWWWWWWWWWWWWNOo;:xKWWWWNNWWWXx;:xKXKd,.   .:OXKd,.oKNXkcckXWMWWWWWWW    //
//    xOKKOd;,:xXNKd,;kXX0l.            ,oOK0oclkXWWWWWWWWMWWMMMWWMMMWWWWWMMMMMMMMMMMMMMMWWNNWWWWWWWWWWMMMMMWWWWWWWWWWWWMWN0d;,lONMMWWWWWWWWWWWWWWWWWWXkc;ckXWWWWWWWWWN0l:oOXXkc.  .;dKN0c..dXWNkc:xKWWWWWWWWW    //
//    NWWMWXOl,ckKKx;;kXXOc.           .c0K0d;:OXWWWWWWWWWWWWWWWMMMMMMMMMWWWMMMMMMMMWMMMWXOxx0XWWWWWWWWWWWWWWWWWWWWWWWWWMW0o,. .lOXWMMWWWWWWWWWWWWWMWN0l';dKNWWWWWWWWWWXxc:dKXOo'  .d0NNk;.,xNMW0c,ckNWWWWWWWW    //
//    WWWWMWXx,'okOd;:OXXkc.       .   .dKKkc'cKWMMMMMMWX0xxxkOKNNNNNWMMMWWWWWWWWWWWWMMMWKd,,lONWWWWWWWWWWWWWMMMMMWWWWWWWKd;,,'.';d0XWWMWWWWWMMWWWWNKkc.'l0NWMWWWWWWWMMNOc':0X0d;  'kXX0o,;dKWMWXx::dKWWWWWWWM    //
//    WWWWWWNO:,cdxo:l0XKk:.      .'..,oOXKd:cxXWMWWMMMWKd;.',:lodxOXWWWWWMMMWWWWWWWWWMWWXOc',dKNWWWWWWWWWWWWWWWWWWWWWWNOl,;oOOxc,,;lx0XNNNNNNNXX0kdc'.,o0NWWWWWWWWWWWMN0l';OX0x;  ;OXKx;.l0NWMWNKd:ckXWWWWWWN    //
//    WWWWWWN0l;codoclOK0x;       .'..cOXXkc:xKNMMWWWWWWN0xddxxolokKNWWWMMMMMMMWWWWWWWWWMWXk;.,dKNWWWWWWWWWWWWWWMWWWWN0d,.,dKWWNKkl;'.,:loooooolc:;;:lx0XNWNXXXNWWWWWWWN0o';OK0d,..c0XOl',xXWWWWWW0c,ckXWWWWNK    //
//    WWWWWWNOc;ldxdlokOd:.      .''..oKX0o':ONWMMWWWWWWWWNNNNNXXXWWMMMMMMWWMMMMMMMMWWWWMWWKx;.':x0XNNWWWWWWWWWWWNX0xo:,,lkXWWMMWWX0xl::::;;;;;:coxOKXNWWWNXKKXNWWWWWWMN0l';kKOo, .;oxl;;o0WWWWMWNO:..,lkXWWWX    //
//    WWWWMWNk,'lxxdooxd;.      ....':kXKxc,lKWWWWWWWWWWWWWWWWMMMWWMMMMMWWWWWWWMMMMMMWWWWWWWN0d:'';lodxxxxkkkkkkxo:,',:dOXWWWWWWWWWWNNXKKK0OOO0KXNNNNNXXK000KXWWWWWWWWN0o'.'oxo:'..,;;..'lOXWWWN0xl;'',:d0NWWW    //
//    WWWWMWKx;;oxxoccc:'       .. .:x0XOlcoONWWWWWWWWWWWNNNWWWWWWWWWWWWWWWMMWWWWWWMMMMWWWMMMWNKkoc::;;,,,;;;;;;,;;:okKXWWWWWWWWWWWWWWWNNNNXNNNNNNXXKK0000KXNWWWWWMWN0dl:,,;;'.,coxkkxl:,;:okK0kl;cxOO0KKKKXNW    //
//    WWWWN0dccokkl;,''..          .o0K0o,cONWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMWWWMMMMWWWNNXXKKK00OOkkxxxxxxxxk0KXNWWWWWWMWWWNWWWWWWWNNNNNNNNNNNXXXXXNNWWWWWWWWWMNOl';x0KOdclx0XNWWNNX0xl;:c:;;ckXWWWWN0doxK    //
//    WWWN0o'.;loc'...             .dXKkc,oKWWWWWWWWWNWWWMMMMMMMMMMMMMMMMMWWWWMMMWWWMWWNKOdollloooooxOKNWWWWWNNWWWWWWWMWMMWNKOxddxk0KNWWWWWWWWWWWWWWWWWWWWWWWWWWWMWKx:,lKWWWNXNNWWWWWWWWWNXOl.  ,oONMWWWN0o;,l    //
//    WWWKd;.  .;:;;,'..          'cOX0dclkNWWWWWMMWWWWWWWWMMMMMMMWWWWMMMMMWWWWWMMMMWXOd:,,:codxdoc:,,lOXWMMMMMMMMWWWWWWNN0xc,,;::::ld0NWMMWWWWWWWWWWWMWWWWWWWWNNX0xc:lOXWWWMMMMMWWWWWWWWWWN0l. .cOXWWWWWNKxc;    //
//    MWXk:..',lk0XXKOxo;..      .ckKKkccd0NMWWWWWMMMMWWWWWWWMMMMMWWWMMWWWWWWWWWWMMWXkc,;oOKXNNNNNXKxc,,o0XNWMMWWWWWXKkdol,.,lkKK0Odc,:xKWMMWMMMWWWWWWWWMMWNX0xollc'.,d0NWMWWNNNWWWWWWWWWWWWNKx:.':dKNWWWWWNKk    //
//    MNKd,,oOKNNWMMWWWNKOo,.    .o0K0o,cONWWWWWWWMMMMWWWWMMMMMWMMMMWNXKOkkkxxxk0XNKxc:oONWWMWWMMMMWNKx:,:lxXWWMMWN0dc:;,,';d0NWMWWN0dc:dKWWWWWWMMMWWWWWWWXOo:;;:loc;ckKNWMWX0xoxKNWMWWWWWWWWWNKkl:lONWWWWMMWN    //
//    WN0l.,dKWMMWMMWMMMMNKx;.   .dKKkc,lKWMMWWWWWMWWWWWWWWMMWWMMMWN0xc;:;;;;;;:cloc,,o0NWMWWWWWWWMMMWNOo,':xKWMMNOl,;d0KKKKNWWWWWWMWXx::x0K0OOKNNWWWWWWWXkc,cx0XNNXKXNNWWWWX0o'.cONWWWWWWMWWWWWNXXXNWWWWWWWWW    //
//    MWKx:ckKWMWNXXXNWWMMNKx;.  ,xK0xc;o0XNNNWWWMWWWWWWWWWMWWMMWNKx:',cxkOOO0Oko:'..:kXWMMWWMMMMMWWWMMWKdc:ckXWMXx:;dKWMMMMMMWWWWWWWN0c'';clccclx0XWWWWNkc:lONWMMMWWWWWWWWWWNKx:;oOXWWWWWWWWWMMMMMWWWNKOOKNWW    //
//    MWWNXXNWMWN0olxKNMMMWNOo'..cdxd:'.,cllodk0KNWWWWWWWWWWWWMMN0l',lOXWWWWWWWWX0d;';xKWMMWMMMMMMWWWWMMNkdc'c0NNKo:lONWMMMMMMMMMWWMWW0:. ,lxkko:',o0XWWKx:cxXWMWWWWWWNK00KNWMWXxc:dKWMWWWWWWWWWMWWWWWXklcdKNX    //
//    WWWWMMWMMWXk;'o0NWMMMWKx:...,;;,',:cc:;,'':oOXWMMMMMWWMMMWXx''o0WMMMMMMMMMMWXOc';o0NWWMWWMMWWMWWWMN0xl''lxkd:;o0NWWNNNWWMMMMMMMWKo,:xKNWNXO:..;lxkkdllxKWMWWWWWN0d;:xKNMMNk:'cONWWWWWWWWWWWWWWWWXkl;:oo:    //
//    WWWWWWMWWXkl;cOXNXXXWWXk:. .:ok0KKXXXK0kl;..;oONWMWWWWMMMN0o;cONWMWWNXXNWWMMMN0d::xXWMWNXXXNWMMWMMN0kd'..;;'.'o0NWKxodKWMWWMMMMWNXKKXWMMWWKo'...,;;,;:d0NWWWWWMNk:.;kXWWN0o'.'lkKXXK0KXWWWWWWWWWNOo,..,,    //
//    WWWWWMWN0d;,lkXNKOk0NWKx;'ckKNWWWWWWWWWWNKkl'.;xKWMMMWMMWXkl:dKNMMWKxlclx0XNWWWNXKXNWMNKd:o0NWMWMMNOxl''okko;'ckXNO:.,kNMMMWWWWWWWWWWWWWWN0l';oxxl. .,oONWMMWMMXkc'c0NNXkl;,,;,,:lc:,;oOXWWMWWWMN0d;,lk0    //
//    WWWWWNKk:''lOXWWNXXNNNOo:lONMMMWWWWWWWWMMMWXkc',oKWMMWWMWXkc:dKNMMWXOo;,;:clox0NWMMWMWXk:.,xKWMMWWKdc::dKWWXx;'c0N0o',dXWWNXOkOXWMMMWWWWWNKdlxKNN0o'.,o0NWWWWWMN0o,,oxdl;;ldoc;'.,:::;,;lOXNWWWWXklco0WW    //
//    dxxxdl;'':xKNWWNXKKXX0d:lOXWMMWWWWWWWWWMMMMMN0d;:xXWMWWWWNKd;:xKNWWWNNX0Oxl;'':oOXNX0xl,..:xKWMMWKx:';o0NMMNO:.;ONN0o,,lxkd:''l0NWMWWWWMWWNXXNWWWWKkdx0XWMWWWWMWN0o;'';lxOOx:;dO00KXXKx:',:oxxdol:cd0NWW    //
//    ;;'..  .:kXWMWN0dlxO0kc,o0NMMWXKKXNWMWWWWWWMMN0o:lOXWWWWWWXx,..;coxOKXXXNNXKOdc;;:ll:,,'..:x0NMMWKxc:lOXWMMNKxoxKWWNOl'.';;'..cOXWMWWWMMMMMWWWWWWWWNNNNWWWWWMWWWWN0o''o0NNOc.;kNWMWMMWNKd:',,,'';okXNWWW    //
//    Ox:,..':d0NMMWNKkk0XKk:'oKNMWXkdx0NWWXOxkXWMMWXd:ckXWMWWN0d:..,;::;;;;;oOXWMWN0d,..:oxO0kl:;lkXWWWXKKXNNNXXNNNNNNWMWNOl,;okOd:ckXWMWWWWWWWMMWWWWWMMMMWWWWWWWMWWWMWNOlcxKNKd::dKWMMWWWMMWNXK00OOO0XNWWWNW    //
//    NOl;:::ld0NMMWWWWWWWXOl:xXWMWNK0KXWWKd::dKWMMWKd:lkXWMWXOl,;lkKXX0ko:;:d0XWWMWNKo,;d0NWWN0d:';lOXWWMMWWKxox0NMMMMMMMWXd:lkXNO:,o0WMWWWWWWNXKKXNWWWNWWWWWWWWWMWWWMMN0olxO0x:;d0NWWWWWWWWWWWMMMWWWWWWWWWWW    //
//    Xx;;odoloONWWWWMMMMWNXK0XWWWWNNNNWWXx::xKWMMWN0o:oONMMW0l,;xXWMMMWWNXKXNWWWWWWWNOocoONWMWWNKxl;;lkKNNXOo,,lONWMWWWMMWKd;ckXN0l,;dKWWWWWWXkl;cx00OdldOXWMMWWWWWWWMWKx::k0Oo',xXWWWNNXNWWWWWWWWWWWWWWWWWWW    //
//    Oo:oO0Oo:l0NWMWWWMMMMMMMMWMWX0doOXN0o,:ONWMMWXkc;oOKXNXOl;cONMWNKXNWMMMMWWWWWMMN0dclONWMWWWWWKkl;;;ccc;...ckXWWWMMMWKx:,lONWN0o,':dOKXX0d;...';cc;'.;dOXWWWWWWWWWKxc;oKXOl.,kNWN0kxOKNWWWWWWWWWWWWWWWWWW    //
//    c;oOXKx;.,dKWMMWWWWWMMMMMMMWXxccxXNKx;;d0NMMNOl'.':cllc:'.'dKWN0l:oOXWWMMWWMMMWKd;:dKWMMWWMMMMWXOdc::cllc:;cx0XNNNKOl;;lONWWWWXkl;;:clc::coddc:ok0Odc;;cdOKNWNX0d:,;d0NNk:.;ONXOxoxO00XNWWWWWWWWWWWWWWWW    //
//    .;kKXO:  .cxKWWWWWWWWWWWWWMWXOookXWNOl:oONMWKd'..';cc:,'...;x0NKx:',cx0XWWWWWN0d,.cONWMMMMWMMWMWWNXXXXXNXOl;,;:llc:;;cxKNWWWWWWWNKOdooodk0XNX0O0KNNX0xc'';coolc:.  ;kXWNk;.c0X0ddk0KOxOXWWWWWWWWWWWWWWWW    //
//    :xKKOl.   .,oOXWWMMWWWWWWMWWKxllkXWNOl:o0NWXk:';dOKXXK00Oxl;,ckXNXOo:;:lxkkkdl;,;oOXWMWWWWWMMWWMMMMMMMMMMWKOdc:;;;:lkKNWWWWWWWWMMMWNNXNNXKOxddddoodOKXK0kdoc;:clc,.:ONWNk;.:OX0xxkKXOoxKNWWWWWWWWWWWWWWM    //
//    xKXOc.      .:xKWMMWWMMMMWWNKOO0NWWKd::xKWNkc,cONWMMWWMWWWXkc,;dKNWN0d;..';;,,:oOXNWWWWWWWWWWWWWWWWWWWWWWWWWNXXKKKXXNWWWWWWWWWWWMMMMMMWKkoccldxxdc;:oOXWWNXKKKXKkl;l0NMNOc.,kXX0xdOK0kk0XWWWWWWWWWWWWWWN    //
//    XXOo.        .;d0NWWWWMMWWWWWNWWNXOo::dKNN0o;:xXWMWWWWWWWMWNKd:cxKWMWXx:,;lxk0XNWWWWWWMWNXK0kkxkO0XNWWWWWWWWWMMMMMMMMMWWWWWWWWWWWWWWMWNKOkOKXNWWNKOo:cxKNWWWWWW0oclkXWWWKx;;dKNN0dodk0XXNWWWWWWWWWWWWX0d    //
//    N0l'           .:oOKXXXXXXNNXK0xoc:coOXWWKx:;xKWMMWMMWWWWWWWWX00KNWMMNKd:ckXWWMMMMMMWWXOxl::;;;;;::odkKNWWWWWWWWWWWMMMMWWWWWWWWWWWWMWWWNNXXXNWWWMMWKxc:dKNWWWNKd;;xKNWWWN0o;:xKWNKxodOXWWWWWWWWWWWNKko:,    //
//    Kx,              .,:clccllolc::;,:d0XNWMNOc':ONMMMMWMWMMMMMWWWWWMWWMMN0d:cONWMMWMMMWXOo;;;coxkOkdc,...ckXWWWWWNX0O0KKKXWWWWWWWWWWWWWWNKkdooloox0XWMWKo,cOX                                                  //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PRUZ is ERC1155Creator {
    constructor() ERC1155Creator("Fine art by Marlon Pruz", "PRUZ") {}
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