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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
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
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
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
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
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
     * @dev Calldata version of {processMultiProof}
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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

// @notice Interface for Polygon bridgable NFTs on L1-chain
interface IERC721BridgableParent is IERC721Enumerable {
    /**
     * Mints a token. Can be called by minting contract or by bridge
     *
     * @param to         Account to mint to
     * @param tokenId    Id of token to mint
     */
    function mint(address to, uint256 tokenId) external;

    /**
     * Mints a token and also sets metadata from L2
     *
     * @param to        Address to mint to
     * @param tokenId   Id of the token to mint
     * @param metadata  ABI encoded tokenURI for the token
     */
    function mint(
        address to,
        uint256 tokenId,
        bytes calldata metadata
    ) external;

    /**
     * @param tokenId token id to check
     * @return Whether or not the given tokenId has been minted
     */
    function exists(uint256 tokenId) external view returns (bool);

    /**
     * Sets the metadata for a given token, only callable by bridge
     *
     * @param tokenId  Id of the token to set metadata for
     * @param data     Metadata for the token
     */
    function setTokenMetadata(uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol"; // OZ: Pausable
import "@openzeppelin/contracts/access/Ownable.sol"; // OZ: Ownership
import "@openzeppelin/contracts/utils/introspection/IERC165.sol"; // OZ: ERC165 interface
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // OZ: Reentrancy Guard
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // OZ: MerkleRoot
import "@openzeppelin/contracts/utils/Counters.sol"; // OZ: Counter

import "./interfaces/IERC721BridgableParent.sol"; // token contract for minting

/// @title StagedMintV1 - lets users mint in stages, currently only 2 stages (premint and public stage)
contract StagedMintV1 is Ownable, ReentrancyGuard, Pausable {
    // For counter
    using Counters for Counters.Counter;

    // Stages
    enum MintStage {
        DISABLED,
        PREMINT,
        ALLOWLIST,
        PUBLIC_SALE
    }

    /** IMMUTABLE STORAGE **/

    /// @notice Number of mints in PREMINT phase
    uint256 constant PREMINT_COUNT = 2;

    /// @notice Number of mints in ALLOWLIST phase
    uint256 constant ALLOWLIST_COUNT = 3;

    /// @notice Cost to mint each NFT (in wei)
    uint256 public immutable MINT_COST;
    /// @notice Cost to premint each NFT (in wei)
    uint256 public immutable PREMINT_COST;
    /// @notice Available NFT supply
    uint256 public immutable AVAILABLE_SUPPLY;
    /// @notice Maximum mints per address
    uint256 public immutable MAX_PER_ADDRESS;
    /// @notice Address of NFT Contract to mint to
    IERC721BridgableParent public immutable NFT_CONTRACT;

    /** MUTABLE STORAGE **/
    /// @notice Variable to keep track of which stage we are in
    MintStage public mintStage = MintStage.DISABLED;
    /// @notice Merkle root hash for the premint list
    bytes32 public merkleRootHash;
    /// @notice Address mapping to track number of completed premints
    mapping(address => uint256) public premintCounts;
    /// @notice Address mapping to track number of completed allowlist mints
    mapping(address => uint256) public allowlistCounts;
    /// @notice Address mapping to track number of completed public sale mints
    mapping(address => uint256) public mintCounts;
    /// @notice Counter for number of NFTs that have been claimed
    Counters.Counter public currentTokenId;

    /** EVENTS **/

    /**
     * @notice Emitted when the owner changes the current mint stage
     *
     * @param owner Address of owner enabling the premint
     * @param stage Stage that the contract is currently in
     */
    event StageChanged(address indexed owner, MintStage stage);

    /**
     * @notice Emitted when the owner withdraws proceeeds
     *
     * @param owner Address of owner withdrawing
     * @param amount  Amount that was withdrew
     */
    event WithdrewProceeds(address indexed owner, uint256 amount);

    /** SETUP **/

    /**
     * @notice Creates a new NFT distribution contract
     *
     * @param _PREMINT_COST in wei per NFT
     * @param _MINT_COST in wei per NFT
     * @param _AVAILABLE_SUPPLY total NFTs to sell
     * @param _MAX_PER_ADDRESS maximum mints allowed per address
     * @param _NFT_CONTRACT_ADDRESS contract address of NFT that will be minted
     */
    constructor(
        uint256 _PREMINT_COST,
        uint256 _MINT_COST,
        uint256 _AVAILABLE_SUPPLY,
        uint256 _MAX_PER_ADDRESS,
        address _NFT_CONTRACT_ADDRESS
    ) {
        PREMINT_COST = _PREMINT_COST;
        MINT_COST = _MINT_COST;
        AVAILABLE_SUPPLY = _AVAILABLE_SUPPLY;
        MAX_PER_ADDRESS = _MAX_PER_ADDRESS;
        NFT_CONTRACT = IERC721BridgableParent(_NFT_CONTRACT_ADDRESS);

        // Check that NFT contract address is correctly set
        require(
            address(NFT_CONTRACT) != address(0),
            "NFT_CONTRACT_ERROR: NFT Address has not been set"
        );

        // Check that NFT contract address supports ERC165 Interface
        require(
            NFT_CONTRACT.supportsInterface(type(IERC165).interfaceId) == true,
            "NFT_CONTRACT_ERROR: NFT Contract doesn't support ERC165 Interface"
        );

        // Check that the contract has the functions we expect
        require(
            NFT_CONTRACT.supportsInterface(
                type(IERC721BridgableParent).interfaceId
            ) == true,
            "NFT_CONTRACT_NOT_BRIDGABLE: NFT Contract is not a IERC721BridgableParent"
        );

        _pause();
    }

    /** EXTERNAL - ENTER RAFFLE OR MINT **/

    /**
     * @notice Allows users on the premint list to premint
     *
     * @param amount        Number of premints
     * @param merkleProof   Proof that the user is on the list
     */
    function enterPremint(uint256 amount, bytes32[] calldata merkleProof)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(
            amount != 0,
            "INCORRECT_AMOUNT: Amount must be greater than zero"
        );

        // Ensure premint is enabled
        require(
            mintStage == MintStage.PREMINT || mintStage == MintStage.ALLOWLIST,
            "PREMINT_NOT_ACTIVE: Premint has not begun"
        );

        // Ensure sufficient payment
        if (mintStage == MintStage.ALLOWLIST) {
            require(
                msg.value == (amount * MINT_COST),
                "INCORRECT_PAYMENT: Incorrect payment amount for mint"
            );

            // Track user allowlist count
            uint256 userPremintedCount = allowlistCounts[_msgSender()];

            // Ensure address is not attempting to premint more than allowed
            require(
                (userPremintedCount + amount) <= ALLOWLIST_COUNT,
                "PREMINT_MAX_REACHED: Attempting to premint more than allotment"
            );

            // Increase count of user premints redeemed
            allowlistCounts[_msgSender()] = (userPremintedCount + amount);
        } else {
            require(
                msg.value == (amount * PREMINT_COST),
                "INCORRECT_PAYMENT: Incorrect payment amount for mint"
            );

            // Track user premint count
            uint256 userPremintedCount = premintCounts[_msgSender()];

            // Ensure address is not attempting to premint more than allowed
            require(
                (userPremintedCount + amount) <= PREMINT_COUNT,
                "PREMINT_MAX_REACHED: Attempting to premint more than allotment"
            );

            // Increase count of user premints redeemed
            premintCounts[_msgSender()] = (userPremintedCount + amount);
        }

        // Ensure address is on premint/allowlist list by checking merkle root
        bytes32 merkleLeaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verifyCalldata(merkleProof, merkleRootHash, merkleLeaf),
            "PREMINT_ADDRESS_MISSING: Address not on premint list"
        );

        _directMintAndIncrementCurrentTokenId(amount);
    }

