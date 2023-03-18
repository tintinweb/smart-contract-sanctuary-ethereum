// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./lib/CoreTypes.sol";
import "./lib/MerkleTree.sol";
import "./interfaces/IBlockHistory.sol";
import "./interfaces/IRecursiveVerifier.sol";

import {
    RecursiveProof,
    SignedRecursiveProof,
    getProofSigner,
    readHashWords
} from "./lib/Proofs.sol";

/**
 * @title BlockHistory
 * @author Theori, Inc.
 * @notice BlockHistory allows trustless and cheap verification of any
 *         historical block hash. Historical blocks are divided into chunks of
 *         fixed size, and each chunk's merkle root is stored on-chain. The
 *         merkle roots are validated on chain using aggregated SNARK proofs,
 *         enabling both trustlessness and scalability.
 *
 * @dev Each SNARK proof validates some contiguous block headers and has
 *      public inputs (parentHash, lastHash, merkleRoot). Here the merkleRoot
 *      is the merkleRoot of all block hashes contained in the proof, which may
 *      commit to many merkle roots which to commit on chain. If the last block
 *      is recent enough (<= 256 blocks old), the lastHash can be confirmed in
 *      the EVM, verifying that all blocks of the proof belong to this chain.
 *      Due to this, the historical blocks' merkle roots are imported in reverse
 *      order.
 */
