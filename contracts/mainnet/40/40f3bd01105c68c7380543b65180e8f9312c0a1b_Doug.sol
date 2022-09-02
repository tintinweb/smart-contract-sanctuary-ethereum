/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// File: @openzeppelin/contracts/utils/Strings.sol

// SPDX-License-Identifier: MIT AND UNLICENSED

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol

// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
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
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

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
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
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
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Address.sol

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

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;







/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
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
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
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
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
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
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
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
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: contracts/Ownable.sol


pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Ownable
 * @dev track owner
 */
contract Ownable {
    address internal _owner;

    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == _owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Set owner's address
     */
    constructor(address owner) {
        _owner = owner;
    }
}

// File: contracts/DutchAuction.sol


pragma solidity >=0.8.0 <0.9.0;

contract DutchAuction {
    uint256 internal _initialPrice;
    uint256 internal _minPrice;
    uint256 internal _step;
    uint256 public startedAt;
    uint256 public finalPrice;

    constructor(
        uint256 initialPrice,
        uint256 minPrice,
        uint256 step,
        uint256 startTime
    ) {
        _initialPrice = initialPrice;
        _minPrice = minPrice;
        _step = step;
        startedAt = startTime;
        finalPrice = minPrice;
    }

    function currentPrice() public view returns (uint256) {
        if (block.timestamp < startedAt) return _initialPrice;

        uint256 delta = block.timestamp - startedAt;
        uint256 thirtyMinuteDecrease = (delta / (30 * 60)) * _step;
        if (thirtyMinuteDecrease >= _initialPrice) {
            return _minPrice;
        }
        uint256 price = _initialPrice - thirtyMinuteDecrease;
        if (price < _minPrice) {
            return _minPrice;
        }
        return price;
    }
}

// File: contracts/DougTag.sol


pragma solidity >=0.8.0 <0.9.0;

/**
 * @title DougTag
 * @dev DougTag NFT
 */
