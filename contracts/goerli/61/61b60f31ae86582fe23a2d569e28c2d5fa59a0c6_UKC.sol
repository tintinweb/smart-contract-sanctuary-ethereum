// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UnknCollection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//                                          ..,,',:llooooc;...........'col;,''..;okOxc';ooc::::::::::::::::ccc:::cdO0KKKKKKKKKKKKKKXXKKKKKKKKKKKKKKKKKKKKKK000000000000000000OOOOkxxdll:,,'....,;cllllc:;;,;:::;,,,''.............................',;:ldxkkkkkkOOO0000Odc:;::codxxxkxollldkOkoc;'....',:cl:;'.....    //
//                                          ..,'..':looool:'..........'cddc;,,'..:xOOo;;ooc:::::::::::ccc:cclc::ccdk0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00KKKKKK0K0K0Okxdolc:;;,..,coxk0OOkdlc::::;;,,'........................................',;coxkkOOO00K0Odl:::cldxxxxxdolodxkkxoc;,....',;::;'......    //
//                                         ...,'...,cloool:'..........'cdxdc;,'..,oOOxlcooc:::::::::::ccccccc::cccodk0KKKKKKKKKKKKKKKKKKKXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKXK0kdlllc::;,.';codoollc::::::;,'.....''......................................'...',coxOO00K0Odl:coxxkOOOkxddxOK0Okdlc:,.......''........    //
//                                          ..,,.. .,clool:'..........'cdkko:,'..'lkOOxddoc:::::::::::clllc::::ccccldk0KKKKKKKKKKKKKKKKKXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKXKkolc::::;,.........,;:c::;''''''''.................;cooloooollc:;'............'.....',cdkOkxoc:;codxkOKKKOkxxO0K0kdlc:,'................    //
//                                          ..,,..  .,cool:'..........'cdkkxl;,..'lxOOOkxoc:ccc:::::::cldoc:::cclccclx0KKKKXXXXXXXKKKKXXXXXXXXXXXXKKKKKKKKKKKKKKKKK00OO0Odolc::::;,.......',:c::;'.''''......',;;::;;,'''...,:ldxkkxxkOOOOOkdl:'...........'.....,:oddlccccccox0KXXXKOkO000kxoc:,'................    //
//                                          ..,,... ..,cll:'..........'cdkkkdc,..,ldkO00kdc::ccc:::::::clcc:::clllcclx0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK0OOOOOkkOkxddlclc:c:,.. ...';:c:;,'.''........lodxkxo:;,''''''',,;;;;;;,ck0OOOOOOOko:'..........'''...':ldoooolodk0KKXNNXKKKKOkdoc:,'................    //
//                                          ..,,.......,cl:'..........'cdkOOkd:..,lddxO0Odc::looc:::::::::::ccclolccok0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0kxxxxkkkxxkxolloolccll:'. ..';:::;'..''...      ,xkxdl:,,,,,'''........,;::lk00OOOOOOOOOxo;..........'''...':loollodxkO0KXNNXKKK0kdol:;'................    //
//                                          ..,,........,::'..........'cdkOOOxl,.'lolok0Odc::cllc:::::::::::::coolccok0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKOkxxxkkkOkxoddl:;:lxxollc'....;::;,,''...         .lxl:;;;,,,,''.......'cdkOOO00000OOOOOOOOkkxoc,.........'''...,:lllldxxxkOKXXKKK00kdolc;'.............  .    //
//                                          ..,,.........,;'..........':dxkOOOd:',lo:;okOdc:::::::::::cc::::::codoccok0XXXXXXXXXXXXXXXXXXXXXXXXXXXXX0xddxkkkkkkkxdoxxc;::coool:'...,::;,,''...    .......co:;;;;;;,'....   ...';coddxxxO000OOOOOkxdollllc,.........''...';llodxkkOOKKKKKK0Okdoc:,............    .    //
//                                          ..,,'........,,'..........':oodkOOko:;lo;':dkdl::::::::ccccc::::::codoccok0XXXXXXNNNXXXXXXXXXXXXXXXXXKOdoloxkkkkxxxddlokd::ccccccl'..';:;,',,..     ......':oo:;;;;,''..        ....';;,,,,:ldO00OOOxoc:::;;:c:,........',....;lloxkOO00KKKKK0Oxoc;'............    ..    //
//                                         ...,;,........,;'..........':lccdkOOxocoo:.'lxxoolc:::::ccccc::::::codoccokKXXNXNNNNNNNNNXXXXXXXXXXX0kolllodkkkkxxxdoolldoccccccclc'.,:;,''',..    .....,;cloc:;;;,''..     ..........:dddoc;;lO000OOdl:::::;;;::;'.......,,'...,clloddoodxkkkkxdc,'...........    ....    //
//    .                                    ...;:;'.......,;'..........':l;':dOOkxddd:..:ddoolc::::ccc:cclcc:::codoccokKXNNNNNNNNNNNNNNNNNXXXK0kdlllodxxxkkxxddoolccccccccllc::c:;,,'.''.    ....':loddl:,,,,'....    .............;x000OO000000Odlc:::::;;;;c:,.......,,'...,clc::;;:coodol:,...........    ......    //
//                                        ....;cc;'......,;'..........':l;.'cxOOkxkxc'.;oollllc::::c:::coocc::codoccokKXNNNNNNNNNNNNNNNNNNX0Okxooooxxkxxxxxddoolc:c::ccldl:;;:;;;;,'...    ....;cccooc:;,,,'....  ...............',coxdodk00000Oxlc:::::::::;:c:'......,,....,:c;;;;;clolc;'..........    .......'    //
//                                        ....;clc:,.....,;'..........':l:..'lkOkkkOd;';ooccolcc::::::ccclllcclodoccokKXNNNNNNNNNNNNNNNNXK0Okxooooddooddoooolllc::cc::clc;;;;;;;;;;;'.    ...':::cc:;;,,',,'...  ..........','',,',;;:;'':x0000Oxlcc::cccc:::::c:'......,,....'::;,;;:::;,...........   ........':    //
//                   .                   .....;clol:,....,;'..........':oc'..,okkkOOkl,;ooc:cccccc::cllccclllclddolcokKXNNNNNNNNNNNNNNNXK0kdolllclcclooc:cllllc:;:c:;:c;,,:c;;:ll:::'    ..';:;:oc;;,,,,'''...   ...';;'...''''....;oxdlccclx00Oxocccccclc::::;:c;'......','...':;'''',''..........   ........;cll    //
//                  ....                  ....;cooolc,...,;'..........':oc,...;oxkO0Oxccooc:::ccccccclllccloolldxolcokKXNNNNNNNNNNNNNNX0Oxocccc::::::::::cccccc:::;;;;;,,;:;;::cc;,'.  ..';;;;::;,''''''.....    .',''............',cdxkO0kc;lxkxocccccccc::::;,,:;.......,,'...,:,..............   ........':dxol    //
//                  ....                  ....;coooooc,..,;'..........':oc,''..:dxk00OdodocccccccccccclolclodoodxdllokKXNNNNNNNNNNNNNX0xoc:::::;;,,,,,;:::::::;;:;,,,;;,,;;;;::;,'.  .',,;;;,,,,,'..'......  ..'....................'',;ck0d;;ckxocccccccc:::;,'';:,......',,....,:'............  ........';:clcco    //
//                  .....                  ...;coodddoc;,,;'..........'coc;,,'.'cdk000Oxxoccccllcccccclllcclllodxdllok0XNNNNNNNNNNNNN0xl:;;;;;;,''''',,,,,,;;,,;;,,,;,,,,,ll;;,..   .''',,'..,,'''......    ..,,'.     .........'''',:lcdO00OO0Oxocccccccc::;,''.';:'......,;'....;;.....................';;::,,:o    //
//    .             ..'....                ...;cooddddolc:;'..........'col;,,,'.,lxO000OkocccccccccllllccccccloxxdlcldOKNNNNNNNNNNNN0xc,,,,,,,''''''''''''''''',,,,,,',,,,:c:,.    .'''''..............     ....    ..'..''.....'..',;clc;:ckKKOxoccccccc::;,''''',:;......',,....,;'....................',;;;,,;l    //
//                  ..''....              ....;cooodddddol:'..........,cdo:;;;,..;dO0000OdccllccccloolllccccccldxolcldOKNNNNNNNNNNNXkl;....'''''''''''........''',,,'',,',;;'.    ..''..'',;:cccc:;,...   ....    ..'''.............',,cl:,ckKKOxlc:::::;;;,,'''''';:'......';,....;;.............',,....',;:;;:cl    //
//                  ..........            ....;cloodddxxdo:'..........'cxxl::;,..,oxk000OdccccccccccccclcccccclodoccldkKXNNNNNNNNNNKdc;....''''''''''.........''',;;,,::,;,.     ...';coddooooolloll:;,...........'....    .........':dk0Oxx0KKOxl:;;;;;;;,,,,''''',:;'.....',,'...,;'..........,:oxl'...',:;;clcc    //
//                  ............           ...,:cloodddxdoc,..........,cxkdoc;,'.,lddk00Odlccccccccccccccccccclodocclox0XNNNNNNNNNXOlc:...'''',,,,,,'..........''',,,,:;;,.    ...,codolcc::cccccc::;;;;,'.........       ..'''....',;cloxo;cx0Oxl:;;;;;;;,,,,,,,,,,:c,...''',;,...';,.......',cokOOd,...';;,cdd:;    //
//                  ..............         ...,;,;cloddddoc,..........,lxkkxo:,'.;oolok0OxlccccccclccccccccccclodolclldkKXNNNNNNNNXd::;..''',,;:cc:;,''.........'',,;;;;,.    ..,colc:::::;,coocc:;;;::;,,''.....     .....''........',;:dd::d0Oxl:;;;;;;;,,,,,,,,,,;c;'..''',:,'..';;.....';ldkO00Od'....'':dkd:;    //
//                  ...............        ...,,..,clodddoc,..........,lxOOOxo;'.;oo::dOOxlccccclodlccccccccccloooccllox0XNNNNNNNNKocl,..'',;cldxdlc:;,'''.......,;,;;;;.    .':c:;;:;;;clllokxdkkdl:,',,'''.. ...  ...'''....  .....;dOO0K00KKOdl::;;;;;;;;,,,,,,'',::'..''',:;'..';:'..':dkO000KK0d'...',,cdkdc;    //
//                  ............'...       ...,,...':loddoc,..........,lxOOOOxl,';oo;':xOxlcccccllolcccccccccclodoccloodOKNNNNNNNN0ddo,,,,,;;:clolccc:;,,,'.......'',,'.    .,c;'';,,;okxl:;,,',,::cc:l:'''..............    ...''...;kKKKKKKK0kdc::;;;;;;;;;,,,,,''':c,''',,;:;'...,:,':oOXK0KXXXK0d,..,:c:codl;:    //
//                  ..................    ....,,'....;coooc,..........,cxOOOOOxl;:oo:',lxxlccccllllccclcccccccloollloxxxOKNNNNNNNNOxxc'........'',,,;;,,''.........','.    .,:,.'''':xOo,...'''..'''',:;'.........'''......''.'''..,;:oxOKKKKK0koc::;;;;;;;;;;,,,,''';c;''',,;c:'...,:clOKNNXKKXNNX0d,..,ldo:::;,:    //
//                  ....  .............   ....,,'.....,cllc'..........,cxkOO00Oxoloo:''cdxlcccloddllloollccllllooolclddxOKNNNNNNNXOd:.  ...........................''.  ...';'.','.':l;..,::::;,,,''''..'...............''.....'',,:c:,,oKKKKK0koc::::;;;;;::;;,,'''',c:'''',,:c,.'''cxOKXNWNXXNNXK0d,..:xxl,'''';    //
//                  ....    ............. ....,,'......':cc,..........,cdxkOO00Oxxxd:'':ddlcllllooollddolllllllooollllodOKNNNNNNNXOl'. ..    ........................  ..',;'.',,,,;,'.':c:;,,,,''''.''.......................,'.',lkxclkKXKKK0xlc:::::;;;;::;,,''''',::'.'',,:c,''''ckOO0KXNNWWNK00d,.'okd:...',;    //
//                  ....     .................,,'........;:,..........,cddoxOO0Okkkxc'':ddllllllloddlllloolllllooollllodOKNNNNNNNNKd;.  ...   .............',,,'.....  ..','..''''',,..;;,,''',,'''..''....''...............''...':xOOOO0KXKK0kdc:::cc::;;;;;;,,''''',::'.'',,:c,''''cxxkO0KNWWWNK0Oo,.'okd:'',;,;    //
//                  ....       ...............,,'...'....,;'..........,cdl:cxOOOkkOOo;':dxollllllloolllllllllllooollllodOKNNNNNNNNNKl.    ..';;;........',:::;,'....   ...'.....'..''..'','''''''..'..'.........................'cxxxxo:lOKKOxoc:::::::::;;;;,,,''''',:c,.'',,:c;''''cxkO0KXNWWWNK0Oo,.'cddc;;;,',    //
//                  .....        .............,,'...''...,;'..........,cdl,,cdkOkkO0ko:cdxolllllloolllllllooollooolllodxOKNNNNNNNNNNd.    .,,,'........,:llc:;,'''..   ........',,.......''.'''''............................,,';lox00d;cOK0koc::;;:cloooolc;,,,,,,,,,:c,'',,,:c;''''lk0KKKXNWWWNXK0d,..;c:;;;,'',    //
//                  .......      ...... ......,;;,,,;;;,;:c:;,,,,,,'..,col,'':oxkkO00OdoxdollllllllllllllloooloooolloddxOXNNNNNNNNNXo.   ..'.     ...';:llc;,'.';c:'.   ........','.........................................:ko;;clodxdoxKKOxlc::::lk0KXXKOd:,,,,,,,,,:c,'',,,:c;''',o0XX0OKNWWWNXXKx,..';;;;,'..'    //
//                  ..'....      .......  ...':oxkkkkkkkkOOOkkkkkkxl,.,cdl;,'';ldxO000OkxdollloddolllllllllllloodolllodxOXNNNNNNNNN0c......'.   ....,;:::;'.....',...     .........................'''...''....... ..   ...lOKOollk0xclkKKKOxlc::::oOXNWWNKxc,,,,,,,,,:c,',;;,;c;''';dKKOxk0XWWWNXXKx,..;odol:'..'    //
//                  ..'''...     ....... ....'ckKXXXXXXXXXXXXXXXXX0d;',cdl:;,'.,cdk00000OxolllooooooddollooolloodolllooxOXNNNNNNNNXkc;'.''.'........',;,,'...    . .'..   ...........'..............'............      ..,o0KKkl:;o00d;dKK0Odl:::::d0NWWWNKxc;,,',,,,,:c,,,;,';:;''';kK0OO0KNWWWNNXXk,..:dxoc,...'    //
//                  .........    ......  ....'ckKXXXXXXXXXNNNNNNXXKx:',ldl;;;,'.,cxO00K0OxolllooooodddoooooooooddooloooxOXNNNNNNNKxl:,,',',;'';,''.........         ....   .....................................      ..:d0KK0dxkdk00xlxK0Okoc:::::d0NWWWNKxc;,,',,,,,::,',,,',;;''':OXK000KXNWWNNXXk;.'coclc,...'    //
//                  ...........  ......  ....'ckKXXXKXXXXXXXXXXXXX0x;',ldl;,;;,'.;oxkO0K0xoooooooooooooooooooooddooooooxOXNNWWNNKdl:;,,,;;:;',:;'.....          .'....',.   ....................................    ...ck0K0KOox00O0Ol:dOOkdlc:::;:d0NWWWNKxc;,,,,,,;:c:,,,,,'';;'',l0NXK000KNWWWNNXk;.'loldxc'..'    //
//                  .....  ............ .....'ck0KXXXXXXXXXKXXXXXX0d;',ldl:;;;,'';ododk00xoooooooooooooooooooooddooooodxOKNNWNN0dlc:;,,,;::,'','....            ........'.   ................................'.    ...:dO0000OodOOOOOkxkOkxdlc::;;:o0XNWNX0xc,,,,,;:cll:,,,,,'';,'';dXNNX00KXNNWWWNXx,..:llool;,''    //
//    .             ..'........'.............'cx0KKKKKKKKKKKKKXXXKOo;.,ldo:::;,'';oo:;lkOkdoooooooooooollloooooddoooooodkKNNNXOdl::;;,',;;;,'......           ............     ..''''......................'..     ..':dO0000kodOOOOOOOOkxxolc::;;;lxO000Oko:,,,,;coddo:,,,,,',;,'':ONNNK0KXNNNWWWNXx,..,;;:::;,''    //
//    ;'.           ..'.........''...........'cx00KKKKKKKKXXXXXXKKOo,.,ldolcc:;'';oo:',lkxdooooooooodolccclooooddoooooodkKNNKxlc;;:::,'.';;''....            ..............      ...........................     . ..,lxk0000klcxOOOOOOkkxdolc::;;;;:cccccc:;,,,,;coddo:,,,,,',,'',oKNXKKXNNNNNWWWNXx,..',,;,,'...    //
//    :;,.          ..'...........''.........':oxkkkkOOOOO0000OOkkdc,.,lxxdol:;'':od:''cdxooooooooooooc:;:cloooddoooooodOKNNKo'.........',,'.....        .................. ....     . ..................        ....;cok0OOOOOxxOOOOOOkkxdolc::;;;;;,,;;;;;,,,,,;clool;,,,,,,,,'';kXX00KNNXXXNWWNNXk;..';;;,''...    //
//    ,''..         ..''......'.....'........';:;;;;:;;;:clc::;;;;;,..,lxkkkxo:,':odc,':ddlcccc:::::::;;,,:coooddoooooodOKNNWXxc,.    ..,,,'....        ........ ...   ........        ..............           ....';;lk0OOOOOOOOOOOOOOkxdolc::;;;;;,,,;;;;,,,,,;coddl;,,;,,,,'''c0NX00XXXXXNNNWNNXk;..,c:,'''...    //
//    ,''..         ...''......''.....'......',,'..''....,;'..........,lxOOOOko:,:ddc,,cdo:;,,,,;;,,,,,,,,;:oddddoooooodOKNNWWWNX0l....,,,,'....      .........  ..    ... ...          ...........             ....';:lx00000OOOOOOOOOOkxdoc:::;;;;;;;;;;;;;;,;;:ldxdc,,;,,,,''';dXWXKKXNXNNWNNNNNXx,..,c:,'.....    //
//    cc;'.  ...................,,'..........',;'''''....;;'..........,lxOO000kdlldxl,,cdo:,,,,,;;;,,,,,,,,:oxddooooooodOKNWWWWWNW0:.',,,,,'.....  .. ........   .     ..               ...........            .....';;;oO0000000OOOOOOOkxdlc:::;;;;;;;;;;;;;;::cloodl;,,;,,,,'',cONNXKXNNWWNNNNXXXOo,..';,'.....'    //
//    xkkc.......................,,,'.........,;,''''....;;'..........,lxOOO000kddkkd:,cdo:;,,,,,,,;;;;,,,,;ldddooooooodOKNNWWWWNNOc;;,'''.................      ....     ..            ...........          ........;;.;kK0000000OOOkkkkdolcc:::;;;;;;;;;;;;::clooooc;,,,,,,''',oKNX00XNWNNXXXKKKOd:'.........'''    //
//    oxxc............,:;'...'''..''..    ....';:;;,'....;;'.........';lxOOO000OkkO0Odcldo:;,,,,,,,;;;;,,',,coddooodxddxOXNNWNNWWO;''''....................    .......  ..              ...........          ........,;.,ok000000OOkkxxxxdolccccc:::;;;;;;;;;;::loddo:,,,,,,,'',:kXKOxOXNNXK0KKXX0dc;......'''''',    //
//    ccc;............:ool:,...'''.....   .....;ccc:;,...;;'..........;lxkOOO00OkkO00Oxddl:,,,,,,,,,,,,,,,,,:oddoodxOOxxOXNWWNNNW0:.         .....  ...... ...  ...... .'.              ...........    ..    .. ......;.':cxK000OOkxxddxkkxdlcccccc::;;;;;;;;;;cldddl;,,,,,,'',:xKXKOx0NNNK00KKKOdc;'...''''',;cox    //
//    ccc;............:dxxxdoc,................,coooc:,.';;'..........,lxxkOOOOOkkO000Okxl;,;;,,,,,,,,,,,,,,:lddolodxxxxOKNWWNNWWWXkc'.     ..  ...   ..... ...........,;.             ............  ......  .. ......''.;;cOK00OxddoodOKXX0dccldxxxol:;;;;;:;:clodo:,,,,,''',;o0XXK0OKNNX0OOkxoc,'...'''';:lxOKXK    //
//    ;::,...........'cxkO000KOd:'..............;ldxdl:;;:;'..........,ldddxkOOkkkO00000ko:;;;;;;;,,,,,,,,,,;codollloodxOXNNWNNNNWN0o,..  .....      ..  . ............,.              ....................   .  ......,..;cxK0kxdoooodk000koccd0KXX0xc;;;;::;:clooc;,,,''''',lk0XXKOO0NNKkoc:,'...''',;cdkKXXNWWX    //
//    ;;;'...........'lkOKXKXNNX0xc,.............;ldxdolcc:'..........,lol:cdkkkxkO00000ko:;;;;;;;;,,,,,,,,,;:looolloodxOXNNWNNWNNNO;..     .          ........... .'..                 ...........................',..;;..cdxOkooooddxxxddocccok000koc::::::::ccll:,',''''',:dk0XN0xxkkxl;''....',:loxO0KXNWWWWWX    //
//    lc:'...........'lOKXX00KXNNXKko:'...''......;cdxxdlc:,..........,loc'';cdddxO00000ko:;;;;;;;;;;,,;;::;;:coollodddxOXNWWWWWWWWNKOl'.         ..  ................                   ...........................'...,,.;dooxdooodxkkxollcccccccccccccccc::::c                                                     //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract UKC is ERC721Creator {
    constructor() ERC721Creator("UnknCollection", "UKC") {}
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