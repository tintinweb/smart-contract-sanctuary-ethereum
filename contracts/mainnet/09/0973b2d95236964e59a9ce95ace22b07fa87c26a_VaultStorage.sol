// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.4;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import {IVaultStorage} from "../interfaces/IVaultStorage.sol";

import {Constants} from "../libraries/Constants.sol";
import {Faucet} from "../libraries/Faucet.sol";
import {SharedEvents} from "../libraries/SharedEvents.sol";

contract VaultStorage is IVaultStorage, Faucet {
    address public override governance;

    //@dev Uniswap pools tick spacing
    int24 public override tickSpacing = 60;

    //@dev twap period to use for rebalance calculations
    uint32 public override twapPeriod = 180 seconds;

    //@dev max amount of wETH that strategy accept for deposit
    uint256 public override cap;

    //@dev lower and upper ticks in Uniswap pools
    // Removed
    int24 public override orderEthUsdcLower;
    int24 public override orderEthUsdcUpper;
    int24 public override orderOsqthEthLower;
    int24 public override orderOsqthEthUpper;

    //@dev timestamp when last rebalance executed
    uint256 public override timeAtLastRebalance;

    //@dev ETH/USDC price when last rebalance executed
    uint256 public override ethPriceAtLastRebalance;

    //@dev min price change for initiating rebalance (1.69%)
    uint256 public override rebalanceThreshold = 10169e14;

    //@dev implied volatility when last rebalance executed
    uint256 public override ivAtLastRebalance;

    //@dev time difference to trigger a hedge (seconds)
    uint256 public override rebalanceTimeThreshold;
    uint256 public override rebalancePriceThreshold;

    //@dev iv adjustment parameter (0.05)
    uint256 public override adjParam = 5e16;

    //@dev ticks thresholds for boundaries calculation
    //values for tests
    int24 public override baseThreshold = 1440;

    //@dev protocol fee expressed as multiple of 1e-6
    uint256 public override protocolFee;

    //@dev accrued fees
    uint256 public override accruedFeesEth;
    uint256 public override accruedFeesUsdc;
    uint256 public override accruedFeesOsqth;

    //@dev total value
    uint256 public override totalValue;

    //@dev rebalance auction duration (seconds)
    uint256 public override auctionTime;

    //@dev start auction price multiplier for rebalance buy auction and reserve price for rebalance sell auction (scaled 1e18)
    uint256 public override minPriceMultiplier;
    uint256 public override maxPriceMultiplier;

    bool public override isSystemPaused = false;

    /**
     * @notice strategy constructor
       @param _cap max amount of wETH that strategy accepts for deposits
       @param _rebalanceTimeThreshold rebalance time threshold (seconds)
       @param _rebalancePriceThreshold rebalance price threshold (0.05*1e18 = 5%)
       @param _auctionTime auction duration (seconds)
       @param _minPriceMultiplier minimum auction price multiplier (0.95*1e18 = min auction price is 95% of twap)
       @param _maxPriceMultiplier maximum auction price multiplier (1.05*1e18 = max auction price is 105% of twap)
       @param _governance governance address
     */
    constructor(
        uint256 _cap,
        uint256 _rebalanceTimeThreshold,
        uint256 _rebalancePriceThreshold,
        uint256 _auctionTime,
        uint256 _minPriceMultiplier,
        uint256 _maxPriceMultiplier,
        uint256 _protocolFee,
        address _governance
    ) Faucet() {
        cap = _cap;

        protocolFee = _protocolFee;

        rebalanceTimeThreshold = _rebalanceTimeThreshold;
        rebalancePriceThreshold = _rebalancePriceThreshold;

        auctionTime = _auctionTime;
        minPriceMultiplier = _minPriceMultiplier;
        maxPriceMultiplier = _maxPriceMultiplier;

        timeAtLastRebalance = 0;
        ivAtLastRebalance = 0;

        governance = _governance;
    }

    /**
     * @notice owner can transfer his admin power to another address
     * @param _governance new governance address
     */
    function setGovernance(address _governance) external override onlyGovernance {
        governance = _governance;
    }

    /**
     * @notice owner can set the strategy cap in USD terms
     * @dev deposits are rejected if it would put the strategy above the cap amount
     * @param _cap the maximum strategy collateral in USD, checked on deposits
     */
    function setCap(uint256 _cap) external onlyGovernance {
        cap = _cap;
    }

    /**
     * @notice owner can set the protocol fee expressed as multiple of 1e-6
     * @param _protocolFee the protocol fee, scaled by 1e18
     */
    function setProtocolFee(uint256 _protocolFee) external onlyGovernance {
        protocolFee = _protocolFee;
    }

    /**
     * @notice owner can set the hedge time threshold in seconds that determines how often the strategy can be hedged
     * @param _rebalanceTimeThreshold the rebalance time threshold, in seconds
     */
    function setRebalanceTimeThreshold(uint256 _rebalanceTimeThreshold) external onlyGovernance {
        rebalanceTimeThreshold = _rebalanceTimeThreshold;
    }

    /**
     * @notice owner can set the hedge time threshold in percent, scaled by 1e18 that determines the deviation in EthUsdc price that can trigger a rebalance
     * @param _rebalancePriceThreshold the hedge price threshold, in percent, scaled by 1e18
     */
    function setRebalancePriceThreshold(uint256 _rebalancePriceThreshold) external onlyGovernance {
        rebalancePriceThreshold = _rebalancePriceThreshold;
    }

    /**
     * @notice owner can set the base threshold for boundaries calculation
     * @param _baseThreshold the rebalance time threshold, in ticks
     */
    function setBaseThreshold(int24 _baseThreshold) external onlyGovernance {
        baseThreshold = _baseThreshold;
    }

    /**
     * @notice owner can set the base threshold for boundaries calculation
     * @param _adjParam the iv adjustment parameter
     */
    function setAdjParam(uint256 _adjParam) external onlyGovernance {
        adjParam = _adjParam;
    }

    /**
     * @notice owner can set the auction time, in seconds, that a hedge auction runs for
     * @param _auctionTime the length of the hedge auction in seconds
     */
    function setAuctionTime(uint256 _auctionTime) external onlyGovernance {
        auctionTime = _auctionTime;
    }

    /**
     * @notice owner can set the min price multiplier in a percentage scaled by 1e18 (95e16 is 95%)
     * @param _minPriceMultiplier the min price multiplier, a percentage, scaled by 1e18
     */
    function setMinPriceMultiplier(uint256 _minPriceMultiplier) external onlyGovernance {
        minPriceMultiplier = _minPriceMultiplier;
    }

    /**
     * @notice owner can set the max price multiplier in a percentage scaled by 1e18 (105e15 is 105%)
     * @param _maxPriceMultiplier the max price multiplier, a percentage, scaled by 1e18
     */
    function setMaxPriceMultiplier(uint256 _maxPriceMultiplier) external onlyGovernance {
        maxPriceMultiplier = _maxPriceMultiplier;
    }

    function setRebalanceThreshold(uint256 _rebalanceThreshold) external onlyGovernance {
        rebalanceThreshold = _rebalanceThreshold;
    }

    // @dev snapshot after each rebalance
    function setSnapshot(
        int24 _orderEthUsdcLower,
        int24 _orderEthUsdcUpper,
        int24 _orderOsqthEthLower,
        int24 _orderOsqthEthUpper,
        uint256 _timeAtLastRebalance,
        uint256 _ivAtLastRebalance,
        uint256 _totalValue,
        uint256 _ethPriceAtLastRebalance
    ) external override onlyVault {
        orderEthUsdcLower = _orderEthUsdcLower;
        orderEthUsdcUpper = _orderEthUsdcUpper;
        orderOsqthEthLower = _orderOsqthEthLower;
        orderOsqthEthUpper = _orderOsqthEthUpper;
        timeAtLastRebalance = _timeAtLastRebalance;
        ivAtLastRebalance = _ivAtLastRebalance;
        totalValue = _totalValue;
        ethPriceAtLastRebalance = _ethPriceAtLastRebalance;
    }

    /// @dev accrude fees in eth
    function setAccruedFeesEth(uint256 _accruedFeesEth) external override onlyMath {
        accruedFeesEth = _accruedFeesEth;
    }

    /// @dev accrude fees in usdc
    function setAccruedFeesUsdc(uint256 _accruedFeesUsdc) external override onlyMath {
        accruedFeesUsdc = _accruedFeesUsdc;
    }

    /// @dev accrude fees in osqth
    function setAccruedFeesOsqth(uint256 _accruedFeesOsqth) external override onlyMath {
        accruedFeesOsqth = _accruedFeesOsqth;
    }

    /// @dev function to update accrude fees on withdrawals
    function updateAccruedFees(
        uint256 amountEth,
        uint256 amountUsdc,
        uint256 amountOsqth
    ) external override onlyVault {
        accruedFeesUsdc = accruedFeesUsdc - amountUsdc;
        accruedFeesEth = accruedFeesEth - amountEth;
        accruedFeesOsqth = accruedFeesOsqth - amountOsqth;
    }

    /// @dev function to set Time, IV, and ethPrice during the first deposit
    function setParamsBeforeDeposit(
        uint256 _timeAtLastRebalance,
        uint256 _ivAtLastRebalance,
        uint256 _ethPriceAtLastRebalance
    ) external override onlyVault {
        timeAtLastRebalance = _timeAtLastRebalance;
        ivAtLastRebalance = _ivAtLastRebalance;
        ethPriceAtLastRebalance = _ethPriceAtLastRebalance;
    }

    /// @dev governance can pause the contract
    function setPause(bool _pause) external onlyGovernance {
        isSystemPaused = _pause;

        emit SharedEvents.Paused(_pause);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.4;

import {Constants} from "../libraries/Constants.sol";

interface IVaultStorage {
    function orderEthUsdcLower() external view returns (int24);

    function orderEthUsdcUpper() external view returns (int24);

    function orderOsqthEthLower() external view returns (int24);

    function orderOsqthEthUpper() external view returns (int24);

    function accruedFeesEth() external view returns (uint256);

    function accruedFeesUsdc() external view returns (uint256);

    function accruedFeesOsqth() external view returns (uint256);

    function protocolFee() external view returns (uint256);

    function timeAtLastRebalance() external view returns (uint256);

    function ivAtLastRebalance() external view returns (uint256);

    function totalValue() external view returns (uint256);

    function setParamsBeforeDeposit(
        uint256 _timeAtLastRebalance,
        uint256 _ivAtLastRebalance,
        uint256 _ethPriceAtLastRebalance
    ) external;

    function rebalanceTimeThreshold() external view returns (uint256);

    function ethPriceAtLastRebalance() external view returns (uint256);

    function rebalanceThreshold() external view returns (uint256);

    function rebalancePriceThreshold() external view returns (uint256);

    function maxPriceMultiplier() external view returns (uint256);

    function minPriceMultiplier() external view returns (uint256);

    function auctionTime() external view returns (uint256);

    function adjParam() external view returns (uint256);

    function twapPeriod() external view returns (uint32);

    function baseThreshold() external view returns (int24);

    function tickSpacing() external view returns (int24);

    function updateAccruedFees(
        uint256,
        uint256,
        uint256
    ) external;

    function setAccruedFeesEth(uint256) external;

    function setAccruedFeesUsdc(uint256) external;

    function setAccruedFeesOsqth(uint256) external;

    function cap() external view returns (uint256);

    function setSnapshot(
        int24 _orderEthUsdcLower,
        int24 _orderEthUsdcUpper,
        int24 _orderOsqthEthLower,
        int24 _orderOsqthEthUpper,
        uint256 _timeAtLastRebalance,
        uint256 _ivAtLastRebalance,
        uint256 _totalValue,
        uint256 _ethPriceAtLastRebalance
    ) external;

    function isSystemPaused() external view returns (bool);

    function governance() external view returns (address);

    function setGovernance(address _governance) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity =0.8.4;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IOracle} from "./uniswap/IOracle.sol";
import {IOsqthController} from "./osqth/IController.sol";
import {IUniswapMath} from "./uniswap/IUniswapMath.sol";

library Constants {
    //@dev ETH-USDC Uniswap pool
    address public constant poolEthUsdc = 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8;

    //@dev oSQTH-ETH Uniswap pool
    address public constant poolEthOsqth = 0x82c427AdFDf2d245Ec51D8046b41c4ee87F0d29C;

    //@dev wETH, USDC and oSQTH tokens
    IERC20 public constant weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 public constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public constant osqth = IERC20(0xf1B99e3E573A1a9C5E6B2Ce818b617F0E664E86B);

    //@dev strategy Uniswap oracle
    IOracle public constant oracle = IOracle(0x65D66c76447ccB45dAf1e8044e918fA786A483A1);

    IOsqthController public constant osqthController = IOsqthController(0x64187ae08781B09368e6253F9E94951243A493D5);

    struct Boundaries {
        int24 ethUsdcLower;
        int24 ethUsdcUpper;
        int24 osqthEthLower;
        int24 osqthEthUpper;
    }

    struct AuctionParams {
        Boundaries boundaries;
        uint128 liquidityEthUsdc;
        uint128 liquidityOsqthEth;
        uint256 totalValue;
        uint256 ethUsdcPrice;
    }

    struct AuctionMinAmounts {
        uint256 minAmountEth;
        uint256 minAmountUsdc;
        uint256 minAmountOsqth;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.4;
pragma abicoder v2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVaultStorage {
    function isSystemPaused() external view returns (bool);

    function governance() external view returns (address);
}

interface IFaucet {
    function setComponents(
        address,
        address,
        address,
        address,
        address,
        address
    ) external;
}

contract Faucet is IFaucet, Ownable {
    address public uniswapMath;
    address public vault;
    address public auction;
    address public vaultMath;
    address public vaultTreasury;
    address public vaultStorage;

    constructor() Ownable() {}

    bool public isInitialized = false;

    function setComponents(
        address _uniswapMath,
        address _vault,
        address _auction,
        address _vaultMath,
        address _vaultTreasury,
        address _vaultStorage
    ) public override onlyOwner {
        assert(!isInitialized);
        (uniswapMath, vault, auction, vaultMath, vaultTreasury, vaultStorage) = (
            _uniswapMath,
            _vault,
            _auction,
            _vaultMath,
            _vaultTreasury,
            _vaultStorage
        );
        isInitialized = true;
    }

    modifier onlyVault() {
        require(msg.sender == vault || msg.sender == auction, "C12");
        _;
    }

    modifier onlyMath() {
        require(msg.sender == vaultMath, "C13");
        _;
    }

    modifier onlyContracts() {
        require(msg.sender == vault || msg.sender == vaultMath || msg.sender == auction, "C14");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == IVaultStorage(vaultStorage).governance(), "C15");
        _;
    }

    /**
     * @notice current balance of a certain token
     */
    function _getBalance(IERC20 token) internal view returns (uint256) {
        return token.balanceOf(vaultTreasury);
    }

    modifier notPaused() {
        require(!IVaultStorage(vaultStorage).isSystemPaused(), "C0");
        _;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity =0.8.4;

library SharedEvents {
    event Deposit(address indexed sender, uint256 shares);

    event TimeRebalance(
        address indexed hedger,
        uint256 auctionTriggerTime,
        uint256 amountEth,
        uint256 amountUsdc,
        uint256 amountOsqth
    );

    event NoRebalance(address indexed hedger, uint256 auctionTriggerTime, uint256 ratio);

    event PriceRebalance(address indexed hedger, uint256 amountEth, uint256 amountUsdc, uint256 amountOsqth);

    event Withdraw(address indexed hedger, uint256 shares, uint256 amountEth, uint256 amountUsdc, uint256 amountOsqth);

    event Rebalance(address indexed hedger, uint256 amountEth, uint256 amountUsdc, uint256 amountOsqth);

    event CollectFees(uint256 feesToVault0, uint256 feesToVault1, uint256 feesToProtocol0, uint256 feesToProtocol1);

    event Paused(bool changedState);

    // event Snapshot(int24 tick, uint256 totalAmount0, uint256 totalAmount1, uint256 totalSupply);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

pragma solidity =0.8.4;

interface IOracle {
    function getHistoricalTwap(
        address _pool,
        address _base,
        address _quote,
        uint32 _period,
        uint32 _periodToHistoricPrice
    ) external view returns (uint256);

    function getTwap(
        address _pool,
        address _base,
        address _quote,
        uint32 _period,
        bool _checkPeriod
    ) external view returns (uint256);

    function getMaxPeriod(address _pool) external view returns (uint32);

    function getTimeWeightedAverageTickSafe(address _pool, uint32 _period)
        external
        view
        returns (int24 timeWeightedAverageTick);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IOsqthController {
    function getDenormalizedMark(uint32 _period) external view returns (uint256);

    function getIndex(uint32 _period) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.4;
pragma abicoder v2;

import {Constants} from "../Constants.sol";

interface IUniswapMath {
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) external pure returns (int24 tick);

    function getSqrtRatioAtTick(int24 tick) external pure returns (uint160 sqrtPriceX96);

    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) external pure returns (uint256 amount0, uint256 amount1);

    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) external pure returns (uint128 liquidity);
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