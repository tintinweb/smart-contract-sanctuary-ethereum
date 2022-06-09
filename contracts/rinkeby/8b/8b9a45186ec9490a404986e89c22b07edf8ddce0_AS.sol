// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: abdllhart editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    0xxxl'....,c:d0xlcdxl;,;kk:,;;,,,,;;:clllllooll:,........       ....:l:,.;:lcll.  .;c;clllll:;;:::;'..','..  ,:xNW0cdx. .,;o:,ddxx;,lddxxxko:;cllo,ck:,':c.ol   .oOc.   .ko,c,';,;xl.cdl0WN0l.  ..;o,;cc    //
//    xdkO;',.',c:lXXOxdxOd,,kKdcl:;;::::::;,',;;;;:cldxddddol::::;;;;;;;;cdxoooo:;loc.'cc'''''',,,,;;cclllc:;:c;...:lOWWd,d: .'cl.:kxd:    ......   .lo,.od. ';.c:   .xk.    ck,,;  .,:c.,xcdNNO'   ..'cc..,:    //
//    c:loc;.',,;;xXNXXXNXxlOKx,::          .......    ....     .;;::,.....,;:cc:;::lk0Ol,...       ...',,,,,,:lclc':lxNWo'ko ..l;.lxll'              ,oo'.xl .,.:;    d0'   .xd,c'    ..;kOd0WO'  .'..;:.  .,    //
//    odxdl:;:cloxxoOKOXNOok0d' ...      ...,clllllcccccccccc::ll;,,,''.';;;;:cc::ccoxkocc:,..........''..... ,l';oc:lo0Wo'Od..;l..xo;,,.              :dl.,x; ..,:    oXl   .xolo.  ':dONNNNNXx..;,...','',;:    //
//    dkkkkOdodxOx,';o00kolc,...   ......',,,;:cll:.........,;:;.        ..'',,,;;;;:lodddxxdlc:::clccc::;;;,',. .,olcoOWk:dc..lc,oo:;;cc:;'.....      'lo;.cd....;.   lKk'  .xOlloloOXNNWWWXxdl.lc   ..;c;'..    //
//    dx0xo;,ododOd,;d0c:c  ...          ..',,''';xx.      .:c::::;;,;,,,,,,,;;;,''........';codddoooooollllcccl:..lc,oOWKc:c;:::xl;od:;;:cloc'....... ,lcc.,k:...,.   ldxl  .OWKdlokKNKOxdl;.;l''c:'...'',:;;    //
//    dkkl;.,oxdlxxcldl.;: .'.                    .ol;;;,''cl.     ..'',,;;:ccccloodddddddl'                  .od'.;:':kWX;    ,xc;xO:...   ,x, .;cloooo:,l,'kc.. ,.  .ollx. 'kXXXXK0kdolc;,,,,colldd:,,'',,,:    //
//    koxkddddOd,co. ',.l;  ::    .;,';'. .::c;.    .',''''..                        ....':llcc:;;;;;;;,,''...,d:..,l,'xWK,   'xc'kOldo::lo:lk,.xkdxdddlcoxl'oo.. ,.  .o::k,.,oxxc'';dkkdl:;,;;;:clol::lc:::'.    //
//    c:;:llxxc:;.;c',''d,  :x'   :c  .c'.oc.:x,.;:cllcc;,.',;:coooolllcc:,....         ....,cllc:;,'',,;:::;;:,...'d:.oNNc  .do.l0ocdc;:ld;:x,:d:dkookxco0O:;o,  ,.  'l';k;.coxl. .;l::c:;;,;;;:collo;',cool,    //
//    ,;;;clodo;;c.;d:.cd.  ;Oc...:c.  ;::d' .:;cc',;:cloddddool:;,,'..'''',,,,,,''..',;:ccclooodddl:,'..........'..dOcdNWx. ld.;KKkkkkkkkklcd:oocxo::cd:.lOo,lo..;. .;,.dx''oxxc..',.':c::;;;;;;::c:;c;.,oxo:    //
//    ';,'..:c:. cllKx:;.   .colodxl'..,coc'.  ...             .;ccc:,.                         .....'....... .cdl:.:OO0NWd..xxlOOxkOO0KXXX00K0kxdxkOKkxd';kk;,kc.;, .;,;;..;okx:.'clc;;;;.......,:cc::loodxkx    //
//    ,.';,,:;'.,c:xXl.;loolcccccc:;,,,,,''.',.....',;,'.      c0o:clOc  .c:;;.   .',.   .,,':,   .'.       .''..';. 'xNWNOdxO00OkkdooodkO000OkxoodxO0Okk;'OXc.dk':; ,o,   .:oxo;.;od,  .'.....   .,;,:cccllod    //
//    occlo:,cdl,'cxx:lOOOd:,,'.             .'codddolc:;:c'   ox.   cl  .o,.c.  .cooc   ;x, :x'  ;l'.,,;,,,,',c' .:,.'0WXkddddxxo;,,,,;c:',;:::cldxllxdk:.xWd'd0clc.cl.   ':ldo:.,o:'',:l;'.',;;;;;;,,,,:cloo    //
//    dooclc:,:d::do;:xxkl           ..'''''',;;;,,'......co:;:c'    ,l. ,d,'xl;;lkcdk.  cx. .coccdl...'''..  'l'  .:o',kXx,,;cl;...    :c.',,,;;;cc. ,oxdlkNX00O::l.:;   ';:odl;.'l' ';,,.  ..',;;;;,,,..,,;;    //
//    lodxxoddcdOkc;',xdd,        .';:cdxxxxxxxdxxxddodk000kxl.      .',,:, .:oool;.o0dllo;...,cllc:;;;;;:cll':o.   .xc .lOc .lxdddoc:;;c:;''clloooc:;;cxOk0XNNWK;,o;;'  .;;ldo;;,'c. ,;....'',;,,,,. .,';;..,    //
//    .,:::cod'.cl,''.loc.       .l:,,:l:;,,,;ccllooddxkO0Kxldkl.           ...'''..';,'...........''''..   lxcd;   .k0;  cd. .'',,;;ll'....l:...',,;;,'':lc:lONN0xd;,.  .clodl,:;.,. :c.';;o0OkOkdoc,,;;c:,:l    //
//    :cc:;,cl,.,:.''.cl;.      .lx.'cod;.    ..''..''',,,:oko:lollcc:::;;:dk0KKOolooolc,....,'''','....',:,'loxl.  .kOx: 'd;        'l'...:dl:.......''.cl;::;xNNWKdl'  .lookl;l'.,..:;.';:lOkxKKklc::ocllcxk    //
//    c,.','..'':; '.'lc,   .'codd:.'oxo'    ...........''..x0: .;ddddooollldo:lo;,,;::;;,,;;;,'......''',;cl;coloo.'kxxc .kl'c;,,;;;cl,. .okx;....   .,,:,  cc.dNWNN0,  .lll0o:o'.,. :;....,;:cc::::;,:;;,,;;    //
//    ll:;'....:; .,.;ccl;loddoc,'.;lldl.    .........   .';xOocloddxOkxdolc:;..lc.',''..............  ..cxlcc'',dd.ckdd' ,Oocc   ....,,..:kkl..      .';l'  .l,.dNNNNk. 'l:lOl:o..;. :dl:,;:c:;,'.....:;;,...    //
//     .''''',:,..'':xkxxl:,'''..  ;dldl. ...     ..''.... ,xdkKd:::ccccokKXKOOl,cc:.                    ;Oocc'':Oc.okdo. l0clc       ;,.:ddc'.       .';l'   'l,.kNNWNl.:l;dO;.cc'.,;cl;:ldoc::;;,;;'.;'.::''    //
//    ,'.''..,'.;looool:;;;;,',cc. cxlxo...............'::,ckldXO,.;,'. 'dkxdxXX:,kk:,;:clc:;;:;;:;,,.  .cOoo;,:'kd.dkdc .kx.lo      ,c,'oxl,..        'cc.    'c',0WNXO:cc;kk' .'cl,'cdl;;;;;;..  .',..,..,;;    //
//    ::::c,',cdollc::ccc:,.....ox;dklxl;lodxxxddddxkxddxocd0coX0:  ....c0o';;xWd'xXxcd00Xdcool';xo;:clclxkdooo,.xx,dkd;.lk'.ol  .;;;;.';okc.......    .'.      ,c.;KNOdolllkx.   .'cl;;;:oc,:c;,,.  ',..,',,'    //
//    ..'od,;xd,,:::cc:;;;;,::;':O0Kxlx, .':clodoooddooodkddOcoO0k'    .'lO:';lNk,dXo,cOXXxokk:.lk;..,oxOOxxk0l .xookdo':x, 'x: .cc. .,:ckO;   ..............',,:xd,;O0clooOOd'    ..';:::c:..,;,';. ,c. ..',,    //
//    .,lc,.lO, ::.:lloddc,;:ll,lKKXdcx:....',''....     .lxkcollKo.    .,dd',lO0,cKl .';cccll:cddccc:'.oOxkkO; ;:;Odl:'xc  ;k, .o,  ;::okl.          .......   .:xO;,xdldcoKd.     ... ,dc:.  .:;.'..l;          //
//    lo:,'.cx. c:,c:d0Okc.;xkc,dK0Kd,ll:;,'''''',,..     ,OOldc,kO;     ',c,.;lko,xO'....,,;;;;;:::.  :kxkddk;.;;dk:l:ox:l:ck, 'o;.'c::dx;..    .....',;;::::::;,;;. ,olodcld,      ...;o;;.   .'.';'l:          //
//    '.,...:x..c;;c:dOxdolldkc'c0KKKocodoolc::;:cdxdoloddx0koo:cxOd.    ...:..odo::oc,...',,,,cddo:..:doxKl:k;.;l0c,dOxcd0d:kl :o;;..colx;  ........''.''',,;cc:ccccc;cocodc;l:.    ...ol.;.   .. .c,'c;''...    //
//    ;'..'..dlcl:c:ldc;;;;',ol'.dWNNKK0Oxoccllc:cllodkOOkxxxkkOOooOl.   .'..;.;kdlc,;lllcllllllc:::cdxodc'.lk'.,d0,,Ok::xOc.lx'co:c...,cdo. ,,.''.',;;;:coolc:;::;'.;d::l;ldl:cc.  .'.cO;.'    .. .;.  ..'...    //
//    c,..'. .'cllc;ox,.....;xo..dWNNNWWNNKOOO00KXNXXNNNNNNNNNNNKOONk'    .'..,'cOl::;,''''.........'';llccox;..,kO.:x:,dkd, 'd;,dxxdoc;cloc,.';llcccllooollc::c:::::cxc.l:.clolcc..;':0o'::,;. '. .;.            //
//    ld;.,.   .:l:':ol;;;;:ddl..xWNNNNWNNNNNWWWNNNNNNNNNNWWNNNNNNNW0:.     ''''.lx'.:;,,'..''','.....,:;,,'.   '0x.:x:cxxo' ,l. ;dxxxdolc'.;:',,...',;:ccllc:coxdlcc:,.;l' .l;lkkc;,;Ok,'cdlco;',.,'             //
//    .xc,,    .cc:;::,,,,'';ll'.dWNNNNNNNNNNNNNNNNNNNNNNWWWNNNNNNNO;',.     ';' 'k:    ..........      .;,'... ;Kd.ld,lx:co,:; ,lclodlcc:;..:ol. ....''...',;coclo:kOcc;.  'l:lxoxd,ok:....',:dc,::.     .,,,    //
//    ;xlc'    .c;;;';:...  ,do'.dNNNNNNNNNNNNNNNNNNNNNNNWWWNNNNN0c',;.      ';'.'kc    .........      .'...'. .dK:.o;'dkdc:cl'.loc'.,:cxxl:'lkOd::ccloc;;::,';ccdOdO0d'  ':codl,.:::xc...''..;coccl.    ,l,..    //
//    xklo.    .:,.'. ;,... .oO: lNNNNNNNNNNNNNNNNWWWWNNWWWWNNNXo;cl,.       .,'..xl    ld.   .               .lKd,o:.cOl,ccc;.:oo;...;ok0xc;ccco:c:;,,;;:;',ldxdlcckO; .colodl:;;;;do;,..,,;;;cdc::    .l'...    //
//    kxox.    .:;..  .''''. .dl ;KWNNNNNNNNNNNNNNWWWWWWWWWNNNKc'dd........  .,...od.   o0,     .';::::ccllodxxdc'ox.'dk, ,d, ;ool;loloxollco, .:;..'.....  ,::,.  ;kkc:oddxd:;llc:dkc,'.,;;:cldx'',    cc ...    //
//    k0dodc.  .,'....  ..,;'.;c.'OWNNNNNNNNNNNNNNWWWWWWWWWWWNl.lk' .,,'..... ',..cx'  .xX;  .::::;;::ccc:;,,,'..co:.,do' .o;.ol;lll;.:xl, .kx. .'','..    ';,..  'xc;kOxxo;:l:locd0dcc;','';cldo.',   .o: ..'    //
//    lkx;;Ol  .;'.. .    .;,.,:. :0NWWNNNNNNNNNNNWWWWWWWWWNWX:'kc.''...    .'.,,.,xc  .dXc .lc.  ..............:c',.;llc. .:looc:dxdoo::' ;Oc    .....','''. .  .:;.:OOl,'';::dllOkc;,',::';cloo,,'   .o:...'    //
//    co:c:xx.  'c,...    .;'..''..,:cldkKNWNNNNNWWWWWWWWWWNWXldd.,,        .;.,;'.:x'  ;Kk..c,  .'.           .l;.;..:lcc'  'o:cxlcc:::oc:kd.        ...       .;,.cOx:,'.',:do'xOc:;'.'',;;:;cd;,.   .l:..'.    //
//    ;cl;codxc. .;;,'... .;......',;:::coddxOXNNWWWWWWWWNWWWXxk:.;. ..     .:.;:'''xl  .ok. ':. .,. ..........:kl,;'..;c::,..l';xoc::.;xdkk'.;,',,,,;;'.       ';.'xOo:;,,;;od..kXOxd:::;,':::o;',    .o;.;,.    //
//    ,l0cc:.'okd,..',,;;'':..;...    .'',;:,.'oXWWWWWWNNNNNWX0O;',.,;  .''',,.:c,:.od.  .,.  :o. ;;.;'.',,,,''xx;;;:c;.'ccc:oc.cxdl;oodockx,l:   ..',,;,   ... 'c'.cxd:cllldo' ,dkkxxxdolc;;ld:.,.    ;o.'c;;    //
//    :clcc'   .coc::::::cl;..c;.........  .:,  cXWNNWNNNNNNNNNd.;''l.         lc;c.:o.   .,. ,Oc ,c;c.       .do....;ll:,;cc;..oloo'':loxk:.l:      .'':'  ..  .c;.'cl, ..',...,;coc'',:odllo;.'.     ::.,dco    //
//    l;;l,         .,;:::cll,;c.   ....... ,c. .dNWNNNNNNNNNNK:':;c;;:.      .o;;: :o.    ':..kk.'l;:;       .do.....,,c:..;;.;ocl'  .cll:. cc       ',:'  ..   ';..,cl,   .,,..,;;:.   ,OOl..,.      ,c.:k:l    //
//    o::,.......   ..,,;l' ,xo,;,,.      '..;;'.,0WNNNNNNNNNWO,col:lold:     'x;,o.;o.     ;c.c0:.l:;c.      ,ko'''''::;' .';;cl:;'.'c,.':' :l.      .,;'  ...  .;;. ,cl'   .,..''';.   ,kc..'.        ;::klc    //
//    o:;;;'..,;'..'. 'Oko:. .loloo:,,'.   ...:l;'lNWNNNNNNNWNl.dO;,o' :k,    .x:.oc,l.      ...xO';:,c.    .ckklcl:;:cc:'. .::lo::ccoc..:,  :l.      ....  .:'...,oc..;dc.   'c'''.:,  .dx,....'.       'ccld    //
//    ddxo,.  .',',:c:lKNXKOc. .':loooc,..  ...;,';OWNNNNNNNWNc'Ox..l, .do.    ld.:d,:c.      ..;0c.;':,   .oxld0kkOc;dkl;'..;cckkccoo;.;c. .l;        .;' .::::,::;od..co,   :c..,..::,cdc;:cc::c,',,,,;,';:c    //
//    dxxo;,,,'. .':;;lkKNNNNKxc.  .,cool;........,oNNNNNNNNW0;:Ol.'l;,';xc    .ld;:o::l.       .dO,'.';   ;xccx0kdxc;cdl::.':clox:..l: :c  ;c.     ..,:c..l:cl;:col:l:':oo, 'l, .;. .ckOkdol;...;lol:,..:c.':    //
//    '...,:;,::;'.....,cONNNNWWKxc,.  .cxc.  ....',kWNNNNNNNo.lx;.;;';;';x,     ,oc:dl:l'   ..  .kl.'.'.  ,xccxxdolc'.;;:c.,lcc:dx,.c, c: .c'  ..'',okxooOdo0Oxk0Kxolc,'cxo,cc.'.;,.:cc;;,'.....,col;.',.;c.'    //
//    .  ':,','.';,...  .'lOXNNNNNWN0xl..dd..    .'.lNNNNNNWK;'dc'.,'.';'.ld.     .co;lo;c:. 'c.  :d.....  .dl,l:..',:l:,cl'::'c:,dxod;.c' .:. .,'. ;kdldO0xodl;,;kx'cl,,:oko,..c;'c:cc,',,'...,;;:cc:,..,';c;    //
//    . ';.  .''....'.... .,odx0NNNNNNWx,dd'.    ..'c0WNNNNWO.;d'......,,..ll.     .ll.oo.;o;.;.  .c,....   lo,;:.   'cl;;;.:; .c;;dkOo''. ':..,;...,c:,,;lxo:loocxx;ld;;ol,.  .,l:..:;,,..'..';,';,,:ll;',.;x    //
//     .''.     .''. ...,,,..'''oNNNNNW0:dd'.    ...:kNNNNNWO.:d... ...',.. .'..    .l,'d: :x'..   ....'.   'dc,c:,'.'cddc,.,:. .c:okOk.   ,' .:;',',;;clc:;';;'',oxlcdKd..     .,dc,:,;:'';:;::;;;;;clcll';ol    //
//       .''.     .''.  .'lxo;..:XWNNNWO:xl'.    ...,dXWNNNWd.cl.  .'...,...    .....;c.:x';k, ..   .'';'',. oOlc:;loclx0k,';.   ,,:kOk,  .'. 'c::xOKKKKK0kdc:;;..';,,xK:.......  ;kl:ldo::cc:cc:cc:;cl::l:lc;    //
//    :;.  .',,;'.  .'''...;kKx;oXWNNNWklx;..    .'.,o0WNNWK;.l:    ,:. .'...    ,;..,l,.xo,kc  ..   ..,;,;. cKxc::c::;:ldc'.    .,;xOx;.     ,o::OKNWWNWWWX0kool::c:lKk;;.    .. .do,colllc:ccc::c:,,';oclc.,    //
//    OOdo:.  .',,;;,. ..''',lk0KNNNNNNdlo...   .';..o0NNNWO..:.    .c,  '..'    .:l;'cc.lx'lk.  ..  ..':'...cxc:odc;lko;c;..    .,,okx:....  ,o,.,;cldKWWWWWWWNKko:,cKxclc'.  .'.;dl..;c::;,,,,;ccc;;,:c:c,,l    //
//    d..,clc:,.   .';;;'. .,;',xNWWWWNxd: '.   ..;;.;0NNNWx.,'      co. ...,;.   .ll',c,:O,,k:   .. ..,c'...lxxxooo:ckc:l'..    .,,lkxc....  ,l.  ',,;;dXWWWWWWWWWNKK0l,;coo,.,..ldd,  .,''.'',:cc::cc;;cc:c;    //
//    : ....';;;;;'..  .,;;. .:;cKWNNWN0xc...'.  .':,.xWNNXc.,. ...  :k'  ...:oc,':o'',c:'Ol'xc    .....lc.,.:kc''.'oxl;ll.       ''ckkd'.'. .:l.  .,:c:;lxkO0XNWWWWWNx,',,,:odc,:xl,',''',;;,,,;:oxxo::;;'.      //
//    ,....',,,'.'::;...  .;:,',dXWNNNWXl,,,,'...'..:,oNNWk.''..'lkd.;Oo;,'';;cclc;..,;o;.xd;xc    ...'.,l,:.,x:...'ld:cx:        .,'xOdc:;..,lc     .,;coo::::cdXWNWK;  .';,';c;,oc.  ..'',,,,,'..'cll:.         //
//    '.....'.'cl,..,::,..  .,c;.;kNWNNW0;..,;,,;,'.,,,0WK;',..;dXWNo'oo:cldxoclc,..,'cd..xx:x:    ...,.'lcc';0dcllxdl:xk'   .    .;'lkllxl:l:;.  ';,,..,;:cox000NWWNx.    .:;.'..;c'.';;;;;:cc::ll:'..,:::'.     //
//    ::ll:::'..,do;. .;;;.   .;l;,kWWNWNo....',;:;,;'.lWk.,''clkNKxx,.;looldx,:Oc''';xc  dkox;    ...;':oll'c0ocldkooddl.  ..     ''ckolko:l.   .:;';;;:codxKWWWWNWXx;,.. .;... ...,;cc,',''''''...,::,..':::    //
//    '':loooc,...ldc;'..,::.   'xdOWWNNWXl.   '.'oo,'.cNd.,;cdd0WO:do.'lccldd:,xOc''ckl.;Odlx'   .. .;;cdxl.:kc;::::dol;.  ..     ..:kdldl,l;.  .,,......;xO0NWWWWWWN0xl;''.... . .';;'.   ..........,cl:,. .    //
//    '...;lddo;..,.':c;...'::,;ox0NNNNNNWKc.  ...;d,..:0c.,:ddcck0kddoc,.;loxOc;OOc',ldxOxcol    .' .;:loxl.cOxdoodo:'::.. .      .'o0kdko;l:.  .c,  ..  .;.lNWWWWWWWWW0o;'...   ;c,. ...........';;;'.,odl:;    //
//    oool;',dxl:. 'c,';.....':lokXWNNNNNNW0;     ;l,..,d;.,ldc;'.,:lclool:cdkOo;d0l..,';;;;'.    ., .;codOl'lo;,.l0c  ;:,. .  .  .cxK0ooxdooc;..:d;  ..  ;,;0WWWWWWWWWW0l'.'.   .o;.;,,'..'''.'...'.',,;:ccld    //
//    cdkkOOl:dc';';, ',.  .. .cdONNNNNNNNNNx.    ;c,...o:.,,,:;:lllc::..cxddxxxkkl,...           .,..,ckkO:,o' . cO,  ';:;...,;:ldoxk:;o;;ddc:loxk, .;. '::OWWWWWWWWWWWKl,...   :xlc'   .c; .',''.... .',,col    //
//    ;c:;cONdlx;.;;..;.  .,..::xNNXNNNNNWNNNo.   cx,...co'',.   .....  .:ol;;,,;:cooc:::;..      .' ';cOkc,cx,...dk.  .;:c:;:looc,;c'  .,';:;,:llc;,;,'',;xNWWWWWWWWWWWNKk:.,..:kxd:..:lll' ',......',,'. .',    //
//    dc:,.oWKdddc;,..,...c;.':x00kdddxxkkkKWXc.  :k;'. .:lc:,.       .;c;;l,  .,:lc'..',:c::;'.   .';:l0o.,l;''.'xx.   .cc'',;:;,;;.     .',,;cc;:ldolcc:dXWWWWWWWWWWWWWWWNd,.;xdoocc;':c;:ll. .''..  ..''...    //
//    doclxKXc'c;:l,....',' .;oooo;...',:cclON0;. 'x:.'  .'cdl,.    .:c;...'cl:::ld:,;:c:,'':llcc::ccc:oO: ;l.'. ;k:    ;:.,;,,'..    ...     .'::cxkO0NWWWWWWWWWWWWWWWWWWWXx:,clld:....:dc;lo:cdc''.....    .    //
//    ;,.;00d::c::ll;.......:lc::,......,:;,cONk. .co'..  .'ol;'  .cc:'.....,coddool:colloclooc::lc:cddko..c:.'..ll.   ;c.:l,',;;,,,,'''..........,;::okkk0XWWWWWWWWWWWW0dxxl,:,,:ll,;,,;,,,,',::;,,'....',,,'    //
//    ,,:xd;:ccllolc:'';:c:;;;,..'','....';;:ok0c...:c''. .,ol,..:o:',;';;.,c,';loll:cl;:c:codxxkoloc:Ok''oo,.'':'.   .o,,d:,,...................'.....ckddkkk0XWWWWWWWNl'cl''l..:olc: .c:''.';c;..',,'''''''.    //
//    .;o:.'c:;c;,:;,:;;:;. .';;;:;,,,,,,..',co0x....::,,..;xxc,:c;::,c,'l';d,:c;o;:;;cclol:coloddl;:xk,.c0o'.,;.    .cc.oc...............';:ccc:;,'..',::ldxxddoxKNWNW0cco,.::  ;xl;;.;o.   ...,;,..........,    //
//    ll'.;llc;;;;,','''.,.  .cc;',::,'','''.:oOk' ..,c';:;oclocccl::..,.,,.o;';.:,.:,:occc:llooc::cl:...lO:',,.     :c..:;..';,,,,,,,,'''',;;,,,,',;;;;',c:ccodl,lNWWXxoo;.,;.  'xo';.;d;,,''',;;::,.. ....';    //
//    .   .;ldc,'...... .'. .:c:'...;;;:;,'.'ldxO;.  .cc,lko..:lccl:,..'..,.:l.,.':.,:;;:lol:c:;,;,.... ,ll;,,.     ,c..'..,::,.   ....''',,,,,,,,,'..'c;',,;.;lccxNWW0xxc.',.   .dd;:''ooc:,,,;;;;::;'.......    //
//    ...    ';'...... ...  :oko. ...,;;;,;c;;odOo.. .'cccKk.  .;::;:c,;'.:'.l,';.,;':c;;ccc;,;,.......;xl.,:..:od;.;..':c:,.     ..''''..      ..';cc:',:,';;c:cdKWWXOxo..'  ..;oo,.:,;o;,,,'''..............    //
//    ...   ..  .'.......  ,ooxkd:'...''''.;l:xdd0c.. .,o:,,     .;:;,,,;;cc;do,c;,:,,;:;,;:,',:;;;coxkxc. ;:'dNOdl;'.,;cl.  .',,,:cc;'','.''.    '::;;;:lc:;c:cx0NX0xdd,..  .'ld,  .:c,;,;,,,,',,'....','''',    //
//    .'. .'.   ;lc:c:'  .;,,ldlokkolc;,;lolcdddokx,....:c'        .,;;;,'',;;::::::ccloooxkOO0OkkOOd:.   .:c;0Ndl:...c;.;c:ccc:;,''.......';:'  ;o;....,clccccoOXOl:,;,.',. .,xk'  .:c;'...',;;;;,'''',,'..':    //
//    ..  ,'. .,,;cc;c:...,':dc;:;:oxxxdoxc'lxlodllc,.....;c:'       .;dkddoc::c:cdxxdloolllldkOOkxl,.....'::oNXxo'.''c'  .;:'...;ldo:.    .'c, .do,,'..';ccodc:kxc'..',,.,'  'xK:  .;;:;...,,,'','.,;cooddxdd    //
//    .  ';...:,',cd,'l;. .'o0l','..','lOl,cdxc'ld;,;;..'. .;ol.  'lodkxl:::cc:cllll;.   .':loxxloxl;..:. .:lkWXxo'';';. ..,;...'kX0OOl.  ..':,..ol.,:,,cldkkd:''...',,:l'',  ,kXl  .,.:;...,;c:,'.','';::::lc    //
//      ,l;..:c,;..lxl;,,,,.;d;.......,lc'::cxc.'ld,';.''.'',oKd..xo,,'''',;cc;'.......,,;clc:;'.c:.'.;:   ;kKWWko;:l''. 'c:;,:;'ckOxl,... .,;. .ld,...',,:do;'...,,'..;o;....oKNo  .,..:,..;clc;;,,'...    .:    //
//    .cd:..:c:,;:';0d...';;;c:,..  .,:;'.;'.lxl,'cxc,:;.',.,kWO.:x,. .''.''';:,;;'...   .';,.'..c;.;'c:   'ONNWkc:lo'.. ..,:..''..,                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AS is ERC1155Creator {
    constructor() ERC1155Creator() {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor() {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x442f2d12f32B96845844162e04bcb4261d589abf;
        Address.functionDelegateCall(
            0x442f2d12f32B96845844162e04bcb4261d589abf,
            abi.encodeWithSignature("initialize()")
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