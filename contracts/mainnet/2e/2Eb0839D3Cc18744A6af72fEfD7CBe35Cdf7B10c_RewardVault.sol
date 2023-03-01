// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;
pragma experimental ABIEncoderV2 ;

import "@openzeppelin/contracts//utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/TransferHelper.sol";
import "./DelegateInterface.sol";
import "./Adminable.sol";

contract RewardVault is DelegateInterface, Adminable, ReentrancyGuard {

    using TransferHelper for IERC20;

    event TrancheAdded (uint256 tranchId, uint64 startTime, uint64 endTime, uint64 expireTime, uint256 total, address provider, IERC20 token, uint128 ruleFlag);
    event TrancheUpdated (uint256 tranchId, uint64 startTime, uint64 endTime, uint64 expireTime, uint256 add);
    event RewardsRecycled (uint256 tranchId, uint256 share);
    event RewardClaimed (uint256 tranchId, address account, uint256 share);
    event TaxFundWithdrawn (IERC20 token, uint256 share);
    event TrancheTreeSet (uint256 tranchId, uint256 unDistribute, uint256 distribute, uint256 tax, bytes32 merkleRoot);

    struct Tranche {
        bytes32 merkleRoot;
        uint64 startTime;
        uint64 endTime;
        uint64 expireTime;
        uint256 total;
        uint256 tax;
        uint256 unDistribute;
        uint256 recycled;
        uint256 claimed;
        address provider;
        IERC20 token;
    }

    mapping(uint256 => Tranche) public tranches;
    // Record of whether user claimed the reward.
    mapping(uint256 => mapping(address => bool)) public claimed;
    // Stored tax fund of all token.
    mapping(IERC20 => uint256) public taxFund;
    // Stored share of all token.
    mapping(IERC20 => uint) public totalShare;
    uint256 public trancheIdx;
    uint64 public defaultExpireDuration;
    address public distributor;

    address private constant _ZERO_ADDRESS = address(0);
    bytes32 private constant _INIT_MERKLE_ROOT = 0x0;
    bytes32 private constant _NO_MERKLE_ROOT = 0x0000000000000000000000000000000000000000000000000000000000000001;

    constructor (){}

    function initialize(address payable _admin, address _distributor, uint64 _defaultExpireDuration) public {
        require(_defaultExpireDuration > 0, "Incorrect inputs");
        admin = _admin;
        distributor = _distributor;
        defaultExpireDuration = _defaultExpireDuration;
    }

    /// @notice reward can supply by anyone.
    /// @dev If token has a tax rate, the actual received will be used.
    /// @param total Provide token amount.
    /// @param startTime The time of distribution rewards begins.
    /// @param endTime The time of distribution rewards ends.
    /// @param ruleFlag Flag corresponds to the rules of reward distribution.
    function newTranche(uint256 total, IERC20 token, uint64 startTime, uint64 endTime, uint128 ruleFlag) external payable {
        require(startTime > block.timestamp && endTime > startTime && total > 0 && ruleFlag > 0, "Incorrect inputs");
        uint256 _transferIn = transferIn(msg.sender, token, total);
        uint256 _trancheId = ++ trancheIdx;
        uint64 expireTime = endTime + defaultExpireDuration;
        tranches[_trancheId] = Tranche(_INIT_MERKLE_ROOT, startTime, endTime, expireTime, _transferIn, 0, 0, 0, 0, msg.sender, token);
        emit TrancheAdded(_trancheId, startTime, endTime, expireTime, _transferIn, msg.sender, token, ruleFlag);
    }

    /// @notice Only provider can update tranche info before the time start.
    /// @dev If token has a tax rate, the actual received will be used.
    /// @param startTime The time of distribution rewards begins.
    /// @param endTime The time of distribution rewards ends.
    /// @param add Added token amount.
    function updateTranche(uint256 _trancheId, uint64 startTime, uint64 endTime, uint256 add) external payable {
        Tranche storage tranche = tranches[_trancheId];
        require(tranche.provider == msg.sender, "No permission");
        require(block.timestamp < tranche.startTime, 'Already started');
        require(startTime > block.timestamp && endTime > startTime, 'Incorrect inputs');
        uint256 _transferIn;
        if (add > 0){
            _transferIn = transferIn(msg.sender, tranche.token, add);
            tranche.total = tranche.total + _transferIn;
        }
        tranche.startTime = startTime;
        tranche.endTime = endTime;
        tranche.expireTime = endTime + defaultExpireDuration;
        emit TrancheUpdated(_trancheId, startTime, endTime, tranche.expireTime, _transferIn);
    }

    /// @notice Only the reward provider can recycle the undistributed rewards and unclaimed rewards.
    function recyclingReward(uint256 _trancheId) external nonReentrant {
        (IERC20 token, uint share) = calRecycling(_trancheId);
        transferOut(msg.sender, token, share);
    }

    /// @notice Recycling the undistributed rewards for multiple tranches.
    /// @param _trancheIds to recycle, required to be sorted by distributing token addresses.
    function recyclingRewards(uint256[] calldata _trancheIds) external nonReentrant{
        uint256 len = _trancheIds.length;
        require(len > 0, "Incorrect inputs");
        IERC20 prevToken;
        uint256 prevShare;
        for (uint256 i = 0; i < len; i ++) {
            (IERC20 token, uint share) = calRecycling(_trancheIds[i]);
            if (prevToken != token && prevShare > 0){
                transferOut(msg.sender, prevToken, prevShare);
                prevShare = 0;
            }
            prevShare = prevShare + share;
            prevToken = token;
        }
        transferOut(msg.sender, prevToken, prevShare);
    }

    /// @notice Users can claim the reward.
    function claim(uint256 _trancheId, uint256 _share, bytes32[] calldata _merkleProof) external nonReentrant {
        IERC20 token = calClaim(_trancheId, _share, _merkleProof);
        transferOut(msg.sender, token, _share);
    }

    function claims(uint256[] calldata _trancheIds, uint256[] calldata _shares, bytes32[][] calldata _merkleProofs) external nonReentrant {
        uint256 len = _trancheIds.length;
        require(len > 0 && len == _shares.length && len == _merkleProofs.length, "Incorrect inputs");
        IERC20 prevToken;
        uint256 prevShare;
        for (uint256 i = 0; i < len; i ++) {
            IERC20 token = calClaim(_trancheIds[i], _shares[i], _merkleProofs[i]);
            if (prevToken != token && prevShare > 0){
                transferOut(msg.sender, prevToken, prevShare);
                prevShare = 0;
            }
            prevShare = prevShare + _shares[i];
            prevToken = token;
        }
        transferOut(msg.sender, prevToken, prevShare);
    }

    function verifyClaim(address account, uint256 _trancheId, uint256 _share, bytes32[] calldata _merkleProof) external view returns (bool valid) {
        return _verifyClaim(account, tranches[_trancheId].merkleRoot, _share, _merkleProof);
    }

    function setExpireDuration(uint64 _defaultExpireDuration) external onlyAdmin {
        require (_defaultExpireDuration > 0, "Incorrect inputs");
        defaultExpireDuration = _defaultExpireDuration;
    }

    function setDistributor(address _distributor) external onlyAdmin {
        distributor = _distributor;
    }

    /// @notice Only the distributor can set the tranche reward distribute info.
    /// @dev If the reward is not distributed for some reason, the merkle root will be set with 1.
    /// @param _undistributed The reward of not distributed.
    /// @param _distributed The reward of distributed.
    /// @param _tax tax fund to admin.
    /// @param _merkleRoot reward tree info.
    function setTrancheTree(uint256 _trancheId, uint256 _undistributed, uint256 _distributed, uint256 _tax, bytes32 _merkleRoot) external {
        require(msg.sender == distributor, "caller must be distributor");
        Tranche storage tranche = tranches[_trancheId];
        require(tranche.endTime < block.timestamp, 'Not end');
        require(_undistributed + _distributed + _tax == tranche.total, 'Incorrect inputs');
        tranche.unDistribute = _undistributed;
        tranche.merkleRoot = _merkleRoot;
        tranche.tax = _tax;
        taxFund[tranche.token] = taxFund[tranche.token] + _tax;
        emit TrancheTreeSet(_trancheId, _undistributed, _distributed, _tax, _merkleRoot);
    }

    /// @notice Only admin can withdraw the tax fund.
    function withdrawTaxFund(IERC20 token, address payable receiver) external onlyAdmin {
        _withdrawTaxFund(token, receiver);
    }

    function withdrawTaxFunds(IERC20[] calldata tokens, address payable receiver) external onlyAdmin {
        uint len = tokens.length;
        for (uint256 i = 0; i < len; i ++) {
            _withdrawTaxFund(tokens[i], receiver);
        }
    }

    function calRecycling(uint256 _trancheId) private returns (IERC20 token, uint share) {
        Tranche storage tranche = tranches[_trancheId];
        require(tranche.provider == msg.sender, "No permission");
        require(tranche.merkleRoot != _INIT_MERKLE_ROOT, "Not start");
        uint recycling = tranche.unDistribute;
        uint distributed = tranche.total - tranche.unDistribute - tranche.tax;
        // can recycle expire
        if (block.timestamp >= tranche.expireTime && distributed > tranche.claimed){
            recycling = recycling + distributed - tranche.claimed;
        }
        recycling = recycling - tranche.recycled;
        require(recycling > 0, "Invalid amount");
        tranche.recycled = tranche.recycled + recycling;
        emit RewardsRecycled(_trancheId, recycling);
        return (tranche.token, recycling);
    }

    function calClaim(uint256 _trancheId, uint256 _share, bytes32[] memory _merkleProof) private returns(IERC20 token) {
        Tranche storage tranche = tranches[_trancheId];
        require(tranche.merkleRoot != _INIT_MERKLE_ROOT, "Not start");
        require(tranche.merkleRoot != _NO_MERKLE_ROOT, "No Reward");
        require(tranche.expireTime > block.timestamp, "Expired");
        require(!claimed[_trancheId][msg.sender], "Already claimed");
        require(_verifyClaim(msg.sender, tranche.merkleRoot, _share, _merkleProof), "Incorrect merkle proof");
        claimed[_trancheId][msg.sender] = true;
        tranche.claimed = tranche.claimed + _share;
        emit RewardClaimed(_trancheId, msg.sender, _share);
        return tranche.token;
    }

    function _verifyClaim(address account, bytes32 root, uint256 _share, bytes32[] memory _merkleProof) private pure returns (bool valid) {
        bytes32 leaf = keccak256(abi.encodePacked(account, _share));
        return MerkleProof.verify(_merkleProof, root, leaf);
    }

    function _withdrawTaxFund(IERC20 token, address payable receiver) private {
        uint withdrawable = taxFund[token];
        require(withdrawable > 0, "Not enough");
        delete taxFund[token];
        transferOut(receiver, token, withdrawable);
        emit TaxFundWithdrawn(token, withdrawable);
    }

    function transferIn(address from, IERC20 token, uint amount) private returns(uint share) {
        if (isNativeToken(token)) {
            require(msg.value == amount, "Not enough");
            share = amount;
        } else {
            uint beforeBalance = token.balanceOf(address(this));
            uint receivedAmount = token.safeTransferFrom(from, address(this), amount);
            share = amountToShare(receivedAmount, beforeBalance, totalShare[token]);
            require(share > 0, "Not enough");
            totalShare[token] = totalShare[token] + share;
        }
    }

    function transferOut(address to, IERC20 token, uint share) private {
        if (isNativeToken(token)) {
            (bool success,) = to.call{value : share}("");
            require(success);
        } else {
            uint _totalShare = totalShare[token];
            totalShare[token] = _totalShare - share;
            token.safeTransfer(to, shareToAmount(share, token.balanceOf(address(this)), _totalShare));
        }
    }

    function amountToShare(uint _amount, uint _reserve, uint _totalShare) private pure returns (uint share){
        share = _amount > 0 && _totalShare > 0 && _reserve > 0 ? _totalShare * _amount / _reserve : _amount;
    }

    function shareToAmount(uint _share, uint _reserve, uint _totalShare) private pure returns (uint amount){
        if (_share > 0 && _totalShare > 0 && _reserve > 0) {
            amount = _reserve * _share / _totalShare;
        }
    }

    function isNativeToken(IERC20 token) private pure returns (bool) {
        return (address(token) == _ZERO_ADDRESS);
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TransferHelper
 * @dev Wrappers around ERC20 operations that returns the value received by recipent and the actual allowance of approval.
 * To use this library you can add a `using TransferHelper for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library TransferHelper {
    function safeTransfer(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) internal returns (uint256 amountReceived) {
        if (_amount > 0) {
            bool success;
            uint256 balanceBefore = _token.balanceOf(_to);
            (success, ) = address(_token).call(abi.encodeWithSelector(_token.transfer.selector, _to, _amount));
            require(success, "TF");
            uint256 balanceAfter = _token.balanceOf(_to);
            require(balanceAfter > balanceBefore, "TF");
            amountReceived = balanceAfter - balanceBefore;
        }
    }

    function safeTransferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256 amountReceived) {
        if (_amount > 0) {
            bool success;
            uint256 balanceBefore = _token.balanceOf(_to);
            (success, ) = address(_token).call(abi.encodeWithSelector(_token.transferFrom.selector, _from, _to, _amount));
            require(success, "TFF");
            uint256 balanceAfter = _token.balanceOf(_to);
            require(balanceAfter > balanceBefore, "TFF");
            amountReceived = balanceAfter - balanceBefore;
        }
    }

    function safeApprove(
        IERC20 _token,
        address _spender,
        uint256 _amount
    ) internal returns (uint256) {
        bool success;
        if (_token.allowance(address(this), _spender) != 0) {
            (success, ) = address(_token).call(abi.encodeWithSelector(_token.approve.selector, _spender, 0));
            require(success, "AF");
        }
        (success, ) = address(_token).call(abi.encodeWithSelector(_token.approve.selector, _spender, _amount));
        require(success, "AF");

        return _token.allowance(address(this), _spender);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

contract DelegateInterface {
    /**
     * Implementation address for this contract
     */
    address public implementation;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

abstract contract Adminable {
    address payable public admin;
    address payable public pendingAdmin;
    address payable public developer;

    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() {
        developer = payable(msg.sender);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "caller must be admin");
        _;
    }
    modifier onlyAdminOrDeveloper() {
        require(msg.sender == admin || msg.sender == developer, "caller must be admin or developer");
        _;
    }

    function setPendingAdmin(address payable newPendingAdmin) external virtual onlyAdmin {
        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;
        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;
        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function acceptAdmin() external virtual {
        require(msg.sender == pendingAdmin, "only pendingAdmin can accept admin");
        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;
        // Store admin with value pendingAdmin
        admin = payable(oldPendingAdmin);
        // Clear the pending value
        pendingAdmin = payable(0);
        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
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