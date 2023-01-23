// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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
            /// @solidity memory-safe-assembly
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
            /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

// import "hardhat/console.sol";

contract TradeCoinMultiSig is EIP712 {
    using Address for address;

    // event MultiSigCreated(address indexed financier, address indexed borrower);
    event CollateralGatheredFromFactory(address indexed gatherer);
    event AddedCollateralToMultisig(
        address supplier,
        uint256[] tokenIds,
        bool isProduct
    );
    event SubFinancierAdded(address subfinancier);
    event SubFinancierRemoved(address subfinancier);
    event SelectorApprovalSet(bytes4 selector, Approval approval);
    event AutoTransactionExecuted(
        address indexed caller,
        bool isProduct,
        bytes data
    );

    // event TransactionAddedToQueue(
    //     address indexed initializer,
    //     uint256 indexed txId,
    //     address to,
    //     uint256 value,
    //     bytes data
    // );
    // event TransactionApproved(address indexed approver, uint256 indexed txId);
    // event TransactionExecuted(address indexed caller, uint256 indexed txId);

    event TransactionExecutedWithSignature(
        address indexed signer,
        address indexed caller
    );

    event ChangeTemporarySelectorForFinancier(
        bytes4 selector,
        Approval approval
    );
    event ChangeTemporarySelectorForBorrower(
        bytes4 selector,
        Approval approval
    );

    event DrainMultiSig(address indexed caller, address indexed destination);

    address public immutable factoryAddress;

    address public immutable financier;
    address public immutable borrower;
    address public immutable drainer;

    address public immutable tradeCoinProductAddress;
    address public immutable tradeCoinCompositionAddress;

    uint256 public txCounter = 0;

    address[] public subFinanciers;
    uint256[] public productCollateral;
    uint256[] public compositionCollateral;

    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256(
            "Permit(address tradeCoinSigner,address tradeCoinContract,uint256 value,bytes data,uint256 nonce,uint256 deadline)"
        );

    //TODO: consider whether this is needed
    enum Approval {
        Needs_Approval,
        Auto_Approved
    }

    struct Transaction {
        bool executed;
        bool approved;
        address to;
        address initializer;
        uint256 value;
        bytes data;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    modifier isFinancier() {
        require(msg.sender == financier, "You are not the financier");
        _;
    }

    modifier isBorrower() {
        require(msg.sender == borrower, "You are not the borrower");
        _;
    }

    modifier isBorrowerOrFinancier() {
        require(
            msg.sender == financier || msg.sender == borrower,
            "Address is not part of this multi-sig"
        );
        _;
    }

    modifier isAutoApproved(bytes memory data) {
        bytes4 selector = bytes4(data);
        if (msg.sender == financier) {
            require(
                selectorApprovalForFinancier[selector] ==
                    Approval.Auto_Approved ||
                    temporaryApprovalSelectorForFinancier[selector] ==
                    Approval.Auto_Approved,
                "Transaction needs approval"
            );
        } else {
            //if (msg.sender == borrower) {
            require(
                selectorApprovalForBorrower[selector] ==
                    Approval.Auto_Approved ||
                    temporaryApprovalSelectorForBorrower[selector] ==
                    Approval.Auto_Approved,
                "Transaction needs approval"
            );
        } //else {
        // revert("Access denied");
        //}
        _;
    }

    modifier isApprovedInQueue(uint256 txId) {
        require(
            !transactionQueue[txId].executed && transactionQueue[txId].approved,
            "Transaction already executed or not approved"
        );
        _;
    }

    mapping(uint256 => Transaction) public transactionQueue;
    mapping(bytes4 => Approval) public selectorApprovalForBorrower;
    mapping(bytes4 => Approval) public selectorApprovalForFinancier;

    mapping(bytes4 => Approval) public temporaryApprovalSelectorForBorrower;
    mapping(bytes4 => Approval) public temporaryApprovalSelectorForFinancier;

    mapping(address => uint256) public nonces;

    constructor(
        address _factoryAddress,
        address _financier,
        address _borrower,
        address _drainer,
        address[] memory _subFinanciers,
        bytes4[] memory _defaultAutoApproveForFinancier,
        bytes4[] memory _defaultAutoApproveForBorrower,
        uint256[] memory _tradeCoinProduct,
        uint256[] memory _tradeCoinComposition,
        address _tradeCoinProductAddress,
        address _tradeCoinCompositionAddress
    ) EIP712("TradeCoin Multi-Sig", "1") {
        factoryAddress = _factoryAddress;
        financier = _financier;
        borrower = _borrower;
        drainer = _drainer;

        tradeCoinProductAddress = _tradeCoinProductAddress;
        tradeCoinCompositionAddress = _tradeCoinCompositionAddress;

        subFinanciers = _subFinanciers;
        productCollateral = _tradeCoinProduct;
        compositionCollateral = _tradeCoinComposition;

        for (uint256 i; i < _defaultAutoApproveForBorrower.length; i++) {
            selectorApprovalForBorrower[
                _defaultAutoApproveForBorrower[i]
            ] = Approval.Auto_Approved;
        }

        for (uint256 i; i < _defaultAutoApproveForFinancier.length; i++) {
            selectorApprovalForFinancier[
                _defaultAutoApproveForFinancier[i]
            ] = Approval.Auto_Approved;
        }
    }

    function gatherAllCollateral() external {
        _transferCollateral(
            tradeCoinProductAddress,
            factoryAddress,
            address(this),
            productCollateral
        );

        _transferCollateral(
            tradeCoinCompositionAddress,
            factoryAddress,
            address(this),
            compositionCollateral
        );

        emit CollateralGatheredFromFactory(msg.sender);
    }

    function addSubFinancier(address newSubFinancier) external isFinancier {
        subFinanciers.push(newSubFinancier);

        emit SubFinancierAdded(newSubFinancier);
    }

    function removeSubFinancier(uint256 indexOfSubfinancier)
        external
        isFinancier
    {
        address removedSubFinancier = subFinanciers[indexOfSubfinancier];
        uint256 indexOfLastItem = subFinanciers.length - 1;

        subFinanciers[indexOfSubfinancier] = subFinanciers[indexOfLastItem];
        subFinanciers.pop();

        emit SubFinancierRemoved(removedSubFinancier);
    }

    function executeAutoFunctionByBorrower(bytes calldata data, bool isProduct)
        external
        isAutoApproved(data)
        isBorrower
    {
        address to = isProduct
            ? tradeCoinProductAddress
            : tradeCoinCompositionAddress;

        _callFunction(to, 0, data);

        emit AutoTransactionExecuted(borrower, isProduct, data);
    }

    function executeAutoFunctionByFinancier(bytes calldata data, bool isProduct)
        external
        isAutoApproved(data)
        isFinancier
    {
        address to = isProduct
            ? tradeCoinProductAddress
            : tradeCoinCompositionAddress;

        _callFunction(to, 0, data);

        emit AutoTransactionExecuted(financier, isProduct, data);
    }

    function changeTemporarySelectorForBorrower(
        bytes4 selector,
        Approval approval
    ) external isFinancier {
        temporaryApprovalSelectorForBorrower[selector] = approval;

        emit ChangeTemporarySelectorForBorrower(selector, approval);
    }

    function changeTemporarySelectorForFinancier(
        bytes4 selector,
        Approval approval
    ) external isBorrower {
        temporaryApprovalSelectorForFinancier[selector] = approval;

        emit ChangeTemporarySelectorForFinancier(selector, approval);
    }

    // function addTransactionToQueue(
    //     address _to,
    //     uint256 _value,
    //     bytes memory _data
    // ) external isBorrowerOrFinancier {
    //     require(_to != address(0), "Can't call a zero address");

    //     transactionQueue[txCounter] = Transaction({
    //         to: _to,
    //         value: _value,
    //         data: _data,
    //         executed: false,
    //         approved: false,
    //         initializer: msg.sender
    //     });

    //     emit TransactionAddedToQueue(msg.sender, txCounter, _to, _value, _data);
    //     txCounter += 1;
    // }

    // function approveTransactionInQueue(uint256 txId)
    //     external
    //     isBorrowerOrFinancier
    // {
    //     address _initializer = transactionQueue[txId].initializer;
    //     require(_initializer != address(0), "Transaction is empty");
    //     require(
    //         !(msg.sender == _initializer),
    //         "The initializer can't approve their transaction"
    //     );

    //     transactionQueue[txId].approved = true;

    //     emit TransactionApproved(msg.sender, txId);
    // }

    // function executeFunctionInQueue(uint256 txId)
    //     external
    //     isApprovedInQueue(txId)
    // {
    //     address _initializer = transactionQueue[txId].initializer;
    //     require(_initializer != address(0), "Transaction is empty");
    //     require(
    //         (msg.sender == _initializer),
    //         "The _initializer can't approve their transaction"
    //     );

    //     Transaction storage transaction = transactionQueue[txId];

    //     transaction.executed = true;
    //     _callFunction(transaction.to, transaction.value, transaction.data);

    //     emit TransactionExecuted(_initializer, txId);
    // }

    function executeFunctionWithSignature(
        address tradeCoinSigner,
        address tradeCoinContract,
        uint256 value,
        bytes memory data,
        uint256 deadline,
        Signature memory signature
    ) external isBorrowerOrFinancier {
        require(block.timestamp <= deadline, "Deadline expired");
        require(
            tradeCoinSigner == financier || tradeCoinSigner == borrower,
            "The signature is not from a financier or borrower"
        );
        require(
            tradeCoinSigner != msg.sender,
            "Can't use a self signed signature"
        );

        bytes32 hash = getTypedDataHash(
            tradeCoinSigner,
            tradeCoinContract,
            value,
            data,
            deadline
        );

        address signer = ecrecover(hash, signature.v, signature.r, signature.s);

        require(
            signer == tradeCoinSigner,
            "The signature is not from the signer"
        );

        _callFunction(tradeCoinContract, value, data);

        emit TransactionExecutedWithSignature(tradeCoinSigner, msg.sender);
    }

    function getTypedDataHash(
        address tradeCoinSigner,
        address tradeCoinContract,
        uint256 value,
        bytes memory data,
        uint256 deadline
    ) internal returns (bytes32 hash) {
        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                tradeCoinSigner,
                tradeCoinContract,
                value,
                keccak256(abi.encodePacked(data)),
                nonces[tradeCoinSigner],
                deadline
            )
        );

        nonces[tradeCoinSigner]++;

        hash = _hashTypedDataV4(structHash);
    }

    function addCollateral(
        uint256[] calldata tokenIds,
        address supplier,
        bool isProduct
    ) external {
        address tokenContract = isProduct
            ? tradeCoinProductAddress
            : tradeCoinCompositionAddress;

        _transferCollateral(tokenContract, supplier, address(this), tokenIds);

        uint256[] storage tokenCollateral = isProduct
            ? productCollateral
            : compositionCollateral;

        uint256 tokenIdsLength = tokenIds.length;
        for (uint256 i; i < tokenIdsLength; ) {
            tokenCollateral.push(tokenIds[i]);

            unchecked {
                ++i;
            }
        }

        emit AddedCollateralToMultisig(supplier, tokenIds, isProduct);
    }

    function drainMultiSig(address drainTo) external {
        require(msg.sender == drainer, "Address is not the drainer");

        _transferCollateral(
            tradeCoinProductAddress,
            address(this),
            drainTo,
            productCollateral
        );

        _transferCollateral(
            tradeCoinCompositionAddress,
            address(this),
            drainTo,
            compositionCollateral
        );

        emit DrainMultiSig(msg.sender, drainTo);
    }

    function _callFunction(
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        (bool success, bytes memory reason) = to.call{value: value}(data);
        // console.log(success);
        if (!success) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
        require(success, "tx failed");
    }

    function _transferCollateral(
        address tokenContract,
        address from,
        address to,
        uint256[] memory tokenIds
    ) internal {
        uint256 tokensLength = tokenIds.length;
        for (uint256 i; i < tokensLength; ) {
            IERC721(tokenContract).transferFrom(from, to, tokenIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    function getSubFinanciers() external view returns (address[] memory) {
        return subFinanciers;
    }

    function getProductCollateral() external view returns (uint256[] memory) {
        return productCollateral;
    }

    function getCompositionCollateral()
        external
        view
        returns (uint256[] memory)
    {
        return compositionCollateral;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./TradeCoinMultiSig.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

// import "hardhat/console.sol";

contract TradeCoinMultiSigFactory is EIP712 {
    event MultiSigInitialized(
        uint256 indexed multiSigId,
        address indexed financier,
        address indexed borrower,
        address drainer,
        address[] subFinanciers,
        bytes4[] defaultAutoApproveForBorrower,
        bytes4[] defaultAutoApproveForFinancier,
        uint256 deadline
    );

    event MultiSigApprovedByBorrower(
        uint256 indexed multiSigId,
        address indexed borrower
    );

    event MultiSigApprovedByFinancier(
        uint256 indexed multiSigId,
        address indexed financier
    );

    event MultiSigCreated(
        uint256 indexed multiSigId,
        address indexed creator,
        address indexed borrower,
        address multiSig
    );

    event MultiSigCreatedWithSignatures(
        address indexed deployer,
        address indexed financier,
        address indexed borrower,
        address multiSig
    );

    event SuppliedCollateralInBulk(
        uint256 indexed multiSigId,
        address indexed supplier,
        uint256[] productTokens,
        uint256[] compositionTokens
    );

    event SuppliedSingleCollateral(
        uint256 indexed multiSigId,
        address indexed supplier,
        uint256 token,
        bool isProduct
    );

    event WithdrawnAllCollateral(
        uint256 indexed multiSigId,
        address indexed withdrawer,
        uint256[] productTokens,
        uint256[] compositionTokens
    );

    event WithdrawnSingleCollateralToken(
        uint256 indexed multiSigId,
        address indexed withdrawer,
        uint256 tokenId,
        bool isProduct
    );

    struct MultiSigAgreement {
        address financier;
        address borrower;
        address drainer;
        address[] subFinanciers;
        bytes4[] defaultAutoApproveForBorrower;
        bytes4[] defaultAutoApproveForFinancier;
        uint256 deadline;
        Collateral collateral;
    }

    struct Collateral {
        uint256[] tradeCoinProducts;
        uint256[] tradeCoinCompositions;
    }

    struct Approved {
        bool isApprovedByFinancier;
        bool isApprovedByBorrower;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    address public immutable tradeCoinProductAddress;
    address public immutable tradeCoinCompositionAddress;

    uint256 public multiSigCounter = 0;

    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256(
            "Permit(address financier,address borrower,address drainer,address[] subFinanciers,bytes4[] defaultAutoApproveForFinancier,bytes4[] defaultAutoApproveForBorrower,uint256 financierNonce,uint256 borrowerNonce,uint256 deadline)"
        );

    modifier isBorrower(uint256 multiSigId) {
        address borrowerOfId = multiSigAgreements[multiSigId].borrower;

        require(borrowerOfId != address(0), "Query for non-existent agreement");
        require(borrowerOfId == msg.sender, "You are not the borrower");
        _;
    }

    constructor(
        string memory name,
        string memory version,
        address _tradeCoinProductAddress,
        address _tradeCoinCompositionAddress
    ) EIP712(name, version) {
        tradeCoinProductAddress = _tradeCoinProductAddress;
        tradeCoinCompositionAddress = _tradeCoinCompositionAddress;
    }

    mapping(uint256 => MultiSigAgreement) public multiSigAgreements;
    mapping(uint256 => Approved) public multiSigApproval;

    mapping(address => uint256) public nonces;

    function initializeMultiSig(
        address _financier,
        address _borrower,
        address _drainer,
        address[] calldata _subFinanciers,
        bytes4[] calldata _defaultAutoApproveForFinancier,
        bytes4[] calldata _defaultAutoApproveForBorrower,
        uint256 _deadline
    ) external {
        require(
            _financier != address(0) && _borrower != address(0),
            "Financier & borrower can't be a zero address"
        );
        require(
            _deadline > block.timestamp,
            "Deadline must be greater then current"
        );

        uint256 _multiSigCounter = multiSigCounter;

        multiSigAgreements[_multiSigCounter] = MultiSigAgreement({
            financier: _financier,
            borrower: _borrower,
            drainer: _drainer,
            subFinanciers: _subFinanciers,
            defaultAutoApproveForFinancier: _defaultAutoApproveForFinancier,
            defaultAutoApproveForBorrower: _defaultAutoApproveForBorrower,
            deadline: _deadline,
            collateral: Collateral({
                tradeCoinProducts: new uint256[](0),
                tradeCoinCompositions: new uint256[](0)
            })
        });

        multiSigCounter += 1;

        emit MultiSigInitialized(
            _multiSigCounter,
            _financier,
            _borrower,
            _drainer,
            _subFinanciers,
            _defaultAutoApproveForBorrower,
            _defaultAutoApproveForFinancier,
            _deadline
        );
    }

    function supplySingleCollateral(
        uint256 multiSigId,
        uint256[] calldata _token,
        bool isProduct
    ) external {
        require(
            multiSigAgreements[multiSigId].financier != address(0),
            "Multi-Sig non-existent"
        );

        require(
            multiSigAgreements[multiSigId].deadline > block.timestamp,
            "Deadline has expired"
        );

        require(_token.length == 1, "The amount of tokens allowed is one");

        _transferToken(msg.sender, address(this), _token, isProduct);

        _appendCollateral(multiSigId, _token, isProduct);

        emit SuppliedSingleCollateral(
            multiSigId,
            msg.sender,
            _token[0],
            isProduct
        );
    }

    function supplyCollateralInBulk(
        uint256 multiSigId,
        uint256[] calldata _productTokens,
        uint256[] calldata _compositionTokens
    ) external {
        require(
            multiSigAgreements[multiSigId].financier != address(0),
            "Multi-Sig non-existent"
        );

        require(
            multiSigAgreements[multiSigId].deadline > block.timestamp,
            "Deadline has expired"
        );

        _transferToken(msg.sender, address(this), _productTokens, true);

        _appendCollateral(multiSigId, _productTokens, true);

        _transferToken(msg.sender, address(this), _compositionTokens, false);

        _appendCollateral(multiSigId, _compositionTokens, false);

        emit SuppliedCollateralInBulk(
            multiSigId,
            msg.sender,
            _productTokens,
            _compositionTokens
        );
    }

    function withdrawSingleCollateralToken(
        uint256 multiSigId,
        uint256 tokenIndex,
        bool isProduct
    ) external isBorrower(multiSigId) {
        Collateral storage _multiSigColl = multiSigAgreements[multiSigId]
            .collateral;

        if (multiSigAgreements[multiSigId].deadline > block.timestamp) {
            require(
                !multiSigApproval[multiSigId].isApprovedByBorrower,
                "Borrower accepted agreement"
            );
        }

        address tokenAddress = isProduct
            ? tradeCoinProductAddress
            : tradeCoinCompositionAddress;

        uint256[] storage _tokens = isProduct
            ? _multiSigColl.tradeCoinProducts
            : _multiSigColl.tradeCoinCompositions;

        uint256 indexOfLastItem = _tokens.length - 1;
        uint256 tokenId = _tokens[tokenIndex];

        IERC721(tokenAddress).transferFrom(address(this), msg.sender, tokenId);

        _tokens[tokenIndex] = _tokens[indexOfLastItem];
        _tokens.pop();

        emit WithdrawnSingleCollateralToken(
            multiSigId,
            msg.sender,
            tokenId,
            isProduct
        );
    }

    function withdrawAllCollateral(uint256 multiSigId)
        external
        isBorrower(multiSigId)
    {
        Collateral storage _multiSigColl = multiSigAgreements[multiSigId]
            .collateral;

        if (multiSigAgreements[multiSigId].deadline > block.timestamp) {
            require(
                !multiSigApproval[multiSigId].isApprovedByBorrower,
                "Borrower accepted agreement"
            );
        }

        uint256[] memory _products = _multiSigColl.tradeCoinProducts;
        uint256[] memory _compositions = _multiSigColl.tradeCoinCompositions;

        _transferToken(address(this), msg.sender, _products, true);

        _transferToken(address(this), msg.sender, _compositions, false);

        delete _multiSigColl.tradeCoinProducts;
        delete _multiSigColl.tradeCoinCompositions;

        emit WithdrawnAllCollateral(
            multiSigId,
            msg.sender,
            _products,
            _compositions
        );
    }

    function approvalByFinancier(uint256 multiSigId) external {
        require(
            multiSigAgreements[multiSigId].financier == msg.sender,
            "You are not the financier"
        );

        require(
            multiSigAgreements[multiSigId].deadline > block.timestamp,
            "Deadline has expired"
        );

        multiSigApproval[multiSigId].isApprovedByFinancier = true;

        emit MultiSigApprovedByFinancier(multiSigId, msg.sender);
    }

    function approvalByBorrower(uint256 multiSigId)
        external
        isBorrower(multiSigId)
    {
        multiSigApproval[multiSigId].isApprovedByBorrower = true;

        require(
            multiSigAgreements[multiSigId].deadline > block.timestamp,
            "Deadline has expired"
        );

        emit MultiSigApprovedByBorrower(multiSigId, msg.sender);
    }

    function createMultiSig(uint256 multiSigId) external returns (address) {
        MultiSigAgreement memory multiSigAgreementsForId = multiSigAgreements[
            multiSigId
        ];

        require(
            multiSigApproval[multiSigId].isApprovedByBorrower &&
                multiSigApproval[multiSigId].isApprovedByFinancier,
            "The agreement isn't approved by both parties"
        );

        require(
            multiSigAgreements[multiSigId].deadline > block.timestamp,
            "Deadline has expired"
        );

        TradeCoinMultiSig multiSig = new TradeCoinMultiSig(
            address(this),
            multiSigAgreementsForId.financier,
            multiSigAgreementsForId.borrower,
            multiSigAgreementsForId.drainer,
            multiSigAgreementsForId.subFinanciers,
            multiSigAgreementsForId.defaultAutoApproveForFinancier,
            multiSigAgreementsForId.defaultAutoApproveForBorrower,
            multiSigAgreementsForId.collateral.tradeCoinProducts,
            multiSigAgreementsForId.collateral.tradeCoinCompositions,
            tradeCoinProductAddress,
            tradeCoinCompositionAddress
        );

        _approveToken(
            address(multiSig),
            multiSigAgreementsForId.collateral.tradeCoinProducts,
            true
        );

        _approveToken(
            address(multiSig),
            multiSigAgreementsForId.collateral.tradeCoinCompositions,
            false
        );

        emit MultiSigCreated(
            multiSigId,
            multiSigAgreementsForId.financier,
            multiSigAgreementsForId.borrower,
            address(multiSig)
        );

        return address(multiSig);
    }

    function createMultiSigWithSignatures(
        MultiSigAgreement calldata multiSigAgreement,
        Signature memory signatureFromFinancier,
        Signature memory signatureFromBorrower
    ) external returns (address) {
        require(
            block.timestamp <= multiSigAgreement.deadline,
            "Deadline expired"
        );

        bytes32 hash = getTypedDataHash(multiSigAgreement);

        require(
            ecrecover(
                hash,
                signatureFromFinancier.v,
                signatureFromFinancier.r,
                signatureFromFinancier.s
            ) == multiSigAgreement.financier,
            "Not signed by the financier"
        );

        require(
            ecrecover(
                hash,
                signatureFromBorrower.v,
                signatureFromBorrower.r,
                signatureFromBorrower.s
            ) == multiSigAgreement.borrower,
            "Not signed by the borrower"
        );

        TradeCoinMultiSig multiSig = new TradeCoinMultiSig(
            address(this),
            multiSigAgreement.financier,
            multiSigAgreement.borrower,
            multiSigAgreement.drainer,
            multiSigAgreement.subFinanciers,
            multiSigAgreement.defaultAutoApproveForFinancier,
            multiSigAgreement.defaultAutoApproveForBorrower,
            new uint256[](0),
            new uint256[](0),
            tradeCoinProductAddress,
            tradeCoinCompositionAddress
        );

        emit MultiSigCreatedWithSignatures(
            msg.sender,
            multiSigAgreement.financier,
            multiSigAgreement.borrower,
            address(multiSig)
        );

        return address(multiSig);
    }

    function getTypedDataHash(MultiSigAgreement calldata multiSigAgreement)
        internal
        returns (bytes32 hash)
    {
        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                multiSigAgreement.financier,
                multiSigAgreement.borrower,
                multiSigAgreement.drainer,
                keccak256(abi.encodePacked(multiSigAgreement.subFinanciers)),
                keccak256(
                    abi.encodePacked(
                        multiSigAgreement.defaultAutoApproveForFinancier
                    )
                ),
                keccak256(
                    abi.encodePacked(
                        multiSigAgreement.defaultAutoApproveForBorrower
                    )
                ),
                nonces[multiSigAgreement.financier],
                nonces[multiSigAgreement.borrower],
                multiSigAgreement.deadline
            )
        );

        nonces[multiSigAgreement.financier]++;
        nonces[multiSigAgreement.borrower]++;

        hash = _hashTypedDataV4(structHash);
    }

    function _appendCollateral(
        uint256 multiSigId,
        uint256[] calldata _tokens,
        bool isProductAddress
    ) internal {
        uint256[] storage multiSigCollateral = isProductAddress
            ? multiSigAgreements[multiSigId].collateral.tradeCoinProducts
            : multiSigAgreements[multiSigId].collateral.tradeCoinCompositions;

        uint256 lengthProduct = _tokens.length;

        for (uint256 i; i < lengthProduct; ) {
            uint256 productToken = _tokens[i];

            multiSigCollateral.push(productToken);

            unchecked {
                ++i;
            }
        }
    }

    function _transferToken(
        address from,
        address to,
        uint256[] memory _tokens,
        bool isProductAddress
    ) internal {
        address tokenAddress = isProductAddress
            ? tradeCoinProductAddress
            : tradeCoinCompositionAddress;

        uint256 lengthComposition = _tokens.length;

        for (uint256 i; i < lengthComposition; ) {
            uint256 token = _tokens[i];

            IERC721(tokenAddress).transferFrom(from, to, token);

            unchecked {
                ++i;
            }
        }
    }

    function _approveToken(
        address to,
        uint256[] memory _tokens,
        bool isProductAddress
    ) internal {
        address tokenAddress = isProductAddress
            ? tradeCoinProductAddress
            : tradeCoinCompositionAddress;

        uint256 lengthComposition = _tokens.length;

        for (uint256 i; i < lengthComposition; ) {
            uint256 token = _tokens[i];

            IERC721(tokenAddress).approve(to, token);

            unchecked {
                ++i;
            }
        }
    }

    function getSubFinanciers(uint256 multiSigId)
        external
        view
        returns (address[] memory)
    {
        return multiSigAgreements[multiSigId].subFinanciers;
    }

    function getDefaultAutoApproveForBorrower(uint256 multiSigId)
        external
        view
        returns (bytes4[] memory)
    {
        return multiSigAgreements[multiSigId].defaultAutoApproveForBorrower;
    }

    function getDefaultAutoApproveForFinancier(uint256 multiSigId)
        external
        view
        returns (bytes4[] memory)
    {
        return multiSigAgreements[multiSigId].defaultAutoApproveForFinancier;
    }

    function getProductCollateral(uint256 multiSigId)
        external
        view
        returns (uint256[] memory)
    {
        return multiSigAgreements[multiSigId].collateral.tradeCoinProducts;
    }

    function getCompositionCollateral(uint256 multiSigId)
        external
        view
        returns (uint256[] memory)
    {
        return multiSigAgreements[multiSigId].collateral.tradeCoinCompositions;
    }
}