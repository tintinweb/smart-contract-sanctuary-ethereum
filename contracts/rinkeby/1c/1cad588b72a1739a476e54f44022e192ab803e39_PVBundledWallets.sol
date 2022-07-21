/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// File:  @openzeppelin /contracts/token/ERC20/IERC20.sol
//SPDX-License-Identifier: Unlicense
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
pragma solidity ^0.8.0;
/**
–	 @dev  Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
–	 @dev  Emitted when value tokens are moved from one account (from) to
–	another (to).
     *
–	Note that value may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
    /**
–	 @dev  Emitted when the allowance of a spender for an owner is set by
–	a call to {approve}. value is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
    /**
–	 @dev  Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    /**
–	 @dev  Returns the amount of tokens owned by account.
     */
    function balanceOf(address account) external view returns (uint256);
    /**
–	 @dev  Moves amount tokens from the caller's account to to.
     *
–	Returns a boolean value indicating whether the operation succeeded.
     *
–	Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);
    /**
–	 @dev  Returns the remaining number of tokens that spender will be
–	allowed to spend on behalf of owner through {transferFrom}. This is
–	zero by default.
     *
–	This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
    /**
–	 @dev  Sets amount as the allowance of spender over the caller's tokens.
     *
–	Returns a boolean value indicating whether the operation succeeded.
     *
–	IMPORTANT: Beware that changing an allowance with this method brings the risk
–	that someone may use both the old and the new allowance by unfortunate
–	transaction ordering. One possible solution to mitigate this race
–	condition is to first reduce the spender's allowance to 0 and set the
–	desired value afterwards:
–	https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
–	Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);
    /**
–	 @dev  Moves amount tokens from from to to using the
–	allowance mechanism. amount is then deducted from the caller's
–	allowance.
     *
–	Returns a boolean value indicating whether the operation succeeded.
     *
–	Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
// File:  @openzeppelin /contracts/utils/introspection/IERC165.sol
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
pragma solidity ^0.8.0;
/**
–	 @dev  Interface of the ERC165 standard, as defined in the
–	[https://eips.ethereum.org/EIPS/eip-165[EIP]](https://eips.ethereum.org/EIPS/eip-165%5BEIP%5D).
 *
–	Implementers can declare support of contract interfaces, which can then be
–	queried by others ({ERC165Checker}).
 *
–	For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
–	 @dev  Returns true if this contract implements the interface defined by
–	interfaceId. See the corresponding
–	[https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified%5BEIP) section]
–	to learn more about how these ids are created.
     *
–	This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
// File:  @openzeppelin /contracts/token/ERC721/IERC721.sol
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)
pragma solidity ^0.8.0;
/**
–	 @dev  Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
–	 @dev  Emitted when tokenId token is transferred from from to to.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    /**
–	 @dev  Emitted when owner enables approved to manage the tokenId token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    /**
–	 @dev  Emitted when owner enables or disables (approved) operator to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    /**
–	 @dev  Returns the number of tokens in owner's account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);
    /**
–	 @dev  Returns the owner of the tokenId token.
     *
–	Requirements:
     *
–	- tokenId must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
    /**
–	 @dev  Safely transfers tokenId token from from to to.
     *
–	Requirements:
     *
–	- from cannot be the zero address.
–	- to cannot be the zero address.
–	- tokenId token must exist and be owned by from.
–	- If the caller is not from, it must be approved to move this token by either {approve} or {setApprovalForAll}.
–	- If to refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
–	Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    /**
–	 @dev  Safely transfers tokenId token from from to to, checking first that contract recipients
–	are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
–	Requirements:
     *
–	- from cannot be the zero address.
–	- to cannot be the zero address.
–	- tokenId token must exist and be owned by from.
–	- If the caller is not from, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
–	- If to refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
–	Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    /**
–	 @dev  Transfers tokenId token from from to to.
     *
–	WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
–	Requirements:
     *
–	- from cannot be the zero address.
–	- to cannot be the zero address.
–	- tokenId token must be owned by from.
–	- If the caller is not from, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
–	Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    /**
–	 @dev  Gives permission to to to transfer tokenId token to another account.
–	The approval is cleared when the token is transferred.
     *
–	Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
–	Requirements:
     *
–	- The caller must own the token or be an approved operator.
–	- tokenId must exist.
     *
–	Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;
    /**
–	 @dev  Approve or remove operator as an operator for the caller.
–	Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
–	Requirements:
     *
–	- The operator cannot be the caller.
     *
–	Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;
    /**
–	 @dev  Returns the account approved for tokenId token.
     *
–	Requirements:
     *
–	- tokenId must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);
    /**
–	 @dev  Returns if the operator is allowed to manage all of the assets of owner.
     *
–	See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
// File:  @openzeppelin /contracts/token/ERC1155/IERC1155.sol
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)
pragma solidity ^0.8.0;
/**
–	 @dev  Required interface of an ERC1155 compliant contract, as defined in the
–	[https://eips.ethereum.org/EIPS/eip-1155[EIP]](https://eips.ethereum.org/EIPS/eip-1155%5BEIP%5D).
 *
–	Available since v3.1.
 */
