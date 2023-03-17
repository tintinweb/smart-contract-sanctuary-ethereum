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

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

interface ICoolERC721A {
  /// @notice Mint an amount of tokens to the given address
  /// @dev Can only be called by an account with the MINTER_ROLE
  ///      Will revert if called when paused, see _beforeTokenTransfer
  /// @param to The address to mint the token to
  /// @param amount The amount of tokens to mint
  function mint(address to, uint256 amount) external;

  /// @notice Externally exposes the _nextTokenId function
  /// @dev used for referencing when burning fractures
  /// @return The next token id
  function nextTokenId() external view returns (uint256);
}

interface IFractures {
  /**
    * @dev Burns `tokenId`. See {ERC721A-_burn}.
    *
    * Requirements:
    *
    * - The caller must own `tokenId` or be an approved operator.
    */
  function burn(uint256 tokenId) external;
}

/// @title Into The Fracture
/// @author Adam Goodman
/// @notice This contract allows the burning of Cool Cats Fractures
contract I is Ownable, Pausable {
  IFractures public _fractures;
  ICoolERC721A public _s;

  bytes32 public _merkleRoot;
  bool public _allowlistEnabled;

  uint256 public _burnWindowStart;
  uint256 public _burnWindowEnd;

  error BurnWindowNotStarted();
  error BurnWindowEnded();
  error InvalidMerkleProof();
  error NullMerkleRoot();

  event AllowlistEnabledSet(bool allowlistEnabled);
  event BurnWindowSet(uint256 burnWindowStart, uint256 burnWindowEnd);
  event FractureAddressSet(address fractures);
  event FractureEntered(uint256[] fractureIds, uint256 firstId);
  event MerkleRootSet(bytes32 merkleRoot);
  event SAddressSet(address s);

  /// @dev Set merkleRoot to the null bytes32 to disable the allowlist
  ///      Any other value will enable the allowlist by default
  constructor(
    address fractures,
    address s,
    uint64 burnWindowStart,
    uint64 burnWindowEnd,
    bytes32 merkleRoot
  ) {
    _fractures = IFractures(fractures);
    _s = ICoolERC721A(s);

    _burnWindowStart = burnWindowStart;
    _burnWindowEnd = burnWindowEnd;

    if (merkleRoot != bytes32(0)) {
      _merkleRoot = merkleRoot;
      _allowlistEnabled = true;
    }

    _pause();
  }

  /// @notice Modifier to check if the burn window is open, otherwise revert
  modifier withinBurnWindow() {
    if (block.timestamp < _burnWindowStart) {
      revert BurnWindowNotStarted();
    }

    if (block.timestamp > _burnWindowEnd) {
      revert BurnWindowEnded();
    }

    _;
  }

  /// @notice Verify merkleProof submitted by a sender
  /// @param sender The account being verified
  /// @param merkleProof Merkle data to verify against
  modifier hasValidMerkleProof(address sender, bytes32[] calldata merkleProof) {
    if (_allowlistEnabled) {
      if (!isValidMerkleProof(sender, merkleProof)) {
        revert InvalidMerkleProof();
      }
    }
    _;
  }

  /// @notice Burns given Fractures and mints S
  /// @param fractureIds The Fractures to burn
  /// @param merkleProof The merkle proof for the given address
  /// @dev If the allowlist is enabled, the merkle proof must be valid, otherwise it will revert
  ///      if the allowlist is disabled, the merkle proof will be ignored, so it can be an empty array
  function enterFracture(
    uint256[] memory fractureIds,
    bytes32[] calldata merkleProof
  ) external whenNotPaused withinBurnWindow hasValidMerkleProof(msg.sender, merkleProof) {
    unchecked {
      uint256 i;
      do {
        _fractures.burn(fractureIds[i]);
      } while (++i < fractureIds.length);
    }

    uint256 nextTokenId = _s.nextTokenId();
    _s.mint(msg.sender, fractureIds.length);

    emit FractureEntered(fractureIds, nextTokenId);
  }

  /// @notice Sets the merkle root for the allowlist
  /// @dev Only the owner can call this function, setting the merkle root does not change
  ///      whether the allowlist is enabled or not
  /// @param merkleRoot The new merkle root
  function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    _merkleRoot = merkleRoot;

    emit MerkleRootSet(merkleRoot);
  }

  /// @notice Sets whether the allowlist is enabled or not
  /// @dev Only the owner can call this function
  /// @param allowlistEnabled Whether the allowlist is enabled or not
  function setAllowlistEnabled(bool allowlistEnabled) external onlyOwner {
    if (allowlistEnabled && _merkleRoot == bytes32(0)) {
      revert NullMerkleRoot();
    }

    _allowlistEnabled = allowlistEnabled;

    emit AllowlistEnabledSet(allowlistEnabled);
  }

  /// @notice Pauses the contract - stopping minting via the public mint function
  /// @dev Only the owner can call this function
  ///      Emit handled by {OpenZepplin Pausable}
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice Unpauses the contract - allowing minting via the public mint function
  /// @dev Only the owner can call this function
  ///      Emit handled by {OpenZepplin Pausable}
  function unpause() external onlyOwner {
    _unpause();
  }

  /// @notice Sets the burn window, start and end times are in seconds since unix epoch
  /// @dev Only the owner can call this function
  /// @param burnWindowStart The start time of the burn window
  /// @param burnWindowEnd The end time of the burn window
  function setBurnWindow(uint256 burnWindowStart, uint256 burnWindowEnd) external onlyOwner {
    _burnWindowStart = burnWindowStart;
    _burnWindowEnd = burnWindowEnd;

    emit BurnWindowSet(burnWindowStart, burnWindowEnd);
  }

  /// @notice Sets the address of the Fractures contract
  /// @dev Only the owner can call this function
  /// @param fractures The address of the Fractures contract
  function setFracturesAddress(address fractures) external onlyOwner {
    _fractures = IFractures(fractures);

    emit FractureAddressSet(fractures);
  }

  /// @notice Sets the address of the s contract
  /// @dev Only the owner can call this function
  /// @param s The address of the s contract
  function setSAddress(address s) external onlyOwner {
    _s = ICoolERC721A(s);

    emit SAddressSet(s);
  }

  /// @notice Checks if a given address is on the merkle tree allowlist
  /// @dev Merkle trees can be generated using https://github.com/OpenZeppelin/merkle-tree
  /// @param account The address to check
  /// @param merkleProof The merkle proof to check
  /// @return Whether the address is on the allowlist or not
  function isValidMerkleProof(
    address account,
    bytes32[] calldata merkleProof
  ) public view virtual returns (bool) {
    return
      MerkleProof.verify(
        merkleProof,
        _merkleRoot,
        keccak256(bytes.concat(keccak256(abi.encode(account))))
      );
  }
}