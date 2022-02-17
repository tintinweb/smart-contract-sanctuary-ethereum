/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: Base64

/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
/// @notice NOT BUILT BY SHEET FIGHTER TEAM. THANK YOU BRECHT DEVOS!
/// @notice For any curious devs, this appears to be the same base64 encoding used by Ether Orcs and Anonymice
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// Part: IBridge

/// @dev Interface for Bridge
interface IBridge {
    function bridgeTokensCallback(address tokenOwner, uint256[] calldata tokenIds) external;
}

// Part: OpenZeppelin/[email protected]/Address

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// Part: OpenZeppelin/[email protected]/Context

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// Part: OpenZeppelin/[email protected]/ECDSA

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return recover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return recover(hash, r, vs);
        } else {
            revert("ECDSA: invalid signature length");
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`, `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// Part: OpenZeppelin/[email protected]/IERC165

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Part: OpenZeppelin/[email protected]/IERC721Receiver

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// Part: OpenZeppelin/[email protected]/Strings

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// Part: SheetFighterUtilities

/// @notice Utilities for Sheet Fighter
library SheetFighterUtilities {

    /// @notice Substring string on range [_startIndex, _endIndex)
    /// @param _str String to substring
    /// @param _startIndex Start index, inclusive
    /// @param _endIndex End index, exclusive
    /// @return Substring from range [_startIndex, endIndex)
    function substring(string memory _str, uint256 _startIndex, uint256 _endIndex) internal pure returns(string memory) {
        bytes memory _strBytes = bytes(_str);
        bytes memory _substringBytes = new bytes(_endIndex - _startIndex);
        uint256 strIndex = 0;
        for(uint256 i = _startIndex; i < _endIndex; i++) {
            _substringBytes[strIndex] = _strBytes[i];
            strIndex++;
        } 

        return string(_substringBytes);
    }


    /// @notice Split a flavor text string, deliminated by a pipe ("|"), with four partitions 
    /// @dev This function does NOT test for edge cases, like consecutive pipes, or strings ending with a pipe
    /// @param _str String to split, deliminated by a pipe: "|"
    /// @return A list of strings, resulting from spliting _str
    function splitFlavorTextString(string memory _str) internal pure returns(string[5] memory) {

        bytes memory str = bytes(_str);
        uint256 startIndex = 0;
        uint partitionIndex = 0;

        // Array to hold partitions
        string[5] memory strArr;

        for(uint256 i = 0; i < str.length; i++) {
            if(str[i] == "|") {
                // Save partition
                strArr[partitionIndex] = substring(_str, startIndex, i);

                // Continue to next partition
                startIndex = i + 1;
                partitionIndex += 1;
            } 
        }

        // Save last partition
        strArr[4] = substring(_str, startIndex, str.length);

        return strArr;
    }

    /// @dev    Get a bit mask
    /// @param  _numBits Number of bits to use for the max
    /// @return A bit mask to be used with the bit-wise operator &
    function getBitMask(uint256 _numBits) internal pure returns(uint256) {
        return (2 << (_numBits + 1)) - 1;
    }

    /// @notice Get fighter stat
    /// @param _stats       Stats for the fighter
    /// @param _shiftBits   Number of bits to shift to get to the stat
    /// @param _min         Min value for the stat
    /// @param _max         Max value for the stat
    /// @return The stat, bounded by _min and _max
    function getFighterStat(
        uint256 _stats, 
        uint8 _shiftBits, 
        uint8 _min, 
        uint8 _max
    )
        internal
        pure 
        returns(uint8) 
    {

        uint256 bitMask = 0xFF; // Equivalent to 11111111 in binary
        uint256 rangeWidth = _max - _min;

        // Get the stat unnormalized (i.e. not bounded between _min and _max)
        uint8 statUnnormalized = uint8((_stats >> _shiftBits) & bitMask);

        // Get the stat normalized (i.e. bounded between _min and _max, inclusive)
        uint8 statNormalized = (uint8(statUnnormalized % (rangeWidth + 1))) + _min;

        return statNormalized;
    }
}

// Part: OpenZeppelin/[email protected]/ERC165

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// Part: OpenZeppelin/[email protected]/IERC721

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// Part: OpenZeppelin/[email protected]/Ownable

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Part: OpenZeppelin/[email protected]/IERC721Enumerable

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// Part: OpenZeppelin/[email protected]/IERC721Metadata

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// Part: ERC721A

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Does not support burning tokens to address(0).
 */
contract ERC721A is
  Context,
  ERC165,
  IERC721,
  IERC721Metadata,
  IERC721Enumerable
{
  using Address for address;
  using Strings for uint256;

  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
  }

  struct AddressData {
    uint128 balance;
    uint128 numberMinted;
  }

  uint256 private currentIndex = 0;

  uint256 internal immutable maxBatchSize;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
  mapping(uint256 => TokenOwnership) private _ownerships;

  // Mapping owner address to address data
  mapping(address => AddressData) private _addressData;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev
   * `maxBatchSize` refers to how much a minter can mint at a time.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_
  ) {
    require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
    _name = name_;
    _symbol = symbol_;
    maxBatchSize = maxBatchSize_;
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return currentIndex;
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    require(index < totalSupply(), "ERC721A: global index out of bounds");
    return index;
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
   * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256)
  {
    require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
    uint256 numMintedSoFar = totalSupply();
    uint256 tokenIdsIdx = 0;
    address currOwnershipAddr = address(0);
    for (uint256 i = 0; i < numMintedSoFar; i++) {
      TokenOwnership memory ownership = _ownerships[i];
      if (ownership.addr != address(0)) {
        currOwnershipAddr = ownership.addr;
      }
      if (currOwnershipAddr == owner) {
        if (tokenIdsIdx == index) {
          return i;
        }
        tokenIdsIdx++;
      }
    }
    revert("ERC721A: unable to get token of owner by index");
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "ERC721A: balance query for the zero address");
    return uint256(_addressData[owner].balance);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    require(
      owner != address(0),
      "ERC721A: number minted query for the zero address"
    );
    return uint256(_addressData[owner].numberMinted);
  }

  function ownershipOf(uint256 tokenId)
    internal
    view
    returns (TokenOwnership memory)
  {
    require(_exists(tokenId), "ERC721A: owner query for nonexistent token");

    uint256 lowestTokenToCheck;
    if (tokenId >= maxBatchSize) {
      lowestTokenToCheck = tokenId - maxBatchSize + 1;
    }

    for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
      TokenOwnership memory ownership = _ownerships[curr];
      if (ownership.addr != address(0)) {
        return ownership;
      }
    }

    revert("ERC721A: unable to determine the owner of token");
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return ownershipOf(tokenId).addr;
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overriden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721A.ownerOf(tokenId);
    require(to != owner, "ERC721A: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721A: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public override {
    require(operator != _msgSender(), "ERC721A: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public override {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721A: transfer to non ERC721Receiver implementer"
    );
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return tokenId < currentIndex;
  }

  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, "");
  }

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `quantity` cannot be larger than the max batch size.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal {
    uint256 startTokenId = currentIndex;
    require(to != address(0), "ERC721A: mint to the zero address");
    // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
    require(!_exists(startTokenId), "ERC721A: token already minted");
    require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    AddressData memory addressData = _addressData[to];
    _addressData[to] = AddressData(
      addressData.balance + uint128(quantity),
      addressData.numberMinted + uint128(quantity)
    );
    _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

    uint256 updatedIndex = startTokenId;

    for (uint256 i = 0; i < quantity; i++) {
      emit Transfer(address(0), to, updatedIndex);
      require(
        _checkOnERC721Received(address(0), to, updatedIndex, _data),
        "ERC721A: transfer to non ERC721Receiver implementer"
      );
      updatedIndex++;
    }

    currentIndex = updatedIndex;
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) private {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
      getApproved(tokenId) == _msgSender() ||
      isApprovedForAll(prevOwnership.addr, _msgSender()));

    require(
      isApprovedOrOwner,
      "ERC721A: transfer caller is not owner nor approved"
    );

    require(
      prevOwnership.addr == from,
      "ERC721A: transfer from incorrect owner"
    );
    require(to != address(0), "ERC721A: transfer to the zero address");

    _beforeTokenTransfers(from, to, tokenId, 1);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, prevOwnership.addr);

    _addressData[from].balance -= 1;
    _addressData[to].balance += 1;
    _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

    // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
    // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
    uint256 nextTokenId = tokenId + 1;
    if (_ownerships[nextTokenId].addr == address(0)) {
      if (_exists(nextTokenId)) {
        _ownerships[nextTokenId] = TokenOwnership(
          prevOwnership.addr,
          prevOwnership.startTimestamp
        );
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  uint256 public nextOwnerToExplicitlySet = 0;

  /**
   * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
   */
  function _setOwnersExplicit(uint256 quantity) internal {
    uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
    require(quantity > 0, "quantity must be nonzero");
    uint256 endIndex = oldNextOwnerToSet + quantity - 1;
    if (endIndex > currentIndex - 1) {
      endIndex = currentIndex - 1;
    }
    // We know if the last one in the group exists, all in the group exist, due to serial ordering.
    require(_exists(endIndex), "not enough minted yet for this cleanup");
    for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
      if (_ownerships[i].addr == address(0)) {
        TokenOwnership memory ownership = ownershipOf(i);
        _ownerships[i] = TokenOwnership(
          ownership.addr,
          ownership.startTimestamp
        );
      }
    }
    nextOwnerToExplicitlySet = endIndex + 1;
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721A: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  /**
   * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
   * minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}

// File: SheetFighterToken.sol

/// @title  Contract creating non-fungible in-game utility tokens for the game Sheet Fighter, which represent players' fighters
/// @author Overlord Paper Co
/// @notice This defines the non-fungible in-game utility tokens for the game Sheet Fighter, which represent players' fighters
contract SheetFighterToken is ERC721A, Ownable {

    /// @dev Contains a fighter's stats
    struct FighterStats {
        uint8 HP;
        uint8 critical;
        uint8 heal;
        uint8 defense;
        uint8 attack;
        SheetColor color;
        PaperStock stock;
    }

    /// @notice Defines possible colors for a Sheet
    enum SheetColor {
        BLUE,
        RED,
        GREEN,
        ORANGE,
        PINK,
        PURPLE
    }

    /// @notice Defines possible paper stock
    enum PaperStock {
        GLOSSY,
        MATTE,
        SATIN
    }

    /// @notice The maximum number of tokens that can be minted
    uint256 public constant MAX_TOKENS = 8_888;                         // 8,888 tokens can minted, max

    /// @notice The maximum number of mints allowed in a single mint transactions
    uint256 public constant MAX_MINTS_PER_TXN = 20;                     // 20 Sheet Fighters mint limit per transaction

    // Token stats variables
    uint8 internal constant MIN_HP = 1;
    uint8 internal constant MIN_CRITICAL = 1;
    uint8 internal constant MIN_HEAL = 1;
    uint8 internal constant MIN_DEFENSE = 1;
    uint8 internal constant MIN_ATTACK = 1;
    uint8 internal constant MAX_HP = 255;
    uint8 internal constant MAX_CRITICAL = 255;
    uint8 internal constant MAX_HEAL = 255;
    uint8 internal constant MAX_DEFENSE = 255;
    uint8 internal constant MAX_ATTACK = 255;
    uint256 internal constant RARE_MOVE_THRESHOLD = 95;                   // This is 95%

    /// @notice The price of minting a single Sheet Fighter
    uint256 public constant PRICE = 5 ether / 100;                      // 0.05 ETH price

    /// @dev A nonce for the seed
    uint256 internal seedNonce = 0;

    /// @notice Indicates whether or not the sale is open for minting
    bool public saleOpen = false;

    /// @notice Address of the GPT-3 signer
    address public mintSigner;

    /// @notice Flavor text of tokens
    mapping(uint256 => string) public flavorTexts;

    /// @notice Stats of tokens
    mapping(uint256 => FighterStats) public tokenStats;

    /// @notice Address of the Polygon bridge
    address public bridge;

    /// @notice Address of the ERC20 CellToken contract
    address public cellTokenAddress;

    mapping(bytes32 => bool) signatureHashUsed;

    /// @notice Construct Sheet Fighter in-game utility NFT
    /// @dev    Call default ERC721 contructor with token name and symbol, and implicitly execute Ownable constructor
    /// @param _mintSigner Address that will be signing mint transactions
    constructor(address _mintSigner) ERC721A("Sheet Fighter", "SHEET", MAX_MINTS_PER_TXN) Ownable() {
        mintSigner = _mintSigner;
    }

    /// @notice Update the address of the CellToken contract
    /// @param _contractAddress Address of the CellToken contract
    function setCellTokenAddress(address _contractAddress) external onlyOwner {
        cellTokenAddress = _contractAddress;
    }

    /// @notice Update the address which signs the mint transactions
    /// @dev    Used for ensuring GPT-3 values have not been altered
    /// @param  _mintSigner New address for the mintSigner
    function setMintSigner(address _mintSigner) external onlyOwner {
        mintSigner = _mintSigner;
    }

    /// @notice Update the address of the bridge
    /// @dev Used for authorization
    /// @param  _bridge New address for the bridge
    function setBridge(address _bridge) external onlyOwner {
        bridge = _bridge;
    }

    /// @dev Withdraw funds as owner
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /// @notice Open or close the sale
    /// @param  _saleOpen Whether or not the sale should be open
    function setSaleOpen(bool _saleOpen) external onlyOwner {
        saleOpen = _saleOpen;
    }

    /// @notice Mint up to 20 Sheet Fighters
    /// @dev This function uses that ERC721A _safeMint function
    /// @param  numTokens Number of Sheet Fighter tokens to mint (1 to 20)
    /// @param  _flavorTexts Array of strings with flavor texts concatonated with a pipe character
    /// @param  signature Signature verifying flavorTexts are unmodified
    function mint(
        uint256 numTokens, 
        string[] memory _flavorTexts,
        bytes memory signature
    ) 
        external 
        payable 
    {
        require(numTokens > 0, "Invalid number of tokens");
        require(saleOpen, "Minting is closed");
        require(msg.value >= PRICE * numTokens, "Insufficient payment");
        require(totalSupply() + numTokens <= MAX_TOKENS, "There aren't that many unminted tokens");
        require(numTokens == _flavorTexts.length, "Invalid parameters");

        // Check flavor text integrity
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(keccak256(abi.encode(_flavorTexts))), 
                signature
            ) == mintSigner, 
            "Invalid signature"
        );

        // Prevent signature replay 
        bytes32 signatureHash = keccak256(signature);
        require(!signatureHashUsed[signatureHash], "Signature has already been used");
        signatureHashUsed[keccak256(signature)] = true;
        
        // Print values
        for(uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = totalSupply() + i;
            tokenStats[tokenId] =  _generateTokenStats(tokenId);
            flavorTexts[tokenId] = _flavorTexts[i];
        }

        // Mint tokens
        _safeMint(msg.sender, numTokens);
    }

    /// @notice Bridge the Sheets
    /// @dev Transfers Sheets to bridge
    /// @param tokenOwner Address of the tokenOwner who is bridging their tokens
    /// @param tokenIds Array of tokenIds that tokenOwner is bridging
    function bridgeSheets(address tokenOwner, uint256[] calldata tokenIds) external {
        require(bridge != address(0), "Bridge is not set");
        require(msg.sender == bridge, "Only bridge can do this");
        for(uint256 index = 0; index < tokenIds.length; index++) {
            transferFrom(tokenOwner, msg.sender, tokenIds[index]);
        }
        IBridge(msg.sender).bridgeTokensCallback(tokenOwner, tokenIds);
    }

    /// @notice Update the sheet to sync with actions that occured on otherside of bridge
    /// @param tokenId Id of the SheetFighter
    /// @param HP New HP value
    /// @param critical New critical value
    /// @param heal New heal value
    /// @param defense New defense value
    /// @param attack New attack value
    function syncBridgedSheet(
        uint256 tokenId,
        uint8 HP,
        uint8 critical,
        uint8 heal,
        uint8 defense,
        uint8 attack
    ) 
        external 
    {
        require(bridge != address(0), "Bridge is not set");    
        require(msg.sender == bridge, "Only bridge can do this");
        require(ownerOf(tokenId) == bridge, "Sheet hasn't been bridged");

        // Update stats
        tokenStats[tokenId].HP = HP;
        tokenStats[tokenId].critical = critical;
        tokenStats[tokenId].heal = heal;
        tokenStats[tokenId].defense = defense;
        tokenStats[tokenId].attack = attack;
    }

    /// @notice Returns the token metadata and SVG artwork
    /// @dev    This generates a data URI, which contains the metadata json, encoded in base64
    /// @param _tokenId The tokenId of the token whos metadata and SVG we want
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token doesn't exist");
        FighterStats memory _stats = tokenStats[_tokenId];
        string[5] memory _flavorTexts = SheetFighterUtilities.splitFlavorTextString(flavorTexts[_tokenId]);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Sheet Fighter #',
                                    Strings.toString(_tokenId),
                                    ' - ',
                                    _flavorTexts[0],
                                    '", "description": "Sheet Fighter is a collection of 100% on-chain fighting spreadsheets, packed with unique and unpredictable GPT-3 generated personalities. Collect, stake, and battle to shred your competition.", "image": "data:image/svg+xml;base64,',
                                    Base64.encode(
                                        bytes(_getSVG(_tokenId, _stats, _flavorTexts))
                                    ),
                                    '","attributes":',
                                    _getAttributes(_stats),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    /// @notice Determines if a stat is rare
    /// @param stat The stat
    /// @param min Minimum value the stat can have
    /// @param max Maximum value the stat can have
    /// @return true if stat is rare, otherwise false
    function isRareStat(uint8 stat, uint8 min, uint8 max) public view returns(bool) {
        return uint256(stat) * 100 >= (RARE_MOVE_THRESHOLD * (uint256(max) - uint256(min))) + (100 * uint256(min));
    }

    /// @notice Generate random uint256
    /// @param  _tokenId Token id for which to generate random number
    /// @param  _address Address for which to generate random number
    /// @return Random uint256
    function _random(uint256 _tokenId, address _address) internal returns(uint256) {
        // Increment nonce
        seedNonce++;

        return uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    _tokenId,
                    _address,
                    seedNonce
                )
            )
        );
    }

    function _generateTokenStats(uint256 tokenId) internal returns(FighterStats memory) {

        uint256 _rand = _random(tokenId, msg.sender);

        // Get Sheet color
        uint8 _colorPredictor = SheetFighterUtilities.getFighterStat(
            _rand,
            40, 
            0, 
            255
        );

        SheetColor color;
        if(_colorPredictor < 116) {
            color = SheetColor.BLUE;
        } else if(_colorPredictor < 193) {
            color = SheetColor.RED;
        } else if(_colorPredictor < 244) {
            color = SheetColor.GREEN;
        } else if(_colorPredictor < 252) {
            color = SheetColor.ORANGE;
        } else if(_colorPredictor < 255) {
            color = SheetColor.PINK;
        } else {
            color = SheetColor.PURPLE;
        }

        // Get paper stock
        uint8 _stockPredictor = SheetFighterUtilities.getFighterStat(
            _rand, 
            48, 
            0, 
            2
        );
        PaperStock stock;
        if(_stockPredictor == 0) {
            stock = PaperStock.GLOSSY;
        } else if(_stockPredictor == 1) {
            stock = PaperStock.MATTE;
        } else if(_stockPredictor == 2) {
            stock = PaperStock.SATIN;
        }

        return FighterStats(
            SheetFighterUtilities.getFighterStat(
                _rand,
                0, 
                MIN_HP, 
                MAX_HP
            ),
            SheetFighterUtilities.getFighterStat(
                _rand,
                8, 
                MIN_CRITICAL, 
                MAX_CRITICAL
            ),
            SheetFighterUtilities.getFighterStat(
                _rand,
                16,
                MIN_HEAL, 
                MAX_HEAL 
            ),
            SheetFighterUtilities.getFighterStat(
                _rand,
                24,
                MIN_DEFENSE, 
                MAX_DEFENSE 
            ),
            SheetFighterUtilities.getFighterStat(
                _rand,
                32,
                MIN_ATTACK, 
                MAX_ATTACK 
            ),
            color,
            stock
        );
    }

    /// @dev Get SVG for token -- SVG string construction must be done in multiple parts to avoid STACK TOO DEEP error
    /// @param _tokenId Token id
    /// @param _stats Fighter stats
    /// @param _flavorTexts static array of flavor texts -- order dictates which string is for which attribute
    /// @return String containing SVG Data URI
    function _getSVG(
        uint256 _tokenId, 
        FighterStats memory _stats, 
        string[5] memory _flavorTexts
    ) 
        internal 
        view 
        returns(string memory) 
    {

        // SVG initialization and styling
        bytes memory svgBytes = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 501"><defs>',
            '<style>.d{font-size:27px;font-family:ArialMT,Arial}.h{fill:#999}.l{text-anchor:end}</style>',
            '</defs><path fill="#d6d6d6" d="M0 0h500v501H0z"/>'
        );

        // Move cells
        // NOTE: Move stats are multiplied by 100, as part of avoiding working with decimals
        svgBytes = abi.encodePacked(
            svgBytes,
            '<path fill="#',
            isRareStat(_stats.attack, MIN_ATTACK, MAX_ATTACK) ? 'ff0': 'fff',
            '" d="M80.53 169.51H494.2v76.67H80.53z"/>',
            '<path fill="#',
            isRareStat(_stats.defense, MIN_DEFENSE, MAX_DEFENSE) ? 'ff0': 'fff',
            '" d="M80.93 252.06H494.6v76.67H80.93z"/>',
            '<path fill="#',
            isRareStat(_stats.critical, MIN_CRITICAL, MAX_CRITICAL) ? 'ff0': 'fff',
            '" d="M80.93 335.46H494.6v76.67H80.93z"/>',
            '<path fill="#',
            isRareStat(_stats.heal, MIN_HEAL, MAX_HEAL) ? 'ff0': 'fff',
            '" d="M80.93 418.15H494.6v76.67H80.93z"/>'
        );

        // HP and misc. paths
        svgBytes = abi.encodePacked(
            svgBytes,
            '<path d="M6.02 418.15h68.94v76.67H6.02zm0-82.73h68.94v76.67H6.02zM6 252.19h68.94v76.67H6zm0-82.69h68.94v76.67H6z" fill="#efefef"/><path d="M5.79 84.33h333.75v78.33H5.79zm339.54 0H494.2v78.33H345.33z" fill="#fff"/>',
            '<text class="d" transform="translate(374.99 133.17)">',
            'HP ',
            Strings.toString(_stats.HP),
            '</text>'
        );

        // Move flavor texts
        svgBytes = abi.encodePacked(
            svgBytes,
            '<text class="d" transform="translate(90.82 217.51)">',
            _flavorTexts[1],
            '</text><text class="d" transform="translate(90.95 300.06)">',
            _flavorTexts[2],
            '</text><text class="d" transform="translate(90.22 383.47)">',
            _flavorTexts[3],
            '</text><text class="d" transform="translate(91.22 466.15)">',
            _flavorTexts[4],
            '</text>'
        );

        // Move values
        svgBytes = abi.encodePacked(
            svgBytes,
            '<text class="d l" transform="translate(485 217.51)">',
            Strings.toString(_stats.attack),
            '</text><text class="d l" transform="translate(485 466.15)">',
            Strings.toString(_stats.heal),
            '</text><text class="d l" transform="translate(485 383.47)">',
            Strings.toString(_stats.critical),
            '</text><text class="d l" transform="translate(485 301.86)">',
            Strings.toString(_stats.defense),
            '</text>'
        );

        // Shapes, name flavor text, token ID, and SVG ending
        string memory sheetColorCode;
        if(_stats.color == SheetColor.RED) {
            sheetColorCode = 'f00';
        } else if(_stats.color == SheetColor.GREEN) {
            sheetColorCode = '3c3';
        } else if(_stats.color == SheetColor.ORANGE) {
            sheetColorCode = 'f90';
        } else if(_stats.color == SheetColor.PINK) {
            sheetColorCode = 'f6f';
        } else if(_stats.color == SheetColor.PURPLE) {
            sheetColorCode = '63c';
        } else {
            // Blue
            sheetColorCode = '00f';
        }

        svgBytes = abi.encodePacked( 
            svgBytes,
            '<path class="h" d="M322.52 112.5h-20a1 1 0 00-1 1v20a1 1 0 001 1h20a1 1 0 001-1v-20a1 1 0 00-1-1zm-4 9l-5.33 5.33a1 1 0 01-.71.3 1 1 0 01-.71-.3l-5.33-5.33a1 1 0 011.41-1.41l4.63 4.62 4.62-4.62a1 1 0 011.42 0 1 1 0 01.04 1.45zM38.65 215l-5.74-4.85-1.19 1.42a4.68 4.68 0 00-5.65.73l9.93 9.93a4.66 4.66 0 00.74-5.64z"/><path class="h" d="M51.55 210.92a4.59 4.59 0 00-2.32.63l-20-23.71h-8.76v8.74l23.71 20a4.68 4.68 0 00.74 5.63l9.94-9.94a4.66 4.66 0 00-3.31-1.35zM33 202l-8.36-8.37L26.3 192l8.37 8.36zm23.75 18.81l-3.54-3.55-3.32 3.32 3.55 3.54v3.72h7.03v-7.03h-3.72zm-29.02-3.55l-3.55 3.55h-3.71v7.03h7.03v-3.72l3.54-3.54-3.31-3.32z"/><path class="h" d="M51.72 187.84L42 199.36l6.31 7.48 12.16-10.25v-8.75zM47.93 202l-1.66-1.66 8.36-8.34 1.66 1.65zm-7.46 68.15l-17 5.14v12.83c0 8.34 6.89 17.4 17 22.77 10.11-5.37 17-14.43 17-22.77v-12.83zm0 37.81C31.78 302.94 26 295.1 26 288.12v-10.93l14.44-4.35zm-7 39.71c-2.69 14.61-4.87 16.79-19.47 19.48 14.61 2.69 16.79 4.87 19.48 19.48 2.69-14.61 4.87-16.79 19.47-19.48-14.61-2.69-16.79-4.87-19.48-19.48zm21.14 27.41c-1.71 9.29-3.1 10.67-12.39 12.38 9.29 1.71 10.68 3.1 12.39 12.39 1.71-9.29 3.09-10.68 12.38-12.39-9.29-1.71-10.67-3.09-12.38-12.38zM34.51 470l2.23 2 2.54 2.17a1.87 1.87 0 001.19.44 1.83 1.83 0 001.19-.44l2.57-2.17c5-4.39 8.82-7.75 11.56-11 3.19-3.83 4.68-7.3 4.68-10.9a11.6 11.6 0 00-11.79-11.7 12.84 12.84 0 00-8.19 3 12.81 12.81 0 00-8.18-3A11.6 11.6 0 0020.49 450c0 7.91 5.58 12.73 14.02 20zm-1.29-17.12h4.85v-4.78h4.85v4.78h4.85v4.77h-4.85v4.77h-4.85v-4.77h-4.85v-4.77z"/>',
            '<path fill="#',
            sheetColorCode,
            '" d="M0 0h500v84.33H0z"/>',
            '<text transform="translate(16.72 133.17)" font-family="Arial-BoldMT,Arial" font-weight="700" font-size="27">',
            _flavorTexts[0],
            '</text><text transform="translate(16.72 51.83)" font-family="Arial-BoldMT,Arial" font-weight="700" font-size="27" fill="#fff">',
            '#',
            Strings.toString(_tokenId),
            '</text></svg>'
        );

        string memory svgString = string(svgBytes);

        return svgString;
    }

    /// @dev Get metadata attributes for provided stats -- string must be created in pieces to avoid STACK TOO DEEP error
    /// @param _stats The Sheet fighter's stats
    /// @return String containing a JSON array of attribute objects, following metadata standard
    function _getAttributes(FighterStats memory _stats) internal view returns(string memory) {

        // Openning list bracket
        string memory attributes = "[";

        // HP object
        attributes = string(
            abi.encodePacked(
                attributes,
                '{"trait_type":"HP",',
                '"value":', 
                Strings.toString(_stats.HP), 
                '},'
            )
        );
        
        // Attack object 
        attributes = string(
            abi.encodePacked(
                attributes,
                '{"trait_type":"Attack",',
                '"value":', 
                Strings.toString(_stats.attack), 
                '},'
            )
        );

        // Defense object
        attributes = string(
            abi.encodePacked(
                attributes,
                '{"trait_type":"Defense",',
                '"value":', 
                Strings.toString(_stats.defense), 
                '},'
            )
        );

        // Critical object
        attributes = string(
            abi.encodePacked(
                attributes,
                '{"trait_type":"Critical",',
                '"value":', 
                Strings.toString(_stats.critical), 
                '},'
            )
        );

        // Heal object
        attributes = string(
            abi.encodePacked(
                attributes,
                '{"trait_type":"Heal",',
                '"value":', 
                Strings.toString(_stats.heal), 
                '},'
            )
        );

        // Number of highlighted cells

        uint8 numHighlightedCells = 0;
        if(isRareStat(_stats.attack, MIN_ATTACK, MAX_ATTACK)) numHighlightedCells++;
        if(isRareStat(_stats.defense, MIN_DEFENSE, MAX_DEFENSE)) numHighlightedCells++;
        if(isRareStat(_stats.critical, MIN_CRITICAL, MAX_CRITICAL)) numHighlightedCells++;
        if(isRareStat(_stats.heal, MIN_HEAL, MAX_HEAL)) numHighlightedCells++;

        attributes = string(
            abi.encodePacked(
                attributes,
                '{"trait_type": "Highlighted Cells",',
                '"value":',
                Strings.toString(numHighlightedCells),
                '},'
            )
        );

        // Job title

        string memory jobTitle;
        if(numHighlightedCells == 0) jobTitle = "Intern";
        else if(numHighlightedCells == 1) jobTitle = "Associate";
        else if(numHighlightedCells == 2) jobTitle = "Manager";
        else if(numHighlightedCells == 3) jobTitle = "Director";
        else if(numHighlightedCells == 4) jobTitle = "Vice President";

        attributes = string(
            abi.encodePacked(
                attributes,
                '{"trait_type": "Job Title",',
                '"value":"',
                jobTitle,
                '"},'
            )
        );

        // Paper Stock

        string memory paperStock;
        if(_stats.stock == PaperStock.GLOSSY) paperStock = "Glossy";
        else if(_stats.stock == PaperStock.MATTE) paperStock = "Matte";
        else if(_stats.stock == PaperStock.SATIN) paperStock = "Satin";

        attributes = string(
            abi.encodePacked(
                attributes,
                '{"trait_type": "Paper Stock",',
                '"value":"',
                paperStock,
                '"},'
            )
        );


        // Sheet color object
        string memory sheetColorString;
        if(_stats.color == SheetColor.RED) {
            sheetColorString = 'Red';
        } else if(_stats.color == SheetColor.GREEN) {
            sheetColorString = 'Green';
        } else if(_stats.color == SheetColor.ORANGE) {
            sheetColorString = 'Orange';
        } else if(_stats.color == SheetColor.PINK) {
            sheetColorString = 'Pink';
        } else if(_stats.color == SheetColor.PURPLE) {
            sheetColorString = 'Purple';
        } else {
            sheetColorString = 'Blue';
        }

        attributes = string(
            abi.encodePacked(
                attributes,
                '{"trait_type":"Color",',
                '"value":"', 
                sheetColorString,
                '"},'
            )
        );

        // Paperstock
        attributes = string(
            abi.encodePacked(
                attributes,
                '{"trait_type": "Sheet Type",',
                '"value":"Genesis"}'
            )
        );

        // Closing bracket
        // NOTE: Make sure object ABOVE this closing bracket doesn't have a trailing comma
        attributes = string(
            abi.encodePacked(
                attributes,
                ']'
            )
        );

        return attributes;
    }
}