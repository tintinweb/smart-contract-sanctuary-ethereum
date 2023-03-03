// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LOVE ON CHAIN
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//               [email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]                        //
//               :[email protected]@[email protected]@MBOO0qSk5F2uL7;;;[email protected]@@qNOLBBMX                         //
//                [email protected]@[email protected]@[email protected]                         //
//                [email protected]@[email protected]@[email protected]@@.       LOVE ON CHAIN       //
//               [email protected]@[email protected]@[email protected];[email protected]:          ArtByGage         //
//            ,[email protected]@[email protected]@BMMMO8qNSSUFqJ:r77:rvv7;;vSG,              . . . .        //
//    :[email protected]@[email protected]@@[email protected]@MBMMGPjLLu1Xr:ii:::777rri::i::,,...,:::,::::::::i.       //
//    [email protected]:,:,:,,,,.. .   ..,....,::.........,,.       //
//    @[email protected]@[email protected]::,.,,,,,.. . .     ......,,:...........,       //
//    [email protected]@[email protected]:,,...,...,.,.,.:.,,:....,,.,,,:.:,,.,...,,.       //
//    [email protected]@ui:,,:,,,,.,.,.,,:,:,,.,.....,,.,,:::::,,.,,:.       //
//    [email protected]@OGYi::,:::,:::,:,:.,,,........ ....,,..:r:,,,,::.       //
//    [email protected]@@@@Xvi,:,:,:,:,:,:,,,,.,,,...... ... ........ir,:,,.:.       //
//    [email protected]@[email protected]@Bv ..,.,,:,,.,.,...,,,.,,,..........   ...,.,ri,,....       //
//    [email protected]@BN7. .,,,:,,,,.........,.,.,...,.,....     ..,.:,iLi...,       //
//    [email protected],   ,.,,,,,,:,:......,,.,,,.,.,.,.,.....   .,::iiU:.....       //
//    [email protected]@BMui.    . ..:,,,,,,,:,:,,.....,,:,,.,,......,..     ..::iiLJ:....       //
//    0qE8MMZX8BOMX;         ....,,:,:::,:::,....,,,,,...,..........     ..:r7uY.....       //
//    [email protected]              ....,.,,:,:::,,.,,:,,.,.,......            .:j07:,...       //
//    kMBMFPOM0u                   ......::::i,,,:,,..,,.. .                 rOv::,..       //
//    8BM5FOMSu.    .               . ....,,:i:::::....                       iJr::,,       //
//    MMkSXMk2,  ,:i::,.             . .....:;iii:....   .              .,,.   :7i::.       //
//    BZF5ZX5r.,iirri:::.           . ......:;7r7::.... .              .::iii,. :ri,,       //
//    OZJSGkv:.iLEk27rii..           ....,.,,rrrY;::....               ::::rLY:..ii::       //
//    MPukEur,:75qPu7iii,..     . ....,.,,::i7;:17i:,,,.. . . .       .:rrrJZ0Y:,,ri:       //
//    M0LEEJi::rvLrrir::...........,.,,:,::irji.u2rii:,:,........,...,:irvY11jr::ii:.       //
//    BOuNZJ7:i:i;r;r::.,.,.,.:,:,:,:,::i:iivu: rkuv7ii::,:,:,:,:::::::::i7vJLLri:ri:       //
//    OM5q0u7r:::i:::::::::::::::::i:::iirrvuu:..1kjvv;;iiii:i:i:i:i:i:iirr7r7r;i;rr:.      //
//    SPMFGuLr;iiii:::i:::i:iiiii:iiiirr77vL5r, .iXFJ7777rri;iiii:iiiiri;irr7rr;7rJ7i.      //
//    SNMqkkjLrrrrir;r;ri;iiiiiririrr77vvLvFui...:7NFjvLvv7vv7r7r7r7rrr7;rr77v7v7v27:.      //
//    ME0E2k2YL7vrrr7r77777r7r7r7rvvvvYLLLS57,....:L0PuLYLLLYvL7vvv7vvv7v7Lvv7L7vFF;:.      //
//    J5OMNUF2JYvvvLvv7vvLvLvvvLvLvLLJLYjqkL:,...,,iJNN5LYLJLYLJLLLLLLvYLJLLLYvv5Zvi:.      //
//    ;[email protected]:,....,:ivqZPujYjLuJuuuuuYuJjYuLYLv1O27::.      //
//    ::7u0BXjjuYYLJYjYjYujUJjJUuuJJY5E85Yi::,...,.::i7FEGS1uuJuJujuuujujuJJvL1MSLii:.      //
//    i,vL1EMOSYJYuYjYujuJujuuuJuYj5GOE2Yri:,,,.:,:,::irjP80NS5uujUjuuUujYJvYXBPj;i:i.      //
//    :,rLv1EMBB1JLJLJLuJuuujuJu1N8BZSjLii:,,:,:,:,:,::[email protected]:::,      //
//    [email protected]@Oq12uuJ2u1FXq8MMMGFu7r::,,,:::,:,,,:::,:[email protected]:::i,      //
//    :.:i;[email protected]@MMOMOMMBMM8GX1Yvr:::,,,:::::,:,:,:,,,:::[email protected]:::::.      //
//    i.i:i;[email protected]::::::::::::::,,,:,:,:,:,,:;vu1SFXXqkNkZBF7i::::::.      //
//    :.:::i:[email protected]:::::::i:i::::,:,:,:,:::::::,::rvuU525UuPBL;:::::::.      //
//    :.::i:i:[email protected]:::i:iiiii::::::,:,:,:,::::::::::::;rv7v70G7ii::::::.      //
//    i,:::::::iiYBMkF22jJvv77i;iiiiiii;ii:i::::::,:,:,:::::::::ii::::ii;rPkir:::::::,      //
//    i.i:::::::[email protected];rir;;iiiriiii:i::,:::::::::::::,::::iii;rirrZurii:i:::i,      //
//    i,:::::::::ivBkj7v7vr7r;iririri;irii:::i:::::i:::::::::::::i:iirirrvEjr;ii:i:i:,      //
//    i,:::,::::i:rqkvv7v77rrrrirrr;i:i:i:::::::::::i:::::::::::::::iirr7vZLriiii:::i,      //
//    i.::,:,::::ii1kY7vr7rrrrrri;ii:i:i:i:::i:::i:::::::i:::::i:iiiirr7rL0Lrri;ii:i:.      //
//    :.::::::iiiiiv0Yv77;r;riiiiiii::::::::::::::::::i:i:i:i:iiiirirrrr770v7rrii::::.      //
//    i.::::::::iri7NUvvrririiiiii:i:i:i:i:::::::::::i:iii:iiiiiiirrr7777L0Jr7iiii::i:      //
//    i.::::i:::ii7r01L77rr;iii:iii:i:i:::i:::::i:::::i:i:ii;ir;r;rr77777LOu7rri;iiii,      //
//    :.:::::i:iiii7PPLvr7iri;i;iiii:i:iii:i:i:i:i:::i:iiii;i;rrr77v7v7v7jM277rr;iiii,      //
//    :.::::::::iirrNkJ77rri;;r;ri;iiiii;iiiiii:i:i:iiiiiiii;i7r77v7v7L7vYM1v77riirii,      //
//    :.:::i::iiirr7kPYL7v77rrrrr7rr;rr;i;iiiiiiiiii:iiii;ir;rr7r7777vvL7JOE777vrri;i:      //
//    i.::::i:iii;77XXJLLvvvL77r777rririiiiiri;iiii:iii:irr;rr7r7r77v7LvLj8Mj7v77i;;7:      //
//    :.:::i:iiii77vS0JuJYvL7v77r7rririii;iriri;ii:iiii;[email protected]:      //
//    :.::::iirirr7vNqUJYLLvL7vv7r7rrir;r;ririii;iiiri;rrirr7r7vv7vvLLLLj1NOBuJvvv7rr:      //
//    :.:i:iirrr;rr7NZUuJJLLvv7v77rrrrr;rr;rir;r;rrr;rrrrr77777L7vvvvLLuukPGMZJJvL77r:      //
//    :.i:::iir;;r77Z01uuYJYLvv7v7vrr77r7r7rrrrrrir;7r777r7rL7v7v7YLjJuu5k0E8GXJJvv77:      //
//    :,:i:iirrrirrLZZ1UJuuuYYLv7v7777r7r777r7rrrr;rr7r7rr7v7vvLvLLjJUu1SqNZEGZFJYvv7i      //
//    :.i:ii;irrrr7JOqFu2juYYLYvLvLvv7v77r777rrr777r7r7r77vvL7LLYYjJuu15XXEN0assciivLi      //
//    i.iii;;7irr772GP1UuuLYvLvL7LvL7v7vr7r7r7r77777r77vvvLLvLvJYuJuu21kkPq0qE0Zk1JjLr      //
//    i.i:iirirr7r75ZPSuuYuLLvLvL7LvLvv7Lvv7L777v7v7LvYLLvLLjJjJUu2U1UkkPXqq0N00XYSuur      //
//    i ,,,::::i:;r5NSujLLvLvv7vrrrr;7r7r7rrrrr7r7r7r7r77vvvvJLJJujUuU2S5SkXkPXqqvv5Yr      //
//    u/clothesareoverrated                                                                 //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract LOVE is ERC1155Creator {
    constructor() ERC1155Creator("LOVE ON CHAIN", "LOVE") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x6bf5ed59dE0E19999d264746843FF931c0133090;
        (bool success, ) = 0x6bf5ed59dE0E19999d264746843FF931c0133090.delegatecall(abi.encodeWithSignature("initialize(string,string)", name, symbol));
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