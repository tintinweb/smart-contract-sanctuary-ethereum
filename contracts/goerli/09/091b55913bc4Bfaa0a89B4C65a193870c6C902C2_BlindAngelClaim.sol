// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

pragma solidity ^0.8.0;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract BlindAngelClaim {

    bytes32 public claimMerkleRoot;
    IERC721 public nft;

    struct WithdrawStruct {
        address creator;
        address to;
        uint256 amount;
        bool isActive;
    }

    event Claimed(address indexed from, uint256 indexed amount, uint256 week);
    event UpdatedClaimList(address indexed updator, bytes32 root_);
    event ApprovedClaimList(address indexed dealer);
    event DeclinedClaimList(address indexed dealer);
    event Deposited(address indexed dealer, uint256 amount);

    event Withdraw(address indexed dealer, address indexed creator, address to, uint256 amount);

    mapping(address => bool) public admins;
    mapping(address => mapping(uint256 => bool)) public claimed;

    address private last_creator;
    bool public frozen;
    bool private isApproved;
    bool private updatedClaimList;
    uint256 public week;

    WithdrawStruct public withdrawRequest;

    modifier onlySigners() {
        require(admins[msg.sender]);
        _;
    }

    modifier onlyNFTOwner() {
        require(nft.balanceOf(msg.sender) > 0);
        _;
    }
    
    constructor(
        address[] memory _owners,
        address _nft
    ) {
        require(_owners.length == 3, "Owners are not 3 addresses" );
        for (uint i = 0; i < _owners.length; i ++) admins[_owners[i]] = true;
        nft = IERC721(_nft);
    }

    // end transfer part
    function claim(uint256 index, uint256 amount, bytes32[] calldata merkleProof, uint256 _week) external onlyNFTOwner {
        require(week == _week, "claim is not available for this week");
        require(!claimed[msg.sender][week], "caller already claimed reward");
        require(!frozen && isApproved, "claim is locked");

        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, amount, week));

        require(
            MerkleProof.verify(merkleProof, claimMerkleRoot, node),
            "Claim: Invalid proof."
        );

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failure! Not withdraw");

        claimed[msg.sender][week] = true;
        emit Claimed(msg.sender, amount, week);
    }

    function updateClaimList(bytes32 root_) external onlySigners {
        require(frozen);
        
        claimMerkleRoot = root_;
        last_creator = msg.sender;
        isApproved = false;
        updatedClaimList = true;
        
        emit UpdatedClaimList(msg.sender, root_);
    }

    function approveClaimList() external onlySigners {
        require(last_creator != msg.sender, "caller is not available for apporving");
        require(!isApproved, "not available approve");
        require(updatedClaimList, "not updated claim list");

        frozen = false;
        isApproved = true;
        updatedClaimList = false;

        emit ApprovedClaimList(msg.sender);
    }

    function clearClaimList() external onlySigners {
        delete claimMerkleRoot;
        frozen = false;

        emit DeclinedClaimList(msg.sender);
    }

    function freeze() external onlySigners {
        frozen = true;
    }

    function unfreeze() external onlySigners {
        frozen = false;
    }

    function deposit(uint256 amount) external payable {
        require(msg.value >= amount);
        emit Deposited(msg.sender, amount);
    }

    function newWithdrawRequest(address to, uint256 amount) external onlySigners {
        require(amount > 0, "withdraw amount must be greater than zero");
        require(to != address(0), "withdraw not allow to empty address");

        withdrawRequest = WithdrawStruct({
            creator: msg.sender,
            to: to,
            amount: amount,
            isActive: true
        });

    }

    function approveWithdrawRequest() external onlySigners {
        require(withdrawRequest.isActive, "withdraw is not requested");
        require(withdrawRequest.creator != msg.sender, "caller is not available to approve");

        (bool sent, ) = payable(withdrawRequest.to).call{value: withdrawRequest.amount}("");

        require(sent, "Failure! Not withdraw");

        withdrawRequest.isActive = false;
        emit Withdraw(msg.sender, withdrawRequest.creator, withdrawRequest.to, withdrawRequest.amount);
    }

    function declineWithdrawRequest() external onlySigners {
        require(!withdrawRequest.isActive, "withdraw is not requested");

        withdrawRequest.isActive = false;
    }

    function increaseWeek() external onlySigners {
        week ++;
    }

    function decreaseWeek() external onlySigners {
        require(week > 0 ,"can't decrease");
        week --;
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