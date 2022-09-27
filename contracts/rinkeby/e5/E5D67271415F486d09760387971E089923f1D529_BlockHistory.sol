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

pragma solidity >=0.8.0;

import "./RLP.sol";

/**
 * @title CoreTypes
 * @author Theori, Inc.
 * @notice Data types and parsing functions for core types, including block headers
 *         and account data.
 */
library CoreTypes {
    struct BlockHeaderData {
        bytes32 ParentHash;
        bytes32 Root;
        bytes32 TxHash;
        bytes32 ReceiptHash;
        uint256 Number;
        uint256 Time;
        uint256 BaseFee;
    }

    struct AccountData {
        uint256 Nonce;
        uint256 Balance;
        bytes32 StorageRoot;
        bytes32 CodeHash;
    }

    function parseHash(bytes calldata buf) internal pure returns (bytes32 result, uint256 offset) {
        uint256 value;
        (value, offset) = RLP.parseUint(buf);
        result = bytes32(value);
    }

    function parseBlockHeader(bytes calldata header)
        internal
        pure
        returns (BlockHeaderData memory data)
    {
        (uint256 listSize, uint256 offset) = RLP.parseList(header);
        header = header[offset:offset + listSize];

        (data.ParentHash, offset) = parseHash(header); // ParentHash
        header = header[offset:];
        offset = RLP.skip(header); // UncleHash
        header = header[offset:];
        offset = RLP.skip(header); // Coinbase
        header = header[offset:];
        (data.Root, offset) = parseHash(header); // Root
        header = header[offset:];
        (data.TxHash, offset) = parseHash(header); // TxHash
        header = header[offset:];
        (data.ReceiptHash, offset) = parseHash(header); // ReceiptHash
        header = header[offset:];
        offset = RLP.skip(header); // Bloom
        header = header[offset:];
        offset = RLP.skip(header); // Difficulty
        header = header[offset:];
        (data.Number, offset) = RLP.parseUint(header); // Number
        header = header[offset:];
        offset = RLP.skip(header); // GasLimit
        header = header[offset:];
        offset = RLP.skip(header); // GasUsed
        header = header[offset:];
        (data.Time, offset) = RLP.parseUint(header); // Time
        header = header[offset:];
        offset = RLP.skip(header); // Extra
        header = header[offset:];
        offset = RLP.skip(header); // MixDigest
        header = header[offset:];
        offset = RLP.skip(header); // Nonce
        header = header[offset:];

        if (header.length > 0) {
            (data.BaseFee, offset) = RLP.parseUint(header); // BaseFee
            header = header[offset:];
        }
    }

    function getBlockHeaderHashAndSize(bytes calldata header)
        internal
        pure
        returns (bytes32 blockHash, uint256 headerSize)
    {
        (uint256 listSize, uint256 offset) = RLP.parseList(header);
        headerSize = offset + listSize;
        blockHash = keccak256(header[0:headerSize]);
    }

    function parseAccount(bytes calldata account) internal pure returns (AccountData memory data) {
        (, uint256 offset) = RLP.parseList(account);
        account = account[offset:];

        (data.Nonce, offset) = RLP.parseUint(account); // Nonce
        account = account[offset:];
        (data.Balance, offset) = RLP.parseUint(account); // Balance
        account = account[offset:];
        (data.StorageRoot, offset) = parseHash(account); // StorageRoot
        account = account[offset:];
        (data.CodeHash, offset) = parseHash(account); // CodeHash
        account = account[offset:];
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

    function skip(bytes calldata buf) internal pure returns (uint256 size) {
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
                    }
                }
            }
        }
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
        }
        unchecked {
            result = buf[offset:offset + size];
            rest = buf[offset + size:];
        }
    }
}