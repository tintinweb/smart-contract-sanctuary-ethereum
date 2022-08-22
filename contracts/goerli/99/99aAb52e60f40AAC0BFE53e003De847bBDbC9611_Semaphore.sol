// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/ISemaphore.sol";
import "./interfaces/IVerifier.sol";
import "./base/SemaphoreCore.sol";
import "./base/SemaphoreGroups.sol";

/// @title Semaphore
contract Semaphore is ISemaphore, SemaphoreCore, SemaphoreGroups {
  /// @dev Gets a tree depth and returns its verifier address.
  mapping(uint8 => IVerifier) public verifiers;

  /// @dev Gets a group id and returns the group admin address.
  mapping(uint256 => address) public groupAdmins;

  /// @dev Checks if the group admin is the transaction sender.
  /// @param groupId: Id of the group.
  modifier onlyGroupAdmin(uint256 groupId) {
    require(groupAdmins[groupId] == _msgSender(), "Semaphore: caller is not the group admin");
    _;
  }

  /// @dev Checks if there is a verifier for the given tree depth.
  /// @param depth: Depth of the tree.
  modifier onlySupportedDepth(uint8 depth) {
    require(address(verifiers[depth]) != address(0), "Semaphore: tree depth is not supported");
    _;
  }

  /// @dev Initializes the Semaphore verifiers used to verify the user's ZK proofs.
  /// @param _verifiers: List of Semaphore verifiers (address and related Merkle tree depth).
  constructor(Verifier[] memory _verifiers) {
    for (uint8 i = 0; i < _verifiers.length; i++) {
      verifiers[_verifiers[i].merkleTreeDepth] = IVerifier(_verifiers[i].contractAddress);
    }
  }

  /// @dev See {ISemaphore-createGroup}.
  function createGroup(
    uint256 groupId,
    uint8 depth,
    uint256 zeroValue,
    address admin
  ) external override onlySupportedDepth(depth) {
    _createGroup(groupId, depth, zeroValue);

    groupAdmins[groupId] = admin;

    emit GroupAdminUpdated(groupId, address(0), admin);
  }

  /// @dev See {ISemaphore-updateGroupAdmin}.
  function updateGroupAdmin(uint256 groupId, address newAdmin) external override onlyGroupAdmin(groupId) {
    groupAdmins[groupId] = newAdmin;

    emit GroupAdminUpdated(groupId, _msgSender(), newAdmin);
  }

  /// @dev See {ISemaphore-addMember}.
  function addMember(uint256 groupId, uint256 identityCommitment) external override onlyGroupAdmin(groupId) {
    _addMember(groupId, identityCommitment);
  }

  /// @dev See {ISemaphore-removeMember}.
  function removeMember(
    uint256 groupId,
    uint256 identityCommitment,
    uint256[] calldata proofSiblings,
    uint8[] calldata proofPathIndices
  ) external override onlyGroupAdmin(groupId) {
    _removeMember(groupId, identityCommitment, proofSiblings, proofPathIndices);
  }

  /// @dev See {ISemaphore-verifyProof}.
  function verifyProof(
    uint256 groupId,
    bytes32 signal,
    uint256 nullifierHash,
    uint256 externalNullifier,
    uint256[8] calldata proof
  ) external override {
    uint256 root = getRoot(groupId);
    uint8 depth = getDepth(groupId);

    require(depth != 0, "Semaphore: group does not exist");

    IVerifier verifier = verifiers[depth];

    _verifyProof(signal, root, nullifierHash, externalNullifier, proof, verifier);

    _saveNullifierHash(nullifierHash);

    emit ProofVerified(groupId, signal);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Semaphore interface.
/// @dev Interface of a Semaphore contract.
interface ISemaphore {
  struct Verifier {
    address contractAddress;
    uint8 merkleTreeDepth;
  }

  /// @dev Emitted when an admin is assigned to a group.
  /// @param groupId: Id of the group.
  /// @param oldAdmin: Old admin of the group.
  /// @param newAdmin: New admin of the group.
  event GroupAdminUpdated(uint256 indexed groupId, address indexed oldAdmin, address indexed newAdmin);

  /// @dev Emitted when a Semaphore proof is verified.
  /// @param groupId: Id of the group.
  /// @param signal: Semaphore signal.
  event ProofVerified(uint256 indexed groupId, bytes32 signal);

  /// @dev Saves the nullifier hash to avoid double signaling and emits an event
  /// if the zero-knowledge proof is valid.
  /// @param groupId: Id of the group.
  /// @param signal: Semaphore signal.
  /// @param nullifierHash: Nullifier hash.
  /// @param externalNullifier: External nullifier.
  /// @param proof: Zero-knowledge proof.
  function verifyProof(
    uint256 groupId,
    bytes32 signal,
    uint256 nullifierHash,
    uint256 externalNullifier,
    uint256[8] calldata proof
  ) external;

  /// @dev Creates a new group. Only the admin will be able to add or remove members.
  /// @param groupId: Id of the group.
  /// @param depth: Depth of the tree.
  /// @param zeroValue: Zero value of the tree.
  /// @param admin: Admin of the group.
  function createGroup(
    uint256 groupId,
    uint8 depth,
    uint256 zeroValue,
    address admin
  ) external;

  /// @dev Updates the group admin.
  /// @param groupId: Id of the group.
  /// @param newAdmin: New admin of the group.
  function updateGroupAdmin(uint256 groupId, address newAdmin) external;

  /// @dev Adds a new member to an existing group.
  /// @param groupId: Id of the group.
  /// @param identityCommitment: New identity commitment.
  function addMember(uint256 groupId, uint256 identityCommitment) external;

  /// @dev Removes a member from an existing group. A proof of membership is
  /// needed to check if the node to be removed is part of the tree.
  /// @param groupId: Id of the group.
  /// @param identityCommitment: Identity commitment to be deleted.
  /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
  /// @param proofPathIndices: Path of the proof of membership.
  function removeMember(
    uint256 groupId,
    uint256 identityCommitment,
    uint256[] calldata proofSiblings,
    uint8[] calldata proofPathIndices
  ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Verifier interface.
/// @dev Interface of Verifier contract.
interface IVerifier {
  function verifyProof(
    uint256[2] memory a,
    uint256[2][2] memory b,
    uint256[2] memory c,
    uint256[4] memory input
  ) external view;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/ISemaphoreCore.sol";
import "../interfaces/IVerifier.sol";

/// @title Semaphore core contract.
/// @notice Minimal code to allow users to signal their endorsement of an arbitrary string.
/// @dev The following code verifies that the proof is correct and saves the hash of the
/// nullifier to prevent double-signaling. External nullifier and Merkle trees (i.e. groups) must be
/// managed externally.
contract SemaphoreCore is ISemaphoreCore {
  /// @dev Gets a nullifier hash and returns true or false.
  /// It is used to prevent double-signaling.
  mapping(uint256 => bool) internal nullifierHashes;

  /// @dev Asserts that no nullifier already exists and if the zero-knowledge proof is valid.
  /// Otherwise it reverts.
  /// @param signal: Semaphore signal.
  /// @param root: Root of the Merkle tree.
  /// @param nullifierHash: Nullifier hash.
  /// @param externalNullifier: External nullifier.
  /// @param proof: Zero-knowledge proof.
  /// @param verifier: Verifier address.
  function _verifyProof(
    bytes32 signal,
    uint256 root,
    uint256 nullifierHash,
    uint256 externalNullifier,
    uint256[8] calldata proof,
    IVerifier verifier
  ) internal view {
    require(!nullifierHashes[nullifierHash], "SemaphoreCore: you cannot use the same nullifier twice");

    uint256 signalHash = _hashSignal(signal);

    verifier.verifyProof(
      [proof[0], proof[1]],
      [[proof[2], proof[3]], [proof[4], proof[5]]],
      [proof[6], proof[7]],
      [root, nullifierHash, signalHash, externalNullifier]
    );
  }

  /// @dev Stores the nullifier hash to prevent double-signaling.
  /// Attention! Remember to call it when you verify a proof if you
  /// need to prevent double-signaling.
  /// @param nullifierHash: Semaphore nullifier hash.
  function _saveNullifierHash(uint256 nullifierHash) internal {
    nullifierHashes[nullifierHash] = true;
  }

  /// @dev Creates a keccak256 hash of the signal.
  /// @param signal: Semaphore signal.
  /// @return Hash of the signal.
  function _hashSignal(bytes32 signal) private pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(signal))) >> 8;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SNARK_SCALAR_FIELD} from "./SemaphoreConstants.sol";
import "../interfaces/ISemaphoreGroups.sol";
import "@zk-kit/incremental-merkle-tree.sol/contracts/IncrementalBinaryTree.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/// @title Semaphore groups contract.
/// @dev The following code allows you to create groups, add and remove members.
/// You can use getters to obtain informations about groups (root, depth, number of leaves).
abstract contract SemaphoreGroups is Context, ISemaphoreGroups {
  using IncrementalBinaryTree for IncrementalTreeData;

  /// @dev Gets a group id and returns the group/tree data.
  mapping(uint256 => IncrementalTreeData) internal groups;

  /// @dev Creates a new group by initializing the associated tree.
  /// @param groupId: Id of the group.
  /// @param depth: Depth of the tree.
  /// @param zeroValue: Zero value of the tree.
  function _createGroup(
    uint256 groupId,
    uint8 depth,
    uint256 zeroValue
  ) internal virtual {
    require(groupId < SNARK_SCALAR_FIELD, "SemaphoreGroups: group id must be < SNARK_SCALAR_FIELD");
    require(getDepth(groupId) == 0, "SemaphoreGroups: group already exists");

    groups[groupId].init(depth, zeroValue);

    emit GroupCreated(groupId, depth, zeroValue);
  }

  /// @dev Adds an identity commitment to an existing group.
  /// @param groupId: Id of the group.
  /// @param identityCommitment: New identity commitment.
  function _addMember(uint256 groupId, uint256 identityCommitment) internal virtual {
    require(getDepth(groupId) != 0, "SemaphoreGroups: group does not exist");

    groups[groupId].insert(identityCommitment);

    uint256 root = getRoot(groupId);

    emit MemberAdded(groupId, identityCommitment, root);
  }

  /// @dev Removes an identity commitment from an existing group. A proof of membership is
  /// needed to check if the node to be deleted is part of the tree.
  /// @param groupId: Id of the group.
  /// @param identityCommitment: Existing identity commitment to be deleted.
  /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
  /// @param proofPathIndices: Path of the proof of membership.
  function _removeMember(
    uint256 groupId,
    uint256 identityCommitment,
    uint256[] calldata proofSiblings,
    uint8[] calldata proofPathIndices
  ) internal virtual {
    require(getDepth(groupId) != 0, "SemaphoreGroups: group does not exist");

    groups[groupId].remove(identityCommitment, proofSiblings, proofPathIndices);

    uint256 root = getRoot(groupId);

    emit MemberRemoved(groupId, identityCommitment, root);
  }

  /// @dev See {ISemaphoreGroups-getRoot}.
  function getRoot(uint256 groupId) public view virtual override returns (uint256) {
    return groups[groupId].root;
  }

  /// @dev See {ISemaphoreGroups-getDepth}.
  function getDepth(uint256 groupId) public view virtual override returns (uint8) {
    return groups[groupId].depth;
  }

  /// @dev See {ISemaphoreGroups-getNumberOfLeaves}.
  function getNumberOfLeaves(uint256 groupId) public view virtual override returns (uint256) {
    return groups[groupId].numberOfLeaves;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title SemaphoreCore interface.
/// @dev Interface of SemaphoreCore contract.
interface ISemaphoreCore {
  /// @notice Emitted when a proof is verified correctly and a new nullifier hash is added.
  /// @param nullifierHash: Hash of external and identity nullifiers.
  event NullifierHashAdded(uint256 nullifierHash);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title SemaphoreGroups interface.
/// @dev Interface of a SemaphoreGroups contract.
interface ISemaphoreGroups {
  /// @dev Emitted when a new group is created.
  /// @param groupId: Id of the group.
  /// @param depth: Depth of the tree.
  /// @param zeroValue: Zero value of the tree.
  event GroupCreated(uint256 indexed groupId, uint8 depth, uint256 zeroValue);

  /// @dev Emitted when a new identity commitment is added.
  /// @param groupId: Group id of the group.
  /// @param identityCommitment: New identity commitment.
  /// @param root: New root hash of the tree.
  event MemberAdded(uint256 indexed groupId, uint256 identityCommitment, uint256 root);

  /// @dev Emitted when a new identity commitment is removed.
  /// @param groupId: Group id of the group.
  /// @param identityCommitment: New identity commitment.
  /// @param root: New root hash of the tree.
  event MemberRemoved(uint256 indexed groupId, uint256 identityCommitment, uint256 root);

  /// @dev Returns the last root hash of a group.
  /// @param groupId: Id of the group.
  /// @return Root hash of the group.
  function getRoot(uint256 groupId) external view returns (uint256);

  /// @dev Returns the depth of the tree of a group.
  /// @param groupId: Id of the group.
  /// @return Depth of the group tree.
  function getDepth(uint256 groupId) external view returns (uint8);

  /// @dev Returns the number of tree leaves of a group.
  /// @param groupId: Id of the group.
  /// @return Number of tree leaves.
  function getNumberOfLeaves(uint256 groupId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {PoseidonT3} from "./Hashes.sol";

// Each incremental tree has certain properties and data that will
// be used to add new leaves.
struct IncrementalTreeData {
  uint8 depth; // Depth of the tree (levels - 1).
  uint256 root; // Root hash of the tree.
  uint256 numberOfLeaves; // Number of leaves of the tree.
  mapping(uint256 => uint256) zeroes; // Zero hashes used for empty nodes (level -> zero hash).
  // The nodes of the subtrees used in the last addition of a leaf (level -> [left node, right node]).
  mapping(uint256 => uint256[2]) lastSubtrees; // Caching these values is essential to efficient appends.
}

/// @title Incremental binary Merkle tree.
/// @dev The incremental tree allows to calculate the root hash each time a leaf is added, ensuring
/// the integrity of the tree.
library IncrementalBinaryTree {
  uint8 internal constant MAX_DEPTH = 32;
  uint256 internal constant SNARK_SCALAR_FIELD =
    21888242871839275222246405745257275088548364400416034343698204186575808495617;

  /// @dev Initializes a tree.
  /// @param self: Tree data.
  /// @param depth: Depth of the tree.
  /// @param zero: Zero value to be used.
  function init(
    IncrementalTreeData storage self,
    uint8 depth,
    uint256 zero
  ) public {
    require(zero < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
    require(depth > 0 && depth <= MAX_DEPTH, "IncrementalBinaryTree: tree depth must be between 1 and 32");

    self.depth = depth;

    for (uint8 i = 0; i < depth; i++) {
      self.zeroes[i] = zero;
      zero = PoseidonT3.poseidon([zero, zero]);
    }

    self.root = zero;
  }

  /// @dev Inserts a leaf in the tree.
  /// @param self: Tree data.
  /// @param leaf: Leaf to be inserted.
  function insert(IncrementalTreeData storage self, uint256 leaf) public {
    require(leaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
    require(self.numberOfLeaves < 2**self.depth, "IncrementalBinaryTree: tree is full");

    uint256 index = self.numberOfLeaves;
    uint256 hash = leaf;

    for (uint8 i = 0; i < self.depth; i++) {
      if (index % 2 == 0) {
        self.lastSubtrees[i] = [hash, self.zeroes[i]];
      } else {
        self.lastSubtrees[i][1] = hash;
      }

      hash = PoseidonT3.poseidon(self.lastSubtrees[i]);
      index /= 2;
    }

    self.root = hash;
    self.numberOfLeaves += 1;
  }

  /// @dev Removes a leaf from the tree.
  /// @param self: Tree data.
  /// @param leaf: Leaf to be removed.
  /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
  /// @param proofPathIndices: Path of the proof of membership.
  function remove(
    IncrementalTreeData storage self,
    uint256 leaf,
    uint256[] calldata proofSiblings,
    uint8[] calldata proofPathIndices
  ) public {
    require(verify(self, leaf, proofSiblings, proofPathIndices), "IncrementalBinaryTree: leaf is not part of the tree");

    uint256 hash = self.zeroes[0];

    for (uint8 i = 0; i < self.depth; i++) {
      if (proofPathIndices[i] == 0) {
        if (proofSiblings[i] == self.lastSubtrees[i][1]) {
          self.lastSubtrees[i][0] = hash;
        }

        hash = PoseidonT3.poseidon([hash, proofSiblings[i]]);
      } else {
        if (proofSiblings[i] == self.lastSubtrees[i][0]) {
          self.lastSubtrees[i][1] = hash;
        }

        hash = PoseidonT3.poseidon([proofSiblings[i], hash]);
      }
    }

    self.root = hash;
  }

  /// @dev Verify if the path is correct and the leaf is part of the tree.
  /// @param self: Tree data.
  /// @param leaf: Leaf to be removed.
  /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
  /// @param proofPathIndices: Path of the proof of membership.
  /// @return True or false.
  function verify(
    IncrementalTreeData storage self,
    uint256 leaf,
    uint256[] calldata proofSiblings,
    uint8[] calldata proofPathIndices
  ) private view returns (bool) {
    require(leaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
    require(
      proofPathIndices.length == self.depth && proofSiblings.length == self.depth,
      "IncrementalBinaryTree: length of path is not correct"
    );

    uint256 hash = leaf;

    for (uint8 i = 0; i < self.depth; i++) {
      require(
        proofSiblings[i] < SNARK_SCALAR_FIELD,
        "IncrementalBinaryTree: sibling node must be < SNARK_SCALAR_FIELD"
      );

      if (proofPathIndices[i] == 0) {
        hash = PoseidonT3.poseidon([hash, proofSiblings[i]]);
      } else {
        hash = PoseidonT3.poseidon([proofSiblings[i], hash]);
      }
    }

    return hash == self.root;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library PoseidonT3 {
  function poseidon(uint256[2] memory) public pure returns (uint256) {}
}

library PoseidonT6 {
  function poseidon(uint256[5] memory) public pure returns (uint256) {}
}