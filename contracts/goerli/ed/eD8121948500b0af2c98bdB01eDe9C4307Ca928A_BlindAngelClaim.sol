// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.0;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract BlindAngelClaim is Ownable {

    bytes32 public claimMerkleRoot;
    IERC721 public nft;

    struct WithdrawStruct {
        address creator;
        address to;
        uint256 amount;
        bool isActive;
    }

    struct SignerRequest {
        address createdBy;
        address signer;
        bool status;
        bool isActive;
    }

    struct AdminExist {
        uint256 index;
        bool status;
    }

    struct ClaimRootRequest {
        address createdBy;
        bytes32 root;
        bool isActive;
    }

    event Claimed(address indexed from, uint256 indexed amount, uint256 week);
    event UpdatedClaimList(address indexed updator, bytes32 root_);
    event ApprovedClaimList(address indexed dealer);
    event DeclinedClaimList(address indexed dealer);
    event Deposit(address indexed dealer, uint256 amount);
    event AddSigner(address indexed dealer, address indexed creator, address signer);
    event RemoveSigner(address indexed dealer, address indexed creator, address signer);
    event Withdraw(address indexed dealer, address indexed creator, address to, uint256 amount);

    address[] public admins;
    mapping(address => AdminExist) public adminsExist;
    mapping(address => mapping(uint256 => bool)) public claimed;

    address private last_creator;
    bool public frozen;
    bool private isApproved;
    bool private updatedClaimList;
    uint256 public week;

    WithdrawStruct public withdrawRequest;
    SignerRequest public signerRequest;
    ClaimRootRequest public claimRootRequest;

    modifier onlySigners() {
        require(adminsExist[msg.sender].status, "not signer");
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
        require(_owners.length > 1, "Signer is 2 at least." );
        for (uint256 i = 0; i < _owners.length; i ++) {
            admins.push(_owners[i]);
            adminsExist[_owners[i]] = AdminExist(i, true);
        }
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

    function newClaimListRequest(bytes32 root_) external onlySigners {
        require(frozen);

        claimRootRequest = ClaimRootRequest(msg.sender, root_, true);
        
        emit UpdatedClaimList(msg.sender, root_);
    }

    function approveClaimListRequest() external onlySigners {
        require(frozen);
        require(claimRootRequest.createdBy != msg.sender, "caller is not available to approve");
        require(claimRootRequest.isActive, "request is not created");

        claimMerkleRoot = claimRootRequest.root;

        emit ApprovedClaimList(msg.sender);
    }

    function declineClaimListRequest() external onlySigners {
        require(claimRootRequest.isActive, "request is not created");

        delete claimRootRequest;

        emit DeclinedClaimList(msg.sender);
    }

    function clearClaimList() external onlySigners {
        delete claimMerkleRoot;
        frozen = false;
    }

    function freeze() external onlySigners {
        frozen = true;
    }

    function unfreeze() external onlySigners {
        frozen = false;
    }

    function deposit() external payable {
        require(msg.value > 0, "insufficient funds");
        emit Deposit(msg.sender, msg.value);
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
        require(withdrawRequest.isActive, "withdraw is not requested");

        withdrawRequest.isActive = false;
    }

    function increaseWeek() external onlySigners {
        week ++;
    }

    function decreaseWeek() external onlySigners {
        require(week > 0 ,"can't decrease");
        week --;
    }

     function newSignerRequest(address signer, bool status) public onlySigners {
        require(signer != msg.sender, "can't request self address");
        require(signer != address(0), "invalid address");

        if (adminsExist[signer].status == status) {
            if (status) revert("signer is already existed");
            else revert("signer is not existed");
        }

        if (!status) {
            require(admins.length > 2, "admin count is 2 at least");
        }

        signerRequest = SignerRequest({
            createdBy: msg.sender,
            signer: signer,
            isActive: true,
            status: status
        });

    }
    
    function declineSignerRequest() public onlySigners {
        require(signerRequest.isActive);
        
        signerRequest.isActive = false;
    }

    function approveSignerRequest() public onlySigners {
        require(signerRequest.isActive);
        require(signerRequest.createdBy != msg.sender, "can't approve transaction you created");
        
        address signer = signerRequest.signer;
        if (signerRequest.status) {
            admins.push(signer);
            adminsExist[signer] = AdminExist(admins.length - 1, true);
            emit AddSigner(msg.sender, signerRequest.createdBy, signer);
        } else {
            uint256 index = adminsExist[signer].index;
            if (index != admins.length - 1) {
                admins[index] = admins[admins.length -1];
                adminsExist[admins[index]].index = index;
            }
            admins.pop();
            emit RemoveSigner(msg.sender, signerRequest.createdBy, signer);
            delete adminsExist[signer];
        }

        signerRequest.isActive = false;
    }

    function getAdmins() public view returns(address[] memory) {
        return admins;
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