interface IERC1155 is IERC165 {
    /**
–	 @dev  Emitted when value tokens of token type id are transferred from from to to by operator.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    /**
–	 @dev  Equivalent to multiple {TransferSingle} events, where operator, from and to are the same for all
–	transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    /**
–	 @dev  Emitted when account grants or revokes permission to operator to transfer their tokens, according to
–	approved.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    /**
–	 @dev  Emitted when the URI for token type id changes to value, if it is a non-programmatic URI.
     *
–	If an {URI} event was emitted for id, the standard
–	[https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees]](https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions%5Bguarantees%5D) that value will equal the value
–	returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);
    /**
–	 @dev  Returns the amount of tokens of token type id owned by account.
     *
–	Requirements:
     *
–	- account cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);
    /**
–	 @dev  xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
–	Requirements:
     *
–	- accounts and ids must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
    /**
–	 @dev  Grants or revokes permission to operator to transfer the caller's tokens, according to approved,
     *
–	Emits an {ApprovalForAll} event.
     *
–	Requirements:
     *
–	- operator cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;
    /**
–	 @dev  Returns true if operator is approved to transfer account's tokens.
     *
–	See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);
    /**
–	 @dev  Transfers amount tokens of token type id from from to to.
     *
–	Emits a {TransferSingle} event.
     *
–	Requirements:
     *
–	- to cannot be the zero address.
–	- If the caller is not from, it must have been approved to spend from's tokens via {setApprovalForAll}.
–	- from must have a balance of tokens of type id of at least amount.
–	- If to refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
–	acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
    /**
–	 @dev  xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
–	Emits a {TransferBatch} event.
     *
–	Requirements:
     *
–	- ids and amounts must have the same length.
–	- If to refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
–	acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
// File:  @openzeppelin /contracts/utils/Strings.sol
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)
pragma solidity ^0.8.0;
/**
–	 @dev  String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;
    /**
–	 @dev  Converts a uint256 to its ASCII string decimal representation.
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
–	 @dev  Converts a uint256 to its ASCII string hexadecimal representation.
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
–	 @dev  Converts a uint256 to its ASCII string hexadecimal representation with fixed length.
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
–	 @dev  Converts an address with fixed length of 20 bytes to its not checksummed ASCII string hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}
// File:  @openzeppelin /contracts/utils/cryptography/ECDSA.sol
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)
pragma solidity ^0.8.0;
/**
–	 @dev  Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
–	These functions can be used to verify that a message was signed by the holder
–	of the private keys of a given address.
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
–	 @dev  Returns the address that signed a hashed message (hash) with
–	signature or error string. This address can then be used for verification purposes.
     *
–	The ecrecover EVM opcode allows for malleable (non-unique) signatures:
–	this function rejects them by requiring the s value to be in the lower
–	half order, and the v value to be either 27 or 28.
     *
–	IMPORTANT: hash must be the result of a hash operation for the
–	verification to be secure: it is possible to craft signatures that
–	recover to arbitrary addresses for non-hashed data. A safe way to ensure
–	this is by receiving a hash of the original message (which may otherwise
–	be too long), and then calling {toEthSignedMessageHash} on it.
     *
–	Documentation for signature generation:
–	- with [https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]](https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign%5BWeb3.js%5D)
–	- with [https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]](https://docs.ethers.io/v5/api/signer/#Signer-signMessage%5Bethers%5D)
     *
–	Available since v4.3.
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) Available since v4.1.
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            ///  @solidity  memory-safe-assembly
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
            ///  @solidity  memory-safe-assembly
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
–	 @dev  Returns the address that signed a hashed message (hash) with
–	signature. This address can then be used for verification purposes.
     *
–	The ecrecover EVM opcode allows for malleable (non-unique) signatures:
–	this function rejects them by requiring the s value to be in the lower
–	half order, and the v value to be either 27 or 28.
     *
–	IMPORTANT: hash must be the result of a hash operation for the
–	verification to be secure: it is possible to craft signatures that
–	recover to arbitrary addresses for non-hashed data. A safe way to ensure
–	this is by receiving a hash of the original message (which may otherwise
–	be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }
    /**
–	 @dev  Overload of {ECDSA-tryRecover} that receives the r and vs short-signature fields separately.
     *
–	See [https://eips.ethereum.org/EIPS/eip-2098[EIP-2098](https://eips.ethereum.org/EIPS/eip-2098%5BEIP-2098) short signatures]
     *
–	Available since v4.3.
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
–	 @dev  Overload of {ECDSA-recover} that receives the r and vs` short-signature fields separately.
     *
–	Available since v4.2.
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
–	 @dev  Overload of {ECDSA-tryRecover} that receives the v,
–	r and s signature fields separately.
     *
–	Available since v4.3.
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
–	 @dev  Overload of {ECDSA-recover} that receives the v,
–	r and s signature fields separately.
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
–	 @dev  Returns an Ethereum Signed Message, created from a hash. This
–	produces hash corresponding to the one signed with the
–	https://eth.wiki/json-rpc/API#eth_sign[eth_sign]
–	JSON-RPC method as part of EIP-191.
     *
–	See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
    /**
–	 @dev  Returns an Ethereum Signed Message, created from s. This
–	produces hash corresponding to the one signed with the
–	https://eth.wiki/json-rpc/API#eth_sign[eth_sign]
–	JSON-RPC method as part of EIP-191.
     *
–	See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }
    /**
–	 @dev  Returns an Ethereum Signed Typed Data, created from a
–	domainSeparator and a structHash. This produces hash corresponding
–	to the one signed with the
–	https://eips.ethereum.org/EIPS/eip-712[eth_signTypedData]
–	JSON-RPC method as part of EIP-712.
     *
–	See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}
// File: contracts/EIP712.sol
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)
pragma solidity ^0.8.0;
/**
–	 @dev  [https://eips.ethereum.org/EIPS/eip-712[EIP](https://eips.ethereum.org/EIPS/eip-712%5BEIP) 712] is a standard for hashing and signing of typed structured data.
 *
–	The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
–	thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
–	they need in their contracts using a combination of abi.encode and keccak256.
 *
–	This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
–	scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
–	({_hashTypedDataV4}).
 *
–	The implementation of the domain separator was designed to be as efficient as possible while still properly updating
–	the chain id to protect against replay attacks on an eventual fork of the chain.
 *
–	NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
–	https://docs.metamask.io/guide/signing-data.html[eth_signTypedDataV4 in MetaMask].
 *
–	Available since v3.4.
 */
contract EIP712 {
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
–	 @dev  Initializes the domain separator and parameter caches.
     *
–	The meaning of name and version is specified in
–	[https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP](https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator%5BEIP) 712]:
     *
–	- name: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
–	- version: the current major version of the signing domain.
     *
–	NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
–	contract upgrade].
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
–	 @dev  Returns the domain separator for the current chain.
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
–	 @dev  Given an already [https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed](https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct%5Bhashed) struct], this
–	function returns the hash of the fully encoded EIP712 message for this domain.
     *
