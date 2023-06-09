// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "Ownable.sol";
import "ERC20.sol";
import "Address.sol";
import "EnumerableSet.sol";
import "EnumerableMap.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "IERC20Metadata.sol";

import "IConicPool.sol";
import "IRewardManager.sol";
import "ICurveHandler.sol";
import "ICurveRegistryCache.sol";
import "IInflationManager.sol";
import "ILpTokenStaker.sol";
import "IConvexHandler.sol";
import "IOracle.sol";
import "IBaseRewardPool.sol";

import "LpToken.sol";
import "RewardManagerV2.sol";

import "ScaledMath.sol";
import "ArrayExtensions.sol";

contract ConicPoolV2 is IConicPool, Ownable {
    using ArrayExtensions for uint256[];
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for ILpToken;
    using ScaledMath for uint256;
    using Address for address;

    // Avoid stack depth errors
    struct DepositVars {
        uint256 exchangeRate;
        uint256 underlyingBalanceIncrease;
        uint256 mintableUnderlyingAmount;
        uint256 lpReceived;
        uint256 underlyingBalanceBefore;
        uint256 allocatedBalanceBefore;
        uint256[] allocatedPerPoolBefore;
        uint256 underlyingBalanceAfter;
        uint256 allocatedBalanceAfter;
        uint256[] allocatedPerPoolAfter;
    }

    uint256 internal constant _IDLE_RATIO_UPPER_BOUND = 0.2e18;
    uint256 internal constant _MIN_DEPEG_THRESHOLD = 0.01e18;
    uint256 internal constant _MAX_DEPEG_THRESHOLD = 0.1e18;
    uint256 internal constant _MAX_DEVIATION_UPPER_BOUND = 0.2e18;
    uint256 internal constant _DEPEG_UNDERLYING_MULTIPLIER = 2;
    uint256 internal constant _TOTAL_UNDERLYING_CACHE_EXPIRY = 3 days;
    uint256 internal constant _MAX_USD_LP_VALUE_FOR_REMOVING_CURVE_POOL = 100e18;

    IERC20 public immutable CVX;
    IERC20 public immutable CRV;
    IERC20 public constant CNC = IERC20(0x9aE380F0272E2162340a5bB646c354271c0F5cFC);
    address internal constant _WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IERC20Metadata public immutable override underlying;
    ILpToken public immutable override lpToken;

    IRewardManager public immutable rewardManager;
    IController public immutable controller;

    /// @dev once the deviation gets under this threshold, the reward distribution will be paused
    /// until the next rebalancing. This is expressed as a ratio, scaled with 18 decimals
    uint256 public maxDeviation = 0.02e18; // 2%
    uint256 public maxIdleCurveLpRatio = 0.05e18; // triggers Convex staking when exceeded
    bool public isShutdown;
    uint256 public depegThreshold = 0.03e18; // 3%
    uint256 internal _cacheUpdatedTimestamp;
    uint256 internal _cachedTotalUnderlying;

    /// @dev `true` while the reward distribution is active
    bool public rebalancingRewardActive;

    EnumerableSet.AddressSet internal _curvePools;
    EnumerableMap.AddressToUintMap internal weights; // liquidity allocation weights

    /// @dev the absolute value in terms of USD of the total deviation after
    /// the weights have been updated
    uint256 public totalDeviationAfterWeightUpdate;

    mapping(address => uint256) _cachedPrices;

    modifier onlyController() {
        require(msg.sender == address(controller), "not authorized");
        _;
    }

    constructor(
        address _underlying,
        IRewardManager _rewardManager,
        address _controller,
        string memory _lpTokenName,
        string memory _symbol,
        address _cvx,
        address _crv
    ) {
        require(
            _underlying != _cvx && _underlying != _crv && _underlying != address(CNC),
            "invalid underlying"
        );
        underlying = IERC20Metadata(_underlying);
        controller = IController(_controller);
        uint8 decimals = IERC20Metadata(_underlying).decimals();
        lpToken = new LpToken(address(this), decimals, _lpTokenName, _symbol);
        rewardManager = _rewardManager;

        CVX = IERC20(_cvx);
        CRV = IERC20(_crv);
        CVX.safeApprove(address(_rewardManager), type(uint256).max);
        CRV.safeApprove(address(_rewardManager), type(uint256).max);
        CNC.safeApprove(address(_rewardManager), type(uint256).max);
    }

    /// @dev We always delegate-call to the Curve handler, which means
    /// that we need to be able to receive the ETH to unwrap it and
    /// send it to the Curve pool, as well as to receive it back from
    /// the Curve pool when withdrawing
    receive() external payable {
        require(address(underlying) == _WETH_ADDRESS, "not WETH pool");
    }

    /// @notice Deposit underlying on behalf of someone
    /// @param underlyingAmount Amount of underlying to deposit
    /// @param minLpReceived The minimum amount of LP to accept from the deposit
    /// @return lpReceived The amount of LP received
    function depositFor(
        address account,
        uint256 underlyingAmount,
        uint256 minLpReceived,
        bool stake
    ) public override returns (uint256) {
        DepositVars memory vars;

        // Preparing deposit
        require(!isShutdown, "pool is shutdown");
        require(underlyingAmount > 0, "deposit amount cannot be zero");
        uint256 underlyingPrice_ = controller.priceOracle().getUSDPrice(address(underlying));
        (
            vars.underlyingBalanceBefore,
            vars.allocatedBalanceBefore,
            vars.allocatedPerPoolBefore
        ) = _getTotalAndPerPoolUnderlying(underlyingPrice_);
        vars.exchangeRate = _exchangeRate(vars.underlyingBalanceBefore);

        // Executing deposit
        underlying.safeTransferFrom(msg.sender, address(this), underlyingAmount);
        _depositToCurve(
            vars.allocatedBalanceBefore,
            vars.allocatedPerPoolBefore,
            underlying.balanceOf(address(this))
        );

        // Minting LP Tokens
        (
            vars.underlyingBalanceAfter,
            vars.allocatedBalanceAfter,
            vars.allocatedPerPoolAfter
        ) = _getTotalAndPerPoolUnderlying(underlyingPrice_);
        vars.underlyingBalanceIncrease = vars.underlyingBalanceAfter - vars.underlyingBalanceBefore;
        vars.mintableUnderlyingAmount = _min(underlyingAmount, vars.underlyingBalanceIncrease);
        vars.lpReceived = vars.mintableUnderlyingAmount.divDown(vars.exchangeRate);
        require(vars.lpReceived >= minLpReceived, "too much slippage");

        if (stake) {
            lpToken.mint(address(this), vars.lpReceived);
            ILpTokenStaker lpTokenStaker = controller.lpTokenStaker();
            lpToken.safeApprove(address(lpTokenStaker), vars.lpReceived);
            lpTokenStaker.stakeFor(vars.lpReceived, address(this), account);
        } else {
            lpToken.mint(account, vars.lpReceived);
        }

        _handleRebalancingRewards(
            account,
            vars.allocatedBalanceBefore,
            vars.allocatedPerPoolBefore,
            vars.allocatedBalanceAfter,
            vars.allocatedPerPoolAfter
        );

        _cachedTotalUnderlying = vars.underlyingBalanceAfter;
        _cacheUpdatedTimestamp = block.timestamp;

        emit Deposit(msg.sender, account, underlyingAmount, vars.lpReceived);
        return vars.lpReceived;
    }

    /// @notice Deposit underlying
    /// @param underlyingAmount Amount of underlying to deposit
    /// @param minLpReceived The minimum amoun of LP to accept from the deposit
    /// @return lpReceived The amount of LP received
    function deposit(
        uint256 underlyingAmount,
        uint256 minLpReceived
    ) external override returns (uint256) {
        return depositFor(msg.sender, underlyingAmount, minLpReceived, true);
    }

    /// @notice Deposit underlying
    /// @param underlyingAmount Amount of underlying to deposit
    /// @param minLpReceived The minimum amoun of LP to accept from the deposit
    /// @param stake Whether or not to stake in the LpTokenStaker
    /// @return lpReceived The amount of LP received
    function deposit(
        uint256 underlyingAmount,
        uint256 minLpReceived,
        bool stake
    ) external override returns (uint256) {
        return depositFor(msg.sender, underlyingAmount, minLpReceived, stake);
    }

    function _depositToCurve(
        uint256 totalUnderlying_,
        uint256[] memory allocatedPerPool,
        uint256 underlyingAmount_
    ) internal {
        uint256 depositsRemaining_ = underlyingAmount_;
        uint256 totalAfterDeposit_ = totalUnderlying_ + underlyingAmount_;

        // NOTE: avoid modifying `allocatedPerPool`
        uint256[] memory allocatedPerPoolCopy = allocatedPerPool.copy();

        while (depositsRemaining_ > 0) {
            (uint256 curvePoolIndex_, uint256 maxDeposit_) = _getDepositPool(
                totalAfterDeposit_,
                allocatedPerPoolCopy
            );
            // account for rounding errors
            if (depositsRemaining_ < maxDeposit_ + 1e2) {
                maxDeposit_ = depositsRemaining_;
            }

            address curvePool_ = _curvePools.at(curvePoolIndex_);

            // Depositing into least balanced pool
            uint256 toDeposit_ = _min(depositsRemaining_, maxDeposit_);
            _depositToCurvePool(curvePool_, toDeposit_);
            depositsRemaining_ -= toDeposit_;
            allocatedPerPoolCopy[curvePoolIndex_] += toDeposit_;
        }
    }

    function _getDepositPool(
        uint256 totalUnderlying_,
        uint256[] memory allocatedPerPool
    ) internal view returns (uint256 poolIndex, uint256 maxDepositAmount) {
        uint256 curvePoolCount_ = allocatedPerPool.length;
        int256 iPoolIndex = -1;
        for (uint256 i; i < curvePoolCount_; i++) {
            address curvePool_ = _curvePools.at(i);
            uint256 allocatedUnderlying_ = allocatedPerPool[i];
            uint256 targetAllocation_ = totalUnderlying_.mulDown(weights.get(curvePool_));
            if (allocatedUnderlying_ >= targetAllocation_) continue;
            uint256 maxBalance_ = targetAllocation_ + targetAllocation_.mulDown(_getMaxDeviation());
            uint256 maxDepositAmount_ = maxBalance_ - allocatedUnderlying_;
            if (maxDepositAmount_ <= maxDepositAmount) continue;
            maxDepositAmount = maxDepositAmount_;
            iPoolIndex = int256(i);
        }
        require(iPoolIndex > -1, "error retrieving deposit pool");
        poolIndex = uint256(iPoolIndex);
    }

    function _depositToCurvePool(address curvePool_, uint256 underlyingAmount_) internal {
        if (underlyingAmount_ == 0) return;
        controller.curveHandler().functionDelegateCall(
            abi.encodeWithSignature(
                "deposit(address,address,uint256)",
                curvePool_,
                underlying,
                underlyingAmount_
            )
        );

        uint256 idleCurveLpBalance_ = _idleCurveLpBalance(curvePool_);
        uint256 totalCurveLpBalance_ = _stakedCurveLpBalance(curvePool_) + idleCurveLpBalance_;

        if (idleCurveLpBalance_.divDown(totalCurveLpBalance_) >= maxIdleCurveLpRatio) {
            controller.convexHandler().functionDelegateCall(
                abi.encodeWithSignature("deposit(address,uint256)", curvePool_, idleCurveLpBalance_)
            );
        }
    }

    /// @notice Get current underlying balance of pool
    function totalUnderlying() public view virtual returns (uint256) {
        (uint256 totalUnderlying_, , ) = getTotalAndPerPoolUnderlying();

        return totalUnderlying_;
    }

    function _exchangeRate(uint256 totalUnderlying_) internal view returns (uint256) {
        uint256 lpSupply = lpToken.totalSupply();
        if (lpSupply == 0 || totalUnderlying_ == 0) return ScaledMath.ONE;

        return totalUnderlying_.divDown(lpSupply);
    }

    /// @notice Get current exchange rate for the pool's LP token to the underlying
    function exchangeRate() public view virtual override returns (uint256) {
        return _exchangeRate(totalUnderlying());
    }

    /// @notice Get current exchange rate for the pool's LP token to USD
    /// @dev This is using the cached total underlying value, so is not precisely accurate.
    function usdExchangeRate() external view virtual override returns (uint256) {
        uint256 underlyingPrice = controller.priceOracle().getUSDPrice(address(underlying));
        return _exchangeRate(_cachedTotalUnderlying).mulDown(underlyingPrice);
    }

    /// @notice Unstake LP Tokens and withdraw underlying
    /// @param conicLpAmount Amount of LP tokens to burn
    /// @param minUnderlyingReceived Minimum amount of underlying to redeem
    /// This should always be set to a reasonable value (e.g. 2%), otherwise
    /// the user withdrawing could be forced into paying a withdrawal penalty fee
    /// by another user
    /// @return uint256 Total underlying withdrawn
    function unstakeAndWithdraw(
        uint256 conicLpAmount,
        uint256 minUnderlyingReceived
    ) external returns (uint256) {
        controller.lpTokenStaker().unstakeFrom(conicLpAmount, msg.sender);
        return withdraw(conicLpAmount, minUnderlyingReceived);
    }

    /// @notice Withdraw underlying
    /// @param conicLpAmount Amount of LP tokens to burn
    /// @param minUnderlyingReceived Minimum amount of underlying to redeem
    /// This should always be set to a reasonable value (e.g. 2%), otherwise
    /// the user withdrawing could be forced into paying a withdrawal penalty fee
    /// by another user
    /// @return uint256 Total underlying withdrawn
    function withdraw(
        uint256 conicLpAmount,
        uint256 minUnderlyingReceived
    ) public override returns (uint256) {
        // Preparing Withdrawals
        require(lpToken.balanceOf(msg.sender) >= conicLpAmount, "insufficient balance");
        uint256 underlyingBalanceBefore_ = underlying.balanceOf(address(this));

        // Processing Withdrawals
        (
            uint256 totalUnderlying_,
            uint256 allocatedUnderlying_,
            uint256[] memory allocatedPerPool
        ) = getTotalAndPerPoolUnderlying();
        uint256 underlyingToReceive_ = conicLpAmount.mulDown(_exchangeRate(totalUnderlying_));
        {
            if (underlyingBalanceBefore_ < underlyingToReceive_) {
                uint256 underlyingToWithdraw_ = underlyingToReceive_ - underlyingBalanceBefore_;
                _withdrawFromCurve(allocatedUnderlying_, allocatedPerPool, underlyingToWithdraw_);
            }
        }

        // Sending Underlying and burning LP Tokens
        uint256 underlyingWithdrawn_ = _min(
            underlying.balanceOf(address(this)),
            underlyingToReceive_
        );
        require(underlyingWithdrawn_ >= minUnderlyingReceived, "too much slippage");
        lpToken.burn(msg.sender, conicLpAmount);
        underlying.safeTransfer(msg.sender, underlyingWithdrawn_);

        _cachedTotalUnderlying = totalUnderlying_ - underlyingWithdrawn_;
        _cacheUpdatedTimestamp = block.timestamp;

        emit Withdraw(msg.sender, underlyingWithdrawn_);
        return underlyingWithdrawn_;
    }

    function _withdrawFromCurve(
        uint256 totalUnderlying_,
        uint256[] memory allocatedPerPool,
        uint256 amount_
    ) internal {
        uint256 withdrawalsRemaining_ = amount_;
        uint256 totalAfterWithdrawal_ = totalUnderlying_ - amount_;

        // NOTE: avoid modifying `allocatedPerPool`
        uint256[] memory allocatedPerPoolCopy = allocatedPerPool.copy();

        while (withdrawalsRemaining_ > 0) {
            (uint256 curvePoolIndex_, uint256 maxWithdrawal_) = _getWithdrawPool(
                totalAfterWithdrawal_,
                allocatedPerPoolCopy
            );
            address curvePool_ = _curvePools.at(curvePoolIndex_);

            // Withdrawing from least balanced Curve pool
            uint256 toWithdraw_ = _min(withdrawalsRemaining_, maxWithdrawal_);
            _withdrawFromCurvePool(curvePool_, toWithdraw_);
            withdrawalsRemaining_ -= toWithdraw_;
            allocatedPerPoolCopy[curvePoolIndex_] -= toWithdraw_;
        }
    }

    function _getWithdrawPool(
        uint256 totalUnderlying_,
        uint256[] memory allocatedPerPool
    ) internal view returns (uint256 withdrawPoolIndex, uint256 maxWithdrawalAmount) {
        uint256 curvePoolCount_ = allocatedPerPool.length;
        int256 iWithdrawPoolIndex = -1;
        for (uint256 i; i < curvePoolCount_; i++) {
            address curvePool_ = _curvePools.at(i);
            uint256 weight_ = weights.get(curvePool_);
            uint256 allocatedUnderlying_ = allocatedPerPool[i];

            // If a curve pool has a weight of 0,
            // withdraw from it if it has more than the max lp value
            if (weight_ == 0) {
                uint256 price_ = controller.priceOracle().getUSDPrice(address(underlying));
                uint256 allocatedUsd = (price_ * allocatedUnderlying_) /
                    10 ** underlying.decimals();
                if (allocatedUsd >= _MAX_USD_LP_VALUE_FOR_REMOVING_CURVE_POOL / 2) {
                    return (uint256(i), allocatedUnderlying_);
                }
            }

            uint256 targetAllocation_ = totalUnderlying_.mulDown(weight_);
            if (allocatedUnderlying_ <= targetAllocation_) continue;
            uint256 minBalance_ = targetAllocation_ - targetAllocation_.mulDown(_getMaxDeviation());
            uint256 maxWithdrawalAmount_ = allocatedUnderlying_ - minBalance_;
            if (maxWithdrawalAmount_ <= maxWithdrawalAmount) continue;
            maxWithdrawalAmount = maxWithdrawalAmount_;
            iWithdrawPoolIndex = int256(i);
        }
        require(iWithdrawPoolIndex > -1, "error retrieving withdraw pool");
        withdrawPoolIndex = uint256(iWithdrawPoolIndex);
    }

    function _withdrawFromCurvePool(address curvePool_, uint256 underlyingAmount_) internal {
        ICurveRegistryCache registryCache_ = controller.curveRegistryCache();
        address curveLpToken_ = registryCache_.lpToken(curvePool_);
        uint256 lpToWithdraw_ = _underlyingToCurveLp(curveLpToken_, underlyingAmount_);
        if (lpToWithdraw_ == 0) return;

        uint256 idleCurveLpBalance_ = _idleCurveLpBalance(curvePool_);
        address rewardPool = registryCache_.getRewardPool(curvePool_);
        uint256 stakedLpBalance = IBaseRewardPool(rewardPool).balanceOf(address(this));
        uint256 totalAvailableLp = idleCurveLpBalance_ + stakedLpBalance;
        // Due to rounding errors with the conversion of underlying to LP tokens,
        // we may not have the precise amount of LP tokens to withdraw from the pool.
        // In this case, we withdraw the maximum amount of LP tokens available.
        if (totalAvailableLp < lpToWithdraw_) {
            lpToWithdraw_ = totalAvailableLp;
        }

        if (lpToWithdraw_ > idleCurveLpBalance_) {
            controller.convexHandler().functionDelegateCall(
                abi.encodeWithSignature(
                    "withdraw(address,uint256)",
                    curvePool_,
                    lpToWithdraw_ - idleCurveLpBalance_
                )
            );
        }

        controller.curveHandler().functionDelegateCall(
            abi.encodeWithSignature(
                "withdraw(address,address,uint256)",
                curvePool_,
                underlying,
                lpToWithdraw_
            )
        );
    }

    function allCurvePools() external view override returns (address[] memory) {
        return _curvePools.values();
    }

    function curvePoolsCount() external view override returns (uint256) {
        return _curvePools.length();
    }

    function getCurvePoolAtIndex(uint256 _index) external view returns (address) {
        return _curvePools.at(_index);
    }

    function isRegisteredCurvePool(address _pool) public view returns (bool) {
        return _curvePools.contains(_pool);
    }

    function getPoolWeight(address _pool) external view returns (uint256) {
        (, uint256 _weight) = weights.tryGet(_pool);
        return _weight;
    }

    // Controller and Admin functions

    function addCurvePool(address _pool) external override onlyOwner {
        require(!_curvePools.contains(_pool), "pool already added");
        ICurveRegistryCache curveRegistryCache_ = controller.curveRegistryCache();
        curveRegistryCache_.initPool(_pool);
        bool supported_ = curveRegistryCache_.hasCoinAnywhere(_pool, address(underlying));
        require(supported_, "coin not in pool");
        address curveLpToken = curveRegistryCache_.lpToken(_pool);
        require(controller.priceOracle().isTokenSupported(curveLpToken), "cannot price LP Token");

        address booster = controller.convexBooster();
        IERC20(curveLpToken).safeApprove(booster, type(uint256).max);

        if (!weights.contains(_pool)) weights.set(_pool, 0);
        require(_curvePools.add(_pool), "failed to add pool");
        emit CurvePoolAdded(_pool);
    }

    // This requires that the weight of the pool is first set to 0
    function removeCurvePool(address _pool) external override onlyOwner {
        require(_curvePools.contains(_pool), "pool not added");
        require(_curvePools.length() > 1, "cannot remove last pool");
        address curveLpToken = controller.curveRegistryCache().lpToken(_pool);
        uint256 lpTokenPrice = controller.priceOracle().getUSDPrice(curveLpToken);
        uint256 usdLpValue = totalCurveLpBalance(_pool).mulDown(lpTokenPrice);
        require(usdLpValue < _MAX_USD_LP_VALUE_FOR_REMOVING_CURVE_POOL, "pool has allocated funds");
        uint256 weight = weights.get(_pool);
        IERC20(curveLpToken).safeApprove(controller.convexBooster(), 0);
        require(weight == 0, "pool has weight set");
        require(_curvePools.remove(_pool), "pool not removed");
        require(weights.remove(_pool), "weight not removed");
        emit CurvePoolRemoved(_pool);
    }

    function updateWeights(PoolWeight[] memory poolWeights) external onlyController {
        require(poolWeights.length == _curvePools.length(), "invalid pool weights");
        uint256 total;
        for (uint256 i; i < poolWeights.length; i++) {
            address pool = poolWeights[i].poolAddress;
            require(isRegisteredCurvePool(pool), "pool is not registered");
            uint256 newWeight = poolWeights[i].weight;
            weights.set(pool, newWeight);
            emit NewWeight(pool, newWeight);
            total += newWeight;
        }

        require(total == ScaledMath.ONE, "weights do not sum to 1");

        (
            uint256 totalUnderlying_,
            uint256 totalAllocated,
            uint256[] memory allocatedPerPool
        ) = getTotalAndPerPoolUnderlying();

        uint256 totalDeviation = _computeTotalDeviation(totalUnderlying_, allocatedPerPool);
        totalDeviationAfterWeightUpdate = totalDeviation;
        rebalancingRewardActive = !_isBalanced(allocatedPerPool, totalAllocated);

        // Updating price cache for all pools
        // Used for seeing if a pool has depegged
        _updatePriceCache();
    }

    function _updatePriceCache() internal {
        uint256 length_ = _curvePools.length();
        IOracle priceOracle_ = controller.priceOracle();
        for (uint256 i; i < length_; i++) {
            address lpToken_ = controller.curveRegistryCache().lpToken(_curvePools.at(i));
            _cachedPrices[lpToken_] = priceOracle_.getUSDPrice(lpToken_);
        }
        address underlying_ = address(underlying);
        _cachedPrices[underlying_] = priceOracle_.getUSDPrice(underlying_);
    }

    function shutdownPool() external override onlyController {
        require(!isShutdown, "pool already shutdown");
        isShutdown = true;
        emit Shutdown();
    }

    function updateDepegThreshold(uint256 newDepegThreshold_) external onlyOwner {
        require(newDepegThreshold_ >= _MIN_DEPEG_THRESHOLD, "invalid depeg threshold");
        require(newDepegThreshold_ <= _MAX_DEPEG_THRESHOLD, "invalid depeg threshold");
        depegThreshold = newDepegThreshold_;
        emit DepegThresholdUpdated(newDepegThreshold_);
    }

    /// @notice Called when an underlying of a Curve Pool has depegged and we want to exit the pool.
    /// Will check if a coin has depegged, and will revert if not.
    /// Sets the weight of the Curve Pool to 0, and re-enables CNC rewards for deposits.
    /// @dev Cannot be called if the underlying of this pool itself has depegged.
    /// @param curvePool_ The Curve Pool to handle.
    function handleDepeggedCurvePool(address curvePool_) external override {
        // Validation
        require(isRegisteredCurvePool(curvePool_), "pool is not registered");
        require(weights.get(curvePool_) != 0, "pool weight already 0");
        require(!_isDepegged(address(underlying)), "underlying is depegged");
        address lpToken_ = controller.curveRegistryCache().lpToken(curvePool_);
        require(_isDepegged(lpToken_), "pool is not depegged");

        // Set target curve pool weight to 0
        // Scale up other weights to compensate
        _setWeightToZero(curvePool_);
        rebalancingRewardActive = true;

        emit HandledDepeggedCurvePool(curvePool_);
    }

    function _setWeightToZero(address curvePool_) internal {
        uint256 weight_ = weights.get(curvePool_);
        if (weight_ == 0) return;
        require(weight_ != ScaledMath.ONE, "can't remove last pool");
        uint256 scaleUp_ = ScaledMath.ONE.divDown(ScaledMath.ONE - weights.get(curvePool_));
        uint256 curvePoolLength_ = _curvePools.length();
        for (uint256 i; i < curvePoolLength_; i++) {
            address pool_ = _curvePools.at(i);
            uint256 newWeight_ = pool_ == curvePool_ ? 0 : weights.get(pool_).mulDown(scaleUp_);
            weights.set(pool_, newWeight_);
            emit NewWeight(pool_, newWeight_);
        }

        // Updating total deviation
        (
            uint256 totalUnderlying_,
            ,
            uint256[] memory allocatedPerPool
        ) = getTotalAndPerPoolUnderlying();
        uint256 totalDeviation = _computeTotalDeviation(totalUnderlying_, allocatedPerPool);
        totalDeviationAfterWeightUpdate = totalDeviation;
    }

    function _isDepegged(address asset_) internal view returns (bool) {
        uint256 depegThreshold_ = depegThreshold;
        if (asset_ == address(underlying)) depegThreshold_ *= _DEPEG_UNDERLYING_MULTIPLIER; // Threshold is higher for underlying
        uint256 cachedPrice_ = _cachedPrices[asset_];
        uint256 currentPrice_ = controller.priceOracle().getUSDPrice(asset_);
        uint256 priceDiff_ = cachedPrice_.absSub(currentPrice_);
        uint256 priceDiffPercent_ = priceDiff_.divDown(cachedPrice_);
        return priceDiffPercent_ > depegThreshold_;
    }

    /**
     * @notice Allows anyone to set the weight of a Curve pool to 0 if the Convex pool for the
     * associated PID has been shutdown. This is a very unilkely outcomu and the method does
     * not reenable rebalancing rewards.
     * @param curvePool_ Curve pool for which the Convex PID is invalid (has been shut down)
     */
    function handleInvalidConvexPid(address curvePool_) external {
        require(isRegisteredCurvePool(curvePool_), "curve pool not registered");
        ICurveRegistryCache registryCache_ = controller.curveRegistryCache();
        uint256 pid = registryCache_.getPid(curvePool_);
        require(registryCache_.isShutdownPid(pid), "convex pool pid is shutdown");
        _setWeightToZero(curvePool_);
        emit HandledInvalidConvexPid(curvePool_, pid);
    }

    function setMaxIdleCurveLpRatio(uint256 maxIdleCurveLpRatio_) external onlyOwner {
        require(maxIdleCurveLpRatio != maxIdleCurveLpRatio_, "same as current");
        require(maxIdleCurveLpRatio_ <= _IDLE_RATIO_UPPER_BOUND, "ratio exceeds upper bound");
        maxIdleCurveLpRatio = maxIdleCurveLpRatio_;
        emit NewMaxIdleCurveLpRatio(maxIdleCurveLpRatio_);
    }

    function setMaxDeviation(uint256 maxDeviation_) external onlyOwner {
        require(maxDeviation != maxDeviation_, "same as current");
        require(maxDeviation_ <= _MAX_DEVIATION_UPPER_BOUND, "deviation exceeds upper bound");
        maxDeviation = maxDeviation_;
        emit MaxDeviationUpdated(maxDeviation_);
    }

    function getWeight(address curvePool) external view returns (uint256) {
        return weights.get(curvePool);
    }

    function getWeights() external view override returns (PoolWeight[] memory) {
        uint256 length_ = _curvePools.length();
        PoolWeight[] memory weights_ = new PoolWeight[](length_);
        for (uint256 i; i < length_; i++) {
            (address pool_, uint256 weight_) = weights.at(i);
            weights_[i] = PoolWeight(pool_, weight_);
        }
        return weights_;
    }

    function getAllocatedUnderlying() external view override returns (PoolWithAmount[] memory) {
        PoolWithAmount[] memory perPoolAllocated = new PoolWithAmount[](_curvePools.length());
        (, , uint256[] memory allocated) = getTotalAndPerPoolUnderlying();

        for (uint256 i; i < perPoolAllocated.length; i++) {
            perPoolAllocated[i] = PoolWithAmount(_curvePools.at(i), allocated[i]);
        }
        return perPoolAllocated;
    }

    function computeTotalDeviation() external view override returns (uint256) {
        (
            ,
            uint256 allocatedUnderlying_,
            uint256[] memory perPoolUnderlying
        ) = getTotalAndPerPoolUnderlying();
        return _computeTotalDeviation(allocatedUnderlying_, perPoolUnderlying);
    }

    function computeDeviationRatio() external view returns (uint256) {
        (
            ,
            uint256 allocatedUnderlying_,
            uint256[] memory perPoolUnderlying
        ) = getTotalAndPerPoolUnderlying();
        if (allocatedUnderlying_ == 0) return 0;
        uint256 deviation = _computeTotalDeviation(allocatedUnderlying_, perPoolUnderlying);
        return deviation.divDown(allocatedUnderlying_);
    }

    function cachedTotalUnderlying() external view virtual override returns (uint256) {
        if (block.timestamp > _cacheUpdatedTimestamp + _TOTAL_UNDERLYING_CACHE_EXPIRY) {
            return totalUnderlying();
        }
        return _cachedTotalUnderlying;
    }

    function getTotalAndPerPoolUnderlying()
        public
        view
        returns (
            uint256 totalUnderlying_,
            uint256 totalAllocated_,
            uint256[] memory perPoolUnderlying_
        )
    {
        uint256 underlyingPrice_ = controller.priceOracle().getUSDPrice(address(underlying));
        return _getTotalAndPerPoolUnderlying(underlyingPrice_);
    }

    function totalCurveLpBalance(address curvePool_) public view returns (uint256) {
        return _stakedCurveLpBalance(curvePool_) + _idleCurveLpBalance(curvePool_);
    }

    function isBalanced() external view override returns (bool) {
        (
            ,
            uint256 allocatedUnderlying_,
            uint256[] memory allocatedPerPool_
        ) = getTotalAndPerPoolUnderlying();
        return _isBalanced(allocatedPerPool_, allocatedUnderlying_);
    }

    /**
     * @notice Returns several values related to the Omnipools's underlying assets.
     * @param underlyingPrice_ Price of the underlying asset in USD
     * @return totalUnderlying_ Total underlying value of the Omnipool
     * @return totalAllocated_ Total underlying value of the Omnipool that is allocated to Curve pools
     * @return perPoolUnderlying_ Array of underlying values of the Omnipool that is allocated to each Curve pool
     */
    function _getTotalAndPerPoolUnderlying(
        uint256 underlyingPrice_
    )
        internal
        view
        returns (
            uint256 totalUnderlying_,
            uint256 totalAllocated_,
            uint256[] memory perPoolUnderlying_
        )
    {
        uint256 curvePoolsLength_ = _curvePools.length();
        perPoolUnderlying_ = new uint256[](curvePoolsLength_);
        for (uint256 i; i < curvePoolsLength_; i++) {
            address curvePool_ = _curvePools.at(i);
            uint256 poolUnderlying_ = _curveLpToUnderlying(
                controller.curveRegistryCache().lpToken(curvePool_),
                totalCurveLpBalance(curvePool_),
                underlyingPrice_
            );
            perPoolUnderlying_[i] = poolUnderlying_;
            totalAllocated_ += poolUnderlying_;
        }
        totalUnderlying_ = totalAllocated_ + underlying.balanceOf(address(this));
    }

    function _stakedCurveLpBalance(address pool_) internal view returns (uint256) {
        return
            IBaseRewardPool(IConvexHandler(controller.convexHandler()).getRewardPool(pool_))
                .balanceOf(address(this));
    }

    function _idleCurveLpBalance(address curvePool_) internal view returns (uint256) {
        return IERC20(controller.curveRegistryCache().lpToken(curvePool_)).balanceOf(address(this));
    }

    function _curveLpToUnderlying(
        address curveLpToken_,
        uint256 curveLpAmount_,
        uint256 underlyingPrice_
    ) internal view returns (uint256) {
        return
            curveLpAmount_
                .mulDown(controller.priceOracle().getUSDPrice(curveLpToken_))
                .divDown(underlyingPrice_)
                .convertScale(18, underlying.decimals());
    }

    function _underlyingToCurveLp(
        address curveLpToken_,
        uint256 underlyingAmount_
    ) internal view returns (uint256) {
        return
            underlyingAmount_
                .mulDown(controller.priceOracle().getUSDPrice(address(underlying)))
                .divDown(controller.priceOracle().getUSDPrice(curveLpToken_))
                .convertScale(underlying.decimals(), 18);
    }

    function _computeTotalDeviation(
        uint256 allocatedUnderlying_,
        uint256[] memory perPoolAllocations_
    ) internal view returns (uint256) {
        uint256 totalDeviation;
        for (uint256 i; i < perPoolAllocations_.length; i++) {
            uint256 weight = weights.get(_curvePools.at(i));
            uint256 targetAmount = allocatedUnderlying_.mulDown(weight);
            totalDeviation += targetAmount.absSub(perPoolAllocations_[i]);
        }
        return totalDeviation;
    }

    function _handleRebalancingRewards(
        address account,
        uint256 allocatedBalanceBefore_,
        uint256[] memory allocatedPerPoolBefore,
        uint256 allocatedBalanceAfter_,
        uint256[] memory allocatedPerPoolAfter
    ) internal {
        if (!rebalancingRewardActive) return;
        uint256 deviationBefore = _computeTotalDeviation(
            allocatedBalanceBefore_,
            allocatedPerPoolBefore
        );
        uint256 deviationAfter = _computeTotalDeviation(
            allocatedBalanceAfter_,
            allocatedPerPoolAfter
        );

        controller.inflationManager().handleRebalancingRewards(
            account,
            deviationBefore,
            deviationAfter
        );

        if (_isBalanced(allocatedPerPoolAfter, allocatedBalanceAfter_)) {
            rebalancingRewardActive = false;
        }
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _isBalanced(
        uint256[] memory allocatedPerPool_,
        uint256 totalAllocated_
    ) internal view returns (bool) {
        if (totalAllocated_ == 0) return true;
        for (uint256 i; i < allocatedPerPool_.length; i++) {
            uint256 weight_ = weights.get(_curvePools.at(i));
            uint256 currentAllocated_ = allocatedPerPool_[i];

            // If a curve pool has a weight of 0,
            if (weight_ == 0) {
                uint256 price_ = controller.priceOracle().getUSDPrice(address(underlying));
                uint256 allocatedUsd_ = (price_ * currentAllocated_) / 10 ** underlying.decimals();
                if (allocatedUsd_ >= _MAX_USD_LP_VALUE_FOR_REMOVING_CURVE_POOL / 2) {
                    return false;
                }
                continue;
            }

            uint256 targetAmount = totalAllocated_.mulDown(weight_);
            uint256 deviation = targetAmount.absSub(currentAllocated_);
            uint256 deviationRatio = deviation.divDown(targetAmount);

            if (deviationRatio > maxDeviation) return false;
        }
        return true;
    }

    function _getMaxDeviation() internal view returns (uint256) {
        return rebalancingRewardActive ? 0 : maxDeviation;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

pragma solidity ^0.8.0;

import "EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "ILpToken.sol";
import "IRewardManager.sol";
import "IOracle.sol";
import "IController.sol";

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

    function controller() external view returns (IController);

    function depegThreshold() external view returns (uint256);

    function maxIdleCurveLpRatio() external view returns (uint256);

    function getPoolWeight(address curvePool) external view returns (uint256);

    function setMaxIdleCurveLpRatio(uint256 value) external;

    function updateDepegThreshold(uint256 value) external;

    function computeDeviationRatio() external view returns (uint256);

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

    function accountCheckpoint(address account) external;

    function poolCheckpoint() external returns (bool);

    function addExtraReward(address reward) external returns (bool);

    function addBatchExtraRewards(address[] memory rewards) external;

    function pool() external view returns (address);

    function setFeePercentage(uint256 _feePercentage) external;

    function claimableRewards(
        address account
    ) external view returns (uint256 cncRewards, uint256 crvRewards, uint256 cvxRewards);

    function claimEarnings() external returns (uint256, uint256, uint256);

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
        returns (address[] memory _pools, uint256[] memory poolWeights, uint256 totalUSDValue);

    function computePoolWeight(
        address pool
    ) external view returns (uint256 poolWeight, uint256 totalUSDValue);

    function currentInflationRate() external view returns (uint256);

    function getCurrentPoolInflationRate(address pool) external view returns (uint256);

    function handleRebalancingRewards(
        address account,
        uint256 deviationBefore,
        uint256 deviationAfter
    ) external;

    function addPoolRebalancingRewardHandler(
        address poolAddress,
        address rebalancingRewardHandler
    ) external;

    function removePoolRebalancingRewardHandler(
        address poolAddress,
        address rebalancingRewardHandler
    ) external;

    function rebalancingRewardHandlers(
        address poolAddress
    ) external view returns (address[] memory);

    function hasPoolRebalancingRewardHandlers(
        address poolAddress,
        address handler
    ) external view returns (bool);
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

    function stakeFor(uint256 amount, address conicPool, address account) external;

    function unstakeFor(uint256 amount, address conicPool, address account) external;

    function unstakeFrom(uint256 amount, address account) external;

    function getUserBalanceForPool(
        address conicPool,
        address account
    ) external view returns (uint256);

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
    ) external view returns (int128, int128, bool);

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
    function poolInfo(
        uint256 pid
    )
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

    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns (bool);

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
        uint256 fromBalance = 10 ** fromDecimals;
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

    function add_liquidity(
        uint256[2] memory amounts,
        uint256 min_mint_amount
    ) external returns (uint256);

    function add_liquidity(
        uint256[3] memory amounts,
        uint256 min_mint_amount,
        bool use_eth,
        address receiver
    ) external returns (uint256);

    function add_liquidity(
        uint256[3] memory amounts,
        uint256 min_mint_amount
    ) external returns (uint256);

    function remove_liquidity(
        uint256 _amount,
        uint256[2] memory min_amounts,
        bool use_eth,
        address receiver
    ) external;

    function remove_liquidity(uint256 _amount, uint256[2] memory min_amounts) external;

    function remove_liquidity(
        uint256 _amount,
        uint256[3] memory min_amounts,
        bool use_eth,
        address receiver
    ) external;

    function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts) external;

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount,
        bool use_eth,
        address receiver
    ) external returns (uint256);

    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);

    function calc_token_amount(uint256[] memory amounts) external view returns (uint256);

    function calc_withdraw_one_coin(
        uint256 token_amount,
        uint256 i
    ) external view returns (uint256);

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

    function remove_liquidity_imbalance(
        uint256[4] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity_imbalance(
        uint256[3] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity_imbalance(
        uint256[2] calldata amounts,
        uint256 max_burn_amount
    ) external;

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

    function get_dy(int128 i, int128 j, uint256 _dx) external view returns (uint256);

    function calc_token_amount(
        uint256[4] calldata amounts,
        bool deposit
    ) external view returns (uint256);

    function calc_token_amount(
        uint256[3] calldata amounts,
        bool deposit
    ) external view returns (uint256);

    function calc_token_amount(
        uint256[2] calldata amounts,
        bool deposit
    ) external view returns (uint256);

    function calc_withdraw_one_coin(
        uint256 _token_amount,
        int128 i
    ) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

library ScaledMath {
    uint256 internal constant DECIMALS = 18;
    uint256 internal constant ONE = 10 ** DECIMALS;

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / ONE;
    }

    function mulDown(uint256 a, uint256 b, uint256 decimals) internal pure returns (uint256) {
        return (a * b) / (10 ** decimals);
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * ONE) / b;
    }

    function divDown(uint256 a, uint256 b, uint256 decimals) internal pure returns (uint256) {
        return (a * 10 ** decimals) / b;
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

    function mulDown(int256 a, int256 b, uint256 decimals) internal pure returns (int256) {
        return (a * b) / int256(10 ** decimals);
    }

    function divDown(int256 a, int256 b) internal pure returns (int256) {
        return (a * int256(ONE)) / b;
    }

    function divDownUint128(uint128 a, uint128 b) internal pure returns (uint128) {
        return (a * uint128(ONE)) / b;
    }

    function divDown(int256 a, int256 b, uint256 decimals) internal pure returns (int256) {
        return (a * int256(10 ** decimals)) / b;
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
        return a * (10 ** (toDecimals - fromDecimals));
    }

    function downscale(
        uint256 a,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (uint256) {
        return a / (10 ** (fromDecimals - toDecimals));
    }

    function upscale(
        int256 a,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (int256) {
        return a * int256(10 ** (toDecimals - fromDecimals));
    }

    function downscale(
        int256 a,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (int256) {
        return a / int256(10 ** (fromDecimals - toDecimals));
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

interface ICurveHandler {
    function deposit(address _curvePool, address _token, uint256 _amount) external;

    function withdraw(address _curvePool, address _token, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IConvexHandler {
    function deposit(address _curvePool, uint256 _amount) external;

    function claimBatchEarnings(address[] memory _curvePools, address _conicPool) external;

    function getRewardPool(address _curvePool) external view returns (address);

    function getCrvEarned(address _account, address _curvePool) external view returns (uint256);

    function getCrvEarnedBatch(
        address _account,
        address[] memory _curvePools
    ) external view returns (uint256);

    function computeClaimableConvex(uint256 crvAmount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IBaseRewardPool {
    function stakeFor(address, uint256) external;

    function stake(uint256) external;

    function stakeAll() external returns (bool);

    function withdraw(uint256 amount, bool claim) external returns (bool);

    function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);

    function earned(address account) external view returns (uint256);

    function getReward() external;

    function getReward(address _account, bool _claimExtras) external;

    function extraRewardsLength() external view returns (uint256);

    function extraRewards(uint256 _pid) external view returns (address);

    function rewardToken() external view returns (address);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "ERC20.sol";
import "ILpToken.sol";
import "IConicPool.sol";

contract LpToken is ILpToken, ERC20 {
    address public immutable minter;
    modifier onlyMinter() {
        require(msg.sender == minter, "not authorized");
        _;
    }

    uint8 private __decimals;

    constructor(
        address _minter,
        uint8 _decimals,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        minter = _minter;
        __decimals = _decimals;
    }

    function decimals() public view virtual override(ERC20, IERC20Metadata) returns (uint8) {
        return __decimals;
    }

    function mint(
        address _account,
        uint256 _amount
    ) external override onlyMinter returns (uint256) {
        _mint(_account, _amount);
        return _amount;
    }

    function burn(address _owner, uint256 _amount) external override onlyMinter returns (uint256) {
        _burn(_owner, _amount);
        return _amount;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "Ownable.sol";
import "Initializable.sol";
import "EnumerableSet.sol";
import "SafeERC20.sol";
import "IERC20Metadata.sol";

import "IConicPool.sol";
import "ILpToken.sol";
import "IRewardManager.sol";
import "IConvexHandler.sol";
import "ICurveHandler.sol";
import "IController.sol";
import "IOracle.sol";
import "IInflationManager.sol";
import "ILpTokenStaker.sol";
import "ICNCLockerV2.sol";
import "ICurvePoolV2.sol";
import "UniswapRouter02.sol";

import "ScaledMath.sol";

contract RewardManagerV2 is IRewardManager, Ownable, Initializable {
    using ScaledMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct RewardMeta {
        uint256 earnedIntegral;
        uint256 lastHoldings;
        mapping(address => uint256) accountIntegral;
        mapping(address => uint256) accountShare;
    }

    IERC20 public constant CVX = IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    IERC20 public constant CRV = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20 public constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 public constant CNC = IERC20(0x9aE380F0272E2162340a5bB646c354271c0F5cFC);
    UniswapRouter02 public constant SUSHISWAP =
        UniswapRouter02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    ICurvePoolV2 public constant CNC_ETH_POOL =
        ICurvePoolV2(0x838af967537350D2C44ABB8c010E49E32673ab94);

    uint256 public constant MAX_FEE_PERCENTAGE = 3e17;
    uint256 public constant SLIPPAGE_THRESHOLD = 0.95e18; // 5% slippage as a multiplier

    bytes32 internal constant _CNC_KEY = "cnc";
    bytes32 internal constant _CRV_KEY = "crv";
    bytes32 internal constant _CVX_KEY = "cvx";

    address public override pool;
    ILpToken public lpToken;
    IERC20 public immutable underlying;
    IController public immutable controller;
    ICNCLockerV2 public immutable locker;
    bool internal _claimingCNC;

    EnumerableSet.AddressSet internal _extraRewards;
    mapping(address => address) public extraRewardsCurvePool;
    mapping(bytes32 => RewardMeta) internal _rewardsMeta;

    bool public feesEnabled;
    uint256 public feePercentage;

    constructor(address _controller, address _underlying, address cncLocker) {
        underlying = IERC20(_underlying);
        controller = IController(_controller);
        WETH.safeApprove(address(CNC_ETH_POOL), type(uint256).max);
        locker = ICNCLockerV2(cncLocker);
    }

    function initialize(address _pool) external onlyOwner initializer {
        pool = _pool;
        lpToken = IConicPool(_pool).lpToken();
    }

    /// @notice Updates the internal fee accounting state. Returns `true` if rewards were claimed
    function poolCheckpoint() public override returns (bool) {
        IConvexHandler convexHandler = IConvexHandler(controller.convexHandler());

        (uint256 crvHoldings, uint256 cvxHoldings, uint256 cncHoldings) = _getHoldings(
            convexHandler
        );
        uint256 crvEarned = crvHoldings - _rewardsMeta[_CRV_KEY].lastHoldings;
        uint256 cvxEarned = cvxHoldings - _rewardsMeta[_CVX_KEY].lastHoldings;
        uint256 cncEarned = cncHoldings - _rewardsMeta[_CNC_KEY].lastHoldings;

        uint256 crvFee;
        uint256 cvxFee;

        if (feesEnabled) {
            crvFee = crvEarned.mulDown(feePercentage);
            cvxFee = cvxEarned.mulDown(feePercentage);
            crvEarned -= crvFee;
            cvxEarned -= cvxFee;
            crvHoldings -= crvFee;
            cvxHoldings -= cvxFee;
        }

        uint256 _totalStaked = controller.lpTokenStaker().getBalanceForPool(pool);
        if (_totalStaked > 0) {
            _updateEarned(_CVX_KEY, cvxHoldings, cvxEarned, _totalStaked);
            _updateEarned(_CRV_KEY, crvHoldings, crvEarned, _totalStaked);
            _updateEarned(_CNC_KEY, cncHoldings, cncEarned, _totalStaked);
        }

        if (!feesEnabled) {
            return false;
        }

        bool rewardsClaimed = false;

        if (crvFee > CRV.balanceOf(pool) || cvxFee > CVX.balanceOf(pool)) {
            _claimPoolEarningsAndSellRewardTokens();
            rewardsClaimed = true;
        }

        CRV.safeTransferFrom(pool, address(this), crvFee);
        CVX.safeTransferFrom(pool, address(this), cvxFee);

        // Fee transfer to the CNC locker
        CRV.safeApprove(address(locker), crvFee);
        CVX.safeApprove(address(locker), cvxFee);
        locker.receiveFees(crvFee, cvxFee);

        return rewardsClaimed;
    }

    function _updateEarned(
        bytes32 key,
        uint256 holdings,
        uint256 earned,
        uint256 _totalSupply
    ) internal {
        _rewardsMeta[key].earnedIntegral += earned.divDown(_totalSupply);
        _rewardsMeta[key].lastHoldings = holdings;
    }

    function _getEarnedRewards()
        internal
        view
        returns (uint256 crvEarned, uint256 cvxEarned, uint256 cncEarned)
    {
        IConvexHandler convexHandler = IConvexHandler(controller.convexHandler());
        return _getEarnedRewards(convexHandler);
    }

    function _getHoldings(
        IConvexHandler convexHandler
    ) internal view returns (uint256 crvHoldings, uint256 cvxHoldings, uint256 cncHoldings) {
        address[] memory curvePools = IConicPool(pool).allCurvePools();

        uint256 claimableCRV = convexHandler.getCrvEarnedBatch(pool, curvePools);
        crvHoldings = CRV.balanceOf(pool) + claimableCRV;

        uint256 claimableCVX = convexHandler.computeClaimableConvex(claimableCRV);
        cvxHoldings = CVX.balanceOf(pool) + claimableCVX;
        cncHoldings = CNC.balanceOf(pool);
        if (!_claimingCNC) {
            cncHoldings += controller.lpTokenStaker().claimableCnc(pool);
        }
    }

    function _getEarnedRewards(
        IConvexHandler convexHandler
    ) internal view returns (uint256 crvEarned, uint256 cvxEarned, uint256 cncEarned) {
        (
            uint256 currentHoldingsCRV,
            uint256 currentHoldingsCVX,
            uint256 currentHoldingsCNC
        ) = _getHoldings(convexHandler);

        crvEarned = currentHoldingsCRV - _rewardsMeta[_CRV_KEY].lastHoldings;
        cvxEarned = currentHoldingsCVX - _rewardsMeta[_CVX_KEY].lastHoldings;
        cncEarned = currentHoldingsCNC - _rewardsMeta[_CNC_KEY].lastHoldings;
    }

    function accountCheckpoint(address account) external {
        _accountCheckpoint(account);
    }

    function _accountCheckpoint(address account) internal {
        uint256 accountBalance = controller.lpTokenStaker().getUserBalanceForPool(pool, account);
        poolCheckpoint();
        _updateAccountRewardsMeta(_CNC_KEY, account, accountBalance);
        _updateAccountRewardsMeta(_CRV_KEY, account, accountBalance);
        _updateAccountRewardsMeta(_CVX_KEY, account, accountBalance);
    }

    function _updateAccountRewardsMeta(bytes32 key, address account, uint256 balance) internal {
        RewardMeta storage meta = _rewardsMeta[key];
        uint256 share = balance.mulDown(meta.earnedIntegral - meta.accountIntegral[account]);
        meta.accountShare[account] += share;
        meta.accountIntegral[account] = meta.earnedIntegral;
    }

    /// @notice Claims all CRV, CVX and CNC earned by a user. All extra reward
    /// tokens earned will be sold for CNC.
    /// @dev Conic pool LP tokens need to be staked in the `LpTokenStaker` in
    /// order to receive a share of the CRV, CVX and CNC earnings.
    /// after selling all extra reward tokens.
    function claimEarnings() public override returns (uint256, uint256, uint256) {
        _accountCheckpoint(msg.sender);
        uint256 crvAmount = _rewardsMeta[_CRV_KEY].accountShare[msg.sender];
        uint256 cvxAmount = _rewardsMeta[_CVX_KEY].accountShare[msg.sender];
        uint256 cncAmount = _rewardsMeta[_CNC_KEY].accountShare[msg.sender];

        if (
            crvAmount > CRV.balanceOf(pool) ||
            cvxAmount > CVX.balanceOf(pool) ||
            cncAmount > CNC.balanceOf(pool)
        ) {
            _claimPoolEarningsAndSellRewardTokens();
        }
        _rewardsMeta[_CNC_KEY].accountShare[msg.sender] = 0;
        _rewardsMeta[_CVX_KEY].accountShare[msg.sender] = 0;
        _rewardsMeta[_CRV_KEY].accountShare[msg.sender] = 0;

        CRV.safeTransferFrom(pool, msg.sender, crvAmount);
        CVX.safeTransferFrom(pool, msg.sender, cvxAmount);
        CNC.safeTransferFrom(pool, msg.sender, cncAmount);

        (
            uint256 currentHoldingsCRV,
            uint256 currentHoldingsCVX,
            uint256 currentHoldingsCNC
        ) = _getHoldings(IConvexHandler(controller.convexHandler()));
        _rewardsMeta[_CRV_KEY].lastHoldings = currentHoldingsCRV;
        _rewardsMeta[_CVX_KEY].lastHoldings = currentHoldingsCVX;
        _rewardsMeta[_CNC_KEY].lastHoldings = currentHoldingsCNC;

        emit EarningsClaimed(msg.sender, cncAmount, crvAmount, cvxAmount);
        return (cncAmount, crvAmount, cvxAmount);
    }

    /// @notice Claims all claimable CVX and CRV from Convex for all staked Curve LP tokens.
    /// Then Swaps all additional rewards tokens for CNC.
    function claimPoolEarningsAndSellRewardTokens() external override {
        if (!poolCheckpoint()) {
            _claimPoolEarningsAndSellRewardTokens();
        }
    }

    function _claimPoolEarningsAndSellRewardTokens() internal {
        _claimPoolEarnings();

        uint256 cncBalanceBefore_ = CNC.balanceOf(pool);

        _sellRewardTokens();

        uint256 receivedCnc_ = CNC.balanceOf(pool) - cncBalanceBefore_;
        uint256 _totalStaked = controller.lpTokenStaker().getBalanceForPool(pool);
        if (_totalStaked > 0)
            _rewardsMeta[_CNC_KEY].earnedIntegral += receivedCnc_.divDown(_totalStaked);
        emit SoldRewardTokens(receivedCnc_);
    }

    /// @notice Claims all claimable CVX and CRV from Convex for all staked Curve LP tokens
    function _claimPoolEarnings() internal {
        _claimingCNC = true;
        controller.lpTokenStaker().claimCNCRewardsForPool(pool);
        _claimingCNC = false;

        uint256 cvxBalance = CVX.balanceOf(pool);
        uint256 crvBalance = CRV.balanceOf(pool);

        address convexHandler = controller.convexHandler();

        IConvexHandler(convexHandler).claimBatchEarnings(IConicPool(pool).allCurvePools(), pool);

        uint256 claimedCvx = CVX.balanceOf(pool) - cvxBalance;
        uint256 claimedCrv = CRV.balanceOf(pool) - crvBalance;

        emit ClaimedRewards(claimedCrv, claimedCvx);
    }

    /// @notice Swaps all additional rewards tokens for CNC.
    function _sellRewardTokens() internal {
        uint256 extraRewardsLength_ = _extraRewards.length();
        if (extraRewardsLength_ == 0) return;
        for (uint256 i; i < extraRewardsLength_; i++) {
            _swapRewardTokenForWeth(_extraRewards.at(i));
        }
        _swapWethForCNC();
    }

    function listExtraRewards() external view returns (address[] memory) {
        return _extraRewards.values();
    }

    function addExtraReward(address reward) public override onlyOwner returns (bool) {
        require(reward != address(0), "invalid address");
        require(
            reward != address(CVX) &&
                reward != address(CRV) &&
                reward != address(underlying) &&
                reward != address(CNC),
            "token not allowed"
        );

        // Checking reward token isn't a Curve Pool LP Token
        address[] memory curvePools_ = IConicPool(pool).allCurvePools();
        for (uint256 i; i < curvePools_.length; i++) {
            address curveLpToken_ = controller.curveRegistryCache().lpToken(curvePools_[i]);
            require(reward != curveLpToken_, "token not allowed");
        }

        IERC20(reward).safeApprove(address(SUSHISWAP), 0);
        IERC20(reward).safeApprove(address(SUSHISWAP), type(uint256).max);
        emit ExtraRewardAdded(reward);
        return _extraRewards.add(reward);
    }

    function addBatchExtraRewards(address[] memory _rewards) external override onlyOwner {
        for (uint256 i; i < _rewards.length; i++) {
            addExtraReward(_rewards[i]);
        }
    }

    function removeExtraReward(address tokenAddress) external onlyOwner {
        _extraRewards.remove(tokenAddress);
        emit ExtraRewardRemoved(tokenAddress);
    }

    function setExtraRewardsCurvePool(address extraReward_, address curvePool_) external onlyOwner {
        require(curvePool_ != extraRewardsCurvePool[extraReward_], "must be different to current");
        if (curvePool_ != address(0)) {
            IERC20(extraReward_).safeApprove(curvePool_, 0);
            IERC20(extraReward_).safeApprove(curvePool_, type(uint256).max);
        }
        extraRewardsCurvePool[extraReward_] = curvePool_;
        emit ExtraRewardsCurvePoolSet(extraReward_, curvePool_);
    }

    function setFeePercentage(uint256 _feePercentage) external override onlyOwner {
        require(_feePercentage < MAX_FEE_PERCENTAGE, "cannot set fee percentage to more than 30%");
        require(locker.totalBoosted() > 0);
        feePercentage = _feePercentage;
        feesEnabled = true;
        emit FeesSet(feePercentage);
    }

    function claimableRewards(
        address account
    ) external view returns (uint256 cncRewards, uint256 crvRewards, uint256 cvxRewards) {
        uint256 _totalStaked = controller.lpTokenStaker().getBalanceForPool(pool);
        if (_totalStaked == 0) return (0, 0, 0);
        (uint256 crvEarned, uint256 cvxEarned, uint256 cncEarned) = _getEarnedRewards();
        uint256 userBalance = controller.lpTokenStaker().getUserBalanceForPool(pool, account);

        cncRewards = _getClaimableReward(
            account,
            _CNC_KEY,
            cncEarned,
            userBalance,
            _totalStaked,
            false
        );
        crvRewards = _getClaimableReward(
            account,
            _CRV_KEY,
            crvEarned,
            userBalance,
            _totalStaked,
            feesEnabled
        );
        cvxRewards = _getClaimableReward(
            account,
            _CVX_KEY,
            cvxEarned,
            userBalance,
            _totalStaked,
            feesEnabled
        );
    }

    function _getClaimableReward(
        address account,
        bytes32 key,
        uint256 earned,
        uint256 userBalance,
        uint256 _totalSupply,
        bool deductFee
    ) internal view returns (uint256) {
        RewardMeta storage meta = _rewardsMeta[key];
        uint256 integral = meta.earnedIntegral;
        if (deductFee) {
            integral += earned.divDown(_totalSupply).mulDown(ScaledMath.ONE - feePercentage);
        } else {
            integral += earned.divDown(_totalSupply);
        }
        return
            meta.accountShare[account] +
            userBalance.mulDown(integral - meta.accountIntegral[account]);
    }

    function _swapRewardTokenForWeth(address rewardToken_) internal {
        uint256 tokenBalance_ = IERC20(rewardToken_).balanceOf(address(this));
        if (tokenBalance_ == 0) return;

        ICurvePoolV2 curvePool_ = ICurvePoolV2(extraRewardsCurvePool[rewardToken_]);
        if (address(curvePool_) != address(0)) {
            (int128 i, int128 j, ) = controller.curveRegistryCache().coinIndices(
                address(curvePool_),
                rewardToken_,
                address(WETH)
            );
            (uint256 from_, uint256 to_) = (uint256(uint128(i)), uint256(uint128(j)));
            curvePool_.exchange(
                from_,
                to_,
                tokenBalance_,
                _minAmountOut(address(rewardToken_), address(WETH), tokenBalance_),
                false,
                address(this)
            );
            return;
        }

        address[] memory path_ = new address[](2);
        path_[0] = rewardToken_;
        path_[1] = address(WETH);
        SUSHISWAP.swapExactTokensForTokens(
            tokenBalance_,
            _minAmountOut(address(rewardToken_), address(WETH), tokenBalance_),
            path_,
            address(this),
            block.timestamp
        );
    }

    function _swapWethForCNC() internal {
        uint256 wethBalance_ = WETH.balanceOf(address(this));
        if (wethBalance_ == 0) return;
        CNC_ETH_POOL.exchange(
            0,
            1,
            wethBalance_,
            _minAmountOut(address(WETH), address(CNC), wethBalance_),
            false,
            pool
        );
    }

    function _minAmountOut(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) internal view returns (uint256) {
        IOracle oracle_ = controller.priceOracle();

        if (tokenIn_ == tokenOut_) {
            return amountIn_;
        }

        // If we don't have a price for either token, we can't calculate the min amount out
        // This should only ever happen for very minor tokens, so we accept the risk of not having
        // slippage protection in that case
        if (!oracle_.isTokenSupported(tokenIn_) || !oracle_.isTokenSupported(tokenOut_)) {
            return 0;
        }

        return
            amountIn_
                .mulDown(oracle_.getUSDPrice(tokenIn_))
                .divDown(oracle_.getUSDPrice(tokenOut_))
                .convertScale(
                    IERC20Metadata(tokenIn_).decimals(),
                    IERC20Metadata(tokenOut_).decimals()
                )
                .mulDown(SLIPPAGE_THRESHOLD);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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

    function lock(uint256 amount, uint64 lockTime, bool relock) external;

    function lockFor(uint256 amount, uint64 lockTime, bool relock, address account) external;

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

    function claimableFees(
        address account
    ) external view returns (uint256 claimableCrv, uint256 claimableCvx);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface UniswapRouter02 {
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external returns (uint256 amountIn);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external view returns (uint256 amountOut);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsOut(
        uint256 amountIn,
        address[] memory path
    ) external view returns (uint256[] memory amounts);

    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) external view returns (uint256 reserveA, uint256 reserveB);

    function WETH() external pure returns (address);
}

interface UniswapV2Pair {
    function getReserves()
        external
        view
        returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

interface UniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

library ArrayExtensions {
    function copy(uint256[] memory array) internal pure returns (uint256[] memory) {
        uint256[] memory copy_ = new uint256[](array.length);
        for (uint256 i = 0; i < array.length; i++) {
            copy_[i] = array[i];
        }
        return copy_;
    }
}