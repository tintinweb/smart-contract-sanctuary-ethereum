// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// name: R1B2ascii
// contract by: artgene.xyz

import "./Artgene721.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░████████████████████████████████████████████████████████████████████████████░░    //
//    ░░████████████████████████████████████████████████████████████████████████████░░    //
//    ░░████████████████████████████████████████████████████████████████████████████░░    //
//    ░░████████████████████████████████████████████████████████████████████████████░░    //
//    ░░████████████▓░░░░░░░░░░░░░░░░░▒▒▒▓▓██████████████████░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░░░░░░░░░░░░░░░░▓██████████████▓░░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░░░░░░░░░░░░░░░░░▒███████████▒░░░░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░▓██████▓░░░░░░░░░▓█████▓▓▒░░░░░░░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░▓███████▒░░░░░░░░▓█████░░░░░░░░░░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░▓██████▓░░░░░░░░░██████░░░░░░▒▓▒░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░░░░░░░░░░░░░░░░░███████░░▒▓████▒░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░░░░░░░░░░░░░░▒▓████████████████▒░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░░▒░░░░░░░░░▒▓██████████████████▒░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░▓███▒░░░░░░░░░▓████████████████▒░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░▓████▒░░░░░░░░░▓███████████████▒░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░▓█████▒░░░░░░░░░▒██████████████▒░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░▓██████▓░░░░░░░░░▒█████████████▒░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░▓███████▓░░░░░░░░░▒████████████▒░░░░░░░▓███████████████░░    //
//    ░░████████████▓▒▒▒▒▒▒▒▒█████████▓▒▒▒▒▒▒▒▒▒████████████▓▒▒▒▒▒▒▒████████████████░░    //
//    ░░████████████████████████████████████████████████████████████████████████████░░    //
//    ░░████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████▓▓▒▒▒▒▒▒▒▒▓▓████████████████░░    //
//    ░░████████████░░░░░░░░░░░░░░░░░░░░░░▒██████████▒░░░░░░░░░░░░░░░░▓█████████████░░    //
//    ░░████████████░░░░░░░░░░░░░░░░░░░░░░░░▓██████▓░░░░░░░░░░░░░░░░░░░░████████████░░    //
//    ░░████████████░░░░░░░░░▒▒▒▒▒▒░░░░░░░░░░█████▓░░░░░░░░▓███▓░░░░░░░░▒███████████░░    //
//    ░░████████████░░░░░░░░░███████▒░░░░░░░░█████░░░░░░░░▓██████░░░░░░░░███████████░░    //
//    ░░████████████░░░░░░░░░███████░░░░░░░░▒███████████████████▓░░░░░░░▒███████████░░    //
//    ░░████████████░░░░░░░░░░░░░░░░░░░░░░░▓███████████████████▒░░░░░░░░████████████░░    //
//    ░░████████████░░░░░░░░░░░░░░░░░░░░░▒▓█████████████████▓░░░░░░░░░▒█████████████░░    //
//    ░░████████████░░░░░░░░░░░░░░░░░░░░░░░░░████████████▓▒░░░░░░░░░▒███████████████░░    //
//    ░░████████████░░░░░░░░░████████░░░░░░░░░█████████▓░░░░░░░░░░▓█████████████████░░    //
//    ░░████████████░░░░░░░░░████████▓░░░░░░░░▓██████▓░░░░░░░░░▓████████████████████░░    //
//    ░░████████████░░░░░░░░░██████▓▒░░░░░░░░░▓█████░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓███████████░░    //
//    ░░████████████░░░░░░░░░░░░░░░░░░░░░░░░░▒█████░░░░░░░░░░░░░░░░░░░░░░███████████░░    //
//    ░░████████████░░░░░░░░░░░░░░░░░░░░░░░░▓█████░░░░░░░░░░░░░░░░░░░░░░░███████████░░    //
//    ░░████████████░░░░░░░░░░░░░░░░░░░▒▒▓▓██████▓░░░░░░░░░░░░░░░░░░░░░░░███████████░░    //
//    ░░████████████████████████████████████████████████████████████████████████████░░    //
//    ░░████████████████████████████████████████████████████████████████████████████░░    //
//    ░░████████████████████████████████████████████████████████████████████████████░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////

