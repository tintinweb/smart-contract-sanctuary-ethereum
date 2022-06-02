pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IXLPToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

/// @dev interface of the frax gauge. Based on FraxUnifiedFarmTemplate.sol
/// https://github.com/FraxFinance/frax-solidity/blob/master/src/hardhat/contracts/Staking/FraxUnifiedFarmTemplate.sol
interface IUnifiedFarm {
    // Struct for the stake
    struct LockedStake {
        bytes32 kek_id;
        uint256 start_timestamp;
        uint256 liquidity;
        uint256 ending_timestamp;
        uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
    }
    function stakeLocked(uint256 liquidity, uint256 secs) external;
    function getReward(address destination_address) external returns (uint256[] memory);
    function withdrawLocked(bytes32 kek_id, address destination_address) external;
    function lockAdditional(bytes32 kek_id, uint256 addl_liq) external;
    function stakerSetVeFXSProxy(address proxy_address) external;
    function stakerToggleMigrator(address migrator_address) external;
    function lock_time_for_max_multiplier() external view returns (uint256);
    function lock_time_min() external view returns (uint256);
    function getAllRewardTokens() external view returns (address[] memory);
    function lockedLiquidityOf(address account) external view returns (uint256);
    function lockedStakesOf(address account) external view returns (LockedStake[] memory);
}

/// @dev interface of the curve stable swap.
interface IStableSwap {
    function coins(uint256 j) external view returns (address);
    function calc_token_amount(uint256[2] calldata _amounts, bool _is_deposit) external view returns (uint256);
    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount, address destination) external returns (uint256);
    function get_dy(int128 _from, int128 _to, uint256 _from_amount) external view returns (uint256);
    function remove_liquidity(uint256 _amount, uint256[2] calldata _min_amounts) external returns (uint256[2] memory);
    function fee() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function remove_liquidity_imbalance(uint256[2] memory amounts, uint256 _max_burn_amount, address _receiver) external returns (uint256);
}

