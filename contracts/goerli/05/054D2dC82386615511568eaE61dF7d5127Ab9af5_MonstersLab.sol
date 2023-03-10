// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import './MonstersStorage.sol';

interface CapsuleMinter {
    // Declare a function that returns the RevealDetail struct
    function getRevealDetails(uint256 _id) external view returns (RevealDetail memory);

    function getShadow(uint256 _nft) external view returns (uint256);

    struct RevealDetail {
        uint256 id;
        uint256 mintDate;
        uint256 revealTime;
    }
}

interface MonsterNFT {
    function getNftPoints(uint256 _tokenId) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);
}

contract MonstersLab {
    using MerkleProof for bytes32[];

    bool public paused = false;
    address public admin;

    uint256[] public costPerStore;

    event MonsterCreated(uint256 indexed nftID, uint256 attributes);
    event MonsterUpdated(uint256 indexed nftID, uint256 attributes);
    event MonsterRevealed(uint256 indexed nftID, uint256 shape);
    event MonsterChanged(uint256 indexed nftID, uint256 attributes);

    MonsterNFT public monsterNft;
    MonstersStorage public storageContract;
    CapsuleMinter public capsuleMinter;

    constructor(MonsterNFT _nft, MonstersStorage _storageContract, CapsuleMinter _capsuleMinter) {
        admin = msg.sender;
        monsterNft = _nft;
        storageContract = _storageContract;
        capsuleMinter = _capsuleMinter;
        costPerStore = [0.01 ether, 0.02 ether, 0.03 ether, 0.04 ether, 0.05 ether];
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, 'Only the admin can call this function.');
        _;
    }

    modifier isNotPaused() {
        require(!paused, 'Contract Paused');
        _;
    }

    function isReadyToReveal(uint256 _tokenID) public view returns (bool) {
        CapsuleMinter.RevealDetail memory revealDetails = capsuleMinter.getRevealDetails(_tokenID);
        uint256 revealTimestamp = revealDetails.mintDate + (revealDetails.revealTime * 1 days); // calculate reveal timestamp
        return (revealTimestamp <= block.timestamp); // return whether reveal timestamp is less than or equal to current timestamp
    }

    function storeMonster(uint256 _nftId, uint256 packedValue, bytes32[] memory _proof) external payable isNotPaused {
        uint256 oldAttributes = storageContract.getMonsterAttributes(_nftId);

        uint256 timesUpdated = storageContract.getMonsterUpdateCount(_nftId);

        // if 0 free, else cost
        // if timesUpdated = 1, cost = 2x = ethCost * (timesUpdated+1)
        uint256 totalCost;
        // if (timesUpdated > 0) {
        //     if (timesUpdated <= costPerStore.length) {
        //         totalCost = costPerStore[timesUpdated - 1];
        //         require(msg.value >= totalCost, 'Payment required');
        //     } else {
        //         totalCost = costPerStore[costPerStore.length - 1];
        //         require(msg.value >= totalCost, 'Payment required');
        //     }
        // }

        require(isReadyToReveal(_nftId), 'Not Ready To Reveal');
        require(monsterNft.ownerOf(_nftId) == msg.sender, 'Not the owner of the NFT');
        require(storageContract.getAttributesMonster(packedValue) == 0, 'Monster Already Exists');

        uint256 _shape = (packedValue >> (8 * 0)) & 0xff;

        //require(storageContract.getMonsterShape(_nftId) != 0, 'Shape Not Revealed'); // checks if the shape was revealed for the nftID
        require(storageContract.getAttributeValuesByShape(_shape) != 0, 'Invalid Monster Shape'); // checks non-zero shape
        require(_shape == capsuleMinter.getShadow(_nftId), 'Shape Does Not Match Revealed Shape'); // checks if the shape is the same as the revealed shape

        // i initialized to 0, full iteration is 12, 0-11, considering shape aswell inside attributes
        for (uint256 i; i <= 11; i++) {
            uint256 attr = (packedValue >> (8 * i)) & 0xff;
            bytes32 root = storageContract.getRealm(_shape, i, attr);

            if (root != 0 && root != bytes32(0)) {
                require(
                    _proof.verify(root, keccak256(abi.encodePacked(Strings.toString(_nftId)))),
                    string(
                        abi.encodePacked('Invalid Monster Id Realm:', Strings.toString(i), ':', Strings.toString(attr))
                    )
                );
            }

            if (i <= 2) {
                require(attr != 0, string(abi.encodePacked('Missing Monster Attribute ', Strings.toString(i))));
            }
            // checks if the attribute is valid, considers shape aswell for example if first is index 0, shape is 1 max shape is 1, but for attrbiutes bg is 1 so max is 10 for example bg cant be over 10
            require(
                attr <= (storageContract.getAttributeValuesByShape(_shape) >> (8 * i)) & 0xff,
                string(abi.encodePacked('Invalid Monster Attribute ', Strings.toString(i)))
            );
            if (i >= 1 && attr != 0) {
                // checks if nft has enough ePoints to equip the attribute
                require(
                    monsterNft.getNftPoints(_nftId) >= storageContract.getAttributePrice(_shape, i, attr),
                    string(
                        abi.encodePacked(
                            'Not Enough Points To Equip:',
                            Strings.toString(i),
                            ':',
                            Strings.toString(attr)
                        )
                    )
                );
                // Skips the shape & empty attribute value
                if (storageContract.getAttributeSupply(_shape, i, attr) == 0) {
                    // If the attribute is not set, skip it's a limitless attribute
                    continue;
                }
                if (attr == ((oldAttributes >> (8 * i)) & 0xff)) {
                    // If the attribute is not changed, skip it
                    continue;
                }
                require(
                    storageContract.getAttributeAvailable(_shape, i, attr) > 0,
                    string(
                        abi.encodePacked(
                            'No more attributes available type:',
                            Strings.toString(i + 1),
                            ':',
                            Strings.toString(attr)
                        )
                    )
                );
                storageContract.decrementAttributeAvailable(_shape, i, attr);
            }
        }

        if (oldAttributes == 0) {
            storageContract.setMonsterAttributes(_nftId, packedValue);
            storageContract.setAttributesMonster(packedValue, _nftId);
            storageContract.incrementMonsterUpdateCount(_nftId);
            emit MonsterCreated(_nftId, packedValue);
        } else {
            storageContract.setAttributesMonster(oldAttributes, 0);
            storageContract.setMonsterAttributes(_nftId, packedValue);
            storageContract.setAttributesMonster(packedValue, _nftId);
            storageContract.incrementMonsterUpdateCount(_nftId);
            emit MonsterUpdated(_nftId, packedValue);

            // if more eth is sent than the cost, return the extra eth to the sender
            // if (msg.value > totalCost) {
            //     payable(msg.sender).transfer(msg.value - totalCost);
            // }
        }
    }

    function pause() external onlyAdmin {
        paused = true;
    }

    function unpause() external onlyAdmin {
        paused = false;
    }

    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MonstersStorage {
    struct AttributeAmount {
        uint256 total;
        uint256 available;
        uint256 price; // points
        bytes32 realm; // merkle root of nftIDs
    }
    struct Monster {
        uint256 shape;
        uint256 attributes;
    }
    mapping(uint256 => uint256) public attributes; // attributes - ID
    mapping(uint256 => Monster) public monsters; // ID - Monster { shape, attributes}
    mapping(uint256 => uint256) public monsterUpdateCount; // ID - num of times updated/stored
    mapping(uint256 => uint256) public monsterAttributes; // ID shape - max number for each attribute

    // shape - attribute type - attribute value - total and available
    mapping(uint256 => mapping(uint256 => mapping(uint256 => AttributeAmount))) public monsterAttributesSupply;

    address public owner; // Owner allowed to call setters on attributes and supply
    address public proxy; // contract address allowed to call setters on monsters

    constructor() {
        owner = msg.sender;
        proxy = msg.sender;
    }

    modifier onlyProxy() {
        require(msg.sender == proxy, 'Only Proxy');
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Only Owner');
        _;
    }

    function setProxy(address _admin) external onlyOwner {
        proxy = _admin;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function setAttributeSupply(
        uint256 _shape,
        uint256 _attribute,
        uint256 _value,
        uint256 _supply,
        uint256 _available
    ) external onlyOwner {
        monsterAttributesSupply[_shape][_attribute][_value].total = _supply;
        monsterAttributesSupply[_shape][_attribute][_value].available = _available;
    }

    function setPrice(uint256 _shape, uint256 _attribute, uint256 _value, uint256 _price) external onlyOwner {
        monsterAttributesSupply[_shape][_attribute][_value].price = _price;
    }

    function setRealm(uint256 _shape, uint256 _attribute, uint256 _value, bytes32 _root) external onlyOwner {
        monsterAttributesSupply[_shape][_attribute][_value].realm = _root;
    }

    function setMonsterAttributesValues(uint256 _shape, uint256 _attributes) external onlyOwner {
        monsterAttributes[_shape] = _attributes; // shape - max number for each attribute in packed uint256 includes shape + attributes
    }

    function getMonsterShape(uint256 _id) public view returns (uint256) {
        return monsters[_id].shape;
    }

    function getMonsterAttributes(uint256 _id) public view returns (uint256) {
        return monsters[_id].attributes;
    }

    function getAttributesMonster(uint256 _attributes) public view returns (uint256) {
        return attributes[_attributes];
    }

    function getAttributeValuesByShape(uint256 _shape) external view returns (uint256) {
        return monsterAttributes[_shape];
    }

    function getRealm(uint256 _shape, uint256 _attribute, uint256 _value) external view returns (bytes32) {
        return monsterAttributesSupply[_shape][_attribute][_value].realm;
    }

    function getAttributePrice(uint256 _shape, uint256 _attribute, uint256 _value) external view returns (uint256) {
        return monsterAttributesSupply[_shape][_attribute][_value].price;
    }

    function getAttributeSupply(uint256 _shape, uint256 _attribute, uint256 _value) external view returns (uint256) {
        return monsterAttributesSupply[_shape][_attribute][_value].total;
    }

    function getAttributeAvailable(uint256 _shape, uint256 _attribute, uint256 _value) external view returns (uint256) {
        return monsterAttributesSupply[_shape][_attribute][_value].available;
    }

    function setMonsterAttributes(uint256 _id, uint256 _attributes) external onlyProxy {
        monsters[_id].attributes = _attributes;
    }

    function setAttributesMonster(uint256 _attributes, uint256 _id) external onlyProxy {
        attributes[_attributes] = _id;
    }

    function incrementMonsterUpdateCount(uint256 _id) external onlyProxy {
        monsterUpdateCount[_id] += 1;
    }

    function getMonsterUpdateCount(uint256 _id) external view returns (uint256) {
        return monsterUpdateCount[_id];
    }

    function setMonsterShape(uint256 _id, uint256 _shape) external onlyProxy {
        monsters[_id].shape = _shape;
    }

    function decrementAttributeAvailable(uint256 _shape, uint256 _attribute, uint256 _value) external onlyProxy {
        monsterAttributesSupply[_shape][_attribute][_value].available -= 1;
    }
}