contract R1B2ASCII is Artgene721 {
    constructor() Artgene721("R1B2ascii", "R1B2ASCII", 100, 1, START_FROM_ONE, "https://metadata.artgene.xyz/api/g/goerli/r1b2ascii/",
                              MintConfig(0.01 ether, 1, 1, 0, 0xD9f1C6C5f76498eB5EFb8b1E6E177bC5f52cAB88, false, 0, 0)) {}
}

// SPDX-License-Identifier: MIXED

// Sources flattened with hardhat v2.14.0 https://hardhat.org

// File @openzeppelin/contracts/proxy/[email protected]

// License-Identifier: MIT
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


// File @openzeppelin/contracts/utils/[email protected]

// License-Identifier: MIT
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


// File contracts/interfaces/IArtgene721.sol

// License-Identifier: MIT
pragma solidity ^0.8.9;

address constant ARTGENE_PROXY_IMPLEMENTATION = 0x00000721bEb748401E0390Bb1c635131cDe1Fae8;

uint256 constant ARTGENE_MAX_SUPPLY_OPEN_EDITION = 0;

struct MintConfig {
    uint256 publicPrice;
    uint256 maxTokensPerMint;
    uint256 maxTokensPerWallet;
    uint256 royaltyFee;
    address payoutReceiver;
    bool shouldLockPayoutReceiver;
    uint32 startTimestamp;
    uint32 endTimestamp;
}

interface IArtgene721 {
    // ------ View functions ------
    function saleStarted() external view returns (bool);

    function isExtensionAdded(address extension) external view returns (bool);

    function renderer() external view returns (address);

    /**
        Extra information stored for each tokenId. Optional, provided on mint
     */
    function data(uint256 tokenId) external view returns (bytes32);

    // ------ Mint functions ------
    /**
        Mint from NFTExtension contract. Optionally provide data parameter.
     */
    function mintExternal(
        uint256 amount,
        address to,
        bytes32 data
    ) external payable;

    // ------ Admin functions ------
    function addExtension(address extension) external;

    function revokeExtension(address extension) external;

    function withdraw() external;

    // ------ View functions ------
    /**
        Recommended royalty for tokenId sale.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);

    // ------ Admin functions ------
    function setRoyaltyReceiver(address receiver) external;

    function setRoyaltyFee(uint256 fee) external;

    // ------ IERC4906 ------

    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

interface IArtgene721Implementation {
    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _nReserved,
        bool _startAtOne,
        string memory uri,
        MintConfig memory config
    ) external;
}


// File contracts/Artgene721.sol

// License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * @title contract by artgene.xyz
 * @dev Artgene721 is extendable implementation of ERC721 based on ERC721A and Artgene721Implementation.
 */

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#S%??%S#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%***++***[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?+***%?**+*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@S+*+*#@@?+*[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*+++%@@@#*[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@S+++*#@@@@%+++*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*+++%@@@@@#*+++%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@S+++*#@@@@@@%+++*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?+++%@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@S++++#@@@@@@@@?+++*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@*+++*%???#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@S+++*#@@@@@#S%?*[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@#?+++;+++++++%%[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@#*;+++?%S%[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%;[email protected]@@@#+++;%@@@#+++;[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*;+;[email protected]@@@@%;+;+#@@@*;+;[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#+;;;[email protected]@@@@@?;;;[email protected]@%;;;[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%;;;[email protected]@@@@@@@?;;;;?#%;;;+#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*;;;[email protected]@@@@@@@@%+;;;+;;;;[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#;;;;#@@@@@@@@@@#%*+;;;+%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#?+*%@@@@@@@@@@@@@@#SS#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////

type StartFromTokenIdOne is bool;

contract Artgene721 is Proxy {
    StartFromTokenIdOne internal constant START_FROM_ONE =
        StartFromTokenIdOne.wrap(true);
    StartFromTokenIdOne internal constant START_FROM_ZERO =
        StartFromTokenIdOne.wrap(false);

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 nReserved,
        StartFromTokenIdOne startAtOne,
        string memory uri,
        MintConfig memory configValues
    ) {
        Address.functionDelegateCall(
            ARTGENE_PROXY_IMPLEMENTATION,
            abi.encodeWithSelector(
                IArtgene721Implementation.initialize.selector,
                name,
                symbol,
                maxSupply,
                nReserved,
                startAtOne,
                uri,
                configValues
            )
        );
    }

    function implementation() public pure returns (address) {
        return _implementation();
    }

    function _implementation() internal pure override returns (address) {
        return address(ARTGENE_PROXY_IMPLEMENTATION);
    }
}