contract LiquidityOps is Ownable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IXLPToken;

    IUnifiedFarm public lpFarm;          // frax unified lp farm
    IXLPToken public xlpToken;           // stax lp receipt;
    IERC20 public lpToken;               // lp pair token

    // curve pool for (xlp, lp) pair. This is an ERC20, 
    // and gets minted/burnt when new liquidity is added/removed in the pool.
    IStableSwap public curveStableSwap;

    address public rewardsManager;
    address public feeCollector;
    address public pegDefender;
    address public operator;
    
    // applyLiquidity can be toggled to be permissionless or only callable by an operator.
    bool public operatorOnlyMode;

    // The order of curve pool tokens
    int128 public inputTokenIndex;
    int128 public staxReceiptTokenIndex;

    // How much of user LP do we add into gauge.
    // The remainder is added as liquidity into curve pool
    LockRate public lockRate;  

    struct LockRate {
        uint128 numerator;
        uint128 denominator;
    }

    FeeRate public feeRate;
    struct FeeRate {
        uint128 numerator;
        uint128 denominator;
    }

    // fxs emissions + random token extra bribe
    IERC20[] public rewardTokens;

    // The period of time (secs) to lock liquidity into the farm.
    uint256 public farmLockTime;

    // FEE_DENOMINATOR from Curve StableSwap
    uint256 internal constant CURVE_FEE_DENOMINATOR = 1e10;

    event SetLockParams(uint128 numerator, uint128 denominator);
    event SetFeeParams(uint128 numerator, uint128 denominator);
    event Locked(uint256 amountLocked);
    event LiquidityAdded(uint256 lpAmount, uint256 xlpAmount, uint256 curveTokenAmount);
    event LiquidityRemoved(uint256 lpAmount, uint256 xlpAmount, uint256 curveTokenAmount);
    event WithdrawAndReLock(bytes32 _kekId, uint256 amount);
    event RewardHarvested(address token, address to, uint256 distributionAmount, uint256 feeAmount);
    event RewardClaimed(uint256[] data);
    event SetVeFXSProxy(address proxy);
    event MigratorToggled(address migrator);
    event RewardsManagerSet(address manager);
    event FeeCollectorSet(address feeCollector);
    event TokenRecovered(address user, uint256 amount);
    event CoinExchanged(address coinSent, uint256 amountSent, uint256 amountReceived);
    event RemovedLiquidityImbalance(uint256 _amount0, uint256 _amounts1, uint256 burnAmount);
    event PegDefenderSet(address defender);
    event FarmLockTimeSet(uint256 secs);
    event OperatorOnlyModeSet(bool value);
    event OperatorSet(address operator);

    constructor(
        address _lpFarm,
        address _lpToken,
        address _xlpToken,
        address _curveStableSwap,
        address _rewardsManager,
        address _feeCollector
    ) {
        lpFarm = IUnifiedFarm(_lpFarm);
        lpToken = IERC20(_lpToken);
        xlpToken = IXLPToken(_xlpToken);

        curveStableSwap = IStableSwap(_curveStableSwap);
        (staxReceiptTokenIndex, inputTokenIndex) = curveStableSwap.coins(0) == address(xlpToken)
            ? (int128(0), int128(1))
            : (int128(1), int128(0));

        rewardsManager = _rewardsManager;
        feeCollector = _feeCollector;
        
        // Lock all liquidity in the lpFarm as a (non-zero denominator) default.
        lockRate.numerator = 100;
        lockRate.denominator = 100;

        // No fees are taken by default
        feeRate.numerator = 0;
        feeRate.denominator = 100;

        // By default, set the lock time to the max (eg 3yrs for TEMPLE/FRAX)
        farmLockTime = lpFarm.lock_time_for_max_multiplier();

        // applyLiquidity is permissionless by default.
        operatorOnlyMode = false;
    }

    function setLockParams(uint128 _numerator, uint128 _denominator) external onlyOwner {
        require(_denominator > 0 && _numerator <= _denominator, "invalid params");
        lockRate.numerator = _numerator;
        lockRate.denominator = _denominator;

        emit SetLockParams(_numerator, _denominator);
    }

    function setRewardsManager(address _manager) external onlyOwner {
        require(_manager != address(0), "invalid address");
        rewardsManager = _manager;

        emit RewardsManagerSet(_manager);
    }

    function setFeeParams(uint128 _numerator, uint128 _denominator) external onlyOwner {
        require(_denominator > 0 && _numerator <= _denominator, "invalid params");
        feeRate.numerator = _numerator;
        feeRate.denominator = _denominator;

        emit SetFeeParams(_numerator, _denominator);
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        require(_feeCollector != address(0), "invalid address");
        feeCollector = _feeCollector;

        emit FeeCollectorSet(_feeCollector);
    }

    function setFarmLockTime(uint256 _secs) external onlyOwner {
        require(_secs >= lpFarm.lock_time_min(), "Minimum lock time not met");
        require(_secs <= lpFarm.lock_time_for_max_multiplier(),"Trying to lock for too long");
        farmLockTime = _secs;
        emit FarmLockTimeSet(_secs);
    }

    // set lp farm in case of migration
    function setLPFarm(address _lpFarm) external onlyOwner {
        require(_lpFarm != address(0), "invalid address");
        lpFarm = IUnifiedFarm(_lpFarm);
    }

    function setRewardTokens() external {
        address[] memory tokens = lpFarm.getAllRewardTokens();
        for (uint i=0; i<tokens.length; i++) {
            rewardTokens.push(IERC20(tokens[i]));
        }
    }

    function setPegDefender(address _pegDefender) external onlyOwner {
        pegDefender = _pegDefender;
        emit PegDefenderSet(_pegDefender);
    }

    function setOperatorOnlyMode(bool _operatorOnlyMode) external onlyOwner {
        operatorOnlyMode = _operatorOnlyMode;
        emit OperatorOnlyModeSet(_operatorOnlyMode);
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
        emit OperatorSet(_operator);
    }

    function exchange(
        address _coinIn,
        uint256 _amount,
        uint256 _minAmountOut
    ) external onlyPegDefender {
        (int128 in_index, int128 out_index) = (staxReceiptTokenIndex, inputTokenIndex);

        if (_coinIn == address(xlpToken)) {
            uint256 balance = xlpToken.balanceOf(address(this));
            require(_amount <= balance, "not enough tokens");
            xlpToken.safeIncreaseAllowance(address(curveStableSwap), _amount);
        } else if (_coinIn == address(lpToken)) {
            uint256 balance = lpToken.balanceOf(address(this));
            require(_amount <= balance, "not enough tokens");
            lpToken.safeIncreaseAllowance(address(curveStableSwap), _amount);
            (in_index, out_index) = (inputTokenIndex, staxReceiptTokenIndex);
        } else {
            revert("unknown token");
        }

        uint256 amountReceived = curveStableSwap.exchange(in_index, out_index, _amount, _minAmountOut);

        emit CoinExchanged(_coinIn, _amount, amountReceived);
    }

    function removeLiquidityImbalance(
        uint256[2] memory _amounts,
        uint256 _maxBurnAmount
    ) external onlyPegDefender {
        require(curveStableSwap.balanceOf(address(this)) > 0, "no liquidity");
        uint256 burnAmount = curveStableSwap.remove_liquidity_imbalance(_amounts, _maxBurnAmount, address(this));

        emit RemovedLiquidityImbalance(_amounts[0], _amounts[1], burnAmount);
    }

    function lockInGauge(uint256 liquidity) private {
        lpToken.safeIncreaseAllowance(address(lpFarm), liquidity);

        // if first time lock
        IUnifiedFarm.LockedStake[] memory lockedStakes = lpFarm.lockedStakesOf(address(this));
        uint256 lockedStakesLength = lockedStakes.length;

        // we want to lock additional if lock end time not expired
        // check last lockedStake if expired
        if (lockedStakesLength == 0 || block.timestamp >= lockedStakes[lockedStakesLength - 1].ending_timestamp) {
            lpFarm.stakeLocked(liquidity, farmLockTime);
        } else {
            lpFarm.lockAdditional(lockedStakes[lockedStakesLength - 1].kek_id, liquidity);
        }
        
        emit Locked(liquidity);
    }

    /** 
      * @notice Add LP/xLP 1:1 into the curve pool
      * @dev Add same amounts of lp and xlp tokens such that the price remains about the same
             - don't apply any peg fixing here. xLP tokens are minted 1:1
      * @param _amount The amount of LP and xLP to add into the pool.
      * @param _minCurveAmountOut The minimum amount of curve liquidity tokens we expect in return.
      */
    function addLiquidity(uint256 _amount, uint256 _minCurveAmountOut) private {
        uint256[2] memory amounts = [_amount, _amount];
        
        // Mint the new xLP. same as lp amount
        xlpToken.mint(address(this), _amount);

        lpToken.safeIncreaseAllowance(address(curveStableSwap), _amount);
        xlpToken.safeIncreaseAllowance(address(curveStableSwap), _amount);

        uint256 liquidity = curveStableSwap.add_liquidity(amounts, _minCurveAmountOut, address(this));
        emit LiquidityAdded(_amount, _amount, liquidity);
    }

    function removeLiquidity(
        uint256 _liquidity,
        uint256 _lpAmountMin,
        uint256 _xlpAmountMin
    ) external onlyPegDefender {
        uint256 balance = curveStableSwap.balanceOf(address(this));
        require(balance >= _liquidity, "not enough tokens");

        uint256 receivedXlpAmount;
        uint256 receivedLpAmount;
        if (staxReceiptTokenIndex == 0) {
            uint256[2] memory balances = curveStableSwap.remove_liquidity(_liquidity, [_xlpAmountMin, _lpAmountMin]);
            receivedXlpAmount = balances[0];
            receivedLpAmount = balances[1];
        } else {
            uint256[2] memory balances = curveStableSwap.remove_liquidity(_liquidity, [_lpAmountMin, _xlpAmountMin]);
            receivedXlpAmount = balances[1];
            receivedLpAmount = balances[0];
        }

        emit LiquidityRemoved(receivedLpAmount, receivedXlpAmount, _liquidity);
    }

    /**
      * @notice Calculate the amounts of liquidity to lock in the gauge vs add into the curve pool, based on lockRate policy.
      */
    function applyLiquidityAmounts(uint256 _liquidity) private view returns (uint256 lockAmount, uint256 addLiquidityAmount) {
        lockAmount = (_liquidity * lockRate.numerator) / lockRate.denominator;
        unchecked {
            addLiquidityAmount = _liquidity - lockAmount;
        }
    }

    /** 
      * @notice Calculates the min expected amount of curve liquditity token to receive when depositing the 
      *         current eligable amount to into the curve LP:xLP liquidity pool
      * @dev Takes into account pool liquidity slippage and fees.
      * @param _liquidity The amount of LP to apply
      * @param _modelSlippage Any extra slippage to account for, given curveStableSwap.calc_token_amount() 
               is an approximation. 1e10 precision, so 1% = 1e8.
      * @return minCurveTokenAmount Expected amount of LP tokens received 
      */ 
    function minCurveLiquidityAmountOut(uint256 _liquidity, uint256 _modelSlippage) external view returns (uint256 minCurveTokenAmount) {
        uint256 feeAndSlippage = _modelSlippage + curveStableSwap.fee();
        require(feeAndSlippage <= CURVE_FEE_DENOMINATOR, "invalid slippage");
        (, uint256 addLiquidityAmount) = applyLiquidityAmounts(_liquidity);
        
        minCurveTokenAmount = 0;
        if (addLiquidityAmount > 0) {
            uint256[2] memory amounts = [addLiquidityAmount, addLiquidityAmount];
            minCurveTokenAmount = curveStableSwap.calc_token_amount(amounts, true);
            unchecked {
                minCurveTokenAmount -= minCurveTokenAmount * feeAndSlippage / CURVE_FEE_DENOMINATOR;
            }
        }
    }

    /** 
      * @notice Apply LP held by this contract - locking into the gauge and adding to the curve liquidity pool
      * @dev The ratio of gauge vs liquidity pool is goverend by the lockRate percentage, set by policy.
      *      It is by default permissionless to call, but may be beneficial to limit how liquidity is deployed
      *      in the future (by a whitelisted operator)
      * @param _liquidity The amount of LP to apply.
      * @param _minCurveTokenAmount When adding liquidity to the pool, what is the minimum number of tokens
      *        to accept.
      */
    function applyLiquidity(uint256 _liquidity, uint256 _minCurveTokenAmount) external onlyOperator {
        require(_liquidity <= lpToken.balanceOf(address(this)), "not enough liquidity");
        (uint256 lockAmount, uint256 addLiquidityAmount) = applyLiquidityAmounts(_liquidity);

        // Policy may be set to put all in gauge, or all as new curve liquidity
        if (lockAmount > 0) {
            lockInGauge(lockAmount);
        }

        if (addLiquidityAmount > 0) {
            addLiquidity(addLiquidityAmount, _minCurveTokenAmount);
        }
    }

    // withdrawAndRelock is called to withdraw expired locks and relock into the most recent
    function withdrawAndRelock(bytes32 _oldKekId) external {
        // there may be reserve lp tokens in contract. account for those
        uint256 lpTokensBefore = lpToken.balanceOf(address(this));
        lpFarm.withdrawLocked(_oldKekId, address(this));
        uint256 lpTokensAfter = lpToken.balanceOf(address(this));
        uint256 lockAmount;
        unchecked {
            lockAmount = lpTokensAfter - lpTokensBefore;
        }

        require(lockAmount > 0, "nothing to withdraw");
        lpToken.safeIncreaseAllowance(address(lpFarm), lockAmount);

        // Re-lock into the most recent lock
        IUnifiedFarm.LockedStake[] memory lockedStakes = lpFarm.lockedStakesOf(address(this));
        uint256 lockedStakesLength = lockedStakes.length;
        // avoid locking in a stale lock position. i.e. a lock with start and endtimestamp set to 0
        // check last lockedStake if expired
        if (block.timestamp >= lockedStakes[lockedStakesLength - 1].ending_timestamp) {
            lpFarm.stakeLocked(lockAmount, farmLockTime);
        } else {
            lpFarm.lockAdditional(lockedStakes[lockedStakesLength - 1].kek_id, lockAmount);
        }

        emit WithdrawAndReLock(_oldKekId, lockAmount);
    }

    // claim reward to this contract.
    // reward manager will withdraw rewards for incentivizing xlp stakers
    function getReward() external returns (uint256[] memory data) {
        data = lpFarm.getReward(address(this));

        emit RewardClaimed(data);
    }

    // get amount to lock based on lock rate
    function _getFeeAmount(uint256 _amount) internal view returns (uint256) {
        return (_amount * feeRate.numerator) / feeRate.denominator;
    }

    // harvest rewards
    function harvestRewards() external {
        // iterate through reward tokens and transfer to rewardsManager
        for (uint i=0; i<rewardTokens.length; i++) {
            IERC20 token = rewardTokens[i];
            uint256 amount = token.balanceOf(address(this));
            uint256 feeAmount = _getFeeAmount(amount);

            if (feeAmount > 0) {
                amount -= feeAmount;
                token.safeTransfer(feeCollector, feeAmount);
            }
            if (amount > 0) {
                token.safeTransfer(rewardsManager, amount);
            }

            emit RewardHarvested(address(token), rewardsManager, amount, feeAmount);
        }
    }

    // Staker can allow a veFXS proxy (the proxy will have to toggle them first)
    function setVeFXSProxy(address _proxy) external onlyOwner {
        lpFarm.stakerSetVeFXSProxy(_proxy);

        emit SetVeFXSProxy(_proxy);
    }

    // Owner can withdraw any locked position.
    // Migration on expired locks can then happen without farm gov/owner having to pause and toggleMigrations()
    function withdrawLocked(bytes32 kek_id, address destination_address) external onlyOwner {
        // The farm emits WithdrawLocked events.
        lpFarm.withdrawLocked(kek_id, destination_address);
    }
    
    // To migrate:
    // - unified farm owner/gov sets valid migrator
    // - stakerToggleMigrator() - this func
    // - gov/owner calls toggleMigrations()
    // - migrator calls migrator_withdraw_locked(this, kek_id), which calls _withdrawLocked(staker, migrator) - sends lps to migrator
    // - migrator is assumed to be new lplocker and therefore would now own the lp tokens and can relock (stakelock) in newly upgraded gauge.
    // Staker can allow a migrator
    function stakerToggleMigrator(address _migrator) external onlyOwner {
        lpFarm.stakerToggleMigrator(_migrator);

        emit MigratorToggled(_migrator);
    }

    // recover tokens except reward tokens
    // for reward tokens use harvestRewards instead
    function recoverToken(address _token, address _to, uint256 _amount) external onlyOwnerOrPegDefender {
        for (uint i=0; i<rewardTokens.length; i++) {
            require(_token != address(rewardTokens[i]), "can't recover reward token this way");
        }

        _transferToken(IERC20(_token), _to, _amount);

        emit TokenRecovered(_to, _amount);
    }

    function _transferToken(IERC20 _token, address _to, uint256 _amount) internal {
        uint256 balance = _token.balanceOf(address(this));
        require(_amount <= balance, "not enough tokens");
        _token.safeTransfer(_to, _amount);
    }

    modifier onlyPegDefender() {
        require(msg.sender == pegDefender, "not defender");
        _;
    }

    modifier onlyOwnerOrPegDefender {
        require(msg.sender == owner() || msg.sender == pegDefender, "only owner or defender");
        _;
    }

    /// @dev Either set to be permissionless, or can only be called by the operator.
    modifier onlyOperator {
        require(!operatorOnlyMode || msg.sender == operator, "not operator");
        _;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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