contract DougTag is Ownable, ERC721 {
    string private _uri;
    mapping(uint256 => uint8) private _types;
    mapping(uint256 => uint8) private _ranks;
    mapping(uint256 => uint8) private _sequenceNumbers;
    uint256 private _tokenCounter;
    address private _doug;

    constructor(address _owner) ERC721("DougTag", "DOUG_TAG") Ownable(_owner) {
        _doug = msg.sender;
    }

    function getDougType(uint256 tokenId) public view returns (uint8) {
        require(_exists(tokenId), "DougTag: token doesn't exist");
        return _types[tokenId];
    }

    function mint(
        address to,
        uint8 dougType,
        uint8 dougRank,
        uint8 sequenceNumber
    ) public {
        require(msg.sender == _doug, "DougTag: Not Doug");
        _tokenCounter++;
        _types[_tokenCounter] = dougType;
        _ranks[_tokenCounter] = dougRank;
        _sequenceNumbers[_tokenCounter] = sequenceNumber;

        _safeMint(to, _tokenCounter);
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function reveal(string memory baseURI) public {
        require(msg.sender == _doug, "DougTag: Not Doug");
        _uri = baseURI;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();

        string memory dougType = Strings.toString(_types[tokenId]);
        string memory rank = Strings.toString(_ranks[tokenId]);
        string memory sequenceNumber = Strings.toString(_ranks[tokenId]);
        bytes memory fullUri = abi.encodePacked(
            baseURI,
            "doug_tag_",
            dougType,
            "_",
            rank,
            "_",
            sequenceNumber,
            ".json"
        );
        return string(fullUri);
    }
}

// File: contracts/IDougBank.sol


pragma solidity >=0.8.0 <0.9.0;

uint8 constant LEADERBOARD_SIZE = 8;

interface IDougBank {
    function onTokenMerged(
        uint8 _type,
        uint8 _rank,
        uint256 tokenA,
        uint256 tokenB,
        uint256 merged
    ) external;
}

// File: contracts/IDougToken.sol


pragma solidity >=0.8.0 <0.9.0;

uint8 constant DOUG_TYPES = 100;

interface IDougToken {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function dougType(uint256 tokenId) external view returns (uint8 dougType);

    function dougRank(uint256 tokenId) external view returns (uint8);
}

// File: contracts/Leaderboard.sol


pragma solidity >=0.8.0 <0.9.0;


uint16 constant LEADERBOARD_PTS_TOTAL = 546;
uint32 constant MAX_LEADERBOARD_SCORE = 2097151;

contract Leaderboard {
    uint32[7] private _increments;

    uint8[DOUG_TYPES] public _leaderboard;
    uint32[DOUG_TYPES] public _typeScore; // init to zero
    uint128[DOUG_TYPES] public _typeRoyalties;

    uint8[21] public _leaderboardAmounts;

    uint8[21] private _top20Amounts;
    uint8 private top20Count;
    uint8[21] private _top20TiedAmounts;
    uint8 private completeCount;

    constructor() {
        _increments[1] = 1;
        _increments[2] = 64;
        _increments[3] = 2048;
        _increments[4] = 32768;
        _increments[5] = 262144;
        _increments[6] = 1048576;

        for (uint8 i = 0; i < 100; i++) {
            // the very first entry is not an actual flavor, we use it to find the start of the flavor list
            _leaderboard[i] = i;
        }

        _top20Amounts[0] = 100;
        _top20Amounts[1] = 76;
        _top20Amounts[2] = 60;
        _top20Amounts[3] = 50;
        _top20Amounts[4] = 42;
        _top20Amounts[5] = 36;
        _top20Amounts[6] = 31;
        _top20Amounts[7] = 27;
        _top20Amounts[8] = 23;
        _top20Amounts[9] = 20;
        _top20Amounts[10] = 17;
        _top20Amounts[11] = 14;
        _top20Amounts[12] = 12;
        _top20Amounts[13] = 10;
        _top20Amounts[14] = 8;
        _top20Amounts[15] = 7;
        _top20Amounts[16] = 5;
        _top20Amounts[17] = 4;
        _top20Amounts[18] = 3;
        _top20Amounts[19] = 2;
        _top20Amounts[20] = 0; // have an extra entry to elimate need for a bounds check

        _top20TiedAmounts[0] = 100;
        _top20TiedAmounts[1] = 88;
        _top20TiedAmounts[2] = 78;
        _top20TiedAmounts[3] = 71;
        _top20TiedAmounts[4] = 65;
        _top20TiedAmounts[5] = 60;
        _top20TiedAmounts[6] = 56;
        _top20TiedAmounts[7] = 53;
        _top20TiedAmounts[8] = 49;
        _top20TiedAmounts[9] = 46;
        _top20TiedAmounts[10] = 43;
        _top20TiedAmounts[11] = 41;
        _top20TiedAmounts[12] = 39;
        _top20TiedAmounts[13] = 36;
        _top20TiedAmounts[14] = 35;
        _top20TiedAmounts[15] = 33;
        _top20TiedAmounts[16] = 31;
        _top20TiedAmounts[17] = 30;
        _top20TiedAmounts[18] = 28;
        _top20TiedAmounts[19] = 27;
        _top20TiedAmounts[20] = 0; // last entry (21st place ) stops the top20 Bonus altogether
    }

    function updateLeaderboard(uint8 _rank, uint8 _type) internal {
        uint32 _delta = _increments[_rank];

        uint32 _newTypeScore = _typeScore[_type] + _delta;

        _typeScore[_type] = _newTypeScore;

        // Activate each of the leaderboard top20 payout slots as each of the first 20 types enter the top20

        if (_newTypeScore == 1) {
            if (top20Count < 20) {
                _leaderboardAmounts[top20Count] = _top20Amounts[top20Count];
                top20Count++;
            }
        }

        // Flatten Top20 rewards when top spot is tied
        // When all 20 are tied, top20 rewards go to 0 and
        // so top20 portion will now distributes across all 100 Doug Flavors

        if (_newTypeScore == MAX_LEADERBOARD_SCORE) {
            if (completeCount < 21) {
                completeCount++;
                for (uint8 i = completeCount; i > 0; i--) {
                    _leaderboardAmounts[i - 1] = _top20TiedAmounts[completeCount - 1];
                }
            }
        }

        // Scan list backward (0 is highest score) from current position copying forward until we find new position
        // Also copy forward the array of _typeRoyalties each time
        // (At the start this may take up to 99 iterations)

        uint8 pos = leaderboardPosition(_type); // find where this type is in the leaderboard (0 is highest)
        uint128 thisRoyalty = _typeRoyalties[pos];

        while (pos > 0) {
            // only check/loop while current pos is not the highest
            uint8 nextType = _leaderboard[pos - 1];
            if (_newTypeScore > _typeScore[nextType]) {
                _leaderboard[pos] = nextType; // relocate the exisitng type that *was* higher in the leaderboard
                _typeRoyalties[pos] = _typeRoyalties[pos - 1]; // relocate the coreespnding Royalty total
            } else {
                break;
            }
            pos--;
        }
        _leaderboard[pos] = _type;
        _typeRoyalties[pos] = thisRoyalty;
    }

    function typeScores() public view returns (uint32[100] memory) {
        return _typeScore;
    }

    function leaderboard() public view returns (uint8[DOUG_TYPES] memory) {
        return _leaderboard;
    }

    function leaderboardPosition(uint8 _type) public view returns (uint8) {
        uint8 pos = 0;
        while (_leaderboard[pos] != _type) {
            pos++;
        }
        return pos;
    }
}

// File: contracts/DougBank.sol


pragma solidity >=0.8.0 <0.9.0;



contract DougBank is Ownable, Leaderboard, IDougBank {
    uint256 public devRoyalties;
    uint256 public commonRoyalties;
    uint256 public undistributedRoyalties;
    IDougToken private _token;
    mapping(uint256 => uint256) public _withdrawals;
    uint16[7] private _rankShareRatio = [2, 5, 12, 28, 64, 144, 320];

    constructor(address tokenAddress, address owner) payable Ownable(owner) {
        _token = IDougToken(tokenAddress);
        for (uint8 i = 0; i < DOUG_TYPES; i++) {
            _typeRoyalties[i] = 1;
        }
    }

    receive() external payable {
        uint256 _devShare = (msg.value * 20) / 100;
        uint256 _communityShare = msg.value - _devShare;

        devRoyalties += _devShare;
        uint256 _highScoreShare = _communityShare >> (1);
        uint256 distributionPerPoint = _highScoreShare / LEADERBOARD_PTS_TOTAL;

        uint256 _disbursed;

        // Plough through the top20 of the ordered leaderboard allocating the bonus royalty share

        for (uint256 i = 0; i < 20; i++) {
            uint8 points = _leaderboardAmounts[i];
            uint128 _typeShare = uint128(distributionPerPoint * points);

            _typeRoyalties[i] += _typeShare;
            _disbursed += _typeShare;
        }

        commonRoyalties += _communityShare - _disbursed;
    }

    function onTokenMerged(
        uint8 _type,
        uint8 _rank,
        uint256 tokenA,
        uint256 tokenB,
        uint256 merged
    ) external override {
        require(msg.sender == address(_token), "DougBank: invalid sender");
        updateLeaderboard(_rank, _type);

        _withdrawals[merged] = _withdrawals[tokenA] + _withdrawals[tokenB];
    }

    function tokenBalance(uint256 tokenId) public view returns (uint256) {
        uint8 _dougType = _token.dougType(tokenId);
        uint8 _dougRank = _token.dougRank(tokenId);

        uint8 _position = leaderboardPosition(_dougType);
        uint256 _typeShare = _typeRoyalties[_position];
        uint256 _totalTypeRoyalties = _typeShare + commonRoyalties / 100;
        uint256 _tokenRoyalties = (_totalTypeRoyalties * _rankShareRatio[_dougRank]) / 575;
        return _tokenRoyalties - _withdrawals[tokenId];
    }

    function tokenBalanceMany(uint256[] memory tokenIds) public view returns (uint256) {
        address _tokenOwnerFirst = _token.ownerOf(tokenIds[0]);
        require(_tokenOwnerFirst == msg.sender, "DougBank: not owner of token");
        uint256 _available = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address _tokenOwner = _token.ownerOf(tokenId);
            require(_tokenOwner == _tokenOwnerFirst, "DougBank: not owner of token");
            uint256 _tokenAvailable = tokenBalance(tokenId);
            _available += _tokenAvailable;
        }

        return _available;
    }

    function transferTokenBalance(uint256 tokenId) public {
        address _tokenOwner = _token.ownerOf(tokenId);
        require(_tokenOwner == msg.sender, "DougBank: not owner of token");
        address payable _to = payable(_tokenOwner);
        uint256 _available = tokenBalance(tokenId);
        _withdrawals[tokenId] += _available;

        _to.transfer(_available);
    }

    function transferTokenBalanceMany(uint256[] memory tokenIds) public {
        address _tokenOwnerFirst = _token.ownerOf(tokenIds[0]);
        require(_tokenOwnerFirst == msg.sender, "DougBank: not owner of token");
        address payable _to = payable(_tokenOwnerFirst);
        uint256 _available = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address _tokenOwner = _token.ownerOf(tokenId);
            require(_tokenOwner == _tokenOwnerFirst, "DougBank: not owner of token");
            uint256 _tokenAvailable = tokenBalance(tokenId);
            _withdrawals[tokenId] += _tokenAvailable;
            _available += _tokenAvailable;
        }

        _to.transfer(_available);
    }

    function withdrawDeveloperRoyalties(address toAddress) public isOwner {
        uint256 _amount = devRoyalties;
        devRoyalties = 0;
        address payable _to = payable(toAddress);
        _to.transfer(_amount);
    }

    function withdrawAll() public isOwner {
        address payable _to = payable(_owner);
        uint256 _amount = address(this).balance;
        _to.transfer(_amount);
    }
}

