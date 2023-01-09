// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nouveau Nouveau
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    NWWWWWWNKkdx0XNNXXXXXXXXXKKKKKK0Okxxddddxxxxddddooollllcccccc:::::::;;;;;;;;;;;;;;,,;;::::::cccllooddxxxxxkOOKNNNNNNXNNNNWWWNNNNNXNNNNNNNNNXXXXXXXXNNN    //
//    WWWWWNNXOdclkKXXXXXXXKKKKKK0Okxddddxxxxdddooolllccc:::;;;;;;,,,,,,,,,,,,,,,,,,,,,,,'',,;;;;;:::::::cclloddxxxkO0KXXXNNNNNNNNNNNNNNWNXNNXXXXXXXKKXXXXNN    //
//    NNNNXXXXXKO0KXXXXXXKKKK0Okxddddddxdddooollccc:::;;;,,,,''''''''''''''.........''''''''',;;::::::;;;::::cloodddxxxkO00KNNNNNNXXNXXKXXNNNNNXXXKKKKKKXKKX    //
//    XNXXXXXXXXXXXXXXKKKK0Okxdddddddddoollcc:::;;;,,,''''....................................',;::::;;,;:::ccclloooddddddxkOKXNNNNX0kllx0KKKXNNXXXKKXXKKKKK    //
//    NXXXXXXXXXXXXKKKK0Okxdoddddddoollcc::;;;,,,'''...........................................',;;;;;;;;::ccclllooooolooddddxkKXXXX0xlldOKKXXXNNXXXXXKKKXXX    //
//    XXXXXXXXXXXKKKK0kxdoddddddoolcc::;;,,,'''..................                           ......',;;;;;:::cclllllollllccloddddk0KXXK0O0KKXXXXXXXXXXXXXKXXK    //
//    XKKXXXKKKKKK0Okdoodddddoolcc::;;,,'''..............                                        .....',,;;;;;:::::cccccccccclooodxO0XXXXXXKKXXXKXXXXXXXKKKK    //
//    KKKKKKKKKK0Oxdooddxxdoolcc:;;,,,''...........                                               .................''',;;:::::cloooodk0XXXXXK0KKKKXXKKKXXXKK    //
//    KKKKKKKK0Oxdoodxxxdoolcc::;,,,''''.......                      ..';::ccc::;,'.             ..... ....       .....'',,;;:::cllooodkOOkxk00KKKXXXKKXXXKK    //
//    KK000K0Oxdoodxxxxdollc::;;,,''''.'....                      .,cdxkkOOO0KKKKKKOxl,.         ..  ..   ..         ...'',,;;::cccclodooooloxO0KKKXXXKXXKXX    //
//    KKK000kdoodxkxxddollcc:;::;,,'',''..                 ..,,,,:dkkxdollodxO0KKKXXXXKkc.......  .. .     ..          ...',;;;:::cccloooodooodOKKKKXXKKKKXX    //
//    K000Odoodxkkxxddoollcccc::;,,,;:,..                'ldxkkkkkkkkxdoc::loxO0KXXXNNNNX0kkxoc;'.'''.       .          ....',,;;;::cccllooodddk0KXKKKKKKKKK    //
//    00Oxooodkkkxxddooooc:clc;,''''','...             .;xOkxxxxkkddxxolllccodk0KKXXNNNNNXX0kdl;'';ldo;.     .            ....',;;::::::cloddodxOKKXK00K00KK    //
//    0kdoodxkkxxxddooollc:;::,'''...''....       .,:looxkkkxxxxxxolddolloc:ldkOKKXXNNNNNXKOdl:,'';oxkkc.    ......         ...',;:::::ccclododdxOKKKKK0OkO0    //
//    xooodkkkxxddooolcccl:,,;;''....'....   ...'cx0000Okkkkxddxddoooooolc::coxO0KKXNNNNXK0ko:,,;coxO00kc..  .,.. ....        ...',;:cclloodddddddkKKKK0OkOK    //
//    oooxkkkxdddoollcc::c:;,;;,...'...    .:dkOOO00OOOkkkkkxddddoolccclc:;,;:oxO0KXNNNXXKOxl;,;cdO0KKK0xlc;;:,...   .        ......,;clodddxxxxdddk0XXXXXXX    //
//    ddxkkkxdddollcc:::;;:::;;;,'....   .;xO0000Okkkkkkkkxxxxxdoloxdlodl:,'';ok00KXNNXKKOko:,;cdk0KXXK0Oxolll.  .  .      ....'','..';:lodxxkkOkxddx0XXXXXN    //
//    dkOkkxddoollcc::;;;,,''''.......   .d0000OkkxxkkkkkOOkxddddoloodddl:,,,cdk0KKXXK000koc;;cokOKXXXK0Okxoll'          ....',,;;;,'.';:loxxkOOOkxddxOXXKXX    //
//    kOkkxdddolccc::;;,,,''......... ...,xK00OkkkdkOOxollldxxolododk0Oxol::coxO00KKX0xxkdl::ldk0KKXXXXK0Okxol:.        ....',;::cc::;;;::lodxkkO0OxddxOXXXX    //
//    OOkxxddolcc:::;;,,'''......''..,,;:lx00OOOkkkxdoc,'...;clxOxoodOOxooooodxkOO000Oo:lolldxO0KKXXXXXKK0Okxo:;,..       ..',;:cccllcccccclodxkO00Oxddx0XXX    //
//    Okkxddolcc::;;,,,''........,;;cdxkO0000OOOxddocc:,:c'.',;:odolodkxoc:::::ldxxkOOd,.,coxO0KKXXXXXXKK00Oxocc'.,. .     ..',;;::ccllllcccccoxkO00Oxddx0XX    //
//    kkxddolcc::;;,,,''.......';loxO0000000OO0Oxxdlcll:;;,;,':cokdlodkOkdoc:::codxkOOxc,..,coxO0KXXXXXXKK0Oxdlc::,.  .      .....'';:cclclooodxOO000OxddkKX    //
//    kxddolcc::;;,,,''.'''...,;lk000OkkkOOOOO00kOkxdxxdoclddollO0dloOXKOkdoolloddxkkdoc:;,.''';lkOOO0KK000Okdllxd.   ..           ..,;cloodxkkO000000kxddkK    //
//    xddolccc:;;,,,''..'','.,:oO00OkkkkkkkOOO00OOK0kdxkkkkxolxKXkolx0Oxxkkkxxxxxddl:;,'.........;oxk0KXXKKOOOxdl:'   ..           ..';:clodxxkOO00000Oxddxk    //
//    xdolccc:;;,;,,''.....';lok00OkkkkkkkkOOOO0OOOKK0Okkxxxk0KOdolx0kl:;;::cl:;,'....     ......,cxOKKXXK00Okxoc:,.               ....',;:cldxkkOO0000kdddd    //
//    doolcc:;;;,,,''......cxdx0OkkkkkkkkkkOOOkkkkkkOOO00000kxddodOKOo;,,''',,.......         ....,:dk00K000OOkxoc.                     ..';coddxkOO000Oxddd    //
//    oolcc::;;,,'''.......lolx0OkkkkkkOOOkkOOkxdoddxkxxkxxddxkO00Odc;,'''''.......'.           ...';lx0XXKK0Oxddl,                     ..',:lodxkkOO000kddd    //
//    ollc::;;,,,''.......'dl:kOkkkkkkkOOOOkOOkddddddxkkkkOO0KK0kdc;,'''.....';:::;'.           ....';cx0KK0Okkxol:.                 ....',;::clodxkkOO0Oxdd    //
//    olcc::;;,,''........'dl;x0kkkkkkxkOOOOOOOkxddddxkkkxxxxkxl:;,'..'..';lool;...              ....',:x0K0OOkxdo:.     ..  ..  ....'''',;;:::clodxkkOOOxdd    //
//    llc::;;,,'''.........lo;lOOOkkkxxxxkkkOOOOkkkxOOkddddolooc,''...';oxxo,.          ......'''''',,'.;kKK0kkxdo;      .'..,.  ...'''''''',;:lodxxkkOOOxdd    //
//    lcc:;;;,,''..........,o;,oO0OkxxkkkxkkOOOOOOO0K0Oxddddxkxo;',,,lk0Ol'         .,codkkOOOOOkxxddoc'.l0K0Okxdc.      ''.',.   ...''......';:lodxkkOOOkdd    //
//    lc::;;,,,''......... .,:,:ok0OkOOOkkkOOOOOO000Oxxxxddllolll;;d0XXOl'..       .'cxO0KKKKK0Okkxxxdo;.;OKK0kxo,        . ..     ......  ...,:clodxkkOOkdd    //
//    cc::;;,,'''.........   .',;ldk000OkkkO00000KOkxxddddl::c:;ckXWWX0Odc,..      .:xOKXXXK0OOOO000Okd:.'xKK0kxl.          .             ...';:codxkkkOOkdd    //
//    cc:;;;,,'''.........     .,;:dxkKKKKKKK000OOxxkdlooxo:;:oONWWNXKXX0kl,.     .;d0KXXK0OxoodxO0000Oo,.c0K0Oxl:'                        ..',;cloxxkkkOkdd    //
//    cc:;;;,,'''.........       .'',codkO00OOOkxxkkOxooddl:o0NMWKKKOxx00ko;.    ..:x0000kkkollcccooooxdc.,xK0kxkk:                          ..';clodxxkkkdd    //
//    cc:;;,,,'''.........          ...,;;lkkOOdl;:xxxkxodkKWWNKkooooooddoc,..   ..:dxxddlcc:;;,,,;::cloo:.cOOxxkd.                          ..,;cloddxkkxdd    //
//    c::;;;,,''''.........             .:lxkkOkdloxxdxO0XWNX0Oxocllloodo:,...  ...;coooc,,,;;;,,;:clllloo,,dK0kdc.                        ...,;:coodxxkkxdd    //
//    cc::;;,,,'''.........             ,k0kO0OOkkkOO0XNNKOxddoollclooodo;..... ..';:cll:,,,,;::cloooollodc'lKK0d;.                      ...',;:cloddxxkkxoo    //
//    cc::;;;,,''''.........            .lkxOKXXXXKKKXX0Oxdooollooooooxx:...... ..';::clc;;;;:cllodddooodxl,l00kl'                      ...',;:clooddxxkxdoo    //
//    cc:::;;,,,'''.........             ':lOXKKXXX0OOkxxdddxdllodddkkd:.........',::::clcccclllodddddxxkx::kOdl,                        ..';;:clloddxxxxddo    //
//    cc:::;;;,,,'''.........            ..;d0000XNXK0OOkxxxxxdxxkOOkl'.....'.....':c:;,;cooooooddxxxkOOkl:oOxl,                        ...',;:cloodxxxxxddo    //
//    dlc::;;;;,,''''.........            .':coxOKXNWWNXXKKK000K0Odl;..  ..',,...';lc:,...;ldxxkkkOOO0Okd:ckxl'                     .....',,;;::cloddxxxdddo    //
//    kdl:::;;;;,,,'''.........            .,;:ldOKXXXNNNNK0KKOdl,..;,.  .,cdxdddxkOkdc....';codxxkOOOkxl:kXKkc.                  ....'',;::::ccllooddxdoool    //
//    kdl::::;;;;,,,''''........            .';;cxOKKKKKKKOOOOx:...,;.   .ckKXK00KXNXKx,....',:cllodxxxo:oKNXXKo.                ....',;;;::ccllloooddddoooo    //
//    kkdl:::;;;;;,,,,'''........            .,:cdO0O00000OO00Okoc:c,.    .:cclk0KKKK0d.....',;:loodxxdl:xXXKKKd.              .....'',;;;::cccllooooodooooo    //
//    kkkdlllclc;,,,,,'''...........         .,,,:OXkxkOOOOO000OOxo;.         .,::ldo:'.....',;:codxxxo:cOXK0kl...               .....',;;:::::ccllooooooooo    //
//    kkkkxxxxxdoc;,,'''''............     . .';':ON0ddxkO00Okdoo:..          .....''.......',;clodxxdl:o0kc'.....                ......',;;;::cclloooooolll    //
//    kkkkkkkkkxxdc,,''''................  ....,;o0NXxlodxkOOxlc:'.        .'::;;;col:,'''',,;:coddddoc:kKx'  .''.               .....'',,;:::cccllloooooooo    //
//    kkkkkkkkkkxdc,,'''.......................':lkNW0ocloddoool:.....,,,;lx0KKKKXXXXKOdoooc:cllodddol:lKXO:   ,,             ......',,;::::cccllcccloolllll    //
//    kkkkkkkkkkkdc;,,'''......................;lo0NWNkccclollol;...':lcloddolloddddxkOOOxdolloodddol::OWNKx' .;;.          ....'',,;;::::ccclllllllllcc::cc    //
//    kkkkkkkkkkkxdlc:,'''.....................:ld0NNWNkc:clloo:,'........,;:::cllloxxxdlc:cloddddol:;xNWNX0c .,,.         ....',,;;;;::::ccllllllllllcccccc    //
//    kkkkkkkkkxddddol;''......................:ddkKNWWW0l:clolc;,,'.....',:oxkO0000OOkxdooodddddol:cONWNXKk;    ..      ....',,;;:::::ccccllllllllllllllooo    //
//    kkkkkkkkkxlc:::;,,'''..................,:cloodOXWWMNkl:lllc:;,''...'',,;;;;;:cclodddddxxddl:cxXWWNXKOd'     .    .....',,;;:::::cccccllllllllloooooooo    //
//    kkkkkkkkxxl:;;,,,,''''''..............,oc::cccoONWMMMXkolclc:;,'......       ..';:loddddlclxXWMWWNXKx;. .. .........'',,;;;;:::::::ccclllllllooooooooo    //
//    kkkkkkkxxxo:::cc:;,'',;::,............;olcc:cloONMMMMMWN0kdlcc:,'...          ..,:lodolldOXWMMMWWNX0l.   .. ......'',,;;::::::ccccccccccllllooooooooll    //
//    kkkkkkkkxxoccllolc;'.':cc;.............coodddxOXWMMMMMWNNWNKOxol:;,...........';codoodOXWNWWMMMWWNKl'.    ......'',,,;:::cccccccccccccccllooooooooolll    //
//    kkkkkkkkkxxolc;;;,'..',;:;'............':c,,dKNWWWWMMMWXXXNNWWNKOdlc::;;:clllcloddxkKWWWNNWMMMWWWNXd,.    .,.....',,;;::::cccccccccccllllooooooooooodd    //
//    kkkkkkkkkkkxxo;'''......................';''oXWWWMWWWMWXKKKKNNWWWNX0OxxdxxkkxxkO0KNWWWWNNNWMMMWWWNXKx,.  .'.....'',,;;;;;::::ccccccclllloooooooooodddd    //
//    kkkkkkkkkkkkxdl:,,''.....................,ok0KKXNWMWWMWKO000KXXNWWWWWWNXXXXXXNWWMMWWWWWNNNWMMWWNNXXKKkc......'',,,;;;;;;:::::cccccccllcclllooooloddddd    //
//    kkkkkkkkkkkkxxdoc;,,,'''................ckKOOkO0XNWMMMN0OOOOOO0KXXNNWWWWWWWMMMMMMWWWWNNNNNWMMWWNK00KKKOl'..'',,,,;;;:::::::cccccllloollcllooodoooooddo    //
//    kkkkkkkkkkkkxxxdolc::;;,,''............;kKK0OOO0KNWMMWXOOkkxxkkkO00XXNNWNNWWWWMWWWWWWNNNXNWMMMWNXKKKXXXO:'',,,,;;;;;::::::ccccllooooooolooooodoooooodo    //
//    kkkkkkkkkkkkxxxxxdoolc::::::;,'''',;;,';xKKKKKKKNWWWMN0OOkxxdddxxkkkO0KXXXNWWWWWWWWWWNNNXXNMMMMWWNNNNXXOc.,;;;:;;::::cccccccclooolllloooooooodddollddd    //
//    kkkkkkkkkkxkkxxxxxddoolcclllc;:c::clc:;;lOXNNNNWWMMMN0kkxxxddooooddoox000KNNWWWWWWWWWNNXXXXWMMMMWWWNNXKd,.;:;:ccccccccccclllllollooollooooodddddooodkO    //
//    xkkkkkkkkkxkkxkkxxxxdddoollccccllcclolc:o0XNWWWWWMMWKkkxxdddddocldolloddxOXNNWWWWWWWNNNXXXXNWMMMWWWNNX0xoc:;;clllllccllllloolloooooollooooddddoooxkO00    //
//    xxxxkkkkkkkkkkkxxxxxxxxdddoooooddollodxdxOKNNNWWWWN0kkxxddddddoc:llccclookKXXNWWWNWWNNNXXXXXNWMWWWWNNXXKK0kollooolllolloooooooooooooooooooddooddx0000O    //
//    OkkxxxxxxkkkkkkkxxxxxxxxxxxxxxxxxxdddxkOOKXNNNWWWXOkxxxdddoooool:::::cllld0XXNWNNNNNNNNNXXXXXNWMWWWNNNNNNXK0OxddoodddooodddoodooooooooooooooddxkKXXXXK    //
//    OOOkkxxxxxxkkkkkkkkxxkkkkkxxxkkxxxxxxkO0XNNNNWWN0kxxxxddooooolll:;:cclclcoOKKXNNNXNNNNNNXXXXXXXWWWWWWWNNNXXKKOkkxdddddddddddddddooodddolooxOkkk0XXKKKK    //
//    OOOOOkxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkO0XNNNWWNKOkxxddddoooollllc;;:ccllccoOK0KXXXXXNXXXXXXXXXXXXNWWMWWNNXXXXXK0OOkxdddodxkOkxdoodxkOOOOO00KKOk0KKKKKKK    //
//    OOOOOOkxxkkkkkkkkkkkkkkkkkkkkkkkkkkkOKXNNWWXKOOkxxddddolllllllccc::clcllcoOK0KKKKKKXXXXXXXXXXXXXXXNWWWNNNNNNNXX000OkxkkO0000OxdkO000000000K0OOKKKKKKKK    //
//    OOOOOOkkxxkkkkkkkkkkkkkkkkkkkkkkkkOO0XNWNX0Okkxdddddddllllccllccclc:ccclloOK0000000KXXXXXXXXXXXXXXXXXNNNNNWWNXXK00000O00000Okk000000OOkkkOOkO0KKKK00KK    //
//    OOOkOOOkxxkkkkkkkkkkkkkkkkkkkOOOOOO0KXK0Okxxxddddooooollllcc::ccclc;:clllokK00000O0XXKKK0KKKXXXXKKKKXKXXNNWWNNXXXKKKK00000OkOKKKK0OkkOOO0000O0KK000KKK    //
//    kkOOOOOkxkOOOOkkkkOOOOkkkkkkOOOOOOOOkkkxxdxddddddllooololllccccllc:,:cllcok000K00K0KK0OOOOOO0KXXXXXXXKXXXXXXNXNNNNNXXKKKK0O0KKKKOkk0KKKKKKK000KKKK000K    //
//    OOOOOOkkkkOOOOOkkkkOOOOOkkkOOOOkkxxdddddddddoollloolllllloollllc::ccccllcoO000K00OOOOOkOOxdxk0KKXXXXXXXXXXKKKKXXXXNNXXXXK00KKK0OO00KKKKKK00K00KKKKKK00    //
//    kOOOOOkkkkOOOOOOkOkkOOOOOkkkxddddolclllllloollc:;;::cllcccccccc::cccccloloO000K0OO000OOkdoxOO0KKKKKKXXXXXKKKKKKKKKKXXXXXXKKKK0O000OKKKKKKK0KK00KKKKK0O    //
//    kkOOOkkOkkOOOOOkkOOkkOOOOkxollol:;;clclooooolc:;;:;,';:ccc:;cllcc:;:ccloloO000K0OO0KK000xdO000KKKXKKKKXXXKKKKKKK0KXXKKKXXXXXKKK0KKO0KKKKKK0KKK00KKK0O0    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NouNou is ERC721Creator {
    constructor() ERC721Creator("Nouveau Nouveau", "NouNou") {}
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