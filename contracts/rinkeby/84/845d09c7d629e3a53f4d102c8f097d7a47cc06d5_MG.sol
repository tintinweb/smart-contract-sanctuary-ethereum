// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Maige
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''',,'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''',:dko:,''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''l0000Od,'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''':k000000o,''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''cxkO00Oxkl''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''cxxO000O0x;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''':xO0000O0kc'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''',o0OOOOOOOo,''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''ckOOOOOO0x;''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''';xOOOOO00k:''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''',dO0OOOO0k:''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''';dOOOOOO0x;''''''''''''''',,;:;;:;;;,,'''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''lkOOOOOOOo,''''''''',,;:ldxkOOkkOkOOxxdol:,''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''',ckOOOOOOOo;'''''''',:dkkk000000OOOO000OO00Oxlc,'''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''';okOOOOOOOd;''''''''cdk0KKKK0OkK0O0000000OO0OO0Od:,'''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''':x00OOOOOOd;''''''',l0KO0XK000OO0000000K0OO0000O00Od;''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''',cOK00000OOx:''''''';x0OKKKXOOKO00OKOO0K0000O0000O0000x:'''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''cO000000OOkc''''''';d0KO0KKN0OK0O000koodx000O0000O0O000x;''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''';x0O000K00Oo,'''''',o0K00000X00000OOo;''';:ok0OO00O00O0OOo,'''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''':k00000000k:'''''',oO0000000N0000Kkc,''''''':xOO0000OO000x:'''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''':k0O00O00Oxc''''',lO0OO000K0X000KOc'''''''''':x000OO000OOkc'''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''';x00O00O00Okl:;:cxOO00O0OOKKK000Oc''''''''''',o00O0000OOOOo,''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''oOOO00O0000OOOkkOOOOOO0OOO0XKOOc'''''''''''',o00OOOO00O00o,''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''';dOO0OOO0OOO0OOOOO0OOO0OO00KKx:''''''''''''';x00OOOO00O0Ol'''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''';xOOOOO00OO0OOOOO000000O0OOd;''''''''''''',oO00000O0000Ol'''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''';okO00OOO0OOOO0O000O00Oxc;,''''''''''''',ck000000O0000kc'''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''',:dO0OOOO0O0O000000Oxc,''''''''''''''',ck0O00000O0O00x;'''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''',:odkOOO0000OOxdo;''''''''''''''''',lO000O00000O00Oc''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''',;ccclllc:;;''''''''''''''''''';dO000K0000000OOd;''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',lk0OO000O0000000k:'''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',ckO0000O0O00O0000kc''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';lxO00000000000000Ox:'''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''',,,,,,,;;::;:lllxk0K0000000O000O00kl,''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''',;:ccldllxooxodxdxkxxxdxOkOOk0OkO0K00K0K0KK0K00K0000Od:''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''';lxkO000KKXK0KK0O0X000O00OK00K0KK00OKK0K0K00K0000000kd:''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''',ldOKK00KK0000000KK0KK000KK00KK0K000OK0KK0K0KK00000K0ko:''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''';cxXK0KK0K0O000K000KK0KK00KK0K0KK000K0k0KKK00KK000000ko:''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''';okK0000K000000K00000O0K0K00K00K0KXK0KK0K00K0000K00KOdc,''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''';ok0XKK0O00000O000K000KO0K000KO0K000KK00KKK000KK00Okdl:'''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''',lx0X0K0KKO000KO0K0K00K0K00K0K0K00K0K00K000KXOkOkdoc;,''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''';o0K0K0KKO0000000K0KK0K000KX00XOOOkkxdxdoolccl:;;,'''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''';xK0XKOK00K00000K0K0000KO0kddoll:;;,,,''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''';x00K0K00000K0000KKK0Oxdlc:;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''',o000000K00K000K0K0KOdc,''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''':kK0000000000OKKKK0k:'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''o0000000K0O0K00K00k:''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''l0000000000KKK00KOl,''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''',cO00000O000KKK000x;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''':k00000000000O000o''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''',d00000OO0OOOOO00o''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''lO00000000O00000x;'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''';xO0000OO00000000d:''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''cO00000000O00OO00ko;''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''',oOK0O0O00O00O0000Okdl:,,'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''';d00O0000000000000OO0Oxdol::;,'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''',o0O00O00O000000O0000OO00Okkxoolllc::;,,''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''',lk0OO00OOOO0O0O0000O0OOO00000000OkOkkkdxdlccccc;;;,'''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''';lxOOOOOOOO0000000O000000O000K00OOKO0K0K0kO000OkOxdxoclc;;,''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''';coxO0OO0000O000OK00000OO0O0KOO000O000K000000000000000kkxodl:;,''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''',:lddOOO0O0000000K0O0O00O0K0K0O0000000000000O0KO0O0KO000KOOkdlc;''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''',::coodkkk000K000O000OKKO00O00O0K0O0000OO00000O0KO000K000K0kxl:,''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''',;;cccooldxxkkkkOOkO0O0KOO00O00K0O0000000K000O00000000OOxl:,'''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''',,,;,;;;;:::cc:collddxkk00O00000000O00000000000Odc;'''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',,;cloO00000O000K000000OO0000xc,'''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';lxO0O000K0K00000OO0000kOxc,'''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',:co000KK0O0000000KO0000kl,''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''':k0OK00KO0000O00000000d,'''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',:xK0KKO00000000000000d,''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',lO0000K0K00K0000000kl,'''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''cO00K00K000KK000K00k:'''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''o000K00K00KK00KKK00o'''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''cOK000K00K0K00X0000x,''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''':O0KKK00X0KK0KK0K0KO;''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''':OKKK0XK0X0KXO0000KO:''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''lKK0X0KK0K00K0K00000c''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''':kKK0K00X0KK0K0K000KO:''''''''''''''    //
//    '''''''''''''''''''''''''''''''':llodoolll:;;,''''''''''''''''''''''''''''''''''''';xK00KKKOK0OK00K0XKO0x,''''''''''''''    //
//    ''''''''''''''''''''''''''''';lxO000000000OkOxdo;,''''''''''''''''''''''''''''''',ck0000KOKK0K000O0KX00O:'''''''''''''''    //
//    ''''''''''''''''''''''''''':lO0KK0O0000O00OO0000kdl:,'''''''''''''''''''''''',,:oxOK00K000000O000000000o''''''''''''''''    //
//    ''''''''''''''''''''''''',lO0K0K0OK0000000000K0O0O00kol::;,,'''''''',;;;cooodkkOX00KO000O0KO00O00KO00Od,''''''''''''''''    //
//    '''''''''''''''''''''''';dOOO00K000K0OO0000OOK0O0K00KKK00kkkkddxddkxxOOO0K0K0O00K00K000O000K00O00OK00x,'''''''''''''''''    //
//    ''''''''''''''''''''''''l0000000000K00000000O0000000K0K00K0KN0OXX0KK0O0K0K0K00X00K0XK0KO0K0K000000KKd;''''''''''''''''''    //
//    ''''''''''''''''''''''',d00O000000K0OdolloldxO000O00000K00K00K00XK0K0OKK0KXKK0KK0K00K00KO0K0K0000K0d;'''''''''''''''''''    //
//    ''''''''''''''''''''''''lO0000O0000d:,'''''',;coxk00000000KKO0K0KX00XK0K0KX0KK0X00K00K0O0O0KOK000kl,''''''''''''''''''''    //
//    '''''''''''''''''''''''':k00000KK0k:'''''''''''',;ldk00000KXKKK0OXK0X0OKK0K00K00K00KOOX0K0OKKKKkd;''''''''''''''''''''''    //
//    '''''''''''''''''''''''',lOK0000O0Oo,''''''''''''''';codO00XNKOKX0000KK000OKK0K0KK0KK0K0KK0KOkd;''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''',o0000O0000ko:,'''''''''''''''';::oxxxk00KK0XXKK00OK00K00XK00000kxo:,''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''';d000O0000K0Oxlc;,'''''''''''''''''',,:clcokxdkOOxOOkkkOxxkoclc,''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''';dO0O00O0KOOO00kdolc:,'''''''''''''''''''''',,,;;;;,,;,,,''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''',:xOOOOKXOO000OOK000xxdlcc;,''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''';cxO0000000000K0000K0000kkdooc;:;,''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''',:ok00000000000000000000000O0Okxooc;,'''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''',:ox000000000000K0000000OkO0K000Okol;''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''',:loxxO00K0OO0KO0O0000K0O0O00000KOxl;,''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''',;ccldoodxkkkOO00O0000O00000000Oxc,''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''';;;cloxxxOO0000000000000xc,''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',,;cdxk000O0000000Oo;'''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';cdkO000000000x:''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';lxO00000000k:'''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',lxO0O0O000x:''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';oOO0000OOd;'''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''lk000000Ol,''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''ck0O000Kd;''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''ck0OO00d;''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',d00000o,''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''lO00Kx;'''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',oO00Ol''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''':k0Okl'''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';dO0kc,'''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',;x0Okl'''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',lkO0Oc''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',o000Ol,''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''lO00Od;'''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',d000k:''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',oO00d,''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',d0Od,''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';lkk:''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',lkx:,'''''',;,'''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''':lxdlc:clooc,'''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';coxxkxo:,''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',,,,'''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''       //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MG is ERC721Creator {
    constructor() ERC721Creator("Maige", "MG") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x80d39537860Dc3677E9345706697bf4dF6527f72;
        Address.functionDelegateCall(
            0x80d39537860Dc3677E9345706697bf4dF6527f72,
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