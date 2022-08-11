/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// File: contracts/protocol_fee_provider/interfaces/IProtocolFeeProvider.sol


interface IProtocolFeeProvider {
    function getProtocolFeeBasisPoint(address owner) external view returns (uint);
}

// File: contracts/oases_exchange/libraries/BasisPointLibrary.sol


library BasisPointLibrary {
    function basisPointCalculate(uint256 value, uint256 basisPointValue) internal pure returns (uint256) {
        return value * basisPointValue / 10000;
    }
}

// File: contracts/common_libraries/PartLibrary.sol


library PartLibrary {

    struct Part {
        address payable account;
        uint96 value;
    }

    bytes32 public constant PART_TYPEHASH = keccak256("Part(address account,uint96 value)");

    function getHash(Part memory part) internal pure returns (bytes32){
        return keccak256(
            abi.encode(PART_TYPEHASH, part.account, part.value)
        );
    }
}

// File: contracts/tokens/erc1155/libraries/ERC1155LazyMintLibrary.sol


library ERC1155LazyMintLibrary {

    struct ERC1155LazyMintData {
        uint256 tokenId;
        uint256 supply;
        string tokenURI;
        PartLibrary.Part[] creatorInfos;
        PartLibrary.Part[] royaltyInfos;
        bytes[] signatures;
    }

    bytes4 constant public ERC1155_LAZY_MINT_ASSET_CLASS = bytes4(keccak256("ERC1155_LAZY_MINT_CLASS"));
    bytes4 constant _INTERFACE_ID_MINT_AND_TRANSFER = 0x6db15a0f;
    bytes32 public constant ERC1155_LAZY_MINT_DATA_TYPEHASH = keccak256(
        "Mint1155(uint256 tokenId,uint256 supply,string tokenURI,Part[] creators,Part[] royalties)Part(address account,uint96 value)"
    );

    function getHash(ERC1155LazyMintData memory erc1155LazyMintData) internal pure returns (bytes32) {
        bytes32[] memory creatorInfosHashes = new bytes32[](erc1155LazyMintData.creatorInfos.length);
        for (uint256 i = 0; i < erc1155LazyMintData.creatorInfos.length; ++i) {
            creatorInfosHashes[i] = PartLibrary.getHash(erc1155LazyMintData.creatorInfos[i]);
        }

        bytes32[] memory royaltyInfosHashes = new bytes32[](erc1155LazyMintData.royaltyInfos.length);
        for (uint256 i = 0; i < erc1155LazyMintData.royaltyInfos.length; ++i) {
            royaltyInfosHashes[i] = PartLibrary.getHash(erc1155LazyMintData.royaltyInfos[i]);
        }

        return keccak256(
            abi.encode(
                ERC1155_LAZY_MINT_DATA_TYPEHASH,
                erc1155LazyMintData.tokenId,
                erc1155LazyMintData.supply,
                keccak256(bytes(erc1155LazyMintData.tokenURI)),
                keccak256(abi.encodePacked(creatorInfosHashes)),
                keccak256(abi.encodePacked(royaltyInfosHashes))
            )
        );
    }
}

// File: contracts/tokens/erc721/libraries/ERC721LazyMintLibrary.sol


library ERC721LazyMintLibrary {
    struct ERC721LazyMintData {
        uint256 tokenId;
        string tokenURI;
        PartLibrary.Part[] creatorInfos;
        PartLibrary.Part[] royaltyInfos;
        bytes[] signatures;
    }

    bytes4 public constant ERC721_LAZY_MINT_ASSET_CLASS = bytes4(keccak256("ERC721_LAZY_MINT_CLASS"));
    bytes4 constant _INTERFACE_ID_MINT_AND_TRANSFER = 0x8486f69f;
    bytes32 public constant ERC721_LAZY_MINT_DATA_TYPEHASH =
        keccak256(
            "Mint721(uint256 tokenId,string tokenURI,Part[] creators,Part[] royalties)Part(address account,uint96 value)"
        );

    function getHash(ERC721LazyMintData memory erc721LazyMintData) internal pure returns (bytes32) {
        bytes32[] memory creatorInfosHashes = new bytes32[](
            erc721LazyMintData.creatorInfos.length
        );
        for (uint256 i = 0; i < erc721LazyMintData.creatorInfos.length; ++i) {
            creatorInfosHashes[i] = PartLibrary.getHash(
                erc721LazyMintData.creatorInfos[i]
            );
        }

        bytes32[] memory royaltyInfosHashes = new bytes32[](
            erc721LazyMintData.royaltyInfos.length
        );
        for (uint256 i = 0; i < erc721LazyMintData.royaltyInfos.length; ++i) {
            royaltyInfosHashes[i] = PartLibrary.getHash(
                erc721LazyMintData.royaltyInfos[i]
            );
        }

        return keccak256(
            abi.encode(
                ERC721_LAZY_MINT_DATA_TYPEHASH,
                erc721LazyMintData.tokenId,
                keccak256(bytes(erc721LazyMintData.tokenURI)),
                keccak256(abi.encodePacked(creatorInfosHashes)),
                keccak256(abi.encodePacked(royaltyInfosHashes))
            ));
    }
}

// File: contracts/royalties/interfaces/IRoyaltiesProvider.sol


pragma abicoder v2;


interface IRoyaltiesProvider {
    function getRoyaltyInfos(address tokenAddress, uint256 tokenId) external returns (PartLibrary.Part[] memory);
}

// File: contracts/oases_exchange/libraries/OrderDataLibrary.sol


library OrderDataLibrary {

    struct Data {
        PartLibrary.Part[] payoutInfos;
        // explicit royalty infos
        PartLibrary.Part[] royaltyInfos;
        PartLibrary.Part[] originFeeInfos;
        bool isMakeFill;
    }

    bytes4 constant public V1 = bytes4(keccak256("V1"));

    function decodeData(bytes memory dataBytes) internal pure returns (Data memory){
        return abi.decode(dataBytes, (Data));
    }
}

// File: @openzeppelin/contracts-upgradeable/interfaces/IERC1271Upgradeable.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)


