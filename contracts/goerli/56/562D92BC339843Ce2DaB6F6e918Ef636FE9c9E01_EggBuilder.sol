/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)
/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)
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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)
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
    function tryRecover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address, RecoverError)
    {
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
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
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
        bytes32 s = vs &
            bytes32(
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
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
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
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
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    Strings.toString(s.length),
                    s
                )
            );
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)
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
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(
            typeHash,
            hashedName,
            hashedVersion
        );
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (
            address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID
        ) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return
                _buildDomainSeparator(
                    _TYPE_HASH,
                    _HASHED_NAME,
                    _HASHED_VERSION
                );
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
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
    function _hashTypedDataV4(bytes32 structHash)
        internal
        view
        virtual
        returns (bytes32)
    {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

/// @notice 管理者権限の実装
abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not owner");
        _;
    }

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(
            _newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        owner = _newOwner;
    }
}

/// @notice 発行権限の実装
abstract contract Mintable {
    mapping(address => bool) public minters;

    constructor() {
        minters[msg.sender] = true;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Mintable: caller is not minter");
        _;
    }

    function setMinter(address newMinter, bool mintable)
        public
        virtual
        onlyMinter
    {
        require(
            newMinter != address(0),
            "Mintable: new minter is the zero address"
        );
        minters[newMinter] = mintable;
    }
}

/// @notice 焼却権限の実装
abstract contract Burnable {
    mapping(address => bool) public burners;

    constructor() {
        burners[msg.sender] = true;
    }

    modifier onlyBurner() {
        require(burners[msg.sender], "Burnable: caller is not burner");
        _;
    }

    function isBurner(address addr) public view returns (bool) {
        return burners[addr];
    }

    function setBurner(address newBurner, bool burnable)
        public
        virtual
        onlyBurner
    {
        require(
            newBurner != address(0),
            "Burnable: new burner is the zero address"
        );
        burners[newBurner] = burnable;
    }
}

/// @notice 署名の実装
abstract contract SupportSig is EIP712 {
    uint256 private MAX_NONCE_DIFFERENCE = 100 * 365 * 24 * 60 * 60;

    constructor(string memory name, string memory version)
        EIP712(name, version)
    {}

    function validNonce(uint256 nonce, uint256 lastNonce)
        internal
        view
        returns (bool)
    {
        return nonce > lastNonce && nonce - lastNonce < MAX_NONCE_DIFFERENCE;
    }

    function getChainId() public view returns (uint256) {
        return block.chainid;
    }

    function getSigner(bytes memory typedContents, bytes memory sig)
        internal
        view
        returns (address)
    {
        return ECDSA.recover(_hashTypedDataV4(keccak256(typedContents)), sig);
    }
}

/// @notice トークン更新履歴の実装
abstract contract SupportTokenUpdateHistory {
    struct TokenUpdateHistoryItem {
        uint256 tokenId;
        uint256 updatedAt;
    }

    uint256 public tokenUpdateHistoryCount;
    TokenUpdateHistoryItem[] public tokenUpdateHistory;

    constructor() {
        TokenUpdateHistoryItem memory dummy;
        tokenUpdateHistory.push(dummy); // 1-based index
    }

    function onTokenUpdated(uint256 tokenId) internal {
        tokenUpdateHistory.push(
            TokenUpdateHistoryItem(tokenId, block.timestamp)
        );
        tokenUpdateHistoryCount++;
    }
}

interface IEggBuilder {
    struct ComposeCondition {
        uint256[] ids;
        uint256[] amounts;
        /*        uint256 shardId1;
        uint256 shardId2;
        uint256 numShard1;
        uint256 numShard2;*/
        string metadataHash;
    }

    /// @notice Shardトークンを組み合わせてEggを生成する。
    /** @dev
    処理概要：
    * 要求元からAnimaを回収
    * 入力されたShardから新しいgeneを計算
    * Shardトークンをburn
    * Eggトークンをmint
    */
    function compose(
        ComposeCondition calldata cond,
        address to,
        address from
    ) external returns (uint256);
}

