// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./SeedGroup.sol";
import "./SimpleRollingGroup.sol";
import "./CustomRollingGroup.sol";
import "./CustomGroup.sol";

contract DistributeFactory is Ownable, ReentrancyGuard {
    struct Group {
        uint96 groupType;
        address groupContractAddress;
    }

    Group[] private _groups;

    IERC20 public immutable token;
    
    uint256 public constant SEED_GROUP = 1;
    uint256 public constant SIMPLE_ROLLING_GROUP = 2;
    uint256 public constant CUSTOM_ROLLING_GROUP = 3;
    uint256 public constant CUSTOM_GROUP = 4;

    constructor(address token_) {
        token = IERC20(token_);
    }

    /* ========== Add Groups ============= */
    function addSeedGroup(
        uint256 groupIndex,
        bytes32 merkleRoot_,
        uint256[] memory pDates,
        uint256[] memory percentages,
        bool isOpen_
    ) external onlyOwner {
        require(groupIndex == _groups.length, "SeedGroup Add: Invalid groupIndex");

        SeedGroup groupContract = new SeedGroup(merkleRoot_, pDates, percentages, isOpen_);
        Group memory group = Group(uint96(SEED_GROUP), address(groupContract));

        _groups.push(group);

        emit SeedGroupAdded(merkleRoot_, pDates, percentages, isOpen_, address(groupContract));
    }

    function addSimpleRollingGroup(
        uint256 groupIndex,
        bytes32 merkleRoot_,
        uint256 period_,
        uint256 percentage_,
        bool isOpen_
    ) external onlyOwner {
        require(groupIndex == _groups.length, "SimpleRollingGroup Add: Invalid groupIndex");

        SimpleRollingGroup groupContract = new SimpleRollingGroup(merkleRoot_, period_, percentage_, isOpen_);
        Group memory group = Group(uint96(SIMPLE_ROLLING_GROUP), address(groupContract));

        _groups.push(group);

        emit SimpleRollingGroupAdded(merkleRoot_, period_, percentage_, isOpen_, address(groupContract));
    }

    function addCustomRollingGroup(
        uint256 groupIndex,
        bytes32 merkleRoot_,
        bool isOpen_
    ) external onlyOwner {
        require(groupIndex == _groups.length, "SimpleRollingGroup Add: Invalid groupIndex");

        CustomRollingGroup groupContract = new CustomRollingGroup(merkleRoot_, isOpen_);
        Group memory group = Group(uint96(CUSTOM_ROLLING_GROUP), address(groupContract));

        _groups.push(group);

        emit CustomRollingGroupAdded(merkleRoot_, isOpen_, address(groupContract));
    }

    function addCustomGroup(
        uint256 groupIndex,
        bytes32 merkleRoot_,
        bool isOpen_
    ) external onlyOwner {
        require(groupIndex == _groups.length, "CustomGroup Add: Invalid groupIndex");

        CustomGroup groupContract = new CustomGroup(merkleRoot_, isOpen_);
        Group memory group = Group(uint96(CUSTOM_GROUP), address(groupContract));

        _groups.push(group);

        emit CustomGroupAdded(merkleRoot_, isOpen_, address(groupContract));
    }

    /* ============= Claim ============ */
    function claimSeedGroup(uint256 groupIndex, address receiverAddress, uint256 amount, bytes32[] calldata merkleProof) external nonReentrant {
        Group memory groupInfo = _getGroupInfo(groupIndex, SEED_GROUP);

        SeedGroup groupContract = SeedGroup(groupInfo.groupContractAddress);
        bytes32 merkleRoot = groupContract.merkleRoot();

        // Verify merkle proof
        bytes32 node = keccak256(abi.encodePacked(groupIndex, receiverAddress, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "SeedGroup Claim: Invalid proof."
        );

        (uint256 lastPaidDate, uint256 claimable) = groupContract.claimableAmount(receiverAddress, amount);

        require(claimable > 0, "SeedGroup Claim: No claimable amount");
        require(token.balanceOf(address(this)) >= claimable, "SeedGroup Claim: Distributor has not enough balance");

        groupContract.updateUserDistribute(receiverAddress, lastPaidDate, claimable);
        token.transfer(receiverAddress, claimable);

        emit SeedGroupClaimed(groupInfo.groupContractAddress, receiverAddress, claimable, lastPaidDate);
    }

    function claimSimpleRollingGroup(uint256 groupIndex, address receiverAddress, uint256 amount, uint256 startDate, bytes32[] calldata merkleProof) external nonReentrant {
        Group memory groupInfo = _getGroupInfo(groupIndex, SIMPLE_ROLLING_GROUP);

        SimpleRollingGroup groupContract = SimpleRollingGroup(groupInfo.groupContractAddress);
        bytes32 merkleRoot = groupContract.merkleRoot();

        // Verify merkle proof
        bytes32 node = keccak256(abi.encodePacked(groupIndex, receiverAddress, amount, startDate));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "SimpleRollingGroup Claim: Invalid proof."
        );

        (uint256 lastPaidDate, uint256 claimable) = groupContract.claimableAmount(receiverAddress, amount, startDate);

        require(claimable > 0, "SimpleRollingGroup Claim: No claimable amount");
        require(token.balanceOf(address(this)) >= claimable, "SimpleRollingGroup Claim: Distributor has not enough balance");

        groupContract.updateUserDistribute(receiverAddress, lastPaidDate, claimable);
        token.transfer(receiverAddress, claimable);

        emit SimpleRollingGroupClaimed(groupInfo.groupContractAddress, receiverAddress, claimable, startDate, lastPaidDate);
    }

    function claimCustomRollingGroup(uint256 groupIndex, address receiverAddress, uint256 amount, uint256 startDate, uint256 period, uint256 percentage, bytes32[] calldata merkleProof) external nonReentrant {
        Group memory groupInfo = _getGroupInfo(groupIndex, CUSTOM_ROLLING_GROUP);

        CustomRollingGroup groupContract = CustomRollingGroup(groupInfo.groupContractAddress);
        bytes32 merkleRoot = groupContract.merkleRoot();

        // Verify merkle proof
        bytes32 node = keccak256(abi.encodePacked(groupIndex, receiverAddress, amount, startDate, period, percentage));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "CustomRollingGroup Claim: Invalid proof."
        );

        (uint256 lastPaidDate, uint256 claimable) = groupContract.claimableAmount(receiverAddress, amount, startDate, period, percentage);

        require(claimable > 0, "CustomRollingGroup Claim: No claimable amount");
        require(token.balanceOf(address(this)) >= claimable, "CustomRollingGroup Claim: Distributor has not enough balance");

        groupContract.updateUserDistribute(receiverAddress, lastPaidDate, claimable);
        token.transfer(receiverAddress, claimable);

        emit CustomRollingGroupClaimed(groupInfo.groupContractAddress, receiverAddress, claimable, startDate, period, percentage, lastPaidDate);
    }

    function claimCustomGroup(uint256 groupIndex, address receiverAddress, uint256 amount, uint256[] memory dates, uint256[] memory percentages, bytes32[] calldata merkleProof) external nonReentrant {
        Group memory groupInfo = _getGroupInfo(groupIndex, CUSTOM_GROUP);

        CustomGroup groupContract = CustomGroup(groupInfo.groupContractAddress);
        bytes32 merkleRoot = groupContract.merkleRoot();

        // Verify merkle proof
        bytes32 node = keccak256(abi.encodePacked(groupIndex, receiverAddress, amount, dates, percentages));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "CustomGroup Claim: Invalid proof."
        );

        (uint256 lastPaidDate, uint256 claimable) = groupContract.claimableAmount(receiverAddress, amount, dates, percentages);

        require(claimable > 0, "CustomGroup Claim: No claimable amount");
        require(token.balanceOf(address(this)) >= claimable, "CustomGroup Claim: Distributor has not enough balance");

        groupContract.updateUserDistribute(receiverAddress, lastPaidDate, claimable);
        token.transfer(receiverAddress, claimable);

        emit CustomGroupClaimed(groupInfo.groupContractAddress, receiverAddress, claimable, dates, percentages, lastPaidDate);
    }

    /* ============ Internals ========== */
    function _getGroupInfo(uint256 groupIndex, uint256 groupType) internal view returns(Group memory) {
        Group[] memory groupList = _groups;
        require(groupList.length >= groupIndex, "Distributor: Not exist pool");        

        Group memory groupInfo = groupList[groupIndex];
        require(groupInfo.groupType == groupType, "Distributor: Group does not match with groupType");

        return groupInfo;
    }

    /* ============ Read ================*/
    function groups() external view returns (Group[] memory) {
        return _groups;
    }

    /* ========== EVENTS ========== */

    event SeedGroupAdded(bytes32 merkleRoot_, uint256[] pDates, uint256[] percentages, bool isOpen, address groupContractAddress);
    event SeedGroupClaimed(address poolAddress, address receiverAddress, uint256 claimedAmount, uint256 paidDistributeDate);

    event SimpleRollingGroupAdded(bytes32 merkleRoot_, uint256 period, uint256 percentage, bool isOpen, address groupContractAddress);
    event SimpleRollingGroupClaimed(address poolAddress, address receiverAddress, uint256 claimedAmount, uint256 startDate, uint256 paidDistributeDate);

    event CustomRollingGroupAdded(bytes32 merkleRoot_, bool isOpen, address groupContractAddress);
    event CustomRollingGroupClaimed(address poolAddress, address receiverAddress, uint256 claimedAmount, uint256 startDate, uint256 period, uint256 percentage, uint256 paidDistributeDate);

    event CustomGroupAdded(bytes32 merkleRoot_, bool isOpen, address groupContractAddress);
    event CustomGroupClaimed(address poolAddress, address receiverAddress, uint256 claimedAmount, uint256[] dates, uint256[] percentages, uint256 paidDistributeDate);
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
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./BaseGroup.sol";

