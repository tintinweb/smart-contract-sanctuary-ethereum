// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "solowei/contracts/AttoDecimal.sol";
import "solowei/contracts/TwoStageOwnable.sol";

import "../SomaAccessControl/utils/AccessibleUpgradeable.sol";

contract FixedSwap is ReentrancyGuard, AccessibleUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using AttoDecimal for AttoDecimal.Instance;

    bytes32 public constant GLOBAL_ADMIN_ROLE = keccak256('FixedSwap.Admin');
    bytes32 public LOCAL_ADMIN_ROLE;

    enum Type {SIMPLE, INTERVAL, LINEAR}

    struct Props {
        uint256 issuanceLimit;
        uint256 startsAt;
        uint256 endsAt;
        IERC20 paymentToken;
        IERC20 issuanceToken;
        AttoDecimal.Instance fee;
        AttoDecimal.Instance rate;
    }

    struct AccountState {
        uint256 limitIndex;
        uint256 paymentSum;
    }

    struct ComplexAccountState {
        uint256 issuanceAmount;
        uint256 withdrawnIssuanceAmount;
    }

    struct Account {
        AccountState state;
        ComplexAccountState complex;
        uint256 immediatelyUnlockedAmount; // linear
        uint256 unlockedIntervalsCount; // interval
    }

    struct State {
        uint256 available;
        uint256 issuance;
        uint256 lockedPayments;
        uint256 unlockedPayments;
        address nominatedOwner;
        address owner;
        uint256[] paymentLimits;
    }

    struct Interval {
        uint256 startsAt;
        AttoDecimal.Instance unlockingPart;
    }

    struct LinearProps {
        uint256 endsAt;
        uint256 duration;
    }

    struct Pool {
        Type type_;
        uint256 index;
        AttoDecimal.Instance immediatelyUnlockingPart;
        Props props;
        LinearProps linear;
        State state;
        Interval[] intervals;
        mapping(address => Account) accounts;
    }

    Pool[] private _pools;
    mapping(IERC20 => uint256) private _collectedFees;

    modifier onlyAdmin() {
        address sender = _msgSender();
        require(hasRole(GLOBAL_ADMIN_ROLE, sender) || hasRole(LOCAL_ADMIN_ROLE, sender), 'FixedSwap: ONLY_ADMIN');
        _;
    }

    function getTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function poolsCount() public view returns (uint256) {
        return _pools.length;
    }

    function poolProps(uint256 poolIndex) public view returns (Type type_, Props memory props) {
        Pool storage pool = _getPool(poolIndex);
        return (pool.type_, pool.props);
    }

    function intervalPoolProps(uint256 poolIndex)
    public
    view
    returns (
        Props memory props,
        AttoDecimal.Instance memory immediatelyUnlockingPart,
        Interval[] memory intervals
    )
    {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolIsInterval(pool);
        return (pool.props, pool.immediatelyUnlockingPart, pool.intervals);
    }

    function linearPoolProps(uint256 poolIndex)
    public
    view
    returns (
        Props memory props,
        AttoDecimal.Instance memory immediatelyUnlockingPart,
        LinearProps memory linear
    )
    {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolIsLinear(pool);
        return (pool.props, pool.immediatelyUnlockingPart, pool.linear);
    }

    function poolState(uint256 poolIndex) public view returns (State memory state) {
        return _getPool(poolIndex).state;
    }

    function poolAccount(uint256 poolIndex, address address_)
    public
    view
    returns (Type type_, AccountState memory state)
    {
        Pool storage pool = _getPool(poolIndex);
        return (pool.type_, pool.accounts[address_].state);
    }

    function intervalPoolAccount(uint256 poolIndex, address address_)
    public
    view
    returns (
        AccountState memory state,
        ComplexAccountState memory complex,
        uint256 unlockedIntervalsCount
    )
    {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolIsInterval(pool);
        Account storage account = pool.accounts[address_];
        return (account.state, account.complex, account.unlockedIntervalsCount);
    }

    function linearPoolAccount(uint256 poolIndex, address address_)
    public
    view
    returns (
        AccountState memory state,
        ComplexAccountState memory complex,
        uint256 immediatelyUnlockedAmount
    )
    {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolIsLinear(pool);
        Account storage account = pool.accounts[address_];
        return (account.state, account.complex, account.immediatelyUnlockedAmount);
    }

    function collectedFees(IERC20 token) public view returns (uint256) {
        return _collectedFees[token];
    }

    event AccountLimitChanged(uint256 indexed poolIndex, address indexed address_, uint256 indexed limitIndex);
    event FeeWithdrawn(address indexed token, uint256 amount);
    event ImmediatelyUnlockingPartUpdated(uint256 indexed poolIndex, uint256 mantissa);
    event IntervalCreated(uint256 indexed poolIndex, uint256 startsAt, uint256 unlockingPart);
    event IssuanceIncreased(uint256 indexed poolIndex, uint256 amount);
    event LinearUnlockingEndingTimestampUpdated(uint256 indexed poolIndex, uint256 timestamp);
    event LinearPoolUnlocking(uint256 indexed poolIndex, address indexed account, uint256 amount);
    event PaymentLimitCreated(uint256 indexed poolIndex, uint256 indexed limitIndex, uint256 limit);
    event PaymentLimitChanged(uint256 indexed poolIndex, uint256 indexed limitIndex, uint256 newLimit);
    event PaymentUnlocked(uint256 indexed poolIndex, uint256 unlockedAmount, uint256 collectedFee);
    event PaymentsWithdrawn(uint256 indexed poolIndex, uint256 amount);
    event PoolOwnerChanged(uint256 indexed poolIndex, address indexed newOwner);
    event PoolOwnerNominated(uint256 indexed poolIndex, address indexed nominatedOwner);
    event UnsoldWithdrawn(uint256 indexed poolIndex, uint256 amount);

    event PoolCreated(
        Type type_,
        IERC20 indexed paymentToken,
        IERC20 indexed issuanceToken,
        uint256 poolIndex,
        uint256 issuanceLimit,
        uint256 startsAt,
        uint256 endsAt,
        uint256 fee,
        uint256 rate,
        uint256 paymentLimit
    );

    event Swap(
        uint256 indexed poolIndex,
        address indexed caller,
        uint256 requestedPaymentAmount,
        uint256 paymentAmount,
        uint256 issuanceAmount
    );

    constructor(address somaAddress)
    SomaContractUpgradeable(somaAddress) {}

    function initialize() external initializer {
        __Accessible_init();
        LOCAL_ADMIN_ROLE = keccak256(abi.encodePacked(address(this), GLOBAL_ADMIN_ROLE));
    }

    function createSimplePool(
        Props memory props,
        uint256 paymentLimit,
        address owner_
    ) external onlyAdmin returns (bool success, uint256 poolIndex) {
        return (true, _createSimplePool(props, paymentLimit, owner_, Type.SIMPLE).index);
    }

    function createIntervalPool(
        Props memory props,
        uint256 paymentLimit,
        address owner_,
        AttoDecimal.Instance memory immediatelyUnlockingPart,
        Interval[] memory intervals
    ) external onlyAdmin returns (bool success, uint256 poolIndex) {
        Pool storage pool = _createSimplePool(props, paymentLimit, owner_, Type.INTERVAL);
        _setImmediatelyUnlockingPart(pool, immediatelyUnlockingPart);
        uint256 intervalsCount = intervals.length;
        AttoDecimal.Instance memory lastUnlockingPart = immediatelyUnlockingPart;
        uint256 lastIntervalStartingTimestamp = props.endsAt - 1;
        for (uint256 i = 0; i < intervalsCount; i++) {
            Interval memory interval = intervals[i];
            require(interval.unlockingPart.gt(lastUnlockingPart), "Invalid interval unlocking part");
            lastUnlockingPart = interval.unlockingPart;
            uint256 startingTimestamp = interval.startsAt;
            require(startingTimestamp > lastIntervalStartingTimestamp, "Invalid interval starting timestamp");
            lastIntervalStartingTimestamp = startingTimestamp;
            pool.intervals.push(interval);
            emit IntervalCreated(poolIndex, interval.startsAt, interval.unlockingPart.mantissa);
        }
        require(lastUnlockingPart.eq(1), "Unlocking part not equal to one");
        return (true, pool.index);
    }

    function createLinearPool(
        Props memory props,
        uint256 paymentLimit,
        address owner_,
        AttoDecimal.Instance memory immediatelyUnlockingPart,
        uint256 linearUnlockingEndsAt
    ) external onlyAdmin returns (bool success, uint256 poolIndex) {
        require(linearUnlockingEndsAt > props.endsAt, "Linear unlocking less than or equal to pool ending timestamp");
        Pool storage pool = _createSimplePool(props, paymentLimit, owner_, Type.LINEAR);
        _setImmediatelyUnlockingPart(pool, immediatelyUnlockingPart);
        pool.linear.endsAt = linearUnlockingEndsAt;
        pool.linear.duration = linearUnlockingEndsAt - props.endsAt;
        emit LinearUnlockingEndingTimestampUpdated(pool.index, linearUnlockingEndsAt);
        return (true, pool.index);
    }

    function increaseIssuance(uint256 poolIndex, uint256 amount) external returns (bool success) {
        require(amount > 0, "Amount is zero");
        Pool storage pool = _getPool(poolIndex);
        require(getTimestamp() < pool.props.endsAt, "Pool ended");
        address caller = msg.sender;
        _assertPoolOwnership(pool, caller);
        pool.state.issuance = pool.state.issuance.add(amount);
        require(pool.state.issuance <= pool.props.issuanceLimit, "Issuance limit exceeded");
        pool.state.available = pool.state.available.add(amount);
        emit IssuanceIncreased(poolIndex, amount);
        pool.props.issuanceToken.safeTransferFrom(caller, address(this), amount);
        return true;
    }

    function swap(uint256 poolIndex, uint256 requestedPaymentAmount)
    external
    nonReentrant
    returns (uint256 paymentAmount, uint256 issuanceAmount)
    {
        require(requestedPaymentAmount > 0, "Requested payment amount is zero");
        address caller = msg.sender;
        Pool storage pool = _getPool(poolIndex);
        uint256 timestamp = getTimestamp();
        require(timestamp >= pool.props.startsAt, "Pool not started");
        require(timestamp < pool.props.endsAt, "Pool ended");
        require(pool.state.available > 0, "No available issuance");
        (paymentAmount, issuanceAmount) = _calculateSwapAmounts(pool, requestedPaymentAmount, caller);
        Account storage account = pool.accounts[caller];
        if (paymentAmount > 0) {
            pool.state.lockedPayments = pool.state.lockedPayments.add(paymentAmount);
            account.state.paymentSum = account.state.paymentSum.add(paymentAmount);
            pool.props.paymentToken.safeTransferFrom(caller, address(this), paymentAmount);
        }
        if (issuanceAmount > 0) {
            if (pool.type_ == Type.SIMPLE) pool.props.issuanceToken.safeTransfer(caller, issuanceAmount);
            else {
                uint256 totalIssuanceAmount = account.complex.issuanceAmount.add(issuanceAmount);
                account.complex.issuanceAmount = totalIssuanceAmount;
                uint256 newWithdrawnIssuanceAmount = pool.immediatelyUnlockingPart.mul(totalIssuanceAmount).floor();
                uint256 issuanceToWithdraw = newWithdrawnIssuanceAmount - account.complex.withdrawnIssuanceAmount;
                account.complex.withdrawnIssuanceAmount = newWithdrawnIssuanceAmount;
                if (pool.type_ == Type.LINEAR) account.immediatelyUnlockedAmount = newWithdrawnIssuanceAmount;
                if (issuanceToWithdraw > 0) pool.props.issuanceToken.safeTransfer(caller, issuanceToWithdraw);
            }
            pool.state.available = pool.state.available.sub(issuanceAmount);
        }
        emit Swap(poolIndex, caller, requestedPaymentAmount, paymentAmount, issuanceAmount);
    }

    function unlockInterval(uint256 poolIndex, uint256 intervalIndex)
    external
    returns (uint256 withdrawnIssuanceAmount)
    {
        address caller = msg.sender;
        Pool storage pool = _getPool(poolIndex);
        _assertPoolIsInterval(pool);
        require(intervalIndex < pool.intervals.length, "Invalid interval index");
        Interval storage interval = pool.intervals[intervalIndex];
        require(interval.startsAt <= getTimestamp(), "Interval not started");
        Account storage account = pool.accounts[caller];
        require(intervalIndex >= account.unlockedIntervalsCount, "Already unlocked");
        uint256 newWithdrawnIssuanceAmount = interval.unlockingPart.mul(account.complex.issuanceAmount).floor();
        uint256 issuanceToWithdraw = newWithdrawnIssuanceAmount - account.complex.withdrawnIssuanceAmount;
        account.complex.withdrawnIssuanceAmount = newWithdrawnIssuanceAmount;
        if (issuanceToWithdraw > 0) pool.props.issuanceToken.safeTransfer(caller, issuanceToWithdraw);
        account.unlockedIntervalsCount = intervalIndex.add(1);
        return issuanceToWithdraw;
    }

    function unlockLinear(uint256 poolIndex) external returns (uint256 withdrawalAmount) {
        address caller = msg.sender;
        uint256 timestamp = getTimestamp();
        Pool storage pool = _getPool(poolIndex);
        _assertPoolIsLinear(pool);
        require(pool.props.endsAt < timestamp, "Pool not ended");
        Account storage account = pool.accounts[caller];
        uint256 issuanceAmount = account.complex.issuanceAmount;
        require(account.complex.withdrawnIssuanceAmount < issuanceAmount, "All funds already unlocked");
        uint256 passedTime = timestamp - pool.props.endsAt;
        uint256 freezedAmount = issuanceAmount.sub(account.immediatelyUnlockedAmount);
        uint256 unfreezedAmount = passedTime.mul(freezedAmount).div(pool.linear.duration);
        uint256 newWithdrawnIssuanceAmount = timestamp >= pool.linear.endsAt
        ? issuanceAmount
        : Math.min(account.immediatelyUnlockedAmount.add(unfreezedAmount), issuanceAmount);
        withdrawalAmount = newWithdrawnIssuanceAmount.sub(account.complex.withdrawnIssuanceAmount);
        if (withdrawalAmount > 0) {
            account.complex.withdrawnIssuanceAmount = newWithdrawnIssuanceAmount;
            emit LinearPoolUnlocking(pool.index, caller, withdrawalAmount);
            pool.props.issuanceToken.safeTransfer(caller, withdrawalAmount);
        }
    }

    function createPaymentLimit(uint256 poolIndex, uint256 limit) external returns (uint256 limitIndex) {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolOwnership(pool, msg.sender);
        limitIndex = pool.state.paymentLimits.length;
        pool.state.paymentLimits.push(limit);
        emit PaymentLimitCreated(poolIndex, limitIndex, limit);
    }

    function changeLimit(
        uint256 poolIndex,
        uint256 limitIndex,
        uint256 newLimit
    ) external returns (bool success) {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolOwnership(pool, msg.sender);
        _validateLimitIndex(pool, limitIndex);
        pool.state.paymentLimits[limitIndex] = newLimit;
        emit PaymentLimitChanged(poolIndex, limitIndex, newLimit);
        return true;
    }

    function setAccountsLimit(
        uint256 poolIndex,
        uint256 limitIndex,
        address[] memory accounts
    ) external returns (bool succcess) {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolOwnership(pool, msg.sender);
        _validateLimitIndex(pool, limitIndex);
        uint256 accountsCount = accounts.length;
        require(accountsCount > 0, "No accounts provided");
        for (uint256 i = 0; i < accountsCount; i++) {
            address account = accounts[i];
            Account storage poolAccount_ = pool.accounts[account];
            if (poolAccount_.state.limitIndex == limitIndex) continue;
            poolAccount_.state.limitIndex = limitIndex;
            emit AccountLimitChanged(poolIndex, account, limitIndex);
        }
        return true;
    }

    function withdrawPayments(uint256 poolIndex) external returns (bool success) {
        Pool storage pool = _getPool(poolIndex);
        address caller = msg.sender;
        _assertPoolOwnership(pool, caller);
        _unlockPayments(pool);
        uint256 collectedPayments = pool.state.unlockedPayments;
        require(collectedPayments > 0, "No collected payments");
        pool.state.unlockedPayments = 0;
        emit PaymentsWithdrawn(poolIndex, collectedPayments);
        pool.props.paymentToken.safeTransfer(caller, collectedPayments);
        return true;
    }

    function withdrawUnsold(uint256 poolIndex) external returns (bool success) {
        Pool storage pool = _getPool(poolIndex);
        address caller = msg.sender;
        _assertPoolOwnership(pool, caller);
        require(getTimestamp() >= pool.props.endsAt, "Not ended");
        uint256 amount = pool.state.available;
        require(amount > 0, "No unsold");
        pool.state.available = 0;
        emit UnsoldWithdrawn(poolIndex, amount);
        pool.props.issuanceToken.safeTransfer(caller, amount);
        return true;
    }

    function collectFee(uint256 poolIndex) external onlyAdmin returns (bool success) {
        _unlockPayments(_getPool(poolIndex));
        return true;
    }

    function withdrawFee(IERC20 token, address to) external onlyAdmin returns (bool success) {
        uint256 collectedFee = _collectedFees[token];
        require(collectedFee > 0, "No collected fees");
        _collectedFees[token] = 0;
        emit FeeWithdrawn(address(token), collectedFee);
        token.safeTransfer(to, collectedFee);
        return true;
    }

    function nominateNewPoolOwner(uint256 poolIndex, address nominatedOwner_) external returns (bool success) {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolOwnership(pool, msg.sender);
        require(nominatedOwner_ != pool.state.owner, "Already owner");
        if (pool.state.nominatedOwner == nominatedOwner_) return true;
        pool.state.nominatedOwner = nominatedOwner_;
        emit PoolOwnerNominated(poolIndex, nominatedOwner_);
        return true;
    }

    function acceptPoolOwnership(uint256 poolIndex) external returns (bool success) {
        Pool storage pool = _getPool(poolIndex);
        address caller = msg.sender;
        require(pool.state.nominatedOwner == caller, "Not nominated to pool ownership");
        pool.state.owner = caller;
        pool.state.nominatedOwner = address(0);
        emit PoolOwnerChanged(poolIndex, caller);
        return true;
    }

    function _assertPoolIsInterval(Pool storage pool) private view {
        require(pool.type_ == Type.INTERVAL, "Not interval pool");
    }

    function _assertPoolIsLinear(Pool storage pool) private view {
        require(pool.type_ == Type.LINEAR, "Not linear pool");
    }

    function _assertPoolOwnership(Pool storage pool, address account) private view {
        require(account == pool.state.owner, "Permission denied");
    }

    function _calculateSwapAmounts(
        Pool storage pool,
        uint256 requestedPaymentAmount,
        address account
    ) private view returns (uint256 paymentAmount, uint256 issuanceAmount) {
        paymentAmount = requestedPaymentAmount;
        Account storage poolAccount_ = pool.accounts[account];
        uint256 paymentLimit = pool.state.paymentLimits[poolAccount_.state.limitIndex];
        require(poolAccount_.state.paymentSum < paymentLimit, "Account payment limit exceeded");
        if (poolAccount_.state.paymentSum.add(paymentAmount) > paymentLimit) {
            paymentAmount = paymentLimit.sub(poolAccount_.state.paymentSum);
        }
        issuanceAmount = pool.props.rate.mul(paymentAmount).floor();
        if (issuanceAmount > pool.state.available) {
            issuanceAmount = pool.state.available;
            paymentAmount = AttoDecimal.div(issuanceAmount, pool.props.rate).ceil();
        }
    }

    function _getPool(uint256 index) private view returns (Pool storage) {
        require(index < _pools.length, "Pool not found");
        return _pools[index];
    }

    function _validateLimitIndex(Pool storage pool, uint256 limitIndex) private view {
        require(limitIndex < pool.state.paymentLimits.length, "Limit not found");
    }

    function _createSimplePool(
        Props memory props,
        uint256 paymentLimit,
        address owner_,
        Type type_
    ) private returns (Pool storage) {
        {
            uint256 timestamp = getTimestamp();
            if (props.startsAt < timestamp) props.startsAt = timestamp;
            require(props.fee.lt(100), "Fee gte 100%");
            require(props.startsAt < props.endsAt, "Invalid ending timestamp");
        }
        uint256 poolIndex = _pools.length;
        _pools.push();
        Pool storage pool = _pools[poolIndex];
        pool.index = poolIndex;
        pool.type_ = type_;
        pool.props = props;
        pool.state.paymentLimits = new uint256[](1);
        pool.state.paymentLimits[0] = paymentLimit;
        pool.state.owner = owner_;
        emit PoolCreated(
            type_,
            props.paymentToken,
            props.issuanceToken,
            poolIndex,
            props.issuanceLimit,
            props.startsAt,
            props.endsAt,
            props.fee.mantissa,
            props.rate.mantissa,
            paymentLimit
        );
        emit PoolOwnerChanged(poolIndex, owner_);
        return pool;
    }

    function _setImmediatelyUnlockingPart(Pool storage pool, AttoDecimal.Instance memory immediatelyUnlockingPart)
    private
    {
        require(immediatelyUnlockingPart.lt(1), "Invalid immediately unlocking part value");
        pool.immediatelyUnlockingPart = immediatelyUnlockingPart;
        emit ImmediatelyUnlockingPartUpdated(pool.index, immediatelyUnlockingPart.mantissa);
    }

    function _unlockPayments(Pool storage pool) private {
        if (pool.state.lockedPayments == 0) return;
        uint256 fee = pool.props.fee.mul(pool.state.lockedPayments).ceil();
        _collectedFees[pool.props.paymentToken] = _collectedFees[pool.props.paymentToken].add(fee);
        uint256 unlockedAmount = pool.state.lockedPayments.sub(fee);
        pool.state.unlockedPayments = pool.state.unlockedPayments.add(unlockedAmount);
        pool.state.lockedPayments = 0;
        emit PaymentUnlocked(pool.index, unlockedAmount, fee);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0-rc.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
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
pragma solidity ^0.8.6;

library AttoDecimal {
    struct Instance {
        uint256 mantissa;
    }

    uint256 internal constant BASE = 10;
    uint256 internal constant EXPONENTIATION = 18;
    uint256 internal constant ONE_MANTISSA = BASE**EXPONENTIATION;
    uint256 internal constant ONE_TENTH_MANTISSA = ONE_MANTISSA / 10;
    uint256 internal constant HALF_MANTISSA = ONE_MANTISSA / 2;
    uint256 internal constant SQUARED_ONE_MANTISSA = ONE_MANTISSA * ONE_MANTISSA;
    uint256 internal constant MAX_INTEGER = type(uint256).max / ONE_MANTISSA;

    function maximum() internal pure returns (Instance memory) {
        return Instance({mantissa: type(uint256).max});
    }

    function zero() internal pure returns (Instance memory) {
        return Instance({mantissa: 0});
    }

    function one() internal pure returns (Instance memory) {
        return Instance({mantissa: ONE_MANTISSA});
    }

    function convert(uint256 integer) internal pure returns (Instance memory) {
        return Instance({mantissa: integer * ONE_MANTISSA});
    }

    function compare(Instance memory a, Instance memory b) internal pure returns (int8) {
        if (a.mantissa < b.mantissa) return -1;
        return int8(a.mantissa > b.mantissa ? 1 : 0);
    }

    function compare(Instance memory a, uint256 b) internal pure returns (int8) {
        return compare(a, convert(b));
    }

    function add(Instance memory a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa + b.mantissa});
    }

    function add(Instance memory a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa + b * ONE_MANTISSA});
    }

    function sub(Instance memory a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa - b.mantissa});
    }

    function sub(Instance memory a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa - b * ONE_MANTISSA});
    }

    function sub(uint256 a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a * ONE_MANTISSA - b.mantissa});
    }

    function mul(Instance memory a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa * b.mantissa / ONE_MANTISSA});
    }

    function mul(Instance memory a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa * b});
    }

    function div(Instance memory a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa * ONE_MANTISSA / b.mantissa});
    }

    function div(Instance memory a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa / b});
    }

    function div(uint256 a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a * SQUARED_ONE_MANTISSA / b.mantissa});
    }

    function div(uint256 a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a * ONE_MANTISSA / b});
    }

    function idiv(Instance memory a, Instance memory b) internal pure returns (uint256) {
        return a.mantissa / b.mantissa;
    }

    function idiv(Instance memory a, uint256 b) internal pure returns (uint256) {
        return a.mantissa / (b * ONE_MANTISSA);
    }

    function idiv(uint256 a, Instance memory b) internal pure returns (uint256) {
        return a * ONE_MANTISSA / b.mantissa;
    }

    function mod(Instance memory a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa % b.mantissa});
    }

    function mod(Instance memory a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa % (b * ONE_MANTISSA)});
    }

    function mod(uint256 a, Instance memory b) internal pure returns (Instance memory) {
        if (a > MAX_INTEGER) return Instance({mantissa: a % b.mantissa * ONE_MANTISSA % b.mantissa});
        return Instance({mantissa: a * ONE_MANTISSA % b.mantissa});
    }

    function floor(Instance memory a) internal pure returns (uint256) {
        return a.mantissa / ONE_MANTISSA;
    }

    function ceil(Instance memory a) internal pure returns (uint256) {
        return (a.mantissa / ONE_MANTISSA) + (a.mantissa % ONE_MANTISSA > 0 ? 1 : 0);
    }

    function round(Instance memory a) internal pure returns (uint256) {
        return (a.mantissa / ONE_MANTISSA) + ((a.mantissa / ONE_TENTH_MANTISSA) % 10 >= 5 ? 1 : 0);
    }

    function eq(Instance memory a, Instance memory b) internal pure returns (bool) {
        return a.mantissa == b.mantissa;
    }

    function eq(Instance memory a, uint256 b) internal pure returns (bool) {
        if (b > MAX_INTEGER) return false;
        return a.mantissa == b * ONE_MANTISSA;
    }

    function gt(Instance memory a, Instance memory b) internal pure returns (bool) {
        return a.mantissa > b.mantissa;
    }

    function gt(Instance memory a, uint256 b) internal pure returns (bool) {
        if (b > MAX_INTEGER) return false;
        return a.mantissa > b * ONE_MANTISSA;
    }

    function gte(Instance memory a, Instance memory b) internal pure returns (bool) {
        return a.mantissa >= b.mantissa;
    }

    function gte(Instance memory a, uint256 b) internal pure returns (bool) {
        if (b > MAX_INTEGER) return false;
        return a.mantissa >= b * ONE_MANTISSA;
    }

    function lt(Instance memory a, Instance memory b) internal pure returns (bool) {
        return a.mantissa < b.mantissa;
    }

    function lt(Instance memory a, uint256 b) internal pure returns (bool) {
        if (b > MAX_INTEGER) return true;
        return a.mantissa < b * ONE_MANTISSA;
    }

    function lte(Instance memory a, Instance memory b) internal pure returns (bool) {
        return a.mantissa <= b.mantissa;
    }

    function lte(Instance memory a, uint256 b) internal pure returns (bool) {
        if (b > MAX_INTEGER) return true;
        return a.mantissa <= b * ONE_MANTISSA;
    }

    function isInteger(Instance memory a) internal pure returns (bool) {
        return a.mantissa % ONE_MANTISSA == 0;
    }

    function isPositive(Instance memory a) internal pure returns (bool) {
        return a.mantissa > 0;
    }

    function isZero(Instance memory a) internal pure returns (bool) {
        return a.mantissa == 0;
    }

    function sum(Instance[] memory array) internal pure returns (Instance memory result) {
        uint256 length = array.length;
        for (uint256 index = 0; index < length; index++) result = add(result, array[index]);
    }

    function toTuple(Instance memory a)
        internal
        pure
        returns (
            uint256 mantissa,
            uint256 base,
            uint256 exponentiation
        )
    {
        return (a.mantissa, BASE, EXPONENTIATION);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

abstract contract TwoStageOwnable {
    address private _nominatedOwner;
    address private _owner;

    function nominatedOwner() public view returns (address) {
        return _nominatedOwner;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    event OwnerChanged(address indexed newOwner);
    event OwnerNominated(address indexed nominatedOwner);

    constructor(address owner_) {
        require(owner_ != address(0), "Owner is zero");
        _setOwner(owner_);
    }

    function acceptOwnership() external returns (bool success) {
        require(msg.sender == _nominatedOwner, "Not nominated to ownership");
        _setOwner(_nominatedOwner);
        return true;
    }

    function nominateNewOwner(address owner_) external onlyOwner returns (bool success) {
        _nominateNewOwner(owner_);
        return true;
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    function _nominateNewOwner(address owner_) internal {
        if (_nominatedOwner == owner_) return;
        require(_owner != owner_, "Already owner");
        _nominatedOwner = owner_;
        emit OwnerNominated(owner_);
    }

    function _setOwner(address newOwner) internal {
        if (_owner == newOwner) return;
        _owner = newOwner;
        _nominatedOwner = address(0);
        emit OwnerChanged(newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

import "../../utils/security/IPausable.sol";
import "../../utils/SomaContractUpgradeable.sol";

import "../ISomaAccessControl.sol";
import "./IAccessible.sol";

abstract contract AccessibleUpgradeable is IAccessible, SomaContractUpgradeable {

    function __Accessible_init() internal onlyInitializing {
        __SomaContract_init_unchained();
    }

    function __Accessible_init_unchained() internal onlyInitializing {
    }

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), "SomaAccessControl: caller does not have the appropriate authority");
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessible).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return IAccessControlUpgradeable(address(SOMA.access())).getRoleAdmin(role);
    }

    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return IAccessControlUpgradeable(address(SOMA.access())).hasRole(role, account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0-rc.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IPausable {

    function paused() external view returns (bool);

    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "../ISOMA.sol";

import "./ISomaContract.sol";

contract SomaContractUpgradeable is ISomaContract, ContextUpgradeable, ERC165Upgradeable {
    function __SomaContract_init() internal onlyInitializing {
        __ERC165_init_unchained();
        __Context_init_unchained();
        __SomaContract_init_unchained();
    }

    function __SomaContract_init_unchained() internal onlyInitializing {
        emit Initialized();
    }

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ISOMA public immutable override SOMA;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address somaAddress) {
        SOMA = ISOMA(somaAddress);
    }

    modifier onlyMasterOrSubMaster {
        address sender = _msgSender();
        require(SOMA.master() == sender || SOMA.subMaster() == sender, 'SOMA: MASTER or SUB MASTER only');
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), 'SOMA: PAUSED');
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ISomaContract).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function paused() public view virtual override returns (bool) {
        return PausableUpgradeable(address(SOMA)).paused();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ISomaAccessControl {

    function rolesOf(address account) external view returns (bytes32[] memory);

    function accountsOf(bytes32 role) external view returns (address[] memory);

    function revokeRoles(bytes32[] memory roles, address target) external;

    function grantRoles(bytes32[] memory roles, address target) external;

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IAccessible {

    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function hasRole(bytes32 role, address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0-rc.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0-rc.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./SomaAccessControl/ISomaAccessControl.sol";
import "./SomaSwap/periphery/ISomaSwapRouter.sol";
import "./SomaSwap/core/interfaces/ISomaSwapFactory.sol";
import "./SomaGuard/ISomaGuard.sol";
import "./TemplateFactory/ITemplateFactory.sol";
import "./Lockdrop/ILockdropFactory.sol";

interface ISOMA {

    event SOMAUpgraded(bytes32 hash, bytes shapshot);

    event SeizeToUpdated(
        address indexed prevSeizeTo,
        address indexed newSeizeTo,
        address indexed sender
    );

    event MintToUpdated(
        address indexed prevMintTo,
        address indexed newMintTo,
        address indexed sender
    );

    struct Snapshot {
        ISomaAccessControl access;
        ISomaGuard guard;
        ISomaSwapFactory swapFactory;
        ITemplateFactory templateFactory;
        ILockdropFactory lockdropFactory;
        IERC20 token;
    }

    function master() external view returns (address);
    function subMaster() external view returns (address);

    function access() external view returns (ISomaAccessControl);
    function guard() external view returns (ISomaGuard);
    function swapFactory() external view returns (ISomaSwapFactory);
    function templateFactory() external view returns (ITemplateFactory);
    function lockdropFactory() external view returns (ILockdropFactory);
    function token() external view returns (IERC20);

    function snapshotHash() external view returns (bytes32);
    function snapshots(bytes32 hash) external view returns (bytes memory);

    function mintTo() external view returns (address);
    function seizeTo() external view returns (address);

    function __upgrade() external;

    function pause() external;
    function unpause() external;

    function setMintTo(address _mintTo) external;
    function setSeizeTo(address _seizeTo) external;

    function snapshot() external view returns (Snapshot memory _cache);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../ISOMA.sol";

interface ISomaContract {

    event Initialized();

    function SOMA() external view returns (ISOMA);

    function paused() external view returns (bool);
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
interface IERC165Upgradeable {
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

pragma solidity >=0.6.2;

interface ISomaSwapRouter {
    function factory() external view returns (address);
    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ISomaSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    event FeeToUpdated(address indexed prevFeeTo, address indexed newFeeTo, address indexed sender);
    event RouterAdded(address indexed router, address indexed sender);
    event RouterRemoved(address indexed router, address indexed sender);

    function TEMPLATE() external view returns (bytes32);
    function TEMPLATE_VERSION() external view returns (uint256);

    function CREATE_PAIR_ROLE() external pure returns (bytes32);
    function FEE_SETTER_ROLE() external pure returns (bytes32);
    function MANAGE_ROUTER_ROLE() external pure returns (bytes32);

    function DEPLOYER() external view returns (address);
    function INIT_CODE_HASH() external view returns (bytes32);

    function feeTo() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function isRouter(address target) external view returns (bool);
    function addRouter(address target) external;
    function removeRouter(address target) external;

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface ISomaGuard {

    event PrivilegesUpdated(address indexed operator, bytes32 prevPrivileges, bytes32 newPrivileges, address indexed account);
    event ContractApproved(address indexed operator, address account);
    event ContractUnapproved(address indexed operator, address account);

    event BatchUpdate(
        address[][] accounts,
        bytes32[] privileges,
        address indexed sender
    );

    event BatchUpdateSingle(
        address[] accounts,
        bytes32[] access,
        address indexed sender
    );

    function DEFAULT_PRIVILEGES() external view returns (bytes32);
    function OPERATOR_ROLE() external view returns (bytes32);

    function privileges(address account) external view returns (bytes32);
    function check(address account, bytes32 query) external view returns (bool);

    function batchFetch(address[] calldata accounts) external view returns (bytes32[] memory access_);
    function batchUpdate(address[] calldata accounts_, bytes32[] calldata access_) external returns (bool);
    function batchUpdate(address[][] calldata accounts_, bytes32[] calldata access_) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface ITemplateFactory {

    event TemplateVersionCreated(bytes32 indexed templateId, uint256 indexed version, address implementation, address indexed sender);
    event DeployRoleUpdated(bytes32 indexed templateId, bytes32 prevRole, bytes32 newRole, address indexed sender);
    event TemplateEnabled(bytes32 indexed templateId, address indexed sender);
    event TemplateDisabled(bytes32 indexed templateId, address indexed sender);
    event TemplateVersionDeprecated(bytes32 indexed templateId, uint256 indexed version, address indexed sender);
    event TemplateVersionUndeprecated(bytes32 indexed templateId, uint256 indexed version, address indexed sender);
    event TemplateDeployed(address indexed instance, bytes32 indexed templateId, uint256 version, bytes args, bytes[] functionCalls, address indexed sender);
    event TemplateCloned(address indexed instance, bytes32 indexed templateId, uint256 version, bytes[] functionCalls, address indexed sender);
    event FunctionCalled(address indexed target, bytes data, bytes result, address indexed sender);

    struct Version {
        bool exists;
        bool deprecated;
        address implementation;
        bytes creationCode;
        uint256 totalParts;
        uint256 partsUploaded;
        address[] instances;
    }

    struct Template {
        bool disabled;
        uint256 latestVersion;
        bytes32 deployRole;
        mapping(uint256 => Version) version;
        address[] instances;
    }

    struct DeploymentInfo {
        bool exists;
        bytes32 templateId;
        uint256 version;
    }

    function initialize() external;

    function version(bytes32 templateId, uint256 version) external view returns (Version memory);

    function latestVersion(bytes32 templateId) external view returns (uint256);

    function templateInstances(bytes32 templateId) external view returns (address[] memory);

    function deploymentInfo(address instance) external view returns (DeploymentInfo memory);

    function deployRole(bytes32 templateId) external view returns (bytes32);

    function deployedByFactory(address instance) external view returns (bool);

    function uploadTemplate(bytes32 templateId, bytes memory creationCode, address implementation) external returns (bool);
    function uploadTemplate(bytes32 templateId, bytes memory initialPart, uint256 totalParts, address implementation) external returns (bool);
    function uploadTemplatePart(bytes32 templateId, uint256 version, bytes memory part) external returns (bool);

    function updateDeployRole(bytes32 templateId, bytes32 deployRole) external returns (bool);

    function disableTemplate(bytes32 templateId) external returns (bool);

    function enableTemplate(bytes32 templateId) external returns (bool);

    function deprecateVersion(bytes32 templateId, uint256 version) external returns (bool);

    function undeprecateVersion(bytes32 templateId, uint256 version) external returns (bool);

    function initCodeHash(bytes32 templateId, uint256 version, bytes memory args) external view returns (bytes32);

    function predictDeployAddress(bytes32 templateId, uint256 version, bytes memory args) external view returns (address);

    function predictDeployAddress(bytes32 templateId, uint256 version, bytes memory args, bytes32 salt) external view returns (address);

    function predictCloneAddress(bytes32 templateId, uint256 version) external view returns (address);

    function predictCloneAddress(bytes32 templateId, uint256 version, bytes32 salt) external view returns (address);

    function deployTemplateLATEST(bytes32 templateId, bytes memory args) external returns (address instance);

    function deployTemplateLATEST(bytes32 templateId, bytes memory args, bytes32 salt) external returns (address instance);

    function deployTemplateLATEST(bytes32 templateId, bytes memory args, bytes[] memory functionCalls) external returns (address instance);

    function deployTemplateLATEST(bytes32 templateId, bytes memory args, bytes[] memory functionCalls, bytes32 salt) external returns (address instance);

    function deployTemplate(bytes32 templateId, uint256 version, bytes memory args) external returns (address instance);

    function deployTemplate(bytes32 templateId, uint256 version, bytes memory args, bytes32 salt) external returns (address instance);

    function deployTemplate(bytes32 templateId, uint256 version, bytes memory args, bytes[] memory functionCalls) external returns (address instance);

    function deployTemplate(bytes32 templateId, uint256 version, bytes memory args, bytes[] memory functionCalls, bytes32 salt) external returns (address instance);

    function cloneTemplateLATEST(bytes32 templateId) external returns (address instance);

    function cloneTemplateLATEST(bytes32 templateId, bytes32 salt) external returns (address instance);

    function cloneTemplateLATEST(bytes32 templateId, bytes[] memory functionCalls) external returns (address instance);

    function cloneTemplateLATEST(bytes32 templateId, bytes[] memory functionCalls, bytes32 salt) external returns (address instance);

    function cloneTemplate(bytes32 templateId, uint256 _version) external returns (address instance);

    function cloneTemplate(bytes32 templateId, uint256 _version, bytes32 salt) external returns (address instance);

    function cloneTemplate(bytes32 templateId, uint256 _version, bytes[] memory functionCalls) external returns (address instance);

    function cloneTemplate(bytes32 templateId, uint256 version, bytes[] memory functionCalls, bytes32 salt) external returns (address instance);

    function functionCall(address target, bytes memory data) external returns (bytes memory result);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ILockdropFactory {

    event LockdropCreated(uint256 id, address asset, address instance);

    function CREATE_ROLE() external pure returns (bytes32);
    function TEMPLATE() external pure returns (bytes32);
    function TEMPLATE_VERSION() external pure returns (uint256);

    function lockdrop(uint256 id) external view returns (address);
    function totalLockdrops() external view returns (uint256);

    function create(
        address asset,
        uint256 startsAt,
        uint256 endsAt,
        address withdrawTo
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}