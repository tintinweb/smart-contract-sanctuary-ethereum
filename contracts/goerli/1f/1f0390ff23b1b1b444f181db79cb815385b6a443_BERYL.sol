// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BERYL
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    ......................................................................................................................................................    //
//    ......................................................................................................................................................    //
//    .................................................................................................................,,,,,................................    //
//    ........,,,..X,,728BB,......................................................................................BBB00000000000,...........................    //
//    ........,,...X55557XX280B................................................................................BB000BBB,BB,BB02280..........................    //
//    ..............X77X280BB000B...........................................................................B080BB,,,BBBBBBB02280B..........................    //
//    ........,,..B000B822XX2000800B.....................................................................B08280BB00000008288280,............................    //
//    .............B8800B08X7;:;X0,B28.................................................................02220000822288082X280B...............................    //
//    ...............B2X7X800B0X,:;28X:8............................................................,8XX80000082X2222280B...................................    //
//    .................B27.37880B0X,.7X.:0.........................................................0XX8B.B088828880B,.......................................    //
//    ....................2;,53:8B.,2,5:7:;......................................................02X8..088888B,.............................................    //
//    .......................8X,55:X8BX..2X7B................................................B00280B02228B..................................................    //
//    ..........................BX,55.X2X,X02,.......................................,00808X;7X22XXX2,......................................................    //
//    ..............................87,.;:X880B,B,................................,82XX2X22XX2027:X28B......................................................    //
//    .................................XXXX228B,000000B..........................X72B..0888228882X0027X0....................................................    //
//    ..............................0880BB27X7XX72X;77X20,....................8777X8000000BB800800BB02XX0...................................................    //
//    ...........................02X28000B.BX7::;X8028882X8.................2,.:;X2X2222222XX808XXX8002XX0..................................................    //
//    .........................8XX28800008;;X827820,B....8X,................8;,,.7;:,,,,,::7800B8XXX80082XX20B..............................................    //
//    ......................02XX2808880075.,:;X22280B00B,082B..................87:.53.,;7228800BB00880000228888800B,........................................    //
//    ....................07XX2822882800X;:,33.,:;X;7X:.3,7X0.......................0000B,,BBBBB000000008820088888888800B,..................................    //
//    ..................,2X722XX2XX222X8.8XX:::.55553..555728,..............................000008822822X2220088080000088280B,..............................    //
//    .................077XXXX77X;X;X22X2XXX0.027;::,.::X0B,................................8882XXX2X7;;XXXX888880800000000080880,..........................    //
//    ................BXXX22XX77:,X7:;XX7;772XX2208220.,...................................8222XX2XX;;7XXXXX8880088000800000BB08080B........................    //
//    ...............0288X7XXXXX:,;;:;:;::,;,.;X7XX7802X22..,.............................22222XX2XXX2XX2228888000000808000080B8000080b.....................    //
//    ...............0288X7XXXXX:,;;:;:;::,;,.;X7XX7802X2220,.............................22222XX2XXX2XX2228888000000808000080B8000080B0,...................    //
//    ...............8222X77X;X2287:;;::,:::,;77:;XXX0828888800B.........................8X80082X222222X222288880088088888228800000000880...................    //
//    ...............X222XXX7;XX88X;7:;;7;;;:7:::;7:;XB.B00X887:XB......................,X282222X222288888888828008888888088888000000000000.................    //
//    ...............2722XXX:7XX7X282XX2XXX;:;:::,.,;;X8002XXXX2X;;7X77XX2880B..........2XX7XX777288288808082XX22X882882288222828880000000820...............    //
//    ...............B7XXXX77;77;XX8808200XXX7X::,,:::7X27;22002X7;;XX:;;;::,,;777XX88X88227;777X82288000BB0XX2XX7X722X8888882282808000880B080..............    //
//    ................8XXX77:,:,:,.;;7XX227XXX7;:;;;:;X;7XX00000,..,..B0002X7;;77;;;7X7X87777;X282X22800BBXXXX22XXXX2XXXX282XX8888880000800BB88.............    //
//    .................B;,,XX:..,,..5.,:,,:XX;;7;;:;;77;X2X28800B0B0002X8.......,B08XX7;;:,,::;7XXX80000027777XX7X2XXX2XX228X222880088800B000B80............    //
//    ...................07:::::;:.3.,..,,:7XXX77;:7;77;87;;XXX8X77XX2X;72,.............008X7;::::7X0008XX7;7XX7;777;XXXX77XXXXX288800000B000008B...........    //
//    .....................BX:,:2008;,,.,,.3,702;;:;;;X0X.,::,,:77;;;,;;:;20...............B22882XXXXX28X77777::;;7XXX282288822X22XX80B0000000008,..........    //
//    ........................8;;X8B8:,.......787;;;X2X2;.,,.,,.:;;;XX7XX2X2B...........022X2280000880...XX7;;X2200BB,,,,,.,.,,,B08228000B000BB08,..........    //
//    ..........................,X.:,,,,,5.,...X;,,:X2X0;,,:;,::;XX77;77X88880........X::X;XX208888B.....,XXX2B...B000BB0000BBBB,.,B0880BB0000B08b..........    //
//    ............................0;:,::7;55.,.:7,,;XX80,,,:::72X:;7;;;;XX8002B......:3,;78...............02BBB0000800000000000000000008000000B,8B..........    //
//    .............................2X2228BX,3.,,;:::;X82,.,;XX2XX77X;7X77200B20.....X..;X8.................80088828888800880800008800888000800B,8B..........    //
//    .............................2;200B,B87.5.,777;282;:7X82XX7X77;;XX780002B....0,7288..................B822282282228822882288888888888000BBB0...........    //
//    ..............................27X200B.,87:,;X;;X28;,;;;:7XX7;;7;;XX80022.....X20,0,..................,82XX22XX22X22X222XXX2288888888000B,B0...........    //
//    ...............................87;8000B.BX:,;:;2X2X.::,:77X77;777;28888B.....BB0B,....................0XX77XXXXX7XXX2XXXXX288282008880BBBB0...........    //
//    ................................,XX2B088.X.,:772288,,;772227XX;:;X0080.................................022XX2XXXX82XXX22XXX8888880880BBBB00...........    //
//    ..................................2:X888X,.,.:XX288X::7;28B2:;;:72880...................................082XX282XXXXX222228828000000BBB,B0,...........    //
//    ...................................0;5,;:,,,,.;88208:::,282X;;77X000.....................................B88XXXXXXXXX2XX28028888000BBBB,B0............    //
//    ....................................2B08.X.,:772288,,;772227XX;:;X00......................................2XX2XXXX82XXX22XXX8888880880BBBb............    //
//    .....................................X.,7X;:,.,78800X,;;X22X78277828......................................,00XXX22XXX228822808000BBBB,,B0,............    //
//    ......................................;;XX27:,55X0880;::,:X7202288X2........................................008X2X2882X228880BBBBBB,BBBB0BBB00........    //
//    ......................................722802,..3,X8280:,.X82XX2080028.....................BBBB,............,8,0X2X222288800000BBBBBB,BBBB0000B........    //
//    ...................................,0X780B88.....822802.0.....08800020.................B82XX77XXXXX22228888288XXXXX2800BBBBBB,BBBBBBB00B00B,..........    //
//    ...............................,822X2800828.......28880X8......B822888................,X2082XX777XXXXXX7XXX777X22800B,,BBBBBB00000000BB,,.............    //
//    ...............................8XX828800B.........B008880.........B00,.................,B,BBBB0000B000808000000,,,B,BBBBBBBBBBB,,.....................    //
//    .................................,....................,...............................................................................................    //
//    ......................................................................................................................................................    //
//    ......................................................................................................................................................    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BERYL is ERC721Creator {
    constructor() ERC721Creator("BERYL", "BERYL") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x03F18a996cD7cB84303054a409F9a6a345C816ff;
        Address.functionDelegateCall(
            0x03F18a996cD7cB84303054a409F9a6a345C816ff,
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