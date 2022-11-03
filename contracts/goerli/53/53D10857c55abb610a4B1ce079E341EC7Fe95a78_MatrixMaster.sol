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

interface IMatrix {
    /// @notice Eggを生成する。
    //    function spawn(string calldata metadataHash, address to) external returns (uint256);

    function spawnCondition()
        external
        returns (IEggBuilder.ComposeCondition memory);

    //    returns (uint256[2] memory shardIds, uint256[2] memory numShards);
    /// @notice Eggの生成に必要とするAnimaの量を取得する。
    function getPrice() external view returns (uint256);

    // @notice Matrix を
    function correspondingSquareKey() external view returns (uint256);

    function getOwner() external view returns (address);
}

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)
/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

interface ISquare is IERC721 {
    function validatorOf(uint256 tokenId) external view returns (address);
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

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

interface IAnima is IERC20, IERC165 {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

/**
 * @title IANMDailyCirculator
 * @notice interface of ANMDailyCirculator
 *
 */
interface IANMDailyCirculator {
    /**
     * @notice spawn() 通知。MatrixMaster.spawn()の実行を通知する。
     * @dev MatrixMasterは spawn() 実行後にAnimaをmatrixが指定する
     * priceをANMtaxBureauにtransferするとともに、本functionを呼び出す必要がある。
     * @param eggTokenId spawn()によって生成したeggのtokenId
     * @param validator 実行したMatrixのvalidator
     * @param validator 実行したMatrixのowner = 開発エンジニア
     * @param price Matrixにより指定されているprice
     */
    function onSpawn(
        uint256 eggTokenId,
        address validator,
        address developer,
        uint256 price
    ) external;

    /**
     * @notice Incubator.incubate() (EGG->ARCANA)実行通知を行う。
     * @dev Incubator は incubate実行後に、本functionを呼び出す必要がある。
     * 以下を実行する。（ANIMAのBURNはANIMAの総発行数が最低発行数を下回らない事）
     * 1. 0.75% をBURN
     * 2. 6% をKights of the Round Tableへtransferする。
     * 対象のEGGを生成したMatrixのOwnerに対して、
     * 1. DaylyShareをインクリメントする。
     * 2. EGGについてプールしていたANIMAの22.25%をtransferする。
     * @param eggTokenId incubate()で使用したEGGトークンID
     * @param arcanaTokenId incubate()で生成したARCANAトークンID
     */
    function onIncubate(uint256 eggTokenId, uint256 arcanaTokenId) external;

    /**
     * @notice Composer.endCompose() (ARCANA->SHARD) 実行通知を行う。
     * @dev ComposerはendCompose() 実行後に本functionを呼び出す必要がある。
     * 以下を実行する。
     * 実行した分解エンジニアに対して、
     * 1. DaylyShareをインクリメントする。
     * 2. 分解したArcanaに関わるPOOLしていたANIMAの50%を分解エンジニアにTransferする。
     * 分解したArcanaの元になったEggを生成したMatrix ownerに対して
     * POOLしていたANIMAの21%を開発エンジニアにtransferする。
     * @param arcanaTokenId 分解したArcana トークンID
     * @param extractor 分解エンジニア
     */
    function onEndDecompose(uint256 arcanaTokenId, address extractor) external;