    /**
     * @notice Whether or not user is on premint list using merkle proof
     *
     * @param account Account to check is on premint list
     * @return TRUE if account is on list, FALSE otherwise
     */
    function isOnPremintList(address account, bytes32[] calldata merkleProof)
        external
        view
        returns (bool)
    {
        bytes32 merkleLeaf = keccak256(abi.encodePacked(account));
        return
            MerkleProof.verifyCalldata(merkleProof, merkleRootHash, merkleLeaf);
    }

    /**
     * @notice Mint during public sale
     *
     * @param amount Number of tokens to mint
     */
    function mint(uint256 amount) external payable whenNotPaused nonReentrant {
        // Ensure public sale has begun
        require(
            mintStage == MintStage.PUBLIC_SALE,
            "PUBLIC_SALE_NOT_STARTED: Public sale has not begun"
        );

        require(
            amount != 0,
            "INCORRECT_AMOUNT: Amount must be greater than zero"
        );

        // Ensure sufficient mint payment
        require(
            msg.value == (amount * MINT_COST),
            "INCORRECT_PAYMENT: Incorrect payment amount for mint"
        );

        uint256 addressMintedCount = mintCounts[_msgSender()];
        // Ensure number of tokens to acquire <= max for this address
        require(
            (addressMintedCount + amount) <= MAX_PER_ADDRESS,
            "MINT_MAX_REACHED: This transaction exceeds your addresses limit of tokens"
        );

        // Increase count of user mints redeemed
        mintCounts[_msgSender()] = (addressMintedCount + amount);

        _directMintAndIncrementCurrentTokenId(amount);
    }

