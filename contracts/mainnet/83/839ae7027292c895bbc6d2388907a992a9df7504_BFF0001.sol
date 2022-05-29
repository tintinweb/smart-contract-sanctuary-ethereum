// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Last Lightbender 0001
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                      . .   .                                                                                                   //
//                                              .. .=I=??=+?$?7I+~~~. ..                                                          //
//                                        ..??++I7$Z$7ZOIZ$$7Z8$$ZZOZZ?=~.                                                        //
//                                     ,IZODZZZ8OO8888$Z8ODDOOOZ78OOOO8OOOO$$=I~,                                                 //
//                                   IZNZZN$OO$N8ZZ8ONO$OM88D8ZO7ZDNDODZ8DDND88DO8??..  . ..                                      //
//                                . ?$OZ7D8O$8O8888D$8ODOZZ8OO88ODZO8ZD8OOZOZ8OOOZ8=ZIZ~,.,,,..                                   //
//                                ,O$ZZZO8MZ8ODNDDODN8MD8N8Z888OO88MO8OZZO$O$ZZZZOZI$7I$ZZ$Z7$I$=,.                               //
//                               ?DZOOO$DNDMZ8NOD8DD8Z8N$8D8DDOD8DDZ887ZO$ZZZ8$OZOZZ$ZZZO$Z77$$$77I?:... .                        //
//                              ,$8I$$$8DZODOODO8OD8DDMODDZZDOOON8OOZZZ8$ZOZ8ZOZ$$$OO$88ZZO78$ZZZ$$77$$O7:...                     //
//                              +8NZNDD8NOONN8OZD8DDM8DDON8OOOD8OZOOZZZ$ZO8OZ$ZDZOZ8ZZD8$88DOOO$OOOZZZ$7$ZZ$+.                    //
//                           . ,$O8+ND7$MNNZDD8O8NMMN88NOD$Z$ZDODO$Z8Z$DOOO$OZOZZZO8ZZ8D8ONND88ZNOZOZ$Z77OZ78I,,                  //
//                ..    ...:..:?7DI8ZZM$88ZNONOZDNNDDODNNOZ8$Z8DZO8Z$OZOZO$OOZZ8OO8OOOZO88DND8DOODN$D8$$7ZOO D8. .                //
//                ,,.,.?+I+~O+:++:IIO7Z78OI=DDODNNNDO8$8888DOOZ8OZZZODO8888ZO88DZDDOO8O$8ND888OOO888ODNO8Z8Z7=D8~                 //
//                .I$ZZIZ$D=O+7OOI:?Z8N7Z7+Z8DOZDZNDOD8Z8DMD8OZ8O7O7ZZ8OOZZ8OOD8ODDOZZOO8ODNMNODO8N8MONDDZZ8Z~D8?                 //
//                ,ZI77?ZOZO8MZ$+M$=?$ZZ?ZNZZ7NMD?D8D8DDNN8D88ODDZZ$$Z8Z8NZDMOM88N8ONO8DDNDDDD88ODO8N8OOODO8+?D8$:                //
//                ,Z$DIZNONZINMZZ7OO+~:Z8?$O$MNNDODZ8DN8DD8ND8$8DO8OOZODODNNMDND8DMDNDNDDOMMNMNMDOOD8DN888DD=888Z:                //
//                7OD+D877$OIM$?OO8NO7=ZDOIZO8NOZZ$D8DNNNDDDD8ZDO8D88D8N88N8D8NDN8NNND8Z88DDODD8OZDDNNO8DDDO,D88,.                //
//                7O7ZZ?7O$ZDZZ7$7NNOOZZMNNDMDOZ7ID$D8I?DD$O$OZMDZ8ODD8MD8D88DMMMNDNMODOO888DDND8DD8ON8DO888OND?,                 //
//                ?DODD88N87NDZ$MODNO8D8IZ88MNN8+,=M8 Z7I8DDDOON8DOZ88D8NN88NOMND88NNNN88O8DDDDDDNO8ONDD8DO8DNN+.                 //
//                ?7ZN8888ON8NMNNDNNNNNDZZO77DN~.~8I,I8ZOOO8OONN$NN8N8D8DDNONN8MNNDDD88888DDNNDDDDDO8NDDDOOD8=.8..                //
//                ?ZO88ZMDNDDDDNMMDDD8NN8D8$7D77=DD+$DZNOOZNN8DD8NDD78D$ZODDD8DNDDD8D8DDDD88DNDDNODDD88D888O8+Z7I                 //
//                ~$NN78DNDNNDDMNNDD8NNDDMDNMM$7ZI==ONZNO$ZDNNDZDNNMNDD88NDDDDDDDDD8N8DN88DMDD888DDNN8D8DO8OO:++                  //
//                =D88ODNNN8D8N8DNDN8DNNNDNON87Z+O8OZNN8MZO8DDDDDDDDDD8O$DNDDD8DNN8DD8N8DO8D~DDD88DD888888OOOZ?,                  //
//                ~$DN88DDODO88DD88N8DMDMODNN88$DNZ7O8DNDIIZ7888DDNDNDDDNNNON8DDDNDDODO8OD. .~D88888D88DO8OOZOD$7.                //
//                =OODD7888DODDO8D8DODNDNNDNNMMMNN7DDDDDN?8DOOOOO88DNDDDDDDDD8DD8DDN8888..   .=8D88O8D8ODD88O$ZDOZ                //
//                 ZO8DO$D88OOZ8ZDDNZ$NONNNNNNO+DDI8DDODNND8Z8DDDNNDDD88DD88DO8DDO8O8:       . +D8DDOD8+=O88OO7$$?O               //
//                 IDDNNNNDN8DONDM8NDO888MNNND$DO88ZN8DDODD8DDDDNDD88+= OI+D8,.8N8DO.          Z888ODD8+..,~888OOZZ               //
//                  ,888OND88D88D88OO8NO8OD8NZ$N8O8NOD8ZONO8NDDDDD$:Z..         , $             +88D88DO8.   ~O88OO~              //
//                  .Z8DZO7?NODDN$8OOZ8O87DNOD8DODOIZZOZDDDODD88N88~             .              :8888OOOZ     .OO8ZD.             //
//                   .$8O88OZDD8D88,..:D.+,ZD8$ODZ8DZOOD$888DD888D8+                            .$88O8ZO~       O8OO,             //
//                       =O?D88Z8? ..:,::.Z8ODZZ8IZ$O8DDO88DD888DZ$+.                             OOO$O:        ,OZOO:            //
//                         ==?Z$O7:      Z$ZZO$8O77. 7.D=$7,8ZOO8ZZ+                             :ZZ88?.         ?OO8?            //
//                         .$7ZOZ      ..$O8DZZOZ        .  .ZOOOZ$.                             =7788..          ZOO8.           //
//                          :8Z?O.      .=OD88I .           .:O$8O7                              ZZO8:            ?OOD$.          //
//                           .77D.      $8OO7.                ZOZ~                            .~=OO8Z.             888I           //
//                               .    .8I78:                 .ZOOO,                           .~Z8OZ:.             ~8O.,          //
//                                   =Z$ID8.                 :$Z8Z~                           Z7ZOO.               +Z$O.          //
//                                  =~$O7O7.                =O$$8=                        .:II$ZZO.                :I,:.          //
//                                .,?I+=+?.               .:~:,:~..                     . .+~7??I?.                               //
//                                 ~~?77..                ..7:+,..                      ~,,=,   ..                                //
//                                                           .:                                                                   //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                     ~.               ~. .          . .=.. .           ..=.                                     //
//                                  NMMMMMM.        .MMMMMMM.         MMMMMMM.        NMMMMM                                      //
//                                 MMM, ,?MM       .MMM ..NMM       .MMM  .MMM.       +O ,MM                                      //
//                                .MM     MMM      .MM    ,MMN       MM.    MMN           MM                                      //
//                                MMM     ,MM      MMM     ,MM      MMM     MMM.          MM                                      //
//                                MMM.    .MM      MMM.     MM      MMM.    :MM           MM                                      //
//                                MMM.     MM     .MMM      MM.     MMM     .MM.          MM                                      //
//                                MMM      MM.     MMM     .MM      MMM     7MM.          MM                                      //
//                                NMM     MMM      MMM.    MMM      MMM.    MMM           MM                                      //
//                                .MMM    MMZ      .MMN    MM.       MMN   .MM .          MM                                      //
//                                  MMM+MMMM        ,MMM+MMMM.       .MMM=MMMM        NMMMMMMMMM.                                 //
//                                   OMMMM.           DMMMM.           OMMMM..        DMMMMMMMMZ,                                 //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BFF0001 is ERC721Creator {
    constructor() ERC721Creator("The Last Lightbender 0001", "BFF0001") {}
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