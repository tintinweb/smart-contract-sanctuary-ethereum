// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JakNFT OPEN EDITIONS
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    doxcoko:,;:lccOKdx0d:;cdxdc:;;okkoc;;l:,.';::lccl:ckxlooll:lkoc::lcclcdd:loc:oOkl,lxl';ooccooodkOdlllol;,cxd:ccll:cxOxxoc:dOolocccclllcollocoxxcccol';    //
//    oxd:lxccoolclldd::dodx:,,cddxc'cxocloollc:c;;oddoclddloc,::ddldc:ccddlodc;lxdc;;:c:oocoxxkdlddldkxl;;;';odOkc;:xd:xKx::c:lolcdo:,:odl'lklcoclOkccc:oo,    //
//    dxlloc:cxkxl::::;oxdk0d,,cc;lo:cloocldcc:,clcd0x:ldlcccccccllcc;lo:loc',:lodoll,:o:':xxdxl:oooddo:okl,:oclxdoooddxdoolc,,ldlldc,':clxol:;lloocl:;;;okc    //
//    kdol:clclccd:,l:;oxdod:';:::lddc,cc,ldlooolllcoololoxlcddolol:,,dx;;dxol:oxdlcloddo;:o:,lxdol::l:lxkxlcloc;lc:dddxl,';odddxdccllodkOdldolc:lc:doollxxo    //
//    lcddlooc:oc:oo::ol,,ldl;;c:cllodlldxolc:col;:lkxcclodlloxx:cl::;cd;'oko;lloxxl;,:do,,cc''ldddcllcclololoxol:cddlc:odccodlloo:,:dkookOollcldo:lo;cdccok    //
//    ;;ldl::odoxk0c.cxdkxdoc:cl;;cclddllol:,lkkxdocoklldc:ccooodl:cl::ollko;cl:;:ldc;:cc:;:c;;:::ccldoc::ododdlclloc::cool;;cc:c:ldodxdoloccc',ccloccodl:;c    //
//    xxkOkx:,ldllko.;ol;:oo;;od:ckxc:;:oddl;;:kkloc,dkc,cc,:llollccxd,,ldxo:,,coodxdoccoldd:';cc::cdkxool:,:olodddxodxxc:oooddo;;kOol:,oo::loc:;;cooldl:::o    //
//    oodllxxol::od:'ldodolcc,;dc:oxo:clodko::cddokl':l;,cc:looxdllc:lc,:l;;cc:cddl:,;ollxxc:c:cdldd:llcokl;dkooxxlo0klddc;',ccoc,:ldxl;,oo;;ooll:;:lollccll    //
//    ool::oollc:ol;';ldo;:;;:::;ooclxd:,,lxkkdlolooll::lll:;olcll;,:clc;;;;::oxc'cl,;lcldxoodddol;;ol;:doloxxl:ol';ccol;;cc,:oloolclxxool,'''loool::cldolc'    //
//    o;,:cc:,:oo:co:;dx;,:;;c:cclolcx0c;:',ldolc;c::c,,l:;:ldc;:do;;oxdc:lc::llcc;,:lolkk:,ldddl;'oOdddddl:col;;dxocol;;,:l;::.:xc;l::c;::;:loolc,:dolox0k:    //
//    ;;cc,:c;';ldloc,l:'lko:c:ldooxxdOOo::lcc;;c;;;'.;olc:,:l;:oxd:,;lc'';:;:lcdko;;oooxddc;cxxc'.:doocld:'cd:cxdlxKklc:ccckx::ooc,;cccllcdxddc:oocdxdodxkc    //
//    :coo:col:cxo:;;ckdll;.'l:;odlldddkl:dkdo;,cllldc:lll:oOOxl;;;:'..':lol;co:cdxxllc,;;lc,cxocol::,;cxd:;lxxol:col:;:cooldc,looc'.cddkl':doc::lxolool:cll    //
//    ol;locodcloc;';oxoc;,;ox:,okl.,occoccoodl,.;oc::::cllkOxc:c:dko:lolc:;:ol:ccc:,,;,::cc'cxoodo::occo:;:lddl:lddc,;:;odcclc::oo:lxO0klcdxl;;:ccoo,;:':lc    //
//    c,;l:;xxllcclccclko;ddcoccOkc,,c;:dxdoo;,,'cc''cdo::ddc:;cdxkdddodoc;:l:c;:ddollloccldoc::l:cdodl:c;,;ol::cllxo;ll:ol,;:olcl::clodlcllxd:ol:lc:::;:oxl    //
//    ;,:o;'oxxdloolc:dOlcdc,dOxol;;l:.;xxdO0d;co::c,;cc::c,;:,ckkdc;lolddlc,,ldlloxxdodc,ccl:;oxc:dxll:.':ddllcokkd;cdoldd;cdxoc;'ccclcx0xdxlc:,,loccc;:cco    //
//    :;,c:,:dxxc,:dlcxOo;;;oxlclcldo::cll::looxxollodl;cl:cdxdxko:::cxdxkl:;;oox0Odllloc:c::lc:xOc;cxdlxdllllolccododllooccccxdldlcoo;cooocdkd,;oolddloxxdd    //
//    ;:c;,:c:ld:;l:,':ddll:;c:ll:xdlodo;lkl::lOKOdllxxo::lxdlocc:;:::cokkkd:;lccoxxc;ldc::,;c;;oxd,,llcc:;coxl,;:;coolol:coc,cdxOl:o:,;;,,:ddlccoodkccdxOx:    //
//    ,ckc,llodc,;odcloodcll:::odcddc::lllllollddlol;:ooloxd:;lloc;;;coxd:ldl';:;,:olcdoloocco:,:dd:;:;,cdccool,,cll:,;cc::clc::lo:cxo:oc;lol;;c:cl:;:ol:::.    //
//    dllolloc:cdodkc:;':oxxddddlodl:;:cc:;:c::lxocc:c:cdlod::ollc.':;cd:cc';c;:odoc,';dOodo;:;:ddldo:',dx,;xxc:clldkc,;:,;lxo:ccoloo:xk;colc:oxdo;.,cc'.,,;    //
//    lc:ddcl::locc:cc,';xOoc:okc:cll,:oooll:,,cccoc,clldolo:;dl;:coo;ckd:cclxo;,'...:olodoollooc;:lc,,clc:lxdl:ld:;cl:,,:dxlcdxOxl::ccolll:;ldxoccolol,';lc    //
//    c;lxddl::col;.,llllccl:;odcclolcdd:oOklcdo;cdxooolodlol:::xOxdo::dkodo,',,;;:c;:dddloOkoc::llcdxlc:;::loc:oo:cloo,,codccxocdl;coc,'.':ll:;clodxdxo''cc    //
//    c,;xolocldl:,.;cox:';;';xl,:oxo,;coxdlcoxoclcdxol:ooclc,,;lkd:;:;cdddl,;lxxxkdddl:,:ol:xkl,,,;cxxlol:;';lodocol:oooxOOxlccloccl:;cldl;lo;;oOxloododdlc    //
//    ,:odlllxdcc;odl:,::;od::doc;lxo:lcco:,,cd;;dl:co:cOkkOocloxkxoolcolcllcclcccldkc,cloxo;;oo:ll;cxx:c::lc::lc::do;oocxl;c::olldd:'.coccldc;:coccclolcc::    //
//    olloddollol:oc:c:llcookdcolldl:coddxo,:ooccokocc',ddodolloooxl:c:oxxolcloclodxddxkxdxdllooooo;;ll;:c:;',ldc:lo::dd;lxdclddxxxo;;od,.clcoo;:o:'cx:'cccd    //
//    ::oo:cl,,oc';:llcol;clodxccol;:xdlkOc;lo;,cdOxoocollxd:co;,;cl;,looxkd:,;cooodolxdlcc:;:;ckkl',c:ckkc:lxxo;.:dko:kd:dxccoc:codl:cloxddoodoxocdxxxddolc    //
//    l:l:'cl::ldc;:lc;cl;:cclc;,cdlclc;:l'.;dllxkxlccdc,cdo:;;',cxxolclo:,'';olcldo:';xkc';lo,':llclccloxdlddoc;lxxOklcc::l:;oc;lc,:clollc::dkdl:loxxlldo;,    //
//    odc:cd:,::odoko:;:loodc';oodkxc:coc;,:c;colc:ccldlc:,:ldkoccolc:lxo:;'cxlclcl:;,cxc;;ckOdcccccdxoloxkOOkko;:;,:;:ddlxd'':cdoc;:ocokd;';dOo,;l::::odl:;    //
//    lo:,ld:';xOxxddoll:cl;',:cddxx;,cl;.,;;:;;xd;:llokdol';loxl;;:;;coccdlloll:,.:kllx:,;coloddxxooxdlolcxkdooodocccokxddo;.,lxdol;;::xxlcdkd:;::::clxOxc:    //
//    ,;:lccxo;ldodddllxococ'';dOdllccol;::;:lcokoldl;cxxo;,lc:c;..:docoollcldolllcoxollcxxdxdldko:lxdccc',ool:ckdl,,xKklloxl,cdo:;o:';oodoccoxx:;oolcllldxd    //
//    c;:dl,cdlc:::::;:lxOklcl;;lo:,,:ccl:loloxdlcll:cdoclloOd:ldl;:xdcloc,:cll,lOOOdod:lOd:lo:'cdoxOdol::lldd;';;;;:kkc,coc,,loolcc,.;ooxkc;clxxxkdoc;clkxd    //
//    oo::oc;dd:llol:;,,,odcxOl';xko;,clol:cclcldllooooolc,;lxkOOdoolod:;;,,ll,;xklcc:do;lol:,',clcdxdkc;oolxx:l:,cclolc,cdc;;xo;dl;;.,ddddccolodooldoc:;c:;    //
//    koc:lo;,lc:oc'..:xo:lc::::clxo:;lxxkkolxdddoxoodl:,coo;:ddxxoc:dxdlcc',;'lkkd:,'cdol:coc',lccl;cxl,'odcc:lo;:oxdxOo;:ldxxo;;:xkl:ll;lxxdoxdoocc::lc,cx    //
//    koddlccclolooll:oOdc::dOocdxo;;cxocoocdx:,ccol:looddl:clooxOx::dc::,cl:;;;dKOdlcoxl::;lko:l:'.,oddl,:cldc'...':c:ll:lodddl:'.cd:';okxxxooxo;ccccodccox    //
//    dxl;:cldccllOO::ol;;:lcol:cooc:lddoo;,::;;coocdl,,:::ccclodlcddxo'.'',:c::odc;;cdo:'.';:dxdooc';c:..;cooc.....'codkxxxkOOdlo;.clcdlcdododd;:doldkkxkx:    //
//    llcododd,;o:cxocc:::coodc,clxxd::l:ll;,..',:odo;,:codccldl:,';ccc,... 'l:cdolcldc'lo,.;::ooloo,..  .,:lx:...   :xkdoodxxkkxxo;.;oxdloc:c:,:oloolooloo;    //
//    :okdlokd;,:lcc:;;:coxxod:'cxdddc;odldd;    .cl;:;:dl;ldxkd:;'......    ,oo:;loll:'... .,:::clc.     .:dd'      ,codxxdxkdoodd:,codxldkc',ooooodxxxdodd    //
//    ;cdlcddl:,:odccxdloxkxdo:;llcldolc;cllc.    .,,:lloo:,ldc:ll,...       .:oxkoc:,..     .;cloxl'. ..  .cc.      ..cxOkxkOlcddodxl:,,,;oc',ldxllolodc;oo    //
//    ;cc:lol;';ddc;clldc;loldkd:,,;dOxxxkkkx,      .':lc;clc::cdd,...        .lkkxo:.       .:::odl;'.     ..        .'oOkxxklldllooc::clc;cl;,,cxdol;:c:ld    //
//    :;',,cdc:k0Oxdxd:;oddlcdkkdccoxkkkkkkkk:        ,l;';c;;loxo;'..        .,okxd:.       .cc;ldxc.      ..         .l0Okkkxdl:ox:'lko;cxdlollxocollddl,,    //
//    ,;,,cccok0dc::x0l:xx::doddlcccdOkxxxkkkc        .,ldlloloxdc,'.          .,ldl.        .;ooccd,       ..        ..cO0OOOkoldo:;coddoxdlxxc,coodoxllxc:    //
//    cccll;::ll::cccddoodc;dkdldxllxxxxxxxkkc.        .cxkOOkxxo:,.     ..     .;:'.         .,dxc,.                  .cOOkkOOl';ll:cd:;okxcldc,lxxxlooxkll    //
//    kddc:lxxkoolclc;o0klxxdxdokkldkkkxxxddxl.  ..     .okkkkxxl;;.    .''.    .'...   ..     .lko'                   .;xkkkkOx:,:l::l::odkxclc:lc;;locool:    //
//    c;l:cl::okklcc,:kOkllxdxoclxddxkkkkkkkkl.   ...    .ckOkkx:'..    .,;..   ...     .;.     'oc.                   ..cxxkdldc:ooolcodl::ccoc:c::cl:,cooc    //
//    oollxo:cdxodxl:cdOdldc:dxodllxxxxxxxxxx:.  .....    .,cxkd:,.    .,::,..   ..     ,l,     .,'.                     'oxxkOOxlxOkl,dkocllcclc,;collllool    //
//    clc;l:,lo''llcooclxl;lc;:oxookOkkkxxxxd,   .'';;.     .;ol;'.    .;;;'..  ..     .:o;.           .      .  ..      .lxkOOkOkOxddc:cdd::oocclol:,cdoold    //
//    ;od:odc;l;;xo,,llld,:do:;clldOOOkkxdxxl.  ....;o:.     .';'.    .:;.'...         ,dxc.          ...     .  ...    .;xOxdkxdxdlll;:oxxlododoooccodc:xxl    //
//    lOkol:cdxc:olllodxdccdxl:loooxOkxxxxdxc.  ....;xd,.      ..     ;dc'...         .lkko,.         .;'    ... ...    .lOOkxOddxcccooc:okkkocccllokkocl:lx    //
//    :c;:lxddx;:olccoddxd;:lcco:lxxkkxxxxxkl.  ..'.:kOc.      .     .lOx;...         ,dkkx:..       .,c'.   ... .'.     .cxdcddlcoocdxxokx;;cdkdcokkdxOd:ox    //
//    loddodlcl,,;:olldlokc;llcllxkxkkxxxxkOc.  ....:OKk:'.          ,xOkl'..        .lxkxxl,.       .:o;.  ......;,.     'll:cccdOd:cdolod:,;dOxcdOxxxkocol    //
//    ,;:llcoxl,ll;:oxxc;dx:lkddkkxkxkxxxkOx'   ..''cxxxo:'..       .oOOkxc'.        ,ddddol:'.  ....;dxc.. .....'l:.    .,ld:,:lkd;.,ool,.codkxc:cdkO0Kklc:    //
//    lo;;,cxo;okxococco:;ddlxddkkkkxkkkkkkl.   .'',coddxd;..       .dkkkkxl'.   ...'lddxxdooc'. ..'lxxxo;.......:dl.     'collool:;,:::c;:ooodOOdl;;cldko;:    //
//    kkccodoloxdloc::;look0OkkOOkkOkOO0kkkc.   .'',cdddxkxc,.     .,xkkkxddl,....':oddxxxddddc,..;ldxdodo,.   .;ldl'     .;odxlcdOOoc:;:lkOxlcdkl,;ccloc;;l    //
//    olc:dxl::lc;cc:;,ldldoldxxOOOOkkOOkkx;    .'',lxxxxxkxoc'.  .cdkkxkxddoc;,;clooooddddxxdoc;:oxxxxxxdl::::loool'.    .cdxxl;::dkc,;::ooclooc:c,;olkx::o    //
//    c:lkxc;ldc:lxdc:cxo:odc:cdkOkkxxxkkkd,   ..'',okxxxxddddo;..cdxxxxkxxkxdoclooooddddooddddoloxkkkxxxxdddddddddl;.    .:dxxl;:;;oc;l:;c;,,ckl:ooolokdcdx    //
//    o:;coo;',;:ccco::xxxdlxc:xkkkkxxkkkxo'   ....'cddddddxddxdodkxxkxxkkkkkxddoooodkkkxdooddddddxkkkxdddddddddoooo;.   ..:odoc:lc;co::od::dclOo;clokdlolcc    //
//    coddc'cooxldxcdlldodoldookkxxdddddddl.   .....:olloooodddxkkkxxkkxxxxxkxxddoddxxxkOOOkxxxkkxddddodddxxdoddoool,.  ...cdlcclodc,cc;;::cxdclol,,cdkdodol    //
//    lox0o;ldxd;;oc:xx:,;;;'.;xkkxdddxxxd:.   .,,'':dddddoooooddddddddxxxkkxddxxddxxdxO0K0Okxxxxdoodddxxddodddoooo:'.    .ldcooox:',:coc:c;cdkdldookxxdodc;    //
//    lkddo;:xkxlc:cloloooc:oxkkkxxxxkkxxxc.   .,,,,cdxkkxxxdoooodddolcldkxdoodddddxxxxkkkkkkkxxdddddxxxddooddddooo:..    .cooxkOkololokxo:''okccxkl;;ldkOl,    //
//    lkko:lxOxlxkl;,'.,cooodxOOOkkkxkkxxxc.   .;,''lxxxkkxxdooooooolc:;;:cclloooddxdolc:;;cdxxdddddxxxddoooddxxddxo;.    .,;,;;clcododdxxc;:cdl:lc;:kOkxc;c    //
//    dodl:dkddoxo;:llxkc::lxkOOkkkxxxdddd:.   .,;',dkdoollcc;,,,''',,''',;::::::;;,'.......','',,,,''''''''',,,,,,''..    ...  ..,loo:,;:coooxdl:cooodoc:dd    //
//    lxl;:dko::xkoclccoxo:ldodxxxxxxxdddx:    .,,,;lc;;,,;;,''..........................               ..............           .,dxxooxoodlodcllldddxkl:cd    //
//    l:coc::l;,lddolllllc;;'.';:;cc::;;,'.    ',,,,...,,,,,'...........                                .                        ';::;:ldolocoko:,:cldoodc',    //
//    c;lxlcoxldx;lOxodxoldo;;oxdol;''..       ...............                                                              ..  .'',dkd:;c:;:lxd:cox0kokO:,c    //
//    :;;oxlxOoxOooocc:oooxx:,ldd0k;......                                           .  ....,,...',,'',,:c,;;..':;.......    ...,;:lkkc::lxc;xOkkkdxklcoloxo    //
//    oxddo::oxdoooodc';cldc,:llcoo;.                              ......  .;:;;'.;c:ccdoccldxxc:oxdc:oclxodx;;codlllc::::c:'';lxxdk0o';lllodloxxxkdc'':lddl    //
//    xdcdxc;;,;,odlkxlcldl;:lcllldoc:'.''.....'';'.'::;l;....:oc:ll:,',;;;ldollocdkdxOkxdkdclkd:oOoll,,,;ddddldOxddooolxOxl:;clcxkddo:cc;:xkl;:c:loc:;;coox    //
//    ccccccc:,;lll;:o:.:Oxloodl:lxxkdlcccod:,:oxko:oOOddoclc,ckxc:lxo,;l;:xklcollodl:lkkkOkkOOOo:codddoccokdoodxddxdoooddodxdl;;coc;odl:;cdd:'';::c:okc';cd    //
//    docllcldo::co:'lx:;cld:'lc:l;cdolodoll:'.:oo:'lkxxd:okc,:okd;,cc,lxdooo:,:dOdcc;;dkxkkxOkllo;,lcco;;ll;:lllcol:oxlldxddxlc;;oc.;olc,,dkdl',dd;:llodold    //
//    lllo:,cl;okoll;cd:',:olco;;loc;ll;locoxddxdol;;:odollodxocdxoc,;loc:lc:l;,lxdcc;:xdxxdddolcolcl,'lo:;'';oOl,:lccl:ll;ll:;,,;loolodkd:lkOo:oo:,coxd:cl:    //
//    xdxdcoxdlcol,:ddllccddloolddlc;cclddodl;:olld:,:lcc:coooc;:clc,'lxookx:clcx0d:loxold;.;::loxxlc;:oxl::::ldoolc:ldll:.'ldlccccxdoo:loc:ll,;lc,..'cdl:cl    //
//    d00lloldOkolodo::cloolcoxolc,;llodolccc;odc:cloc,;;:xklddlooxOOdocdxcccll,:dolloo::::c:;,:odolodolccdollcdoc:dxdlldol:;;lc:,;oolol:xx:c:'ldlcldocllccl    //
//    odxccdodxdldOdl:;:docll:':dklcc,,;lddxdodxc.;kkc;;coooooool;:oc:lxoclddl::dkkdc::cllkdcol;:ddccol,;::lxkccldxllc,,;ldo;,:dl;ldlclloxoolocckx,,dl;:odox    //
//    dllc:ldool:;c:::,:lclxdl;,:olllooloccdkdcodooxo,;cckOoldollcol:clccdollccclodocccoookc.;::clodo:locodcll:l:cddo:'',,cdlccc:lc:lol;ol:k0xodko':kd:ldxlo    //
//    lloxolddooc:,,ccc;;dxdxxl;',:lloo:ldococ;,;oxlc:clccooll;:xoc;;o;.'oddolldl:c:cc::ldo;,locldclolxd;,cl:;ddloc::;::od:;cdc,;codo;cxd:;oxdkkodxol::ocldc    //
//    :;:lc:loclc:,:lcclolldko;:;:d::c,'x0odxoclool;;:oko;lo,.,do;:lloc,;oxdlclc,.'cdoooc,;:col;cdc:occo;:doooodo:;;ol,:clc,ldclooxoclxdlcdkoclllccll:;colol    //
//    d:;lldOl.'lc:lkxcco:cxo:c:;co:;c,'c:;dKO:,ol',:ldxo:ddod:cxlloclddc:cccdl:oodoolccc:c:cc,coodcodoxolll:coc;:cldolodlddoc:cclo:.,cl:;lxxccoolloc,:oxdc:    //
//    :;;oxooo:;xOddoccl:cxd:cdl;:ldd:,:;;cool:;l,;xxc:odcdOdc:odccllodo:,lxddxxdlcodo:cdodxdl:clxxlcxxolc:ccoolc:cdl;cc::ldldoclc,;:cloxkc:o;.:l;;ll;,:llcc    //
//    ::cl:cloo:;ol;cc:c::loc:;:c:lxl'cl,:cc,;::lccxxocc:,:oxdooxklckOdoddook0xl,.,l:;:lkxoxdc:;;:oxdol;:llokklc;;:lc:cod,,ooxOooxxxlodc:llll;;dxllc;cclldo;    //
//    :',;,;cod:,lo:l:;:looddxxl;:ol::oc,ol,,oxodc';ldko,,lcck0kxdoooOOxkkxcod:;;,;clc;lxoodolc:l:,dkdllxkoldxo:col;:od:coll;:dOOxxlcol;;xklldddxlokd:''coc;    //
//    :;:lcoolollooc:lolldl:;dKo;cookxddc:coodd:cccc;lx:.'ol:ddoolll:dOxollcoOdccclcll;,,',:c,'cc;,okoc:lkxcclodlc:,::;::ccc:cldlcllldd,.cd::oxO0dlxkxoccdd;    //
//    Kkxdk0kkdcldoc:lc:cccc:cdkxxxdoll::c;::;;:c,,odk0o';dl,;ldxollclc;looolxdcllccc:ccol;::';dxc,c:',:loolcodoldddl;:c,,clcdoll:;dxdko';:ll::cdko:lkko:lc'    //
//    xd;:oodl,,lxkl:cc;;cc':xxOXO:cxdodxxddd:':ocldcodc;ldl:lxo:ldoc,c:;oool::,l0kdlldxdc:;;;oOxc;:cl;:d::dlc:;lddc,,;clc:::;cxocoocokxolclxdlldxoclxkdlxkd    //
//    ooc;cxdc:;:oc;coldo::ccloxko;:doldo:ldd:.':dkoccc,;oxoclxc;;:o:;dx;;odc:dxllollllllol;cccdlccldo::dddxlllccldc:l:;;,,:lldkkdddolcoxdodxdccoxxoox0kkkkk    //
//    kxo;;ol;;''oo;,:dkdl:oxllddo::lcloxxddol:,ldoc';;'::cdddlcoloo::ox:,lxd::l:,;clc:olcdlcoc;:ododdoddcokc;oodocllxko:;okoodoo;:odl:ldookxddkOdl:.,oxo:cO    //
//    dodocccc:';oookdcclloo;;ldOxclo::odo:oxol:oxc:llcldococ;cdl:ccddlldlcdk:.':looxl'coccdkxlcdk0OocllccdOl:doloo:,loc,:KXdoo::lccllOxolc;:oodxoclcldool:l    //
//    kc;odoocc;;loxdcokdloc:ldldxlc;cdkdcoxdoool::ccdocoo:clcdkxo;lxc',lkxcdx,'lkc,;:lo:,,cdoodkl:dl':c,cxolxl;colxkkd;;ddodoccccdd:cdddddlccclkd:c:co:ox,'    //
//    :lodddo;clooloddldddlcxdc,',':coocloxdlloc,,okood:,lc;codloxccdl,:xdooxxdox0d;:ollll:,cc;cxl'::,;:::ccooddc;:cdOx:cdc:ollxoollc;:c:,:odc;cdc.,dxl:cdl:    //
//    ccc::cddl:c::dkl,clddoko,':l:;cocodxlll;cllcclldoccol;colcod:'co;:odkOkoccool:lxl;cocccl,.lolllclkd:;:oxoc:dx;:l:ldl;:c,:ol:;;:lo:';:coodoll;:dl:odo;c    //
//    :''''colldxc:ooc::colclldko;:lc;codo:c::;;dc:okk:':,;c,;dolxo';o:,clxx::o:cddlcxo,:coOkdc,,;ldxxxxo;;:colc:okccllxoccclcll:c:lxd;;lc;lo:cc;cllddcco:cd    //
//    c;';ccodooodollxo,;:,;lldddd:;c;:lldddllx:'lxodxo:;,,:clc::::..cclocdkdcc:;;lkdl::cloxxo;;lccl::oc,:::clocldkl,,ol:lclococ:xd;cd:,lxo:cxdclocll::c,.;l    //
//    ll,';coc;;,,oxocllclllddodd:';doloolddllolcoo;:olcc;;llllc::oc;::,,cdodxd:'':odc,;:c:,codkOkoc::ol,,.;lc;:ccloc,lol;;xdclccolcloldxoc;coxc,;:cc,:l,,ll    //
//    ;:clc:l:cl,.;lcoxd;;llxkodxc'cOolkxllocck0xooocc;;clldo:ldloOkocol;:oddokxodl;lool::cldlcoc;:ol,:ccddl::coo::od:;c:;oO0dclcoodkxc;,coldd::dxldxooxolol    //
//    odoododdllol::ldkx:,;:doolcloolccc:dkc;;cdccc;coccl:dxl;'ldc:l;;odd:cOOoclclooo;,dxc;ll,':oocc:,lccdocc:;oxxkdldxc:dxllooocodc;:oo,cK0occoxdcloolll;;o    //
//    cloo:;c:;oxol:lcco,;:::;ccdd:..lxl:oxlcoollcl::oodxdxxolc,;ccll,,ldddOOo:cc:cc:;;oc:c'.,;:oOxcc::;;lc:l:.,lldc;c:;cxkxxo:odll:cdlc::oxlcol:lodo;':clxl    //
//    :llld::oxOdlocldoclo:,''loodl::lddcolldo:;loc;cOkoxd:cc:cclxxodl,ldccodc;,:lxo;lo;.,::ccdl;cdl::cdxodko:clclc;;;:lccxkc.'dd::ccc,;:llldol:.':dx:,lkOkl    //
//    oxdoxllkdc:ol;::l:;dl,,;d0Ox:;:;;;ldd;,c,;xl;ccoxOkol:lddllodod:.:dolo:.,::cdoldxo,,col;cxdoddl;odldlcllloloc;oxddo:cOxldxddooddo;:oocllloocldc';cdxld    //
//    :codo:;oOo:xd:c:;cokd;:clxo,:l;cxdloodoc,'ccc:;oocc;ldlldl;:ocllclodoll;;looo:cOdcoc:dxoll,;:,';oc:c;cod::occoloooxo:dxoOddOolddcoooolodc'ckdlldollddl    //
//    dc:lodl:c:lOkddxdlcdkooocll,;dc,coclclolo;c0Kxlodcccodolc;,:;:lool:cooxo:;;:,.;dcokdc;lxlcdl,,;coloxl:llloloxc;:,'cl:oddocloxdlllloddloxxoxOoclc::;:xk    //
//    c::;:odl,,',llldocooddccoxddkko,.lxo;:lodcld:,okccdc:ddddcc::ll;cxlcdxkxc;clc::loOxdl;okxddc;locc::dl:olcl;;:,:l:c;;lll:clcoxocccooodxxoxxol::ccoxxoll    //
//                                                                                                                                                              //
//    JakNFT OPEN EDITIONS                                                                                                                                      //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JakNFT is ERC1155Creator {
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x142FD5b9d67721EfDA3A5E2E9be47A96c9B724A4;
        Address.functionDelegateCall(
            0x142FD5b9d67721EfDA3A5E2E9be47A96c9B724A4,
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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