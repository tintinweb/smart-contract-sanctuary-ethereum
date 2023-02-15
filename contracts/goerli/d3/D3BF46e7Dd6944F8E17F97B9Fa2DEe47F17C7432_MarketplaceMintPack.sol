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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
pragma solidity ^0.8.17;
interface IMinter 
{ 
    function purchase(uint256 _projectId) payable external returns (uint tokenID); 
    function purchaseTo(address _to, uint _projectId) payable external returns (uint tokenID);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
interface IMP 
{ 
    /**
     * @dev { For Instances Where Golden Token Or Artists Have A Bespoke Mint Pass Contract }
     */
    function _LiveMintBurn(uint TicketID) external returns(address Recipient); 

    /**
     * @dev { For Instances Where Artists Share The Same Mint Pass Contract }
     */
    function _LiveMintBurnShared(uint TicketID) external returns(address Recipient, uint ArtistID);
}

//SPDX-License-Identifier: MIT
/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/
/**
 * @dev: @brougkr
 */
pragma solidity 0.8.17;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IMP} from "./IMP.sol";
import {IMinter} from "./IMinter.sol";
contract MarketplaceMintPack is Ownable, ReentrancyGuard
{
    struct Sale
    {
        string _Name;                     // [0] -> _Name
        uint _ProjectID;                  // [1] -> _ProjectID
        uint _PriceStart;                 // [2] -> _PriceStart
        uint _PriceEnd;                   // [3] -> _PriceEnd
        uint _WalletLimiter;              // [4] -> _WalletLimiter
        uint _MaximumAvailableForSale;    // [5] -> _MaximumAvailableForSale
        uint _StartingBlockUnixTimestamp; // [6] -> _StartingBlockUnixTimestamp
        uint _SecondsBetweenPriceDecay;   // [7] -> _SecondsBetweenPriceDecay
    }

    struct InternalSale
    {
        address _NFT;             // [0] -> _NFT
        address _Operator;        // [1] _Operator (Wallet That NFT Is Pulling From)
        uint _CurrentIndex;       // [2] _CurrentIndex (If Simple Sale Type, This Is The Next Token Index To Iterate Upon)
        bool _Presale;            // [3] _Presale (Whether It's A Presale Or Dutch)
        bool _Simple;             // [4] _Simple (Whether It's A purchaseTo() Or Simple ERC721 transferFrom() Sale)
        bool _ActivePublic;       // [5] -> _ActivePublic
        bool _ActiveBrightList;   // [6] -> _ActiveBrightList 
        bool _Discount;           // [7] -> _Discount
        bool _ETHClaimsEnabled;   // [8] -> _ETHClaimsEnabled
    }

    struct SaleParam
    {
        bytes32[] _Roots;        // [0] -> _Roots
        bytes32[] _RootsAmounts; // [1] -> _RootsAmounts
        uint[] _DiscountAmounts; // [2] -> _DiscountAmounts
    }

    struct MiscSale
    {
        uint _AmountSold;         // [0] -> _AmountSold
        uint _UniqueSales;        // [1] -> _UniqueSales
        uint _FinalClearingPrice; // [2] -> _FinalClearingPrice
        uint _CurrentRefundIndex; // [3] -> _CurrentRefundIndex
    }

    struct Order
    {
        address _Purchaser;       // [0] _Purchaser
        uint _PurchaseValue;      // [1] _PurchaseValue
        uint _PurchaseAmount;     // [2] _PurchaseAmount
        uint _Priority;           // [3] _BrightList Priority Status note: (0 Is Highest Priority)
        bool _BrightListPurchase; // [4] _BrightListPurchase
        bool _Claimed;            // [5] _Claimed
    }

    struct _UserSaleInformation
    {
        uint[] _UserOrderIndexes;      // [0] -> _UserOrderIndexes
        uint _PurchasedAmount;         // [1] -> _PurchaseAmount
        uint _RemainingPurchaseAmount; // [2] -> _RemainingPurchaseAmount
        uint _ClaimIndex;              // [3] -> _ClaimIndex
        uint _AmountRemaining;         // [4] -> _AmountRemaining
        uint _CurrentPrice;            // [5] -> _MintPassCurrentPrice
        uint _Priority;                // [6] -> _Priority For BrightList note: (0 Is Highest Priority)
        bool _MaxAmountVerified;       // [7] -> _MaxAmountVerified     
        bool _BrightListEligible;      // [8] -> _BrightListEligible
        bool _SaleActive;              // [9] -> _SalePaused
    }

    struct Info
    {
        uint _CurrentPrice;            // [0] -> _CurrentPrice
        uint _MaximumAvailableForSale; // [1] -> _MaximumAvailableForSale
        uint _AmountRemaining;         // [2] -> _AmountRemaining
        bool _Ended;                   // [3] -> _Ended
    }

    /*------------------
     * STATE VARIABLES *
    -------------------*/

    address public _DR = 0x00000000000076A84feF008CDAbe6409d2FE638B;                     // Delegation Registry 
    uint public _TOTAL_UNIQUE_SALES_DUTCH;                                               // Total Unique Dutch Sales
    // address private constant _BRT_MULTISIG = 0x0BC56e3c1397e4570069e89C07936A5c6020e3BE; // `sales.brightmoments.eth`
    address private constant _BRT_MULTISIG = 0x7603C5eed8e57Ad795ec5F0081eFB21d1eEBf937; // test
    
    /*-----------
     * MAPPINGS *
    ------------*/

    mapping(uint=>Sale) public Sales;                                                  // [SaleIndex] => Sale
    mapping(uint=>MiscSale) public SaleState;                                          // [SaleIndex] => MiscSale
    mapping(uint=>InternalSale) public SalesInternal;                                  // [SaleIndex] => InternalSale
    mapping(uint=>Order[]) public Orders;                                              // [SaleIndex][UniqueSaleIndex] => Order
    mapping(uint=>mapping(address=>_UserSaleInformation)) public UserInfo;             // [SaleIndex][Wallet] => UserInfo
    mapping(uint=>SaleParam) private SaleParams;                                       // [SaleIndex] => SaleParam
    mapping(address=>bool) public Admin;                                               // [Wallet] => IsAdmin
    mapping(address=>bool) public InitializedSale;                                     // [NFT Address] => IsEnabled
    mapping(address=>uint) public NFTAddressToSaleIndex;                               // [NFT Address] => SaleIndex

    event Purchased(address Purchaser, uint Amount, uint MessageValue, uint CurrentPurchaseValue, uint NewAmountSold);
    event PurchasedTraditional(uint SaleIndex, address Purchaser, uint DesiredAmount, uint MessageValue, bool PresaleEnded);    
    event MarketplacePurchase(uint SaleIndex, uint Amount, uint MessageValue, address Recipient, bool BrightList);
    event Refunded(uint Value);
    event OrderRefundFailed(uint SaleIndex, uint OrderIndex);
    event SaleStarted(uint SaleIndex);
    event RefundClaimed(uint SaleIndex, uint OrderIndex);
    event TraditionalSaleStarted(uint SaleIndex);

    constructor() { Admin[msg.sender] = true; }

    /*---------------------
     * EXTERNAL FUNCTIONS *
    ----------------------*/

    /**
     * @dev Purchases NFTs
     * note: `msg.value` Must Be Sufficient To Purchase NFTs @ The Current Price Of The Dutch Auction
     * note: @param ProofEligibility - Merkle Proof Of Eligibility For BrightList note: Input --> [0x0] <-- For Empty Proof
     * note: @param ProofAmount - Merkle Proof Of Amount For BrightList note: Input --> [0x0] <-- For Empty Proof
     */
    function Purchase (
        uint SaleIndex, 
        uint Amount, 
        uint DI, 
        uint MaxAmount, 
        bytes32[] calldata ProofEligibility, 
        bytes32[] calldata ProofAmount
    ) external payable nonReentrant { 
        InternalSale memory _IS = SalesInternal[SaleIndex];
        require(tx.origin == msg.sender, "DutchMarketplace: EOA Only");
        require(block.timestamp >= Sales[SaleIndex]._StartingBlockUnixTimestamp, "DutchMarketplace: Sale Not Started");
        require(_IS._ActivePublic || _IS._ActiveBrightList, "DutchMarketplace: Sale Not Active");
        address Recipient = msg.sender;
        uint OrderIndex = SaleState[SaleIndex]._UniqueSales;
        if(DI != 69420) { Recipient = IDelegationRegistry(_DR).getDelegationsByDelegate(msg.sender)[DI].vault; }
        require(Recipient != address(0), "DutchMarketplace: Invalid Recipient");
        if(SaleState[SaleIndex]._AmountSold + Amount > Sales[SaleIndex]._MaximumAvailableForSale)
        {
            Amount = Sales[SaleIndex]._MaximumAvailableForSale - SaleState[SaleIndex]._AmountSold;
        }
        uint NewAmountSold = SaleState[SaleIndex]._AmountSold + Amount;
        require(NewAmountSold <= Sales[SaleIndex]._MaximumAvailableForSale, "DutchMarketplace: Sold Out");
        uint Priority = 69420;
        uint NewUserPurchasedAmount = UserInfo[SaleIndex][Recipient]._PurchasedAmount + Amount;
        require(Amount > 0 && Amount <= Sales[SaleIndex]._WalletLimiter, "DutchMarketplace: Incorrect Amount");
        uint CurrentPrice = ViewCurrentPrice(SaleIndex);
        uint CurrentPurchaseValue = CurrentPrice * Amount;
        require(msg.value >= CurrentPurchaseValue, "DutchMarketplace: Incorrect ETH Amount Sent");
        if(msg.value > CurrentPurchaseValue) { __Refund(msg.sender, (msg.value - CurrentPurchaseValue)); }
        Orders[SaleIndex].push(Order(msg.sender, CurrentPurchaseValue, Amount, Priority, false, false));
        UserInfo[SaleIndex][Recipient]._UserOrderIndexes.push(OrderIndex);
        UserInfo[SaleIndex][Recipient]._PurchasedAmount = NewUserPurchasedAmount;
        SaleState[SaleIndex]._UniqueSales = OrderIndex + 1;
        SaleState[SaleIndex]._AmountSold = NewAmountSold;
        require(SaleState[SaleIndex]._AmountSold <= Sales[SaleIndex]._MaximumAvailableForSale, "DutchMarketplace: Overflow");
        if(SaleState[SaleIndex]._AmountSold == Sales[SaleIndex]._MaximumAvailableForSale)
        { 
            SaleState[SaleIndex]._FinalClearingPrice = CurrentPrice; 
            ___EndSale(SaleIndex);
        }
        for(uint x; x < Amount; x++)
        {
            for(uint y; y < 11; y++)
            {
                IERC721(_IS._NFT).transferFrom (
                    _IS._Operator,        // `from`
                    msg.sender,           // `to`
                    _IS._CurrentIndex + y // `tokenID`
                );
            }
            SalesInternal[SaleIndex]._CurrentIndex = SalesInternal[SaleIndex]._CurrentIndex + 11;
        }
        emit Purchased(msg.sender, Amount, msg.value, CurrentPurchaseValue, NewAmountSold);
    }

    /**
     * @dev Claims ETH Unspent During An Auction
     */
    function UnspendETH(uint SaleIndex) external nonReentrant
    {
        require(tx.origin == msg.sender, "DutchMarketplace: EOA Only");
        require(SalesInternal[SaleIndex]._ETHClaimsEnabled, "DutchMarketplace: During-Sale Claims Are Not Active For This Sale");
        uint Price = ViewCurrentPrice(SaleIndex);
        uint[] memory _UserOrderIndexes = UserInfo[SaleIndex][msg.sender]._UserOrderIndexes;
        for(uint ClaimIndex; ClaimIndex < _UserOrderIndexes.length; ClaimIndex++)
        {
            Order memory _Order = Orders[SaleIndex][_UserOrderIndexes[ClaimIndex]];
            if(!_Order._Claimed)
            {
                Orders[SaleIndex][_UserOrderIndexes[ClaimIndex]]._Claimed = true;
                require(msg.sender == _Order._Purchaser, "DutchMarketplace: Invalid State");
                (bool _ConfirmedRefund,) = _Order._Purchaser.call {
                    value: _Order._PurchaseValue - (Price * _Order._PurchaseAmount)
                } ("");
                require(_ConfirmedRefund, "DutchMarketplace: Order Refund Failed");
                emit RefundClaimed(SaleIndex, _UserOrderIndexes[ClaimIndex]);
            }
        }
    }

    /*------------------
     * ADMIN FUNCTIONS *
    -------------------*/

    /**
     * @dev Starts A Sale
     * note: The True Discount Amount Is 100 - _Sale._DiscountAmount
     * note: Ex. _DiscountAmount = 75 = 25% Discount
     * note: Simple = True = IERC721(NFT).transferFrom() Sale
     * note: Simple = False = Custom purchaseTo Logic (ArtBlocks Or Custom Mint Pass)
     */
    function __StartSale(
        Sale memory _Sale,
        InternalSale memory _State,
        bytes32[] calldata RootsEligibility,
        bytes32[] calldata RootsAmounts,
        uint[] calldata DiscountAmounts
    ) external onlyAdmin {
        require(!InitializedSale[_State._NFT], "DutchMarketplace: Sale Already Initiated With This NFT Address");
        InitializedSale[_State._NFT] = true;
        NFTAddressToSaleIndex[_State._NFT] = _TOTAL_UNIQUE_SALES_DUTCH;
        Sales[_TOTAL_UNIQUE_SALES_DUTCH] = _Sale;
        SalesInternal[_TOTAL_UNIQUE_SALES_DUTCH] = _State;
        SaleParams[_TOTAL_UNIQUE_SALES_DUTCH] = SaleParam(RootsEligibility, RootsAmounts, DiscountAmounts);
        require(RootsEligibility.length == DiscountAmounts.length, "DutchMarketplace: Invalid Merkle Root Length");
        for(uint x; x < SaleParams[_TOTAL_UNIQUE_SALES_DUTCH]._DiscountAmounts.length; x++)
        {
            require(DiscountAmounts[x] <= 100, "DutchMarketplace: Invalid Discount Amount");
        }
        require(Sales[_TOTAL_UNIQUE_SALES_DUTCH]._PriceStart >= Sales[_TOTAL_UNIQUE_SALES_DUTCH]._PriceEnd, "DutchMarketplace: Invalid Start And End Prices");
        emit SaleStarted(_TOTAL_UNIQUE_SALES_DUTCH);
        _TOTAL_UNIQUE_SALES_DUTCH++;
    }

    /**
     * @dev Initiates Withdraw Of Refunds & Sale Proceeds
     * note: This Is Only After The Sale Has Completed
     */
    function __InitiateRefundsAndProceeds(uint SaleIndex) external nonReentrant onlyAdmin 
    {
        bool _TxConfirmed;
        uint _Proceeds;
        uint _Refund;
        require(SaleState[SaleIndex]._FinalClearingPrice > 0, "DutchMarketplace: Final Clearing Price Not Seeded");
        Order memory _Order;
        for(uint OrderIndex = SaleState[SaleIndex]._CurrentRefundIndex; OrderIndex < SaleState[SaleIndex]._UniqueSales; OrderIndex++)
        {
            _Order = Orders[SaleIndex][OrderIndex];
            if(!_Order._Claimed)
            {
                if(!_Order._BrightListPurchase) // No BrightList
                {
                    _Refund = _Order._PurchaseValue - (SaleState[SaleIndex]._FinalClearingPrice * _Order._PurchaseAmount);
                    _Proceeds += _Order._PurchaseValue - _Refund;
                    (_TxConfirmed,) = _Order._Purchaser.call{ value: _Refund }(""); 
                }
                if(!_TxConfirmed) { emit OrderRefundFailed(SaleIndex, OrderIndex); }
                Orders[SaleIndex][OrderIndex]._Claimed = true;
            }
        }
        (_TxConfirmed,) = _BRT_MULTISIG.call{ value: _Proceeds }(""); 
        require(_TxConfirmed, "DutchMarketplace: Multisig Refund Failed, Use Failsafe Withdraw And Manually Process");
        SaleState[SaleIndex]._CurrentRefundIndex = SaleState[SaleIndex]._UniqueSales; // Resets Refund Index
    }

    /*--------------*/
    /*  ONLY OWNER  */
    /*--------------*/

    /**
     * @dev Modifies The Sale State `Simple` Status
     * note: Simple = True = IERC721(NFT).transferFrom() Sale
     * note: Simple = False = IMINTER(NFT).purchaseTo(NFT, (ProjectID || Amt)) Sale
     */
    function ___ModifySaleSimpleState(uint SaleIndex, bool State) external onlyOwner
    {
        SalesInternal[SaleIndex]._Simple = State;
    }

    /**
     * @dev Modifies The Sale Starting Token Index
     * note: If `Simple` Sale, Then This Is The Current TokenID Being Transferred In The Sale
     */
    function ___ModifySaleStartingTokenIndex(uint SaleIndex, uint StartingTokenID) external onlyOwner
    {
        SalesInternal[SaleIndex]._CurrentIndex = StartingTokenID;
    }

    /**
     * @dev Modifies The Sale Name
     */
    function ___ModifySaleName(uint SaleIndex, string calldata Name) external onlyOwner
    {
        Sales[SaleIndex]._Name = Name;
    }

    /**
     * @dev Modifies The ArtBlocks Sale ProjectID (if applicable)
     */
    function ___ModifySaleProjectID(uint SaleIndex, uint ProjectID) external onlyOwner
    {
        Sales[SaleIndex]._ProjectID = ProjectID;
    }

    /**
     * @dev Modifies The Starting Price
     */
    function ___ModifyPriceStart(uint SaleIndex, uint PriceStart) external onlyOwner
    {
        Sales[SaleIndex]._PriceStart = PriceStart;
    }

    /**
     * @dev Modifies The Ending Price
     */
    function ___ModifyPriceEnd(uint SaleIndex, uint PriceEnd) external onlyOwner
    {
        Sales[SaleIndex]._PriceEnd = PriceEnd;
    }

    /**
     * @dev Modifies The Per-Wallet-Limiter
     */
    function ___ModifyWalletLimiter(uint SaleIndex, uint WalletLimiter) external onlyOwner
    {
        Sales[SaleIndex]._WalletLimiter = WalletLimiter;
    }

    /**
     * @dev Modifies The Maximum NFTs For Sale
     */
    function ___ModifyMaxForSale(uint SaleIndex, uint AmountForSale) external onlyOwner
    {
        Sales[SaleIndex]._MaximumAvailableForSale = AmountForSale;
    }

    /**
     * @dev Modifies The Starting Unix Timestamp
     */
    function ___ModifyTimestampStart(uint SaleIndex, uint Timestamp) external onlyOwner
    {
        Sales[SaleIndex]._StartingBlockUnixTimestamp = Timestamp;
    }

    /**
     * @dev Modifies The Price Decay (Input In Seconds)
     */
    function ___ModifyPriceDecay(uint SaleIndex, uint PriceDecayInSeconds) external onlyOwner
    {
        Sales[SaleIndex]._SecondsBetweenPriceDecay = PriceDecayInSeconds;
    }


    /**
     * @dev Modifies The Sale Discount Amount
     * note: Ex. The True Discount Amount = 100 - `DiscountAmount`
     * note: Ex. `DiscountAmount` = 75 | 100 - `DiscountAmount` = 25% Discount
     */
    function ___ModifySaleDiscountAmount(uint SaleIndex, uint[] calldata DiscountAmounts) external onlyOwner
    {
        for(uint x; x < DiscountAmounts.length; x++)
        {
            require(DiscountAmounts[x] <= 100, "DutchMarketplace: Invalid Discount Amount");
            SaleParams[SaleIndex]._DiscountAmounts[x] = DiscountAmounts[x];
        }
    }

    /**
     * @dev Modifies The NFT Address Of A Sale
     */
    function ___ModifySaleNFTAddress(uint SaleIndex, address NFT) external onlyOwner
    {
        SalesInternal[SaleIndex]._NFT = NFT;
    }

    /**
     * @dev Modifies The Final Clearing Price Of A Sale
     */
    function ___ModifySaleClearingPrice(uint SaleIndex, uint ClearingPrice) external onlyOwner
    {
        SaleState[SaleIndex]._FinalClearingPrice = ClearingPrice;
    }

    /**
     * @dev Modifies The Public Active Sale State
     */
    function ___ModifySaleStatePublic(uint SaleIndex, bool State) external onlyOwner
    {
        SalesInternal[SaleIndex]._ActivePublic = State;
    }

    /**
     * @dev Modifies The BrightList Active Sale State
     */
    function ___ModifySaleStateBrightList(uint SaleIndex, bool State) external onlyOwner
    {
        SalesInternal[SaleIndex]._ActiveBrightList = State;
    }

    /**
     * @dev Modifies The State Of ETH Claims
     * note: This Enables Users To Claim ETH Rebate Pending In The Contract Before The Sale Concludes
     */
    function ___ModifySaleETHClaimsEnabled(uint SaleIndex, bool State) external onlyOwner
    {
        SalesInternal[SaleIndex]._ETHClaimsEnabled = State;
    }

    /**
     * @dev Modifies The Merkle Root
     */
    function ___ModifySaleRoot(uint SaleIndex, uint Priority, bytes32 Root) external onlyOwner
    {
        SaleParams[SaleIndex]._Roots[Priority] = Root;
    }

    /**
     * @dev Modifies The Merkle Root For A Priority Max Amount
     */
    function ___ModifySaleRootAmount(uint SaleIndex, uint Priority, bytes32 Root) external onlyOwner
    {
        SaleParams[SaleIndex]._RootsAmounts[Priority] = Root;
    }

    /**
     * @dev onlyOwner: Modifies Sale
     */
    function ___ModifySale(uint SaleIndex, Sale memory _Sale) external onlyOwner { Sales[SaleIndex] = _Sale; }

    /**
     * @dev Modifies The Sale Operator
     */
    function ___ModifySaleOperator(uint SaleIndex, address Operator) external onlyOwner { SalesInternal[SaleIndex]._Operator = Operator; }

    /**
     * @dev onlyOwner: Grants Admin Role
     */
    function ___AdminGrant(address _Admin) external onlyOwner { Admin[_Admin] = true; }

    /**
     * @dev onlyOwner: Removes Admin Role
     */
    function ___AdminRemove(address _Admin) external onlyOwner { Admin[_Admin] = false; }

    /**
     * @dev onlyOwner: Withdraws All Ether From The Contract
     */
    function ___WithdrawEther() external onlyOwner { payable(msg.sender).transfer(address(this).balance); }

    /**
     * @dev onlyOwner: Withdraws Ether From Contract To Address With An Amount
     */
    function ___WithdrawEtherToAddress(address payable Recipient, uint Amount) external onlyOwner
    {
        require(Amount > 0 && Amount <= address(this).balance, "Invalid Amount");
        (bool Success, ) = Recipient.call{value: Amount}("");
        require(Success, "Unable to Withdraw, Recipient May Have Reverted");
    }

    /**
     * @dev Withdraws ERC721s From Contract
     */
    function ___WithdrawERC721(address Contract, address Recipient, uint[] calldata TokenIDs) external onlyOwner 
    { 
        for(uint TokenID; TokenID < TokenIDs.length;)
        {
            IERC721(Contract).transferFrom(address(this), Recipient, TokenIDs[TokenID]);
            unchecked { TokenID++; }
        }
    }

    /*-----------------
     * VIEW FUNCTIONS *
    ------------------*/

    /**
     * @dev Returns Sale Information For A Given Wallet At `SaleIndex`
     * @param SaleIndex        | The Sale Index
     * @param Wallet           | The Currently Connected Wallet
     * @param DN               | The Delegation Index
     * @param ProofEligibility | The Proof For The BrightList
     * @param ProofAmount      | The Proof For The MaxAmount
     */
    function ViewWalletSaleInformation(
        uint SaleIndex,
        address Wallet,
        uint DN,
        uint MaxAmount,
        bytes32[] calldata ProofEligibility,
        bytes32[] calldata ProofAmount
    ) external view returns (_UserSaleInformation memory) {
        uint CurrentPrice = ViewCurrentPrice(SaleIndex);
        uint Priority;
        bool Verified;
        bool VerifiedAmount;
        bool Active = SalesInternal[SaleIndex]._ActiveBrightList || SalesInternal[SaleIndex]._ActivePublic;
        if(DN != 69420) { Wallet = IDelegationRegistry(_DR).getDelegationsByDelegate(Wallet)[DN].vault; }
        uint AmountPurchased = MaxAmount - UserInfo[SaleIndex][Wallet]._PurchasedAmount; // The User's Remaining Purchase Allocation
        (Verified, Priority) = ViewBrightListStatus(SaleIndex, Wallet, ProofEligibility);
        if(Verified) // If The User Is Eligible & Passed A Valid MaxAmount   
        { 
            VerifiedAmount = VerifyAmount(Wallet, MaxAmount, SaleParams[SaleIndex]._RootsAmounts[Priority], ProofAmount);
        }
        return(
            _UserSaleInformation(
                UserInfo[SaleIndex][Wallet]._UserOrderIndexes,                                // The User's Order Indexes
                UserInfo[SaleIndex][Wallet]._PurchasedAmount,                                 // The User's Total Purchase Amount For `SaleIndex`
                AmountPurchased,                                                              
                UserInfo[SaleIndex][Wallet]._ClaimIndex,                                      // The User's Claim Index
                Sales[SaleIndex]._MaximumAvailableForSale - SaleState[SaleIndex]._AmountSold, // The Remaining Amount Available For Sale
                CurrentPrice,                                                                 // The Current Price Of A Sale
                Priority,                                                                     // Which Priority The User Is Eligible For
                Verified,                                                                     // If The User Is Eligible For BrightList
                VerifiedAmount,                                                               // If The User Is Eligible For The MaxAmount
                Active                                                                         // If The Sale Is Ended
            )
        );
    }

    /**
     * @dev Returns All Orders Of `SaleIndex` Within A Range `StartingIndex` & `EndingIndex` Inclusive
     */
    function ViewOrders(uint SaleIndex) external view returns (Order[] memory) { return Orders[SaleIndex]; }

    /**
     * @dev Returns All Orders Of `SaleIndex` Within A Range `StartingIndex` & `EndingIndex` Inclusive
     */
    function ViewOrdersInRange(uint SaleIndex, uint StartingIndex, uint EndingIndex) external view returns (Order[] memory) 
    { 
        uint Range = EndingIndex - StartingIndex;
        Order[] memory _Orders = new Order[](Range);
        for(uint x; x < Range; x++) { _Orders[x] = Orders[SaleIndex][StartingIndex+x]; }
        return _Orders; 
    }

    /**
     * @dev Returns A [][] Of All Orders On Multiple SaleIndexes Within A Range `StartingIndex` & `EndingIndex` Inclusive
     */
    function ViewAllOrders(uint[] calldata SaleIndexes, uint StartingIndex, uint EndingIndex) external view returns (Order[][] memory)
    {
        Order[][] memory __Orders = new Order[][](EndingIndex-StartingIndex);
        for(uint SaleIndex; SaleIndex <= SaleIndexes.length; SaleIndex++) { __Orders[SaleIndex] = Orders[SaleIndex]; }
        return __Orders;
    }

    /**
     * @dev Returns Sale Index By NFT Contract Address
     */
    function ViewSaleIndexByNFTAddress(address NFT) public view returns (uint)
    {
        
        uint SaleIndex = NFTAddressToSaleIndex[NFT];
        if(SaleIndex != 0) { return SaleIndex; }
        return 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff; // type(uint).max
    }

    /**
     * @dev Returns an [] Of Sale States
     */
    function ViewSaleStates(uint[] calldata SaleIndexes) public view returns (Sale[] memory, Info[] memory)
    {
        Sale[] memory _Sales = new Sale[](SaleIndexes.length);
        Info[] memory _Infos = new Info[](SaleIndexes.length);
        bool Active;
        for(uint x; x < SaleIndexes.length; x++) 
        { 
            Active = SalesInternal[SaleIndexes[x]]._ActivePublic || SalesInternal[SaleIndexes[x]]._ActiveBrightList;
            _Sales[x] = Sales[SaleIndexes[x]]; 
            _Infos[x] = Info(
                ViewCurrentPrice(SaleIndexes[x]),
                Sales[x]._MaximumAvailableForSale,
                Sales[x]._MaximumAvailableForSale - SaleState[SaleIndexes[x]]._AmountSold,
                Active
            );
        }
        return (_Sales, _Infos);
    }

    /**
     * @dev Returns An [] Of Internal Sale States
     */
    function ViewInternalSaleStates(uint[] calldata SaleIndexes) public view returns (InternalSale[] memory)
    {
        InternalSale[] memory _InternalSales = new InternalSale[](SaleIndexes.length);
        for(uint x; x < SaleIndexes.length; x++) { _InternalSales[x] = SalesInternal[SaleIndexes[x]]; }
        return _InternalSales;
    }

    /**
     * @dev Returns Current Dutch Price For Sale Index
     */
    function ViewCurrentPrice(uint SaleIndex) public view returns (uint Price)
    {
        if(block.timestamp <= Sales[SaleIndex]._StartingBlockUnixTimestamp) { return Sales[SaleIndex]._PriceStart; }  // Sale Not Started
        if(SaleState[SaleIndex]._FinalClearingPrice > 0) { return SaleState[SaleIndex]._FinalClearingPrice; } // Sale Finished
        uint CurrentPrice = Sales[SaleIndex]._PriceStart; // Initiates Current Price
        uint SecondsElapsed = block.timestamp - Sales[SaleIndex]._StartingBlockUnixTimestamp; // Unix Seconds Elapsed At Current Query Timestamp
        CurrentPrice >>= SecondsElapsed / Sales[SaleIndex]._SecondsBetweenPriceDecay; // Div/2 For Each Half Life Iterated Upon
        CurrentPrice -= (CurrentPrice * (SecondsElapsed % Sales[SaleIndex]._SecondsBetweenPriceDecay)) / Sales[SaleIndex]._SecondsBetweenPriceDecay / 2;
        if(CurrentPrice <= Sales[SaleIndex]._PriceEnd) { return Sales[SaleIndex]._PriceEnd; } // Sale Ended At Resting Band
        return CurrentPrice; // Sale Currently Active
    }

    /**
     * @dev Returns All Order Information Including Addresses And Corresponding Refund Amounts
     */
    function ViewAllOrderRefunds(uint SaleIndex) public view returns (address[] memory, uint[] memory)
    {
        address[] memory Addresses = new address[](SaleState[SaleIndex]._UniqueSales);
        uint[] memory Refunds = new uint[](SaleState[SaleIndex]._UniqueSales);
        uint[] memory DiscountAmounts = SaleParams[SaleIndex]._DiscountAmounts;
        uint CurrentPrice = ViewCurrentPrice(SaleIndex);
        Order memory _Order;
        for(uint OrderIndex; OrderIndex < SaleState[SaleIndex]._UniqueSales; OrderIndex++)
        {
            _Order = Orders[SaleIndex][OrderIndex];
            if(_Order._BrightListPurchase)
            {
                Refunds[OrderIndex] = _Order._PurchaseValue - (
                    ((SaleState[SaleIndex]._FinalClearingPrice * DiscountAmounts[_Order._Priority]) / 100) * _Order._PurchaseAmount
                );
            }
            else { Refunds[OrderIndex] = _Order._PurchaseValue - (CurrentPrice * _Order._PurchaseAmount); }
            Addresses[OrderIndex] = _Order._Purchaser;
        }
        return(Addresses, Refunds);
    }

    /**
     * @dev Returns All State Parameters Of A Sale
     */
    function ViewAllSaleInformation(uint SaleIndex) public view returns (Sale memory, InternalSale memory, MiscSale memory, SaleParam memory, uint Price) 
    {
        return ( Sales[SaleIndex], SalesInternal[SaleIndex], SaleState[SaleIndex], SaleParams[SaleIndex], ViewCurrentPrice(SaleIndex) );
    }

    /**
     * @dev Returns If User Is On BrightList
     * note: Returns BrightList Status & Best Priority Index
     */
    function ViewBrightListStatus(uint SaleIndex, address Recipient, bytes32[] calldata Proof) public view returns (bool, uint)
    {
        bool Verified;
        uint Amount = SaleParams[SaleIndex]._Roots.length;
        bytes32 Leaf = keccak256(abi.encodePacked(Recipient));
        for(uint PriorityIndex; PriorityIndex < Amount; PriorityIndex++) 
        { 
            Verified = MerkleProof.verify(Proof, SaleParams[SaleIndex]._Roots[PriorityIndex], Leaf); 
            if(Verified) { return (true, PriorityIndex); }
        }
        return (false, 69420);
    }

    /**
     * @dev Verifies Brightlist
     */
    function VerifyBrightList(address _Wallet, bytes32 _Root, bytes32[] calldata _Proof) public pure returns(bool)
    {
        bytes32 _Leaf = keccak256(abi.encodePacked(_Wallet));
        return MerkleProof.verify(_Proof, _Root, _Leaf);
    }

    /**
     * @dev Verifies Maximum Purchase Amount Being Passed Is Valid
     */
    function VerifyAmount(address _Wallet, uint _Amount, bytes32 _Root, bytes32[] calldata _Proof) public pure returns(bool)
    {
        bytes32 _Leaf = (keccak256(abi.encodePacked(_Wallet, _Amount)));
        return MerkleProof.verify(_Proof, _Root, _Leaf);
    }

    /*---------------------
     * INTERNAL FUNCTIONS *
    ----------------------*/

    /**
     * @dev Ends A Sale
     */
    function ___EndSale(uint SaleIndex) internal 
    { 
        SalesInternal[SaleIndex]._ActivePublic = false; 
        SalesInternal[SaleIndex]._ActiveBrightList = false;
    }

    /**
     * @dev Refunds `Recipient` ETH Amount `Value`
     */
    function __Refund(address Recipient, uint Value) internal
    {
        (bool Confirmed,) = Recipient.call{value: Value}(""); 
        require(Confirmed, "DutchMarketplace: Refund failed");
        emit Refunded(Value);
    }

    /*-----------
     * MODIFIER *
    ------------*/

    modifier onlyAdmin
    {
        require(Admin[msg.sender]);
        _;
    }
}

interface IERC20 { function approve(address From, address To, uint Amount) external; }
interface IERC721 
{ 
    function transferFrom(address From, address To, uint TokenID) external; 
    function purchaseTo(address _to, uint256 _projectId) external payable returns (uint256 _tokenId);
}
interface IDelegationRegistry
{
    enum DelegationType 
    {
        NONE,
        ALL,
        CONTRACT,
        TOKEN
    }

    struct DelegationInfo 
    {
        DelegationType type_;
        address vault;
        address delegate;
        address contract_;
        uint256 tokenId;
    }

    function getDelegationsByDelegate(address delegate) external view returns (DelegationInfo[] memory);
}