    /**
     * @notice Persona.absorb() 通知。
     * @dev Personaはabsorb() 実行後に本functionを実行する必要がある。
     * 本function は以下を実行する。
     * absorbしたArcanaトークンに関わるPOOLをburnする。
     * @param arcanaTokenId absorbしたArcanaトークンID
     */
    function onAbsorb(uint256 arcanaTokenId) external;
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

// for debug
contract MatrixMaster is Ownable {
    uint256 public numRegistered;
    address private _animaContract;
    ISquare private _squareContract;
    address private _eggBuilder;
    address private _circulator = address(this);
    //    uint256 private _registrationFee;
    struct MatrixInfo {
        address matrix;
        uint256 price;
    }
    address private _shard;

    // matrix id -> matrix contract address
    mapping(uint256 => MatrixInfo) public registered;
    // matrix contract address -> matrix id
    mapping(address => uint256) public lookup;

    event Register(uint256 matrixId, address contractAddress);
    event Spawn(uint256 matrixId, uint256 eggId, address to, uint256 price);
    event SpawnBatch(
        uint256 matrixId,
        uint256[] eggId,
        address to,
        uint256 price
    );

    function setAnimaToken(address tokenAddress) external onlyOwner {
        _animaContract = tokenAddress;
    }

    function setSquareToken(address tokenAddress) external onlyOwner {
        _squareContract = ISquare(tokenAddress);
    }

    function setCirculator(address tokenAddress) external onlyOwner {
        _circulator = tokenAddress;
    }

    /*
    function setRegistrationFee(uint256 registrationFee) external onlyOwner {
        _registrationFee = registrationFee;
    }
*/
    function setEggBuilder(address _address) external onlyOwner {
        _eggBuilder = _address;
    }

    function setShard(address _address) external onlyOwner {
        _shard = _address;
    }

    /**
     * @notice Matrixを登録する。
     * @dev from Whitepaper, MATRIXのブロードキャスト時に一定量のANIMAをBURNする。
     * @param contractAddress 登録するMatrixのアドレス
     * @return 登録した Matrix の ID
     */
    function register(address contractAddress) external returns (uint256) {
        require(
            IERC165(contractAddress).supportsInterface(
                type(IMatrix).interfaceId
            ),
            "MatrixMaster: not Matrix implementation"
        );
        require(
            lookup[contractAddress] == 0,
            "MatrixMaster: duplicates not allowed"
        );
        uint256 price = IMatrix(contractAddress).getPrice();
        uint256 _registrationFee = price * 10;
        if (_animaContract != address(0) && _registrationFee > 0) {
            IAnima(_animaContract).burn(msg.sender, _registrationFee);
        }
        uint256 id = numRegistered + 1;
        registered[id] = MatrixInfo(contractAddress, price);
        lookup[contractAddress] = id;
        emit Register(id, contractAddress);
        numRegistered++;
        return id;
    }

    /*
    /// @notice 貯まったAnimaを引き出す（暫定）
    function withdraw(address to) external onlyOwner {
        uint256 amount = animaToken.balanceOf(address(this));
        animaToken.transfer(to, amount);
    }
*/

    /// @notice Egg生成に要するAnimaの額を取得する。
    function getPrice(uint256 matrixId) external view returns (uint256) {
        require(
            registered[matrixId].matrix != address(0x0),
            "MatrixMaster: invalid matrixId"
        );
        return registered[matrixId].price;
    }

    /**
     * @notice Eggを生成する。
     * @dev
     * #Ticket: ANICANA-120, ANICANA-83
     * msg.sender は指定されたMatrixのsquareKeyのissuer=validatorでなければならない。
     * @param matrixId 実行する MatrixのID
     * @param to Eggの生成先
     * @return 生成したEggのID
     */
    function spawn(uint256 matrixId, address to) external returns (uint256) {
        require(
            registered[matrixId].matrix != address(0x0),
            "MatrixMaster: invalid matrixId"
        );
        IMatrix matrix = IMatrix(registered[matrixId].matrix);
        address developer = matrix.getOwner();
        uint256 squareKey = matrix.correspondingSquareKey();
        address validator = _squareContract.validatorOf(squareKey);
        address squareOwner = _squareContract.ownerOf(squareKey);
        require(
            msg.sender == squareOwner,
            "MatrixMaster: caller is not validator of the matrix"
        );
        uint256 price = registered[matrixId].price;
        uint256 allowance = IAnima(_animaContract).allowance(
            msg.sender,
            address(this)
        );
        require(allowance >= price, "ERC20: insufficient allowance");
        IEggBuilder.ComposeCondition memory cond = matrix.spawnCondition();
        /*        uint256 balance = IERC1155(_shard).balanceOf(address(matrix),cond.shardId1);
        require(balance >= cond.numShard1,"MatrixMaster: insufficient shard1");
        balance = IERC1155(_shard).balanceOf(address(matrix),cond.shardId2);
        require(balance >= cond.numShard2,"MatrixMaster: insufficient shard2");*/
        uint256 eggId = IEggBuilder(_eggBuilder).compose(
            cond,
            to,
            address(matrix)
        );
        if (_circulator != address(this)) {
            IAnima(_animaContract).transferFrom(msg.sender, _circulator, price);
            IANMDailyCirculator(_circulator).onSpawn(
                eggId,
                validator,
                developer,
                price
            );
        }
        emit Spawn(matrixId, eggId, to, price);
        return eggId;
    }

    function spawnBatch(
        uint256 matrixId,
        uint256 numEggs,
        address to
    ) external returns (uint256[] memory) {
        require(
            registered[matrixId].matrix != address(0x0),
            "MatrixMaster: invalid matrixId"
        );
        IMatrix matrix = IMatrix(registered[matrixId].matrix);
        address developer = matrix.getOwner();
        uint256 squareKey = matrix.correspondingSquareKey();
        address validator = _squareContract.validatorOf(squareKey);
        address squareOwner = _squareContract.ownerOf(squareKey);
        require(
            msg.sender == squareOwner,
            "MatrixMaster: caller is not square key owner of the matrix"
        );
        uint256 price = registered[matrixId].price * numEggs;
        uint256 allowance = IAnima(_animaContract).allowance(
            msg.sender,
            address(this)
        );
        require(allowance >= price, "MatrixMaster: insufficient allowance");
        IAnima(_animaContract).transferFrom(msg.sender, _circulator, price);
        uint256[] memory eggIds = new uint256[](numEggs);
        for (uint256 i = 0; i < numEggs; i++) {
            IEggBuilder.ComposeCondition memory cond = matrix.spawnCondition();
            eggIds[i] = IEggBuilder(_eggBuilder).compose(
                cond,
                to,
                address(matrix)
            );
            if (_circulator != address(this)) {
                IANMDailyCirculator(_circulator).onSpawn(
                    eggIds[i],
                    validator,
                    developer,
                    price
                );
            }
        }
        emit SpawnBatch(matrixId, eggIds, to, price);
        return eggIds;
    }
}