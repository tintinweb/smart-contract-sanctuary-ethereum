// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Skulls & Stones Physical Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//    00OOO0OOO00OO000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkOOkkkOOOkkOOOkkOOkkkkkdc:lxOkkkOOOkk    //
//    0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkOkOOOOOkkkOOOOkkkkkOOkkkkkkkxlc,.  .lOkOOkkkkO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkOOkkkOOOOOOOOOkkkkkOOkkkkkkkxl,.       'dOkOkkkOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOOOOOOOOOOOkkkkkkkkkOOOOOkkkkkkOkkkkkOko:.           'dOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkOOOOOOOkOOOOOOOOOOOkkkkOOkkOOOOOkkkOkkkkkkkkkd:'               .okOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkOOOOOkkkkOkkOkkOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkko,.                  .cxOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkOkkkkOkOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxc'                       .ckOO    //
//    OOOOOOOOOkOOOOOOOOOOOkxoc;,,',;;:::cllodddddolllllodddxxxkkkkkkkkkkkkxkkkOOkkd:.                           'ok    //
//    OOOOOOOOOOOOOOOOOOxo:'. ..',''..............        ......',;;:lxkkOd,'lkOkd;.                              .x    //
//    OOOOOkOOOOOOOdlll;.  .;ldkkOOkkkkkxddollccclllloolccc:;;;,'..   'lxkx: .:l,.                                .o    //
//    OOOOkkkOOkkOk;     ,lkOOOkOOkkkkkkkkkOkkOkOOOkOkkkkOOOOkOkkkxo;.  'lkk:                                  .'cdO    //
//    OkOOOOOOOOOx;.     .'ckOOOkkkkkkkkkkOOkkkkOOOkkkkOOOkkOOOkkkkkkd;.  .''.  .                            .:dOOOO    //
//    OOOOOOOOOd:.          .;okOkkkkkkkOOOOkkOOOOOkkkOOkkkOOOOOOOOOxo:.     ,:.                          .,lkOOOOOO    //
//    OOOOOOOxc. ...           ':dkOkkOOOkkkOOOOOOOkkOOOOkkOOOOkdl:,.        ;xl.                       'cxOOOOOOOOO    //
//    OOOOOOd'  ,l,              .;okOOOOkOOOOOOOOkOOOOOOkdl:;,..             ,xd.                   .:dOOOOOOOOOOOO    //
//    OOOOOo. .:k:                  'cxOOOOOOOOOOOOOkdl:,..                ,'  ;kd.               .:dO0OOOOOOOOOOOOO    //
//    OOOOo. .cOd.               ..   .:okOOOOOkdl:,..                    .ox'  ;kx'          .,cdO0OOOOO0OOOOOOOOOO    //
//    OOOd' .cO0o.              .c'     .,ldo:,..                        .cOOx'  :Ox'      .,lx0000OO0O00OOO0OOOOOOO    //
//    OOk,  ;k00k'             'c'                                       ,kOOOd. .cOd.   'lk00OO000OOOOOOOOOOOOOOOOO    //
//    OOl. .d0OOOd.          .;l,          ..                           .lOOOO0d.  cOx'  ;O000000OO00OOOOOOOOOOOOOOO    //
//    0k,  :O0O000d'        .od'          ;xk:.                        .oOOO00O0o. .l0x:.:k0O0OOOOOOOOOOOOOOOOOOOOOO    //
//    0x. .o0000000x:.      .;'        .;oOO0Oo,.                     ;xOO0O0000O:  'x0OOO0OOOO0OOOOOOOOOOOOOOOOOOOO    //
//    0d. .d000000000kl;'...    ...,:ldkkxk00Okkkoc;'.           ..':dO00000000O0x'  :O0O000OOOO000OOOOOOOOOOOOOOOOO    //
//    0o. 'x0000000000000kxxdooddxO000Ol..:Od'.,k000Okdlcc:::::lodkO00000000000O00c  .d0O00OOOO000OOOOOOOOOOOOOOOOOO    //
//    0l. 'k000000000000000O0000OOO0000d. .xl  ,O000000000000000OOO0000000000000O0d.  l0O0OOOOOOOOOO0OOOOOOOOOOOOOOO    //
//    0l. 'k0000000000000000000000000O0Oo;cko..d000000000000OOOOO0000OOO0000000000k,  ;O0OOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0o. .x0000000000000000000000000O000000Oxk00000000000000000000O0O0000000OOOO0O;  ,k0OOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    Kx. .o000000000000000000000000000000000000000OO00000000000000000O000000OOOOOO:  'k0OOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    Kk' .o000000000000000000000000000000000000000O00000000000OO00OO0OO000OOOOOOOO:  .x0OOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    KO;  :0000000000000000000000000000000000000000000000000O00O000OO000OOOOOOOOOO;  'x0OOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    00l. 'kK00000000000000000000000000000000000O000000OOO0OO00OO0OOOOOOOOOOOOOOOx'  ;kOOOOOOOOOOOOOOOOOOOOOOOkOOOO    //
//    0Kd. .d00000000000000000000000000000000000000000OOOO00000OOOOOOOOOOOOOOOOOOOl. .oOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0KO;  ;O00000000000000000000000000000000OOO000OOOOOO000O00OOOOOOOOOOOOOOOOOd'  ,kOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000d.  :O0000000000000000000000000000000O000OOOOOOOO000OOOOOOOOOOOOOOOOOOOx,  .oOOOOOOOOOOOOOkOOOOOOkkOOOOOOOO    //
//    0000d. .:k000000000000000000000000000OOOO00OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOd.  .lkOOOkkOOkOOOOOkOOOOOOOOOOOOOOOO    //
//    00000o.  .oO00000O00000000O0000O00000OOOOOOOOOOOOOO0OOOOOOOOOOOOOOOOOOOkl.  'oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000kc. .,ok000000O00000000OO00OOOOOOOOOOOOOOOOO0OOOOOOOOOOOOOOOOOkxl'   ;kOOOOOOOOkOOOOOOOOOOOOOOOOOOOOOOOO    //
//    00000000x:.  .:lxO0OO00OO00OOOOO00OOOOOOOOOOxlcdOOOkkkOOOOOOOOOxdoc;..   'okOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0000000000ko;.  .':oxkOkkxl,.,lxxd;.;x0OOO0k,  ;kOOo...'',,,,'..    ..,:okOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0000000000000kdc,.  ......    .:l,  .l0OOO0x.  cOO0d.   ..   ...';:odxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    00000000000000000kdl:,',;:ld, .;l:.  c00OO0x' .o0O0d. .:oxdddxkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000000000000O: .:lc,  ;O00O0O; .o0O0o. 'oxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    00000000000000000000000OOO0k; .cll:. ,k0OO0O; .o0O0d. 'ox0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000O000O0000x' .lllc. .x0O00O:  cOO0x' .;d0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000O000000O0d. 'olll' .l00000o. ;O00k' .'o0OOOOOOOOOOOOOOOOOOOOOOOOOOOOO00OOOOOOOOOOOOOOOOOOOOO    //
//    00000000000000000O0000000O0o. ,ddoo,  ,llcc:,. .,;;,.  .l0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000000000000o. .,'...   .......  .'....,cx0OOOOOOOOOOOOOOOO0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000000OOO000d. .';clooodxxkkOOkddkOOkkOO0OOO00OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000Oxc::cldkkocx000000000000000000000OOOOOO00OOOOOO0OOOOO00OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000x;''','';:ldO000000000000OOO000OOOOO0000Okkxoc:clxOOOOOOO00OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000x:'',,,'''',:loxO00000000OO0000Okxxdlllc:;,''''''lO0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0000000K0000000000kc'',,''''''''',:clddoccodddolc:;,,''..'''''.''',oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0000000K0000000000x;'',''''''''''''..'''.'''''''''''''''''''...''',o0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000o,'''''''''''''''''''.''''''''''''''.........''';x0O00OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000d;'',,,'''''''',,,:::,'''''''''''.'''.......''''ck0000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000x;''',,;:cloddxxxkOOOxdoodol:,'''''''...''''''';d0O00OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    00K000000000000000Odl::ldkO000000000000000000OOxoc:,''..'''''''''cO0O0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0000K0000000000000000OO000000000000000000000000000Oxol:;,''''''''ck0OOOOO0O000OO00OOOOOOOO00OOOOOOOOOOOOOOOOOO    //
//    000K0000000000000000000000000000000O00000O00000000O000OOkdl:;;:;:oO0OO00OOOOO00OO0OOOOOOOO00OOOOOOOOOOOOOOOOOO    //
//    0000000000000000000000000000000000000000OO00000OO0000000000Oxxkkk00000OOOOO00OOO00OOOOOO00OOOOOOOOOOOOOOOOOOOO    //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SnS is ERC721Creator {
    constructor() ERC721Creator("Skulls & Stones Physical Collection", "SnS") {}
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