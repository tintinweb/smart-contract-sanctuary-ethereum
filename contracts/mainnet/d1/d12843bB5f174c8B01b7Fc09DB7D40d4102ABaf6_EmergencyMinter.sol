// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "Ownable.sol";

import "IController.sol";
import "ICNCToken.sol";
import "IMinter.sol";

/// @notice this contract will be added as a minter to the CNC token
/// and will only be allow to add new minters for the first three months
/// to be able to recover in case of an issue in the protocol
/// Adding a minter will always be a governance decision and will have a
/// timelock of 7 days (enforced by the governance proxy)
/// to allow the community to review the decision
/// should there ever be a need to add a new minter
/// This will only be used in case of an emergency and should not actually
/// be used should the protocol operate as intended
contract EmergencyMinter is Ownable {
    event LpTokenStakerSwitched(address previousTokenStaker, address newTokenStaker);
    event RebalancingRewardsHandlerSwitched(address previousHandler, address newHandler);
    event Shutdown();

    uint256 public constant ACTIVE_TIME = 90 days;

    ICNCToken public immutable cnc;
    IController public immutable controller;
    uint256 public immutable deployedAt;

    constructor(ICNCToken _cnc, IController _controller) {
        cnc = _cnc;
        controller = _controller;
        deployedAt = block.timestamp;
    }

    /// @notice this switches the rebalancing reward handler in charge of minting CNC as reward
    /// it replaces the reward handler for all the pools that have the previous handler
    /// this should typicall be all the Omnipools, since at launch, they will all have
    /// the same reward handler
    function switchRebalancingRewardsHandler(address previousHandler, address newHandler)
        external
        onlyOwner
    {
        address[] memory pools = controller.listPools();
        IInflationManager inflationManager = controller.inflationManager();
        for (uint256 i; i < pools.length; i++) {
            address pool = pools[i];
            if (inflationManager.hasPoolRebalancingRewardHandlers(pool, previousHandler)) {
                inflationManager.removePoolRebalancingRewardHandler(pool, previousHandler);
                inflationManager.addPoolRebalancingRewardHandler(pool, newHandler);
            }
        }
        _switchMinter(IMinter(previousHandler), IMinter(newHandler));
        emit RebalancingRewardsHandlerSwitched(previousHandler, newHandler);
    }

    // NOTE: If a new LpTokenStaker is created, the previous one should be shut down first.
    // Otherwise there is a risk of double counting inflation.
    // Also to rescue rewards, one should call `claimPoolEarningsAndSellRewardTokens` for the reward managers
    function switchLpTokenStaker(address previousTokenStaker, address newTokenStaker)
        external
        onlyOwner
    {
        require(
            address(controller.lpTokenStaker()) == previousTokenStaker,
            "EmergencyMinter: invalid staker"
        );
        ILpTokenStaker(previousTokenStaker).shutdown();
        controller.setLpTokenStaker(newTokenStaker);
        _switchMinter(IMinter(previousTokenStaker), IMinter(newTokenStaker));
        emit LpTokenStakerSwitched(previousTokenStaker, newTokenStaker);
    }

    /// @notice renounces minting rights for `currentMinter` and adds them to `replacementMinter`
    /// This is a critical operation that should only be executed in case an issue arises and will have a 7 days timelock
    /// This function will only be callable for the first 90 days after deployment
    function _switchMinter(IMinter currentMinter, IMinter replacementMinter) internal {
        require(block.timestamp < deployedAt + ACTIVE_TIME, "EmergencyMinter: no longer active");
        require(
            address(currentMinter) != address(replacementMinter),
            "EmergencyMinter: same minter"
        );
        require(
            _isMinter(address(currentMinter)),
            "EmergencyMinter: currentMinter is not a minter"
        );
        require(
            replacementMinter.supportsInterface(IMinter.renounceMinterRights.selector),
            "EmergencyMinter: invalid minter"
        );

        currentMinter.renounceMinterRights();
        cnc.addMinter(address(replacementMinter));
    }

    /// @notice after the 90 days period, the contract cannot add new minters anymore
    /// and this can be called to remove it from the list of minters,
    /// although this will in practice not make a difference
    function shutdown() external {
        require(block.timestamp >= deployedAt + ACTIVE_TIME, "EmergencyMinter: still active");
        cnc.renounceMinterRights();
        emit Shutdown();
    }

    /// @dev we do not have a constant-time way to check if an address is a minter
    /// so we need to iterate through all the minters
    /// there should only ever be three minters when this function is called, so this is not an issue
    function _isMinter(address minter) internal view returns (bool) {
        address[] memory minters = cnc.listMinters();
        for (uint256 i; i < minters.length; i++) {
            if (minters[i] == address(minter)) {
                return true;
            }
        }
        return false;
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

import "IERC165.sol";

interface IMinter is IERC165 {
    function renounceMinterRights() external;
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