contract BlockHistory is Ownable, IBlockHistory {
    // depth of the merkle trees whose roots we store in storage
    uint256 private constant MERKLE_TREE_DEPTH = 13;
    uint256 private constant BLOCKS_PER_CHUNK = 1 << MERKLE_TREE_DEPTH;

    /// @dev address of the reliquary, immutable
    address public immutable reliquary;

    /// @dev the expected signer of the SNARK proofs - if 0, then no signatures
    address public signer;

    /// @dev maps numBlocks => SNARK verifier (with VK embedded), only assigned
    ///      to in the constructor
    mapping(uint256 => IRecursiveVerifier) public verifiers;

    /// @dev parent hash of oldest block in current merkle trees
    ///      (0 once backlog fully imported)
    bytes32 public parentHash;

    /// @dev the earliest merkle root that has been imported
    uint256 public earliestRoot;

    /// @dev hash of most recent block in merkle trees
    bytes32 public lastHash;

    /// @dev merkle roots of block chunks between parentHash and lastHash
    mapping(uint256 => bytes32) private merkleRoots;

    event ImportMerkleRoot(uint256 indexed index, bytes32 merkleRoot);
    event NewSigner(address newSigner);

    enum ProofType {
        Merkle,
        SNARK
    }

    /// @dev A SNARK + Merkle proof used to prove validity of a block
    struct ValidBlockSNARK {
        uint256 numBlocks;
        uint256 endBlock;
        SignedRecursiveProof snark;
        bytes32[] merkleProof;
    }

    constructor(
        uint256[] memory sizes,
        IRecursiveVerifier[] memory _verifiers,
        address _reliquary
    ) Ownable() {
        reliquary = _reliquary;

        require(sizes.length == _verifiers.length);
        for (uint256 i = 0; i < sizes.length; i++) {
            require(address(verifiers[sizes[i]]) == address(0));
            verifiers[sizes[i]] = _verifiers[i];
        }
    }

    /**
     * @notice Checks if a SNARK is valid and signed as expected.
     *         Signatures checks are disabled if stored signer == address(0)
     *         Properties proven by the SNARK:
     *         - (parent ... last) form a valid block chain of length numBlocks
     *         - root is the merkle root of all contained blocks
     *
     * @param proof the aggregated proof
     * @param numBlocks the number of blocks contained in the proof
     * @return the validity
     */
    function validSNARK(SignedRecursiveProof calldata proof, uint256 numBlocks)
        internal
        view
        returns (bool)
    {
        address expected = signer;
        if (expected != address(0) && getProofSigner(proof) != expected) {
            return false;
        }
        IRecursiveVerifier verifier = verifiers[numBlocks];
        require(address(verifier) != address(0), "invalid numBlocks");
        return verifier.verify(proof.inner);
    }

    /**
     * @notice Asserts that the provided SNARK proof is valid and contains
     *         the provied merkle roots.
     *
     * @param proof the aggregated proof
     * @param roots the merkle roots
     * @return parent the parentHash of the proof blocks
     * @return last the lastHash of the proof blocks
     */
    function assertValidSNARKWithRoots(
        SignedRecursiveProof calldata proof,
        bytes32[] calldata roots
    ) internal view returns (bytes32 parent, bytes32 last) {
        require(roots.length & (roots.length - 1) == 0, "roots length must be a power of 2");

        // extract the inputs from the proof
        bytes32 proofRoot;
        (parent, last, proofRoot) = parseProofInputs(proof);

        // ensure the merkle roots are valid
        require(proofRoot == MerkleTree.computeRoot(roots), "invalid roots");

        // assert the SNARK proof is valid
        require(validSNARK(proof, BLOCKS_PER_CHUNK * roots.length), "invalid SNARK");
    }

    /**
     * @notice Checks if the given block number/hash connects to the current
     *         block using a SNARK.
     *
     * @param num the block number to check
     * @param hash the block hash to check
     * @param encodedProof the encoded ValidBlockSNARK
     * @return the validity
     */
    function validBlockHashWithSNARK(
        bytes32 hash,
        uint256 num,
        bytes calldata encodedProof
    ) internal view returns (bool) {
        ValidBlockSNARK calldata proof = parseValidBlockSNARK(encodedProof);

        (bytes32 proofParent, bytes32 proofLast, bytes32 proofRoot) = parseProofInputs(proof.snark);

        // check that the proof ends with a current block
        if (!validCurrentBlock(proofLast, proof.endBlock)) {
            return false;
        }

        if (!validSNARK(proof.snark, proof.numBlocks)) {
            return false;
        }

        // compute the first block number in the proof
        uint256 startBlock = proof.endBlock + 1 - proof.numBlocks;

        // check if the target block is the parent of the proven blocks
        if (num == startBlock - 1 && hash == proofParent) {
            // merkle proof not needed in this case
            return true;
        }

        // check if the target block is in the proven merkle root
        uint256 index = num - startBlock;
        return MerkleTree.validProof(proofRoot, index, hash, proof.merkleProof);
    }

    /**
     * @notice Checks if the given block number + hash exists in a commited
     *         merkle tree.
     *
     * @param num the block number to check
     * @param hash the block hash to check
     * @param encodedProof the encoded merkle proof
     * @return the validity
     */
    function validBlockHashWithMerkle(
        bytes32 hash,
        uint256 num,
        bytes calldata encodedProof
    ) internal view returns (bool) {
        bytes32 merkleRoot = merkleRoots[num / BLOCKS_PER_CHUNK];
        if (merkleRoot == 0) {
            return false;
        }
        bytes32[] calldata proofHashes = parseMerkleProof(encodedProof);
        if (proofHashes.length != MERKLE_TREE_DEPTH) {
            return false;
        }
        return MerkleTree.validProof(merkleRoot, num % BLOCKS_PER_CHUNK, hash, proofHashes);
    }

    /**
     * @notice Checks if the block is a current block (defined as being
     *         accessible in the EVM, i.e. <= 256 blocks old) and that the hash
     *         is correct.
     *
     * @param hash the alleged block hash
     * @param num the block number
     * @return the validity
     */
    function validCurrentBlock(bytes32 hash, uint256 num) internal view returns (bool) {
        // the block hash must be accessible in the EVM and match
        return (block.number - num <= 256) && (blockhash(num) == hash);
    }

    /**
     * @notice Stores the merkle roots starting at the index
     *
     * @param index the index for the first merkle root
     * @param roots the merkle roots
     */
    function storeMerkleRoots(uint256 index, bytes32[] calldata roots) internal {
        for (uint256 i = 0; i < roots.length; i++) {
            merkleRoots[index + i] = roots[i];
            emit ImportMerkleRoot(index + i, roots[i]);
        }
    }

    /**
     * @notice Imports new chunks of blocks before the current parentHash
     *
     * @param proof the aggregated proof for these chunks
     * @param roots the merkle roots for the chunks
     */
    function importParent(SignedRecursiveProof calldata proof, bytes32[] calldata roots) external {
        require(parentHash != 0 && earliestRoot != 0, "import not started or already completed");

        (bytes32 proofParent, bytes32 proofLast) = assertValidSNARKWithRoots(proof, roots);

        // assert the last hash in the proof is our current parent hash
        require(parentHash == proofLast, "proof doesn't connect with parentHash");

        // store the merkle roots
        uint256 index = earliestRoot - roots.length;
        storeMerkleRoots(index, roots);

        // store the new parentHash and earliestRoot
        parentHash = proofParent;
        earliestRoot = index;
    }

    /**
     * @notice Imports new chunks of blocks after the current lastHash
     *
     * @param endBlock the last block number in the chunks
     * @param proof the aggregated proof for these chunks
     * @param roots the merkle roots for the chunks
     * @param connectProof an optional SNARK proof connecting the proof to
     *                     a current block
     */
    function importLast(
        uint256 endBlock,
        SignedRecursiveProof calldata proof,
        bytes32[] calldata roots,
        bytes calldata connectProof
    ) external {
        require((endBlock + 1) % BLOCKS_PER_CHUNK == 0, "endBlock must end at a chunk boundary");

        (bytes32 proofParent, bytes32 proofLast) = assertValidSNARKWithRoots(proof, roots);

        if (!validCurrentBlock(proofLast, endBlock)) {
            // if the proof doesn't connect our lastHash with a current block,
            // then the connectProof must fill the gap
            require(
                validBlockHashWithSNARK(proofLast, endBlock, connectProof),
                "connectProof invalid"
            );
        }

        uint256 index = (endBlock + 1) / BLOCKS_PER_CHUNK - roots.length;
        if (lastHash == 0) {
            // if we're importing for the first time, set parentHash and earliestRoot
            require(parentHash == 0);
            parentHash = proofParent;
            earliestRoot = index;
        } else {
            require(proofParent == lastHash, "proof doesn't connect with lastHash");
        }

        // store the new lastHash
        lastHash = proofLast;

        // store the merkle roots
        storeMerkleRoots(index, roots);
    }

    /**
     * @notice Checks if a block hash is valid. A proof is required unless the
     *         block is current (accesible in the EVM). If the target block has
     *         no commited merkle root, the proof must contain a SNARK proof.
     *
     * @param hash the hash to check
     * @param num the block number for the alleged hash
     * @param proof the merkle witness or SNARK proof (if needed)
     * @return the validity
     */
    function _validBlockHash(
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) internal view returns (bool) {
        if (validCurrentBlock(hash, num)) {
            return true;
        }

        ProofType typ;
        (typ, proof) = parseProofType(proof);
        if (typ == ProofType.Merkle) {
            return validBlockHashWithMerkle(hash, num, proof);
        } else if (typ == ProofType.SNARK) {
            return validBlockHashWithSNARK(hash, num, proof);
        } else {
            revert("invalid proof type");
        }
    }

    /**
     * @notice Checks if a block hash is correct. A proof is required unless the
     *         block is current (accesible in the EVM). If the target block has
     *         no commited merkle root, the proof must contain a SNARK proof.
     *         Reverts if block hash or proof is invalid.
     *
     * @param hash the hash to check
     * @param num the block number for the alleged hash
     * @param proof the merkle witness or SNARK proof (if needed)
     */
    function validBlockHash(
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) external view returns (bool) {
        require(msg.sender == reliquary || msg.sender == owner());
        require(num < block.number);
        return _validBlockHash(hash, num, proof);
    }

    /**
     * @notice Parses a proof type and proof from the encoded proof
     *
     * @param proof the encoded proof
     * @return typ the proof type (SNARK or Merkle)
     * @return proof the remaining encoded proof
     */
    function parseProofType(bytes calldata encodedProof)
        internal
        pure
        returns (ProofType typ, bytes calldata proof)
    {
        require(encodedProof.length > 0, "cannot parse proof type");
        typ = ProofType(uint8(encodedProof[0]));
        proof = encodedProof[1:];
    }

    /**
     * @notice Parses a ValidBlockSNARK from calldata bytes
     *
     * @param proof the encoded proof
     * @return result a ValidBlockSNARK
     */
    function parseValidBlockSNARK(bytes calldata proof)
        internal
        pure
        returns (ValidBlockSNARK calldata result)
    {
        // solidity doesn't support getting calldata outputs from abi.decode
        // but we can decode it; calldata structs are just offsets
        assembly {
            result := proof.offset
        }
    }

    /**
     * @notice Parses a merkle inclusion proof from the bytes
     *
     * @param proof the encoded merkle inclusion proof
     * @return result the array of proof hashes
     */
    function parseMerkleProof(bytes calldata proof)
        internal
        pure
        returns (bytes32[] calldata result)
    {
        require(proof.length % 32 == 0);
        require(proof.length >= 32);

        // solidity doesn't support getting calldata outputs from abi.decode
        // but we can decode it; calldata arrays are just (offset,length)
        assembly {
            result.offset := add(proof.offset, 0x20)
            result.length := calldataload(proof.offset)
        }
    }

    /**
     * @notice Parses the proof inputs for block history snark proofs
     *
     * @param proof the snark proof
     * @return proofParent the parentHash of the proof blocks
     * @return proofLast the lastHash of the proof blocks
     * @return proofRoot the merkle root of the proof blocks
     */
    function parseProofInputs(SignedRecursiveProof calldata proof)
        internal
        pure
        returns (
            bytes32 proofParent,
            bytes32 proofLast,
            bytes32 proofRoot
        )
    {
        uint256[] calldata inputs = proof.inner.inputs;
        require(inputs.length == 12);
        proofParent = readHashWords(inputs[0:4]);
        proofLast = readHashWords(inputs[4:8]);
        proofRoot = readHashWords(inputs[8:12]);
    }

    /**
     * @notice sets the expected signer of the SNARK proofs, only callable by
     *         the contract owner
     *
     * @param _signer the new signer; if 0, disables signature checks
     */
    function setSigner(address _signer) external onlyOwner {
        require(signer != _signer);
        signer = _signer;
        emit NewSigner(_signer);
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./interfaces/IContractURI.sol";
import "./interfaces/IERC5192.sol";
import "./interfaces/ITokenURI.sol";

/**
 * @title RelicToken
 * @author Theori, Inc.
 * @notice RelicToken is the base contract for all Relic SBTs. It implements
 *         ERC721 (with transfers disables) and ERC5192.
 */
abstract contract RelicToken is Ownable, ERC165, IERC721, IERC721Metadata, IERC5192 {
    mapping(address => bool) public provers;

    /// @notice contract metadata URI provider
    IContractURI contractURIProvider;

    /**
     * @notice determind if the given owner is entitiled to a token with the specific data
     * @param owner the address in question
     * @param data the opaque data in question
     * @return the existence of the given data
     */
    function hasToken(address owner, uint96 data) internal view virtual returns (bool);

    /**
     * @notice updates the set of contracts trusted to create new tokens and
     *         possibly resolve entitlement questions
     * @param prover the address of the prover
     * @param valid whether the prover is trusted
     */
    function setProver(address prover, bool valid) external onlyOwner {
        provers[prover] = valid;
    }

    /**
     * @notice helper function to break a tokenId into its constituent data
     * @param tokenId the tokenId in question
     * @return who the address bound to this token
     * @return data any additional data bound to this token
     */
    function parseTokenId(uint256 tokenId) internal pure returns (address who, uint96 data) {
        who = address(bytes20(bytes32(tokenId << 96)));
        data = uint96(tokenId >> 160);
    }

    /**
     * @notice issue a new Relic
     * @param who the address to which this token should be bound
     * @param data any data to be associated with this token
     * @dev emits ERC-721 Transfer event and ERC-5192 Locked event. Note
     *      that storage is not generally updated by this function.
     */
    function mint(address who, uint96 data) public virtual {
        require(provers[msg.sender], "only a prover can mint");
        require(hasToken(who, data), "cannot mint for invalid token");

        uint256 id = uint256(uint160(who)) | (uint256(data) << 160);
        emit Transfer(address(0), who, id);
        emit Locked(id);
    }

    /* begin ERC-721 spec functions */
    /**
     * @inheritdoc IERC721
     * @dev If the token has not been issued (no transfer event) this function
     *      may still return an owner if there is an account entitled to this
     *      token.
     */
    function ownerOf(uint256 id) public view virtual returns (address who) {
        uint96 data;
        (who, data) = parseTokenId(id);
        if (!hasToken(who, data)) {
            who = address(0);
        }
    }

    /**
     * @inheritdoc IERC721
     * @dev Balance will always be 0 if the address is not entitled to any
     *      tokens, and 1 if they are entitled to a token. If multiple tokens
     *      are minted, this will still return 1.
     */
    function balanceOf(address who) external view override returns (uint256 balance) {
        require(who != address(0), "ERC721: address zero is not a valid owner");
        if (hasToken(who, 0)) {
            balance = 1;
        }
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: Relics are soul-bound/non-transferrable
     */
    function safeTransferFrom(
        address, /* from */
        address, /* _to */
        uint256, /* _tokenId */
        bytes calldata /* data */
    ) external pure {
        revert("RelicToken is soulbound");
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: Relics are soul-bound/non-transferrable
     */
    function safeTransferFrom(
        address, /* from */
        address, /* to */
        uint256 /* tokenId */
    ) external pure {
        revert("RelicToken is soulbound");
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: Relics are soul-bound/non-transferrable
     */
    function transferFrom(
        address, /* from */
        address, /* to */
        uint256 /* id */
    ) external pure {
        revert("RelicToken is soulbound");
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: Relics are soul-bound/non-transferrable
     */
    function approve(
        address, /* to */
        uint256 /* tokenId */
    ) external pure {
        revert("RelicToken is soulbound");
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: Relics are soul-bound/non-transferrable
     */
    function setApprovalForAll(
        address, /* operator */
        bool /* _approved */
    ) external pure {
        revert("RelicToken is soulbound");
    }

    /**
     * @inheritdoc IERC721
     * @dev Always returns the null address: Relics are soul-bound/non-transferrable
     */
    function getApproved(
        uint256 /* tokenId */
    ) external pure returns (address operator) {
        operator = address(0);
    }

    /**
     * @inheritdoc IERC721
     * @dev Always returns false: Relics are soul-bound/non-transferrable
     */
    function isApprovedForAll(
        address, /* owner */
        address /* operator */
    ) external pure returns (bool) {
        return false;
    }

    /**
     * @inheritdoc IERC165
     * @dev Supported interfaces: IERC721, IERC721Metadata, IERC5192
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC5192).interfaceId ||
            super.supportsInterface(interfaceId));
    }

    /// @inheritdoc IERC721Metadata
    function name() external pure virtual returns (string memory);

    /// @inheritdoc IERC721Metadata
    function symbol() external pure virtual returns (string memory);

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 tokenID) external view virtual returns (string memory);

    /* end ERC-721 spec functions */

    /* begin ERC-5192 spec functions */
    /**
     * @inheritdoc IERC5192
     * @dev All valid tokens are locked: Relics are soul-bound/non-transferrable
     */
    function locked(uint256 id) external view returns (bool) {
        return ownerOf(id) != address(0);
    }

    /* end ERC-5192 spec functions */

    /* begin OpenSea metadata functions */
    /**
     * @notice contract metadata URI as defined by OpenSea
     */
    function contractURI() external view returns (string memory) {
        return contractURIProvider.contractURI();
    }

    /**
     * @notice set contract-level metadata URI provider
     * @param provider new metadata URI provider
     */
    function setContractURIProvider(IContractURI provider) external onlyOwner {
        contractURIProvider = provider;
    }
    /* end OpenSea metadata functions */
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

import "../lib/Facts.sol";

pragma solidity >=0.8.12;

/**
 * @title IBatchProver
 * @author Theori, Inc.
 * @notice IBatchProver is a standard interface implemented by some Relic provers.
 *         Supports proving multiple facts ephemerally or proving and storing
 *         them in the Reliquary.
 */
interface IBatchProver {
    /**
     * @notice prove multiple facts ephemerally
     * @param proof the encoded proof, depends on the prover implementation
     * @param store whether to store the facts in the reliquary
     * @return facts the proven facts' information
     */
    function proveBatch(bytes calldata proof, bool store)
        external
        payable
        returns (Fact[] memory facts);
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @title Block history provider
 * @author Theori, Inc.
 * @notice IBlockHistory provides a way to verify a blockhash
 */

interface IBlockHistory {
    /**
     * @notice Determine if the given hash corresponds to the given block
     * @param hash the hash if the block in question
     * @param num the number of the block in question
     * @param proof any witness data required to prove the block hash is
     *        correct (such as a Merkle or SNARK proof)
     * @return boolean indicating if the block hash can be verified correct
     */
    function validBlockHash(
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) external view returns (bool);
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @title NFT Contract Metadata URI provider
 * @author Theori, Inc.
 * @notice Outsourced contractURI provider for NFT/SBT tokens
 */
interface IContractURI {
    /**
     * @notice Get the contract metadata URI
     * @return the string of the URI
     */
    function contractURI() external view returns (string memory);
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

/**
 * @title EIP-5192 specification
 * @author Theori, Inc.
 * @notice EIP-5192 events and functions
 */
interface IERC5192 {
    /// @notice Emitted when the locking status is changed to locked.
    /// @dev If a token is minted and the status is locked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Locked(uint256 tokenId);

    /// @notice Emitted when the locking status is changed to unlocked.
    /// @dev If a token is minted and the status is unlocked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Unlocked(uint256 tokenId);

    /// @notice Returns the locking status of an Soulbound Token
    /// @dev SBTs assigned to zero address are considered invalid, and queries
    /// about them do throw.
    /// @param tokenId The identifier for an SBT.
    function locked(uint256 tokenId) external view returns (bool);
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

import {RecursiveProof} from "../lib/Proofs.sol";

/**
 * @title Verifier of zk-SNARK proofs
 * @author Theori, Inc.
 * @notice Provider of validity checking of zk-SNARKs
 */
interface IRecursiveVerifier {
    /**
     * @notice Checks the validity of SNARK data
     * @param proof the proof to verify
     * @return the validity of the proof
     */
    function verify(RecursiveProof calldata proof) external view returns (bool);
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "../lib/Facts.sol";

interface IReliquary {
    event NewProver(address prover, uint64 version);
    event PendingProverAdded(address prover, uint64 version, uint64 timestamp);
    event ProverRevoked(address prover, uint64 version);
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    struct ProverInfo {
        uint64 version;
        FeeInfo feeInfo;
        bool revoked;
    }

    enum FeeFlags {
        FeeNone,
        FeeNative,
        FeeCredits,
        FeeExternalDelegate,
        FeeExternalToken
    }

    struct FeeInfo {
        uint8 flags;
        uint16 feeCredits;
        // feeWei = feeWeiMantissa * pow(10, feeWeiExponent)
        uint8 feeWeiMantissa;
        uint8 feeWeiExponent;
        uint32 feeExternalId;
    }

    function ADD_PROVER_ROLE() external view returns (bytes32);

    function CREDITS_ROLE() external view returns (bytes32);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function DELAY() external view returns (uint64);

    function GOVERNANCE_ROLE() external view returns (bytes32);

    function SUBSCRIPTION_ROLE() external view returns (bytes32);

    function activateProver(address prover) external;

    function addCredits(address user, uint192 amount) external;

    function addProver(address prover, uint64 version) external;

    function addSubscriber(address user, uint64 ts) external;

    function assertValidBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external payable;

    function assertValidBlockHashFromProver(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external view;

    function checkProveFactFee(address sender) external payable;

    function checkProver(ProverInfo memory prover) external pure;

    function credits(address user) external view returns (uint192);

    function debugValidBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external view returns (bool);

    function debugVerifyFact(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    function factFees(uint8)
        external
        view
        returns (
            uint8 flags,
            uint16 feeCredits,
            uint8 feeWeiMantissa,
            uint8 feeWeiExponent,
            uint32 feeExternalId
        );

    function feeAccounts(address)
        external
        view
        returns (uint64 subscriberUntilTime, uint192 credits);

    function feeExternals(uint256) external view returns (address);

    function getFact(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    function getProveFactNativeFee(address prover) external view returns (uint256);

    function getProveFactTokenFee(address prover) external view returns (uint256);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getVerifyFactNativeFee(FactSignature factSig) external view returns (uint256);

    function getVerifyFactTokenFee(FactSignature factSig) external view returns (uint256);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account) external view returns (bool);

    function initialized() external view returns (bool);

    function isSubscriber(address user) external view returns (bool);

    function pendingProvers(address) external view returns (uint64 timestamp, uint64 version);

    function provers(address) external view returns (ProverInfo memory);

    function removeCredits(address user, uint192 amount) external;

    function removeSubscriber(address user) external;

    function renounceRole(bytes32 role, address account) external;

    function resetFact(address account, FactSignature factSig) external;

    function revokeProver(address prover) external;

    function revokeRole(bytes32 role, address account) external;

    function setCredits(address user, uint192 amount) external;

    function setFact(
        address account,
        FactSignature factSig,
        bytes memory data
    ) external;

    function setFactFee(
        uint8 cls,
        FeeInfo memory feeInfo,
        address feeExternal
    ) external;

    function setInitialized() external;

    function setProverFee(
        address prover,
        FeeInfo memory feeInfo,
        address feeExternal
    ) external;

    function setValidBlockFee(FeeInfo memory feeInfo, address feeExternal) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function validBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external payable returns (bool);

    function validBlockHashFromProver(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external view returns (bool);

    function verifyBlockFeeInfo()
        external
        view
        returns (
            uint8 flags,
            uint16 feeCredits,
            uint8 feeWeiMantissa,
            uint8 feeWeiExponent,
            uint32 feeExternalId
        );

    function verifyFact(address account, FactSignature factSig)
        external
        payable
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    function verifyFactNoFee(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    function verifyFactVersion(address account, FactSignature factSig)
        external
        payable
        returns (bool exists, uint64 version);

    function verifyFactVersionNoFee(address account, FactSignature factSig)
        external
        view
        returns (bool exists, uint64 version);

    function versions(uint64) external view returns (address);

    function withdrawFees(address token, address dest) external;
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @title NFT Token URI provider
 * @author Theori, Inc.
 * @notice Outsourced tokenURI provider for NFT/SBT tokens
 */
interface ITokenURI {
    /**
     * @notice Get the URI for the given token
     * @param tokenID the unique ID for the token
     * @return the string of the URI
     * @dev when called with an invalid tokenID, this may revert,
     *      or it may return invalid output
     */
    function tokenURI(uint256 tokenID) external view returns (string memory);
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.13;

// custom bytes calldata pointer storing (length | offset) in one word,
// also allows calldata pointers to be stored in memory
type BytesCalldata is uint256;

using BytesCalldataOps for BytesCalldata global;

// can't introduce global using .. for non UDTs
// each consumer should add the following line:
using BytesCalldataOps for bytes;

/**
 * @author Theori, Inc
 * @title BytesCalldataOps
 * @notice Common operations for bytes calldata, implemented for both the builtin
 *         type and our BytesCalldata type. These operations are heavily optimized
 *         and omit safety checks, so this library should only be used when memory
 *         safety is not a security issue.
 */
library BytesCalldataOps {
    function length(BytesCalldata bc) internal pure returns (uint256 result) {
        assembly {
            result := shr(128, shl(128, bc))
        }
    }

    function offset(BytesCalldata bc) internal pure returns (uint256 result) {
        assembly {
            result := shr(128, bc)
        }
    }

    function convert(BytesCalldata bc) internal pure returns (bytes calldata value) {
        assembly {
            value.offset := shr(128, bc)
            value.length := shr(128, shl(128, bc))
        }
    }

    function convert(bytes calldata inp) internal pure returns (BytesCalldata bc) {
        assembly {
            bc := or(shl(128, inp.offset), inp.length)
        }
    }

    function slice(
        BytesCalldata bc,
        uint256 start,
        uint256 len
    ) internal pure returns (BytesCalldata result) {
        assembly {
            result := shl(128, add(shr(128, bc), start)) // add to the offset and clear the length
            result := or(result, len) // set the new length
        }
    }

    function slice(
        bytes calldata value,
        uint256 start,
        uint256 len
    ) internal pure returns (bytes calldata result) {
        assembly {
            result.offset := add(value.offset, start)
            result.length := len
        }
    }

    function prefix(BytesCalldata bc, uint256 len) internal pure returns (BytesCalldata result) {
        assembly {
            result := shl(128, shr(128, bc)) // clear out the length
            result := or(result, len) // set it to the new length
        }
    }

    function prefix(bytes calldata value, uint256 len)
        internal
        pure
        returns (bytes calldata result)
    {
        assembly {
            result.offset := value.offset
            result.length := len
        }
    }

    function suffix(BytesCalldata bc, uint256 start) internal pure returns (BytesCalldata result) {
        assembly {
            result := add(bc, shl(128, start)) // add to the offset
            result := sub(result, start) // subtract from the length
        }
    }

    function suffix(bytes calldata value, uint256 start)
        internal
        pure
        returns (bytes calldata result)
    {
        assembly {
            result.offset := add(value.offset, start)
            result.length := sub(value.length, start)
        }
    }

    function split(BytesCalldata bc, uint256 start)
        internal
        pure
        returns (BytesCalldata, BytesCalldata)
    {
        return (prefix(bc, start), suffix(bc, start));
    }

    function split(bytes calldata value, uint256 start)
        internal
        pure
        returns (bytes calldata, bytes calldata)
    {
        return (prefix(value, start), suffix(value, start));
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

import "./BytesCalldata.sol";
import "./RLP.sol";

/**
 * @title CoreTypes
 * @author Theori, Inc.
 * @notice Data types and parsing functions for core types, including block headers
 *         and account data.
 */
library CoreTypes {
    using BytesCalldataOps for bytes;
    struct BlockHeaderData {
        bytes32 ParentHash;
        address Coinbase;
        bytes32 Root;
        bytes32 TxHash;
        bytes32 ReceiptHash;
        uint256 Number;
        uint256 GasLimit;
        uint256 GasUsed;
        uint256 Time;
        bytes32 MixHash;
        uint256 BaseFee;
    }

    struct AccountData {
        uint256 Nonce;
        uint256 Balance;
        bytes32 StorageRoot;
        bytes32 CodeHash;
    }

    struct LogData {
        address Address;
        bytes32[] Topics;
        bytes Data;
    }

    function parseHash(bytes calldata buf) internal pure returns (bytes32 result, uint256 offset) {
        uint256 value;
        (value, offset) = RLP.parseUint(buf);
        result = bytes32(value);
    }

    function parseAddress(bytes calldata buf)
        internal
        pure
        returns (address result, uint256 offset)
    {
        uint256 value;
        (value, offset) = RLP.parseUint(buf);
        result = address(uint160(value));
    }

    function parseBlockHeader(bytes calldata header)
        internal
        pure
        returns (BlockHeaderData memory data)
    {
        (uint256 listSize, uint256 offset) = RLP.parseList(header);
        header = header.slice(offset, listSize);

        (data.ParentHash, offset) = parseHash(header); // ParentHash
        header = header.suffix(offset);
        header = RLP.skip(header); // UncleHash
        (data.Coinbase, offset) = parseAddress(header); // Coinbase
        header = header.suffix(offset);
        (data.Root, offset) = parseHash(header); // Root
        header = header.suffix(offset);
        (data.TxHash, offset) = parseHash(header); // TxHash
        header = header.suffix(offset);
        (data.ReceiptHash, offset) = parseHash(header); // ReceiptHash
        header = header.suffix(offset);
        header = RLP.skip(header); // Bloom
        header = RLP.skip(header); // Difficulty
        (data.Number, offset) = RLP.parseUint(header); // Number
        header = header.suffix(offset);
        (data.GasLimit, offset) = RLP.parseUint(header); // GasLimit
        header = header.suffix(offset);
        (data.GasUsed, offset) = RLP.parseUint(header); // GasUsed
        header = header.suffix(offset);
        (data.Time, offset) = RLP.parseUint(header); // Time
        header = header.suffix(offset);
        header = RLP.skip(header); // Extra
        (data.MixHash, offset) = parseHash(header); // MixHash
        header = header.suffix(offset);
        header = RLP.skip(header); // Nonce

        if (header.length > 0) {
            (data.BaseFee, offset) = RLP.parseUint(header); // BaseFee
        }
    }

    function getBlockHeaderHashAndSize(bytes calldata header)
        internal
        pure
        returns (bytes32 blockHash, uint256 headerSize)
    {
        (uint256 listSize, uint256 offset) = RLP.parseList(header);
        unchecked {
            headerSize = offset + listSize;
        }
        blockHash = keccak256(header.prefix(headerSize));
    }

    function parseAccount(bytes calldata account) internal pure returns (AccountData memory data) {
        (, uint256 offset) = RLP.parseList(account);
        account = account.suffix(offset);

        (data.Nonce, offset) = RLP.parseUint(account); // Nonce
        account = account.suffix(offset);
        (data.Balance, offset) = RLP.parseUint(account); // Balance
        account = account.suffix(offset);
        (data.StorageRoot, offset) = parseHash(account); // StorageRoot
        account = account.suffix(offset);
        (data.CodeHash, offset) = parseHash(account); // CodeHash
        account = account.suffix(offset);
    }

    function parseLog(bytes calldata log) internal pure returns (LogData memory data) {
        (, uint256 offset) = RLP.parseList(log);
        log = log.suffix(offset);

        uint256 tmp;
        (tmp, offset) = RLP.parseUint(log); // Address
        data.Address = address(uint160(tmp));
        log = log.suffix(offset);

        (tmp, offset) = RLP.parseList(log); // Topics
        bytes calldata topics = log.slice(offset, tmp);
        log = log.suffix(offset + tmp);

        require(topics.length % 33 == 0);
        data.Topics = new bytes32[](tmp / 33);
        uint256 i = 0;
        while (topics.length > 0) {
            (data.Topics[i], offset) = parseHash(topics);
            topics = topics.suffix(offset);
            unchecked {
                i++;
            }
        }

        (data.Data, ) = RLP.splitBytes(log);
    }

    function extractLog(bytes calldata receiptValue, uint256 logIdx)
        internal
        pure
        returns (LogData memory)
    {
        // support EIP-2718: Currently all transaction types have the same
        // receipt RLP format, so we can just skip the receipt type byte
        if (receiptValue[0] < 0x80) {
            receiptValue = receiptValue.suffix(1);
        }

        (, uint256 offset) = RLP.parseList(receiptValue);
        receiptValue = receiptValue.suffix(offset);

        // pre EIP-658, receipts stored an intermediate state root in this field
        // post EIP-658, the field is a tx status (0 for failure, 1 for success)
        uint256 statusOrIntermediateRoot;
        (statusOrIntermediateRoot, offset) = RLP.parseUint(receiptValue);
        require(statusOrIntermediateRoot != 0, "tx did not succeed");
        receiptValue = receiptValue.suffix(offset);

        receiptValue = RLP.skip(receiptValue); // GasUsed
        receiptValue = RLP.skip(receiptValue); // LogsBloom

        uint256 length;
        (length, offset) = RLP.parseList(receiptValue); // Logs
        receiptValue = receiptValue.slice(offset, length);

        // skip the earlier logs
        for (uint256 i = 0; i < logIdx; i++) {
            require(receiptValue.length > 0, "log index does not exist");
            receiptValue = RLP.skip(receiptValue);
        }

        return parseLog(receiptValue);
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "./Facts.sol";

/**
 * @title FactSigs
 * @author Theori, Inc.
 * @notice Helper functions for computing fact signatures
 */
library FactSigs {
    /**
     * @notice Produce the fact signature data for birth certificates
     */
    function birthCertificateFactSigData() internal pure returns (bytes memory) {
        return abi.encode("BirthCertificate");
    }

    /**
     * @notice Produce the fact signature for a birth certificate fact
     */
    function birthCertificateFactSig() internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, birthCertificateFactSigData());
    }

    /**
     * @notice Produce the fact signature data for an account's storage root
     * @param blockNum the block number to look at
     * @param storageRoot the storageRoot for the account
     */
    function accountStorageFactSigData(uint256 blockNum, bytes32 storageRoot)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode("AccountStorage", blockNum, storageRoot);
    }

    /**
     * @notice Produce a fact signature for an accoun't storage root
     * @param blockNum the block number to look at
     * @param storageRoot the storageRoot for the account
     */
    function accountStorageFactSig(uint256 blockNum, bytes32 storageRoot)
        internal
        pure
        returns (FactSignature)
    {
        return
            Facts.toFactSignature(Facts.NO_FEE, accountStorageFactSigData(blockNum, storageRoot));
    }

    /**
     * @notice Produce the fact signature data for a storage slot
     * @param slot the account's slot
     * @param blockNum the block number to look at
     */
    function storageSlotFactSigData(bytes32 slot, uint256 blockNum)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode("StorageSlot", slot, blockNum);
    }

    /**
     * @notice Produce a fact signature for a storage slot
     * @param slot the account's slot
     * @param blockNum the block number to look at
     */
    function storageSlotFactSig(bytes32 slot, uint256 blockNum)
        internal
        pure
        returns (FactSignature)
    {
        return Facts.toFactSignature(Facts.NO_FEE, storageSlotFactSigData(slot, blockNum));
    }

    /**
     * @notice Produce the fact signature data for a log
     * @param blockNum the block number to look at
     * @param txIdx the transaction index in the block
     * @param logIdx the log index in the transaction
     */
    function logFactSigData(
        uint256 blockNum,
        uint256 txIdx,
        uint256 logIdx
    ) internal pure returns (bytes memory) {
        return abi.encode("Log", blockNum, txIdx, logIdx);
    }

    /**
     * @notice Produce a fact signature for a log
     * @param blockNum the block number to look at
     * @param txIdx the transaction index in the block
     * @param logIdx the log index in the transaction
     */
    function logFactSig(
        uint256 blockNum,
        uint256 txIdx,
        uint256 logIdx
    ) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, logFactSigData(blockNum, txIdx, logIdx));
    }

    /**
     * @notice Produce the fact signature data for a block header
     * @param blockNum the block number
     */
    function blockHeaderSigData(uint256 blockNum) internal pure returns (bytes memory) {
        return abi.encode("BlockHeader", blockNum);
    }

    /**
     * @notice Produce the fact signature data for a block header
     * @param blockNum the block number
     */
    function blockHeaderSig(uint256 blockNum) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, blockHeaderSigData(blockNum));
    }

    /**
     * @notice Produce the fact signature data for an event fact
     * @param eventId The event in question
     */
    function eventFactSigData(uint64 eventId) internal pure returns (bytes memory) {
        return abi.encode("EventAttendance", "EventID", eventId);
    }

    /**
     * @notice Produce a fact signature for a given event
     * @param eventId The event in question
     */
    function eventFactSig(uint64 eventId) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, eventFactSigData(eventId));
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

type FactSignature is bytes32;

struct Fact {
    address account;
    FactSignature sig;
    bytes data;
}

library Facts {
    uint8 internal constant NO_FEE = 0;

    function toFactSignature(uint8 cls, bytes memory data) internal pure returns (FactSignature) {
        return FactSignature.wrap(bytes32((uint256(keccak256(data)) << 8) | cls));
    }

    function toFactClass(FactSignature factSig) internal pure returns (uint8) {
        return uint8(uint256(FactSignature.unwrap(factSig)));
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

/**
 * @title MPT
 * @author Theori, Inc.
 * @notice Implements proof checking for Ethereum Merkle-Patricia Tries.
 *         To save gas, it assumes nodes are validly structured,
 *         so soundness is only guaranteed if the rootHash belongs
 *         to a valid ethereum block.
 */

pragma solidity >=0.8.0;

import "./RLP.sol";
import "./CoreTypes.sol";
import "./BytesCalldata.sol";

library MPT {
    using BytesCalldataOps for bytes;

    struct Node {
        BytesCalldata data;
        bytes32 hash;
    }

    // prefix constants
    uint8 constant ODD_LENGTH = 1;
    uint8 constant LEAF = 2;
    uint8 constant MAX_PREFIX = 3;

    /**
     * @notice parses concatenated MPT nodes into processed Node structs
     * @param input the concatenated MPT nodes
     * @return result the parsed nodes array, containing a calldata slice and hash
     *                for each node
     */
    function parseNodes(bytes calldata input) internal pure returns (Node[] memory result) {
        uint256 freePtr;
        uint256 firstNode;

        // we'll use a dynamic amount of memory starting at the free pointer
        // it is crucial that no other allocations happen during parsing
        assembly {
            freePtr := mload(0x40)

            // corrupt free pointer to cause out-of-gas if allocation occurs
            mstore(0x40, 0xcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc)

            firstNode := freePtr
        }

        uint256 count;
        while (input.length > 0) {
            (uint256 listsize, uint256 offset) = RLP.parseList(input);
            bytes calldata node = input.slice(offset, listsize);
            BytesCalldata slice = node.convert();

            uint256 len;
            assembly {
                len := add(listsize, offset)

                // compute node hash
                calldatacopy(freePtr, input.offset, len)
                let nodeHash := keccak256(freePtr, len)

                // store the Node struct (calldata slice and hash)
                mstore(freePtr, slice)
                mstore(add(freePtr, 0x20), nodeHash)

                // advance pointer
                count := add(count, 1)
                freePtr := add(freePtr, 0x40)
            }

            input = input.suffix(len);
        }

        assembly {
            // allocate the result array and fill it with the node pointers
            result := freePtr
            mstore(result, count)
            freePtr := add(freePtr, 0x20)
            for {
                let i := 0
            } lt(i, count) {
                i := add(i, 1)
            } {
                mstore(freePtr, add(firstNode, mul(0x40, i)))
                freePtr := add(freePtr, 0x20)
            }

            // update the free pointer
            mstore(0x40, freePtr)
        }
    }

    /**
     * @notice parses a compressed MPT proof into arrays of Node structs
     * @param nodes the set of nodes used in the compressed proofs
     * @param compressed the compressed MPT proof
     * @param count the number of proofs expected from the compressed proof
     * @return result the array of proofs
     */
    function parseCompressedProofs(
        Node[] memory nodes,
        bytes calldata compressed,
        uint256 count
    ) internal pure returns (Node[][] memory result) {
        uint256 resultPtr;
        uint256 freePtr;

        // we'll use a dynamic amount of memory starting at the free pointer
        // it is crucial that no other allocations happen during parsing
        assembly {
            result := mload(0x40)

            // corrupt free pointer to cause out-of-gas if allocation occurs
            mstore(0x40, 0xcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc)

            mstore(result, count)
            resultPtr := add(result, 0x20)
            freePtr := add(resultPtr, mul(0x20, count))
        }

        (uint256 listSize, uint256 offset) = RLP.parseList(compressed);
        compressed = compressed.slice(offset, listSize);

        // parse the indices and populate the proof list
        for (; count > 0; count--) {
            bytes calldata indices;
            (listSize, offset) = RLP.parseList(compressed);
            indices = compressed.slice(offset, listSize);
            compressed = compressed.suffix(listSize + offset);

            // begin next proof array
            uint256 arr;
            assembly {
                arr := freePtr
                freePtr := add(freePtr, 0x20)
            }

            // fill proof array
            uint256 len;
            for (len = 0; indices.length > 0; len++) {
                uint256 idx;
                (idx, offset) = RLP.parseUint(indices);
                indices = indices.suffix(offset);
                require(idx < nodes.length, "invalid node index in compressed proof");
                assembly {
                    let node := mload(add(add(nodes, 0x20), mul(0x20, idx)))
                    mstore(freePtr, node)
                    freePtr := add(freePtr, 0x20)
                }
            }

            assembly {
                // store the array length
                mstore(arr, len)

                // store the array pointer in the result
                mstore(resultPtr, arr)
                resultPtr := add(resultPtr, 0x20)
            }
        }

        assembly {
            // update the free pointer
            mstore(0x40, freePtr)
        }
    }

    /**
     * @notice Checks if the provided bytes match the key at a given offset
     * @param key the MPT key to check against
     * @param keyLen the length (in nibbles) of the key
     * @param testBytes the subkey to check
     */
    function subkeysEqual(
        bytes32 key,
        uint256 keyLen,
        bytes calldata testBytes
    ) private pure returns (bool result) {
        // arithmetic cannot overflow because testBytes is from calldata
        uint256 nibbleLength;
        unchecked {
            nibbleLength = 2 * testBytes.length;
            require(nibbleLength <= keyLen);
        }

        assembly {
            let shiftAmount := sub(256, shl(2, nibbleLength))
            let testValue := shr(shiftAmount, calldataload(testBytes.offset))
            let subkey := shr(shiftAmount, key)
            result := eq(testValue, subkey)
        }
    }

    /**
     * @notice checks the MPT proof. Note: for certain optimizations, we assume
     *         that the rootHash belongs to a valid ethereum block. Correctness
     *         is only guaranteed in that case.
     *         Gas usage depends on both proof size and key nibble values.
     *         Gas usage for actual ethereum account proofs: ~ 30000 - 45000
     * @param nodes MPT proof nodes, parsed using parseNodes()
     * @param key the MPT key, padded with trailing 0s if needed
     * @param keyLen the byte length of the MPT key, must be <= 32
     * @param expectedHash the root hash of the MPT
     */
    function verifyTrieValueWithNodes(
        Node[] memory nodes,
        bytes32 key,
        uint256 keyLen,
        bytes32 expectedHash
    ) internal pure returns (bool exists, bytes calldata value) {
        // handle completely empty trie case
        if (nodes.length == 0) {
            require(keccak256(hex"80") == expectedHash, "root hash incorrect");
            return (false, msg.data[:0]);
        }

        // we will read the key nibble by nibble, so double the length
        unchecked {
            keyLen *= 2;
        }

        // initialize return values to make solc happy;
        // one will always be overwritten before returing
        assembly {
            value.offset := 0
            value.length := 0
        }
        exists = true;

        // we'll use nodes as a pointer, advancing through each element
        // end will point to the end of the array
        uint256 end;
        assembly {
            end := add(nodes, add(0x20, mul(0x20, mload(nodes))))
            nodes := add(nodes, 0x20)
        }

        while (true) {
            bytes calldata node;
            {
                BytesCalldata slice;
                bytes32 nodeHash;

                // load the element and advance the proof pointer
                assembly {
                    // bounds checking
                    if iszero(lt(nodes, end)) {
                        revert(0, 0)
                    }

                    let ptr := mload(nodes)
                    nodes := add(nodes, 0x20)

                    slice := mload(ptr)
                    nodeHash := mload(add(ptr, 0x20))
                }
                node = slice.convert();

                require(nodeHash == expectedHash, "node hash incorrect");
            }

            // find the length of the first two elements
            uint256 size = RLP.nextSize(node);
            unchecked {
                size += RLP.nextSize(node.suffix(size));
            }

            // we now know which type of node we're looking at:
            // leaf + extension nodes have 2 list elements, branch nodes have 17
            if (size == node.length) {
                // only two elements, leaf or extension node
                bytes calldata encodedPath;
                (encodedPath, node) = RLP.splitBytes(node);

                // keep track of whether the key nibbles match
                bool keysMatch;

                // the first nibble of the encodedPath tells us the type of
                // node and if it contains an even or odd number of nibbles
                uint8 firstByte = uint8(encodedPath[0]);
                uint8 prefix = firstByte >> 4;
                require(prefix <= MAX_PREFIX);
                if (prefix & ODD_LENGTH == 0) {
                    // second nibble is padding, must be 0
                    require(firstByte & 0xf == 0);
                    keysMatch = true;
                } else {
                    // second nibble is part of key
                    keysMatch = (firstByte & 0xf) == (uint8(bytes1(key)) >> 4);
                    unchecked {
                        key <<= 4;
                        keyLen--;
                    }
                }

                // check the remainder of the encodedPath
                encodedPath = encodedPath.suffix(1);
                keysMatch = keysMatch && subkeysEqual(key, keyLen, encodedPath);
                // cannot overflow because encodedPath is from calldata
                unchecked {
                    key <<= 8 * encodedPath.length;
                    keyLen -= 2 * encodedPath.length;
                }

                if (prefix & LEAF == 0) {
                    // extension can't prove nonexistence, subkeys must match
                    require(keysMatch);

                    (expectedHash, ) = CoreTypes.parseHash(node);
                } else {
                    // leaf node, must have used all of key
                    require(keyLen == 0);

                    if (keysMatch) {
                        // if keys equal, we found the value
                        (value, node) = RLP.splitBytes(node);
                        break;
                    } else {
                        // if keys aren't equal, key doesn't exist
                        exists = false;
                        break;
                    }
                }
            } else {
                // branch node, this is the hotspot for gas usage

                // there should be 17 elements (16 branch hashes + a value)
                // we won't explicitly check this in order to save gas, since
                // it's implied by inclusion in a valid ethereum block

                // also note, we never need the value element because we assume
                // uniquely-prefixed keys, so branch nodes never hold values

                // fetch the branch for the next nibble of the key
                uint256 keyNibble = uint256(key >> 252);

                // skip past the branches we don't need
                // we already skipped past 2 elements; start there if we can
                uint256 i = 0;
                if (keyNibble >= 2) {
                    i = 2;
                    node = node.suffix(size);
                }
                while (i < keyNibble) {
                    node = RLP.skip(node);
                    unchecked {
                        i++;
                    }
                }

                (expectedHash, ) = CoreTypes.parseHash(node);
                // if we've reached an empty branch, key doesn't exist
                if (expectedHash == 0) {
                    exists = false;
                    break;
                }
                unchecked {
                    key <<= 4;
                    keyLen -= 1;
                }
            }
        }
    }

    /**
     * @notice checks the MPT proof. Note: for certain optimizations, we assume
     *         that the rootHash belongs to a valid ethereum block. Correctness
     *         is only guaranteed in that case.
     *         Gas usage depends on both proof size and key nibble values.
     *         Gas usage for actual ethereum account proofs: ~ 30000 - 45000
     * @param proof the encoded MPT proof noodes concatenated
     * @param key the MPT key, padded with trailing 0s if needed
     * @param keyLen the byte length of the MPT key, must be <= 32
     * @param rootHash the root hash of the MPT
     */
    function verifyTrieValue(
        bytes calldata proof,
        bytes32 key,
        uint256 keyLen,
        bytes32 rootHash
    ) internal pure returns (bool exists, bytes calldata value) {
        Node[] memory nodes = parseNodes(proof);
        return verifyTrieValueWithNodes(nodes, key, keyLen, rootHash);
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @title Merkle Tree
 * @author Theori, Inc.
 * @notice Gas optimized SHA256 Merkle tree code.
 */
library MerkleTree {
    /**
     * @notice computes a SHA256 merkle root of the provided hashes, in place
     * @param temp the mutable array of hashes
     * @return the merkle root hash
     */
    function computeRoot(bytes32[] memory temp) internal view returns (bytes32) {
        uint256 count = temp.length;
        assembly {
            // repeat until we arrive at one root hash
            for {

            } gt(count, 1) {

            } {
                let dataElementLocation := add(temp, 0x20)
                let hashElementLocation := add(temp, 0x20)
                for {
                    let i := 0
                } lt(i, count) {
                    i := add(i, 2)
                } {
                    if iszero(
                        staticcall(gas(), 0x2, hashElementLocation, 0x40, dataElementLocation, 0x20)
                    ) {
                        revert(0, 0)
                    }
                    dataElementLocation := add(dataElementLocation, 0x20)
                    hashElementLocation := add(hashElementLocation, 0x40)
                }
                count := shr(1, count)
            }
        }
        return temp[0];
    }

    /**
     * @notice check if a hash is in the merkle tree for rootHash
     * @param rootHash the merkle root
     * @param index the index of the node to check
     * @param hash the hash to check
     * @param proofHashes the proof, i.e. the sequence of siblings from the
     *        node to root
     */
    function validProof(
        bytes32 rootHash,
        uint256 index,
        bytes32 hash,
        bytes32[] memory proofHashes
    ) internal view returns (bool result) {
        assembly {
            let constructedHash := hash
            let length := mload(proofHashes)
            let start := add(proofHashes, 0x20)
            let end := add(start, mul(length, 0x20))
            for {
                let ptr := start
            } lt(ptr, end) {
                ptr := add(ptr, 0x20)
            } {
                let proofHash := mload(ptr)

                // use scratch space (0x0 - 0x40) for hash input
                switch and(index, 1)
                case 0 {
                    mstore(0x0, constructedHash)
                    mstore(0x20, proofHash)
                }
                case 1 {
                    mstore(0x0, proofHash)
                    mstore(0x20, constructedHash)
                }

                // compute sha256
                if iszero(staticcall(gas(), 0x2, 0x0, 0x40, 0x0, 0x20)) {
                    revert(0, 0)
                }
                constructedHash := mload(0x0)

                index := shr(1, index)
            }
            result := eq(constructedHash, rootHash)
        }
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

/*
 * @author Theori, Inc.
 */

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

uint256 constant BASE_PROOF_SIZE = 34;
uint256 constant SUBPROOF_LIMBS_SIZE = 16;

struct RecursiveProof {
    uint256[BASE_PROOF_SIZE] base;
    uint256[SUBPROOF_LIMBS_SIZE] subproofLimbs;
    uint256[] inputs;
}

struct SignedRecursiveProof {
    RecursiveProof inner;
    bytes signature;
}

/**
 * @notice recover the signer of the proof
 * @param proof the SignedRecursiveProof
 * @return the address of the signer
 */
function getProofSigner(SignedRecursiveProof calldata proof) pure returns (address) {
    bytes32 msgHash = keccak256(
        abi.encodePacked("\x19Ethereum Signed Message:\n", "32", hashProof(proof.inner))
    );
    return ECDSA.recover(msgHash, proof.signature);
}

/**
 * @notice hash the contents of a RecursiveProof
 * @param proof the RecursiveProof
 * @return result a 32-byte digest of the proof
 */
function hashProof(RecursiveProof calldata proof) pure returns (bytes32 result) {
    uint256[] calldata inputs = proof.inputs;
    assembly {
        let ptr := mload(0x40)
        let contigLen := mul(0x20, add(BASE_PROOF_SIZE, SUBPROOF_LIMBS_SIZE))
        let inputsLen := mul(0x20, inputs.length)
        calldatacopy(ptr, proof, contigLen)
        calldatacopy(add(ptr, contigLen), inputs.offset, inputsLen)
        result := keccak256(ptr, add(contigLen, inputsLen))
    }
}

/**
 * @notice reverse the byte order of a uint256
 * @param input the input value
 * @return v the byte-order reversed value
 */
function byteReverse(uint256 input) pure returns (uint256 v) {
    v = input;

    uint256 MASK08 = 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00;
    uint256 MASK16 = 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000;
    uint256 MASK32 = 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000;
    uint256 MASK64 = 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000;

    // swap bytes
    v = ((v & MASK08) >> 8) | ((v & (~MASK08)) << 8);

    // swap 2-byte long pairs
    v = ((v & MASK16) >> 16) | ((v & (~MASK16)) << 16);

    // swap 4-byte long pairs
    v = ((v & MASK32) >> 32) | ((v & (~MASK32)) << 32);

    // swap 8-byte long pairs
    v = ((v & MASK64) >> 64) | ((v & (~MASK64)) << 64);

    // swap 16-byte long pairs
    v = (v >> 128) | (v << 128);
}

/**
 * @notice reads a 32-byte hash from its little-endian word-encoded form
 * @param words the hash words
 * @return the hash
 */
function readHashWords(uint256[] calldata words) pure returns (bytes32) {
    uint256 mask = 0xffffffffffffffff;
    uint256 result = (words[0] & mask);
    result |= (words[1] & mask) << 0x40;
    result |= (words[2] & mask) << 0x80;
    result |= (words[3] & mask) << 0xc0;
    return bytes32(byteReverse(result));
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @title RLP
 * @author Theori, Inc.
 * @notice Gas optimized RLP parsing code. Note that some parsing logic is
 *         duplicated because helper functions are oddly expensive.
 */
library RLP {
    function parseUint(bytes calldata buf) internal pure returns (uint256 result, uint256 size) {
        assembly {
            // check that we have at least one byte of input
            if iszero(buf.length) {
                revert(0, 0)
            }
            let first32 := calldataload(buf.offset)
            let kind := shr(248, first32)

            // ensure it's a not a long string or list (> 0xB7)
            // also ensure it's not a short string longer than 32 bytes (> 0xA0)
            if gt(kind, 0xA0) {
                revert(0, 0)
            }

            switch lt(kind, 0x80)
            case true {
                // small single byte
                result := kind
                size := 1
            }
            case false {
                // short string
                size := sub(kind, 0x80)

                // ensure it's not reading out of bounds
                if lt(buf.length, size) {
                    revert(0, 0)
                }

                switch eq(size, 32)
                case true {
                    // if it's exactly 32 bytes, read it from calldata
                    result := calldataload(add(buf.offset, 1))
                }
                case false {
                    // if it's < 32 bytes, we've already read it from calldata
                    result := shr(shl(3, sub(32, size)), shl(8, first32))
                }
                size := add(size, 1)
            }
        }
    }

    function nextSize(bytes calldata buf) internal pure returns (uint256 size) {
        assembly {
            if iszero(buf.length) {
                revert(0, 0)
            }
            let first32 := calldataload(buf.offset)
            let kind := shr(248, first32)

            switch lt(kind, 0x80)
            case true {
                // small single byte
                size := 1
            }
            case false {
                switch lt(kind, 0xB8)
                case true {
                    // short string
                    size := add(1, sub(kind, 0x80))
                }
                case false {
                    switch lt(kind, 0xC0)
                    case true {
                        // long string
                        let lengthSize := sub(kind, 0xB7)

                        // ensure that we don't overflow
                        if gt(lengthSize, 31) {
                            revert(0, 0)
                        }

                        // ensure that we don't read out of bounds
                        if lt(buf.length, lengthSize) {
                            revert(0, 0)
                        }
                        size := shr(mul(8, sub(32, lengthSize)), shl(8, first32))
                        size := add(size, add(1, lengthSize))
                    }
                    case false {
                        switch lt(kind, 0xF8)
                        case true {
                            // short list
                            size := add(1, sub(kind, 0xC0))
                        }
                        case false {
                            let lengthSize := sub(kind, 0xF7)

                            // ensure that we don't overflow
                            if gt(lengthSize, 31) {
                                revert(0, 0)
                            }
                            // ensure that we don't read out of bounds
                            if lt(buf.length, lengthSize) {
                                revert(0, 0)
                            }
                            size := shr(mul(8, sub(32, lengthSize)), shl(8, first32))
                            size := add(size, add(1, lengthSize))
                        }
                    }
                }
            }
        }
    }

    function skip(bytes calldata buf) internal pure returns (bytes calldata) {
        uint256 size = RLP.nextSize(buf);
        assembly {
            buf.offset := add(buf.offset, size)
            buf.length := sub(buf.length, size)
        }
        return buf;
    }

    function parseList(bytes calldata buf)
        internal
        pure
        returns (uint256 listSize, uint256 offset)
    {
        assembly {
            // check that we have at least one byte of input
            if iszero(buf.length) {
                revert(0, 0)
            }
            let first32 := calldataload(buf.offset)
            let kind := shr(248, first32)

            // ensure it's a list
            if lt(kind, 0xC0) {
                revert(0, 0)
            }

            switch lt(kind, 0xF8)
            case true {
                // short list
                listSize := sub(kind, 0xC0)
                offset := 1
            }
            case false {
                // long list
                let lengthSize := sub(kind, 0xF7)

                // ensure that we don't overflow
                if gt(lengthSize, 31) {
                    revert(0, 0)
                }
                // ensure that we don't read out of bounds
                if lt(buf.length, lengthSize) {
                    revert(0, 0)
                }
                listSize := shr(mul(8, sub(32, lengthSize)), shl(8, first32))
                offset := add(lengthSize, 1)
            }
        }
    }

    function splitBytes(bytes calldata buf)
        internal
        pure
        returns (bytes calldata result, bytes calldata rest)
    {
        uint256 offset;
        uint256 size;
        assembly {
            // check that we have at least one byte of input
            if iszero(buf.length) {
                revert(0, 0)
            }
            let first32 := calldataload(buf.offset)
            let kind := shr(248, first32)

            // ensure it's a not list
            if gt(kind, 0xBF) {
                revert(0, 0)
            }

            switch lt(kind, 0x80)
            case true {
                // small single byte
                offset := 0
                size := 1
            }
            case false {
                switch lt(kind, 0xB8)
                case true {
                    // short string
                    offset := 1
                    size := sub(kind, 0x80)
                }
                case false {
                    // long string
                    let lengthSize := sub(kind, 0xB7)

                    // ensure that we don't overflow
                    if gt(lengthSize, 31) {
                        revert(0, 0)
                    }
                    // ensure we don't read out of bounds
                    if lt(buf.length, lengthSize) {
                        revert(0, 0)
                    }
                    size := shr(mul(8, sub(32, lengthSize)), shl(8, first32))
                    offset := add(lengthSize, 1)
                }
            }

            result.offset := add(buf.offset, offset)
            result.length := size

            let end := add(offset, size)
            rest.offset := add(buf.offset, end)
            rest.length := sub(buf.length, end)
        }
    }

    function encodeUint(uint256 value) internal pure returns (bytes memory) {
        // allocate our result bytes
        bytes memory result = new bytes(33);

        if (value == 0) {
            // store length = 1, value = 0x80
            assembly {
                mstore(add(result, 1), 0x180)
            }
            return result;
        }

        if (value < 128) {
            // store length = 1, value = value
            assembly {
                mstore(add(result, 1), or(0x100, value))
            }
            return result;
        }

        if (value > 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
            // length 33, prefix 0xa0 followed by value
            assembly {
                mstore(add(result, 1), 0x21a0)
                mstore(add(result, 33), value)
            }
            return result;
        }

        if (value > 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
            // length 32, prefix 0x9f followed by value
            assembly {
                mstore(add(result, 1), 0x209f)
                mstore(add(result, 33), shl(8, value))
            }
            return result;
        }

        assembly {
            let length := 1
            for {
                let min := 0x100
            } lt(sub(min, 1), value) {
                min := shl(8, min)
            } {
                length := add(length, 1)
            }

            let bytesLength := add(length, 1)

            // bytes length field
            let hi := shl(mul(bytesLength, 8), bytesLength)

            // rlp encoding of value
            let lo := or(shl(mul(length, 8), add(length, 0x80)), value)

            mstore(add(result, bytesLength), or(hi, lo))
        }
        return result;
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../interfaces/IReliquary.sol";
import "../interfaces/IBatchProver.sol";

abstract contract BatchProver is ERC165, IBatchProver {
    IReliquary immutable reliquary;

    constructor(IReliquary _reliquary) {
        reliquary = _reliquary;
    }

    // Signaling event for off-chain indexers, does not contain data in order
    // to save gas
    event FactsProven();

    // must implemented by each prover
    function _prove(bytes calldata proof) internal view virtual returns (Fact[] memory);

    // can optionally be overridden by each prover
    function _afterStore(Fact memory fact, bool alreadyStored) internal virtual {}

    /**
     * @notice proves a fact ephemerally and returns the fact information
     * @param proof the encoded proof for this prover
     * @param store whether to store the fact in the reqliquary
     */
    function proveBatch(bytes calldata proof, bool store)
        public
        payable
        returns (Fact[] memory facts)
    {
        reliquary.checkProveFactFee{value: msg.value}(msg.sender);
        facts = _prove(proof);
        emit FactsProven();
        for (uint256 i = 0; i < facts.length; i++) {
            Fact memory fact = facts[i];
            if (store) {
                (bool alreadyStored, , ) = reliquary.getFact(fact.account, fact.sig);
                reliquary.setFact(fact.account, fact.sig, fact.data);
                _afterStore(fact, alreadyStored);
            }
        }
    }

    /**
     * @inheritdoc IERC165
     * @dev Supported interfaces: IProver
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return (interfaceId == type(IBatchProver).interfaceId ||
            super.supportsInterface(interfaceId));
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "../interfaces/IReliquary.sol";
import "../RelicToken.sol";
import "../BlockHistory.sol";
import "./BatchProver.sol";
import "./StateVerifier.sol";
import "../lib/FactSigs.sol";

/**
 * @title CachedMultiStorageSlotProver
 * @author Theori, Inc.
 * @notice CachedMultiStorageSlotProver batch proves multiple storage slots from an account
 *         at a particular block, using a cached account storage root
 */
contract CachedMultiStorageSlotProver is BatchProver, StateVerifier {
    constructor(BlockHistory blockHistory, IReliquary _reliquary)
        BatchProver(_reliquary)
        StateVerifier(blockHistory, _reliquary)
    {}

    struct CachedMultiStorageSlotProof {
        address account;
        uint256 blockNumber;
        bytes32 storageRoot;
        bytes proofNodes;
        bytes32[] slots;
        bytes slotProofs;
    }

    function parseCachedMultiStorageSlotProof(bytes calldata proof)
        internal
        pure
        returns (CachedMultiStorageSlotProof calldata res)
    {
        assembly {
            res := proof.offset
        }
    }

    /**
     * @notice Proves that a storage slot had a particular value at a particular block.
     *
     * @param encodedProof the encoded CachedMultiStorageSlotProof
     */
    function _prove(bytes calldata encodedProof) internal view override returns (Fact[] memory) {
        CachedMultiStorageSlotProof calldata proof = parseCachedMultiStorageSlotProof(encodedProof);
        (bool exists, , ) = reliquary.getFact(
            proof.account,
            FactSigs.accountStorageFactSig(proof.blockNumber, proof.storageRoot)
        );
        require(exists, "Cached storage root doesn't exist");

        BytesCalldata[] memory values = verifyMultiStorageSlot(
            proof.proofNodes,
            proof.slots,
            proof.slotProofs,
            proof.storageRoot
        );

        Fact[] memory facts = new Fact[](values.length);

        for (uint256 i = 0; i < values.length; i++) {
            facts[i] = Fact(
                proof.account,
                FactSigs.storageSlotFactSig(proof.slots[i], proof.blockNumber),
                values[i].convert()
            );
        }
        return facts;
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "../BlockHistory.sol";
import "../interfaces/IReliquary.sol";
import "../lib/BytesCalldata.sol";
import "../lib/CoreTypes.sol";
import "../lib/RLP.sol";
import "../lib/MPT.sol";

/**
 * @title StateVerifier
 * @author Theori, Inc.
 * @notice StateVerifier is a base contract for verifying historical Ethereum
 *         state using BlockHistory proofs and MPT proofs.
 */
contract StateVerifier {
    using BytesCalldataOps for bytes;

    BlockHistory public immutable blockHistory;
    IReliquary private immutable reliquary;

    constructor(BlockHistory _blockHistory, IReliquary _reliquary) {
        blockHistory = _blockHistory;
        reliquary = _reliquary;
    }

    /**
     * @notice verifies that the block header is included in the current chain
     *         by querying the BlockHistory contract using the provided proof.
     *         Reverts if the header or proof is invalid.
     *
     * @param header the block header in RLP encoded form
     * @param proof the proof to pass to blockHistory
     * @return head the parsed block header
     */
    function verifyBlockHeader(bytes calldata header, bytes calldata proof)
        internal
        view
        returns (CoreTypes.BlockHeaderData memory head)
    {
        // first validate the block, ensuring that the rootHash is valid
        (bytes32 blockHash, ) = CoreTypes.getBlockHeaderHashAndSize(header);
        head = CoreTypes.parseBlockHeader(header);
        reliquary.assertValidBlockHashFromProver(
            address(blockHistory),
            blockHash,
            head.Number,
            proof
        );
    }

    /**
     * @notice verifies that the account is included in the account trie using
     *         the provided proof. Accepts both existence and nonexistence
     *         proofs. Reverts if the proof is invalid. Assumes the stateRoot
     *         comes from a valid Ethereum block header.
     *
     * @param account the account address to check
     * @param proof the MPT proof for the account trie
     * @param stateRoot the MPT root hash for the account trie
     * @return exists whether the account exists
     * @return acc the parsed account value
     */
    function verifyAccount(
        address account,
        bytes calldata proof,
        bytes32 stateRoot
    ) internal pure returns (bool exists, CoreTypes.AccountData memory acc) {
        bytes32 key = keccak256(abi.encodePacked(account));

        // validate the trie node and extract the value (if it exists)
        bytes calldata accountValue;
        (exists, accountValue) = MPT.verifyTrieValue(proof, key, 32, stateRoot);
        if (exists) {
            acc = CoreTypes.parseAccount(accountValue);
        }
    }

    /**
     * @notice verifies that the storage slot is included in the storage trie
     *         using the provided proof. Accepts both existence and nonexistence
     *         proofs. Reverts if the proof is invalid. Assumes the storageRoot
     *         comes from a valid Ethereum account.
     *
     * @param slot the storage slot index
     * @param proof the MPT proof for the storage trie
     * @param storageRoot the MPT root hash for the storage trie
     * @return value the value in the storage slot, as bytes, with leading 0 bytes removed
     */
    function verifyStorageSlot(
        bytes32 slot,
        bytes calldata proof,
        bytes32 storageRoot
    ) internal pure returns (bytes calldata value) {
        bytes32 key = keccak256(abi.encodePacked(slot));

        // validate the trie node and extract the value (default is 0)
        bool exists;
        (exists, value) = MPT.verifyTrieValue(proof, key, 32, storageRoot);
        if (exists) {
            (value, ) = RLP.splitBytes(value);
            require(value.length <= 32);
        }
    }

    /**
     * @notice verifies that each storage slot is included in the storage trie
     *         using the provided proofs. Accepts both existence and nonexistence
     *         proofs. Reverts if a proof is invalid. Assumes the storageRoot
     *         comes from a valid Ethereum account.
     * @param proofNodes concatenation of all nodes used in the trie proofs
     * @param slots the list of slots being proven
     * @param slotProofs the compressed MPT proofs for each slot
     * @param storageRoot the MPT root hash for the storage trie
     * @return values the values in the storage slot, as bytes, with leading 0 bytes removed
     */
    function verifyMultiStorageSlot(
        bytes calldata proofNodes,
        bytes32[] calldata slots,
        bytes calldata slotProofs,
        bytes32 storageRoot
    ) internal pure returns (BytesCalldata[] memory values) {
        MPT.Node[] memory nodes = MPT.parseNodes(proofNodes);
        MPT.Node[][] memory proofs = MPT.parseCompressedProofs(nodes, slotProofs, slots.length);
        BytesCalldata[] memory results = new BytesCalldata[](slots.length);

        for (uint256 i = 0; i < slots.length; i++) {
            bytes32 key = keccak256(abi.encodePacked(slots[i]));
            (bool exists, bytes calldata value) = MPT.verifyTrieValueWithNodes(
                proofs[i],
                key,
                32,
                storageRoot
            );
            if (exists) {
                (value, ) = RLP.splitBytes(value);
                require(value.length <= 32);
            }
            results[i] = value.convert();
        }
        return results;
    }

    /**
     * @notice verifies that the receipt is included in the receipts trie using
     *         the provided proof. Accepts both existence and nonexistence
     *         proofs. Reverts if the proof is invalid. Assumes the receiptsRoot
     *         comes from a valid Ethereum block header.
     *
     * @param idx the receipt index in the block
     * @param proof the MPT proof for the storage trie
     * @param receiptsRoot the MPT root hash for the storage trie
     * @return exists whether the receipt index exists
     * @return value the value in the storage slot, as bytes, with leading 0 bytes removed
     */
    function verifyReceipt(
        uint256 idx,
        bytes calldata proof,
        bytes32 receiptsRoot
    ) internal pure returns (bool exists, bytes calldata value) {
        bytes memory key = RLP.encodeUint(idx);
        (exists, value) = MPT.verifyTrieValue(proof, bytes32(key), key.length, receiptsRoot);
    }

    /**
     * @notice verifies that the account is included in the account trie for
     *         a block using the provided proofs. Accepts both existence and
     *         nonexistence proofs. Reverts if the proofs are invalid.
     *
     * @param account the account address to check
     * @param accountProof the MPT proof for the account trie
     * @param header the block header in RLP encoded form
     * @param blockProof the proof to pass to blockHistory
     * @return exists whether the account exists
     * @return head the parsed block header
     * @return acc the parsed account value
     */
    function verifyAccountAtBlock(
        address account,
        bytes calldata accountProof,
        bytes calldata header,
        bytes calldata blockProof
    )
        internal
        view
        returns (
            bool exists,
            CoreTypes.BlockHeaderData memory head,
            CoreTypes.AccountData memory acc
        )
    {
        head = verifyBlockHeader(header, blockProof);
        (exists, acc) = verifyAccount(account, accountProof, head.Root);
    }

    /**
     * @notice verifies a log was emitted in the given block, txIdx, and logIdx
     *         using the provided proofs. Reverts if the log doesn't exist or if
     *         the proofs are invalid.
     *
     * @param txIdx the transaction index in the block
     * @param logIdx the index of the log in the transaction
     * @param receiptProof the Merkle-Patricia trie proof for the receipt
     * @param header the block header, RLP encoded
     * @param blockProof proof that the block header is valid
     * @return head the parsed block header
     * @return log the parsed log value
     */
    function verifyLogAtBlock(
        uint256 txIdx,
        uint256 logIdx,
        bytes calldata receiptProof,
        bytes calldata header,
        bytes calldata blockProof
    ) internal view returns (CoreTypes.BlockHeaderData memory head, CoreTypes.LogData memory log) {
        head = verifyBlockHeader(header, blockProof);
        (bool exists, bytes calldata receiptValue) = verifyReceipt(
            txIdx,
            receiptProof,
            head.ReceiptHash
        );
        require(exists, "receipt does not exist");
        log = CoreTypes.extractLog(receiptValue, logIdx);
    }
}