–	This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
–	`solidity
–	bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
–	keccak256("Mail(address to,string contents)"),
–	mailTo,
–	keccak256(bytes(mailContents))
–	)));
–	address signer = ECDSA.recover(digest, signature);
–	`
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}
// File: contracts/BasicValidator.sol
pragma solidity ^0.8.0;

contract BasicValidator is EIP712 {
    bytes32 public constant _TYPEHASH =
        keccak256("Data(string primaryAddress,string currentAddress)");
    struct Data {
        string primaryAddress;
        string currentAddress;
    }
    // solhint-disable-next-line no-empty-blocks
    constructor() EIP712("PV Bundled Wallet Signatures Verification", "1") {}
    function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }
    function getChainId() external view returns (uint256) {
        return block.chainid;
    }
    function verifySignature(
        bytes memory signature,
        Data memory data,
        address validator
    ) public view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _TYPEHASH,
                    keccak256(bytes(data.primaryAddress)),
                    keccak256(bytes(data.currentAddress))
                )
            )
        );
        address recoveredSigner = ECDSA.recover(digest, signature);
        return recoveredSigner == validator;
    }
}
// File: contracts/PVBundledWallets.sol
pragma solidity ^0.8.0;


contract PVBundledWallets is BasicValidator {
    mapping(address => address[]) public primaryToSecondaryWallets;
    mapping(address => bool) public isBundleEnabled;
    mapping(address => address) public secondaryToPrimaryWallet;
    error signatureVerificationFailed(address _failedAddress);
    error zeroSecondaryWallets();
    error notPartOfBundle();
    event WalletsAddedToBundle(address[] addressesAdded);
    event WalletsRemovedFromBundle(address[] addressesRemoved);
    event SecondaryWalletRemovedFromBundle(
        address primaryWallet,
        address secondaryWallet
    );
    // add address
    function addWallets(
        address[] memory _addresses,
        bytes[] memory _signatures,
        Data[] memory _data
    ) external {
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (!verifySignature(_signatures[i], _data[i], _addresses[i])) {
                revert signatureVerificationFailed(_addresses[i]);
            }
        }
        for (uint256 j = 0; j < _addresses.length; j++) {
            if (primaryToSecondaryWallets[msg.sender].length == 0) {
                primaryToSecondaryWallets[msg.sender].push(_addresses[j]);
            } else {
                for (
                    uint256 k = 0;
                    k < primaryToSecondaryWallets[msg.sender].length;
                    k++
                ) {
                    if (
                        (_addresses[j] ==
                            primaryToSecondaryWallets[msg.sender][k]) ||
                        secondaryToPrimaryWallet[_addresses[j]] != address(0)
                    ) break;
                    if (k == primaryToSecondaryWallets[msg.sender].length - 1) {
                        primaryToSecondaryWallets[msg.sender].push(
                            _addresses[j]
                        );
                        secondaryToPrimaryWallet[_addresses[j]] = msg.sender;
                    }
                }
            }
        }
        isBundleEnabled[msg.sender] = true;
        emit WalletsAddedToBundle(_addresses);
    }
    function removeWallets(address[] memory _addresses) external {
        for (uint256 j = 0; j < _addresses.length; j++) {
            for (
                uint256 k = 0;
                k < primaryToSecondaryWallets[msg.sender].length;
                k++
            ) {
                if (_addresses[j] == primaryToSecondaryWallets[msg.sender][k]) {
                    delete primaryToSecondaryWallets[msg.sender][k];
                    secondaryToPrimaryWallet[_addresses[j]] = address(0);
                    for (
                        uint256 i = k;
                        i < primaryToSecondaryWallets[msg.sender].length;
                        i++
                    ) {
                        // replace current item with the last item in array and pop the last item
                        // this method is used as we do not care about order of addresses
                        primaryToSecondaryWallets[msg.sender][
                            i
                        ] = primaryToSecondaryWallets[msg.sender][
                            primaryToSecondaryWallets[msg.sender].length - 1
                        ];
                        primaryToSecondaryWallets[msg.sender].pop();
                    }
                    break;
                }
            }
        }
        emit WalletsRemovedFromBundle(_addresses);
    }
    function removeSecondaryWalletFromBundle() external {
        if (secondaryToPrimaryWallet[msg.sender] == address(0))
            revert notPartOfBundle();
        address primaryWallet = secondaryToPrimaryWallet[msg.sender];
        for (
            uint256 k = 0;
            k < primaryToSecondaryWallets[primaryWallet].length;
            k++
        ) {
            if (msg.sender == primaryToSecondaryWallets[primaryWallet][k]) {
                delete primaryToSecondaryWallets[primaryWallet][k];
                secondaryToPrimaryWallet[msg.sender] = address(0);
                for (
                    uint256 i = k;
                    i < primaryToSecondaryWallets[primaryWallet].length;
                    i++
                ) {
                    // replace current item with the last item in array and pop the last item
                    // this method is used as we do not care about order of addresses
                    primaryToSecondaryWallets[primaryWallet][
                        i
                    ] = primaryToSecondaryWallets[primaryWallet][
                        primaryToSecondaryWallets[primaryWallet].length - 1
                    ];
                    primaryToSecondaryWallets[primaryWallet].pop();
                }
                break;
            }
        }
        emit SecondaryWalletRemovedFromBundle(primaryWallet, msg.sender);
    }
    function toggleBundling(bool _bundleStatus) external {
        if (!_bundleStatus) isBundleEnabled[msg.sender] = false;
        else if (
            _bundleStatus == true &&
            primaryToSecondaryWallets[msg.sender].length > 0
        ) {
            isBundleEnabled[msg.sender] = true;
        } else {
            revert zeroSecondaryWallets();
        }
    }
    /**
–	 @dev  See {IERC721-balanceOf}.
     */
    function ERC721BalanceOf(address user, IERC721 tokenContract)
        public
        view
        returns (uint256)
    {
        uint256 bundledBalance = tokenContract.balanceOf(user);
        if (!isBundleEnabled[user]) return bundledBalance;
        for (uint256 i = 0; i < primaryToSecondaryWallets[user].length; i++) {
            if (primaryToSecondaryWallets[user][i] == address(0)) {
                continue;
            }
            bundledBalance += tokenContract.balanceOf(
                primaryToSecondaryWallets[user][i]
            );
        }
        return bundledBalance;
    }
    /**
–	 @dev  See {IERC721-ownerOf}.
     */
    function isOwnerOfERC721(
        uint256 tokenId,
        address user,
        IERC721 tokenContract
    ) public view returns (bool) {
        if (!isBundleEnabled[user]) {
            return user == tokenContract.ownerOf(tokenId);
        }
        if (user == tokenContract.ownerOf(tokenId)) return true;
        for (uint256 i = 0; i < primaryToSecondaryWallets[user].length; i++) {
            if (primaryToSecondaryWallets[user][i] == address(0)) {
                continue;
            }
            if (
                primaryToSecondaryWallets[user][i] ==
                tokenContract.ownerOf(tokenId)
            ) {
                return true;
            }
        }
        return false;
    }
    /**
–	 @dev  See {IERC20-balanceOf}.
     */
    function ERC20BalanceOf(address user, IERC20 tokenContract)
        public
        view
        returns (uint256)
    {
        uint256 bundledBalance = tokenContract.balanceOf(user);
        if (!isBundleEnabled[user]) return tokenContract.balanceOf(user);
        for (uint256 i = 0; i < primaryToSecondaryWallets[user].length; i++) {
            if (primaryToSecondaryWallets[user][i] == address(0)) {
                continue;
            }
            bundledBalance += tokenContract.balanceOf(
                primaryToSecondaryWallets[user][i]
            );
        }
        return bundledBalance;
    }
    /**
–	 @dev  See {IERC1155-balanceOf}.
     *
–	Requirements:
     *
–	- account cannot be the zero address.
     */
    function ERC1155BalanceOf(
        address user,
        IERC1155 tokenContract,
        uint256 id
    ) public view returns (uint256) {
        uint256 bundledBalance = tokenContract.balanceOf(user, id);
        if (!isBundleEnabled[user]) return tokenContract.balanceOf(user, id);
        for (uint256 i = 0; i < primaryToSecondaryWallets[user].length; i++) {
            if (primaryToSecondaryWallets[user][i] == address(0)) {
                continue;
            }
            bundledBalance += tokenContract.balanceOf(
                primaryToSecondaryWallets[user][i],
                id
            );
        }
        return bundledBalance;
    }
    function fetchSecondaryWallets(address primaryWallet)
        public
        view
        returns (address[] memory secondaryAddresses)
    {
        if (isBundleEnabled[primaryWallet]) {
            return primaryToSecondaryWallets[primaryWallet];
        } else {
            return (new address[](0));
        }
    }
}