interface IShard {
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    function burnBatch(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;
}

contract PercentUtil {
    /*
    uint16[] percentBits = [
        0x028F,	// 01=0b0000001010001111  0.0099945068359375
        0x051E,	// 02=0b0000010100011110  0.019989013671875
        0x07AE,	// 03=0b0000011110101110  0.029998779296875
        0x0A3D,	// 04=0b0000101000111101  0.0399932861328125
        0x0CCC,	// 05=0b0000110011001100  0.04998779296875
        0x0F5C,	// 06=0b0000111101011100  0.05999755859375
        0x11EB,	// 07=0b0001000111101011  0.0699920654296875
        0x147A,	// 08=0b0001010001111010  0.079986572265625
        0x170A,	// 09=0b0001011100001010  0.089996337890625
        0x1999,	// 10=0b0001100110011001  0.0999908447265625
        0x1C28,	// 11=0b0001110000101000  0.1099853515625
        0x1EB8,	// 12=0b0001111010111000  0.1199951171875
        0x2147,	// 13=0b0010000101000111  0.1299896240234375
        0x23D7,	// 14=0b0010001111010111  0.1399993896484375
        0x2666,	// 15=0b0010011001100110  0.149993896484375
        0x28F5,	// 16=0b0010100011110101  0.1599884033203125
        0x2B85,	// 17=0b0010101110000101  0.1699981689453125
        0x2E14,	// 18=0b0010111000010100  0.17999267578125
        0x30A3,	// 19=0b0011000010100011  0.1899871826171875
        0x3333,	// 20=0b0011001100110011  0.1999969482421875
        0x35C2,	// 21=0b0011010111000010  0.209991455078125
        0x3851,	// 22=0b0011100001010001  0.2199859619140625
        0x3AE1,	// 23=0b0011101011100001  0.2299957275390625
        0x3D70,	// 24=0b0011110101110000  0.239990234375
        0x4000,	// 25=0b0100000000000000  0.25
        0x428F,	// 26=0b0100001010001111  0.2599945068359375
        0x451E,	// 27=0b0100010100011110  0.269989013671875
        0x47AE,	// 28=0b0100011110101110  0.279998779296875
        0x4A3D,	// 29=0b0100101000111101  0.2899932861328125
        0x4CCC,	// 30=0b0100110011001100  0.29998779296875
        0x4F5C,	// 31=0b0100111101011100  0.30999755859375
        0x51EB,	// 32=0b0101000111101011  0.3199920654296875
        0x547A,	// 33=0b0101010001111010  0.329986572265625
        0x570A,	// 34=0b0101011100001010  0.339996337890625
        0x5999,	// 35=0b0101100110011001  0.3499908447265625
        0x5C28,	// 36=0b0101110000101000  0.3599853515625
        0x5EB8,	// 37=0b0101111010111000  0.3699951171875
        0x6147,	// 38=0b0110000101000111  0.3799896240234375
        0x63D7,	// 39=0b0110001111010111  0.3899993896484375
        0x6666,	// 40=0b0110011001100110  0.399993896484375
        0x68F5,	// 41=0b0110100011110101  0.4099884033203125
        0x6B85,	// 42=0b0110101110000101  0.4199981689453125
        0x6E14,	// 43=0b0110111000010100  0.42999267578125
        0x70A3,	// 44=0b0111000010100011  0.4399871826171875
        0x7333,	// 45=0b0111001100110011  0.4499969482421875
        0x75C2,	// 46=0b0111010111000010  0.459991455078125
        0x7851,	// 47=0b0111100001010001  0.4699859619140625
        0x7AE1,	// 48=0b0111101011100001  0.4799957275390625
        0x7D70,	// 49=0b0111110101110000  0.489990234375
        0x8000,	// 50=0b1000000000000000  0.5
        0x828F,	// 51=0b1000001010001111  0.5099945068359375
        0x851E,	// 52=0b1000010100011110  0.519989013671875
        0x87AE,	// 53=0b1000011110101110  0.529998779296875
        0x8A3D,	// 54=0b1000101000111101  0.5399932861328125
        0x8CCC,	// 55=0b1000110011001100  0.54998779296875
        0x8F5C,	// 56=0b1000111101011100  0.55999755859375
        0x91EB,	// 57=0b1001000111101011  0.5699920654296875
        0x947A,	// 58=0b1001010001111010  0.579986572265625
        0x970A,	// 59=0b1001011100001010  0.589996337890625
        0x9999,	// 60=0b1001100110011001  0.5999908447265625
        0x9C28,	// 61=0b1001110000101000  0.6099853515625
        0x9EB8,	// 62=0b1001111010111000  0.6199951171875
        0xA147,	// 63=0b1010000101000111  0.6299896240234375
        0xA3D7,	// 64=0b1010001111010111  0.6399993896484375
        0xA666,	// 65=0b1010011001100110  0.649993896484375
        0xA8F5,	// 66=0b1010100011110101  0.6599884033203125
        0xAB85,	// 67=0b1010101110000101  0.6699981689453125
        0xAE14,	// 68=0b1010111000010100  0.67999267578125
        0xB0A3,	// 69=0b1011000010100011  0.6899871826171875
        0xB333,	// 70=0b1011001100110011  0.6999969482421875
        0xB5C2,	// 71=0b1011010111000010  0.709991455078125
        0xB851,	// 72=0b1011100001010001  0.7199859619140625
        0xBAE1,	// 73=0b1011101011100001  0.7299957275390625
        0xBD70,	// 74=0b1011110101110000  0.739990234375
        0xC000,	// 75=0b1100000000000000  0.75
        0xC28F,	// 76=0b1100001010001111  0.7599945068359375
        0xC51E,	// 77=0b1100010100011110  0.769989013671875
        0xC7AE,	// 78=0b1100011110101110  0.779998779296875
        0xCA3D,	// 79=0b1100101000111101  0.7899932861328125
        0xCCCC,	// 80=0b1100110011001100  0.79998779296875
        0xCF5C,	// 81=0b1100111101011100  0.80999755859375
        0xD1EB,	// 82=0b1101000111101011  0.8199920654296875
        0xD47A,	// 83=0b1101010001111010  0.829986572265625
        0xD70A,	// 84=0b1101011100001010  0.839996337890625
        0xD999,	// 85=0b1101100110011001  0.8499908447265625
        0xDC28,	// 86=0b1101110000101000  0.8599853515625
        0xDEB8,	// 87=0b1101111010111000  0.8699951171875
        0xE147,	// 88=0b1110000101000111  0.8799896240234375
        0xE3D7,	// 89=0b1110001111010111  0.8899993896484375
        0xE666,	// 90=0b1110011001100110  0.899993896484375
        0xE8F5,	// 91=0b1110100011110101  0.9099884033203125
        0xEB85,	// 92=0b1110101110000101  0.9199981689453125
        0xEE14,	// 93=0b1110111000010100  0.92999267578125
        0xF0A3,	// 94=0b1111000010100011  0.9399871826171875
        0xF333,	// 95=0b1111001100110011  0.9499969482421875
        0xF5C2,	// 96=0b1111010111000010  0.959991455078125
        0xF851,	// 97=0b1111100001010001  0.9699859619140625
        0xFAE1,	// 98=0b1111101011100001  0.9799957275390625
        0xFD70	// 99=0b1111110101110000  0.989990234375
    ];*/
    uint32[] percentBits = [
        0x028F5C28, // 01=0b00000010100011110101110000101000  0.009999999776482582
        0x051EB851, // 02=0b00000101000111101011100001010001  0.019999999785795808
        0x07AE147A, // 03=0b00000111101011100001010001111010  0.029999999795109034
        0x0A3D70A3, // 04=0b00001010001111010111000010100011  0.03999999980442226
        0x0CCCCCCC, // 05=0b00001100110011001100110011001100  0.049999999813735485
        0x0F5C28F5, // 06=0b00001111010111000010100011110101  0.05999999982304871
        0x11EB851E, // 07=0b00010001111010111000010100011110  0.06999999983236194
        0x147AE147, // 08=0b00010100011110101110000101000111  0.07999999984167516
        0x170A3D70, // 09=0b00010111000010100011110101110000  0.08999999985098839
        0x19999999, // 10=0b00011001100110011001100110011001  0.09999999986030161
        0x1C28F5C2, // 11=0b00011100001010001111010111000010  0.10999999986961484
        0x1EB851EB, // 12=0b00011110101110000101000111101011  0.11999999987892807
        0x2147AE14, // 13=0b00100001010001111010111000010100  0.1299999998882413
        0x23D70A3D, // 14=0b00100011110101110000101000111101  0.13999999989755452
        0x26666666, // 15=0b00100110011001100110011001100110  0.14999999990686774
        0x28F5C28F, // 16=0b00101000111101011100001010001111  0.15999999991618097
        0x2B851EB8, // 17=0b00101011100001010001111010111000  0.1699999999254942
        0x2E147AE1, // 18=0b00101110000101000111101011100001  0.17999999993480742
        0x30A3D70A, // 19=0b00110000101000111101011100001010  0.18999999994412065
        0x33333333, // 20=0b00110011001100110011001100110011  0.19999999995343387
        0x35C28F5C, // 21=0b00110101110000101000111101011100  0.2099999999627471
        0x3851EB85, // 22=0b00111000010100011110101110000101  0.21999999997206032
        0x3AE147AE, // 23=0b00111010111000010100011110101110  0.22999999998137355
        0x3D70A3D7, // 24=0b00111101011100001010001111010111  0.23999999999068677
        0x40000000, // 25=0b01000000000000000000000000000000  0.25
        0x428F5C28, // 26=0b01000010100011110101110000101000  0.2599999997764826
        0x451EB851, // 27=0b01000101000111101011100001010001  0.2699999997857958
        0x47AE147A, // 28=0b01000111101011100001010001111010  0.27999999979510903
        0x4A3D70A3, // 29=0b01001010001111010111000010100011  0.28999999980442226
        0x4CCCCCCC, // 30=0b01001100110011001100110011001100  0.2999999998137355
        0x4F5C28F5, // 31=0b01001111010111000010100011110101  0.3099999998230487
        0x51EB851E, // 32=0b01010001111010111000010100011110  0.31999999983236194
        0x547AE147, // 33=0b01010100011110101110000101000111  0.32999999984167516
        0x570A3D70, // 34=0b01010111000010100011110101110000  0.3399999998509884
        0x59999999, // 35=0b01011001100110011001100110011001  0.3499999998603016
        0x5C28F5C2, // 36=0b01011100001010001111010111000010  0.35999999986961484
        0x5EB851EB, // 37=0b01011110101110000101000111101011  0.36999999987892807
        0x6147AE14, // 38=0b01100001010001111010111000010100  0.3799999998882413
        0x63D70A3D, // 39=0b01100011110101110000101000111101  0.3899999998975545
        0x66666666, // 40=0b01100110011001100110011001100110  0.39999999990686774
        0x68F5C28F, // 41=0b01101000111101011100001010001111  0.40999999991618097
        0x6B851EB8, // 42=0b01101011100001010001111010111000  0.4199999999254942
        0x6E147AE1, // 43=0b01101110000101000111101011100001  0.4299999999348074
        0x70A3D70A, // 44=0b01110000101000111101011100001010  0.43999999994412065
        0x73333333, // 45=0b01110011001100110011001100110011  0.44999999995343387
        0x75C28F5C, // 46=0b01110101110000101000111101011100  0.4599999999627471
        0x7851EB85, // 47=0b01111000010100011110101110000101  0.4699999999720603
        0x7AE147AE, // 48=0b01111010111000010100011110101110  0.47999999998137355
        0x7D70A3D7, // 49=0b01111101011100001010001111010111  0.4899999999906868
        0x80000000, // 50=0b10000000000000000000000000000000  0.5
        0x828F5C28, // 51=0b10000010100011110101110000101000  0.5099999997764826
        0x851EB851, // 52=0b10000101000111101011100001010001  0.5199999997857958
        0x87AE147A, // 53=0b10000111101011100001010001111010  0.529999999795109
        0x8A3D70A3, // 54=0b10001010001111010111000010100011  0.5399999998044223
        0x8CCCCCCC, // 55=0b10001100110011001100110011001100  0.5499999998137355
        0x8F5C28F5, // 56=0b10001111010111000010100011110101  0.5599999998230487
        0x91EB851E, // 57=0b10010001111010111000010100011110  0.5699999998323619
        0x947AE147, // 58=0b10010100011110101110000101000111  0.5799999998416752
        0x970A3D70, // 59=0b10010111000010100011110101110000  0.5899999998509884
        0x99999999, // 60=0b10011001100110011001100110011001  0.5999999998603016
        0x9C28F5C2, // 61=0b10011100001010001111010111000010  0.6099999998696148
        0x9EB851EB, // 62=0b10011110101110000101000111101011  0.6199999998789281
        0xA147AE14, // 63=0b10100001010001111010111000010100  0.6299999998882413
        0xA3D70A3D, // 64=0b10100011110101110000101000111101  0.6399999998975545
        0xA6666666, // 65=0b10100110011001100110011001100110  0.6499999999068677
        0xA8F5C28F, // 66=0b10101000111101011100001010001111  0.659999999916181
        0xAB851EB8, // 67=0b10101011100001010001111010111000  0.6699999999254942
        0xAE147AE1, // 68=0b10101110000101000111101011100001  0.6799999999348074
        0xB0A3D70A, // 69=0b10110000101000111101011100001010  0.6899999999441206
        0xB3333333, // 70=0b10110011001100110011001100110011  0.6999999999534339
        0xB5C28F5C, // 71=0b10110101110000101000111101011100  0.7099999999627471
        0xB851EB85, // 72=0b10111000010100011110101110000101  0.7199999999720603
        0xBAE147AE, // 73=0b10111010111000010100011110101110  0.7299999999813735
        0xBD70A3D7, // 74=0b10111101011100001010001111010111  0.7399999999906868
        0xC0000000, // 75=0b11000000000000000000000000000000  0.75
        0xC28F5C28, // 76=0b11000010100011110101110000101000  0.7599999997764826
        0xC51EB851, // 77=0b11000101000111101011100001010001  0.7699999997857958
        0xC7AE147A, // 78=0b11000111101011100001010001111010  0.779999999795109
        0xCA3D70A3, // 79=0b11001010001111010111000010100011  0.7899999998044223
        0xCCCCCCCC, // 80=0b11001100110011001100110011001100  0.7999999998137355
        0xCF5C28F5, // 81=0b11001111010111000010100011110101  0.8099999998230487
        0xD1EB851E, // 82=0b11010001111010111000010100011110  0.8199999998323619
        0xD47AE147, // 83=0b11010100011110101110000101000111  0.8299999998416752
        0xD70A3D70, // 84=0b11010111000010100011110101110000  0.8399999998509884
        0xD9999999, // 85=0b11011001100110011001100110011001  0.8499999998603016
        0xDC28F5C2, // 86=0b11011100001010001111010111000010  0.8599999998696148
        0xDEB851EB, // 87=0b11011110101110000101000111101011  0.8699999998789281
        0xE147AE14, // 88=0b11100001010001111010111000010100  0.8799999998882413
        0xE3D70A3D, // 89=0b11100011110101110000101000111101  0.8899999998975545
        0xE6666666, // 90=0b11100110011001100110011001100110  0.8999999999068677
        0xE8F5C28F, // 91=0b11101000111101011100001010001111  0.909999999916181
        0xEB851EB8, // 92=0b11101011100001010001111010111000  0.9199999999254942
        0xEE147AE1, // 93=0b11101110000101000111101011100001  0.9299999999348074
        0xF0A3D70A, // 94=0b11110000101000111101011100001010  0.9399999999441206
        0xF3333333, // 95=0b11110011001100110011001100110011  0.9499999999534339
        0xF5C28F5C, // 96=0b11110101110000101000111101011100  0.9599999999627471
        0xF851EB85, // 97=0b11111000010100011110101110000101  0.9699999999720603
        0xFAE147AE, // 98=0b11111010111000010100011110101110  0.9799999999813735
        0xFD70A3D7 // 99=0b11111101011100001010001111010111  0.9899999999906868
    ];

    function percent(uint256 value, uint256 _percent)
        public
        view
        returns (uint256)
    {
        if (_percent == 0) {
            return 0;
        } else if (_percent >= 100) {
            return value;
        }
        uint32 bits = percentBits[_percent - 1];
        uint256 ret = 0;
        value = value >> 1;
        for (; bits != 0 && value != 0; bits = bits << 1) {
            if ((bits & 0x80000000) != 0) {
                ret += value;
            }
            value = value >> 1;
        }
        return ret;
    }

    //                0 1 2 3 4 5 6 7 8 9 A B C D E F 0 1 2 3 4 5 6 7 8 9 A B C D E F
    uint256 mask8 =
        0x7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f;
    uint256 carryMask =
        0x0101010101010101010101010101010101010101010101010101010101010101;

    function percentForByteUnit(uint256 value, uint256 _percent)
        public
        view
        returns (uint256, uint256)
    {
        if (_percent == 0) {
            return (0, 0);
        } else if (_percent >= 100) {
            return (value, 0);
        }
        uint32 bits = percentBits[_percent - 1];
        uint256 ret = 0;
        uint256 carry = value & carryMask;
        value = (value >> 1) & mask8;
        for (; bits != 0 && value != 0; bits = bits << 1) {
            if ((bits & 0x80000000) != 0) {
                ret += value;
            }
            value = (value >> 1) & mask8;
            carry = value & carryMask;
        }
        return (ret, carry);
    }
}

interface IMintableERC721 {
    function mint(
        address to,
        uint256 gene,
        string calldata metadataHash
    ) external returns (uint256);
}

contract EggBuilder is Ownable, IEggBuilder, PercentUtil {
    uint256 nonce;
    address public shardToken;
    IMintableERC721 public eggToken;
    address private _matrixMaster;

    function setShardToken(address address_) public onlyOwner {
        shardToken = address_;
    }

    function setEggToken(address address_) public onlyOwner {
        eggToken = IMintableERC721(address_);
    }

    function setMatrixMaster(address address_) external {
        _matrixMaster = address_;
    }

    /// @notice Shardトークンを組み合わせてEggを生成する。
    /** @dev
    処理概要：
    * 要求元からAnimaを回収
    * 入力されたShardから新しいgeneを計算
    * Shardトークンをburn
    * Eggトークンをmint
    */
    function compose(
        ComposeCondition calldata cond,
        address to,
        address from
    ) external override(IEggBuilder) returns (uint256) {
        require(
            msg.sender == owner || msg.sender == _matrixMaster,
            "EggBuilder: the caller is not MatrixMaster nor owner"
        );
        //        ComposeCondition memory c = cond;
        uint256 gene1;
        uint256 carry1;
        uint256 gene2;
        uint256 carry2;
        (gene1, carry1) = percentForByteUnit(cond.ids[0], cond.amounts[0]);
        (gene2, carry2) = percentForByteUnit(cond.ids[1], cond.amounts[1]);
        uint256 newGene = gene1 + gene2 + (carry1 & carry2);
        newGene = mutation(newGene);
        // DEBUG START
        /*
        uint256 balance = IERC1155(shardToken).balanceOf(from,cond.shardId1);
        require(balance >= cond.numShard1,"NOT ENOUGH BALANCE shard1");
        balance = IERC1155(shardToken).balanceOf(from,cond.shardId2);
        require(balance >= cond.numShard2,"NOT ENOUGH BALANCE shard2");
        */
        // DEBUG END
        /*
        IShard(shardToken).burn(from, cond.shardId1, cond.numShard1);
        IShard(shardToken).burn(from, cond.shardId2, cond.numShard2);
        uint256[] memory ids = new uint256[](2);
        ids[0] = cond.shardId1;
        ids[1] = cond.shardId2;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = cond.numShard1;
        amounts[1] = cond.numShard2;*/
        IShard(shardToken).burnBatch(from, cond.ids, cond.amounts);
        uint256 eggId = eggToken.mint(to, newGene, cond.metadataHash);
        return eggId;
    }

    /*
    function reply(ComposeCondition calldata cond) external pure
    returns (uint256 shard1, uint256 num1, uint256 shard2, uint256 num2) {
        shard1 = cond.shardId1;
        shard2 = cond.shardId2;
        num1 = cond.numShard1;
        num2 = cond.numShard2;
    }
    */

    function mutation(uint256 gene) internal returns (uint256) {
        uint256 shifter = 256;
        uint256 mask = 0xff00000000000000000000000000000000000000000000000000000000000000;
        for (; mask != 0; mask >>= 8) {
            shifter -= 8;
            uint256 randVal = uint256(
                keccak256(abi.encodePacked(block.timestamp, ++nonce))
            ) % 100;
            if (randVal < 5) {
                uint256 unitGene = uint256(
                    keccak256(abi.encodePacked(block.timestamp, ++nonce))
                ) % 0x100;
                gene = (gene & ~mask) | (unitGene << shifter);
            }
        }
        return gene;
    }
    /*
    function _combineGenes(ComposeCondition calldata cond) private pure returns (uint256)
    {
        uint256 bitmask1 = 0x7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f;
        uint256 bitmask2 = 0x0101010101010101010101010101010101010101010101010101010101010101;
        uint256 gene1div2 = (gene1 >> 1) & bitmask1;
        uint256 gene2div2 = (gene2 >> 1) & bitmask1;
        uint256 roundingErrorRecovery = (gene1 & gene2 & bitmask2);
        return (gene1div2 + gene2div2 + roundingErrorRecovery);
    }
*/
}