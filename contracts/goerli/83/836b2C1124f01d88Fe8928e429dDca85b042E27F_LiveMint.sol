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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
/**
 * @dev @brougkr
 */
pragma solidity 0.8.17;
interface IGT 
{ 
    /**
     * @dev { Golden Token Burn }
     */
    function _LiveMintBurn(uint TicketID) external returns (address Recipient); 
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
/**
 * @dev @brougkr
 */
pragma solidity 0.8.17;
interface IMP 
{ 
    /**
     * @dev { For Instances Where Golden Token Or Artists Have A Bespoke Mint Pass Contract }
     */
    function _LiveMintBurn(uint TicketID) external returns (address Recipient, uint ArtistID); 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
interface IPoly 
{ 
    // without delegate.cash
    function purchaseTo(
        address _to, 
        uint _projectId, 
        address _ownedNFTAddress, 
        uint _ownedNFTTokenID
    ) payable external returns (uint tokenID);
}

// SPDX-License-Identifier: MIT
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
import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IMinter } from "./IMinter.sol";
import { IMP } from "./IMP.sol";
import { IGT } from "./IGT.sol";
import { IPoly } from "./IPoly.sol";
contract LiveMint is Ownable, ReentrancyGuard
{  
    struct City
    {
        string _Name;         // _Name
        uint _QRCurrentIndex; // _QRCurrentIndex (Should be Always Be (333 * (City# % 7)) + 1000
        address _ERC20;       // _ERC20 
        bytes32 _Root;        // _Root
    }

    struct Artist
    {
        address _MintPass;        // _MintPass
        address _Minter;          // _Minter
        address _PolyptychSource; // _PolyptychSource
        uint _MaxSupply;          // _MaxSupply
        uint _MintPassProjectID;  // _MintPassProjectID
        uint _ArtBlocksProjectID; // _ArtBlocksProjectID 
        uint _PolyStart;          // _PolyStart
        uint _PolyEnd;            // _PolyEnd
    }

    struct User
    {
        bool _Eligible;   // _Eligible
        uint _Allocation; // _Allocation
    }

    /*-------------------*/
    /*  STATE VARIABLES  */
    /*-------------------*/

    bytes32 private constant _AUTHORIZED = keccak256("AUTHORIZED");                      // Authorized Role
    bytes32 private constant _MINTER_ROLE = keccak256("MINTER_ROLE");                    // Minter Role
    bytes32 private constant _ADMIN_ROLE = keccak256("ADMIN_ROLE");                      // Admin Role
    uint private constant ONE_MILLION = 1000000;                                         // One Million         
    address public _GOLDEN_TOKEN = 0x985e1932FFd2aA4bC9cE611DFe12816A248cD2cE;           // Golden Token Address
    address public _CITIZEN_MINTER = 0xDd06d8483868Cd0C5E69C24eEaA2A5F2bEaFd42b;         // ArtBlocks Minter Contract
    address public _BRT_MULTISIG = 0xB96E81f80b3AEEf65CB6d0E280b15FD5DBE71937;           // BRT Multisig
    address public _ERC20Factory;                                                        // ERC20 Factory
    address public _MintPassFactory;                                                     // MintPass Factory    
    uint public _CurrentCityIndex = 6;                                                   // Current City Index
    uint public _UniqueArtistsInvoked;                                                   // Unique Artists Invoked

    /*-------------------*/
    /*     MAPPINGS      */
    /*-------------------*/
    
    mapping(uint => Artist) public Artists;                              // [ArtistID] => Artist
    mapping(uint => City) public Cities;                                 // [CityIndex] => City Struct
    mapping(uint => mapping(address => bool)) public _QRRedeemed;        // [CityIndex][Wallet] => If User Has Redeemed QR
    mapping(uint => mapping(address => uint)) public _QRAllocation;      // [CityIndex][Wallet] => Wallet's QR Code Allocation
    mapping(uint => mapping(uint => address)) public _BrightListCitizen; // [CityIndex][TicketID] => Address Of CryptoCitizen Minting Recipient 
    mapping(uint => mapping(uint => address)) public _BrightListArtist;  // [ArtistID][TicketID] => Address Of Artist NFT Recipient
    mapping(uint => mapping(uint => string)) public _DataArtists;        // [ArtistID][TicketID] => Artist Data
    mapping(uint => mapping(uint => string)) public _DataCitizens;       // [CityIndex][TicketID] => Data For Golden Token Checkins
    mapping(uint => mapping(uint => uint)) public _MintedTokenIDCitizen; // [CityIndex][TicketID] => MintedTokenID
    mapping(uint => mapping(uint => uint)) public _MintedTokenIDArtist;  // [ArtistID][TicketID] => MintedTokenID
    mapping(uint => mapping(uint => bool)) public _MintedArtist;         // [ArtistID][TicketID] => If Minted
    mapping(uint => mapping(uint => bool)) public _MintedCitizen;        // [CityIndex][TicketID] => If Golden Ticket ID Has Minted Or Not
    mapping(address => bytes32) public Role;                             // [Wallet] => BRT Minter Role
    mapping(uint=>uint) public AmountRemaining;                          // [ArtistID] => Mints Remaining
    mapping(uint=>mapping(uint=>uint)) public _ArtBlocksProjectID;       // [ArtistID][TicketID] => ArtBlocksProjectID

    /*-------------------*/
    /*      EVENTS       */
    /*-------------------*/

    /**
     * @dev Emitted When `Redeemer` IRL-mints CryptoCitizen Corresponding To Their Redeemed `TicketID`.
     **/
    event LiveMintComplete(address indexed Redeemer, uint TicketID, uint TokenID, string Data);

    /**
     * @dev Emitted When `Redeemer` IRL-mints A Artist NFT Corresponding To Their Redeemed `TicketID`.
     */
    event LiveMintCompleteArtist(address Recipient, uint ArtistID, uint TicketID, uint MintedWorkTokenID);

    /**
     * @dev Emitted When An Artist Mint Pass Is Redeemed
     */
    event ArtistMintPassRedeemed(address Redeemer, uint ArtistIDs, uint TicketIDs, string Data, string Type);

    /**
     * @dev Emitted When `Redeemer` Redeems Golden Token Corresponding To `TicketID` 
     **/
    event GoldenTokenRedeemed(address indexed Redeemer, uint TicketID, string Data, string Type);

    /**
     * @dev Emitted When `Redeemer` Redeems Golden Token Corresponding To `TicketID` 
     **/
    event QRRedeemed(address indexed Redeemer, uint TicketID, string Data, string Type);
    
    /**
     * @dev Emitted When A Reservation Is Wiped
     */
    event ReservationWiped(uint TicketID, address Redeemer, string Data);

    /**
     * @dev Emitted When A Contract Is Authorized
     */
    event AuthorizedContract(address NewAddress);

    /**
     * @dev Emitted When A Contract Is Deauthorized
     */
    event DeauthorizedContract(address NewAddress);


    /*-------------------*/
    /*    CONSTRUCTOR    */
    /*-------------------*/

    constructor()
    { 
        Cities[0]._Name = "CryptoGalacticans"; 
        Cities[1]._Name = "CryptoVenetians";
        Cities[2]._Name = "CryptoNewYorkers";
        Cities[3]._Name = "CryptoBerliners";
        Cities[4]._Name = "CryptoLondoners";
        Cities[5]._Name = "CryptoMexas";
        Cities[6]._Name = "CryptoTokyites";
        Cities[7]._Name = "CryptoCitizen City #8";
        Cities[8]._Name = "CryptoCitizen City #9";
        Cities[9]._Name = "CryptoCitizen City #10";
        Role[0xe06F5FAE754e81Bc050215fF89B03d9e9FF20700] = _ADMIN_ROLE;  // `operator.brightmoments.eth`
        Role[0x1A0a3E3AE390a0710f8A6d00587082273eA8F6C9] = _MINTER_ROLE; // BRT Minter #1
        Role[0x4d8013b0c264034CBf22De9DF33e22f58D52F207] = _MINTER_ROLE; // BRT Minter #2
        Role[0x4D9A8CF2fE52b8D49C7F7EAA87b2886c2bCB4160] = _MINTER_ROLE; // BRT Minter #3
        Role[0x124fd966A0D83aA020D3C54AE2c9f4800b46F460] = _MINTER_ROLE; // BRT Minter #4
        Role[0x100469feA90Ac1Fe1073E1B2b5c020A8413635c4] = _MINTER_ROLE; // BRT Minter #5
        Role[0x756De4236373fd17652b377315954ca327412bBA] = _MINTER_ROLE; // BRT Minter #6
        Role[0xc5Dfba6ef7803665C1BDE478B51Bd7eB257A2Cb9] = _MINTER_ROLE; // BRT Minter #7
        Role[0xFBF32b29Bcf8fEe32d43a4Bfd3e7249daec457C0] = _MINTER_ROLE; // BRT Minter #8
        Role[0xF2A15A83DEE7f03C70936449037d65a1C100FF27] = _MINTER_ROLE; // BRT Minter #9
        Role[0x1D2BAB965a4bB72f177Cd641C7BacF3d8257230D] = _MINTER_ROLE; // BRT Minter #10
        Role[0x2e51E8b950D72BDf003b58E357C2BA28FB77c7fB] = _MINTER_ROLE; // BRT Minter #11
        Role[0x8a7186dECb91Da854090be8226222eA42c5eeCb6] = _MINTER_ROLE; // BRT Minter #12
        Role[0x7603C5eed8e57Ad795ec5F0081eFB21d1eEBf937] = _MINTER_ROLE; // BRT Minter #13
        Role[msg.sender] = _AUTHORIZED; // `operator.brightmoments.eth`
        Role[0xe06F5FAE754e81Bc050215fF89B03d9e9FF20700] = _AUTHORIZED;
    }

    /*-------------------*/
    /*  PUBLIC FUNCTIONS */
    /*-------------------*/

    /**
     * @dev Redeems Golden Tokens & BrightLists Address To Receive CryptoCitizen
     **/
    function RedeemGT (
        uint[] calldata TicketIDs, 
        string[] calldata Data,
        string[] calldata Type
    ) external nonReentrant {
        address Recipient;
        for(uint x; x < TicketIDs.length; x++)
        {
            require(
                IERC721(_GOLDEN_TOKEN).ownerOf(TicketIDs[x]) == msg.sender, 
                "LiveMint: Sender Does Not Own Token With The Input Token ID"
            );
            Recipient = IGT(_GOLDEN_TOKEN)._LiveMintBurn(TicketIDs[x]);
            require(Recipient == msg.sender, "LiveMint: Recipient Must Be Valid Owner");
            _BrightListCitizen[_CurrentCityIndex][TicketIDs[x]] = msg.sender;
            _DataCitizens[_CurrentCityIndex][TicketIDs[x]] = Data[x];
            emit GoldenTokenRedeemed(msg.sender, TicketIDs[x], Data[x], Type[x]);
        }
    }

    /**
     * @dev Redeems Artist Mint Pass & BrightLists Address To Receive A NFT
     **/
    function RedeemAP (
        uint[] calldata ArtistIDs,
        uint[] calldata TicketIDs, 
        string[] calldata Data,
        string[] calldata Type
    ) external nonReentrant {
        address Recipient;
        uint ArtBlocksProjectID;
        uint Start;
        uint MaxSupply;
        uint End;
        uint CurrentTicketID;
        for(uint ArtistID; ArtistID < ArtistIDs.length; ArtistID++)
        {
            Start = Artists[ArtistIDs[ArtistID]]._MintPassProjectID * ONE_MILLION;
            MaxSupply = Artists[ArtistIDs[ArtistID]]._MaxSupply;
            End = Start + MaxSupply;
            for(uint TicketID; TicketID < TicketIDs.length; TicketID++)
            {
                CurrentTicketID = TicketIDs[TicketID];
                require(
                    CurrentTicketID >= Start && CurrentTicketID < End,
                    "LiveMint: Ticket ID Is Not Valid For The Input Artist ID"
                );
                require(
                    IERC721(_MintPassFactory).ownerOf(CurrentTicketID) == msg.sender, 
                    "LiveMint: Sender Does Not Own Token With The Input Token ID"
                );
                require(
                    _BrightListArtist[ArtistIDs[ArtistID]][CurrentTicketID] == address(0),
                    "LiveMint: Address Cannot Be Overwritten"
                );
                (Recipient, ArtBlocksProjectID) = IMP(_MintPassFactory)._LiveMintBurn(CurrentTicketID);
                _BrightListArtist[ArtistIDs[ArtistID]][CurrentTicketID] = Recipient;
                _ArtBlocksProjectID[ArtistIDs[ArtistID]][CurrentTicketID] = ArtBlocksProjectID;
                _DataArtists[ArtistIDs[ArtistID]][CurrentTicketID] = Data[TicketID];
                emit ArtistMintPassRedeemed(Recipient, ArtistIDs[ArtistID], CurrentTicketID, Data[TicketID], Type[TicketID]);
            }
        }
    } 
    
    /**
     * @dev Redeems Spot For IRL Minting
     */
    function RedeemQR(string calldata Data, string calldata Type, bytes32[] calldata Proof) external nonReentrant 
    {
        require(readQREligibility(msg.sender, Proof), "LiveMint: User Is Not Eligible To Redeem QR");
        if(_QRAllocation[_CurrentCityIndex][msg.sender] == 0) // User Is Able To Redeem Explicitly 1 QR Code
        {
            require(!_QRRedeemed[_CurrentCityIndex][msg.sender], "LiveMint: User Has Already Redeemed");
            _DataCitizens[_CurrentCityIndex][Cities[_CurrentCityIndex]._QRCurrentIndex] = Data;
            _BrightListCitizen[_CurrentCityIndex][Cities[_CurrentCityIndex]._QRCurrentIndex] = msg.sender;
            emit QRRedeemed(msg.sender, Cities[_CurrentCityIndex]._QRCurrentIndex, Data, Type);
            Cities[_CurrentCityIndex]._QRCurrentIndex++; 
        }
        else // User Is Able To Redeem More Than 1 QR Code Because Their Integer Allocation > 0
        {
            uint _Allocation = _QRAllocation[_CurrentCityIndex][msg.sender];
            uint _CurrentQR = Cities[_CurrentCityIndex]._QRCurrentIndex;
            uint _Limit = _Allocation + _CurrentQR;
            _QRAllocation[_CurrentCityIndex][msg.sender] = 0;
            Cities[_CurrentCityIndex]._QRCurrentIndex = _Limit;
            for(_CurrentQR; _CurrentQR < _Limit; _CurrentQR++)
            {
                _DataCitizens[_CurrentCityIndex][_CurrentQR] = Data;
                _BrightListCitizen[_CurrentCityIndex][_CurrentQR] = msg.sender;
                emit QRRedeemed(msg.sender, _CurrentQR, Data, Type);
            }
        }
        _QRRedeemed[_CurrentCityIndex][msg.sender] = true;
    }

    /*--------------------*/
    /*    LIVE MINTING    */
    /*--------------------*/

    /**
     * @dev Batch Mints Verified Users On The Brightlist CryptoCitizens
     * note: { For CryptoCitizen Cities }
     */
    function _LiveMintCitizen(uint[] calldata TicketIDs) external onlyMinter
    {
        address Recipient;
        uint MintedWorkTokenID;
        for(uint TicketID; TicketID < TicketIDs.length; TicketID++)
        {
            require(!_MintedCitizen[_CurrentCityIndex][TicketIDs[TicketID]], "LiveMint: Golden Token Already Minted");
            if(_BrightListCitizen[_CurrentCityIndex][TicketIDs[TicketID]] != address(0))
            {
                Recipient = _BrightListCitizen[_CurrentCityIndex][TicketIDs[TicketID]];
            }
            else { Recipient = IGT(_GOLDEN_TOKEN)._LiveMintBurn(TicketIDs[TicketID]); }
            require(Recipient != address(0), "LiveMint: Invalid Recipient");
            _MintedCitizen[_CurrentCityIndex][TicketIDs[TicketID]] = true;
            MintedWorkTokenID = IMinter(_CITIZEN_MINTER).purchaseTo(Recipient, _CurrentCityIndex);
            _MintedTokenIDCitizen[_CurrentCityIndex][TicketIDs[TicketID]] = MintedWorkTokenID;
            emit LiveMintComplete(Recipient, TicketIDs[TicketID], MintedWorkTokenID, _DataCitizens[_CurrentCityIndex][TicketIDs[TicketID]]); 
        }
    }

    /**
     * @dev Burns Artist Mint Pass In Exchange For The Minted Work
     * note: { For Instances Where Multiple Artists Share The Same Mint Pass & Return (Recipient, ArtBlocksProjectID) }
     */
    function _LiveMintArtist(uint ArtistID, uint[] calldata TicketIDs) external onlyMinter
    {
        address Recipient;
        address MintPass = Artists[ArtistID]._MintPass;
        address Minter = Artists[ArtistID]._Minter;
        uint ArtBlocksProjectID;
        uint MintedWorkTokenID;
        uint TicketID;
        uint Start = Artists[ArtistID]._MintPassProjectID * ONE_MILLION;
        uint MaxSupply = Artists[ArtistID]._MaxSupply;
        uint End = Start + MaxSupply;
        require(AmountRemaining[ArtistID] > 0, "LiveMint: ArtistID Mint Limit Reached");
        require(TicketIDs.length <= AmountRemaining[ArtistID], "LiveMint: TicketID Length Exceeds ArtistID Mint Limit");
        AmountRemaining[ArtistID] = AmountRemaining[ArtistID] - TicketIDs.length;
        for(uint x; x < TicketIDs.length; x++)
        {
            TicketID = TicketIDs[x];
            require(TicketID >= Start && TicketID < End, "LiveMint: Ticket ID Is Not Valid For The Input Artist ID");
            require(!_MintedArtist[ArtistID][TicketID], "LiveMint: Artist Mint Pass Already Minted");
            _MintedArtist[ArtistID][TicketID] = true;
            if(_BrightListArtist[ArtistID][TicketID] == address(0))
            {
                (Recipient, ArtBlocksProjectID) = IMP(MintPass)._LiveMintBurn(TicketID);
            }
            else
            {
                Recipient = _BrightListArtist[ArtistID][TicketID];
                ArtBlocksProjectID = _ArtBlocksProjectID[ArtistID][TicketID];
            }
            MintedWorkTokenID = IMinter(Minter).purchaseTo(Recipient, ArtBlocksProjectID);
            _MintedTokenIDArtist[ArtistID][TicketID] = MintedWorkTokenID;
            emit LiveMintCompleteArtist(Recipient, ArtistID, TicketID, MintedWorkTokenID);
        }
    }

    /**
     * @dev Batch Mints Artists With ArtBlocks Polyptych Minter
     */
    function _LiveMintArtistPoly(uint ArtistID, uint[] calldata TicketIDs) external onlyMinter
    {
        address Source = Artists[ArtistID]._PolyptychSource;
        address Minter = Artists[ArtistID]._Minter;
        uint ArtBlocksProjectID = Artists[ArtistID]._ArtBlocksProjectID;
        uint PolyStart = Artists[ArtistID]._PolyStart;
        uint PolyEnd = Artists[ArtistID]._PolyEnd;
        require(Source != address(0), "LiveMint: Invalid Minter Setup");
        require(AmountRemaining[ArtistID] > 0, "LiveMint: ArtistID Mint Limit Reached");
        require(TicketIDs.length <= AmountRemaining[ArtistID], "LiveMint: TicketID [] Length Exceeds ArtistID Mint Limit");
        address Recipient;
        uint MintedWorkTokenID;
        uint TicketID;
        AmountRemaining[ArtistID] = AmountRemaining[ArtistID] - TicketIDs.length;
        for(uint x; x < TicketIDs.length; x++)
        {
            TicketID = TicketIDs[x];
            require(!_MintedArtist[ArtistID][TicketID], "LiveMint: Input TicketID Already Minted");
            _MintedArtist[ArtistID][TicketID] = true;
            require(TicketID >= PolyStart && TicketID <= PolyEnd, "LiveMint: Input TicketID Is Not Valid For The Input Artist ID");
            Recipient = IERC721(Source).ownerOf(TicketID);
            require(Recipient != address(0), "LiveMint: Invalid Recipient");
            MintedWorkTokenID = IPoly(Minter).purchaseTo(Recipient, ArtBlocksProjectID, Source, TicketID);
            _MintedTokenIDArtist[ArtistID][TicketID] = MintedWorkTokenID;
            emit LiveMintCompleteArtist(Recipient, ArtistID, TicketID, MintedWorkTokenID);
        }
    }

    /*-------------------*/
    /*  OWNER FUNCTIONS  */
    /*-------------------*/

    /**
     * @dev Grants Address BRT Minter Role
     **/
    function __AddMinter(address Minter) external onlyOwner { Role[Minter] = _MINTER_ROLE; }
    
    /**
     * @dev Deactivates Address From BRT Minter Role
     **/
    function __RemoveMinter(address Minter) external onlyOwner { Role[Minter] = 0x0; }

    /**
     * @dev Changes The Mint Pass Factory Contract Address
     */
    function __ChangeMintPassFactory(address Contract) external onlyOwner { _MintPassFactory = Contract; }

    /**
     * @dev Changes Mint Pass Address For Artist LiveMints
     */
    function __ChangeMintPass(uint ProjectID, address Contract) external onlyOwner { Artists[ProjectID]._MintPass = Contract; }

    /**
     * @dev Changes Merkle Root For Citizen LiveMints
     */
    function __ChangeRootCitizen(bytes32 NewRoot) external onlyOwner { Cities[_CurrentCityIndex]._Root = NewRoot; }

    /**
     * @dev Overwrites QR Allocation
     */
    function __QRAllocationsOverwrite(address[] calldata Addresses, uint[] calldata Amounts) external onlyOwner
    {
        require(Addresses.length == Amounts.length, "LiveMint: Input Arrays Must Match");
        for(uint x; x < Addresses.length; x++) { _QRAllocation[_CurrentCityIndex][Addresses[x]] = Amounts[x]; }
    }

    /**
     * @dev Increments QR Allocations
     */
    function __QRAllocationsIncrement(address[] calldata Addresses, uint[] calldata Amounts) external onlyOwner
    {
        require(Addresses.length == Amounts.length, "LiveMint: Input Arrays Must Match");
        for(uint x; x < Addresses.length; x++) { _QRAllocation[_CurrentCityIndex][Addresses[x]] += Amounts[x]; }
    }

    /**
     * @dev Mints To Multisig
     */
    function __QRAllocationsSetNoShow(uint[] calldata TicketIDs) external onlyOwner
    {
        for(uint TicketIndex; TicketIndex < TicketIDs.length; TicketIndex++)
        {
            require(!_MintedCitizen[_CurrentCityIndex][TicketIDs[TicketIndex]], "LiveMint: Ticket ID Already Minted");
            _BrightListCitizen[_CurrentCityIndex][TicketIDs[TicketIndex]] = _BRT_MULTISIG;
        }
    }

    /**
     * @dev Changes ArtBlocks CryptoCitizen Minter Address
     */
    function __ChangeArtBlocksMinterCitizens(address ContractAddress) external onlyOwner { _CITIZEN_MINTER = ContractAddress; }

    /**
     * @dev Changes Multisig Address
     */
    function __ChangeMultisigAddress(address Recipient) external onlyOwner { _BRT_MULTISIG = Recipient; }

    /**
     * @dev Changes QR Current Index
     */
    function __ChangeQRIndex(uint NewIndex) external onlyOwner { Cities[_CurrentCityIndex]._QRCurrentIndex = NewIndex; }

    /**
     * @dev Batch Approves BRT For Purchasing
     */
    function __BatchApproveERC20(address[] calldata ERC20s, address[] calldata Operators) external onlyOwner
    {
        require(ERC20s.length == Operators.length, "LiveMint: Arrays Must Be Equal Length");
        for(uint x; x < ERC20s.length; x++) { IERC20(ERC20s[x]).approve(Operators[x], 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff); }
    }

    /**
     * @dev Instantiates New City
     * note: CityIndex Always Corresponds To ArtBlocks ProjectID
     */
    function __NewCity (
        string calldata Name,
        uint CityIndex,
        uint QRIndex,
        address ERC20
    ) external onlyOwner {
        Cities[CityIndex] = City(
            Name,
            QRIndex,
            ERC20,
            0x6942069420694206942069420694206942069420694206942069420694206942
        );
    }

    /**
     * @dev Overrides An Artist
     */
    function __OverrideArtist(uint ArtistID, Artist memory NewArtist) external onlyOwner { Artists[ArtistID] = NewArtist; }

    /**
     * @dev Instantiates A New City
     */
    function __NewCityStruct(uint CityIndex, City memory NewCity) external onlyOwner { Cities[CityIndex] = NewCity; }

    /**
     * @dev Returns An Artist Struct
     */
    function __NewArtistStruct(uint ArtistID, Artist memory NewArtist) external onlyOwner { Artists[ArtistID] = NewArtist; }

    /**
     * @dev Changes The Minter Address For An Artist
     */
    function __NewArtistMinter(uint ArtistID, address Minter) external onlyOwner { Artists[ArtistID]._Minter = Minter; }

    /**
     * @dev Withdraws Any Ether Mistakenly Sent to Contract to Multisig
     **/
    function __WithdrawEther() external onlyOwner { payable(msg.sender).transfer(address(this).balance); }

    /**
     * @dev Withdraws ERC20 Tokens to Multisig
     **/
    function __WithdrawERC20(address TokenAddress) external onlyOwner 
    { 
        IERC20 erc20Token = IERC20(TokenAddress);
        uint balance = erc20Token.balanceOf(address(this));
        require(balance > 0, "0 ERC20 Balance At `TokenAddress`");
        erc20Token.transfer(msg.sender, balance);
    }

    /**
     * @dev Withdraws Any NFT Mistakenly Sent To This Contract.
     */
    function __WithdrawERC721(address ContractAddress, address Recipient, uint TokenID) external onlyOwner
    {
        IERC721(ContractAddress).transferFrom(address(this), Recipient, TokenID);
    }

    /**
     * @dev Authorizes A Contract To Mint
     */
    function ____AuthorizeContract(address NewAddress) external onlyOwner 
    { 
        Role[NewAddress] = _AUTHORIZED; 
        emit AuthorizedContract(NewAddress);
    }

    /**
     * @dev Deauthorizes A Contract From Minting
     */
    function ___DeauthorizeContract(address NewAddress) external onlyOwner 
    { 
        Role[NewAddress] = 0x0; 
        emit DeauthorizedContract(NewAddress);
    }
    
    /*-------------------*/
    /*    PUBLIC VIEW    */
    /*-------------------*/

    /**
     * @dev Returns If User Is Eligible To Redeem QR Code
     */
    function readEligibility(address Recipient, bytes32[] memory Proof) public view returns(User memory)
    {
        bool Eligible = readQREligibility(Recipient, Proof);
        uint Allocation;
        if(Eligible && _QRAllocation[_CurrentCityIndex][Recipient] > 0) { Allocation = _QRAllocation[_CurrentCityIndex][Recipient]; }
        return User(Eligible, Allocation);
    }

    /**
     * @dev Returns If User Is Eligible To Redeem QR Code
     */
    function readQREligibility(address Recipient, bytes32[] memory Proof) public view returns(bool)
    {
        bytes32 Leaf = keccak256(abi.encodePacked(Recipient));
        bool BrightListEligible = MerkleProof.verify(Proof, Cities[_CurrentCityIndex]._Root, Leaf);
        if(
            (BrightListEligible && !_QRRedeemed[_CurrentCityIndex][Recipient])
            || 
            (BrightListEligible && _QRAllocation[_CurrentCityIndex][Recipient] > 0)
            
        ) { return true; }
        else { return false; }
    }

    /**
     * @dev Returns An Array Of Unminted Golden Tokens
     */
    function readCitizenUnmintedTicketIDs() public view returns(uint[] memory)
    {
        uint[] memory UnmintedTokenIDs = new uint[](1000);
        uint Counter;
        uint CityIDBuffer = _CurrentCityIndex % 7 * 1000;
        for(uint TokenID; TokenID < 1000; TokenID++)
        {
            uint _TokenID = TokenID + CityIDBuffer;
            if(
                !_MintedCitizen[_CurrentCityIndex][_TokenID]
                &&
                _BrightListCitizen[_CurrentCityIndex][_TokenID] != address(0)
            ) 
            { 
                UnmintedTokenIDs[Counter] = _TokenID; 
                Counter++;
            }
        }
        uint[] memory FormattedUnMintedTokenIDs = new uint[](Counter);
        uint Found;
        for(uint FormattedTokenID; FormattedTokenID < Counter; FormattedTokenID++)
        {
            if(UnmintedTokenIDs[FormattedTokenID] != 0 || (UnmintedTokenIDs[FormattedTokenID] == 0 && FormattedTokenID == 0))
            {
                FormattedUnMintedTokenIDs[Found] = UnmintedTokenIDs[FormattedTokenID];
                Found++;
            }
        }
        return FormattedUnMintedTokenIDs;
    }

    /**
     * @dev Returns An Array Of Unminted Golden Tokens
     */
    function readCitizenMintedTicketIDs(uint CityID) public view returns(uint[] memory)
    {
        uint[] memory MintedTokenIDs = new uint[](1000);
        uint Counter;
        uint CityIDBuffer = (CityID % 7) * 1000;
        uint _TicketID;
        for(uint TicketID; TicketID < 1000; TicketID++)
        {
            _TicketID = TicketID + CityIDBuffer;
            if(_MintedCitizen[CityID][_TicketID]) 
            { 
                MintedTokenIDs[Counter] = _TicketID; 
                Counter++;
            }
        }
        uint[] memory FormattedMintedTokenIDs = new uint[](Counter);
        uint Found;
        for(uint FormattedTokenID; FormattedTokenID < Counter; FormattedTokenID++)
        {
            if(MintedTokenIDs[FormattedTokenID] != 0 || (MintedTokenIDs[FormattedTokenID] == 0 && FormattedTokenID == 0))
            {
                FormattedMintedTokenIDs[Found] = MintedTokenIDs[FormattedTokenID];
                Found++;
            }
        }
        return FormattedMintedTokenIDs;
    }

    /**
     * @dev Returns A 2d Array Of Checked In & Unminted TicketIDs Awaiting A Mint
     */
    function readCitizenCheckedInTicketIDs() public view returns(uint[] memory TokenIDs)
    {
        uint[] memory _TokenIDs = new uint[](1000);
        uint CityIDBuffer = (_CurrentCityIndex % 7) * 1000;
        uint _TicketID;
        uint Counter;
        for(uint TicketID; TicketID < 1000; TicketID++)
        {
            _TicketID = TicketID + CityIDBuffer;
            if(
                !_MintedCitizen[_CurrentCityIndex][_TicketID]
                &&
                _BrightListCitizen[_CurrentCityIndex][_TicketID] != address(0)
            ) 
            { 
                _TokenIDs[Counter] = _TicketID; 
                Counter++;
            }
        }
        uint[] memory FormattedCheckedInTickets = new uint[](Counter);
        uint Found;
        for(uint x; x < Counter; x++)
        {
            if(_TokenIDs[x] != 0 || (_TokenIDs[x] == 0 && x == 0))
            {
                FormattedCheckedInTickets[Found] = _TokenIDs[x];
                Found++;
            }
        }
        return FormattedCheckedInTickets;
    }

    /**
     * @dev Returns A 2d Array Of Minted ArtistIDs
     */
    function readArtistUnmintedTicketIDs(uint[] calldata ArtistIDs, uint Range) public view returns(uint[][] memory TokenIDs)
    {
        uint[][] memory _TokenIDs = new uint[][](ArtistIDs.length);
        uint Index;
        for(uint ArtistID; ArtistID < ArtistIDs.length; ArtistID++)
        {
            uint[] memory UnmintedArtistTokenIDs = new uint[](Range);
            uint Counter;
            for(uint TokenID; TokenID < Range; TokenID++)
            {
                bool TicketIDBurned;
                try IERC721(_MintPassFactory).ownerOf(TokenID) { } // checks if token is burned
                catch { TicketIDBurned = true; }
                if(
                    !_MintedArtist[ArtistIDs[ArtistID]][TokenID]
                    &&
                    (
                        _BrightListArtist[ArtistIDs[ArtistID]][TokenID] != address(0)
                        ||
                        TicketIDBurned == false
                    )
                ) 
                { 
                    UnmintedArtistTokenIDs[Counter] = TokenID; 
                    Counter++;
                }
            }
            uint[] memory FormattedUnMintedArtistIDs = new uint[](Counter);
            uint Found;
            for(uint x; x < Counter; x++)
            {
                if(UnmintedArtistTokenIDs[x] != 0 || (UnmintedArtistTokenIDs[x] == 0 && x == 0))
                {
                    FormattedUnMintedArtistIDs[Found] = UnmintedArtistTokenIDs[x];
                    Found++;
                }
            }
            _TokenIDs[Index] = FormattedUnMintedArtistIDs;
            Index++;
        }
        return (_TokenIDs);
    }

    /**
     * @dev Returns A 2d Array Of Minted ArtistIDs
     */
    function readArtistMintedTicketIDs(uint[] calldata ArtistIDs, uint Range) public view returns(uint[][] memory TokenIDs)
    {
        uint[][] memory _TokenIDs = new uint[][](ArtistIDs.length);
        uint Index;
        for(uint ArtistID; ArtistID < ArtistIDs.length; ArtistID++)
        {
            uint[] memory MintedTokenIDs = new uint[](Range);
            uint Counter;
            for(uint TokenID; TokenID < Range; TokenID++)
            {
                if(_MintedArtist[ArtistIDs[ArtistID]][TokenID])
                { 
                    MintedTokenIDs[Counter] = TokenID; 
                    Counter++;
                }
            }
            uint[] memory FormattedMintedTokenIDs = new uint[](Counter);
            uint Found;
            for(uint x; x < Counter; x++)
            {
                if(MintedTokenIDs[x] != 0 || (MintedTokenIDs[x] == 0 && x == 0))
                {
                    FormattedMintedTokenIDs[Found] = MintedTokenIDs[x];
                    Found++;
                }
            }
            _TokenIDs[Index] = FormattedMintedTokenIDs;
            Index++;
        }
        return (_TokenIDs);
    }

    /**
     * @dev Returns Original Recipients Of CryptoCitizens
     */
    function readCitizenBrightList(uint CityIndex) public view returns(address[] memory Recipients)
    {
        address[] memory _Recipients = new address[](1000);
        uint Start = (CityIndex % 7) * 1000;
        for(uint x; x < 1000; x++) { _Recipients[x] = _BrightListCitizen[CityIndex][Start+x]; }
        return _Recipients;
    }

    /**
     * @dev Returns Original Recipient Of Artist NFTs
     */
    function readArtistBrightList(uint ArtistID, uint Range) public view returns(address[] memory Recipients)
    {
        address[] memory _Recipients = new address[](Range);
        for(uint x; x < Range; x++) { _Recipients[x] = _BrightListArtist[ArtistID][x]; }
        return _Recipients;    
    }

    /**
     * @dev Returns The City Struct At Index Of `CityIndex`
     */
    function readCitizenCity(uint CityIndex) public view returns(City memory) { return Cities[CityIndex]; }

    /**
     * @dev Returns The Artist Struct At Index Of `ArtistID`
     */
    function readArtist(uint ArtistID) public view returns(Artist memory) { return Artists[ArtistID]; }

    /**
     * @dev Returns A Minted Work TokenID Corresponding To The Input Artist TicketID 
     */
    function readArtistMintedTokenID(uint ArtistID, uint TicketID) external view returns (uint)
    {
        if(!_MintedArtist[ArtistID][TicketID]) { return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff; }
        else { return _MintedTokenIDArtist[ArtistID][TicketID]; }
    }

    /**
     * @dev Returns A Minted Citizen TokenID Corresponding To Input TicketID
     */
    function readCitizenMintedTokenID(uint CityIndex, uint TicketID) external view returns(uint)
    {
        if(!_MintedCitizen[CityIndex][TicketID]) { return type(uint).max; }
        else { return _MintedTokenIDCitizen[CityIndex][TicketID]; }  
    }
    
    /*-------------------------*/
    /*        LAUNCHPAD        */
    /*-------------------------*/

    /**
     * @dev Initializes A LiveMint Artist
     */
    function __InitLiveMint(Artist memory _Params) external onlyAuthorized returns (uint)
    {
        AmountRemaining[_UniqueArtistsInvoked] = _Params._MaxSupply;
        Artists[_UniqueArtistsInvoked] = _Params;
        _UniqueArtistsInvoked++;
        return _UniqueArtistsInvoked - 1;
    }

    /*-------------------------*/
    /*     ACCESS MODIFIERS    */
    /*-------------------------*/

    /**
     * @dev Access Modifier That Allows Only BrightListed BRT Minters
     **/
    modifier onlyMinter() 
    {
        require(Role[msg.sender] == _MINTER_ROLE, "LiveMint: OnlyMinter Caller Is Not Approved BRT Minter");
        _;
    }

    /**
     * @dev Access Modifier That Allows Only Authorized Contracts
     */
    modifier onlyAuthorized()
    {
        require(Role[msg.sender] == _AUTHORIZED, "LiveMint: OnlyAuthorized Caller Is Not Approved Contract");
        _;
    }
}