// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "SafeERC20.sol";
import "IERC20.sol";
import "Ownable.sol";

import "ScaledMath.sol";
import "ICNCLockerV2.sol";
import "ICNCToken.sol";
import "ICNCVoteLocker.sol";
import "IController.sol";

contract CNCLockerV2 is ICNCLockerV2, Ownable {
    using SafeERC20 for ICNCToken;
    using SafeERC20 for IERC20;
    using ScaledMath for uint256;
    using ScaledMath for uint128;
    using MerkleProof for MerkleProof.Proof;

    address public constant V1_LOCKER = address(0x3F41480DD3b32F1cC579125F9570DCcD07E07667);

    uint128 internal constant _MIN_LOCK_TIME = 120 days;
    uint128 internal constant _MAX_LOCK_TIME = 240 days;
    uint128 internal constant _GRACE_PERIOD = 28 days;
    uint128 internal constant _MIN_BOOST = 1e18;
    uint128 internal constant _MAX_BOOST = 1.5e18;
    uint128 internal constant _KICK_PENALTY = 1e17;
    uint256 internal constant _MAX_KICK_PENALTY_AMOUNT = 1000e18;
    uint128 constant _AIRDROP_DURATION = 182 days;
    uint256 internal constant _MAX_AIRDROP_BOOST = 3.5e18;

    ICNCToken public immutable cncToken;

    // Boost data
    mapping(address => uint256) public lockedBalance;
    mapping(address => uint256) public lockedBoosted;
    mapping(address => VoteLock[]) public voteLocks;
    mapping(address => uint256) internal _airdroppedBoost;
    mapping(address => bool) public override claimedAirdrop;
    uint64 internal _nextId;
    uint256 public immutable airdropEndTime;
    bytes32 public immutable merkleRoot;
    uint256 public totalLocked;
    uint256 public totalBoosted;
    bool public isShutdown;

    // Fee data
    IERC20 public immutable crv;
    IERC20 public immutable cvx;
    uint256 public accruedFeesIntegralCrv;
    uint256 public accruedFeesIntegralCvx;
    mapping(address => uint256) public perAccountAccruedCrv;
    mapping(address => uint256) public perAccountFeesCrv;
    mapping(address => uint256) public perAccountAccruedCvx;
    mapping(address => uint256) public perAccountFeesCvx;

    address public immutable treasury;
    IController public immutable controller;

    constructor(
        address _controller,
        address _cncToken,
        address _treasury,
        address _crv,
        address _cvx,
        bytes32 _merkleRoot
    ) Ownable() {
        controller = IController(_controller);
        cncToken = ICNCToken(_cncToken);
        treasury = _treasury;
        crv = IERC20(_crv);
        cvx = IERC20(_cvx);
        airdropEndTime = block.timestamp + _AIRDROP_DURATION;
        merkleRoot = _merkleRoot;
    }

    function lock(uint256 amount, uint64 lockTime) external override {
        lock(amount, lockTime, false);
    }

    /// @notice Lock an amount of CNC for vlCNC.
    /// @param amount Amount of CNC to lock.
    /// @param lockTime Duration of the lock.
    /// @param relock_ `True` if this is a relock of an existing lock.
    function lock(
        uint256 amount,
        uint64 lockTime,
        bool relock_
    ) public override {
        lockFor(amount, lockTime, relock_, msg.sender);
    }

    /// @notice Lock an amount of CNC for vlCNC.
    /// @param amount Amount of CNC to lock.
    /// @param lockTime Duration of the lock.
    /// @param relock_ `True` if this is a relock of all existing locks.
    /// @param account The account to receive the vlCNC.
    function lockFor(
        uint256 amount,
        uint64 lockTime,
        bool relock_,
        address account
    ) public override {
        require(!isShutdown, "locker suspended");
        require((_MIN_LOCK_TIME <= lockTime) && (lockTime <= _MAX_LOCK_TIME), "lock time invalid");
        require(!relock_ || msg.sender == account, "relock only for self");
        _feeCheckpoint(account);
        cncToken.safeTransferFrom(msg.sender, address(this), amount);

        uint128 boost = computeBoost(lockTime);

        uint256 airdropBoost_ = airdropBoost(msg.sender);
        if (airdropBoost_ > 1e18) {
            claimedAirdrop[msg.sender] = true;
            boost = boost.mulDownUint128(uint128(airdropBoost_));
            delete _airdroppedBoost[msg.sender];
        }

        uint64 unlockTime = uint64(block.timestamp) + lockTime;
        uint256 boostedAmount;

        if (relock_) {
            uint256 length = voteLocks[account].length;
            for (uint256 i; i < length; i++) {
                require(
                    voteLocks[account][i].unlockTime < unlockTime,
                    "cannot move the unlock time up"
                );
            }
            delete voteLocks[account];
            totalBoosted -= lockedBoosted[account];
            lockedBoosted[account] = 0;
            _addVoteLock(account, lockedBalance[account] + amount, unlockTime, boost);
            boostedAmount = (lockedBalance[account] + amount).mulDown(uint256(boost));
        } else {
            _addVoteLock(account, amount, unlockTime, boost);
            boostedAmount = amount.mulDown(boost);
        }
        totalLocked += amount;
        totalBoosted += boostedAmount;
        lockedBalance[account] += amount;
        lockedBoosted[account] += boostedAmount;
        emit Locked(account, amount, unlockTime, relock_);
    }

    /// @notice Process all expired locks of msg.sender and withdraw unlocked CNC.
    function executeAvailableUnlocks() external override returns (uint256) {
        return executeAvailableUnlocksFor(msg.sender);
    }

    /// @notice Process all expired locks of msg.sender and withdraw unlocked CNC to `dst`.
    function executeAvailableUnlocksFor(address dst) public override returns (uint256) {
        require(dst != address(0), "invalid destination");
        _feeCheckpoint(msg.sender);
        uint256 sumUnlockable;
        uint256 sumBoosted;
        VoteLock[] storage _pending = voteLocks[msg.sender];
        uint256 i = _pending.length;
        while (i > 0) {
            i = i - 1;

            if (isShutdown || _pending[i].unlockTime <= block.timestamp) {
                sumUnlockable += _pending[i].amount;
                sumBoosted += _pending[i].amount.mulDown(_pending[i].boost);
                _pending[i] = _pending[_pending.length - 1];
                _pending.pop();
            }
        }
        totalLocked -= sumUnlockable;
        totalBoosted -= sumBoosted;
        lockedBalance[msg.sender] -= sumUnlockable;
        lockedBoosted[msg.sender] -= sumBoosted;
        cncToken.safeTransfer(dst, sumUnlockable);
        emit UnlockExecuted(msg.sender, sumUnlockable);
        return sumUnlockable;
    }

    /// @notice Process specified locks of msg.sender and withdraw unlocked CNC to `dst`.
    /// @param dst Destination address to receive unlocked CNC.
    /// @param lockIds Array of lock IDs to process.
    /// @return unlocked Amount of CNC unlocked.
    function executeUnlocks(address dst, uint64[] calldata lockIds)
        public
        override
        returns (uint256)
    {
        _feeCheckpoint(msg.sender);
        uint256 sumUnlockable;
        uint256 sumBoosted;
        VoteLock[] storage _pending = voteLocks[msg.sender];
        for (uint256 idIndex; idIndex < lockIds.length; idIndex++) {
            uint256 index = _getLockIndexById(msg.sender, lockIds[idIndex]);
            require(
                isShutdown || _pending[index].unlockTime <= block.timestamp,
                "lock not expired"
            );
            sumUnlockable += _pending[index].amount;
            sumBoosted += _pending[index].amount.mulDown(_pending[index].boost);
            _pending[index] = _pending[_pending.length - 1];
            _pending.pop();
        }
        totalLocked -= sumUnlockable;
        totalBoosted -= sumBoosted;
        lockedBalance[msg.sender] -= sumUnlockable;
        lockedBoosted[msg.sender] -= sumBoosted;
        cncToken.safeTransfer(dst, sumUnlockable);
        emit UnlockExecuted(msg.sender, sumUnlockable);
        return sumUnlockable;
    }

    /// @notice Get unlocked CNC balance for an address
    /// @param user Address to get unlocked CNC balance for
    /// @return Unlocked CNC balance
    function unlockableBalance(address user) public view override returns (uint256) {
        uint256 sumUnlockable = 0;
        VoteLock[] storage _pending = voteLocks[user];
        uint256 length = _pending.length;
        for (uint256 i; i < length; i++) {
            if (_pending[i].unlockTime <= uint128(block.timestamp)) {
                sumUnlockable += _pending[i].amount;
            }
        }
        return sumUnlockable;
    }

    /// @notice Get unlocked boosted CNC balance for an address
    /// @param user Address to get unlocked boosted CNC balance for
    /// @return Unlocked boosted CNC balance
    function unlockableBalanceBoosted(address user) public view override returns (uint256) {
        uint256 sumUnlockable = 0;
        VoteLock[] storage _pending = voteLocks[user];
        uint256 length = _pending.length;
        for (uint256 i; i < length; i++) {
            if (_pending[i].unlockTime <= uint128(block.timestamp)) {
                sumUnlockable += _pending[i].amount.mulDown(_pending[i].boost);
            }
        }
        return sumUnlockable;
    }

    function shutDown() external override onlyOwner {
        require(!isShutdown, "locker already suspended");
        isShutdown = true;
        emit Shutdown();
    }

    function recoverToken(address token) external override {
        require(
            token != address(cncToken) && token != address(crv) && token != address(cvx),
            "cannot withdraw token"
        );
        IERC20 _token = IERC20(token);
        _token.safeTransfer(treasury, _token.balanceOf(address(this)));
        emit TokenRecovered(token);
    }

    /// @notice Relock a specific lock
    /// @dev Users locking CNC can create multiple locks therefore individual locks can be relocked separately.
    /// @param lockId Id of the lock to relock.
    /// @param lockTime Duration for which the locks's CNC amount should be relocked for.
    function relock(uint64 lockId, uint64 lockTime) external override {
        require(!isShutdown, "locker suspended");
        require((_MIN_LOCK_TIME <= lockTime) && (lockTime <= _MAX_LOCK_TIME), "lock time invalid");
        _feeCheckpoint(msg.sender);
        _relock(lockId, lockTime);
    }

    /// @notice Relock specified locks
    /// @param lockIds Ids of the locks to relock.
    /// @param lockTime Duration for which the locks's CNC amount should be relocked for.
    function relockMultiple(uint64[] calldata lockIds, uint64 lockTime) external override {
        require(!isShutdown, "locker suspended");
        require((_MIN_LOCK_TIME <= lockTime) && (lockTime <= _MAX_LOCK_TIME), "lock time invalid");
        _feeCheckpoint(msg.sender);
        for (uint256 i; i < lockIds.length; i++) {
            _relock(lockIds[i], lockTime);
        }
    }

    function _relock(uint64 lockId, uint64 lockTime) internal {
        uint256 lockIndex = _getLockIndexById(msg.sender, lockId);

        uint128 boost = computeBoost(lockTime);

        uint64 unlockTime = uint64(block.timestamp) + lockTime;

        VoteLock[] storage locks = voteLocks[msg.sender];
        require(locks[lockIndex].unlockTime < unlockTime, "cannot move the unlock time up");
        uint256 amount = locks[lockIndex].amount;
        uint256 previousBoostedAmount = locks[lockIndex].amount.mulDown(locks[lockIndex].boost);
        locks[lockIndex] = locks[locks.length - 1];
        locks.pop();

        _addVoteLock(msg.sender, amount, unlockTime, boost);
        uint256 boostedAmount = amount.mulDown(boost);

        totalBoosted = totalBoosted + boostedAmount - previousBoostedAmount;
        lockedBoosted[msg.sender] =
            lockedBoosted[msg.sender] +
            boostedAmount -
            previousBoostedAmount;

        emit Relocked(msg.sender, amount);
    }

    function relock(uint64 lockTime) external override {
        require(!isShutdown, "locker suspended");
        require((_MIN_LOCK_TIME <= lockTime) && (lockTime <= _MAX_LOCK_TIME), "lock time invalid");
        _feeCheckpoint(msg.sender);

        uint128 boost = computeBoost(lockTime);

        uint64 unlockTime = uint64(block.timestamp) + lockTime;

        uint256 length = voteLocks[msg.sender].length;
        for (uint256 i; i < length; i++) {
            require(
                voteLocks[msg.sender][i].unlockTime < unlockTime,
                "cannot move the unlock time up"
            );
        }
        delete voteLocks[msg.sender];
        totalBoosted -= lockedBoosted[msg.sender];
        lockedBoosted[msg.sender] = 0;
        _addVoteLock(msg.sender, lockedBalance[msg.sender], unlockTime, boost);
        uint256 boostedAmount = lockedBalance[msg.sender].mulDown(uint256(boost));
        totalBoosted += boostedAmount;
        lockedBoosted[msg.sender] += boostedAmount;
        emit Relocked(msg.sender, lockedBalance[msg.sender]);
    }

    /// @notice Kick an expired lock
    function kick(address user, uint64 lockId) external override {
        uint256 lockIndex = _getLockIndexById(user, lockId);
        VoteLock[] storage _pending = voteLocks[user];
        require(
            _pending[lockIndex].unlockTime + _GRACE_PERIOD <= uint128(block.timestamp),
            "cannot kick this lock"
        );
        _feeCheckpoint(user);
        uint256 amount = _pending[lockIndex].amount;
        totalLocked -= amount;
        totalBoosted -= amount.mulDown(_pending[lockIndex].boost);
        lockedBalance[user] -= amount;
        lockedBoosted[user] -= amount.mulDown(_pending[lockIndex].boost);
        uint256 kickPenalty = amount.mulDown(_KICK_PENALTY);
        if (kickPenalty > _MAX_KICK_PENALTY_AMOUNT) {
            kickPenalty = _MAX_KICK_PENALTY_AMOUNT;
        }
        cncToken.safeTransfer(user, amount - kickPenalty);
        cncToken.safeTransfer(msg.sender, kickPenalty);
        emit KickExecuted(user, msg.sender, amount);
        _pending[lockIndex] = _pending[_pending.length - 1];
        _pending.pop();
    }

    function receiveFees(uint256 amountCrv, uint256 amountCvx) external override {
        crv.safeTransferFrom(msg.sender, address(this), amountCrv);
        cvx.safeTransferFrom(msg.sender, address(this), amountCvx);
        accruedFeesIntegralCrv += amountCrv.divDown(totalBoosted);
        accruedFeesIntegralCvx += amountCvx.divDown(totalBoosted);
        emit FeesReceived(msg.sender, amountCrv, amountCvx);
    }

    function claimFees() external override returns (uint256 crvAmount, uint256 cvxAmount) {
        _feeCheckpoint(msg.sender);
        crvAmount = perAccountFeesCrv[msg.sender];
        cvxAmount = perAccountFeesCvx[msg.sender];
        crv.safeTransfer(msg.sender, crvAmount);
        cvx.safeTransfer(msg.sender, cvxAmount);
        perAccountFeesCrv[msg.sender] = 0;
        perAccountFeesCvx[msg.sender] = 0;
        emit FeesClaimed(msg.sender, crvAmount, cvxAmount);
    }

    function claimAirdropBoost(uint256 amount, MerkleProof.Proof calldata proof) external override {
        require(block.timestamp < airdropEndTime, "airdrop ended");
        require(!claimedAirdrop[msg.sender], "already claimed");
        require(amount <= _MAX_AIRDROP_BOOST, "amount exceeds max airdrop boost");
        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount));
        require(proof.isValid(node, merkleRoot), "invalid proof");
        _airdroppedBoost[msg.sender] = amount;
        emit AirdropBoostClaimed(msg.sender, amount);
    }

    function claimableFees(address account)
        external
        view
        override
        returns (uint256 claimableCrv, uint256 claimableCvx)
    {
        uint256 boost_ = lockedBoosted[account];
        claimableCrv =
            perAccountFeesCrv[account] +
            boost_.mulDown(accruedFeesIntegralCrv - perAccountAccruedCrv[account]);
        claimableCvx =
            perAccountFeesCvx[account] +
            boost_.mulDown(accruedFeesIntegralCvx - perAccountAccruedCvx[account]);
    }

    function balanceOf(address user) external view override returns (uint256) {
        return totalVoteBoost(user);
    }

    function _feeCheckpoint(address account) internal {
        uint256 boost_ = lockedBoosted[account];
        perAccountFeesCrv[account] += boost_.mulDown(
            accruedFeesIntegralCrv - perAccountAccruedCrv[account]
        );
        perAccountAccruedCrv[account] = accruedFeesIntegralCrv;
        perAccountFeesCvx[account] += boost_.mulDown(
            accruedFeesIntegralCvx - perAccountAccruedCvx[account]
        );
        perAccountAccruedCvx[account] = accruedFeesIntegralCvx;
    }

    function computeBoost(uint128 lockTime) public pure override returns (uint128) {
        return ((_MAX_BOOST - _MIN_BOOST).mulDownUint128(
            (lockTime - _MIN_LOCK_TIME).divDownUint128(_MAX_LOCK_TIME - _MIN_LOCK_TIME)
        ) + _MIN_BOOST);
    }

    function airdropBoost(address account) public view override returns (uint256) {
        if (_airdroppedBoost[account] == 0) return 1e18;
        return _airdroppedBoost[account];
    }

    function totalVoteBoost(address account) public view override returns (uint256) {
        return totalRewardsBoost(account).mulDown(controller.lpTokenStaker().getBoost(account));
    }

    function totalRewardsBoost(address account) public view override returns (uint256) {
        return
            lockedBoosted[account] -
            unlockableBalanceBoosted(account) +
            ICNCVoteLocker(V1_LOCKER).balanceOf(account);
    }

    function userLocks(address account) external view override returns (VoteLock[] memory) {
        return voteLocks[account];
    }

    function _getLockIndexById(address user, uint64 id) internal view returns (uint256) {
        uint256 length_ = voteLocks[user].length;
        for (uint256 i; i < length_; i++) {
            if (voteLocks[user][i].id == id) {
                return i;
            }
        }
        revert("lock doesn't exist");
    }

    function _addVoteLock(
        address user,
        uint256 amount,
        uint64 unlockTime,
        uint128 boost
    ) internal {
        uint64 id = _nextId;
        voteLocks[user].push(VoteLock(amount, unlockTime, boost, id));
        _nextId = id + 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "draft-IERC20Permit.sol";
import "Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

library ScaledMath {
    uint256 internal constant DECIMALS = 18;
    uint256 internal constant ONE = 10**DECIMALS;

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / ONE;
    }

    function mulDown(
        uint256 a,
        uint256 b,
        uint256 decimals
    ) internal pure returns (uint256) {
        return (a * b) / (10**decimals);
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * ONE) / b;
    }

    function divDown(
        uint256 a,
        uint256 b,
        uint256 decimals
    ) internal pure returns (uint256) {
        return (a * 10**decimals) / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        return ((a * ONE) - 1) / b + 1;
    }

    function mulDown(int256 a, int256 b) internal pure returns (int256) {
        return (a * b) / int256(ONE);
    }

    function mulDownUint128(uint128 a, uint128 b) internal pure returns (uint128) {
        return (a * b) / uint128(ONE);
    }

    function mulDown(
        int256 a,
        int256 b,
        uint256 decimals
    ) internal pure returns (int256) {
        return (a * b) / int256(10**decimals);
    }

    function divDown(int256 a, int256 b) internal pure returns (int256) {
        return (a * int256(ONE)) / b;
    }

    function divDownUint128(uint128 a, uint128 b) internal pure returns (uint128) {
        return (a * uint128(ONE)) / b;
    }

    function divDown(
        int256 a,
        int256 b,
        uint256 decimals
    ) internal pure returns (int256) {
        return (a * int256(10**decimals)) / b;
    }

    function convertScale(
        uint256 a,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (uint256) {
        if (fromDecimals == toDecimals) return a;
        if (fromDecimals > toDecimals) return downscale(a, fromDecimals, toDecimals);
        return upscale(a, fromDecimals, toDecimals);
    }

    function convertScale(
        int256 a,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (int256) {
        if (fromDecimals == toDecimals) return a;
        if (fromDecimals > toDecimals) return downscale(a, fromDecimals, toDecimals);
        return upscale(a, fromDecimals, toDecimals);
    }

    function upscale(
        uint256 a,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (uint256) {
        return a * (10**(toDecimals - fromDecimals));
    }

    function downscale(
        uint256 a,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (uint256) {
        return a / (10**(fromDecimals - toDecimals));
    }

    function upscale(
        int256 a,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (int256) {
        return a * int256(10**(toDecimals - fromDecimals));
    }

    function downscale(
        int256 a,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (int256) {
        return a / int256(10**(fromDecimals - toDecimals));
    }

    function intPow(uint256 a, uint256 n) internal pure returns (uint256) {
        uint256 result = ONE;
        for (uint256 i; i < n; ) {
            result = mulDown(result, a);
            unchecked {
                ++i;
            }
        }
        return result;
    }

    function absSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a >= b ? a - b : b - a;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "MerkleProof.sol";

interface ICNCLockerV2 {
    event Locked(address indexed account, uint256 amount, uint256 unlockTime, bool relocked);
    event UnlockExecuted(address indexed account, uint256 amount);
    event Relocked(address indexed account, uint256 amount);
    event KickExecuted(address indexed account, address indexed kicker, uint256 amount);
    event FeesReceived(address indexed sender, uint256 crvAmount, uint256 cvxAmount);
    event FeesClaimed(address indexed claimer, uint256 crvAmount, uint256 cvxAmount);
    event AirdropBoostClaimed(address indexed claimer, uint256 amount);
    event Shutdown();
    event TokenRecovered(address indexed token);

    struct VoteLock {
        uint256 amount;
        uint64 unlockTime;
        uint128 boost;
        uint64 id;
    }

    function lock(uint256 amount, uint64 lockTime) external;

    function lock(
        uint256 amount,
        uint64 lockTime,
        bool relock
    ) external;

    function lockFor(
        uint256 amount,
        uint64 lockTime,
        bool relock,
        address account
    ) external;

    function relock(uint64 lockId, uint64 lockTime) external;

    function relock(uint64 lockTime) external;

    function relockMultiple(uint64[] calldata lockIds, uint64 lockTime) external;

    function totalBoosted() external view returns (uint256);

    function shutDown() external;

    function recoverToken(address token) external;

    function executeAvailableUnlocks() external returns (uint256);

    function executeAvailableUnlocksFor(address dst) external returns (uint256);

    function executeUnlocks(address dst, uint64[] calldata lockIds) external returns (uint256);

    function claimAirdropBoost(uint256 amount, MerkleProof.Proof calldata proof) external;

    // This will need to include the boosts etc.
    function balanceOf(address user) external view returns (uint256);

    function unlockableBalance(address user) external view returns (uint256);

    function unlockableBalanceBoosted(address user) external view returns (uint256);

    function kick(address user, uint64 lockId) external;

    function receiveFees(uint256 amountCrv, uint256 amountCvx) external;

    function claimableFees(address account)
        external
        view
        returns (uint256 claimableCrv, uint256 claimableCvx);

    function claimFees() external returns (uint256 crvAmount, uint256 cvxAmount);

    function computeBoost(uint128 lockTime) external view returns (uint128);

    function airdropBoost(address account) external view returns (uint256);

    function claimedAirdrop(address account) external view returns (bool);

    function totalVoteBoost(address account) external view returns (uint256);

    function totalRewardsBoost(address account) external view returns (uint256);

    function userLocks(address account) external view returns (VoteLock[] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

library MerkleProof {
    struct Proof {
        uint16 nodeIndex;
        bytes32[] hashes;
    }

    function isValid(
        Proof memory proof,
        bytes32 node,
        bytes32 merkleRoot
    ) internal pure returns (bool) {
        uint256 length = proof.hashes.length;
        uint16 nodeIndex = proof.nodeIndex;
        for (uint256 i = 0; i < length; i++) {
            if (nodeIndex % 2 == 0) {
                node = keccak256(abi.encodePacked(node, proof.hashes[i]));
            } else {
                node = keccak256(abi.encodePacked(proof.hashes[i], node));
            }
            nodeIndex /= 2;
        }

        return node == merkleRoot;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "IERC20.sol";

interface ICNCToken is IERC20 {
    event MinterAdded(address minter);
    event MinterRemoved(address minter);
    event InitialDistributionMinted(uint256 amount);
    event AirdropMinted(uint256 amount);
    event AMMRewardsMinted(uint256 amount);
    event TreasuryRewardsMinted(uint256 amount);
    event SeedShareMinted(uint256 amount);

    /// @notice adds a new minter
    function addMinter(address newMinter) external;

    /// @notice renounces the minter rights of the sender
    function renounceMinterRights() external;

    /// @notice mints the initial distribution amount to the distribution contract
    function mintInitialDistribution(address distribution) external;

    /// @notice mints the airdrop amount to the airdrop contract
    function mintAirdrop(address airdropHandler) external;

    /// @notice mints the amm rewards
    function mintAMMRewards(address ammGauge) external;

    /// @notice mints `amount` to `account`
    function mint(address account, uint256 amount) external returns (uint256);

    /// @notice returns a list of all authorized minters
    function listMinters() external view returns (address[] memory);

    /// @notice returns the ratio of inflation already minted
    function inflationMintedRatio() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface ICNCVoteLocker {
    event Locked(address indexed account, uint256 amount, uint256 unlockTime, bool relocked);
    event UnlockExecuted(address indexed account, uint256 amount);

    function lock(uint256 amount) external;

    function lock(uint256 amount, bool relock) external;

    function shutDown() external;

    function recoverToken(address token) external;

    function executeAvailableUnlocks() external returns (uint256);

    function balanceOf(address user) external view returns (uint256);

    function unlockableBalance(address user) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "IConicPool.sol";
import "IOracle.sol";
import "IInflationManager.sol";
import "ILpTokenStaker.sol";
import "ICurveRegistryCache.sol";

interface IController {
    event PoolAdded(address indexed pool);
    event PoolRemoved(address indexed pool);
    event PoolShutdown(address indexed pool);
    event ConvexBoosterSet(address convexBooster);
    event CurveHandlerSet(address curveHandler);
    event ConvexHandlerSet(address convexHandler);
    event CurveRegistryCacheSet(address curveRegistryCache);
    event InflationManagerSet(address inflationManager);
    event PriceOracleSet(address priceOracle);
    event WeightUpdateMinDelaySet(uint256 weightUpdateMinDelay);

    struct WeightUpdate {
        address conicPoolAddress;
        IConicPool.PoolWeight[] weights;
    }

    // inflation manager

    function inflationManager() external view returns (IInflationManager);

    function setInflationManager(address manager) external;

    // views
    function curveRegistryCache() external view returns (ICurveRegistryCache);

    /// lp token staker
    function setLpTokenStaker(address _lpTokenStaker) external;

    function lpTokenStaker() external view returns (ILpTokenStaker);

    // oracle
    function priceOracle() external view returns (IOracle);

    function setPriceOracle(address oracle) external;

    // pool functions

    function listPools() external view returns (address[] memory);

    function listActivePools() external view returns (address[] memory);

    function isPool(address poolAddress) external view returns (bool);

    function isActivePool(address poolAddress) external view returns (bool);

    function addPool(address poolAddress) external;

    function shutdownPool(address poolAddress) external;

    function removePool(address poolAddress) external;

    function cncToken() external view returns (address);

    function lastWeightUpdate(address poolAddress) external view returns (uint256);

    function updateWeights(WeightUpdate memory update) external;

    function updateAllWeights(WeightUpdate[] memory weights) external;

    // handler functions

    function convexBooster() external view returns (address);

    function curveHandler() external view returns (address);

    function convexHandler() external view returns (address);

    function setConvexBooster(address _convexBooster) external;

    function setCurveHandler(address _curveHandler) external;

    function setConvexHandler(address _convexHandler) external;

    function setCurveRegistryCache(address curveRegistryCache_) external;

    function emergencyMinter() external view returns (address);

    function setWeightUpdateMinDelay(uint256 delay) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "ILpToken.sol";
import "IRewardManager.sol";
import "IOracle.sol";

interface IConicPool {
    event Deposit(
        address indexed sender,
        address indexed receiver,
        uint256 depositedAmount,
        uint256 lpReceived
    );
    event Withdraw(address indexed account, uint256 amount);
    event NewWeight(address indexed curvePool, uint256 newWeight);
    event NewMaxIdleCurveLpRatio(uint256 newRatio);
    event ClaimedRewards(uint256 claimedCrv, uint256 claimedCvx);
    event HandledDepeggedCurvePool(address curvePool_);
    event HandledInvalidConvexPid(address curvePool_, uint256 pid_);
    event CurvePoolAdded(address curvePool_);
    event CurvePoolRemoved(address curvePool_);
    event Shutdown();
    event DepegThresholdUpdated(uint256 newThreshold);
    event MaxDeviationUpdated(uint256 newMaxDeviation);

    struct PoolWeight {
        address poolAddress;
        uint256 weight;
    }

    struct PoolWithAmount {
        address poolAddress;
        uint256 amount;
    }

    function underlying() external view returns (IERC20Metadata);

    function lpToken() external view returns (ILpToken);

    function rewardManager() external view returns (IRewardManager);

    function depositFor(
        address _account,
        uint256 _amount,
        uint256 _minLpReceived,
        bool stake
    ) external returns (uint256);

    function deposit(uint256 _amount, uint256 _minLpReceived) external returns (uint256);

    function deposit(
        uint256 _amount,
        uint256 _minLpReceived,
        bool stake
    ) external returns (uint256);

    function exchangeRate() external view returns (uint256);

    function usdExchangeRate() external view returns (uint256);

    function allCurvePools() external view returns (address[] memory);

    function curvePoolsCount() external view returns (uint256);

    function getCurvePoolAtIndex(uint256 _index) external view returns (address);

    function unstakeAndWithdraw(uint256 _amount, uint256 _minAmount) external returns (uint256);

    function withdraw(uint256 _amount, uint256 _minAmount) external returns (uint256);

    function updateWeights(PoolWeight[] memory poolWeights) external;

    function getWeight(address curvePool) external view returns (uint256);

    function getWeights() external view returns (PoolWeight[] memory);

    function getAllocatedUnderlying() external view returns (PoolWithAmount[] memory);

    function removeCurvePool(address pool) external;

    function addCurvePool(address pool) external;

    function totalCurveLpBalance(address curvePool_) external view returns (uint256);

    function rebalancingRewardActive() external view returns (bool);

    function totalDeviationAfterWeightUpdate() external view returns (uint256);

    function computeTotalDeviation() external view returns (uint256);

    /// @notice returns the total amount of funds held by this pool in terms of underlying
    function totalUnderlying() external view returns (uint256);

    function getTotalAndPerPoolUnderlying()
        external
        view
        returns (
            uint256 totalUnderlying_,
            uint256 totalAllocated_,
            uint256[] memory perPoolUnderlying_
        );

    /// @notice same as `totalUnderlying` but returns a cached version
    /// that might be slightly outdated if oracle prices have changed
    /// @dev this is useful in cases where we want to reduce gas usage and do
    /// not need a precise value
    function cachedTotalUnderlying() external view returns (uint256);

    function handleInvalidConvexPid(address pool) external;

    function shutdownPool() external;

    function isShutdown() external view returns (bool);

    function handleDepeggedCurvePool(address curvePool_) external;

    function isBalanced() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "IERC20Metadata.sol";

interface ILpToken is IERC20Metadata {
    function mint(address account, uint256 amount) external returns (uint256);

    function burn(address _owner, uint256 _amount) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IRewardManager {
    event ClaimedRewards(uint256 claimedCrv, uint256 claimedCvx);
    event SoldRewardTokens(uint256 targetTokenReceived);
    event ExtraRewardAdded(address reward);
    event ExtraRewardRemoved(address reward);
    event ExtraRewardsCurvePoolSet(address extraReward, address curvePool);
    event FeesSet(uint256 feePercentage);
    event FeesEnabled(uint256 feePercentage);
    event EarningsClaimed(
        address indexed claimedBy,
        uint256 cncEarned,
        uint256 crvEarned,
        uint256 cvxEarned
    );

    struct RewardMeta {
        uint256 earnedIntegral;
        uint256 lastEarned;
        mapping(address => uint256) accountIntegral;
        mapping(address => uint256) accountShare;
    }

    function accountCheckpoint(address account) external;

    function poolCheckpoint() external returns (bool);

    function addExtraReward(address reward) external returns (bool);

    function addBatchExtraRewards(address[] memory rewards) external;

    function pool() external view returns (address);

    function setFeePercentage(uint256 _feePercentage) external;

    function claimableRewards(address account)
        external
        view
        returns (
            uint256 cncRewards,
            uint256 crvRewards,
            uint256 cvxRewards
        );

    function claimEarnings()
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function claimPoolEarningsAndSellRewardTokens() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IOracle {
    event TokenUpdated(address indexed token, address feed, uint256 maxDelay, bool isEthPrice);

    /// @notice returns the price in USD of symbol.
    function getUSDPrice(address token) external view returns (uint256);

    /// @notice returns if the given token is supported for pricing.
    function isTokenSupported(address token) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IInflationManager {
    event TokensClaimed(address indexed pool, uint256 cncAmount);
    event RebalancingRewardHandlerAdded(address indexed pool, address indexed handler);
    event RebalancingRewardHandlerRemoved(address indexed pool, address indexed handler);
    event PoolWeightsUpdated();

    function executeInflationRateUpdate() external;

    function updatePoolWeights() external;

    /// @notice returns the weights of the Conic pools to know how much inflation
    /// each of them will receive, as well as the total amount of USD value in all the pools
    function computePoolWeights()
        external
        view
        returns (
            address[] memory _pools,
            uint256[] memory poolWeights,
            uint256 totalUSDValue
        );

    function computePoolWeight(address pool)
        external
        view
        returns (uint256 poolWeight, uint256 totalUSDValue);

    function currentInflationRate() external view returns (uint256);

    function getCurrentPoolInflationRate(address pool) external view returns (uint256);

    function handleRebalancingRewards(
        address account,
        uint256 deviationBefore,
        uint256 deviationAfter
    ) external;

    function addPoolRebalancingRewardHandler(address poolAddress, address rebalancingRewardHandler)
        external;

    function removePoolRebalancingRewardHandler(
        address poolAddress,
        address rebalancingRewardHandler
    ) external;

    function rebalancingRewardHandlers(address poolAddress)
        external
        view
        returns (address[] memory);

    function hasPoolRebalancingRewardHandlers(address poolAddress, address handler)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface ILpTokenStaker {
    event LpTokenStaked(address indexed account, uint256 amount);
    event LpTokenUnstaked(address indexed account, uint256 amount);
    event TokensClaimed(address indexed pool, uint256 cncAmount);
    event Shutdown();

    function stake(uint256 amount, address conicPool) external;

    function unstake(uint256 amount, address conicPool) external;

    function stakeFor(
        uint256 amount,
        address conicPool,
        address account
    ) external;

    function unstakeFor(
        uint256 amount,
        address conicPool,
        address account
    ) external;

    function unstakeFrom(uint256 amount, address account) external;

    function getUserBalanceForPool(address conicPool, address account)
        external
        view
        returns (uint256);

    function getBalanceForPool(address conicPool) external view returns (uint256);

    function updateBoost(address user) external;

    function claimCNCRewardsForPool(address pool) external;

    function claimableCnc(address pool) external view returns (uint256);

    function checkpoint(address pool) external returns (uint256);

    function shutdown() external;

    function getBoost(address user) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "IBooster.sol";
import "CurvePoolUtils.sol";

interface ICurveRegistryCache {
    function BOOSTER() external view returns (IBooster);

    function initPool(address pool_) external;

    function initPool(address pool_, uint256 pid_) external;

    function lpToken(address pool_) external view returns (address);

    function assetType(address pool_) external view returns (CurvePoolUtils.AssetType);

    function isRegistered(address pool_) external view returns (bool);

    function hasCoinDirectly(address pool_, address coin_) external view returns (bool);

    function hasCoinAnywhere(address pool_, address coin_) external view returns (bool);

    function basePool(address pool_) external view returns (address);

    function coinIndex(address pool_, address coin_) external view returns (int128);

    function nCoins(address pool_) external view returns (uint256);

    function coinIndices(
        address pool_,
        address from_,
        address to_
    )
        external
        view
        returns (
            int128,
            int128,
            bool
        );

    function decimals(address pool_) external view returns (uint256[] memory);

    function interfaceVersion(address pool_) external view returns (uint256);

    function poolFromLpToken(address lpToken_) external view returns (address);

    function coins(address pool_) external view returns (address[] memory);

    function getPid(address _pool) external view returns (uint256);

    function getRewardPool(address _pool) external view returns (address);

    function isShutdownPid(uint256 pid_) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IBooster {
    function poolInfo(uint256 pid)
        external
        view
        returns (
            address lpToken,
            address token,
            address gauge,
            address crvRewards,
            address stash,
            bool shutdown
        );

    function poolLength() external view returns (uint256);

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function withdrawAll(uint256 _pid) external returns (bool);

    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    function earmarkRewards(uint256 _pid) external returns (bool);

    function isShutdown() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "ICurvePoolV2.sol";
import "ICurvePoolV1.sol";
import "ScaledMath.sol";

library CurvePoolUtils {
    using ScaledMath for uint256;

    uint256 internal constant _DEFAULT_IMBALANCE_THRESHOLD = 0.02e18;

    enum AssetType {
        USD,
        ETH,
        BTC,
        OTHER,
        CRYPTO
    }

    struct PoolMeta {
        address pool;
        uint256 numberOfCoins;
        AssetType assetType;
        uint256[] decimals;
        uint256[] prices;
        uint256[] thresholds;
    }

    function ensurePoolBalanced(PoolMeta memory poolMeta) internal view {
        uint256 fromDecimals = poolMeta.decimals[0];
        uint256 fromBalance = 10**fromDecimals;
        uint256 fromPrice = poolMeta.prices[0];
        for (uint256 i = 1; i < poolMeta.numberOfCoins; i++) {
            uint256 toDecimals = poolMeta.decimals[i];
            uint256 toPrice = poolMeta.prices[i];
            uint256 toExpectedUnscaled = (fromBalance * fromPrice) / toPrice;
            uint256 toExpected = toExpectedUnscaled.convertScale(
                uint8(fromDecimals),
                uint8(toDecimals)
            );

            uint256 toActual;

            if (poolMeta.assetType == AssetType.CRYPTO) {
                // Handling crypto pools
                toActual = ICurvePoolV2(poolMeta.pool).get_dy(0, i, fromBalance);
            } else {
                // Handling other pools
                toActual = ICurvePoolV1(poolMeta.pool).get_dy(0, int128(uint128(i)), fromBalance);
            }

            require(
                _isWithinThreshold(toExpected, toActual, poolMeta.thresholds[i]),
                "pool is not balanced"
            );
        }
    }

    function _isWithinThreshold(
        uint256 a,
        uint256 b,
        uint256 imbalanceTreshold
    ) internal pure returns (bool) {
        if (imbalanceTreshold == 0) imbalanceTreshold = _DEFAULT_IMBALANCE_THRESHOLD;
        if (a > b) return (a - b).divDown(a) <= imbalanceTreshold;
        return (b - a).divDown(b) <= imbalanceTreshold;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ICurvePoolV2 {
    function token() external view returns (address);

    function coins(uint256 i) external view returns (address);

    function factory() external view returns (address);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth,
        address receiver
    ) external returns (uint256);

    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        address receiver
    ) external returns (uint256);

    function add_liquidity(
        uint256[2] memory amounts,
        uint256 min_mint_amount,
        bool use_eth,
        address receiver
    ) external returns (uint256);

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function add_liquidity(
        uint256[3] memory amounts,
        uint256 min_mint_amount,
        bool use_eth,
        address receiver
    ) external returns (uint256);

    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function remove_liquidity(
        uint256 _amount,
        uint256[2] memory min_amounts,
        bool use_eth,
        address receiver
    ) external;

    function remove_liquidity(uint256 _amount, uint256[2] memory min_amounts)
        external;

    function remove_liquidity(
        uint256 _amount,
        uint256[3] memory min_amounts,
        bool use_eth,
        address receiver
    ) external;

    function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts)
        external;

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount,
        bool use_eth,
        address receiver
    ) external returns (uint256);

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function calc_token_amount(uint256[] memory amounts)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 token_amount, uint256 i)
        external
        view
        returns (uint256);

    function get_virtual_price() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ICurvePoolV1 {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[8] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[7] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[6] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[5] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external;

    function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount)
        external;

    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount)
        external;

    function remove_liquidity_imbalance(uint256[2] calldata amounts, uint256 max_burn_amount)
        external;

    function lp_token() external view returns (address);

    function A_PRECISION() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function remove_liquidity(uint256 _amount, uint256[3] calldata min_amounts) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function coins(uint256 i) external view returns (address);

    function balances(uint256 i) external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 _dx
    ) external view returns (uint256);

    function calc_token_amount(uint256[4] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;
}