contract SeedGroup is BaseGroup {
    struct DistStage {
        uint160 distDate;
        uint96 percentage;
    }

    DistStage[] private _stages;

    constructor(bytes32 merkleRoot_, uint256[] memory pDates, uint256[] memory percentages, bool isOpen_) BaseGroup(merkleRoot_, isOpen_) {
        require(
            pDates.length > 0 &&
                percentages.length > 0 &&
                pDates.length == percentages.length,
            "SeedGroup: Invalid init values"
        );

        uint256 totalPercentage = 0;

        for (uint256 i = 0; i < pDates.length; i++) {
            DistStage memory stage = DistStage(
                uint160(pDates[i]),
                uint96(percentages[i])
            );
            totalPercentage += percentages[i];
            _stages.push(stage);
        }

        require(
            totalPercentage == PERCENT_DENOMINATOR,
            "SeedGroup: Invalid percentage values"
        );
    }

    function claimableAmount(address receiverAddress, uint256 amount) external view returns(uint256 lastPaidDate, uint256 claimable) {
        DistStage[] memory stageList = _stages;

        uint256 currentTime = block.timestamp;

        uint256 claimablePercentage = 0;

        for(uint256 i = 0; i < stageList.length; i++) {
            if (currentTime >= stageList[i].distDate) {
                if (stageList[i].distDate > userLastPaidDate[receiverAddress]) {
                    claimablePercentage += stageList[i].percentage;
                    lastPaidDate = stageList[i].distDate;
                }
            }
        }

        if (lastPaidDate == stageList[stageList.length - 1].distDate) {
            claimable = amount - userClaimedAmount[receiverAddress];
        } else {
            claimable = amount * claimablePercentage / PERCENT_DENOMINATOR;
        }
    }

    function stages() external view returns(DistStage[] memory) {
        return _stages;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./RollingGroup.sol";

contract SimpleRollingGroup is RollingGroup {
   
    uint256 public immutable period;
    uint256 public immutable percentage;

    constructor(bytes32 merkleRoot_, uint256 period_, uint256 percentage_, bool isOpen_) RollingGroup(merkleRoot_, isOpen_) {
        require(period_ > 0 && percentage_ <= PERCENT_DENOMINATOR, "SimpleRollingGroup: Invalid init values");
      
        period = period_;
        percentage = percentage_;
    }

    function claimableAmount(address receiverAddress, uint256 amount, uint256 startDate) external view returns(uint256 lastPaidDate, uint256 claimable) {
        (lastPaidDate, claimable) = _claimableAmount(receiverAddress, amount, startDate, period, percentage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./RollingGroup.sol";

contract CustomRollingGroup is RollingGroup {
   
    constructor(bytes32 merkleRoot_, bool isOpen_) RollingGroup(merkleRoot_, isOpen_) {}

    function claimableAmount(address receiverAddress, uint256 amount, uint256 startDate, uint256 period, uint256 percentage) external view returns(uint256 lastPaidDate, uint256 claimable) {
        require(percentage <= PERCENT_DENOMINATOR, "CustomRollingGroup: invalid percentage");
        (lastPaidDate, claimable) = _claimableAmount(receiverAddress, amount, startDate, period, percentage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./BaseGroup.sol";

contract CustomGroup is BaseGroup {
    constructor(bytes32 merkleRoot_, bool isOpen_) BaseGroup(merkleRoot_, isOpen_) {}

    function claimableAmount(address receiverAddress, uint256 amount, uint256[] memory dates, uint256[] memory percentages) external view returns(uint256 lastPaidDate, uint256 claimable) {
        uint256 currentTime = block.timestamp;

        uint256 claimablePercentage = 0;

        for(uint256 i = 0; i < dates.length; i++) {
            if (currentTime >= dates[i]) {
                if (dates[i] > userLastPaidDate[receiverAddress]) {
                    claimablePercentage += percentages[i];
                    lastPaidDate = dates[i];
                }
            }
        }

        if (lastPaidDate == dates[dates.length - 1]) {
            claimable = amount - userClaimedAmount[receiverAddress];
        } else {
            claimable = amount * claimablePercentage / PERCENT_DENOMINATOR;
        }
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
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseGroup is Ownable {

    bytes32 public merkleRoot;

    mapping(address => uint256) public userClaimedAmount;
    mapping(address => uint256) public userLastPaidDate;
    mapping(address => uint256) public userLastClaimDate;

    bool public immutable isOpen;

    uint256 public constant PERCENT_DENOMINATOR = 10000;

    constructor(bytes32 merkleRoot_, bool isOpen_) {
        merkleRoot = merkleRoot_;
        isOpen = isOpen_;
    }

    function updateUserDistribute(address receiverAddress, uint256 lastPaidDate, uint256 claimable) external onlyOwner() {
        userLastPaidDate[receiverAddress] = lastPaidDate;
        userClaimedAmount[receiverAddress] += claimable;
        userLastClaimDate[receiverAddress] = block.timestamp;
    }

    function updateMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        require(isOpen, "Update Group: Group is not open");
        merkleRoot = merkleRoot_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./BaseGroup.sol";

contract RollingGroup is BaseGroup {
   
    constructor(bytes32 merkleRoot_, bool isOpen_) BaseGroup(merkleRoot_, isOpen_) {}

    function _claimableAmount(address receiverAddress, uint256 amount, uint256 startDate, uint256 period, uint256 percentage) internal view returns(uint256 lastPaidDate, uint256 claimable) {

        uint256 currentTime = block.timestamp;

        if (currentTime < startDate) {
            return (lastPaidDate, claimable);
        }

        uint256 restAmount = amount - userClaimedAmount[receiverAddress];

        if (restAmount == 0) {
            return (lastPaidDate, claimable);
        }

        uint256 passedTimeFromStart = currentTime - startDate;
        uint256 paidCntFromStart =  (passedTimeFromStart / period) + 1;

        if (paidCntFromStart * percentage >= PERCENT_DENOMINATOR) {
            claimable = restAmount;
            lastPaidDate = currentTime;

            return (lastPaidDate, claimable);
        }

        uint256 passedTimeFromLast = userLastPaidDate[receiverAddress] - startDate;
        uint256 paidCntFromLast = (passedTimeFromLast / period) + 1;

        uint256 shouldPaidCnt = paidCntFromStart - paidCntFromLast;

        claimable = (amount * percentage * shouldPaidCnt) / PERCENT_DENOMINATOR;
        lastPaidDate = currentTime;
    }
}