// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CyberAlhaji X Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//      ..                ..                            ..  .........;c:,....    ..      ............,::;;;,,'.....;;'..',,'.,;;;;,...,..  ..........';:,...''.,:,....',,'.'',;cc;;;;;;;;::c::::::::cccccc::,',,,'..'''',''.........................         .....................................................    //
//        ..               ...                                ........;c:,....    .......  ...........,;;;;,''......::'..,;;,;:c:;,,..,,..............,:;..',,',:,...'',,..'',;clc:;;;;;;;::::::::::cc:;;;:;'......''.'''''........................         ............................    ......................    //
//         ..                ..                     .            .....':c:,.....   ......   ...........,;;:;,''.....':;..';;;::cc:;;,.';.........'.....;;..',,';:;'.',,,;,'',;:clc::;;;;;;::;;:::::cc::;;:c;......''..',,,'''''''.................. ..  .............................      ...... ................    //
//           ..               ..                    .             ....',:c;,'....   .......  .........',,,;;,'''.....','..,;;;:cclc:;,,c:;;;,,'..''...''''..''';:;,,,;;;;;,,;;::cclllllc::::;;;;;;:llllllll;'...','....'''''',,''................. ... ...............'...........       ...... ..................    //
//             ..               ..                 ..               ...',::;,'.....  ......  .......',,:c;,,;;'.'........',;;;:ccllc:::loc:;;;;,,,;,..''''.'',;::;;,;;:::;;;;::::cllllc::::::;;;::lcloooolc,'.',,,''''''''',,,,,''.......'''....         ..........''............     .......  ...................    //
//      .       ..               ...             ...                 ...',;;;,,'....................;;,;ll;,;;'.........'',;::::cclccc::ooc:;;;::;;,..''','',;:cc::::cc::;;;;:::cclodoolc:;;;;::lolc:coolc;,;;;;;,,,,,,,,,,,;;;;;,,,,''',;,'...          ........'............      .......  .....................    //
//     ....       ..              ...         ....                   .....'',;;;'........'''.......'::;;:ol:,,,'..'',::;;;;;::;:ccccccc:cl;''''''''......',,;;:ccccccccc::::::;:cclooooc;;;;::cdxolccccc:,...,;;;;;;;,,,,,;;;;;,,;;;,,,,;;,...           ..................       ....... ........................    //
//      ....       ..           . ...                                  ....'.',::,........'''......''',::col;,;;,,;:cclc::cc::::ccccccc::ol;,''''........',;;:cllccccccc::cc::;:ccloolc::::ccldxxxdoc:::'......';::;,',,,,,,,,,,,,,,,,,;;'......         ..   ............      ..................................    //
//        ....       ......       ...                                   .......,;;,..........'.........,:ccol,',:::::ccc:cccccccclllcccc:coc;,,''''''....',:clooolccccccc:cc::;;::cllccccclldxkkxdoc;:c:;,,,'..,;:;,'',,,,,,;;;;;;,,;;;,'......        ..    ... .......      ...............''.........''........    //
//          ...       ......     ...                                      ......',;;'.........''........,ccloc,';c;;,,;;:ccllcc:cclllcccccloccc::::cc::;'';:clooolc:::clc:clllooolllccc::ccokOOkdll::cc;,;;;,'',;;,,,;;,;;;;,,,;,,,;;;,.......       ...         .....      ................''''.....''''.........    //
//    ..      ..     ..............                                        ....'..';;'','................,ccloc,':;,,,,;::ccccccccllllc:::clolllc::::::;'';cloddolc:;:llc:clc:ccccccc:::::ldkkxollc:cc;;;;:;,,,,,,;::;;,,;;,,,;,,,;;;'........      ..           ...      ..............'''',;:;'..'''''..........    //
//    .....    ...   ...   .......                                      ..   ......';;,','................,:ccc:'';;,,;:;;:cllcccodolccc::clollolc::;;;;'';cloddolc::clolccc:;:::::cccclllodddolllccc,,::::;;;;;;:::::;;;;,,,,,,,,;,'.........     ..           ...    ...............',,,;;:cc:,''''''........'''    //
//    .......    ...  ....  ..  .. .......                                ..  .....',,,,,,''..  ........''.';;;;,.';;;,;:::clllcccoddxkoccclooloooooooolc::lodxddlc::ccllclc:;;;;;:::::ccloddoooollc;,:c:;;;;;:::::::::;;,,,,''',,'..........    ..          ....   ........'.......',;;;::cccc:;;;,,,,'..''''''''    //
//    ..........  ...   ...     ............                                .  .....',,',,,''... .......''''',;;;,,;;;:cc:::cllcc::ldxkdlc::cloooooodxkxxxxxkkkxdolccccllllc:::;;::ccccccldddooooll;;:c:;,,;;::;:cc:;;;,,,,''''''...... ....    ..          ..... ........'.......',;::::clllcccllc;,,,'''''''''''    //
//    ............. ..           .............                       ...     .   ....','',,'..... ........'';;:::;;;;:cdkdcc:cccclodoodddlc::dOxlllcllooooxOOOkkxdollccclolc:cc:;::ccllooxkxdooool:;:c;,',;;;;::ccc:::;,,,'..'''...... .....  ...         ......................';;::::clllccclll:,',,''''',,,;;,,    //
//    ..................          ..............                       ...    ..  .....',',,'.....  ......',,,,,,,,,;:cxK0dc::::lodxxoxkkkxllkKKd::ccllloldkOOOkxdddoooooolclooollcclodddkkxdddol:;:c;,',;;;;;:ccllcc:;,,'..'''................          ... .................';:::ccclllcccclc:,',,,'''',;:::cl:'    //
//    ....................            .... .......                 ...  ....   ...  ....'''''''.....,oc'...';:;;,,,;;:cox0Oolc:::clkkddkkOkooOKX0c;:cllclldkOkxddddooooooolccllloollloodkOkxdddoc;:lc,',;:,,;;:ccllc;,''....''.........  .....  ..      ....................';:;;::ccllcccllc:;;::;,'''',;:ccccl:.    //
//    ......................          .....  .......                ........... ...   ....''.','.....d0o....:xkxo;,,;;cclldololccccokdcdkxxolkXX0o:loolccdO00Oxdxxxxxxxxxxxoc::clddodddxkkxxxddl:;cl:;;:;,',;::ccc:;,'.....'.':,.....    ...   ...       ..................,;:;;;:::::ccccc:;:clc;,''',;::cllccl:.    //
//    ........................  .     .......  ......                   ......... ..   ........'.....'kk' ..'lk0Oo:;;;;:cccclolccc:cxxlodooooOXXXKOkOOdlcdO00Okxkkkxxxxkxxxdl::cloddxxkOOkkxxdoc:col::c:,,,,;:ccc:,'.....'....,.....    ..   ...        ..................,;,;;::::;::cc:;;:cc:;'''',;:ccllllccc:.    //
//    ...........................          .... .......                    .......      ..............;l. ...':dOkc;;;;;:ccloooolcodxxooolldk0KKKK00KKOxxkOOOOOkkkkxkkkkkkxdlccclloddxkOOOkxddddddxoloo:;;;::cc:;,......'.....  ....  ... ....         ...'..................',,;:;::::;;;cc:,'''',;::clllcccc::,.    //
//    ...............,,'........          ..  .   ......                    ......   ..   ....'.........   .,'';dko;;,',,;clloxxkkOOkOxoood0XXXK0Oxdk00000OOOOOOOOOkkxxkOOkollllodoodkOOOOkxxxkkxxdoool:;;::::;,'.....''............... ....   ..    .............  ............',;;;;,;cl:;'''',;;:cclccc:::;;,'.    //
//    ...............',,,.. ....       .........    ......                     ........    .....'.','....  .cddodxxoc;',',:lllxO00000KKOOOOKXXKKKKK000OO0OOOOOOOOOOOkxxxO0kdoddddoddkOOOOkxxkkkkkxdooc:;;::;;,'.....''''''',::'...... ....  ....   .......  ....       ...........;:,'',;;,'.',;;;:ccc:::;;;;;;,'.    //
//    ................''''......    ................. ......                     ......     ':,'::..,;;oxc. ..'cddooolllcccloook0000K00000000OO0KKKKK0OOOOOOOOOOO0OOOOOO0KOxxddolloxOOOOOkkkkkkxddddoc:;;;;,,'....',''',',;,'......       ..'..   .......  ...     ..  ..........',,,,'''''',;;,,;;::;;;;;;;;;;,'.    //
//    ....................'................ ..  .......    ...                    .....     .'cccol,.'cx00x;....lxkkxdxxolllodxO00K0000000000000OOO00KKKKKKK0000K00OOO00KKK00kxxxxxOOOOOO00OOkxddolc:;;;;;,,''.''',,,''.','.......      ..,'..   ...........         ................'''''',,,',,;;;,,,,,,;;;;,,,'    //
//    ...............',,;,'''...........'...      .......     .. ...          ....  .....     .:llodl,':dO0Ol'...;oxkkkOkolldkO0000000KKK0000000O0KXXXXXNXXXXXXXKKKKKKKKKKKKKOxkOOOO00000K00Okxdolcc:;;,;;,'''',,,,''..''........    ...,;'.    .....  ...         ................''...',,''',,;,,,,,,,,;;,'',,,'    //
//    ...............',;;;,;;,.........''..        .......     .  ....        .............   ..:loodxl,;oxOOxc'..,lxO000OxodkOO0KKKKKKK00000000000KKXXXXXXXXXXXXXXKKKKXKKKK0OOOO00KKXKKKK00Okxdolc:;;;:c:,,,;;,,,'..''.......... ..',;;,..   .......           ..................'''''',,'''',,,,,,,;;;;;,'..','.    //
//    ...............';:;;;;;,........'''..  ..  ...........        ....       ...'''........  ..;loddkdc:cdkOkd;',cxO00KKKOxxkO0KKKKKKKKKKKKKKKKKKKK0OOOkkkkkkO00KKKKKKKKK00OO00KKXXXXKK00OOOOkxxolc;:c:;;:::;,,'................';;;'..   .........        .....  ........,'.'''''','''''',,,,,,,,,,,,,,'...'''.    //
//    ...............';::;;;;,............  ... ........'....         ....      ...':::lc;''......,:xkxkxl;:okOOxl;,:xO0KKKKOkkO0KKKKKKKKKKKKXXK0kxollloddddddoodoooodddkO0K00000KXXXXXXK0000OkkOkxoc:;;;:clc:;'..........';,..',;:;,.    ..........    .......         ...,;,''..'''''''',,:l:,,,,,,''''......'..    //
//    ...............,;::;;,;:............. .... ... ...........        ....     ..,ldlcddl:;,'...,:ck0KX0xccd000kxdllk00KXXX0OOKKKKKKKKXXXXK0xlcccoxkO0KXXXXXKK0Okdol:::ldk0KKKKKXXXXXXK000OkkOkxoc:;:cclcc:;'.........''';;,;::;'.   .................';;,..        ...'......'''''''''';c:lo:,,,,,'''..........    //
//    ..''...........,:c:;,',:,'''.................  .........''..         ....   ..;od;';:col,...'lxx0XNNX0xdk0K0O00Oxk0XXXXXK00KKKXKXXNXKkl::lxO0KKKK0000000000Okxdoc:;,;cxKXXXXXXXXXXKKK0kkOkkxollclooooc,'''......',,'';c:;,'.   ................;cool;;,.     ....'......'',,'''''',;coc::;,,,,,,'''''.......    //
//    ..,;;,.........';c:,,..,,,;,..................................         ..... ..,ll,..';c;....cO0O0XNNNX0OOKKKKKK0kx0XNXXXXKKKXXXXNXOo;;cdkkkxxdxxxxxdddxxxxxdolc:;;,'';o0XXXXNNNNXXXKOOOOkkxdxxxdddoc;,,'.....,;;,,;cc:'....................';lol:'. .,.  .....'......''',,,,,,;:cclodo:,',;;,,,''''........    //
//    ..';;;;,''.'...';c:,,...';:;'...............................','..        ..'....'::'...''....;dO0KKXXXNXK0OO0XKKKK00XXXXXXXXXXXXXXx:,,,:ddoc::cccc:;,,,,;:ccccc:;''....,ckKXXNNNNNXKK0OOkkxdxkxxdol:;;,'.''';ccc:;cc:,....''.................','.. . .;............''',,,,:lc:cooloddolc:;;;;;,'''..........    //
//    ..';;::::,''...';l:,,,'.';:;'.................................',;,..       ..''..';;'.'''...':dO00KXXXXK0OOOkKXKKKK0O0KXKKKKXXXXKd,'..',;;;;;;;,;:lllllcc::;,',,,,'......;xKNNNNNNNXK0OOOkxxkxdol:::;,'''',cllc:cc;.....';,..................   .... .'...''..':,''',,;;;;;;;;::;;clcclllc:,,;;'''..........    //
//    ..;:::cdd:''...';c:,,c;.';:;'..............''...............''..',,'..       .',,,;:;,'''....';lxO00KXXXXXK0OKXKKKKKOkk00KXXXXXKx,....'''''..';lkKNNXKK0kolc,.............:kXNNNNXXKK000Okxxdolcccclc,'....,:ccc:'...'''...,'............       ..   .'..,:c;'''',,,;;;;,,;;;;;;;:cccodollc:;;,'''..........    //
//    ..:c:cldkc'....';c:,,:;'';c;'..............'.................'''....',,..     ..,:::;;;,,'..''..,cxO00KXXK0KXXK0000000OkO0KKXXXO:.........':loox0KKK0OOkl;,,,',;,..  ......cOXNNNXXKK0000Oxdlclooddl;.....,,:cc'...';,......';'.......               .,,,:lc;,',,,;;;;;;;;;;;:;;:cc:;;:oolcc;,,,,''.........    //
//    ..;:clloxc'...',;lc,,;,'';c;...............''.................''''''..,;;,'... ...,:::;,,,'''.....'cdk00K0O0KK0OO0KXNXXK00KKXXKo..........collccooodllol::c:,',,....   ....'lONNNXXXK00OOkdlodxxdo:'....,,:cc,..';,'......,'',...........        .....,,':c:;;,,;;;;;;;;;;;:cc:;,,,'''',;c:;;,,,,,,,,.......    //
//    ..;clolloc'...';:ll;,;,'';c;...............'..................'',;;;;,,;:::;;'.....';:;;;;,'','...',,:okO00Oxk0OOKNNNNNNNNXXXXKo....,,....:l:;:;;clc:;;,':ol,.....'.. .,'.,'.xNNNNXNXKOkkkkkOOxooc;'..,,;cl;'..';;.................,;ccc:,.. .........,'.;:,,;;;;;;;;::;;:::;,;;;;:cc;,,,ll;,,;;,,,,'.......    //
//    ..;codllo:''..';clc;;;:,,;c;.....................''...'.....'''':oddo:;clc;,,;:,'..',;;;::,,;:c;',:c:,,:ldxOkxkOO0XXXNNNNNXKKXKo;;:::ll,..':;'''.','.....,:c'.....'.. .;oc;'.dNWNNNNNXXKKXKKKOxlc:'.';:cc;',:;''...............';codollodoc,'........',''::,',,,,,;:loc,,:cccccodxk0Oxl,,lo:,;;;::;;'.......    //
//    ..;codlld:'...';cdc,,;:;;:c;...............''.....''''''''....'',:oxd:;:llc;;cdc,'''',,,'''',,,,',::cc;,,;codxddkKXXXXNNNNXXKKKd,,co;cl,....'''...........';'.......  .,c;;'.dNWWWWWWNNK0OkkO0x:co:;;cc:,,,,'''''...... ....,:odddoooollc;'....',,'...'..,,:cc;',,;;;,,;cllcccokkkkkOkl;;cl;,;;:cc:;,.......    //
//    ..;cclcldc'...';coc;;;;;;;::'..............''...'''''''''''''''.'',:ccclc;loc:ccll:;,'',;,''''',;;;;:;,,,;looddxOXXKKXXXNNXXXKKd...,.',.......',,,.........,'........ .......xNWWWWNWNNK0OkxOOo;:ol::::::,,;;;,..    ...':ldxxxdoddol:,'....';::c:;'..'..,:llc:;;;,;;:codddddxxdooxO0xc;;cl:,,;:;;;;,.......    //
//    .';ccc:ldc'...';cl:::;;;;,;:'..............,,'..'',,,'''''''',,,,'';clllccoocclcldoc:;,,;;,,,,,,,;;;,,,,;cdOK000KXKKXXXXNNXNNK0l..............'cc,....    ....... .'.........oXWWNNNNXXKK0Ok0xc:loc::::::;:;'....  ...'cxkkdlloolc;,''...,;:c::;;;,...'.';,'',,'''',:c:clllxxlcclllk0xc;;:l:,,;;;;;;;'......    //
//    '':ccc:ld:'...';::;cl:;;;,,:'..............''......''',,;;;,',,;;,,;clccccolclc:oxdlcllc;,,,;;;;,,,,,,,;:lox0KXXXXXXXXK0O0XNNNXl............;,,;'....       ..... ......  ..;kXNNNNNXOk0KOkdxdc:cooooc::::;;'....  ....,clc::::,''....';::;,,',;::,'..'.';,'',,;;'',;c:;:oxkdcccodddxxl:;:dl,,;;;;:c:,......    //
//    ',:cc:;cdc'....,;;;loc::;,,;'..............''....''''''',::;:cc:;;;;cc:cclllcccldxddoodoolllc:::;;;;;;;;;cokkO0XXNXXXKk:c0NNNNKc............c:'......         ..        ....'dKNNNNXK0kOkddodko:cool:::cllc;......      ....''......'',,,''''',,,,,'',;,,:,,,,,;;:clddc;:olcloloxkkddkd:;cxo,,;;;::::,......    //
//    ,;:cc::lxc'....,,,;lo:::;,;;,..............''...'',,''''',,,;cllc:;;cc:cc:cocclodxkkkkkxdooxOxoc:;;;;;;;;;cddxOXXNXXXXk:,oOKNNk;..,,.;;...........  .                  .;,..',dXNNNXK00kdoxxxOdccoolloooc;'.....      ...........';;,,'''',,'',',,,;cc:,cdl:,'',,cxxdl;,;;;;cloxkOOxodxdooxo',;;;;;;;,......    //
//    ;:ccc:coxc'....',,:ll;,;,',;,...............'..';:;;;;;;;,,,,,,;;::::c::::coolodk00OOO00Okk0KK0x:;;::;;;;;;cloOXNNNNNNXOlclkXXx;;..''':c:,.        .                .';:,..,;;ckNNNXK00kdododOxloxdddolc;,,,'..........''.....'',:ll;''''''',,,,,,,:::;;oxl;''';:;ldl;',;;;;coxkOkxxxxOxc:oo,,;;;;;;;'......    //
//    ;coc::coxc.....',;:::;,,,',;,...............'..,:::;;:cc:;;;;,,,;;::cl::::cloolcldkOOOO00000K00kc;;::::::c:lxkOXNNNNNNNNKo,:dkd,'. ....';:::;,...             ..',;;;;'.... .,;oXNNXXK0kddddoxO0Okxoodolccc:'...'''''',:;,'..,:c:;:::,,'''',,,,,,,;;;::;cl;''',cl:ldo:,,;:loxkO000OO0Okl;;lo,,;;;;;;,.......    //
//    :loc::cod:.....'';cc:;;;;,,;,...............'..;:::;,;:::;;;;;;;,,;;:c;;;:cdxdoooooxkkkkk0KKXKKkc;;loc;::clxK00KXNNNNNNNN0l;,'....  .......';:::;;;;;;;;;;;,,,;;;;,'......  ..cONNNXXK0OkkkxdxkOO0Oxdxdocclc;;,,'..'',;::,'.',:cc:;;;;,,,'',,;;::cccclc:;:,;;;;;;;lolc::lxkO0000OOOOkxxl;;lo;,;:;;;;,.......    //
//    :lo:;;cod:......';locc::;,,;,...............'..,;:;,,,,,;:c:;,;;;;;:cc::;;cdkkkkxxxdddxdxkO0KKKklc::c::::clx0KKKKKXXNNNNNNXKx:....      ..','......',,,,,,''.......','.     .oKNNNNNXXNNXKKK0OOO0KKOkxxl;;:,''...',;;;;;,',,,,,;:c:;,,,,,,,;:clllolllcc:;;:::;;;;;:ccloxxkkOOkddolcc:lxo::lo;;::::::,.,'....    //
//    ;cl;;;cod:......',odcc::;,;;,..................','.',;;;cloolcc:::::;::c:::lddxxdddooooloooddddoc:;;;:::ccoxk0XK0OO0XNNNXXX0xc.....       .,:lollc:'.'''''.';::cclol;.     .lOKXNNNWWWNNNXXXK0000KKkxxdc::c:,..',;;;;;;:;;,,,,,,,;::;;;;:::cccc::::;;;::;;;;;;;;:::c:codooolc:cllldkllko::ll:;::::::,.,'....    //
//    ;::ll::odc'.....';ldlc::;,,;'..................''..,:c;,:llcccc:::::::;;;;;:;::::::::::::;;;;,,;;;;;::ccccoxOKX0OOO0KXXXKKOd;.,,. .   ....  ..:oxxl::c:ccc::oxxxxxl'..  .. .ckKXNNNNNNNNNXXXK0000KX0kko:;;;;,,;::cc:::::;,''''',,;;:;;;::::;;;;;;;;;;;::;;:                                                     //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CFN is ERC1155Creator {
    constructor() ERC1155Creator("CyberAlhaji X Editions", "CFN") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xE9FF7CA11280553Af56d04Ecb8Be6B8c4468DCB2;
        (bool success, ) = 0xE9FF7CA11280553Af56d04Ecb8Be6B8c4468DCB2.delegatecall(abi.encodeWithSignature("initialize(string,string)", name, symbol));
        require(success, "Initialization failed");
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

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
 * ```solidity
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
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
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

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
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

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}