    /** EXTERNAL - ADMIN */

    /** @notice Allows contract owner to withdraw proceeds of mints */
    function withdrawProceeds() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        // Ensure there are proceeds to claim
        require(balance > 0, "PAYOUT_EMPTY: No proceeds available to claim");

        // Pay owner proceeds
        (bool sent, ) = payable(_msgSender()).call{value: balance}("");
        require(
            sent == true,
            "WITHDRAW_UNSUCCESFUL: Was unable to withdraw proceeds"
        );

        emit WithdrewProceeds(_msgSender(), balance);
    }

    /**
     * @notice Update the merkleproof root hash for the premint list
     *
     * @param rootHash for the merkle tree root
     */
    function updateMerkleRoot(bytes32 rootHash) external onlyOwner {
        // Ensure premint is enabled
        require(
            mintStage == MintStage.DISABLED,
            "NOT_DISABLED: Can not add to premint list unless disabled"
        );

        merkleRootHash = rootHash;
    }

    /**
     * @notice Pause/Unpause this contract
     *
     * @param _paused Whether to pause or unpause the contract
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused == true) _pause();
        else _unpause();
    }

    /**
     * @notice Sets the mint stage
     *
     * @param _stage Stage to change to
     */
    function setMintStage(MintStage _stage) external onlyOwner {
        mintStage = _stage;

        emit StageChanged(_msgSender(), _stage);
    }

    /** INTERNAL **/

    /**
     * @notice Private function used by premint and mint to mint
     *
     * @param amount number of tokens to mint
     */
    function _directMintAndIncrementCurrentTokenId(uint256 amount) internal {
        // Ensure NFTs are still available
        require(
            (currentTokenId.current() + amount) <= AVAILABLE_SUPPLY,
            "NFT_MAX_REACHED: Not enough NFTs left to fulfill transaction"
        );

        // Mint NFTs for number requested
        for (uint256 i = 0; i < amount; ++i) {
            // Increment current token id to next id
            currentTokenId.increment();
            // Mint current token id as NFT
            _mintNFT(_msgSender(), currentTokenId.current());
        }
    }

    /**
     * @notice Function to mint from the NFT contract
     *
     * @param to address to mint NFT to
     * @param tokenId tokenId to mint
     */
    function _mintNFT(address to, uint256 tokenId) internal {
        // Call mint function on external NFT contract
        NFT_CONTRACT.mint(to, tokenId);
    }
}