// File: contracts/Doug.sol


pragma solidity >=0.8.0 <0.9.0;






uint8 constant MAX_SUPPLY_PER_TYPE = 127;
uint8 constant MAX_TOKENS_PER_REQUEST = 5;

/**
 * @title Doug
 * @dev Doug NFT
 */
contract Doug is Ownable, DutchAuction, ERC721, IDougToken {
    string private _uri;
    bool public revealed;
    bool public isFrozen;
    DougBank private _bank;
    DougTag private _tags;
    address private immutable _signer;
    mapping(uint256 => uint8) private _dougTypes;
    mapping(uint256 => uint8) private _dougRanks;
    mapping(uint256 => uint8) private _dougSeqNos;
    uint8[MAX_SUPPLY_PER_TYPE] private _tumblers;
    uint8[DOUG_TYPES][7] private _dougCounts;

    uint256 private _reserveMax;
    uint256 private _mergeCounter = 12700;
    uint256 private _mintCounter;
    uint256 private _invitePrice;
    uint256 private _inviteStartTime;

    constructor(
        string memory baseURI,
        address signer,
        uint256 invitePrice,
        uint256 reserveMax,
        uint256 initialPrice,
        uint256 minPrice,
        uint256 step,
        uint256 inviteStartTime,
        uint256 startTime
    )
        payable
        ERC721("Doug", "DOUG")
        DutchAuction(initialPrice, minPrice, step, startTime)
        Ownable(msg.sender)
    {
        _uri = baseURI;
        _signer = signer;
        _invitePrice = invitePrice;
        _reserveMax = reserveMax;
        _inviteStartTime = inviteStartTime;
        _tags = new DougTag(msg.sender);
        _bank = (new DougBank){value: msg.value}(address(this), msg.sender);
    }

    function dougsMinted() public view returns (uint256) {
        return _mintCounter;
    }

    function dougsRemaining() public view returns (uint256) {
        return 12700 - _mintCounter;
    }

    function getInviteStartTime() public view returns (uint256) {
        return _inviteStartTime;
    }

    function getInvitePrice() public view returns (uint256) {
        return _invitePrice;
    }

    function mintWithInvite(bytes memory nonce, bytes memory signature) public payable {
        require(msg.value >= _invitePrice, "Doug: incorrect price");
        require(_mintCounter >= _reserveMax, "Doug: reserve mint is incomplete");
        require(block.timestamp >= _inviteStartTime, "Doug: invites are not open");
        require(block.timestamp < startedAt, "Doug: auction already started");
        bytes memory message = abi.encodePacked(msg.sender, nonce);
        require(_signatureValid(message, signature), "Doug: invalid signature");
        _mint();
    }

    function mint(uint8 amount) public payable {
        require(amount <= MAX_TOKENS_PER_REQUEST, "Doug: unable to mint that many");
        require(msg.value >= currentPrice() * amount, "Doug: incorrect price");
        require(_mintCounter >= _reserveMax, "Doug: reserve mint is incomplete");
        require(block.timestamp >= startedAt, "Doug: auction has not started");

        for (uint8 i = 0; i < amount; i++) {
            _mint();
        }
    }

    function _mint() internal {
        require(_mintCounter < 12700, "Doug: no more supply");
        _mintCounter++;
        _dougRanks[_mintCounter] = 0;
        _safeMint(msg.sender, _mintCounter);
    }

    function merge(uint256 tokenA, uint256 tokenB) public {
        require(isFrozen, "Doug: merge not allowed");
        require(tokenA != tokenB, "Doug: can't merge with itself");
        require(ownerOf(tokenA) == msg.sender, "Doug: not owner of 1st token");
        require(ownerOf(tokenB) == msg.sender, "Doug: not owner of 2nd token");
        uint8 _dougRank = _dougRanks[tokenA];
        require(_dougRank == _dougRanks[tokenB], "Doug: rank mismatch");
        uint8 _dougType = dougType(tokenA);
        require(_dougType == dougType(tokenB), "Doug: type mismatch");
        uint8 _newRank = _dougRank + 1;

        uint8 tokenASequenceNumber = dougSequenceNumber(tokenA);
        uint8 tokenBSequenceNumber = dougSequenceNumber(tokenB);

        _burn(tokenA);
        _burn(tokenB);
        _mergeCounter++;
        uint256 tokenId = _mergeCounter;
        _dougRanks[tokenId] = _newRank;
        _dougTypes[tokenId] = _dougType;
        _dougSeqNos[tokenId] = _dougCounts[_newRank][_dougType];
        _dougCounts[_newRank][_dougType]++;

        _safeMint(msg.sender, tokenId);
        _tags.mint(msg.sender, _dougType, _dougRank, tokenASequenceNumber);
        _tags.mint(msg.sender, _dougType, _dougRank, tokenBSequenceNumber);

        _bank.onTokenMerged(_dougType, _newRank, tokenA, tokenB, tokenId);
    }

    function _signatureValid(bytes memory message, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(message);
        return _signer == ECDSA.recover(messageHash, signature);
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();

        // If post reveal
        if (revealed) {
            string memory seqNo = Strings.toString(dougSequenceNumber(tokenId));
            string memory rank = Strings.toString(_dougRanks[tokenId]);
            string memory tokenType = Strings.toString(dougType(tokenId));
            bytes memory fullUri = abi.encodePacked(
                baseURI,
                "doug_",
                tokenType,
                "_",
                rank,
                "_",
                seqNo,
                ".json"
            );
            return bytes(baseURI).length > 0 ? string(fullUri) : "";
        }

        // pre-reveal
        string memory tokenStr = Strings.toString(tokenId);
        bytes memory placeholderUri = abi.encodePacked(baseURI, "pre_doug_", tokenStr, ".json");
        return bytes(baseURI).length > 0 ? string(placeholderUri) : "";
    }

    function ownerOf(uint256 tokenId) public view override(ERC721, IDougToken) returns (address) {
        return ERC721.ownerOf(tokenId);
    }

    function randomNumber(uint8 max, uint8 index) internal view returns (uint8) {
        uint256 k = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, index)));
        return uint8(k % max);
    }

    function dougType(uint256 tokenId) public view returns (uint8) {
        if (_dougRanks[tokenId] > 0) {
            return _dougTypes[tokenId];
        }

        uint8 tumblerNumber = uint8(tokenId % MAX_SUPPLY_PER_TYPE);
        uint8 offset = _tumblers[tumblerNumber];
        uint8 tokenType = (uint8(tokenId / MAX_SUPPLY_PER_TYPE) + offset) % DOUG_TYPES;
        return tokenType;
    }

    function dougRank(uint256 tokenId) public view returns (uint8) {
        return _dougRanks[tokenId];
    }

    function dougSequenceNumber(uint256 tokenId) public view returns (uint8) {
        if (_dougRanks[tokenId] > 0) {
            return _dougSeqNos[tokenId];
        }

        return uint8(tokenId % MAX_SUPPLY_PER_TYPE);
    }

    // Admin utilities
    function mintReserve(uint16 amount, address to) public isOwner {
        require(_mintCounter + amount <= _reserveMax, "Doug: amount exceeds reserve max");
        require(_mintCounter + amount <= 12700, "Doug: no more supply");
        uint256 newTokenId = _mintCounter;
        unchecked {
            for (uint16 i = 0; i < amount; i++) {
                newTokenId++;
                _mint(to, newTokenId);
            }
        }

        _mintCounter = newTokenId;
    }

    function reveal(string memory baseURI) public isOwner {
        require(!isFrozen, "Doug: Cannot reveal after freeze");

        _uri = baseURI;
        revealed = true;

        // Assign Doug Type Tumblers
        for (uint8 i = 0; i < MAX_SUPPLY_PER_TYPE; i++) {
            _tumblers[i] = randomNumber(MAX_SUPPLY_PER_TYPE, i);
        }

        _tags.reveal(baseURI);
    }

    function mergeAllowed() public view returns (bool) {
        return isFrozen;
    }

    function withdrawAll() public isOwner {
        address payable _to = payable(_owner);
        uint256 _balance = address(this).balance;
        _to.transfer(_balance);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function tagsContract() external view returns (address) {
        return address(_tags);
    }

    function bankContract() external view returns (address) {
        return address(_bank);
    }

    function freeze() public isOwner {
        isFrozen = true;
    }

    function setInviteStartTime(uint256 inviteStartTime) public isOwner {
        _inviteStartTime = inviteStartTime;
    }

    function setAuctionDetails(
        uint256 initialPrice,
        uint256 minPrice,
        uint256 step,
        uint256 startTime
    ) public isOwner {
        _initialPrice = initialPrice;
        _minPrice = minPrice;
        _step = step;
        startedAt = startTime;
    }
}