/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271Upgradeable {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// File: @openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)


/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)


/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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

// File: contracts/oases_exchange/libraries/MathLibrary.sol


library MathLibrary {

    // @dev Calculates partial value given a numerator and denominator rounded down.
    //      Reverts if rounding error is >= 0.1%
    // @param numerator Numerator.
    // @param denominator Denominator.
    // @param target value to calculate partial of.
    // @return partial amount value of target rounded down.
    function safeGetPartialAmountWithFloorRounding(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
    internal
    pure
    returns
    (uint256)
    {
        require(
            !isFloorRoundingError(numerator, denominator, target),
            "bad floor rounding"
        );

        return numerator * target / denominator;
    }

    function isFloorRoundingError(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
    internal
    pure
    returns
    (bool)
    {
        require(denominator != 0, "zero divisor");

        // The absolute rounding error is the difference between the rounded
        // value and the ideal value. The relative rounding error is the
        // absolute rounding error divided by the absolute value of the
        // ideal value. This is undefined when the ideal value is zero.
        //
        // The ideal value is `numerator * target / denominator`.
        // Let's call `numerator * target % denominator` the remainder.
        // The absolute error is `remainder / denominator`.
        //
        // When the ideal value is zero, we require the absolute error to
        // be zero. Fortunately, this is always the case. The ideal value is
        // zero iff `numerator == 0` and/or `target == 0`. In this case the
        // remainder and absolute error are also zero.
        if (target == 0 || numerator == 0) {
            return false;
        }

        // Otherwise, we want the relative rounding error to be strictly
        // less than 0.1%.
        // The relative error is `remainder / (numerator * target)`.
        // We want the relative error less than 1 / 1000:
        //        remainder / (numerator * target)  <  1 / 1000
        // or equivalently:
        //        1000 * remainder  <  numerator * target
        // so we have a rounding error if:
        //        1000 * remainder  >=  numerator * target
        uint256 remainder = mulmod(target, numerator, denominator);
        return remainder * 1000 >= numerator * target;
    }
}

// File: contracts/oases_exchange/libraries/TransferHelperLibrary.sol


library TransferHelperLibrary {
    // helpful library for transfer from contract to an address as the receiver
    function transferEth(address receiver, uint256 amount) internal {
        (bool success,) = receiver.call{value: amount}("");
        require(success, "bad eth transfer");
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol


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
interface IERC165Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

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
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

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
    function balanceOf(address account, uint256 id) external view returns (uint256);

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
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File: @openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

// File: contracts/interfaces/INFTTransferProxy.sol


interface INFTTransferProxy {
    function safeTransferFromERC721(
        IERC721Upgradeable addressERC721,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFromERC1155(
        IERC1155Upgradeable addressERC1155,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/interfaces/IERC20TransferProxy.sol


interface IERC20TransferProxy {
    function safeTransferFromERC20(
        IERC20Upgradeable addressERC20,
        address sender,
        address recipient,
        uint256 amount
    ) external;
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)


/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/cryptography/SignatureChecker.sol)


/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * ERC1271 contract signatures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureCheckerUpgradeable {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable.tryRecover(hash, signature);
        if (error == ECDSAUpgradeable.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271Upgradeable.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271Upgradeable.isValidSignature.selector);
    }
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol


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
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

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
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
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
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// File: contracts/common_libraries/AssetLibrary.sol


library AssetLibrary {

    struct AssetType {
        bytes4 assetClass;
        bytes data;
    }

    struct Asset {
        AssetType assetType;
        uint256 value;
    }

    bytes4 constant public ETH_ASSET_CLASS = bytes4(keccak256("ETH_CLASS"));
    bytes4 constant public ERC20_ASSET_CLASS = bytes4(keccak256("ERC20_CLASS"));
    bytes4 constant public ERC721_ASSET_CLASS = bytes4(keccak256("ERC721_CLASS"));
    bytes4 constant public ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155_CLASS"));
    bytes4 constant public COLLECTION = bytes4(keccak256("COLLECTION_CLASS"));
    bytes4 constant public CRYPTO_PUNKS = bytes4(keccak256("CRYPTO_PUNKS_CLASS"));

    bytes32 constant ASSET_TYPE_TYPEHASH = keccak256(
        "AssetType(bytes4 assetClass,bytes data)"
    );

    bytes32 constant ASSET_TYPEHASH = keccak256(
        "Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)"
    );

    function getHash(AssetType memory assetType) internal pure returns (bytes32){
        return keccak256(
            abi.encode(
                ASSET_TYPE_TYPEHASH,
                assetType.assetClass,
                keccak256(assetType.data)
            )
        );
    }

    function getHash(Asset memory asset) internal pure returns (bytes32){
        return keccak256(
            abi.encode(
                ASSET_TYPEHASH,
                getHash(asset.assetType),
                asset.value
            ));
    }
}

// File: contracts/oases_exchange/libraries/FeeSideLibrary.sol


library FeeSideLibrary {

    enum FeeSide {NONE, MAKE, TAKE}

    function getFeeSide(bytes4 makeAssetClass, bytes4 takeAssetClass) internal pure returns (FeeSide){
        FeeSide feeSide = FeeSide.NONE;
        if (makeAssetClass == AssetLibrary.ETH_ASSET_CLASS) {
            feeSide = FeeSide.MAKE;
        } else if (takeAssetClass == AssetLibrary.ETH_ASSET_CLASS) {
            feeSide = FeeSide.TAKE;
        } else if (makeAssetClass == AssetLibrary.ERC20_ASSET_CLASS) {
            feeSide = FeeSide.MAKE;
        } else if (takeAssetClass == AssetLibrary.ERC20_ASSET_CLASS) {
            feeSide = FeeSide.TAKE;
        } else if (makeAssetClass == AssetLibrary.ERC1155_ASSET_CLASS) {
            feeSide = FeeSide.MAKE;
        } else if (takeAssetClass == AssetLibrary.ERC1155_ASSET_CLASS) {
            feeSide = FeeSide.TAKE;
        }

        return feeSide;
    }
}

// File: contracts/oases_exchange/libraries/OrderLibrary.sol



pragma solidity 0.8.8;



library OrderLibrary {

    struct Order {
        address maker;
        AssetLibrary.Asset makeAsset;
        address taker;
        AssetLibrary.Asset takeAsset;
        uint256 salt;
        uint256 startTime;
        uint256 endTime;
        bytes4 dataType;
        bytes data;
    }

    bytes32 constant ORDER_TYPEHASH = keccak256(
        "Order(address maker,Asset makeAsset,address taker,Asset takeAsset,uint256 salt,uint256 startTime,uint256 endTime,bytes4 dataType,bytes data)Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)"
    );

    function checkTimeValidity(Order memory order) internal view {
        uint256 currentTimestamp = block.timestamp;
        require(order.startTime == 0 || order.startTime < currentTimestamp, "Order start validation failed");
        require(order.endTime == 0 || order.endTime > currentTimestamp, "Order end validation failed");
    }

    function getHash(Order memory order) internal pure returns (bytes32){
        return keccak256(
            abi.encode(
                ORDER_TYPEHASH,
                order.maker,
                AssetLibrary.getHash(order.makeAsset),
                order.taker,
                AssetLibrary.getHash(order.takeAsset),
                order.salt,
                order.startTime,
                order.endTime,
                order.dataType,
                keccak256(order.data)
            )
        );
    }

    function getHashKey(Order memory order) internal pure returns (bytes32){
        return keccak256(
            abi.encode(
                order.maker,
                AssetLibrary.getHash(order.makeAsset.assetType),
                AssetLibrary.getHash(order.takeAsset.assetType),
                order.salt,
                order.data
            )
        );
    }

    function calculateRemainingValuesInOrder(
        Order memory order,
        uint256 fill,
        bool isMakeFill
    )
    internal
    pure
    returns
    (uint256 makeRemainingValue, uint256 takeRemainingValue)
    {
        if (isMakeFill) {
            makeRemainingValue = order.makeAsset.value - fill;
            takeRemainingValue = MathLibrary.safeGetPartialAmountWithFloorRounding(
                order.takeAsset.value,
                order.makeAsset.value,
                makeRemainingValue
            );
        } else {
            takeRemainingValue = order.takeAsset.value - fill;
            makeRemainingValue = MathLibrary.safeGetPartialAmountWithFloorRounding(
                order.makeAsset.value,
                order.takeAsset.value,
                takeRemainingValue
            );
        }
    }
}

// File: contracts/oases_exchange/libraries/FillLibrary.sol


library FillLibrary {

    struct FillResult {
        uint256 leftValue;
        uint256 rightValue;
    }

    function fillOrders(
        OrderLibrary.Order memory leftOrder,
        OrderLibrary.Order memory rightOrder,
        uint256 leftOrderFillRecord,
        uint256 rightOrderFillRecord,
        bool leftOrderIsMakeFill,
        bool rightOrderIsMakeFill
    )
    internal
    pure
    returns
    (FillResult memory fillResult)
    {
        (uint256 leftOrderMakeValue,uint256 leftOrderTakeValue) = OrderLibrary.calculateRemainingValuesInOrder(
            leftOrder,
            leftOrderFillRecord,
            leftOrderIsMakeFill
        );

        (uint256 rightOrderMakeValue,uint256 rightOrderTakeValue) = OrderLibrary.calculateRemainingValuesInOrder(
            rightOrder,
            rightOrderFillRecord,
            rightOrderIsMakeFill
        );

        if (rightOrderTakeValue > leftOrderMakeValue) {
            // left order will be filled fully this time
            uint256 rightShouldTakeAsRightRate = MathLibrary.safeGetPartialAmountWithFloorRounding(
                leftOrderTakeValue,
                rightOrder.makeAsset.value,
                rightOrder.takeAsset.value
            );
            require(rightShouldTakeAsRightRate <= leftOrderMakeValue, "bad fill when left order should be filled fully");
            fillResult.leftValue = leftOrderMakeValue;
            fillResult.rightValue = leftOrderTakeValue;
        } else {
            // right order will be filled fully this time
            // or
            // both of left and right ones will be fully filled together
            uint256 leftShouldMakeAsLeftRate = MathLibrary.safeGetPartialAmountWithFloorRounding(
                rightOrderTakeValue,
                leftOrder.makeAsset.value,
                leftOrder.takeAsset.value
            );
            require(leftShouldMakeAsLeftRate <= rightOrderMakeValue, "bad fill when right order or both sides should be filled fully");
            fillResult.leftValue = rightOrderTakeValue;
            fillResult.rightValue = leftShouldMakeAsLeftRate;
        }
    }
}

// File: contracts/oases_exchange/libraries/OrderDataParsingLibrary.sol


library OrderDataParsingLibrary {
    function parse(OrderLibrary.Order memory order) pure internal returns (OrderDataLibrary.Data memory orderData){
        if (order.dataType == OrderDataLibrary.V1) {
            orderData = OrderDataLibrary.decodeData(order.data);
        } else {
            require(order.dataType == 0xffffffff, "unsupported order data type");
        }

        if (orderData.payoutInfos.length == 0) {
            orderData.payoutInfos = new PartLibrary.Part[](1);
            orderData.payoutInfos[0].account = payable(order.maker);
            orderData.payoutInfos[0].value = 10000;
        }
    }
}

// File: contracts/oases_exchange/OrderVerifier.sol


abstract contract OrderVerifier is ContextUpgradeable, EIP712Upgradeable {
    using AddressUpgradeable for address;

    function __OrderVerifier_init_unchained() internal onlyInitializing {
        __EIP712_init_unchained("OasesExchange", "1");
    }

    function verifyOrder(OrderLibrary.Order memory order, bytes memory signature) internal view {
        if (order.salt == 0) {
            if (order.maker != address(0)) {
                require(_msgSender() == order.maker, "maker is not tx sender");
            } else {
                order.maker = _msgSender();
            }
        } else {
            if (_msgSender() != order.maker) {
                require(
                    SignatureCheckerUpgradeable.isValidSignatureNow(
                        order.maker,
                        _hashTypedDataV4(OrderLibrary.getHash(order)),
                        signature
                    ),
                    "bad order signature verification"
                );
            }
        }
    }

    uint256[50] private __gap;
}

// File: contracts/interfaces/ITransferProxy.sol


interface ITransferProxy {
    function transfer(AssetLibrary.Asset memory asset, address from, address to) external;
}

// File: contracts/interfaces/ICashier.sol


abstract contract ICashier {
    event Transfer(AssetLibrary.Asset asset, address from, address to, bytes4 direction, bytes4 transferType);

    function transfer(
        AssetLibrary.Asset memory asset,
        address from,
        address to,
        bytes4 transferType,
        bytes4 direction
    ) internal virtual;
}

// File: contracts/oases_exchange/interfaces/ICashierManager.sol


abstract contract ICashierManager is ICashier {
    // transfer direction
    bytes4 constant TO_MAKER_DIRECTION = bytes4(keccak256("TO_MAKER_DIRECTION"));
    bytes4 constant TO_TAKER_DIRECTION = bytes4(keccak256("TO_TAKER_DIRECTION"));

    // transfer type
    bytes4 constant PROTOCOL_FEE = bytes4(keccak256("PROTOCOL_FEE_TYPE"));
    bytes4 constant ROYALTY = bytes4(keccak256("ROYALTY_TYPE"));
    bytes4 constant ORIGIN_FEE = bytes4(keccak256("ORIGIN_FEE_TYPE"));
    bytes4 constant PAYMENT = bytes4(keccak256("PAYMENT_TYPE"));

    function allocateAssets(
        FillLibrary.FillResult memory fillResult,
        AssetLibrary.AssetType memory matchedMakeAssetType,
        AssetLibrary.AssetType memory matchedTakeAssetType,
        OrderLibrary.Order memory leftOrder,
        OrderLibrary.Order memory rightOrder,
        OrderDataLibrary.Data memory leftOrderData,
        OrderDataLibrary.Data memory rightOrderData
    ) internal virtual returns (uint256 totalMakeAmount, uint256 totalTakeAmount);
}

// File: contracts/oases_exchange/OasesCashierManager.sol


abstract contract OasesCashierManager is OwnableUpgradeable, ICashierManager {
    using BasisPointLibrary for uint256;
    using AddressUpgradeable for address;

    mapping(address => address) feeReceivers;
    address defaultFeeReceiver;
    IProtocolFeeProvider protocolFeeProvider;

    function __OasesCashierManager_init_unchained(
        address newDefaultFeeReceiver,
        IProtocolFeeProvider newProtocolFeeProvider
    ) internal onlyInitializing {
        defaultFeeReceiver = newDefaultFeeReceiver;
        protocolFeeProvider = newProtocolFeeProvider;
    }

    // set protocol fee provider address by the owner
    function setProtocolFeeProvider(address newProtocolFeeProvider) external onlyOwner {
        require(newProtocolFeeProvider.isContract(), "not CA");
        protocolFeeProvider = IProtocolFeeProvider(newProtocolFeeProvider);
    }

    // set default fee receiver address by the owner
    function setDefaultFeeReceiver(address newDefaultFeeReceiver) external onlyOwner {
        defaultFeeReceiver = newDefaultFeeReceiver;
    }

    // set the receiver for each token by the owner
    function setFeeReceiver(address tokenAddress, address receiver) external onlyOwner {
        feeReceivers[tokenAddress] = receiver;
    }

    // get the address of protocol fee provider
    function getProtocolFeeProvider() public view returns (address){
        return address(protocolFeeProvider);
    }

    // get the address of default fee receiver
    function getDefaultFeeReceiver() public view returns (address){
        return defaultFeeReceiver;
    }

    // get fee receiver address by asset address
    function getFeeReceiver(address assetAddress) public view returns (address){
        address receiverAddress = feeReceivers[assetAddress];
        if (receiverAddress != address(0)) {
            return receiverAddress;
        }

        return defaultFeeReceiver;
    }

    function allocateAssets(
        FillLibrary.FillResult memory fillResult,
        AssetLibrary.AssetType memory matchedMakeAssetType,
        AssetLibrary.AssetType memory matchedTakeAssetType,
        OrderLibrary.Order memory leftOrder,
        OrderLibrary.Order memory rightOrder,
        OrderDataLibrary.Data memory leftOrderData,
        OrderDataLibrary.Data memory rightOrderData
    )
    internal
    override
    returns
    (uint256 totalMakeAmount, uint256 totalTakeAmount)
    {
        totalMakeAmount = fillResult.leftValue;
        totalTakeAmount = fillResult.rightValue;

        // get fee side
        FeeSideLibrary.FeeSide feeSide = FeeSideLibrary.getFeeSide(
            matchedMakeAssetType.assetClass,
            matchedTakeAssetType.assetClass
        );
        if (feeSide == FeeSideLibrary.FeeSide.MAKE) {
            totalMakeAmount = transferPaymentWithFeesAndRoyalties(
                leftOrder.maker,
                rightOrder.maker,
                fillResult.leftValue,
                leftOrderData,
                rightOrderData,
                matchedMakeAssetType,
                matchedTakeAssetType,
                TO_TAKER_DIRECTION
            );
            transferPayment(
                rightOrder.maker,
                fillResult.rightValue,
                matchedTakeAssetType,
                leftOrderData.payoutInfos,
                TO_MAKER_DIRECTION
            );
        } else if (feeSide == FeeSideLibrary.FeeSide.TAKE) {
            totalTakeAmount = transferPaymentWithFeesAndRoyalties(
                rightOrder.maker,
                leftOrder.maker,
                fillResult.rightValue,
                rightOrderData,
                leftOrderData,
                matchedTakeAssetType,
                matchedMakeAssetType,
                TO_MAKER_DIRECTION
            );
            transferPayment(
                leftOrder.maker,
                fillResult.leftValue,
                matchedMakeAssetType,
                rightOrderData.payoutInfos,
                TO_TAKER_DIRECTION
            );
        } else {
            // no fee side
            transferPayment(
                leftOrder.maker,
                fillResult.leftValue,
                matchedMakeAssetType,
                rightOrderData.payoutInfos,
                TO_TAKER_DIRECTION
            );
            transferPayment(
                rightOrder.maker,
                fillResult.rightValue,
                matchedTakeAssetType,
                leftOrderData.payoutInfos,
                TO_MAKER_DIRECTION
            );
        }
    }

    function transferPaymentWithFeesAndRoyalties(
        address payer,
        address customizedProtocolFeeChecker,
        uint256 amountToCalculate,
        OrderDataLibrary.Data memory paymentData,
        OrderDataLibrary.Data memory nftData,
        AssetLibrary.AssetType memory paymentType,
        AssetLibrary.AssetType memory nftType,
        bytes4 direction
    )
    internal
    returns
    (uint256 totalAmount)
    {
        totalAmount = sumAmountAndFees(amountToCalculate, paymentData.originFeeInfos);
        uint256 rest = transferProtocolFee(
            payer,
            customizedProtocolFeeChecker,
            totalAmount,
            amountToCalculate,
            paymentType,
            direction
        );
        rest = transferRoyalties(
            payer,
            rest,
            amountToCalculate,
            paymentType,
            nftType,
            nftData.royaltyInfos,
            direction
        );
        (rest,) = transferFees(
            payer,
            false,
            rest,
            amountToCalculate,
            paymentType,
            paymentData.originFeeInfos,
            ORIGIN_FEE,
            direction
        );
        (rest,) = transferFees(
            payer,
            false,
            rest,
            amountToCalculate,
            paymentType,
            nftData.originFeeInfos,
            ORIGIN_FEE,
            direction
        );
        transferPayment(
            payer,
            rest,
            paymentType,
            nftData.payoutInfos,
            direction
        );
    }

    function transferProtocolFee(
        address payer,
        address customizedProtocolFeeChecker,
        uint256 totalAmountAndFeesRest,
        uint256 amountToCalculateFee,
        AssetLibrary.AssetType memory paymentType,
        bytes4 direction
    )
    internal
    returns
    (uint256)
    {
        (uint256 rest, uint256 fee) = deductFeeWithBasisPoint(
            totalAmountAndFeesRest,
            amountToCalculateFee,
            protocolFeeProvider.getProtocolFeeBasisPoint(customizedProtocolFeeChecker)
        );
        if (fee > 0) {
            address paymentAddress = address(0);
            if (paymentType.assetClass == AssetLibrary.ERC20_ASSET_CLASS) {
                paymentAddress = abi.decode(paymentType.data, (address));
            } else if (paymentType.assetClass == AssetLibrary.ERC1155_ASSET_CLASS) {
                uint256 tokenId;
                (paymentAddress, tokenId) = abi.decode(paymentType.data, (address, uint256));
            }

            // transfer fee
            transfer(
                AssetLibrary.Asset({
            assetType : paymentType,
            value : fee
            }),
                payer,
                getFeeReceiver(paymentAddress),
                PROTOCOL_FEE,
                direction
            );
        }

        return rest;
    }

    function transferFees(
        address payer,
        bool doSumFeeBasisPoints,
        uint256 totalAmountAndFeesRest,
        uint256 amountToCalculateFee,
        AssetLibrary.AssetType memory paymentType,
        PartLibrary.Part[] memory feeInfos,
        bytes4 transferType,
        bytes4 direction
    )
    internal
    returns
    (uint256 rest, uint256 totalFeeBasisPoints)
    {
        rest = totalAmountAndFeesRest;
        for (uint256 i = 0; i < feeInfos.length; ++i) {
            if (doSumFeeBasisPoints) {
                totalFeeBasisPoints += feeInfos[i].value;
            }
            uint256 fee;
            (rest, fee) = deductFeeWithBasisPoint(rest, amountToCalculateFee, feeInfos[i].value);
            if (fee > 0) {
                // transfer fee
                transfer(
                    AssetLibrary.Asset({
                assetType : paymentType,
                value : fee
                }),
                    payer,
                    feeInfos[i].account,
                    transferType,
                    direction
                );
            }
        }
    }

    // only nft has royalty
    function transferRoyalties(
        address payer,
        uint256 totalAmountAndFeesRest,
        uint256 amountToCalculateRoyalties,
        AssetLibrary.AssetType memory royaltyType,
        AssetLibrary.AssetType memory nftType,
        PartLibrary.Part[] memory royaltyInfosForExistedNFT,
        bytes4 direction
    )
    internal
    returns
    (uint256)
    {
        PartLibrary.Part[] memory royaltyInfos;
        // get infos of royalties
        if (nftType.assetClass == AssetLibrary.ERC721_ASSET_CLASS || nftType.assetClass == AssetLibrary.ERC1155_ASSET_CLASS) {
            royaltyInfos = royaltyInfosForExistedNFT;
        } else if (nftType.assetClass == ERC721LazyMintLibrary.ERC721_LAZY_MINT_ASSET_CLASS) {
            // decode the royaltyInfos of lazy mint erc721
            (, ERC721LazyMintLibrary.ERC721LazyMintData memory erc721LazyMintData) = abi.decode(
                nftType.data,
                (address, ERC721LazyMintLibrary.ERC721LazyMintData)
            );
            royaltyInfos = erc721LazyMintData.royaltyInfos;
        } else if (nftType.assetClass == ERC1155LazyMintLibrary.ERC1155_LAZY_MINT_ASSET_CLASS) {
            // decode the royaltyInfos of lazy mint erc1155
            (, ERC1155LazyMintLibrary.ERC1155LazyMintData memory erc1155LazyMintData) = abi.decode(
                nftType.data,
                (address, ERC1155LazyMintLibrary.ERC1155LazyMintData)
            );
            royaltyInfos = erc1155LazyMintData.royaltyInfos;
        }

        (uint256 rest, uint256 totalFeeBasisPoints) = transferFees(
            payer,
            true,
            totalAmountAndFeesRest,
            amountToCalculateRoyalties,
            royaltyType,
            royaltyInfos,
            ROYALTY,
            direction
        );

        require(totalFeeBasisPoints <= 5000, "royalties sum exceeds 50%");

        return rest;
    }

    function transferPayment(
        address payer,
        uint256 amountToCalculate,
        AssetLibrary.AssetType memory paymentType,
        PartLibrary.Part[] memory paymentInfos,
        bytes4 direction
    )
    internal
    {
        uint256 totalFeeBasisPoints = 0;
        uint256 rest = amountToCalculate;
        uint256 lastPartIndex = paymentInfos.length - 1;
        for (uint256 i = 0; i < lastPartIndex; ++i) {
            PartLibrary.Part memory paymentInfo = paymentInfos[i];
            uint256 amountToPay = amountToCalculate.basisPointCalculate(paymentInfo.value);
            totalFeeBasisPoints += paymentInfo.value;
            if (amountToPay > 0) {
                rest -= amountToPay;
                transfer(
                    AssetLibrary.Asset({
                assetType : paymentType,
                value : amountToPay
                }),
                    payer,
                    paymentInfo.account,
                    PAYMENT,
                    direction
                );
            }
        }

        PartLibrary.Part memory lastPaymentInfo = paymentInfos[lastPartIndex];
        require(
            totalFeeBasisPoints + lastPaymentInfo.value == 10000,
            "total bps of payment is not 100%"
        );
        if (rest > 0) {
            transfer(
                AssetLibrary.Asset({
            assetType : paymentType,
            value : rest
            }),
                payer,
                lastPaymentInfo.account,
                PAYMENT,
                direction
            );
        }
    }

    // calculate the sum of amount and all fees
    function sumAmountAndFees(
        uint256 amount,
        PartLibrary.Part[] memory orderOriginalFees
    )
    internal
    pure
    returns
    (uint256 totalSum)
    {
        totalSum = amount;
        for (uint256 i = 0; i < orderOriginalFees.length; ++i) {
            totalSum += amount.basisPointCalculate(orderOriginalFees[i].value);
        }
    }

    function deductFeeWithBasisPoint(
        uint256 value,
        uint256 amountToCalculateFee,
        uint256 feeBasisPoint
    )
    internal
    pure
    returns
    (uint256 rest, uint256 realFee){
        uint256 fee = amountToCalculateFee.basisPointCalculate(feeBasisPoint);
        if (value > fee) {
            rest = value - fee;
            realFee = fee;
        } else {
            rest = 0;
            realFee = value;
        }
    }

    uint256[47] private __gap;
}

// File: contracts/oases_exchange/Cashier.sol


abstract contract Cashier is OwnableUpgradeable, ICashier {
    using TransferHelperLibrary for address;

    mapping(bytes4 => address) transferProxies;

    event SetTransferProxy(bytes4 indexed assetType, address transferProxyAddress);

    function __Cashier_init_unchained(
        IERC20TransferProxy ERC20TransferProxyAddress,
        INFTTransferProxy NFTTransferProxyAddress
    ) internal {
        transferProxies[AssetLibrary.ERC20_ASSET_CLASS] = address(ERC20TransferProxyAddress);
        transferProxies[AssetLibrary.ERC721_ASSET_CLASS] = address(NFTTransferProxyAddress);
        transferProxies[AssetLibrary.ERC1155_ASSET_CLASS] = address(NFTTransferProxyAddress);
    }

    function transfer(
        AssetLibrary.Asset memory asset,
        address from,
        address to,
        bytes4 transferType,
        bytes4 direction
    )
    internal
    override
    {
        if (asset.assetType.assetClass == AssetLibrary.ETH_ASSET_CLASS) {
            to.transferEth(asset.value);
        } else if (asset.assetType.assetClass == AssetLibrary.ERC20_ASSET_CLASS) {
            // decode ERC20 address
            (address addressERC20) = abi.decode(asset.assetType.data, (address));
            IERC20TransferProxy(transferProxies[AssetLibrary.ERC20_ASSET_CLASS]).safeTransferFromERC20(
                IERC20Upgradeable(addressERC20),
                from,
                to,
                asset.value
            );
        } else if (asset.assetType.assetClass == AssetLibrary.ERC721_ASSET_CLASS) {
            // decode ERC721 address and token id
            (address addressERC721, uint256 tokenId) = abi.decode(asset.assetType.data, (address, uint256));
            require(asset.value == 1, "ERC721's strict amount");
            INFTTransferProxy(transferProxies[AssetLibrary.ERC721_ASSET_CLASS]).safeTransferFromERC721(
                IERC721Upgradeable(addressERC721),
                from,
                to,
                tokenId
            );
        } else if (asset.assetType.assetClass == AssetLibrary.ERC1155_ASSET_CLASS) {
            // decode ERC1155 address and id
            (address addressERC1155, uint256 id) = abi.decode(asset.assetType.data, (address, uint256));
            INFTTransferProxy(transferProxies[AssetLibrary.ERC1155_ASSET_CLASS]).safeTransferFromERC1155(
                IERC1155Upgradeable(addressERC1155),
                from,
                to,
                id,
                asset.value,
                ""
            );
        } else {
            // transfer the asset(not ETH/ERC20/ERC721/ERC1155) by customized transfer proxy
            ITransferProxy(transferProxies[asset.assetType.assetClass]).transfer(asset, from, to);
        }

        emit Transfer(asset, from, to, direction, transferType);
    }

    // set transfer proxy address by the owner
    function setTransferProxy(bytes4 assetType, address transferProxyAddress) external onlyOwner {
        transferProxies[assetType] = transferProxyAddress;
        emit SetTransferProxy(assetType, transferProxyAddress);
    }

    uint256[49] private __gap;
}

// File: contracts/interfaces/IAssetTypeMatcher.sol


interface IAssetTypeMatcher {
    function matchAssetTypes(
        AssetLibrary.AssetType memory leftAssetType,
        AssetLibrary.AssetType memory rightAssetType
    )
    external
    view
    returns
    (AssetLibrary.AssetType memory);
}

// File: contracts/oases_exchange/AssetTypeMatcher.sol


abstract contract AssetTypeMatcher is OwnableUpgradeable {

    bytes constant EMPTY_BYTES = "";

    mapping(bytes4 => address) assetTypeMatchers;

    event AssetTypeMatcherChange(bytes4 indexed assetType, address matcherAddress);

    // set asset type matcher by the owner of the contract
    function setAssetTypeMatcher(bytes4 assetType, address matcherAddress) external onlyOwner {
        assetTypeMatchers[assetType] = matcherAddress;
        emit AssetTypeMatcherChange(assetType, matcherAddress);
    }

    function generalMatch(
        AssetLibrary.AssetType memory leftAssetType,
        AssetLibrary.AssetType memory rightAssetType
    )
    private
    pure
    returns
    (AssetLibrary.AssetType memory)
    {
        if (keccak256(leftAssetType.data) == keccak256(rightAssetType.data)) {
            return leftAssetType;
        }

        return AssetLibrary.AssetType(0, EMPTY_BYTES);
    }

    function matchAssetTypesByOneSide(
        AssetLibrary.AssetType memory leftAssetType,
        AssetLibrary.AssetType memory rightAssetType
    )
    private
    view
    returns
    (AssetLibrary.AssetType memory)
    {
        bytes4 leftAssetClass = leftAssetType.assetClass;
        bytes4 rightAssetClass = rightAssetType.assetClass;
        if (leftAssetClass == AssetLibrary.ETH_ASSET_CLASS) {
            if (rightAssetClass == AssetLibrary.ETH_ASSET_CLASS) {
                return leftAssetType;
            }

            return AssetLibrary.AssetType(0, EMPTY_BYTES);
        }

        if (leftAssetClass == AssetLibrary.ERC20_ASSET_CLASS) {
            if (rightAssetClass == AssetLibrary.ERC20_ASSET_CLASS) {
                return generalMatch(leftAssetType, rightAssetType);
            }

            return AssetLibrary.AssetType(0, EMPTY_BYTES);
        }

        if (leftAssetClass == AssetLibrary.ERC721_ASSET_CLASS) {
            if (rightAssetClass == AssetLibrary.ERC721_ASSET_CLASS) {
                return generalMatch(leftAssetType, rightAssetType);
            }

            return AssetLibrary.AssetType(0, EMPTY_BYTES);
        }

        if (leftAssetClass == AssetLibrary.ERC1155_ASSET_CLASS) {
            if (rightAssetClass == AssetLibrary.ERC1155_ASSET_CLASS) {
                return generalMatch(leftAssetType, rightAssetType);
            }

            return AssetLibrary.AssetType(0, EMPTY_BYTES);
        }

        // match with the matcher from assetTypeMatchers
        address typeMatcherAddress = assetTypeMatchers[leftAssetClass];
        if (typeMatcherAddress != address(0)) {
            return IAssetTypeMatcher(typeMatcherAddress).matchAssetTypes(leftAssetType, rightAssetType);
        }

        require(leftAssetClass == rightAssetClass, "unknown matching rule");
        return generalMatch(leftAssetType, rightAssetType);
    }

    function matchAssetTypes(
        AssetLibrary.AssetType memory leftAssetType,
        AssetLibrary.AssetType memory rightAssetType
    )
    internal
    view
    returns
    (AssetLibrary.AssetType memory)
    {
        AssetLibrary.AssetType memory matchResult = matchAssetTypesByOneSide(leftAssetType, rightAssetType);
        if (matchResult.assetClass != 0) {
            return matchResult;
        } else {
            return matchAssetTypesByOneSide(rightAssetType, leftAssetType);
        }
    }

    uint256[49] private __gap;
}

// File: contracts/oases_exchange/OasesMatchingCore.sol


abstract contract OasesMatchingCore is AssetTypeMatcher, Cashier, OrderVerifier, ICashierManager {
    using TransferHelperLibrary for address;

    // record the filled amount of each order
    mapping(bytes32 => uint256) filledRecords;

    event CancelOrder(
        bytes32 orderHashKey,
        address orderMaker,
        AssetLibrary.AssetType makeAssetType,
        AssetLibrary.AssetType takeAssetType
    );

    event Trade(
        bytes32 leftOrderHashKey,
        bytes32 rightOrderHashKey,
        address leftOrderMaker,
        address rightOrderMaker,
        uint256 fillResultLeftValue,
        uint256 fillResultRightValue,
        AssetLibrary.AssetType matchedMakeAssetType,
        AssetLibrary.AssetType matchedTakeAssetType
    );

    function cancelOrders(OrderLibrary.Order[] calldata orders) external {
        uint len = orders.length;
        for (uint256 i = 0; i < len; ++i) {
            OrderLibrary.Order memory order = orders[i];
            require(msg.sender == order.maker, "not the order maker");
            require(order.salt != 0, "salt 0 cannot be cancelled");
            bytes32 orderKeyHash = OrderLibrary.getHashKey(order);
            filledRecords[orderKeyHash] = type(uint256).max;

            emit CancelOrder(
                orderKeyHash,
                order.maker,
                order.makeAsset.assetType,
                order.takeAsset.assetType
            );
        }
    }

    function matchOrders(
        OrderLibrary.Order memory leftOrder,
        OrderLibrary.Order memory rightOrder,
        bytes calldata leftSignature,
        bytes calldata rightSignature
    )
    external
    payable
    {
        validateOrder(leftOrder, leftSignature);
        validateOrder(rightOrder, rightSignature);
        if (leftOrder.taker != address(0)) {
            require(rightOrder.maker == leftOrder.taker, "unmatched taker of left order");
        }
        if (rightOrder.taker != address(0)) {
            require(rightOrder.taker == leftOrder.maker, "unmatched taker of right order");
        }

        trade(leftOrder, rightOrder);
    }

    function trade(OrderLibrary.Order memory leftOrder, OrderLibrary.Order memory rightOrder) internal {
        (
        AssetLibrary.AssetType memory matchedMakeAssetType,
        AssetLibrary.AssetType memory matchedTakeAssetType
        ) = matchAssetTypesFromOrders(leftOrder, rightOrder);

        bytes32 leftOrderHashKey = OrderLibrary.getHashKey(leftOrder);
        bytes32 rightOrderHashKey = OrderLibrary.getHashKey(rightOrder);

        OrderDataLibrary.Data memory leftOrderData = OrderDataParsingLibrary.parse(leftOrder);
        OrderDataLibrary.Data memory rightOrderData = OrderDataParsingLibrary.parse(rightOrder);

        FillLibrary.FillResult memory fillResult = getFillResult(
            leftOrder,
            rightOrder,
            leftOrderHashKey,
            rightOrderHashKey,
            leftOrderData,
            rightOrderData
        );

        (uint256 totalMakeAmount, uint256 totalTakeAmount) = allocateAssets(
            fillResult,
            matchedMakeAssetType,
            matchedTakeAssetType,
            leftOrder,
            rightOrder,
            leftOrderData,
            rightOrderData
        );

        // transfer extra eth
        if (matchedMakeAssetType.assetClass == AssetLibrary.ETH_ASSET_CLASS) {
            require(matchedTakeAssetType.assetClass != AssetLibrary.ETH_ASSET_CLASS);
            uint256 ethAmount = msg.value;
            require(ethAmount >= totalMakeAmount, "insufficient eth");
            if (ethAmount > totalMakeAmount) {
                address(msg.sender).transferEth(ethAmount - totalMakeAmount);
            }
        } else if (matchedTakeAssetType.assetClass == AssetLibrary.ETH_ASSET_CLASS) {
            uint256 ethAmount = msg.value;
            require(ethAmount >= totalTakeAmount, "insufficient eth");
            if (ethAmount > totalTakeAmount) {
                address(msg.sender).transferEth(ethAmount - totalTakeAmount);
            }
        }

        emit Trade(
            leftOrderHashKey,
            rightOrderHashKey,
            leftOrder.maker,
            rightOrder.maker,
            fillResult.leftValue,
            fillResult.rightValue,
            matchedMakeAssetType,
            matchedTakeAssetType
        );
    }

    function getFillResult(
        OrderLibrary.Order memory leftOrder,
        OrderLibrary.Order memory rightOrder,
        bytes32 leftOrderHashKey,
        bytes32 rightOrderHashKey,
        OrderDataLibrary.Data memory leftOrderData,
        OrderDataLibrary.Data memory rightOrderData
    )
    internal
    returns
    (FillLibrary.FillResult memory fillResult)
    {
        uint256 leftOrderFillRecord = getOrderFilledRecord(leftOrder.salt, leftOrderHashKey);
        uint256 rightOrderFillRecord = getOrderFilledRecord(rightOrder.salt, rightOrderHashKey);

        fillResult = FillLibrary.fillOrders(
            leftOrder,
            rightOrder,
            leftOrderFillRecord,
            rightOrderFillRecord,
            leftOrderData.isMakeFill,
            rightOrderData.isMakeFill
        );

        require(fillResult.rightValue > 0 && fillResult.leftValue > 0, "null fill");

        if (leftOrder.salt != 0) {
            if (leftOrderData.isMakeFill) {
                filledRecords[leftOrderHashKey] = leftOrderFillRecord + fillResult.leftValue;
            } else {
                filledRecords[leftOrderHashKey] = leftOrderFillRecord + fillResult.rightValue;
            }
        }

        if (rightOrder.salt != 0) {
            if (rightOrderData.isMakeFill) {
                filledRecords[rightOrderHashKey] = rightOrderFillRecord + fillResult.rightValue;
            } else {
                filledRecords[rightOrderHashKey] = rightOrderFillRecord + fillResult.leftValue;
            }
        }
    }

    function matchAssetTypesFromOrders(
        OrderLibrary.Order memory leftOrder,
        OrderLibrary.Order memory rightOrder
    )
    internal
    view
    returns
    (AssetLibrary.AssetType memory matchedMakeAssetType, AssetLibrary.AssetType memory matchedTakeAssetType)
    {
        matchedMakeAssetType = matchAssetTypes(leftOrder.makeAsset.assetType, rightOrder.takeAsset.assetType);
        require(matchedMakeAssetType.assetClass != 0, "bad match of make asset");
        matchedTakeAssetType = matchAssetTypes(leftOrder.takeAsset.assetType, rightOrder.makeAsset.assetType);
        require(matchedTakeAssetType.assetClass != 0, "bad match of take asset");
    }

    // get filled record of each order by its order key hash
    function getFilledRecords(bytes32 orderKeyHash) public view returns (uint256){
        return filledRecords[orderKeyHash];
    }

    function validateOrder(OrderLibrary.Order memory order, bytes memory signature) internal view {
        OrderLibrary.checkTimeValidity(order);
        verifyOrder(order, signature);
    }

    function getOrderFilledRecord(
        uint256 orderSalt,
        bytes32 orderHashKey
    )
    internal
    view
    returns
    (uint256){
        if (orderSalt == 0) {
            return 0;
        } else {
            return filledRecords[orderHashKey];
        }
    }

    uint256[49] private __gap;
}

// File: contracts/oases_exchange/OasesExchange.sol
// SPDX-License-Identifier: MIT


pragma solidity 0.8.8;


contract OasesExchange is OasesMatchingCore, OasesCashierManager {
    function __OasesExchange_init(
        address newDefaultFeeReceiver,
        IProtocolFeeProvider newProtocolFeeProviderAddress,
        IERC20TransferProxy newERC20TransferProxyAddress,
        INFTTransferProxy newNFTTransferProxyAddress
    )
    external
    initializer {
        __Ownable_init_unchained();
        __Cashier_init_unchained(
            newERC20TransferProxyAddress,
            newNFTTransferProxyAddress
        );
        __OasesCashierManager_init_unchained(
            newDefaultFeeReceiver,
            newProtocolFeeProviderAddress
        );
        __OrderVerifier_init_unchained();
    }
}