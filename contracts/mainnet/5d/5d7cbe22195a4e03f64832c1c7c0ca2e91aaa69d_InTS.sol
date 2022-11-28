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

pragma solidity ^0.8.0;

/// @title: Inspiration_Tina_Singa
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    llllc:lollllolllclllllc::cc;;;;;;;;,;looolcldooooooodddoc;;,,:l::::cllcclooooooollccccc:'oOco0xkkdxddxxxolxxddxddkkkkkkkkkk0X0kKXKKkx00xxkxdoodod00xloOOO0kx0KKOkkkkdloxookkdkkdk0kdOKkxd:o0xoodddOOxk00dol;oKNKkkkk00OkkkkOkclKk;lolodxddodxxdloOXxx00OkkxkxddOx;;::;;codxxO0Okxdolllllllllcccccccccclllllc    //
//    lcccc::ccllccc:cllooolc:cl:,;;;;;,,':ollooccoooooooddddo:;;,';l:;:::lllc:loollc:::::::::,:kol0kkkodxddddllxxdddoxkkkkkkkkkkOKKk0XKKOdkKkxOkxdlloO0Oxok00OOO0000kkxdooodldkkxkkdx0Odx00kxcoOkdddddx0xkk0Oool:dXN0kkkkk00OkkkOdcxKo;looddddodxxxdookKxx00OkxdkxddkOl;:,:oxOOkdolc::;;;;;;;::cclllllllc::ccccll    //
//    dc:::::::::;;,;:codoollllc,;;;;;,,''coooool:cllooooooooc;;::';lc::::cccc:lol:;:::::::;;;,'lkoxOxkdloooodllxxddooxkkkkkkkkkkOK0k0X000xx00dkOxdolx0OkodO0KK00O0KOdooodxoldOkxkkddOOxk0OOxldOkddxxdk0kxkO0kloocoKN0kkkkkk00kkkklcO0c:dddddddxxdxddolOKdk000kddkxddx0o;;:dOkdlc:;,'''.'''''',,;;;::cloooolc::ccl    //
//    cc:;;::::::;,,,,,;lllllcc;,;;;;;,,',coollllc:cllloloooc;;;::;col:clcllcccol:::cc;;;;;,,;:;;oxdOOkkdldooolcdxddoldkkkkkkkkkkOKOkKXO0KxxOKkd0kddxO00dd0KKKkdkK0xcldxxdooxO0OkkddOOxkKOxdlx0kddxddk0kxkk0OdoddllONKOkkkkkOKOkkxcl0OccdddddddddddoxdlOKxkK00Odxkddxx0d;cxOxll:,''''''..'''',,;;;;::::ccoodol::c:    //
//    ;:::ccccc:;,;;,,,';clllcc;,;,,,,''.,cllllllc::lollclc:;:;;::;cocclccllc::c;;::;;;;::cccccc:;lxoxkxkxddxxdooxddoldkkkkkkkkkk00OOXKOKKxxkKOdOkddk00kx00kkxokK0o:oxxdlloxO0Oxxdd0OxkK0docxOdddddkOOkxkO00ddddxocxKNKOkkkkk00kkdco0x:lxddddddddddooloOOOO0K0OkOxddxk0dlkkolo;''''''''..'',,;;;;;;;:cccccloddoc::    //
//    :::ccccclc;;:;,,'':ccccc:,',,'''''',:lllc:::;;:::::;;;;;;:::;locclccllc;:;:c:,,;;:cccc::cccc;okooxdkklodddoodooooxkkkkkkkkO0OkKX0kK0dxk00dkxodO0OdO0kkxdkKOl:oxdoooxxkOxdxdx00kk0Kko:oOddddkO0kxxk0KkddddddocdO0XXKOkkkO0Okdcd0dcddoddddooooooolxOdOKOKKxk0xdxxOOod0olo;'''''''',;:cclllllllllclcccc:clddoc:    //
//    ;:::cclcc:;::;,,';llccc:;,'',;;::clcclooollc:;:;;;;;;:;;::c::llcllcllll::c:;,',:cc:cccllooool:xKdoxdkOooddxdodddodkkkkkkkO0Ok0XKO0KxdkkKOxkxoxO0kx0Okxox0Ol:ldoodxkkxdxxkkk0KOxOX0xl:xkdxk00kxxxOK0xoddddodlcxOkOXNX0kkO0Okdcd0d;lodddoooodxxdooOkoOKOO0OkOkxxk0xoOkoo:,',,,,,:clooooooollclooooolc::::lddoc    //
//    :c::ccccc;::;;;;:loc:cc::;;:clllloolllooolloc:lccc:;;;:::::;:lcccc:cllccc:,',;::::cccclllllloc:OKoxkk0xlddddoododdxkkkkkO0Ok0XKO0XOdxkk0kkkddxOOkx0OkxdO0d:cdlokkkxxkkkKOx000OxOX0xl:kOx00kdxkxk0koodddddddcokkkk0NWKOkO0Okdcd0d;ldxoooooxxxxookOdxOK0kO0kxkxx0kld0dol,,,,,,:lllcccllloolodolloooool:::clddl    //
//    cccllc::;,;;,;:clllc::c:ccc::::::::c:cclcccc:;clcc:::cccll::lolc::;;:c::::;;:::;:cccc:::::::c;:O0ldOOKklooddlododddkkkkO0Ok0X0OKKOdxkk0OdkkddxOOkx00xxxO0l:dooOOkkkKN00KdO0k0OxOXOkd:kOkKOodOxdOKxooddddooloxkkkkKNWXOkO0kkdcd0x;oxoddlodxdddokOdxkOKOx0Odkkx0Ollkkooc,,,,,:llc;cllooodoooodxdllooddo::ccoxo    //
//    llllc;::,,,;:cllccc:::c:;cl:,;;;::;;:;:cccccc::cccccclllllclooolc;;,,,,,,,;:c;;;:::::::::;;;;lO0olkO00doooddlododddkkkO0Ok0K00K0kdxkk0OooxkxlokOOxkKkdx0OccdoxK0Ok0WXOXOxOkkO0kkX0OOllOOO0ddOxodk0K0kxollldkkkkk0NWNKkk0Okkxco0kcoddxolddddodOOxxOO0kxOOxkkk0OlcdOxoo;,,,,,cooc:ododxxddxxxooxdloooddl:ccldd    //
//    olc:;;;,,;ccllcccccllccc:cll:;;;:::;;;;:loooooc:cllllllllcclllooolc::;,,;:cccccccccccllllccokOxlokOO0xdkdodooxdddddkkO0OOKK0KKOxdxkk0Old0OkkkxxO0kd00xoOOclolkKKkkXWK0Xkk0dxkOOk0XO0kcoOOkkxOOkxkOO0XKo:oxkkkkk0NWNKOk00kkkkllkOlcdxdooddoox0Oxk00OkkOkxkkO0xccodkdll;,,,,;looxlldddddddxkkxodkoloodol::lldx    //
//    l:;:;;;::clclccclloodolccccclc;;:::;,,,'';cllll::ccllcccccllllooolccc::;:cclodooollloooldOK0kooxOOOOxooddoloxxdddddO0OkO00KK0kxdxkO0xlldOO0OkOOk00dxKkoO0olockK0xkXW00Xxk0kxxkO0OKK0XkclO0xxkkkO00OkxoldkkkkkOKNNX0kO00Okkkkolx0dcxxddoooxOOxkO0OOkkOkkkO0klcodxxxoll;,,,,:ooxkdodddodddllxkddkollooooc:clox    //
//    :::;;:ll::lccllodddxxxo:clooolccc:;,,,'''.',:clllccccc:::clllccccccc::::;:loooollllooox0X0xodkOOOOxooddollxkxdddxdk0Ok000K0Oxdxkk00dcodddkOO0kO0k0koO0xk0dlold00xkXW00Kxk0kkxdxO0O00KXklcx0OdooxOKK0dlxkkkkkOXNX0OO0K0kkkkkkxldOOolddddkOOkkOOOkkOOkk00Oxolodddkxxocl;,,,;cddoodxxddddxdlcodxkxllooodxoclcox    //
//    :;;;cllc::cllooddxxxdoccoxxxddolc::;,''''''''',;:ccccccccccccc:c::::::cclllodddddoldk0X0kxkOkOOkxooodddod0OddddxxkOkO0O0K0kxdxkOKOoodooddoO0kOxkOO0dxKKkkxldolO0xx0WX0KkkKOkkxdxO0O0KKXOoclO0xdooxOdlxkkkkkOXX0OkOXXOkkkkkkkkdoxOOllk0OOkkOOkkOOxk00Oxdooxkkkk0kdOdlo:,;,;loooxkkxdddddddoodddolllooddlcccdd    //
//    ;;:llccc::looodddddodxdoodddxdxxdolcc::;;,,,'''',,,,;;:ccc::::;::::cloooooooddddodkKKOxox00OkkxddooooookKkodddxOOOkO0O0KOkxdxkOKkldxxxdooooO0kxx0O0kd0NOxkdddld0OdkNN0KOx00kkkkdxO0O0XKX0xccdOkdddo:okkkkkkKX0kkk0X0kkkkkkkkkkodk0kldkkOkkkkOkk00kdolldkkkkkO0Odk0odd:,;;:oddxxxdxxdddddolcc:cccccllolc::cdo    //
//    ;:llcccc::odddddooloxkkxdooxxdxxxkkxdlccc::;;;;,,,,,;;;;;;::::clooodxxdxxoodoloxO00kddk0Okkkdldkkxoold0KdodddxOOOkO0OKKkxddxk0Kdlooddxddddox0OkxO00OdON0xkddxook0kdONXK0xk0Okkkkdx00x0XKKKkoclkOddocdkkkkkOKKkkkkk0KOkkkkkkkkkxodk0klokxxkkk0OkxoodxO0O0000OOOdo0Ooddc,;;loodddxdxxxxdddc::ccclooddxdcc::ooc    //
//    :clcccccllodoooool:ldoddddoodxdxxxkkkkdoolloolcccccccc:cc:ldddoddooodxdxxxolodO0Okxook0OkkxdooodxxdokXOolddok0kxkO0OKKkkddxk0Xxlddddddddddld0kkx000OdON0xkxoxdloO0kx0NKKOdk0OkkkkdkKkdkKKKK0dl:dOxdlokkkkkOK0kkkkkkO00OkkkkkkkkxodkOOlcxxkOkxddxxddxxkkkkOOkkxok0xdxo:;;:odoloxxxxxddddl::clodxxxxxdl::codo:    //
//    clccc::ldocloodddo:lxddoooodooxxxxxkkkxddoodxdodxkxdddoddoodxddoddooodoxkdlok0OkddxxkOkkxoldxddddooOXklldddO0kdxk0O0KOkxdxkOXOloxxxdddxxdloOkkkk000kd0NOdOklxxolk00kx0X00Odx0OkkkxdO0xxxOKKKKxl:oOklldkkkkk0KOkkkkkkkO000OOkkkkkxodkOOocdxolokkkOxcldxkkkkkkxdxOxdxoc;;;ldxocodxxdddddoccoldxxxxxxdc::codl::    //
//    ccccccloolloddddooc:ldddddoooddddxxxxkkxddooodddxkxddddxxxdodddddoooddooddk0OkdooddOkkOdoxdoddddlo0Xxloxdx00xdxkOOOK0kkxdxk0XxldddxdddxdddkkkkO000Oxk0OxdKkldxxod000kkOOOKOddO0OkkdkKkxkxkK0KKkl;oOxlldkkkkk0K0kkkkkkkkkO0000OkkkxodkO0x:;dOkxddkkoldxkkkkxddkOxddoc::;:odxdllodxddddxdlodoxxxxxxoc::lddl::c    //
//    cclcccoollllodooooolccodooooooddddxkxxkxdoooddxxdxxddddxxxxxddddxdoloxxld00OxooxddxkkOdooodoooollOXxloxdx00kdxkk0O00kkkddkkKXdldddddolodxkxkOO000Oxk0xod0Xxlddxoo00OOOO0kOK0xdk0OkdxKOxkkkkK00XOl;x0dlcokkkkk0KKK0OkkkkkkkkO0000Okxodkk0kcokooddxklokxxxxxdxOkxdolol:;;lddxdoolldddddddoxddxxxdl:::coddc:ccl    //
//    lllccooooodolloooooool:looooooodoodkkdxddddddxxxxddooodddxxxxxxxddddllok0OOxolokdxkkOdloooooooocxNOloxdd0KkxdxkOOO0OkkkddkkKXocddoooddxkkkO0OOOkxxOOxxk0N0oddddllOKOk00OOkk00kdxO0xdK0xkkkkk0OOXOlcOOdolokkkkkkOKXXXK0OkkkkkkkOO000xoxkkO0d:ldddxdlxkkkkkOOkxdoolol:;;cxxxxdddllldddddooxdodoc;,,;cddlcccc:;    //
//    llccloooddodolooooooooccooddollodoodxddxxxxxxxxxdddxxkkkkkkkkxxxxddoloO0OOxloooOkdk0xldxdddxxxloXKdlxxokXOkxdkkOO00kkkkxdkkKXd:llooxkkOO000OkkkkkkxxOXNXOooddddcokKKkkKXkxOkO0OxdxkxK0xkkkkxO0k0XOcd0xdkdoxkkkkkkOKXNNXKOkkkkkkkkO00xxkkkO0kccoddodkkOOOkkdolollol::;cxkdxxdxdooloddddlodl:;,'',codoc:::;;,,    //
//    lccclloddddddoooddodddlcoddollooddllxkxxxxxxxxddxxOOkkkkkkkkkkkkkxxlo00OOxddooxxddk0olddddddkxckWOooxdo0XOkxdxkOO00kkkkxdxk0NO:cdxxkO00OOOOkkkkxkOKXKOOxodddddlcdkKXOOXWNkxOkO0OkxodK0xkkkkkk0OkKXdlOOdOOocdkkkkkkkO0XNNNKOkkkkkkkkOOOOkkkk00l:odkkkkkxdolllloolc:;:lxkxxkdxxddolooodlc;,''''':oddc::;;;::::    //
//    cccllloddddddddoodddddllddooolllodoldkxdxxxkxddkkkxxxxxxxkkkkkkkkkdd00OkdddlldxxxoOOllddoddddllKWkodxdo0XOkkxxkOO00OkkkkxdxOXXdcdkOOOOOkOOkxkk0K0Okxddxkxdddddclkk0XO0NWXKkkOxO0OOddK0xkkkkkxOOx0XklkOdddxllxkkkkkkkkO0XWNX0OkkkkkkkxkK0kkkk0Kdcddoollllloooolc:;;:okkxxkxdxxxdooolc;'....'';lddl:;:;;;:lccl    //
//    lccclloddxddddddoddddoloddollloooxolokkdddxkdxkkkddkkkkkxxkkkkkkkxd00OkdxoccdxxkxkOkccooodxxdcdKNOddxxlkNKOkxdkO0O00kkkkxddk0NKolkkkkOkxkO0K0OxdlllodoodddddoclxkkKX0XWN000xkkkO00xkKOO0kkkkxOOkOKklkkldkOdcdOkkkkkkkkkOKNWNKkkkkkkkxxOK0kkkk0Kd:cccclloollc::;:coxkxxkkxxxxxddoo:,'....'',cdxdl;;;;;;;clccc    //
//    llccllodddxddxxxdoddllddollllooloxdloxkdddkxxkkkkooddkkkkxxkkkkkxdO0OkxdxlcoxxxxkkOOooolodxxdldKN0ddxxoo0NKOkxxkO0OKKOkkkxdxk0NKllkkxkOKK0xddlloooodddoooooc:lxkkOXK0NWXOOKOkkxkO0k0KdkKOkkkkOOxOKdlxdxOkdccxOkkkkkkkkkkOKNWN0kkkkkxdkkOK0kkkkKKl:ccccc::::::cldxkxxkkxxxxxxddoc;'......';cdxxo:;;;:;:ccol:c    //
//    olccloooxxxxxxxxxdllodolcclooooloxdlokkxddxxkOkkkkdodxxxxxodkkkxoO0OkxxxxolxxxkkOkO0odxoooddolx0XXxddxxld0XX0kxdk00OO000OOxxkk0XKdlkXX0xolloxxdddooddxxxdlccdkkkOKXKNWN0kkK0kkxOkkkKOld00kkkkkOxOOooxkOxkxlokkkkkkkkkkkkkOKNWKOkkkkdxkkk0X0kkk0Xx;;::;:::clodxkkxxxxxxxxxxddxdc,''...'''coldxdc;;;;;;:cclllc    //
//    lolccldoodxxxxddooloolllllloollloxdlokkxdddxkkkkkkOxodxkkkxooodokKOkxxxkxooxxxkxOkkKdlxddxxddldOKW0dxxxxodOKXK0xdxO0OkkOO0OOO00OKXOddooodddxodddoddxdooolldkkkkOKXKNWWXOkkK0kxxOkx0KkooOKOkkxkOk0dldkOkkxlokkkkkkkkkkkkkkk0NWXOkkkxxkkkkkKXOkkONO::llloodxxxxdxxdddxxxxxxxxxxo,.''''''':xoldxdc;,;;;:clc::ll    //
//    lollccloddddddddddoccccccllllllldxoldkkddddxOkkkkkklcdxkkkkxdocdK0OxxkkkdodxdxxkkOk0klodddxxxodOOXNkdkxxxodkO0KK0kdxO00Okkkkdx0000XKxoooddoxxdooooooooodxkkkkk0KKKNWWN0kkOK0kkkkxOXOOkoOKOkOxkOOkodkOkxoldkkkkkkkkkkkkkkkOKWNKkkkxxkkkkkkKXOkkKNOclooddddddddddxddxxxxxxxxxxdl'.''''.';lxdldxdc:;;;;:ll:;;cc    //
//    llollcccloodxxxxxdlcclcllllcllllddloxkxddxxxOkOkkkkdoodkkkkxdloKKOOkkkOkxlodxxxkxkkk0dododdxxloOO0NNkdkxxxddxkkO000kkxk000Okkxdk00O0XXOdlloddocllodxkkkkkkkO0KKKXWWWN0kkkK0OOxkxOXOx0koO0OkkxOOxldkkkxlcxkkkkkkkkkkkkkkkk0NWXOkkxxkkkkkkOKXOk0XNd:lllllloddooodddddxxxxxxxxxdl,.''...,coxdcoxdc::,,;:ccc::cc    //
//    lllllcc:::::ccllloocllllllclllclddoxkkddxkxxkOOkkxxxxxxkkkkxdlkXOOkkkkOxxooodxxkkdkxOOlodddxkdlxOk0NNOdkkxkxddxkkkkO0Okkkk0000xdk00OkOKXkc:loooxkkkkkkkOO0000KXNWWWN0kkk0K0OkxxkX0xk0kx0OkOkkOkooOOkocdkOkOkkkkkkkkkkkkk0XWN0kxxxkkkkkkk0X0kOXNk:cloooooooooddddooooddxdxddxdl;.'''.':ooddcoxoc::;',cccc:;:c    //
//    clcllllc;,,,,,;:oxl;ccclclllllcoxxxkkddxxkkdxkkkdxkkxdddxkkdldKKOOkkkkkxddxddxxxkxdxx0klooddddclkOk0XNKkxxkxxxxxxxkkkkOOOkkkk0K0kxO0kdoddodxkkkkkkOO00000000XWWWWNKOkkkOKOOkxxkX0xkOOxO0OOkkkOkcx0oldxOkOOkkkkkkkkkkkkk0XWN0kxxkkkkkkkO0X0O0XNkccoooddddddoooddddddoooodddxxoo:''''',ldoddclxdc;:;',;;:cc:::    //
//    cclllllllc:::;:dxd:;::ccclllccdkkxkkdxxxkOkdodkxdxkkdlcdxxxdlkX0OOOkkkxxxdxkoxddxkdodx0klooodlc:dOkkOKXNKxddxOkxdxxxxxkkkkOOkkxkkoldddxkkkkkkOO000000OO0KXNWWWWNK0kkkkO0OOkxdOXOxkOOxk0Okkkkk0x:lddxkkkkOOOkkkkkkkkkkOKNNKOxxkkkkkkkO0KKOOKNKdclodddddxxxddddooooddddooodxxxdol,','';lddodcldol:::,,,;ccccc:    //
//    cccclolllllc:lxxxc;;ccc::cllldkkxkkxxxxkOkxxdlloooddoccdxxdooOXOkOOkOxxkkddkkddddxkdlodOOdlloxOxcdOkkkO0XNKxxdddxOkxxxxxxkkxddllodxkkkkkOO000000OOO0KXNWWWWWNX0Okkkkk00kkkxdOKkxkO0kkOkkkkkddxdodkkkkkkkkkkkkkkkOkkO0XNX0kxxkkkkkkO0KK0O0XXxccxxdddxxdxxxxxddddloddxxxddddxxxoo:',,':lddodlcodl:::;,;;;clccc    //
//    c:::::llloocldxdoc:,:lcccccldkkxkxdxkxxOkkxxxdllllllclxxdddoo0XOkOOkkxxkkxooxxdddddxxdodxxdO00xdoloOkkkkO0KNNKkxoooxkkxdllooodxkkkkOO0000000000KXNNWWWNNXXK0OkkkkkkO0OkOkdxO0xxkO0OkOxxdoxdodxkOkkkkkkkkkkkkkkkOOO0XNX0kxxkkkkkkO0K0OO0XKxlcodkxxxdxxxxxxxxddxdoloxxxkxdddodxddo;',,;codooo:ld:;c::;,;;;:ccc    //
//    llcc:;;lllcldxdool:,:lllccloxkkxxxxkxxkOxxxxxooxxxxxddxxddoll0XkkOOxkkkkkkxdododdllodxolx0KOxdxxxxookOkkkkkOKNNNXkc;llllodkkOOO0000KKKKKKXXNNNNNXXKK00OOkkkkkkkkkO00kkkxdxkxdxxxkxdxxxxxkOOOkkkOkkkkOkkkkOkkkkO0KXXK0kxxkkkkkO0000O0KX0dlldxddxxxxooddddddddxxddloxxxxkxxddodxddl,',';cooloclo:;c::;;;;;:::c    //
//    ccll:;:clccdxdoll:,;looolldxdxxxxxkxxkkxxxkxdoddddxxddddddoolOXOkOOxkkkkkxxxkOkddooolld0KOxdxxxxxkO0xokOkkkkk0XX0kocldkO0000KXXXXXNNNNNXXXK0OOkxxxxxxxxxxxxxxxxkkOkxkkxxxkkxkkkkkOOO000O00OOOO0OOOOkkOkkkOO0KKXXK0kxxxkkkO0000OO0KX0xolldxxxdddddddxkkkkkkkxxxxxolodxxkkxdddoddddc,'',,:olclcll;:lc::;,;;;;:    //
//    lcclcccllcldollc:,;loooldxdddodxkkxkkxxxxkxxdddxxdxxddddddoolkX0kOOkkOkkkxxxk00OkxxolkK0xddxxxxxOKOdlcldxOOkxooooxO0KKKXXNNNNNNXXK0OkkkkkkkkkxxxxxxkkOOO0KKK000KKKKXXKKKKKKKK0000OOOOOkkkkkkkOO000OOO000KKKKK0OkxxxxOOO0000OO0KK0xolloxxooooccodxkkkkOkkkkkkkkxxdoxxdddxxdddoldoodc'''',;cllccll:clllc:;;;;;    //
//    olcllooocclc:;::;:looodxxxdoodxkkxxxxkxxkxdxdddxxxxxdxdddxddldXKkOOkkOkkOxxxxkOxxxdd0KOxddddkdkXKxollooollolldkKXXXNNNNNXXK0OkkxkkOkkxxxxkkkxxxxxxxxddxxxxxkkkO0K0OOOOOOOO00000000000000000000000KKKKK00OkxxxxxkkOO000O000KXKOxolldxxoodddxxdolxOkkOOkOkkkkkkkkkdoxxkkkxxddddloxxxdc,'',,,:lccclolcclllc::;;    //
//    oollooolcc;,,;;:cooodxkxxxdodxddxxxxkxxkkxdxxdxxxxxxddddoodxol0XOOOkkOOxOkdkkkOOkdo0KOxdxddkxxX0olkkxolc::okKXXXNNWNXK0OkxxkOOOkkkkkxdxxkkkOOOkkkdoxkkkkxxxxxdddxkk0000OkkkkkkkkkkkkkkOOOOOOOOOOOOkkkkkkkkkkkOOOOOOO0KXXKOxdolldddddodkkkkkxdolxOkkkkkkkkkkOkkkkodxdddxxxkkkkdokkkxdl:'',,,;::cc:ldlccllllc;    //
//    loolloolc;,;,;cooooxxxxxdxxdddddkkxxkOkOkxdxkxdxddxxxddddoooolxX0kOOkOOkk0kxkkkOOdkK0kdxxoxxdKKddxddxo:cx0XXXNNWNKKOkxkOOOOOOkxxxxkkkkkkkxxxxxxxoccldxxkkkOOkxxdddodxkO0000OkkxxxxxxxkxxxxxxxxxxxxxxxxkkkOOOO000KKK0OkxxollodxdddxooxkkkkkkxooxkOkkkkkkkkkkkkkOdoxxxxdddddddxdloxddodol;',,,,,;:c:ldooc:cllc    //
//    loollool:;,,,:odooxxxxxdxxxdoxkkxxxxkkkOkkdddxxxddxdxxxxdoooxxo0XOO0OOkOkk0Okxxkkk0KOxdxdokdxXOodxxocoOXXXNWWNK0OxxkOOOOOkxxkkkkxxxxxxxxxxxkkkkOdllok0000OkxddkkkkxkkxdkkkkOO000K00OOkkkkkkkkkkkkOOOO00KKKKK0OkxddolllokkxdodddxxdoxkkkkkxxkOOkkkkkkkkkkkOkkkkxodxxdddddxxddxxllodddddddl,,,,,,,:ccloooolc:c    //
//    lloolooc:,,,,cdooxkxxddxxxxkxdkOkxdddxkkkkkxddddddddddodddxkxolxXKOOOOkkOkxO0OkxoxKKkddxddkdkXxldlcd0XXXNWNX0kxkO00OkkxxkkxxxxxxxxkkkOOOOO0OOOOOdlllxkkxoolloooodxkOO0OOOOkddxkOxxkkkkOOO0000KKK00OOOkkxxxdddlxocodddddkkxdodddxxddkkkdddddxxxkOkkkkkkkkkOkkkdodxxxddddddxddxxoloddxxdddxo;,,,,,,:lccooodolc    //
//    lllolooc:,,,,ldlokxkdoxxxxxkOxdxkOkxxxdddxxxxxddddoodddxkkkxlodokX0OOOOkk0kxxO0kokK0kddkxdkxkXOccdKXXXNWNX0kxkO0OkxxxxkkxxxkkkkOOOOO000OOOOOOkxdlllclodcclccccccclokkkkO0OkOKX0xxkkxlcddooodxdlllcllodoooxkO0kOkldddddxkxxdddddxdodkkooxOOOkxodkkkkkkkkkkkOxoodxxxxdddddddddxxoloddxxxdooxd:,,,,,;cl:;cloddo    //
//    ollooooc:;;,,lxodkxkdodxxxxxkkkddxkOOkkkkxkkxxxdddxxkkkkkxoldxddokX0OOOkkO0Oxx00dkK0kddxkoxkxOdoOXXXNWNKOkkO00OxdxxxxxkkkkOOOOO000OOOOkxxxxxxdddcclol:;:oollllcclodkOOOOO0K0kxkO0000kokK0OOk0Kdlookxk0kkkxkkOOkdoxdddxkxxdddddddoooxookkkkkdllokkkkkkkOkkxdoddddxxxxddddddddxxoloddxxxxdooxd:,,,,;;cl;,:cloo    //
//    dlloooocc::,;lxdoxkxkdodxddddxxkxddddxkOOkkkOOkkkkxxkkxdlloddxxddlkX0OOOkkk00kk0Ok00xdddkddOdcdXXKNWNKOkxO0OxxxxkxkkkkkOOOO00OOO0OkxxxddxkOOOOOOdclodc';odooodooodxkO000OkxooxO0KKK00xok00OkOK0oloxkx0OkkkkxOOkooxxxkxxddddddddddddloxkkkkkkkkkkkkkkkOkxdddxxddddooodddddxddxxooooddxxxxxooxxc,,,,,,cl;;cccc    //
//    dlcoooolccc::lxxodkxxkxdxxxxxxdddxxolloddxxxkkkkkxxolllooddddddxxdlxK0OkkkxkOOOOxx00xoookkdolkXXXWNKOkxk0OddxxxkkkkkOOOO00OOOOkkkxdxkO0OOOOOOkkkkxl:ldollodddoooddoooxkdodxkxkkkO00KK0kxxO0OOk00xooxxkKOkOkkxkkolxxxxddddxxdoloddddooxkkkkkkkkkkkkkxxddoodddxxdddddddxddddddxdodkxddxxxxxdoodxl,,''';lc;:llc    //
//    doloooollcllclxxdoxkkxxxxxxxdddddddddxdoooodddddddooddxxxddddddxxddod0KOkkkxxxxkkdkKkdlloOdckXKXWX0kxx0OxdxxxkkkkkO00O00OOkkkkddxk0K0OkxkkOOO00K0ko:;:clddddddddoooo:cdOOkkxxxxxkkkkO0K0kkxkOOOO0kodkxk0O000kxxxolodddxxdddodooodddodddxxxxkkxxxxdddddddddxxxxxxxxxxxxdxxdoddlooxxkxxxxkkxdlldxl,'..';l:,;cl    //
//    doloooolllllclxxkdldkkkxxxxxxxxxxdddxxddxdddxkxxxkkkkkkxxxdddddxddxxddk00OOOkxkkxddO0OdololxXKXWXOxxk0kdxxxkkkkkO00O00OkkOkxddxOKKOddk00OOOO00xdllodoccclllodddxxoldxdlodxxkkxxxxxxkkkO0K0OkxkOOOKKxxOkk0OkO00OkkxoooooodddddddoodxooddddddddddooddddxxxxxxkkkOOkkkkkkxdxxxoclddddxkxxxxxxddocdxl'...':l:,;:    //
//    xocloooollolclxxxxocddxxxxxxdxxxxxdxxxxxkxxxxxxxxxxxxxkkxdxdddddddddxdodO0OkkkkkkOkxkK0xl,lKXXWXOxdO0xoxxkkkkkk0K000OxkOOxxxxOKKOxl:d0OkO0KOxxxdlcoddxxxdollllccc;;lxxxxdoloodxkkxxxxkkkOK0OOxdOOO0XOxO0O00xx000Okkkxdoodxddddxdodddloddddxxxddddodxxxxkkkk                                                     //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract InTS is ERC721Creator {
    constructor() ERC721Creator("Inspiration_Tina_Singa", "InTS") {}
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