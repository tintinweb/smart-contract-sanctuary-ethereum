// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: z1z
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00KKKKKKKKKKKKKKKKKKKKKKKKKKKXKKKXKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00OOkkkkkkOOOO0000K0000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0Okxdolcc:;,,''''',,,;;::cllodxkO00000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0kxoc:;'..'',;;:cc,,:ccccc::;;,'..'',:codkO000000KK00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXKKKKKXKKKKKKKKKKKKKKKKKKKKKK0kdl:,''''':lloxxkkkOkc:xOkOOOOOkkxo;;lc:;'..,;coxO0000000KKK0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKK0Oxo:,.';:loxo;oOkOOOOOOOOl:xOOOOOOOOOOx;lOkOkxdl:;'.';cdk0K0000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKOdl;'';:ldkkOOOkcckO00OO00O0o;xOO00000OO0d;oOOOOOOOOko;,;'.,cok00K00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKK0kl;'',,:xOOOkkOOO0o:d0O0000000d:dOO00000000o;dOOOOOOOOOo;lxdl;'.,cdO000KKKKKKKK0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKXKKKKKKKKKKKKKKKKKKKOdc,.,:oko;oOOOOOO000k:cOO00000OOd;lkkkkOOOO00l:xOOOOOOOOOc;xOOOkdc,'';ok0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKK00d:'';lxkOOkc:xOO00OO00Ol;oolllllllc,;llllllllll;,lxkO000O0x:lOOOOOOkxo:'.,lk0KK0KK0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKK0d:'';okOOOOOOx:lOOOOOxoll:,:lodxxkOOx:lOOOOOOkkkd;;lllllldxOo:xOOOOOOOOkl;;,.,lk0K00K00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKKKK0x:''';xOOOOOOOOOo:oxollcodkkccOOOOOOO0k:ckOOOOOOO0k:lkOOkxollc,;dkO00OOOOd;lkd:'.,oO00KK0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKK0Oo,',ldcckOOOOOOOOo;,codkOOOOOl:xOOOOO00OcckOO0OOO00x:oOOOOOOOOo,:ccoxOO00k:ckkkkd:'.:x0000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKK00k:''cxOOxclkOOOOxocll:oOOOOOOOOx:oOOO0O00OlckOOO00000d;dOOOOOOOkc:xkdocclxOl;xOOOkOkl,.,lO00KKKKKKK0KKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKK0d,',okOOO0x:lkkoccoxOOo:dOOOOOO0Occxdoollll:,clllllllo:,okOOOOO0x;okkOOOxlc:;oOOOOOOOkd;.':k00KKKKKK0KKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKK0l,':dkOOOOO0x::ccdkOOO0OcckOOOkdoo:,cllooddxl:oxxdxxddo;,ccllodkOl:xOkOOOOOd;,cdOOOOOOko;;'.:x000000KKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKOl'',lOOOOOOOOd:,ckOOOOOOOd:lolllloxd:lOkkkkkOo:dOkkOOOOkcckkxdlccc,:xOOOOOOOc:ddccdOOOOo;okl'.;x000000KKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKXKKKKKKOl'':oclkOOOOxc:dd:lkOOOOOko:,:oxkOOOkl:xOkkkkOd:oOkkkkkOk:ckkkkkkkc,:ccdkOOOo;oOOko:lkOo:okOOo'.;x000000KKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKK0l,':xOxccxOOo:lkkOd:oOOkxlclo:ckOOkkOOd:dOkkkkOd:lkkkkkkOx:lkkkkkkxc:xxoc:cxx:ckOkOOkc:c:oOOOOOo,.;x000KKKK0KKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKd,.:xOkOklcoc:dkkOkkd:odccoxkOd:okkkOkOx:lkkxxxxo;:odddxxxo;lxxxkxko;lxxkkdl:,;xOOOOOkkc.:kOkOOOkl'.:k00KKKK00KKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKk:.;dOOOOOOo';xkkkkOOkl,;okkkkkkl:dkkkxxd:,::;,,,''''''',,;,,:clodxxc:dxxxxxxl,;cdkkkOOo;c:ckOOOkko,.'lO0000K000KKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKXKKK0l''lOOOOOOx:::cxkkOOkl:::okkkkkkx:cdoc;,''.''..','.',;,;;'.....',;::,cxxxxxxo;ldl:cdkko;oOx:ckOkko::;.,x00000KKK000KKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKK0Kx;.,:dkOOOx:ckxc:dkkd:cxxl:dkkkxxd:'''..........,:'.';;;::,.....'.....,:lodxo::dxxo::ol;okkOx:cxxc:dkl'.cO0000KKK000KKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKK0l''ldccxOkc:xkkkl:oo:lkkxxl:okdc;,..............';'.';;;;,'.............',:l:;lxdxxxl,,oxkkkkd:;:cxkOx;.,x0000KKK000KKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKk:.;xOko:lc:dOkkkko,,okkkxxxl;:;..................,'..'',''.................'':odddxxc,,cxxkkkx:'ckkkOkc.'lO00000KK00KKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKd,'cOOOOxc'ckOkkkkl;:cdxxxxdc'.''.'........'..................................';loddc;lo;cxkkx:;::dOkkOo,.:k000000000KKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKK0o''oOOOOkc;:cxkkkl;oxl:oxdo;''''..........'oc...................................':oc;ldxo;lko;cxd;lkkkkl,.,x000000000KKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKK0l',dOkkOx;lkl:lxd;lxxxl:lc,''''............;dc....................................',cddxxc;::lxkx::xkdc:,.,d000000000KKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKOc'':oxOOl;dOkxc:;:xxxxxl,''''''''..........'cxc....................................'coddxo,,lxxxxl;lc:lxc.'d0000000000KKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKOc',ooclxc:xOkkkl';dxxxd:'''''''''...........:do:;...................................,cddl:;,lxxxxo;,cdkk:.,d0000000000KKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKK0l',dOxoc,:kOkkkl:c:cdd:'''''''''............'c:,c;...................................,c:;lo;:xxxo:':xkkx:.,d0000000000KKKKKKKKKKKKK    //
//    XXXXXXXXXXXKKKKKKK0o',oOOkx:,cdkOx::xdc::'''.....................::;c,...................................';ldd:;do::l;cxkkx;.,x0O00000000KKKKKKKKKKKKK    //
//    XXXXXXXXKKKKKKKKKKKd,'lOkOkccoccod;cxddl,..'......................;::c'..................................':oddc,::cdd::xkxl,.;k0O000000000KKKKKKKKKKKK    //
//    XXXXXXXXKKKKKKKKKKKk:':xOkkc:xkdl:'cxddc'..........................;clc'..................................,ldo:':dxxd;cdl:,''cO0O000000000KKKKKKKKKKKK    //
//    XXXXXXXXXXXKKKKKKKK0l',:loxl:xkkko,,cod:............................;dx:..................................'cc:,,oxdxo,,:cl:.,oOOO0000000000KKKKKKKKKKK    //
//    XXXXXXXXXXXXKKKKXK0Kx;':olc:;okkkx:;c::,.....,;,'....................;xx;..........................'',,'..',;c:;oxdo:,cdxo,.:xOO00000000000KKKKKKKKKKK    //
//    XXXXXXXXXXXXKKKKKKKK0l,,oOkd;;ldxkc;oo:'....';:::,,,,,,,,,,,,,,,,;,,;;cxd:;:cclc;..................,;;:,..';lo;:ooc;,:dkd:.'oOO000000000000KKKKKKKKKKK    //
//    XXXXXXXXXXXXKKKXKKKKKk:':xOOo;clclc;cxdc;:::codoolcccccccllllllooooooolldxdooddd:..................,,;:,..':oc,;::lc;lxxl'.ckOO0O00000000KKKKKKKKKKKKK    //
//    XXXXXXXXXXXXKKKKKKKKK0d,,ckOkcckxoc,;odc,,',';c:;;,,,,,'''''''''........:kkd:'.....................',,,'..'cl;,:ldd;:doc,.;dOOO000000000KKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKOl,,:ldo:lkkko;,:,................................'lkkx:............................',,'cdodc,;:;'.,oOOOOO0000000KKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXKKKKKKK00Ol,';ll:;oxkxc;::'.................................'';:'...........................,;,:ool:,;cl;',lkOOOO00000000KKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXKKKKKKKK00Ol',lxdc;:lloc;l:................................................................':;;cc:,'cdo:''lkOOOOO00000000KKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXKKKKKKKKK00kl,'cxxl;:lc:,,c;..............................................................';,';;:;,cdo;',lkOOOOO000000000KKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXKKKKKKKKK00Oo;':dxl:cxdl:,,..............................................................',,;clc;:lc,.,okOOOOOO00000000KKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXKKKKKKK000Od:',;c:';oxxl,''............................................................':lll,';;''':dOOOOOO0000000000KKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXKKKKKKK000Okl,';cl:;;:cc;,..........................................................',:cc;,;c:,',lkOOOOO00000000000KKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXKKKKKKKKK00OOd:',:do:,;::;'........................................................',;;,';lo:'':dkkOOOO00000000000KKK0KKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXKKKKKKK000000ko;',colc:ldoc;'....................................................';:;;;cl:,';okOOOO0000000000000KKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXXKKKKKKKK00000Oko;',:oo::lddl:'..............................................',;cc:;:cl:'.;lxOOOOO00000000000000KKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXXKKKKKKKK0000000Oko:'':llcccldoc,......................',,,'...............';ccc:;:::;'';lxkOOOOO0000000000000KKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXXKKKKKKKKK0000000OOOdc;',:lc::ccll:,'.................,;;;,,............',:cc:;:::;,',:oxkOOOOOO00000000000KKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXXKKKKKKKKKKK00000000OOkdc,',:ccccccccc;,'.............',,,,,'.......',;::;:::;;;'',:lxkkOOOO00000000000000KKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKK00000000OOOOkdc;,',::;::c:::;;;,,''.......'',,'..'',,,,;;::;;;;,'',:lxkOOOOOO000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKK000000000OOOOOkdoc;,',;;;;;::::::;;,,,','..',,,;;;::;,,,;,,'',:ldxkkOOOOOO00000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKK00KK00000000OOOOOOkxolc;,'',,;;,,,,,,;;;,''',,,,,,,,,''',:cldxkkkOOOO00000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXKXXKKKKKKKKKKKKKKKKKKK0000000000OOOOOOOOOkxdlcc:;;,,''''''...''',,;:clodxxkkkkkOOOOOO0000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKK00000000000000000000OOOOOOOOOkkxxddddo:,:ddxxkkOOOOOOOOOOOOOOO00000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKK00000000000000000000000000OOOOOOOOOkkkl'ckkOOOOOOOOOOOOOOOOOO00000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKK000000000000000000000000000000OOOOOOOOl,ckOOOOOOOOOOOOOOOOOOO00000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKK00000000000000000000000000000OOOOOOkkkOl'cxOkkkOOOOOOOOOOOOOOOOO00000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKK00000000000000000000000000000OOOOOOOkxdxc,:odxkkkkkkkkOOOOOOOOOOOOO000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKK0000000000000000000000000000OOOOkxol:;,;'.';;,;:ldxxkkkkkOOOOOOOOOO0000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKK00000000000000000000000000OOOOkxl;,;:ccc;',:cc:;,,;ldxxkkkkkkOOOOOOO0000000000KK000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKK000000000000000000000000OOOOOkl,,:ol:;''....'';:cc,';lxxkkkkkkOOOOOOO00000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKXXKKKKKKKKKKKKKKKK0000000000000000000000OOOOx:';ol;'............':lc,'cdkkkkkkOOOOOOOO0000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKK0000000000000000000OOOOOOkc.;ol,................,ll''lxkkkkkOOOOOOO00000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKK00000000000000000OOOOOOOOx,.ld;..................;o:.,dkkkkkOOOOOO000000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKK00000000000000000OO00OOOOd''oo'..................,ol.'okkkOOOOOOO000000000000000KKKKK0KKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKK0000000000000000000000OOOOx,.ld,..................;oc.,dkkkOOOOOO0000000000000000KKKKK0KKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKK000000000000000000000000OOOOkc.,ol,................'lo,.ckkOkOOOOO00000000000000000000KK0KKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKK0000000000000000O0000000000OOOk:.,oo;'.............;oo,.;xOkOOOOO000000000000000000000KKK0KKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKK000000000000000000000000000OOOOkl'':llc;'......';:lo:''cxOOOOOOO0000000000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKK000000000000000000000000000000OOOxl,',:cllccccllcc;',:dkOOOOOO0000000000000KKK000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKK0000000000000000000000000000000OO0Oxoc;,',,,,,,',;coxOOOOOO0000000000000000KKK000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXKKKKKKKKKKKK000KK000000000000000000000000000000000OOO0OkxdollllloxkOOOO0OOO00000000000000000KKK000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract z1z is ERC721Creator {
    constructor() ERC721Creator("z1z", "z1z") {}
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