/**
 *Submitted for verification at Etherscan.io on 2022-10-16
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IENSRegistrar {
    function changeRootNodeOwner(bytes32 rootNode_, address _newOwner) external;

    function register(
        string memory rootName_,
        bytes32 rootNode_,
        string calldata label_,
        address owner_
    )
    external;

    function changePermissionContract(address _newPermissionContract) external;

    function labelOwner(bytes32 rootNode_, string calldata label) external view returns (address);

    function changeLabelOwner(bytes32 rootNode_, string calldata label_, address newOwner_)
    external;
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]

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


// File contracts/PermissionContract.sol

pragma solidity ^0.8.0;


/**
 * @title PermissionContract
 * @author Graeme (@strangechances)
 *
 *  An ERC20 that grants access to the ENS namespace through a
 *  burn-and-register model.
 */
contract PermissionContract {
    // ============ Mutable Ownership Configuration ============

    address private _owner;
    address private _rootProvider;
    /**
     * @dev Allows for two-step ownership transfer, whereby the next owner
     * needs to accept the ownership transfer explicitly.
     */
    address private _nextOwner;

    // ============ Mutable Registration Configuration ============

    bool public registrable = true;
    address public ensRegistrar;

    // ============ Merkle Root Configuration ============

    mapping(bytes32 => bytes32) public merkleRoots;
    // Root shard => Node => True/False
    mapping(bytes32 => mapping(bytes32 => bool)) internal claimed;

    // Registration fee
    uint256 public registrationFee = 0.001 ether;

    // ============ Events ============

    event Registered(string label, address owner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event RootUpdated(bytes32 rootShard, bytes32 oldRoot, bytes32 newRoot);
    event Transfer(address indexed from, address indexed to, uint256 value);

    // ============ Modifiers ============

    modifier canRegister() {
        require(registrable, "PermissionContract: registration is closed.");
        _;
    }

    modifier onlyOwner() {
        require(isOwner(), "PermissionContract: caller is not the owner.");
        _;
    }

    modifier onlyNextOwner() {
        require(
            isNextOwner(),
            "PermissionContract: current owner must set caller as next owner."
        );
        _;
    }

    modifier onlyRootProvider() {
        require(isRootProvider() || isOwner(), "PermissionContract: caller is not the root provider or owner.");
        _;
    }

    // ============ Constructor ============

    constructor() public {
        _owner = tx.origin;
        emit OwnershipTransferred(address(0), _owner);
    }

    // ============ Registration ============

    /**
     * Burns the sender's invite tokens and registers an ENS given label to a given address.
     * @param owner_ The address that should own the label.
     * @param rootName_ The name of the ens root
     * @param rootNode_ The hashed node for the ens root
     * @param label_ The user's ENS label, e.g. "admin" for admin.soul.xyz.
     * @param rootShard_ The merkle proof shard
     * @param merkleProof_ The merkle proof
     */
    function registerWithProof(
        address owner_,
        string memory rootName_,
        bytes32 rootNode_,
        string calldata label_,
        bytes32 rootShard_,
        bytes32[] calldata merkleProof_
    )
        external
        payable
        canRegister
    {
//        require(msg.value >= registrationFee, "registration fee required");

        emit Registered(label_, owner_);
        // Generate the node for the merkle tree.
        bytes32 merkleNode = keccak256(abi.encodePacked(owner_, rootNode_, label_));
        // Make sure it's not already claimed.
        //        require(!claimed[rootShard_][rootNode_], "PermissionContract: already claimed.");
        // Verify the merkle proof.
        require(
            MerkleProof.verify(merkleProof_, merkleRoots[rootShard_], merkleNode),
            "PermissionContract: Invalid proof."
        );
        // Mark it claimed.
        //        claimed[rootShard_][merkleNode] = true;
        // Register the node.
        IENSRegistrar(ensRegistrar).register(
            rootName_,
            rootNode_,
            label_,
            owner_
        );
    }

    // ============ Ownership ============

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Returns true if the caller is the current root provider.
     */
    function isRootProvider() public view returns (bool) {
        return msg.sender == _rootProvider;
    }

    /**
     * @dev Returns true if the caller is the next owner.
     */
    function isNextOwner() public view returns (bool) {
        return msg.sender == _nextOwner;
    }

    /**
     * @dev Allows a new account (`newOwner`) to accept ownership.
     * Can only be called by the current owner.
     */
    function transferOwnership(address nextOwner_) external onlyOwner {
        require(
            nextOwner_ != address(0),
            "PermissionContract: next owner is the zero address."
        );

        _nextOwner = nextOwner_;
    }

    /**
     * @dev Cancel a transfer of ownership to a new account.
     * Can only be called by the current owner.
     */
    function cancelOwnershipTransfer() external onlyOwner {
        delete _nextOwner;
    }

    /**
     * @dev Transfers ownership of the contract to the caller.
     * Can only be called by a new potential owner set by the current owner.
     */
    function acceptOwnership() external onlyNextOwner {
        delete _nextOwner;

        emit OwnershipTransferred(_owner, msg.sender);

        _owner = msg.sender;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    // ============ Configuration Management ============

    /**
     * Allows the owner to change the ENS Registrar address.
     */
    function setENSRegistrar(address ensRegistrar_) external onlyOwner {
        ensRegistrar = ensRegistrar_;
    }

    /**
     * Allows the owner to pause registration.
     */
    function setRegistrable(bool registrable_) external onlyOwner {
        registrable = registrable_;
    }

    // ============ Merkle-Tree Token Claim ============

    function setMerkleRoot(bytes32 rootShard, bytes32 merkleRoot_) external onlyRootProvider {
        emit RootUpdated(rootShard, merkleRoots[rootShard], merkleRoot_);
        merkleRoots[rootShard] = merkleRoot_;
    }

    function getMerkleRoot(bytes32 shard) public view returns (bytes32) {
        return merkleRoots[shard];
    }

    function isClaimed(bytes32 rootShard, bytes32 node) public view returns (bool) {
        return claimed[rootShard][node];
    }

    function transferFunds(address payable to, uint256 value) external onlyOwner
    {
        _sendFunds(to, value);
        emit Transfer(address(this), to, value);
    }

    function _sendFunds(address payable recipient, uint256 amount) private {
        require(
            address(this).balance >= amount,
            "Insufficient balance for send"
        );

        (bool success,) = recipient.call{value : amount}("");
        require(success, "Unable to send value: recipient may have reverted");
    }

    receive() external payable {}
}