pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (investments/frax-gauge/temple-frax/LiquidityOps.sol)

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../../../interfaces/common/IMintableToken.sol";
import "../../../interfaces/investments/frax-gauge/tranche/ITranche.sol";
import "../../../interfaces/investments/frax-gauge/tranche/ITrancheRegistry.sol";
import "../../../interfaces/investments/frax-gauge/temple-frax/ILiquidityOps.sol";
import "../../../interfaces/external/frax/IFraxGauge.sol";

import "../../../common/access/Operators.sol";
import "../../../common/Executable.sol";
import "../../../common/CommonEventsAndErrors.sol";
import "../../../common/FractionalAmount.sol";
import "../../../liquidity-pools/CurveStableSwap.sol";

/// @notice Manage the locked LP, applying it to underlying gauges (via tranches) and exit liquidity pools
///
/// When applying liquidity:
/// 1/ A new tranche is auto-created (via a factory clone) when the `trancheSize` is hit in the current tranche
/// 2/ The new tranche base implementation can be set with `nextTrancheImplId`, where
///    the `trancheRegistry` maintains the implementations and creates new instances. 
///    Example implementations:
///      a/ Direct Tranche: We proxy directly to the gauge using STAX's vefxs proxy only
///      b/ Convex Vault Tranche: We lock using the Convex frax vaults - a jointly owned vault
///         such that we can use their veFXS proxy to get a 2x rewards boost (for a fee)
///         Using tranches allow STAX to switch that chunk of LP from using Convex's veFXS proxy to STAX's veFXS proxy.
/// 3/ Each new vault will have one single active lock - so new liquidity added to that tranche will have the same boost and expiry.
///      a/ So if we create a new tranche the lock expiry will be new (and can be longer/shorter than the first one for more/less rewards boost).
///      b/ The net APR is therefore the weighted average across each of the locks.
contract LiquidityOps is ILiquidityOps, Ownable, Operators {
    using SafeERC20 for IERC20;
    using SafeERC20 for IMintableToken;
    using CurveStableSwap for CurveStableSwap.Data;
    using FractionalAmount for FractionalAmount.Data;

    /// @notice The LP token pair used for staking in the underlying gauge
    IERC20 public immutable lpToken;

    /// @notice STAX LP receipt token
    IMintableToken public immutable xlpToken;

    /** GAUGE / LOCK SETTINGS */

    /// @notice The underlying Frax gauge that we expect to be used by any new tranches. 
    IFraxGauge public underlyingGauge; 

    /// @notice Percentage of how much user LP we add into gauge each time applyLiquidity() is called.
    ///         The remainder is added as liquidity into curve pool
    FractionalAmount.Data public lockRate;  

    /// @notice The period of time (secs) to lock liquidity into the gauge.
    /// @dev Only one active lock will be created within each tranche.
    ///      So if the lock hasn't expired - we lock additional into the existing one.
    uint256 public lockTime;

    /** TRANCHE SETTINGS */

    /// @notice Registry to create new gauge tranches.
    ITrancheRegistry public trancheRegistry;

    /// @notice The tranche registry implementation to use when a new gauge tranche needs to be created.
    uint256 public nextTrancheImplId;

    /// @notice When the current tranche has more than this amount of LP locked already,
    ///         a new tranche will be created and used for the locks
    uint256 public trancheSize;

    /// @notice The address of the current gauge tranche that's being used for new LP deposits.
    ITranche public currentTranche;

    /// @notice All known gauge tranche instsances that this liquidity ops created
    mapping(address => bool) public tranches;
    address[] public trancheList;

    /** EXIT LIQUIDITY AND DEFENSE
      * 
      * A protocol determined percentage of LP will be supplied as liquidity to a Curve v1 Stable Swap.
      * This is to allow exit liquidity for users to liquidiate by exchanging xlp->lp.
      * 
      * To help manage the defense of peg, pegDefender has access to manage the protocol owned curve liqudiity.
      */

    /// @notice Curve v1 Stable Swap (xLP:LP) is used as the pool for exit liquidity.
    CurveStableSwap.Data public curveStableSwap;

    /// @notice Whitelisted account responsible for defending the exit liqudity pool's peg
    address public pegDefender;

    /** GAUGE REWARDS AND FEES */

    /// @notice What percentage of fees does STAX retain.
    FractionalAmount.Data public feeRate;

    /// @notice Destination address for retained STAX fees.
    address public feeCollector;

    /// @notice Where rewards are sent when collected from the gauge and harvested.
    address public rewardsManager;

    /// @notice FXS emissions from the underlying gauge + any other bonus tokens.
    /// @dev Operators to set this manually.
    address[] public rewardTokens;

    event LockRateSet(uint128 numerator, uint128 denominator);
    event FeeRateSet(uint128 numerator, uint128 denominator);
    event Locked(uint256 amountLocked, bytes32 kekId);
    event WithdrawAndReLock(address indexed oldTrancheAddress, bytes32 oldKekId, address indexed newTrancheAddress, uint256 amount, bytes32 newKekId);
    event RewardHarvested(address indexed token, address indexed to, uint256 distributionAmount, uint256 feeAmount);
    event RewardsManagerSet(address indexed manager);
    event FeeCollectorSet(address indexed feeCollector);
    event PegDefenderSet(address indexed defender);
    event LockTimeSet(uint256 secs);
    event UnderlyingGaugeSet(address indexed gaugeAddress);
    event NextTrancheImplSet(uint256 implId);
    event CurrentTrancheSet(address indexed tranche);
    event TrancheRegistrySet(address indexed registry);
    event TrancheSizeSet(uint256 trancheSize);
    event RewardTokensSet(address[] tokenAddresses);
    event KnownTrancheForgotten(address indexed tranche, uint256 idx);

    error OnlyOwnerOrPegDefender(address caller);
    error OnlyPegDefender(address caller); 
    error UnexpectedGauge(address expected, address found);

    constructor(
        address _underlyingGauge,
        address _trancheRegistry,
        address _lpToken,
        address _xlpToken,
        address _curveStableSwap,
        address _rewardsManager,
        address _feeCollector,
        uint256 _trancheSize
    ) {
        underlyingGauge = IFraxGauge(_underlyingGauge);
        trancheRegistry = ITrancheRegistry(_trancheRegistry); 

        lpToken = IERC20(_lpToken);
        xlpToken = IMintableToken(_xlpToken);

        ICurveStableSwap ccs = ICurveStableSwap(_curveStableSwap);
        curveStableSwap = CurveStableSwap.Data(ccs, IERC20(ccs.coins(0)), IERC20(ccs.coins(1)));

        rewardsManager = _rewardsManager;
        feeCollector = _feeCollector;
        
        // Lock all liquidity in the underlyingGauge as a (non-zero denominator) default.
        lockRate.set(100, 100);

        // No fees are taken by default
        feeRate.set(0, 100);

        // By default, set the lock time to the max (eg 3yrs for TEMPLE/FRAX)
        lockTime = underlyingGauge.lock_time_for_max_multiplier();

        trancheSize = _trancheSize;
    }

    /// @notice Set the ratio for how much to lock in the gauge (vs apply to exit liquidity pool)
    function setLockRate(uint128 _numerator, uint128 _denominator) external onlyOwner {
        lockRate.set(_numerator, _denominator);
        emit LockRateSet(_numerator, _denominator);
    }

    /// @notice Where rewards are sent when collected from the gauge and harvested.
    function setRewardsManager(address _manager) external onlyOwner {
        if (_manager == address(0)) revert CommonEventsAndErrors.InvalidAddress(_manager);
        rewardsManager = _manager;

        emit RewardsManagerSet(_manager);
    }

    /// @notice Set the ratio of how much fees STAX retains from rewards claimed from the tranches
    function setFeeRate(uint128 _numerator, uint128 _denominator) external onlyOwner {
        feeRate.set(_numerator, _denominator);
        emit FeeRateSet(_numerator, _denominator);
    }

    /// @notice Where STAX fees are sent
    function setFeeCollector(address _feeCollector) external onlyOwner {
        if (_feeCollector == address(0)) revert CommonEventsAndErrors.InvalidAddress(_feeCollector);
        feeCollector = _feeCollector;

        emit FeeCollectorSet(_feeCollector);
    }

    /// @notice Set the expected underlying gauge that is staked into.
    /// @dev Each tranche implementation that is used should also use this same underlying gauge
    function setUnderlyingGauge(address gaugeAddress) external onlyOwner {
        if (gaugeAddress == address(0)) revert CommonEventsAndErrors.InvalidAddress(gaugeAddress);

        underlyingGauge = IFraxGauge(gaugeAddress);
        emit UnderlyingGaugeSet(gaugeAddress);
    }

    /// @notice Se the tranche registry (in case of upgrade.
    /// @dev Existing tranches will need to be added into the new registry (registry.addExistingTranche)
    ///      and then added into this liquidity ops list one by one with setCurrentTranche()
    function setTrancheRegistry(address registry) external onlyOwner {
        if (registry == address(0)) revert CommonEventsAndErrors.InvalidAddress(registry);

        trancheRegistry = ITrancheRegistry(registry);
        emit TrancheRegistrySet(registry);
    }

    /// @notice The list of all tranches this liquidity ops has been managing.
    function allTranches() external override view returns (address[] memory) {
        return trancheList;
    }

    function _addTranche(address _tranche, bool _setCurrentTranche) internal {
        // Add to the known tranches
        if (!tranches[_tranche]) {
            trancheList.push(_tranche);
        }
        tranches[_tranche] = true;

        // Set the currentTranche if required
        if (_setCurrentTranche) {
            currentTranche = ITranche(_tranche);
            emit CurrentTrancheSet(_tranche);
        }
    }

    function _createTranche(uint256 _implId, bool _setCurrentTranche) internal returns (address tranche, address underlyingGaugeAddress, address stakingToken) {
        (tranche, underlyingGaugeAddress, stakingToken) = trancheRegistry.createTranche(_implId);
        
        if (underlyingGaugeAddress != address(underlyingGauge)) revert UnexpectedGauge(address(underlyingGauge), underlyingGaugeAddress);
        if (stakingToken != address(lpToken)) revert CommonEventsAndErrors.InvalidToken(address(stakingToken));

        _addTranche(tranche, _setCurrentTranche);
    }

    /// @notice Manually create a new gauge tranche for future use (or in the case of migration).
    /// @dev Once created, the new tranche can be selected for use with `setCurrentTranche()`
    function createTranche(uint256 _implId) external onlyOwnerOrOperators returns (address, address, address) {
        return _createTranche(_implId, false);
    }

    /// @notice Set the gauge tranche to use for new LP deposits.
    /// @dev This liquidity ops must be the owner of the tranche.
    /// This can be used to point to an existing tranche that was auto-created, or if a new 
    /// tranche is manually created using createTranche()
    function setCurrentTranche(address tranche) external onlyOwnerOrOperators {
        if (tranche == address(0)) revert CommonEventsAndErrors.InvalidAddress(tranche);
        if (Ownable(tranche).owner() != address(this)) revert CommonEventsAndErrors.OnlyOwner(address(this));
        _addTranche(tranche, true);
    }

    /// @notice Remove a tranche from the set of known tranches
    function forgetKnownTranche(address _tranche, uint256 _idx) external onlyOwnerOrOperators {
        if (trancheList[_idx] != _tranche) revert CommonEventsAndErrors.InvalidParam();

        delete tranches[_tranche];
        delete trancheList[_idx];

        emit KnownTrancheForgotten(_tranche, _idx);
    }

    /// @notice Set the underlying gauge lock time, used for new tranches or
    ///         new locks (if the old lock expired) in existing tranches
    function setLockTime(uint256 _secs) external onlyOwner {
        if (_secs < underlyingGauge.lock_time_min() || _secs > underlyingGauge.lock_time_for_max_multiplier()) 
            revert CommonEventsAndErrors.InvalidParam();
        lockTime = _secs;
        emit LockTimeSet(_secs);
    }

    /// @notice Set the reward tokens to get and harvest from the underlying tranches/gauges.
    /// @dev This might be just the underlying gauge tokens, but also might be others, depending on the vault type.
    function setRewardTokens(address[] calldata tokenAddresses) external onlyOwnerOrOperators {
        // Rewards can't be either the LP or xLP tokens
        for (uint256 i=0; i<tokenAddresses.length;) {
            if (
                tokenAddresses[i] == address(0) || 
                tokenAddresses[i] == address(xlpToken) || 
                tokenAddresses[i] == address(lpToken)
            ) {
                revert CommonEventsAndErrors.InvalidToken(tokenAddresses[i]);
            }
            unchecked {i++;}
        }

        rewardTokens = tokenAddresses;
        emit RewardTokensSet(tokenAddresses);
    }

    /// @notice Set the address allowed to operate peg defence.
    function setPegDefender(address _pegDefender) external onlyOwner {
        pegDefender = _pegDefender;
        emit PegDefenderSet(_pegDefender);
    }

    function addOperator(address _address) external override onlyOwner {
        _addOperator(_address);
    }

    function removeOperator(address _address) external override onlyOwner {
        _removeOperator(_address);
    }

    /// @notice Peg Defence: Exchange xLP <--> LP
    function exchange(
        address _coinIn,
        uint256 _amount,
        uint256 _minAmountOut
    ) external onlyOwnerOrPegDefender {
        curveStableSwap.exchange(_coinIn, _amount, _minAmountOut, msg.sender); 
    }

    /// @notice Peg Defence: Remove liquidity from xLP:LP pool in imbalanced amounts
    function removeLiquidityImbalance(
        uint256[2] memory _amounts,
        uint256 _maxBurnAmount
    ) external onlyOwnerOrPegDefender {
        curveStableSwap.removeLiquidityImbalance(_amounts, _maxBurnAmount); 
    }

    /// @notice Peg Defence: Remove liquidity from xLP:LP pool in equal amounts, given an amount of liquidity
    function removeLiquidity(
        uint256 _liquidity,
        uint256 _minAmount0,
        uint256 _minAmount1
    ) external onlyOwnerOrPegDefender {
        curveStableSwap.removeLiquidity(_liquidity, _minAmount0, _minAmount1);
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
    function minCurveLiquidityAmountOut(uint256 _liquidity, uint256 _modelSlippage) external view returns (uint256) {
        (, uint256 addLiquidityAmount) = lockRate.split(_liquidity);
        return curveStableSwap.minAmountOut(addLiquidityAmount, _modelSlippage);
    }

    /** 
      * @notice Apply LP held by this contract - locking into the gauge and adding to the curve liquidity pool
      * @dev The ratio of gauge vs liquidity pool is goverend by the lockRate percentage, set by policy.
      *      It is by default permissionless to call, but may be beneficial to limit how liquidity is deployed
      *      in the future (by a whitelisted operator)
      * @param _liquidity The amount of LP to apply.
      * @param _minCurveTokenAmount When adding liquidity to the pool, what is the minimum number of tokens
      *        to accept.
      * @param _tranche The tranche to apply the liquidity into
      */
    function _applyLiquidity(uint256 _liquidity, uint256 _minCurveTokenAmount, ITranche _tranche) internal {
        uint256 balance = lpToken.balanceOf(address(this));
        if (balance < _liquidity) revert CommonEventsAndErrors.InsufficientBalance(address(lpToken), _liquidity, balance);
        (uint256 lockAmount, uint256 addLiquidityAmount) = lockRate.split(_liquidity);

        // Function is protected if we're adding LP into the pool, because we need to ensure _minCurveTokenAmount
        // is set correctly.
        if (addLiquidityAmount > 0 && msg.sender != owner() && !operators[msg.sender]) revert CommonEventsAndErrors.OnlyOwnerOrOperators(msg.sender);

        // Policy may be set to put all in gauge, or all as new curve liquidity
        if (lockAmount > 0) {
            lpToken.safeTransfer(address(_tranche), lockAmount);
            bytes32 kekId = _tranche.stake(lockAmount, lockTime);
            emit Locked(lockAmount, kekId);
        }

        if (addLiquidityAmount > 0) {
            xlpToken.mint(address(this), addLiquidityAmount);
            curveStableSwap.addLiquidity(addLiquidityAmount, _minCurveTokenAmount);
        }
    }

    /// @notice Set the tranche registry implementation to use when a new gauge tranche needs to be created.
    function setNextTrancheImplId(uint256 implId) external onlyOwnerOrOperators {
        // Cannot set a tranche implementation which is disabled / closed for staking
        ITrancheRegistry.ImplementationDetails memory implDetails = trancheRegistry.implDetails(implId);
        if (implDetails.disabled || implDetails.closedForStaking) revert ITrancheRegistry.InvalidTrancheImpl(implId);

        nextTrancheImplId = implId;
        emit NextTrancheImplSet(implId);
    }

    /// @notice Set the tranche size - when new LP is applied, if the current tranche is larger than
    ///         this size, then a new tranche will be created
    function setTrancheSize(uint256 _trancheSize) external onlyOwnerOrOperators {
        if (_trancheSize == 0) revert CommonEventsAndErrors.InvalidParam();

        trancheSize = _trancheSize;
        emit TrancheSizeSet(_trancheSize);
    }

    function _newTrancheRequired() internal view returns (bool) {
        return (
            address(currentTranche) == address(0) ||
            !currentTranche.willAcceptLock(trancheSize)
        );
    }

    /// @notice Apply any accrued LP to the underlying tranche->gauge, and exit liquidity pool
    /// @dev Actual splits and how the liqudity is applied is according to contract settings, eg `lockRate`
    function applyLiquidity(uint256 _liquidity, uint256 _minCurveTokenAmount) external {
        // If required, update/create the handle to the current gauge tranche to use.
        if (_newTrancheRequired()) {
            _createTranche(nextTrancheImplId, true);
        }

        _applyLiquidity(_liquidity, _minCurveTokenAmount, currentTranche);
    }

    /// @notice Apply liquidity in a specific tranche address.
    /// @dev This tranche must exist in the registry and be active.
    function applyLiquidityInTranche(uint256 _liquidity, uint256 _minCurveTokenAmount, address _trancheAddress) external {
        if (!tranches[_trancheAddress]) revert ITrancheRegistry.UnknownTranche(_trancheAddress);
        
        _applyLiquidity(_liquidity, _minCurveTokenAmount, ITranche(_trancheAddress));
    }

    /// @notice Withdraw from an expired lock, and relock into the most recent.
    /// @dev If the originating tranche is still active, create a new lock in that tranche
    ///      Otherwise apply into the currently active tranche's lock.
    function withdrawAndRelock(address _trancheAddress, bytes32 _oldKekId) external onlyOwnerOrOperators {
        if (!tranches[_trancheAddress]) revert ITrancheRegistry.UnknownTranche(_trancheAddress);

        // Withdraw from the old tranche, depositing the LP dircetly into the new tranche
        // As long as the old tranche is still active, re-use it.
        // Otherwise use the most current tranche
        // (which still might need creating/updating to a new tranche - based on volume/etc)
        ITranche newTranche = ITranche(_trancheAddress);
        if (newTranche.disabled()) {
            if (_newTrancheRequired()) {
                _createTranche(nextTrancheImplId, true);
            }
            newTranche = currentTranche;
        }
        uint256 withdrawnAmount = ITranche(_trancheAddress).withdraw(_oldKekId, address(newTranche));

        if (withdrawnAmount > 0) {
            // Re-lock - the LP was already transferred to the tranche.
            bytes32 newKekId = newTranche.stake(withdrawnAmount, lockTime);
            emit WithdrawAndReLock(_trancheAddress, _oldKekId, address(newTranche), withdrawnAmount, newKekId);
        }
    }

    /// @notice Pull the rewards from each of the selected tranches.
    /// @dev The caller can first get the list of active tranches off-chain using `trancheList`, 
    ///      and filter to active/split accordingly.
    function getRewards(address[] calldata _tranches) external override {
        for (uint256 i=0; i<_tranches.length;) {
            if (!tranches[_tranches[i]]) revert ITrancheRegistry.UnknownTranche(_tranches[i]);

            address trancheAddress = _tranches[i];
            ITranche(trancheAddress).getRewards(rewardTokens);
            unchecked { ++i; }    
        }
    }

    /// @notice Harvest rewards - take a cut of fees and send the remaining rewards to the `rewardsManager`
    function harvestRewards() external override {
        // Iterate through reward tokens and transfer to rewardsManager
        for (uint i=0; i<rewardTokens.length;) {
            address token = rewardTokens[i];
            (uint256 feeAmount, uint256 rewardAmount) = feeRate.split(IERC20(token).balanceOf(address(this)));

            if (feeAmount > 0) {
                IERC20(token).safeTransfer(feeCollector, feeAmount);
            }
            if (rewardAmount > 0) {
                IERC20(token).safeTransfer(rewardsManager, rewardAmount);
            }

            emit RewardHarvested(address(token), rewardsManager, rewardAmount, feeAmount);
            unchecked { i++; }
        }
    }

    /// @notice Set the underlying staker in a tranche to use a particular veFXS proxy for extra reward boost
    /// @dev The proxy will have to toggle them first.
    function setVeFXSProxyForTranche(address trancheAddress, address proxy) external onlyOwner {
        ITranche(trancheAddress).setVeFXSProxy(proxy);
    }

    /// @notice Owner can withdraw any locked position.
    /// @dev Migration on expired locks can then happen without farm gov/owner having to pause and toggleMigrations()
    function withdraw(address trancheAddress, bytes32 kek_id, address destination_address) external onlyOwnerOrOperators returns (uint256) {
        if (!tranches[trancheAddress]) revert ITrancheRegistry.UnknownTranche(trancheAddress);
        return ITranche(trancheAddress).withdraw(kek_id, destination_address);
    }
    
    // To migrate:
    // - unified farm owner/gov sets valid migrator
    // - stakerToggleMigrator() - this func
    // - gov/owner calls toggleMigrations()
    // - migrator calls migrator_withdraw_locked(this, kek_id), which calls _withdrawLocked(staker, migrator) - sends lps to migrator
    // - migrator is assumed to be new lplocker and therefore would now own the lp tokens and can relock (stakelock) in newly upgraded gauge.
    /// @notice An underlying staker in a tranche can allow a migrator
    function stakerToggleMigratorForTranche(address trancheAddress, address _migrator) external onlyOwner {
        ITranche(trancheAddress).toggleMigrator(_migrator);
    }

    /// @notice recover tokens except reward tokens
    /// @dev for reward tokens use harvestRewards instead
    function recoverToken(address _token, address _to, uint256 _amount) external onlyOwnerOrPegDefender {
        for (uint i=0; i<rewardTokens.length;) {
            if (_token == rewardTokens[i]) revert CommonEventsAndErrors.InvalidToken(_token);
            unchecked { i++; }
        }

        IERC20(_token).safeTransfer(_to, _amount);
        emit CommonEventsAndErrors.TokenRecovered(_to, _token, _amount);
    }

    /**
      * @notice execute arbitrary functions
      * @dev Operators and owners are allowed to execute
      * In LiquidityOps case, this is useful in case we need to operate on the underlying Tranches,
      * since LiquidityOps is the owner of these factory created tranches.
      * eg to update the owner (new LiquidityOps version), recover tokens, etc
      */
    function execute(address _to, uint256 _value, bytes calldata _data) external onlyOwnerOrOperators returns (bytes memory) {
        return Executable.execute(_to, _value, _data);
    }

    modifier onlyOwnerOrOperators() {
        if (msg.sender != owner() && !operators[msg.sender]) revert CommonEventsAndErrors.OnlyOwnerOrOperators(msg.sender);
        _;
    }

    modifier onlyOwnerOrPegDefender {
        if (msg.sender != owner() && msg.sender != pegDefender) revert OnlyOwnerOrPegDefender(msg.sender);
        _;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/common/IMintableToken.sol)

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/frax-gauge/tranche/ITranche.sol)

import "../../../external/frax/IFraxGauge.sol";

interface ITranche {
    enum TrancheType {
        DIRECT,
        CONVEX_VAULT
    }

    event RegistrySet(address indexed registry);
    event SetDisabled(bool isDisabled);
    event RewardClaimed(address indexed trancheAddress, uint256[] rewardData);
    event AdditionalLocked(address indexed staker, bytes32 kekId, uint256 liquidity);
    event VeFXSProxySet(address indexed proxy);
    event MigratorToggled(address indexed migrator);

    error InactiveTranche(address tranche);
    error AlreadyInitialized();
    
    function disabled() external view returns (bool);
    function willAcceptLock(uint256 liquidity) external view returns (bool);
    function lockedStakes() external view returns (IFraxGauge.LockedStake[] memory);

    function initialize(address _registry, uint256 _fromImplId, address _newOwner) external returns (address, address);
    function setRegistry(address _registry) external;
    function setDisabled(bool isDisabled) external;
    function setVeFXSProxy(address _proxy) external;
    function toggleMigrator(address migrator_address) external;

    function stake(uint256 liquidity, uint256 secs) external returns (bytes32 kek_id);
    function withdraw(bytes32 kek_id, address destination_address) external returns (uint256 withdrawnAmount);
    function getRewards(address[] calldata rewardTokens) external returns (uint256[] memory rewardAmounts);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/frax-gauge/tranche/ITrancheRegistry.sol)

interface ITrancheRegistry {
    struct ImplementationDetails {
        // The reference tranche implementation which is to be cloned
        address implementation;

        // If true, new/additional locks cannot be added into this tranche type
        bool closedForStaking;

        // If true, no staking allowed and these tranches have no rewards
        // to claim or tokens to withdraw. So fully deprecated.
        bool disabled;
    }

    event TrancheCreated(uint256 indexed implId, address indexed tranche, address stakingAddress, address stakingToken);
    event TrancheImplCreated(uint256 indexed implId, address indexed implementation);
    event ImplementationDisabled(uint256 indexed implId, bool value);
    event ImplementationClosedForStaking(uint256 indexed implId, bool value);
    event AddedExistingTranche(uint256 indexed implId, address indexed tranche);

    error OnlyOwnerOperatorTranche(address caller);
    error InvalidTrancheImpl(uint256 implId);
    error TrancheAlreadyExists(address tranche);
    error UnknownTranche(address tranche);

    function createTranche(uint256 _implId) external returns (address tranche, address underlyingGaugeAddress, address stakingToken);
    function implDetails(uint256 _implId) external view returns (ImplementationDetails memory details);
    function execute(address _to, uint256 _value, bytes calldata _data) external returns (bytes memory);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/frax-gauge/temple-frax/ILiquidityOps.sol)

interface ILiquidityOps {
    function allTranches() external view returns (address[] memory);
    function getRewards(address[] calldata _tranches) external;
    function harvestRewards() external;
    function minCurveLiquidityAmountOut(
        uint256 _liquidity,
        uint256 _modelSlippage
    ) external view returns (uint256 minCurveTokenAmount);
    function applyLiquidity(uint256 _liquidity, uint256 _minCurveTokenAmount) external;
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/external/curve/IFraxGauge.sol)

// ref: https://github.com/FraxFinance/frax-solidity/blob/master/src/hardhat/contracts/Staking/FraxUnifiedFarm_ERC20.sol

interface IFraxGauge {
    struct LockedStake {
        bytes32 kek_id;
        uint256 start_timestamp;
        uint256 liquidity;
        uint256 ending_timestamp;
        uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
    }

    function stakeLocked(uint256 liquidity, uint256 secs) external;
    function lockAdditional(bytes32 kek_id, uint256 addl_liq) external;
    function withdrawLocked(bytes32 kek_id, address destination_address) external;

    function lockedStakesOf(address account) external view returns (LockedStake[] memory);
    function getAllRewardTokens() external view returns (address[] memory);
    function getReward(address destination_address) external returns (uint256[] memory);

    function stakerSetVeFXSProxy(address proxy_address) external;
    function stakerToggleMigrator(address migrator_address) external;

    function lock_time_min() external view returns (uint256);
    function lock_time_for_max_multiplier() external view returns (uint256);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (common/access/Operators.sol)

/// @notice Inherit to add an Operator role which multiple addreses can be granted.
/// @dev Derived classes to implement addOperator() and removeOperator()
abstract contract Operators {
    /// @notice A set of addresses which are approved to run operations.
    mapping(address => bool) public operators;

    event AddedOperator(address indexed account);
    event RemovedOperator(address indexed account);

    error OnlyOperators(address caller);

    function _addOperator(address _account) internal {
        operators[_account] = true;
        emit AddedOperator(_account);
    }

    /// @notice Grant `_account` the operator role
    /// @dev Derived classes to implement and add protection on who can call
    function addOperator(address _account) external virtual;

    function _removeOperator(address _account) internal {
        delete operators[_account];
        emit RemovedOperator(_account);
    }

    /// @notice Revoke the operator role from `_account`
    /// @dev Derived classes to implement and add protection on who can call
    function removeOperator(address _account) external virtual;

    modifier onlyOperators() {
        if (!operators[msg.sender]) revert OnlyOperators(msg.sender);
        _;
    }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (common/Executable.sol)

/// @notice An inlined library function to add a generic execute() function to contracts.
/// @dev As this is a powerful funciton, care and consideration needs to be taken when 
///      adding into contracts, and on who can call.
library Executable {
    error UnknownFailure();

    /// @notice Call a function on another contract, where the msg.sender will be this contract
    /// @param _to The address of the contract to call
    /// @param _value Any eth to send
    /// @param _data The encoded function selector and args.
    /// @dev If the underlying function reverts, this willl revert where the underlying revert message will bubble up.
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = _to.call{value: _value}(_data);
        
        if (success) {
            return returndata;
        } else if (returndata.length > 0) {
            // Look for revert reason and bubble it up if present
            // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L232
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert UnknownFailure();
        }
    }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (common/CommonEventsAndErrors.sol)

/// @notice A collection of common errors thrown within the STAX contracts
library CommonEventsAndErrors {
    error InsufficientBalance(address token, uint256 required, uint256 balance);
    error InvalidToken(address token);
    error InvalidParam();
    error InvalidAddress(address addr);
    error OnlyOwner(address caller);
    error OnlyOwnerOrOperators(address caller);
    error InvalidAmount(address token, uint256 amount);

    event TokenRecovered(address indexed to, address indexed token, uint256 amount);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (common/FractionalAmount.sol)

import "./CommonEventsAndErrors.sol";

/// @notice Utilities to operate on fractional amounts of an input
/// - eg to calculate the split of rewards for fees.
library FractionalAmount {
    struct Data {
        uint128 numerator;
        uint128 denominator;
    }

    /// @notice Helper to set the storage value with safety checks.
    function set(Data storage self, uint128 _numerator, uint128 _denominator) internal {
        if (_denominator == 0 || _numerator > _denominator) revert CommonEventsAndErrors.InvalidParam();
        self.numerator = _numerator;
        self.denominator = _denominator;
    }

    /// @notice Split an amount into two parts based on a fractional ratio
    /// eg: 333/1000 (33.3%) can be used to split an input amount of 600 into: (199, 401).
    /// @dev The numerator amount is truncated if necessary
    function split(Data storage self, uint256 inputAmount) internal view returns (uint256 numeratorAmount, uint256 denominatorAmount) {
        if (self.numerator == 0) {
            return (0, inputAmount);
        }
        unchecked {
            numeratorAmount = (inputAmount * self.numerator) / self.denominator;
            denominatorAmount = inputAmount - numeratorAmount;
        }
    }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (liquidity-pools/CurveStableSwap.sol)

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/external/curve/ICurveStableSwap.sol";

import "../common/CommonEventsAndErrors.sol";

/// @notice A wrapper around Curve v1 stable swap
library CurveStableSwap {
    using SafeERC20 for IERC20;

    struct Data {
        ICurveStableSwap pool;
        IERC20 token0;
        IERC20 token1;
    }

    event CoinExchanged(address coinSent, uint256 amountSent, uint256 amountReceived);
    event RemovedLiquidityImbalance(uint256 receivedAmount0, uint256 receivedAmount1, uint256 burnAmount);
    event LiquidityAdded(uint256 sentAmount0, uint256 sentAmount1, uint256 curveTokenAmount);
    event LiquidityRemoved(uint256 receivedAmount0, uint256 receivedAmount1, uint256 curveTokenAmount);

    error InvalidSlippage(uint256 slippage);

    uint256 internal constant CURVE_FEE_DENOMINATOR = 1e10;

    function exchangeQuote(
        Data storage self,
        address _coinIn,
        uint256 _fromAmount
    ) internal view returns (uint256) {
        (, int128 inIndex, int128 outIndex) = _getExchangeInfo(self, _coinIn);
        return self.pool.get_dy(inIndex, outIndex, _fromAmount);
    }

    function exchange(
        Data storage self,
        address _coinIn,
        uint256 _amount,
        uint256 _minAmountOut,
        address _receiver
    ) internal returns (uint256 amountOut) {
        (IERC20 tokenIn, int128 inIndex, int128 outIndex) = _getExchangeInfo(self, _coinIn);

        uint256 balance = tokenIn.balanceOf(address(this));
        if (balance < _amount) revert CommonEventsAndErrors.InsufficientBalance(address(tokenIn), _amount, balance);
        tokenIn.safeIncreaseAllowance(address(self.pool), _amount);

        amountOut = self.pool.exchange(inIndex, outIndex, _amount, _minAmountOut, _receiver);
        emit CoinExchanged(_coinIn, _amount, amountOut);
    }

    function _getExchangeInfo(
        Data storage self,
        address _coinIn
    ) private view returns (IERC20 tokenIn, int128 inIndex, int128 outIndex) {
        if (_coinIn == address(self.token0)) {
            (tokenIn, inIndex, outIndex) = (self.token0, 0, 1);
        } else if (_coinIn == address(self.token1)) {
            (tokenIn, inIndex, outIndex) = (self.token1, 1, 0);
        } else {
            revert CommonEventsAndErrors.InvalidToken(_coinIn);
        }
    }

    function removeLiquidityImbalance(
        Data storage self,
        uint256[2] memory _amounts,
        uint256 _maxBurnAmount
    ) internal returns (uint256 burnAmount) {
        uint256 balance = self.pool.balanceOf(address(this));
        if (balance <= 0) revert CommonEventsAndErrors.InsufficientBalance(address(self.pool), 1, balance);
        burnAmount = self.pool.remove_liquidity_imbalance(_amounts, _maxBurnAmount, address(this));

        emit RemovedLiquidityImbalance(_amounts[0], _amounts[1], burnAmount);
    }

    /** 
      * @notice Add LP/xLP 1:1 into the curve pool
      * @dev Add same amounts of lp and xlp tokens such that the price remains about the same
             - don't apply any peg fixing here. xLP tokens are minted 1:1
      * @param _amount The amount of LP and xLP to add into the pool.
      * @param _minAmountOut The minimum amount of curve liquidity tokens we expect in return.
      */
    function addLiquidity(
        Data storage self,
        uint256 _amount,
        uint256 _minAmountOut
    ) internal returns (uint256 liquidity) {
        uint256[2] memory amounts = [_amount, _amount];
        
        self.token0.safeIncreaseAllowance(address(self.pool), _amount);
        self.token1.safeIncreaseAllowance(address(self.pool), _amount);

        liquidity = self.pool.add_liquidity(amounts, _minAmountOut, address(this));
        emit LiquidityAdded(_amount, _amount, liquidity);
    }

    function removeLiquidity(
        Data storage self,
        uint256 _liquidity,
        uint256 _minAmount0,
        uint256 _minAmount1
    ) internal returns (uint256[2] memory balancesOut) {
        uint256 balance = self.pool.balanceOf(address(this));
        if (balance < _liquidity) revert CommonEventsAndErrors.InsufficientBalance(address(self.pool), _liquidity, balance);
        balancesOut = self.pool.remove_liquidity(_liquidity, [_minAmount0, _minAmount1]);
        emit LiquidityRemoved(balancesOut[0], balancesOut[1], _liquidity);
    }

    /** 
      * @notice Calculates the min expected amount of curve liquidity token to receive when depositing the 
      *         current eligible amount to into the curve LP:xLP liquidity pool
      * @dev Takes into account pool liquidity slippage and fees.
      * @param _liquidity The amount of LP to apply
      * @param _modelSlippage Any extra slippage to account for, given curveStableSwap.calc_token_amount() 
               is an approximation. 1e10 precision, so 1% = 1e8.
      * @return minCurveTokenAmount Expected amount of LP tokens received 
      */ 
    function minAmountOut(
        Data storage self,
        uint256 _liquidity,
        uint256 _modelSlippage
    ) internal view returns (uint256 minCurveTokenAmount) {
        uint256 feeAndSlippage = _modelSlippage + self.pool.fee();        if (feeAndSlippage > CURVE_FEE_DENOMINATOR) revert InvalidSlippage(feeAndSlippage);
        
        minCurveTokenAmount = 0;
        if (_liquidity > 0) {
            uint256[2] memory amounts = [_liquidity, _liquidity];
            minCurveTokenAmount = self.pool.calc_token_amount(amounts, true);
            unchecked {
                minCurveTokenAmount -= minCurveTokenAmount * feeAndSlippage / CURVE_FEE_DENOMINATOR;
            }
        }
    }

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/external/curve/ICurveStableSwap.sol)

interface ICurveStableSwap {
    function coins(uint256 j) external view returns (address);
    function calc_token_amount(uint256[2] calldata _amounts, bool _is_deposit) external view returns (uint256);
    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount, address destination) external returns (uint256);
    function get_dy(int128 _from, int128 _to, uint256 _from_amount) external view returns (uint256);
    function remove_liquidity(uint256 _amount, uint256[2] calldata _min_amounts) external returns (uint256[2] memory);
    function fee() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
    function remove_liquidity_imbalance(uint256[2] memory amounts, uint256 _max_burn_amount, address _receiver) external returns (uint256);
}