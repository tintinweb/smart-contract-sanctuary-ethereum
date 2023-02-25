// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

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
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#mint
/// @notice Any contract that calls IUniswapV3PoolActions#mint must implement this interface
interface IUniswapV3MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
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

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
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

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
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
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
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
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
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
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
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
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
interface ISelfPermit {
    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// Can be used instead of #selfPermit to prevent calls from failing due to a frontrun of a call to #selfPermit
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// Can be used instead of #selfPermitAllowed to prevent calls from failing due to a frontrun of a call to #selfPermitAllowed.
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;
pragma abicoder v2;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

/// @param pool The Uniswap V3 pool
/// @param tickLower The lower tick of the Bunni's UniV3 LP position
/// @param tickUpper The upper tick of the Bunni's UniV3 LP position
struct BunniKey {
    IUniswapV3Pool pool;
    int24 tickLower;
    int24 tickUpper;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;
pragma abicoder v2;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import {IMulticall} from "@uniswap/v3-periphery/contracts/interfaces/IMulticall.sol";
import {ISelfPermit} from "@uniswap/v3-periphery/contracts/interfaces/ISelfPermit.sol";

import "../base/Structs.sol";
import {IERC20} from "./IERC20.sol";
import {IBunniToken} from "./IBunniToken.sol";
import {ILiquidityManagement} from "./ILiquidityManagement.sol";

/// @title BunniHub
/// @author zefram.eth
/// @notice The main contract LPs interact with. Each BunniKey corresponds to a BunniToken,
/// which is the ERC20 LP token for the Uniswap V3 position specified by the BunniKey.
/// Use deposit()/withdraw() to mint/burn LP tokens, and use compound() to compound the swap fees
/// back into the LP position.
interface IBunniHub is IMulticall, ISelfPermit, ILiquidityManagement {
    /// @notice Emitted when liquidity is increased via deposit
    /// @param sender The msg.sender address
    /// @param recipient The address of the account that received the share tokens
    /// @param bunniKeyHash The hash of the Bunni position's key
    /// @param liquidity The amount by which liquidity was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    /// @param shares The amount of share tokens minted to the recipient
    event Deposit(
        address indexed sender,
        address indexed recipient,
        bytes32 indexed bunniKeyHash,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1,
        uint256 shares
    );
    /// @notice Emitted when liquidity is decreased via withdrawal
    /// @param sender The msg.sender address
    /// @param recipient The address of the account that received the collected tokens
    /// @param bunniKeyHash The hash of the Bunni position's key
    /// @param liquidity The amount by which liquidity was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    /// @param shares The amount of share tokens burnt from the sender
    event Withdraw(
        address indexed sender,
        address indexed recipient,
        bytes32 indexed bunniKeyHash,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1,
        uint256 shares
    );
    /// @notice Emitted when fees are compounded back into liquidity
    /// @param sender The msg.sender address
    /// @param bunniKeyHash The hash of the Bunni position's key
    /// @param liquidity The amount by which liquidity was increased
    /// @param amount0 The amount of token0 added to the liquidity position
    /// @param amount1 The amount of token1 added to the liquidity position
    event Compound(
        address indexed sender,
        bytes32 indexed bunniKeyHash,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    /// @notice Emitted when a new IBunniToken is created
    /// @param bunniKeyHash The hash of the Bunni position's key
    /// @param pool The Uniswap V3 pool
    /// @param tickLower The lower tick of the Bunni's UniV3 LP position
    /// @param tickUpper The upper tick of the Bunni's UniV3 LP position
    event NewBunni(
        IBunniToken indexed token,
        bytes32 indexed bunniKeyHash,
        IUniswapV3Pool indexed pool,
        int24 tickLower,
        int24 tickUpper
    );
    /// @notice Emitted when protocol fees are paid to the factory
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount1 The amount of token1 protocol fees that is withdrawn
    event PayProtocolFee(uint256 amount0, uint256 amount1);
    /// @notice Emitted when the protocol fee has been updated
    /// @param newProtocolFee The new protocol fee
    event SetProtocolFee(uint256 newProtocolFee);

    /// @param key The Bunni position's key
    /// @param amount0Desired The desired amount of token0 to be spent,
    /// @param amount1Desired The desired amount of token1 to be spent,
    /// @param amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// @param amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// @param deadline The time by which the transaction must be included to effect the change
    /// @param recipient The recipient of the minted share tokens
    struct DepositParams {
        BunniKey key;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
        address recipient;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @dev Must be called after the corresponding BunniToken has been deployed via deployBunniToken()
    /// @param params The input parameters
    /// key The Bunni position's key
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return shares The new share tokens minted to the sender
    /// @return addedLiquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function deposit(DepositParams calldata params)
        external
        payable
        returns (
            uint256 shares,
            uint128 addedLiquidity,
            uint256 amount0,
            uint256 amount1
        );

    /// @param key The Bunni position's key
    /// @param recipient The user if not withdrawing ETH, address(0) if withdrawing ETH
    /// @param shares The amount of ERC20 tokens (this) to burn,
    /// @param amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// @param amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// @param deadline The time by which the transaction must be included to effect the change
    struct WithdrawParams {
        BunniKey key;
        address recipient;
        uint256 shares;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in the position and sends the tokens to the sender.
    /// If withdrawing ETH, need to follow up with unwrapWETH9() and sweepToken()
    /// @dev Must be called after the corresponding BunniToken has been deployed via deployBunniToken()
    /// @param params The input parameters
    /// key The Bunni position's key
    /// recipient The user if not withdrawing ETH, address(0) if withdrawing ETH
    /// shares The amount of share tokens to burn,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return removedLiquidity The amount of liquidity decrease
    /// @return amount0 The amount of token0 withdrawn to the recipient
    /// @return amount1 The amount of token1 withdrawn to the recipient
    function withdraw(WithdrawParams calldata params)
        external
        returns (
            uint128 removedLiquidity,
            uint256 amount0,
            uint256 amount1
        );

    /// @notice Claims the trading fees earned and uses it to add liquidity.
    /// @dev Must be called after the corresponding BunniToken has been deployed via deployBunniToken()
    /// @param key The Bunni position's key
    /// @return addedLiquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 added to the liquidity position
    /// @return amount1 The amount of token1 added to the liquidity position
    function compound(BunniKey calldata key)
        external
        returns (
            uint128 addedLiquidity,
            uint256 amount0,
            uint256 amount1
        );

    /// @notice Deploys the BunniToken contract for a Bunni position. This token
    /// represents a user's share in the Uniswap V3 LP position.
    /// @param key The Bunni position's key
    /// @return token The deployed BunniToken
    function deployBunniToken(BunniKey calldata key)
        external
        returns (IBunniToken token);

    /// @notice Returns the BunniToken contract for a Bunni position. This token
    /// represents a user's share in the Uniswap V3 LP position.
    /// If the contract hasn't been created yet, returns 0.
    /// @param key The Bunni position's key
    /// @return token The BunniToken contract
    function getBunniToken(BunniKey calldata key)
        external
        view
        returns (IBunniToken token);

    /// @notice Sweeps ERC20 token balances to a recipient. Mainly used for extracting protocol fees.
    /// Only callable by the owner.
    /// @param tokenList The list of ERC20 tokens to sweep
    /// @param recipient The token recipient address
    function sweepTokens(IERC20[] calldata tokenList, address recipient)
        external;

    /// @notice Updates the protocol fee value. Scaled by 1e18. Only callable by the owner.
    /// @param value The new protocol fee value
    function setProtocolFee(uint256 value) external;

    /// @notice Returns the protocol fee value. Decimal value <1, scaled by 1e18.
    function protocolFee() external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import {IERC20} from "./IERC20.sol";
import {IBunniHub} from "./IBunniHub.sol";

/// @title BunniToken
/// @author zefram.eth
/// @notice ERC20 token that represents a user's LP position
interface IBunniToken is IERC20 {
    function pool() external view returns (IUniswapV3Pool);

    function tickLower() external view returns (int24);

    function tickUpper() external view returns (int24);

    function hub() external view returns (IBunniHub);

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * Modified from OpenZeppelin's IERC20 contract
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @return The name of the token
     */
    function name() external view returns (string memory);

    /**
     * @return The symbol of the token
     */
    function symbol() external view returns (string memory);

    /**
     * @return The number of decimal places the token has
     */
    function decimals() external view returns (uint8);

    function nonces(address account) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function DOMAIN_SEPARATOR() external view returns (bytes32);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.5.0;

import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3MintCallback} from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";

/// @title Liquidity management functions
/// @notice Internal functions for safely managing liquidity in Uniswap V3
interface ILiquidityManagement is IUniswapV3MintCallback {
    function factory() external view returns (IUniswapV3Factory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

// For compatibility, we're keeping the same function names as in the original Curve code, including the mixed-case
// naming convention.
// solhint-disable func-name-mixedcase
// solhint-disable func-param-name-mixedcase

interface ILiquidityGauge {
    // solhint-disable-next-line var-name-mixedcase
    event RelativeWeightCapChanged(uint256 new_relative_weight_cap);

    /**
     * @notice Returns liquidity emissions calculated during checkpoints for the given user.
     * @param user User address.
     * @return uint256 token amount to issue for the address.
     */
    function integrate_fraction(address user) external view returns (uint256);

    /**
     * @notice Record a checkpoint for a given user.
     * @param user User address.
     * @return bool Always true.
     */
    function user_checkpoint(address user) external returns (bool);

    /**
     * @notice Returns true if gauge is killed; false otherwise.
     */
    function is_killed() external view returns (bool);

    /**
     * @notice Kills the gauge so it cannot mint tokens.
     */
    function killGauge() external;

    /**
     * @notice Unkills the gauge so it can mint tokens again.
     */
    function unkillGauge() external;

    /**
     * @notice Uses the Uniswap Poor oracle to decide whether a gauge is alive
     */
    function makeGaugePermissionless() external;

    /**
     * @notice Sets a new relative weight cap for the gauge.
     * The value shall be normalized to 1e18, and not greater than MAX_RELATIVE_WEIGHT_CAP.
     * @param relativeWeightCap New relative weight cap.
     */
    function setRelativeWeightCap(uint256 relativeWeightCap) external;

    /**
     * @notice Gets the relative weight cap for the gauge.
     */
    function getRelativeWeightCap() external view returns (uint256);

    /**
     * @notice Returns the gauge's relative weight for a given time, capped to its relative weight cap attribute.
     * @param time Timestamp in the past or present.
     */
    function getCappedRelativeWeight(uint256 time) external view returns (uint256);

    function initialize(
        address lpToken,
        uint256 relativeWeightCap,
        address votingEscrowDelegation,
        address admin,
        bytes32 positionKey
    ) external;

    function change_pending_admin(address newPendingAdmin) external;

    function claim_admin() external;

    function admin() external view returns (address);

    function deposit(uint256 amount) external;

    function deposit(uint256 amount, address recipient) external;

    function withdraw(uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function claim_rewards() external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";
import {SafeTransferLib} from "../utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "../utils/FixedPointMathLib.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "./ERC20.sol";

import {SafeTransferLib} from "../utils/SafeTransferLib.sol";

/// @notice Minimalist and modern Wrapped Ether implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/WETH.sol)
/// @author Inspired by WETH9 (https://github.com/dapphub/ds-weth/blob/master/src/weth9.sol)
contract WETH is ERC20("Wrapped Ether", "WETH", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Library for converting between addresses and bytes32 values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Bytes32AddressLib.sol)
library Bytes32AddressLib {
    function fromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(address addressValue) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Simplified by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import {BoringOwnable} from "boringsolidity/BoringOwnable.sol";

import {Bytes32AddressLib} from "solmate/utils/Bytes32AddressLib.sol";

import {Gate} from "./Gate.sol";
import {NegativeYieldToken} from "./NegativeYieldToken.sol";
import {PerpetualYieldToken} from "./PerpetualYieldToken.sol";

contract Factory is BoringOwnable {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using Bytes32AddressLib for address;
    using Bytes32AddressLib for bytes32;

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error Error_ProtocolFeeRecipientIsZero();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event SetProtocolFee(ProtocolFeeInfo protocolFeeInfo_);
    event DeployYieldTokenPair(
        Gate indexed gate,
        address indexed vault,
        NegativeYieldToken nyt,
        PerpetualYieldToken pyt
    );

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    struct ProtocolFeeInfo {
        uint8 fee; // each increment represents 0.1%, so max is 25.5%
        address recipient;
    }
    /// @notice The protocol fee and the fee recipient address.
    ProtocolFeeInfo public protocolFeeInfo;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(ProtocolFeeInfo memory protocolFeeInfo_) {
        if (
            protocolFeeInfo_.fee != 0 &&
            protocolFeeInfo_.recipient == address(0)
        ) {
            revert Error_ProtocolFeeRecipientIsZero();
        }
        protocolFeeInfo = protocolFeeInfo_;
        emit SetProtocolFee(protocolFeeInfo_);
    }

    /// -----------------------------------------------------------------------
    /// User actions
    /// -----------------------------------------------------------------------

    /// @notice Deploys the NegativeYieldToken and PerpetualYieldToken associated with a vault.
    /// @dev Will revert if they have already been deployed.
    /// @param gate The gate that will use the NYT and PYT
    /// @param vault The vault to deploy NYT and PYT for
    /// @return nyt The deployed NegativeYieldToken
    /// @return pyt The deployed PerpetualYieldToken
    function deployYieldTokenPair(Gate gate, address vault)
        public
        virtual
        returns (NegativeYieldToken nyt, PerpetualYieldToken pyt)
    {
        // Use the CREATE2 opcode to deploy new NegativeYieldToken and PerpetualYieldToken contracts.
        // This will revert if the contracts have already been deployed,
        // as the salt & bytecode hash would be the same and we can't deploy with it twice.
        nyt = new NegativeYieldToken{salt: bytes32(0)}(gate, vault);
        pyt = new PerpetualYieldToken{salt: bytes32(0)}(gate, vault);

        emit DeployYieldTokenPair(gate, vault, nyt, pyt);
    }

    /// -----------------------------------------------------------------------
    /// Getters
    /// -----------------------------------------------------------------------

    /// @notice Returns the NegativeYieldToken associated with a gate & vault pair.
    /// @dev Returns non-zero value even if the contract hasn't been deployed yet.
    /// @param gate The gate to query
    /// @param vault The vault to query
    /// @return The NegativeYieldToken address
    function getNegativeYieldToken(Gate gate, address vault)
        public
        view
        virtual
        returns (NegativeYieldToken)
    {
        return
            NegativeYieldToken(_computeYieldTokenAddress(gate, vault, false));
    }

    /// @notice Returns the PerpetualYieldToken associated with a gate & vault pair.
    /// @dev Returns non-zero value even if the contract hasn't been deployed yet.
    /// @param gate The gate to query
    /// @param vault The vault to query
    /// @return The PerpetualYieldToken address
    function getPerpetualYieldToken(Gate gate, address vault)
        public
        view
        virtual
        returns (PerpetualYieldToken)
    {
        return
            PerpetualYieldToken(_computeYieldTokenAddress(gate, vault, true));
    }

    /// -----------------------------------------------------------------------
    /// Owner functions
    /// -----------------------------------------------------------------------

    /// @notice Updates the protocol fee and/or the protocol fee recipient.
    /// Only callable by the owner.
    /// @param protocolFeeInfo_ The new protocol fee info
    function ownerSetProtocolFee(ProtocolFeeInfo calldata protocolFeeInfo_)
        external
        virtual
        onlyOwner
    {
        if (
            protocolFeeInfo_.fee != 0 &&
            protocolFeeInfo_.recipient == address(0)
        ) {
            revert Error_ProtocolFeeRecipientIsZero();
        }
        protocolFeeInfo = protocolFeeInfo_;

        emit SetProtocolFee(protocolFeeInfo_);
    }

    /// -----------------------------------------------------------------------
    /// Internal utilities
    /// -----------------------------------------------------------------------

    /// @dev Computes the address of PYTs and NYTs using CREATE2.
    function _computeYieldTokenAddress(
        Gate gate,
        address vault,
        bool isPerpetualYieldToken
    ) internal view virtual returns (address) {
        return
            keccak256(
                abi.encodePacked(
                    // Prefix:
                    bytes1(0xFF),
                    // Creator:
                    address(this),
                    // Salt:
                    bytes32(0),
                    // Bytecode hash:
                    keccak256(
                        abi.encodePacked(
                            // Deployment bytecode:
                            isPerpetualYieldToken
                                ? type(PerpetualYieldToken).creationCode
                                : type(NegativeYieldToken).creationCode,
                            // Constructor arguments:
                            abi.encode(gate, vault)
                        )
                    )
                )
            ).fromLast20Bytes(); // Convert the CREATE2 hash into an address.
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import {BoringOwnable} from "boringsolidity/BoringOwnable.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {Factory} from "./Factory.sol";
import {IxPYT} from "./external/IxPYT.sol";
import {FullMath} from "./lib/FullMath.sol";
import {Multicall} from "./lib/Multicall.sol";
import {SelfPermit} from "./lib/SelfPermit.sol";
import {NegativeYieldToken} from "./NegativeYieldToken.sol";
import {PerpetualYieldToken} from "./PerpetualYieldToken.sol";

/// @title Gate
/// @author zefram.eth
/// @notice Gate is the main contract users interact with to mint/burn NegativeYieldToken
/// and PerpetualYieldToken, as well as claim the yield earned by PYTs.
/// @dev Gate is an abstract contract that should be inherited from in order to support
/// a specific vault protocol (e.g. YearnGate supports YearnVault). Each Gate handles
/// all vaults & associated NYTs/PYTs of a specific vault protocol.
///
/// Vaults are yield-generating contracts used by Gate. Gate makes several assumptions about
/// a vault:
/// 1) A vault has a single associated underlying token that is immutable.
/// 2) A vault gives depositors yield denominated in the underlying token.
/// 3) A vault depositor owns shares in the vault, which represents their deposit.
/// 4) Vaults have a notion of "price per share", which is the amount of underlying tokens
///    each vault share can be redeemed for.
/// 5) If vault shares are represented using an ERC20 token, then the ERC20 token contract must be
///    the vault contract itself.
abstract contract Gate is
    ReentrancyGuard,
    Multicall,
    SelfPermit,
    BoringOwnable
{
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for ERC20;
    using SafeTransferLib for ERC4626;

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error Error_InvalidInput();
    error Error_VaultSharesNotERC20();
    error Error_TokenPairNotDeployed();
    error Error_EmergencyExitNotActivated();
    error Error_SenderNotPerpetualYieldToken();
    error Error_EmergencyExitAlreadyActivated();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event EnterWithUnderlying(
        address sender,
        address indexed nytRecipient,
        address indexed pytRecipient,
        address indexed vault,
        IxPYT xPYT,
        uint256 underlyingAmount
    );
    event EnterWithVaultShares(
        address sender,
        address indexed nytRecipient,
        address indexed pytRecipient,
        address indexed vault,
        IxPYT xPYT,
        uint256 vaultSharesAmount
    );
    event ExitToUnderlying(
        address indexed sender,
        address indexed recipient,
        address indexed vault,
        IxPYT xPYT,
        uint256 underlyingAmount
    );
    event ExitToVaultShares(
        address indexed sender,
        address indexed recipient,
        address indexed vault,
        IxPYT xPYT,
        uint256 vaultSharesAmount
    );
    event ClaimYieldInUnderlying(
        address indexed sender,
        address indexed recipient,
        address indexed vault,
        uint256 underlyingAmount
    );
    event ClaimYieldInVaultShares(
        address indexed sender,
        address indexed recipient,
        address indexed vault,
        uint256 vaultSharesAmount
    );
    event ClaimYieldAndEnter(
        address sender,
        address indexed nytRecipient,
        address indexed pytRecipient,
        address indexed vault,
        IxPYT xPYT,
        uint256 amount
    );

    /// -----------------------------------------------------------------------
    /// Structs
    /// -----------------------------------------------------------------------

    /// @param activated True if emergency exit has been activated, false if not
    /// @param pytPriceInUnderlying The amount of underlying assets each PYT can redeem for.
    /// Should be a value in the range [0, PRECISION]
    struct EmergencyExitStatus {
        bool activated;
        uint96 pytPriceInUnderlying;
    }

    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    /// @notice The decimals of precision used by yieldPerTokenStored and pricePerVaultShareStored
    uint256 internal constant PRECISION_DECIMALS = 27;

    /// @notice The precision used by yieldPerTokenStored and pricePerVaultShareStored
    uint256 internal constant PRECISION = 10**PRECISION_DECIMALS;

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    Factory public immutable factory;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice The amount of underlying tokens each vault share is worth, at the time of the last update.
    /// Uses PRECISION.
    /// @dev vault => value
    mapping(address => uint256) public pricePerVaultShareStored;

    /// @notice The amount of yield each PYT has accrued, at the time of the last update.
    /// Scaled by PRECISION.
    /// @dev vault => value
    mapping(address => uint256) public yieldPerTokenStored;

    /// @notice The amount of yield each PYT has accrued, at the time when a user has last interacted
    /// with the gate/PYT. Shifted by 1, so e.g. 3 represents 2, 10 represents 9.
    /// @dev vault => user => value
    /// The value is shifted to use 0 for representing uninitialized users.
    mapping(address => mapping(address => uint256))
        public userYieldPerTokenStored;

    /// @notice The amount of yield a user has accrued, at the time when they last interacted
    /// with the gate/PYT (without calling claimYieldInUnderlying()).
    /// Shifted by 1, so e.g. 3 represents 2, 10 represents 9.
    /// @dev vault => user => value
    mapping(address => mapping(address => uint256)) public userAccruedYield;

    /// @notice Stores info relevant to emergency exits of a vault.
    /// @dev vault => value
    mapping(address => EmergencyExitStatus) public emergencyExitStatusOfVault;

    /// -----------------------------------------------------------------------
    /// Initialization
    /// -----------------------------------------------------------------------

    constructor(Factory factory_) {
        factory = factory_;
    }

    /// -----------------------------------------------------------------------
    /// User actions
    /// -----------------------------------------------------------------------

    /// @notice Converts underlying tokens into NegativeYieldToken and PerpetualYieldToken.
    /// The amount of NYT and PYT minted will be equal to the underlying token amount.
    /// @dev The underlying tokens will be immediately deposited into the specified vault.
    /// If the NYT and PYT for the specified vault haven't been deployed yet, this call will
    /// deploy them before proceeding, which will increase the gas cost significantly.
    /// @param nytRecipient The recipient of the minted NYT
    /// @param pytRecipient The recipient of the minted PYT
    /// @param vault The vault to mint NYT and PYT for
    /// @param xPYT The xPYT contract to deposit the minted PYT into. Set to 0 to receive raw PYT instead.
    /// @param underlyingAmount The amount of underlying tokens to use
    /// @return mintAmount The amount of NYT and PYT minted (the amounts are equal)
    function enterWithUnderlying(
        address nytRecipient,
        address pytRecipient,
        address vault,
        IxPYT xPYT,
        uint256 underlyingAmount
    ) external virtual nonReentrant returns (uint256 mintAmount) {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        if (underlyingAmount == 0) {
            return 0;
        }

        /// -----------------------------------------------------------------------
        /// State updates & effects
        /// -----------------------------------------------------------------------

        // mint PYT and NYT
        mintAmount = underlyingAmount;
        _enter(
            nytRecipient,
            pytRecipient,
            vault,
            xPYT,
            underlyingAmount,
            getPricePerVaultShare(vault)
        );

        // transfer underlying from msg.sender to address(this)
        ERC20 underlying = getUnderlyingOfVault(vault);
        underlying.safeTransferFrom(
            msg.sender,
            address(this),
            underlyingAmount
        );

        // deposit underlying into vault
        _depositIntoVault(underlying, underlyingAmount, vault);

        emit EnterWithUnderlying(
            msg.sender,
            nytRecipient,
            pytRecipient,
            vault,
            xPYT,
            underlyingAmount
        );
    }

    /// @notice Converts vault share tokens into NegativeYieldToken and PerpetualYieldToken.
    /// @dev Only available if vault shares are transferrable ERC20 tokens.
    /// If the NYT and PYT for the specified vault haven't been deployed yet, this call will
    /// deploy them before proceeding, which will increase the gas cost significantly.
    /// @param nytRecipient The recipient of the minted NYT
    /// @param pytRecipient The recipient of the minted PYT
    /// @param vault The vault to mint NYT and PYT for
    /// @param xPYT The xPYT contract to deposit the minted PYT into. Set to 0 to receive raw PYT instead.
    /// @param vaultSharesAmount The amount of vault share tokens to use
    /// @return mintAmount The amount of NYT and PYT minted (the amounts are equal)
    function enterWithVaultShares(
        address nytRecipient,
        address pytRecipient,
        address vault,
        IxPYT xPYT,
        uint256 vaultSharesAmount
    ) external virtual nonReentrant returns (uint256 mintAmount) {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        if (vaultSharesAmount == 0) {
            return 0;
        }

        // only supported if vault shares are ERC20
        if (!vaultSharesIsERC20()) {
            revert Error_VaultSharesNotERC20();
        }

        /// -----------------------------------------------------------------------
        /// State updates & effects
        /// -----------------------------------------------------------------------

        // mint PYT and NYT
        uint256 updatedPricePerVaultShare = getPricePerVaultShare(vault);
        mintAmount = _vaultSharesAmountToUnderlyingAmount(
            vault,
            vaultSharesAmount,
            updatedPricePerVaultShare
        );
        _enter(
            nytRecipient,
            pytRecipient,
            vault,
            xPYT,
            mintAmount,
            updatedPricePerVaultShare
        );

        // transfer vault tokens from msg.sender to address(this)
        ERC20(vault).safeTransferFrom(
            msg.sender,
            address(this),
            vaultSharesAmount
        );

        emit EnterWithVaultShares(
            msg.sender,
            nytRecipient,
            pytRecipient,
            vault,
            xPYT,
            vaultSharesAmount
        );
    }

    /// @notice Converts NegativeYieldToken and PerpetualYieldToken to underlying tokens.
    /// The amount of NYT and PYT burned will be equal to the underlying token amount.
    /// @dev The underlying tokens will be immediately withdrawn from the specified vault.
    /// If the NYT and PYT for the specified vault haven't been deployed yet, this call will
    /// revert.
    /// @param recipient The recipient of the minted NYT and PYT
    /// @param vault The vault to mint NYT and PYT for
    /// @param xPYT The xPYT contract to use for burning PYT. Set to 0 to burn raw PYT instead.
    /// @param underlyingAmount The amount of underlying tokens requested
    /// @return burnAmount The amount of NYT and PYT burned (the amounts are equal)
    function exitToUnderlying(
        address recipient,
        address vault,
        IxPYT xPYT,
        uint256 underlyingAmount
    ) external virtual nonReentrant returns (uint256 burnAmount) {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        if (underlyingAmount == 0) {
            return 0;
        }

        /// -----------------------------------------------------------------------
        /// State updates & effects
        /// -----------------------------------------------------------------------

        // burn PYT and NYT
        uint256 updatedPricePerVaultShare = getPricePerVaultShare(vault);
        burnAmount = underlyingAmount;
        _exit(vault, xPYT, underlyingAmount, updatedPricePerVaultShare);

        // withdraw underlying from vault to recipient
        // don't check balance since user can just withdraw slightly less
        // saves gas this way
        underlyingAmount = _withdrawFromVault(
            recipient,
            vault,
            underlyingAmount,
            updatedPricePerVaultShare,
            false
        );

        emit ExitToUnderlying(
            msg.sender,
            recipient,
            vault,
            xPYT,
            underlyingAmount
        );
    }

    /// @notice Converts NegativeYieldToken and PerpetualYieldToken to vault share tokens.
    /// The amount of NYT and PYT burned will be equal to the underlying token amount.
    /// @dev Only available if vault shares are transferrable ERC20 tokens.
    /// If the NYT and PYT for the specified vault haven't been deployed yet, this call will
    /// revert.
    /// @param recipient The recipient of the minted NYT and PYT
    /// @param vault The vault to mint NYT and PYT for
    /// @param xPYT The xPYT contract to use for burning PYT. Set to 0 to burn raw PYT instead.
    /// @param vaultSharesAmount The amount of vault share tokens requested
    /// @return burnAmount The amount of NYT and PYT burned (the amounts are equal)
    function exitToVaultShares(
        address recipient,
        address vault,
        IxPYT xPYT,
        uint256 vaultSharesAmount
    ) external virtual nonReentrant returns (uint256 burnAmount) {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        if (vaultSharesAmount == 0) {
            return 0;
        }

        // only supported if vault shares are ERC20
        if (!vaultSharesIsERC20()) {
            revert Error_VaultSharesNotERC20();
        }

        /// -----------------------------------------------------------------------
        /// State updates & effects
        /// -----------------------------------------------------------------------

        // burn PYT and NYT
        uint256 updatedPricePerVaultShare = getPricePerVaultShare(vault);
        burnAmount = _vaultSharesAmountToUnderlyingAmountRoundingUp(
            vault,
            vaultSharesAmount,
            updatedPricePerVaultShare
        );
        _exit(vault, xPYT, burnAmount, updatedPricePerVaultShare);

        // transfer vault tokens to recipient
        ERC20(vault).safeTransfer(recipient, vaultSharesAmount);

        emit ExitToVaultShares(
            msg.sender,
            recipient,
            vault,
            xPYT,
            vaultSharesAmount
        );
    }

    /// @notice Claims the yield earned by the PerpetualYieldToken balance of msg.sender, in the underlying token.
    /// @dev If the NYT and PYT for the specified vault haven't been deployed yet, this call will
    /// revert.
    /// @param recipient The recipient of the yield
    /// @param vault The vault to claim yield from
    /// @return yieldAmount The amount of yield claimed, in underlying tokens
    function claimYieldInUnderlying(address recipient, address vault)
        external
        virtual
        nonReentrant
        returns (uint256 yieldAmount)
    {
        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // update storage variables and compute yield amount
        uint256 updatedPricePerVaultShare = getPricePerVaultShare(vault);
        yieldAmount = _claimYield(vault, updatedPricePerVaultShare);

        // withdraw yield
        if (yieldAmount != 0) {
            /// -----------------------------------------------------------------------
            /// Effects
            /// -----------------------------------------------------------------------

            (uint8 fee, address protocolFeeRecipient) = factory
                .protocolFeeInfo();

            if (fee != 0) {
                uint256 protocolFee = (yieldAmount * fee) / 1000;
                unchecked {
                    // can't underflow since fee < 256
                    yieldAmount -= protocolFee;
                }

                if (vaultSharesIsERC20()) {
                    // vault shares are in ERC20
                    // do share transfer
                    protocolFee = _underlyingAmountToVaultSharesAmount(
                        vault,
                        protocolFee,
                        updatedPricePerVaultShare
                    );
                    uint256 vaultSharesBalance = ERC20(vault).balanceOf(
                        address(this)
                    );
                    if (protocolFee > vaultSharesBalance) {
                        protocolFee = vaultSharesBalance;
                    }
                    if (protocolFee != 0) {
                        ERC20(vault).safeTransfer(
                            protocolFeeRecipient,
                            protocolFee
                        );
                    }
                } else {
                    // vault shares are not in ERC20
                    // withdraw underlying from vault
                    // checkBalance is set to true to prevent getting stuck
                    // due to rounding errors
                    if (protocolFee != 0) {
                        _withdrawFromVault(
                            protocolFeeRecipient,
                            vault,
                            protocolFee,
                            updatedPricePerVaultShare,
                            true
                        );
                    }
                }
            }

            // withdraw underlying to recipient
            // checkBalance is set to true to prevent getting stuck
            // due to rounding errors
            yieldAmount = _withdrawFromVault(
                recipient,
                vault,
                yieldAmount,
                updatedPricePerVaultShare,
                true
            );

            emit ClaimYieldInUnderlying(
                msg.sender,
                recipient,
                vault,
                yieldAmount
            );
        }
    }

    /// @notice Claims the yield earned by the PerpetualYieldToken balance of msg.sender, in vault shares.
    /// @dev Only available if vault shares are transferrable ERC20 tokens.
    /// If the NYT and PYT for the specified vault haven't been deployed yet, this call will
    /// revert.
    /// @param recipient The recipient of the yield
    /// @param vault The vault to claim yield from
    /// @return yieldAmount The amount of yield claimed, in vault shares
    function claimYieldInVaultShares(address recipient, address vault)
        external
        virtual
        nonReentrant
        returns (uint256 yieldAmount)
    {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        // only supported if vault shares are ERC20
        if (!vaultSharesIsERC20()) {
            revert Error_VaultSharesNotERC20();
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // update storage variables and compute yield amount
        uint256 updatedPricePerVaultShare = getPricePerVaultShare(vault);
        yieldAmount = _claimYield(vault, updatedPricePerVaultShare);

        // withdraw yield
        if (yieldAmount != 0) {
            /// -----------------------------------------------------------------------
            /// Effects
            /// -----------------------------------------------------------------------

            // convert yieldAmount to be denominated in vault shares
            yieldAmount = _underlyingAmountToVaultSharesAmount(
                vault,
                yieldAmount,
                updatedPricePerVaultShare
            );

            (uint8 fee, address protocolFeeRecipient) = factory
                .protocolFeeInfo();
            uint256 vaultSharesBalance = getVaultShareBalance(vault);
            if (fee != 0) {
                uint256 protocolFee = (yieldAmount * fee) / 1000;
                protocolFee = protocolFee > vaultSharesBalance
                    ? vaultSharesBalance
                    : protocolFee;
                unchecked {
                    // can't underflow since fee < 256
                    yieldAmount -= protocolFee;
                }

                if (protocolFee > 0) {
                    ERC20(vault).safeTransfer(
                        protocolFeeRecipient,
                        protocolFee
                    );

                    vaultSharesBalance -= protocolFee;
                }
            }

            // transfer vault shares to recipient
            // check if vault shares is enough to prevent getting stuck
            // from rounding errors
            yieldAmount = yieldAmount > vaultSharesBalance
                ? vaultSharesBalance
                : yieldAmount;
            if (yieldAmount > 0) {
                ERC20(vault).safeTransfer(recipient, yieldAmount);
            }

            emit ClaimYieldInVaultShares(
                msg.sender,
                recipient,
                vault,
                yieldAmount
            );
        }
    }

    /// @notice Claims the yield earned by the PerpetualYieldToken balance of msg.sender, and immediately
    /// use the yield to mint NYT and PYT.
    /// @dev Introduced to save gas for xPYT compounding, since it avoids vault withdraws/transfers.
    /// If the NYT and PYT for the specified vault haven't been deployed yet, this call will
    /// revert.
    /// @param nytRecipient The recipient of the minted NYT
    /// @param pytRecipient The recipient of the minted PYT
    /// @param vault The vault to claim yield from
    /// @param xPYT The xPYT contract to deposit the minted PYT into. Set to 0 to receive raw PYT instead.
    /// @return yieldAmount The amount of yield claimed, in underlying tokens
    function claimYieldAndEnter(
        address nytRecipient,
        address pytRecipient,
        address vault,
        IxPYT xPYT
    ) external virtual nonReentrant returns (uint256 yieldAmount) {
        // update storage variables and compute yield amount
        uint256 updatedPricePerVaultShare = getPricePerVaultShare(vault);
        yieldAmount = _claimYield(vault, updatedPricePerVaultShare);

        // use yield to mint NYT and PYT
        if (yieldAmount != 0) {
            (uint8 fee, address protocolFeeRecipient) = factory
                .protocolFeeInfo();

            if (fee != 0) {
                uint256 protocolFee = (yieldAmount * fee) / 1000;
                unchecked {
                    // can't underflow since fee < 256
                    yieldAmount -= protocolFee;
                }

                if (vaultSharesIsERC20()) {
                    // vault shares are in ERC20
                    // do share transfer
                    protocolFee = _underlyingAmountToVaultSharesAmount(
                        vault,
                        protocolFee,
                        updatedPricePerVaultShare
                    );
                    uint256 vaultSharesBalance = ERC20(vault).balanceOf(
                        address(this)
                    );
                    if (protocolFee > vaultSharesBalance) {
                        protocolFee = vaultSharesBalance;
                    }
                    if (protocolFee != 0) {
                        ERC20(vault).safeTransfer(
                            protocolFeeRecipient,
                            protocolFee
                        );
                    }
                } else {
                    // vault shares are not in ERC20
                    // withdraw underlying from vault
                    // checkBalance is set to true to prevent getting stuck
                    // due to rounding errors
                    if (protocolFee != 0) {
                        _withdrawFromVault(
                            protocolFeeRecipient,
                            vault,
                            protocolFee,
                            updatedPricePerVaultShare,
                            true
                        );
                    }
                }
            }

            NegativeYieldToken nyt = getNegativeYieldTokenForVault(vault);
            PerpetualYieldToken pyt = getPerpetualYieldTokenForVault(vault);

            if (address(xPYT) == address(0)) {
                // accrue yield to pytRecipient if they're not msg.sender
                // no need to do it if the recipient is msg.sender, since
                // we already accrued yield in _claimYield
                if (pytRecipient != msg.sender) {
                    _accrueYield(
                        vault,
                        pyt,
                        pytRecipient,
                        updatedPricePerVaultShare
                    );
                }
            } else {
                // accrue yield to xPYT contract since it gets minted PYT
                _accrueYield(
                    vault,
                    pyt,
                    address(xPYT),
                    updatedPricePerVaultShare
                );
            }

            // mint NYTs and PYTs
            nyt.gateMint(nytRecipient, yieldAmount);
            if (address(xPYT) == address(0)) {
                // mint raw PYT to recipient
                pyt.gateMint(pytRecipient, yieldAmount);
            } else {
                // mint PYT to xPYT contract
                pyt.gateMint(address(xPYT), yieldAmount);

                /// -----------------------------------------------------------------------
                /// Effects
                /// -----------------------------------------------------------------------

                // call sweep to mint xPYT using the PYT
                xPYT.sweep(pytRecipient);
            }

            emit ClaimYieldAndEnter(
                msg.sender,
                nytRecipient,
                pytRecipient,
                vault,
                xPYT,
                yieldAmount
            );
        }
    }

    /// -----------------------------------------------------------------------
    /// Getters
    /// -----------------------------------------------------------------------

    /// @notice Returns the NegativeYieldToken associated with a vault.
    /// @dev Returns non-zero value even if the contract hasn't been deployed yet.
    /// @param vault The vault to query
    /// @return The NegativeYieldToken address
    function getNegativeYieldTokenForVault(address vault)
        public
        view
        virtual
        returns (NegativeYieldToken)
    {
        return factory.getNegativeYieldToken(this, vault);
    }

    /// @notice Returns the PerpetualYieldToken associated with a vault.
    /// @dev Returns non-zero value even if the contract hasn't been deployed yet.
    /// @param vault The vault to query
    /// @return The PerpetualYieldToken address
    function getPerpetualYieldTokenForVault(address vault)
        public
        view
        virtual
        returns (PerpetualYieldToken)
    {
        return factory.getPerpetualYieldToken(this, vault);
    }

    /// @notice Returns the amount of yield claimable by a PerpetualYieldToken holder from a vault.
    /// Accounts for protocol fees.
    /// @param vault The vault to query
    /// @param user The PYT holder to query
    /// @return yieldAmount The amount of yield claimable
    function getClaimableYieldAmount(address vault, address user)
        external
        view
        virtual
        returns (uint256 yieldAmount)
    {
        PerpetualYieldToken pyt = getPerpetualYieldTokenForVault(vault);
        uint256 userYieldPerTokenStored_ = userYieldPerTokenStored[vault][user];
        if (userYieldPerTokenStored_ == 0) {
            // uninitialized account
            return 0;
        }
        yieldAmount = _getClaimableYieldAmount(
            vault,
            user,
            _computeYieldPerToken(vault, pyt, getPricePerVaultShare(vault)),
            userYieldPerTokenStored_,
            pyt.balanceOf(user)
        );
        (uint8 fee, ) = factory.protocolFeeInfo();
        if (fee != 0) {
            uint256 protocolFee = (yieldAmount * fee) / 1000;
            unchecked {
                // can't underflow since fee < 256
                yieldAmount -= protocolFee;
            }
        }
    }

    /// @notice Computes the latest yieldPerToken value for a vault.
    /// @param vault The vault to query
    /// @return The latest yieldPerToken value
    function computeYieldPerToken(address vault)
        external
        view
        virtual
        returns (uint256)
    {
        return
            _computeYieldPerToken(
                vault,
                getPerpetualYieldTokenForVault(vault),
                getPricePerVaultShare(vault)
            );
    }

    /// @notice Returns the underlying token of a vault.
    /// @param vault The vault to query
    /// @return The underlying token
    function getUnderlyingOfVault(address vault)
        public
        view
        virtual
        returns (ERC20);

    /// @notice Returns the amount of underlying tokens each share of a vault is worth.
    /// @param vault The vault to query
    /// @return The pricePerVaultShare value
    function getPricePerVaultShare(address vault)
        public
        view
        virtual
        returns (uint256);

    /// @notice Returns the amount of vault shares owned by the gate.
    /// @param vault The vault to query
    /// @return The gate's vault share balance
    function getVaultShareBalance(address vault)
        public
        view
        virtual
        returns (uint256);

    /// @return True if the vaults supported by this gate use transferrable ERC20 tokens
    /// to represent shares, false otherwise.
    function vaultSharesIsERC20() public pure virtual returns (bool);

    /// @notice Computes the ERC20 name of the NegativeYieldToken of a vault.
    /// @param vault The vault to query
    /// @return The ERC20 name
    function negativeYieldTokenName(address vault)
        external
        view
        virtual
        returns (string memory);

    /// @notice Computes the ERC20 symbol of the NegativeYieldToken of a vault.
    /// @param vault The vault to query
    /// @return The ERC20 symbol
    function negativeYieldTokenSymbol(address vault)
        external
        view
        virtual
        returns (string memory);

    /// @notice Computes the ERC20 name of the PerpetualYieldToken of a vault.
    /// @param vault The vault to query
    /// @return The ERC20 name
    function perpetualYieldTokenName(address vault)
        external
        view
        virtual
        returns (string memory);

    /// @notice Computes the ERC20 symbol of the NegativeYieldToken of a vault.
    /// @param vault The vault to query
    /// @return The ERC20 symbol
    function perpetualYieldTokenSymbol(address vault)
        external
        view
        virtual
        returns (string memory);

    /// -----------------------------------------------------------------------
    /// PYT transfer hook
    /// -----------------------------------------------------------------------

    /// @notice SHOULD NOT BE CALLED BY USERS, ONLY CALLED BY PERPETUAL YIELD TOKEN CONTRACTS
    /// @dev Called by PYT contracts deployed by this gate before each token transfer, in order to
    /// accrue the yield earned by the from & to accounts
    /// @param from The token transfer from account
    /// @param to The token transfer to account
    /// @param fromBalance The token balance of the from account before the transfer
    /// @param toBalance The token balance of the to account before the transfer
    function beforePerpetualYieldTokenTransfer(
        address from,
        address to,
        uint256 amount,
        uint256 fromBalance,
        uint256 toBalance
    ) external virtual {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        if (amount == 0) {
            return;
        }

        address vault = PerpetualYieldToken(msg.sender).vault();
        PerpetualYieldToken pyt = getPerpetualYieldTokenForVault(vault);
        if (msg.sender != address(pyt)) {
            revert Error_SenderNotPerpetualYieldToken();
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // accrue yield
        uint256 updatedPricePerVaultShare = getPricePerVaultShare(vault);
        uint256 updatedYieldPerToken = _computeYieldPerToken(
            vault,
            pyt,
            updatedPricePerVaultShare
        );
        yieldPerTokenStored[vault] = updatedYieldPerToken;
        pricePerVaultShareStored[vault] = updatedPricePerVaultShare;

        // we know the from account must have held PYTs before
        // so we will always accrue the yield earned by the from account
        userAccruedYield[vault][from] =
            _getClaimableYieldAmount(
                vault,
                from,
                updatedYieldPerToken,
                userYieldPerTokenStored[vault][from],
                fromBalance
            ) +
            1;
        userYieldPerTokenStored[vault][from] = updatedYieldPerToken + 1;

        // the to account might not have held PYTs before
        // we only accrue yield if they have
        uint256 toUserYieldPerTokenStored = userYieldPerTokenStored[vault][to];
        if (toUserYieldPerTokenStored != 0) {
            // to account has held PYTs before
            userAccruedYield[vault][to] =
                _getClaimableYieldAmount(
                    vault,
                    to,
                    updatedYieldPerToken,
                    toUserYieldPerTokenStored,
                    toBalance
                ) +
                1;
        }
        userYieldPerTokenStored[vault][to] = updatedYieldPerToken + 1;
    }

    /// -----------------------------------------------------------------------
    /// Emergency exit
    /// -----------------------------------------------------------------------

    /// @notice Activates the emergency exit mode for a certain vault. Only callable by owner.
    /// @dev Activating emergency exit allows PYT/NYT holders to do single-sided burns to redeem the underlying
    /// collateral. This is to prevent cases where a large portion of PYT/NYT is locked up in a buggy/malicious contract
    /// and locks up the underlying collateral forever.
    /// @param vault The vault to activate emergency exit for
    /// @param pytPriceInUnderlying The amount of underlying asset burning each PYT can redeem. Scaled by PRECISION.
    function ownerActivateEmergencyExitForVault(
        address vault,
        uint96 pytPriceInUnderlying
    ) external virtual onlyOwner {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        // we only allow emergency exit to be activated once (until deactivation)
        // because if pytPriceInUnderlying is ever modified after activation
        // then PYT/NYT will become unbacked
        if (emergencyExitStatusOfVault[vault].activated) {
            revert Error_EmergencyExitAlreadyActivated();
        }

        // we need to ensure the PYT price value is within the range [0, PRECISION]
        if (pytPriceInUnderlying > PRECISION) {
            revert Error_InvalidInput();
        }

        // the PYT & NYT must have already been deployed
        NegativeYieldToken nyt = getNegativeYieldTokenForVault(vault);
        if (address(nyt).code.length == 0) {
            revert Error_TokenPairNotDeployed();
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        emergencyExitStatusOfVault[vault] = EmergencyExitStatus({
            activated: true,
            pytPriceInUnderlying: pytPriceInUnderlying
        });
    }

    /// @notice Deactivates the emergency exit mode for a certain vault. Only callable by owner.
    /// @param vault The vault to deactivate emergency exit for
    function ownerDeactivateEmergencyExitForVault(address vault)
        external
        virtual
        onlyOwner
    {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        // can only deactivate emergency exit when it's already activated
        if (!emergencyExitStatusOfVault[vault].activated) {
            revert Error_EmergencyExitNotActivated();
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // reset the emergency exit status
        delete emergencyExitStatusOfVault[vault];
    }

    /// @notice Emergency exit NYTs into the underlying asset. Only callable when emergency exit has
    /// been activated for the vault.
    /// @param vault The vault to exit NYT for
    /// @param amount The amount of NYT to exit
    /// @param recipient The recipient of the underlying asset
    /// @return underlyingAmount The amount of underlying asset exited
    function emergencyExitNegativeYieldToken(
        address vault,
        uint256 amount,
        address recipient
    ) external virtual returns (uint256 underlyingAmount) {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        // ensure emergency exit is active
        EmergencyExitStatus memory status = emergencyExitStatusOfVault[vault];
        if (!status.activated) {
            revert Error_EmergencyExitNotActivated();
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        PerpetualYieldToken pyt = getPerpetualYieldTokenForVault(vault);
        uint256 updatedPricePerVaultShare = getPricePerVaultShare(vault);

        // accrue yield
        _accrueYield(vault, pyt, msg.sender, updatedPricePerVaultShare);

        // burn NYT from the sender
        NegativeYieldToken nyt = getNegativeYieldTokenForVault(vault);
        nyt.gateBurn(msg.sender, amount);

        /// -----------------------------------------------------------------------
        /// Effects
        /// -----------------------------------------------------------------------

        // compute how much of the underlying assets to give the recipient
        // rounds down
        underlyingAmount = FullMath.mulDiv(
            amount,
            PRECISION - status.pytPriceInUnderlying,
            PRECISION
        );

        // withdraw underlying from vault to recipient
        // don't check balance since user can just withdraw slightly less
        // saves gas this way
        underlyingAmount = _withdrawFromVault(
            recipient,
            vault,
            underlyingAmount,
            updatedPricePerVaultShare,
            false
        );
    }

    /// @notice Emergency exit PYTs into the underlying asset. Only callable when emergency exit has
    /// been activated for the vault.
    /// @param vault The vault to exit PYT for
    /// @param xPYT The xPYT contract to use for burning PYT. Set to 0 to burn raw PYT instead.
    /// @param amount The amount of PYT to exit
    /// @param recipient The recipient of the underlying asset
    /// @return underlyingAmount The amount of underlying asset exited
    function emergencyExitPerpetualYieldToken(
        address vault,
        IxPYT xPYT,
        uint256 amount,
        address recipient
    ) external virtual returns (uint256 underlyingAmount) {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        // ensure emergency exit is active
        EmergencyExitStatus memory status = emergencyExitStatusOfVault[vault];
        if (!status.activated) {
            revert Error_EmergencyExitNotActivated();
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        PerpetualYieldToken pyt = getPerpetualYieldTokenForVault(vault);
        uint256 updatedPricePerVaultShare = getPricePerVaultShare(vault);

        // accrue yield
        _accrueYield(vault, pyt, msg.sender, updatedPricePerVaultShare);

        if (address(xPYT) == address(0)) {
            // burn raw PYT from sender
            pyt.gateBurn(msg.sender, amount);
        } else {
            /// -----------------------------------------------------------------------
            /// Effects
            /// -----------------------------------------------------------------------

            // convert xPYT to PYT then burn
            xPYT.withdraw(amount, address(this), msg.sender);
            pyt.gateBurn(address(this), amount);
        }

        /// -----------------------------------------------------------------------
        /// Effects
        /// -----------------------------------------------------------------------

        // compute how much of the underlying assets to give the recipient
        // rounds down
        underlyingAmount = FullMath.mulDiv(
            amount,
            status.pytPriceInUnderlying,
            PRECISION
        );

        // withdraw underlying from vault to recipient
        // don't check balance since user can just withdraw slightly less
        // saves gas this way
        underlyingAmount = _withdrawFromVault(
            recipient,
            vault,
            underlyingAmount,
            updatedPricePerVaultShare,
            false
        );
    }

    /// -----------------------------------------------------------------------
    /// Internal utilities
    /// -----------------------------------------------------------------------

    /// @dev Updates the yield earned globally and for a particular user.
    function _accrueYield(
        address vault,
        PerpetualYieldToken pyt,
        address user,
        uint256 updatedPricePerVaultShare
    ) internal virtual {
        uint256 updatedYieldPerToken = _computeYieldPerToken(
            vault,
            pyt,
            updatedPricePerVaultShare
        );
        uint256 userYieldPerTokenStored_ = userYieldPerTokenStored[vault][user];
        if (userYieldPerTokenStored_ != 0) {
            userAccruedYield[vault][user] =
                _getClaimableYieldAmount(
                    vault,
                    user,
                    updatedYieldPerToken,
                    userYieldPerTokenStored_,
                    pyt.balanceOf(user)
                ) +
                1;
        }
        yieldPerTokenStored[vault] = updatedYieldPerToken;
        pricePerVaultShareStored[vault] = updatedPricePerVaultShare;
        userYieldPerTokenStored[vault][user] = updatedYieldPerToken + 1;
    }

    /// @dev Mints PYTs and NYTs to the recipient given the amount of underlying deposited.
    function _enter(
        address nytRecipient,
        address pytRecipient,
        address vault,
        IxPYT xPYT,
        uint256 underlyingAmount,
        uint256 updatedPricePerVaultShare
    ) internal virtual {
        NegativeYieldToken nyt = getNegativeYieldTokenForVault(vault);
        if (address(nyt).code.length == 0) {
            // token pair hasn't been deployed yet
            // do the deployment now
            // only need to check nyt since nyt and pyt are always deployed in pairs
            factory.deployYieldTokenPair(this, vault);
        }
        PerpetualYieldToken pyt = getPerpetualYieldTokenForVault(vault);

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // accrue yield
        _accrueYield(
            vault,
            pyt,
            address(xPYT) == address(0) ? pytRecipient : address(xPYT),
            updatedPricePerVaultShare
        );

        // mint NYTs and PYTs
        nyt.gateMint(nytRecipient, underlyingAmount);
        if (address(xPYT) == address(0)) {
            // mint raw PYT to recipient
            pyt.gateMint(pytRecipient, underlyingAmount);
        } else {
            // mint PYT to xPYT contract
            pyt.gateMint(address(xPYT), underlyingAmount);

            /// -----------------------------------------------------------------------
            /// Effects
            /// -----------------------------------------------------------------------

            // call sweep to mint xPYT using the PYT
            xPYT.sweep(pytRecipient);
        }
    }

    /// @dev Burns PYTs and NYTs from msg.sender given the amount of underlying withdrawn.
    function _exit(
        address vault,
        IxPYT xPYT,
        uint256 underlyingAmount,
        uint256 updatedPricePerVaultShare
    ) internal virtual {
        NegativeYieldToken nyt = getNegativeYieldTokenForVault(vault);
        PerpetualYieldToken pyt = getPerpetualYieldTokenForVault(vault);
        if (address(nyt).code.length == 0) {
            revert Error_TokenPairNotDeployed();
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // accrue yield
        _accrueYield(
            vault,
            pyt,
            address(xPYT) == address(0) ? msg.sender : address(this),
            updatedPricePerVaultShare
        );

        // burn NYTs and PYTs
        nyt.gateBurn(msg.sender, underlyingAmount);
        if (address(xPYT) == address(0)) {
            // burn raw PYT from sender
            pyt.gateBurn(msg.sender, underlyingAmount);
        } else {
            /// -----------------------------------------------------------------------
            /// Effects
            /// -----------------------------------------------------------------------

            // convert xPYT to PYT then burn
            xPYT.withdraw(underlyingAmount, address(this), msg.sender);
            pyt.gateBurn(address(this), underlyingAmount);
        }
    }

    /// @dev Updates storage variables for when a PYT holder claims the accrued yield.
    function _claimYield(address vault, uint256 updatedPricePerVaultShare)
        internal
        virtual
        returns (uint256 yieldAmount)
    {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        PerpetualYieldToken pyt = getPerpetualYieldTokenForVault(vault);
        if (address(pyt).code.length == 0) {
            revert Error_TokenPairNotDeployed();
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // accrue yield
        uint256 updatedYieldPerToken = _computeYieldPerToken(
            vault,
            pyt,
            updatedPricePerVaultShare
        );
        uint256 userYieldPerTokenStored_ = userYieldPerTokenStored[vault][
            msg.sender
        ];
        if (userYieldPerTokenStored_ != 0) {
            yieldAmount = _getClaimableYieldAmount(
                vault,
                msg.sender,
                updatedYieldPerToken,
                userYieldPerTokenStored_,
                pyt.balanceOf(msg.sender)
            );
        }
        yieldPerTokenStored[vault] = updatedYieldPerToken;
        pricePerVaultShareStored[vault] = updatedPricePerVaultShare;
        userYieldPerTokenStored[vault][msg.sender] = updatedYieldPerToken + 1;
        if (yieldAmount != 0) {
            userAccruedYield[vault][msg.sender] = 1;
        }
    }

    /// @dev Returns the amount of yield claimable by a PerpetualYieldToken holder from a vault.
    /// Assumes userYieldPerTokenStored_ != 0. Does not account for protocol fees.
    function _getClaimableYieldAmount(
        address vault,
        address user,
        uint256 updatedYieldPerToken,
        uint256 userYieldPerTokenStored_,
        uint256 userPYTBalance
    ) internal view virtual returns (uint256 yieldAmount) {
        unchecked {
            // the stored value is shifted by one
            uint256 actualUserYieldPerToken = userYieldPerTokenStored_ - 1;

            // updatedYieldPerToken - actualUserYieldPerToken won't underflow since we check updatedYieldPerToken > actualUserYieldPerToken
            yieldAmount = FullMath.mulDiv(
                userPYTBalance,
                updatedYieldPerToken > actualUserYieldPerToken
                    ? updatedYieldPerToken - actualUserYieldPerToken
                    : 0,
                PRECISION
            );

            uint256 accruedYield = userAccruedYield[vault][user];
            if (accruedYield > 1) {
                // won't overflow since the sum is at most the totalSupply of the vault's underlying, which
                // is at most 256 bits.
                // the stored accruedYield value is shifted by one
                yieldAmount += accruedYield - 1;
            }
        }
    }

    /// @dev Deposits underlying tokens into a vault
    /// @param underlying The underlying token to deposit
    /// @param underlyingAmount The amount of tokens to deposit
    /// @param vault The vault to deposit into
    function _depositIntoVault(
        ERC20 underlying,
        uint256 underlyingAmount,
        address vault
    ) internal virtual;

    /// @dev Withdraws underlying tokens from a vault
    /// @param recipient The recipient of the underlying tokens
    /// @param vault The vault to withdraw from
    /// @param underlyingAmount The amount of tokens to withdraw
    /// @param pricePerVaultShare The latest price per vault share value
    /// @param checkBalance Set to true to withdraw the entire balance if we're trying
    /// to withdraw more than the balance (due to rounding errors)
    /// @return withdrawnUnderlyingAmount The amount of underlying tokens withdrawn
    function _withdrawFromVault(
        address recipient,
        address vault,
        uint256 underlyingAmount,
        uint256 pricePerVaultShare,
        bool checkBalance
    ) internal virtual returns (uint256 withdrawnUnderlyingAmount);

    /// @dev Converts a vault share amount into an equivalent underlying asset amount
    function _vaultSharesAmountToUnderlyingAmount(
        address vault,
        uint256 vaultSharesAmount,
        uint256 pricePerVaultShare
    ) internal view virtual returns (uint256);

    /// @dev Converts a vault share amount into an equivalent underlying asset amount, rounding up
    function _vaultSharesAmountToUnderlyingAmountRoundingUp(
        address vault,
        uint256 vaultSharesAmount,
        uint256 pricePerVaultShare
    ) internal view virtual returns (uint256);

    /// @dev Converts an underlying asset amount into an equivalent vault shares amount
    function _underlyingAmountToVaultSharesAmount(
        address vault,
        uint256 underlyingAmount,
        uint256 pricePerVaultShare
    ) internal view virtual returns (uint256);

    /// @dev Computes the latest yieldPerToken value for a vault.
    function _computeYieldPerToken(
        address vault,
        PerpetualYieldToken pyt,
        uint256 updatedPricePerVaultShare
    ) internal view virtual returns (uint256) {
        uint256 pytTotalSupply = pyt.totalSupply();
        if (pytTotalSupply == 0) {
            return yieldPerTokenStored[vault];
        }
        uint256 pricePerVaultShareStored_ = pricePerVaultShareStored[vault];
        if (updatedPricePerVaultShare <= pricePerVaultShareStored_) {
            // rounding error in vault share or no yield accrued
            return yieldPerTokenStored[vault];
        }
        uint256 newYieldPerTokenAccrued;
        unchecked {
            // can't underflow since we know updatedPricePerVaultShare > pricePerVaultShareStored_
            newYieldPerTokenAccrued = FullMath.mulDiv(
                updatedPricePerVaultShare - pricePerVaultShareStored_,
                getVaultShareBalance(vault),
                pytTotalSupply
            );
        }
        return yieldPerTokenStored[vault] + newYieldPerTokenAccrued;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import {Gate} from "./Gate.sol";
import {BaseERC20} from "./lib/BaseERC20.sol";

/// @title NegativeYieldToken
/// @author zefram.eth
/// @notice The ERC20 contract representing negative yield tokens
contract NegativeYieldToken is BaseERC20 {
    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(Gate gate_, address vault_)
        BaseERC20(
            gate_.negativeYieldTokenName(vault_),
            gate_.negativeYieldTokenSymbol(vault_),
            gate_,
            vault_
        )
    {}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import {Gate} from "./Gate.sol";
import {BaseERC20} from "./lib/BaseERC20.sol";

/// @title PerpetualYieldToken
/// @author zefram.eth
/// @notice The ERC20 contract representing perpetual yield tokens
contract PerpetualYieldToken is BaseERC20 {
    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(Gate gate_, address vault_)
        BaseERC20(
            gate_.perpetualYieldTokenName(vault_),
            gate_.perpetualYieldTokenSymbol(vault_),
            gate_,
            vault_
        )
    {}

    /// -----------------------------------------------------------------------
    /// ERC20 overrides
    /// -----------------------------------------------------------------------

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        // load balances to save gas
        uint256 fromBalance = balanceOf[msg.sender];
        uint256 toBalance = balanceOf[to];

        // call transfer hook
        gate.beforePerpetualYieldTokenTransfer(
            msg.sender,
            to,
            amount,
            fromBalance,
            toBalance
        );

        // do transfer
        // skip during self transfers since toBalance is cached
        // which leads to free minting, a critical issue
        if (msg.sender != to) {
            balanceOf[msg.sender] = fromBalance - amount;

            // Cannot overflow because the sum of all user
            // balances can't exceed the max uint256 value.
            unchecked {
                balanceOf[to] = toBalance + amount;
            }
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        // load balances to save gas
        uint256 fromBalance = balanceOf[from];
        uint256 toBalance = balanceOf[to];

        // call transfer hook
        gate.beforePerpetualYieldTokenTransfer(
            from,
            to,
            amount,
            fromBalance,
            toBalance
        );

        // update allowance
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        // do transfer
        // skip during self transfers since toBalance is cached
        // which leads to free minting, a critical issue
        if (from != to) {
            balanceOf[from] = fromBalance - amount;

            // Cannot overflow because the sum of all user
            // balances can't exceed the max uint256 value.
            unchecked {
                balanceOf[to] = toBalance + amount;
            }
        }

        emit Transfer(from, to, amount);

        return true;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.13;

import {ERC4626} from "solmate/mixins/ERC4626.sol";

abstract contract IxPYT is ERC4626 {
    function sweep(address receiver) external virtual returns (uint256 shares);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

import {ERC20} from "solmate/tokens/ERC20.sol";

import {Gate} from "../Gate.sol";

/// @title BaseERC20
/// @author zefram.eth
/// @notice The base ERC20 contract used by NegativeYieldToken and PerpetualYieldToken
/// @dev Uses the same number of decimals as the vault's underlying token
contract BaseERC20 is ERC20 {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error Error_NotGate();

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    Gate public immutable gate;
    address public immutable vault;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(
        string memory name_,
        string memory symbol_,
        Gate gate_,
        address vault_
    ) ERC20(name_, symbol_, gate_.getUnderlyingOfVault(vault_).decimals()) {
        gate = gate_;
        vault = vault_;
    }

    /// -----------------------------------------------------------------------
    /// Gate-callable functions
    /// -----------------------------------------------------------------------

    function gateMint(address to, uint256 amount) external virtual {
        if (msg.sender != address(gate)) {
            revert Error_NotGate();
        }

        _mint(to, amount);
    }

    function gateBurn(address from, uint256 amount) external virtual {
        if (msg.sender != address(gate)) {
            revert Error_NotGate();
        }

        _burn(from, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall {
    function multicall(bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.5.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
/// @dev These functions are expected to be embedded in multicalls to allow EOAs to approve a contract and call a function
/// that requires an approval in a single transaction.
abstract contract SelfPermit {
    function selfPermit(
        ERC20 token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        token.permit(msg.sender, address(this), value, deadline, v, r, s);
    }

    function selfPermitIfNecessary(
        ERC20 token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        if (token.allowance(msg.sender, address(this)) < value)
            selfPermit(token, value, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

import "bunni/interfaces/IBunniHub.sol";

import {ILiquidityGauge} from "gauge-foundry/interfaces/ILiquidityGauge.sol";

import {WETH} from "solmate/tokens/WETH.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {Gate, IxPYT} from "timeless/Gate.sol";

import {Multicall} from "./lib/Multicall.sol";
import {SelfPermit} from "./lib/SelfPermit.sol";

contract BunniLpZapIn is ReentrancyGuard, Multicall, SelfPermit {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error BunniLpZapIn__SameToken();
    error BunniLpZapIn__PastDeadline();
    error BunniLpZapIn__ZeroExSwapFailed();
    error BunniLpZapIn__InsufficientOutput();

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @notice The 0x proxy contract used for 0x swaps
    address public immutable zeroExProxy;

    /// @notice The Wrapped Ethereum contract
    WETH public immutable weth;

    /// @notice BunniHub for managing Uniswap v3 liquidity
    IBunniHub public immutable bunniHub;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address zeroExProxy_, WETH weth_, IBunniHub bunniHub_) {
        zeroExProxy = zeroExProxy_;
        weth = weth_;
        bunniHub = bunniHub_;
    }

    /// -----------------------------------------------------------------------
    /// Zaps
    /// -----------------------------------------------------------------------

    /// @notice Deposits tokens into a Bunni LP position and then stakes it in a gauge. Any leftover tokens
    /// are refunded to the recipient address.
    /// @dev depositParams.recipient is always overridden to address(this) so can just make it 0,
    /// depositParams.amount0Desired and depositParams.amount1Desired are overridden to the balances
    /// of address(this) if the corresponding useContractBalance flag is set to true.
    /// @param depositParams The deposit params passed to BunniHub
    /// @param gauge The gauge contract to stake the LP tokens into. Make sure it isn't malicious!
    /// @param token0 The token0 of the Uniswap pair to LP into
    /// @param token1 The token1 of the Uniswap pair to LP into
    /// @param recipient The recipient of the staked gauge position
    /// @param sharesMin The minimum acceptable amount of shares received. Used for controlling slippage.
    /// @param useContractBalance0 Set to true to use the token0 balance of address(this) instead of msg.sender
    /// @param useContractBalance1 Set to true to use the token1 balance of address(this) instead of msg.sender
    /// @param compound Set to true to compound the Bunni pool before depositing
    /// @return shares The new share tokens minted to the sender
    /// @return addedLiquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function zapIn(
        IBunniHub.DepositParams memory depositParams,
        ILiquidityGauge gauge,
        ERC20 token0,
        ERC20 token1,
        address recipient,
        uint256 sharesMin,
        bool useContractBalance0,
        bool useContractBalance1,
        bool compound
    )
        external
        virtual
        nonReentrant
        returns (uint256 shares, uint128 addedLiquidity, uint256 amount0, uint256 amount1)
    {
        // transfer tokens in and modify deposit params
        if (!useContractBalance0) {
            token0.safeTransferFrom(msg.sender, address(this), depositParams.amount0Desired);
        } else {
            depositParams.amount0Desired = token0.balanceOf(address(this));
        }
        if (!useContractBalance1) {
            token1.safeTransferFrom(msg.sender, address(this), depositParams.amount1Desired);
        } else {
            depositParams.amount1Desired = token1.balanceOf(address(this));
        }
        depositParams.recipient = address(this);

        // compound if requested
        if (compound) {
            bunniHub.compound(depositParams.key);
        }

        // approve tokens to Bunni
        token0.safeApprove(address(bunniHub), depositParams.amount0Desired);
        token1.safeApprove(address(bunniHub), depositParams.amount1Desired);

        // deposit tokens into Bunni
        (shares, addedLiquidity, amount0, amount1) = bunniHub.deposit(depositParams);
        if (shares < sharesMin) {
            revert BunniLpZapIn__InsufficientOutput();
        }

        // stake Bunni shares into gauge
        bunniHub.getBunniToken(depositParams.key).approve(address(gauge), shares);
        gauge.deposit(shares, recipient);

        // refund tokens
        uint256 balance = token0.balanceOf(address(this));
        if (balance != 0) {
            token0.safeTransfer(recipient, balance);
        }
        balance = token1.balanceOf(address(this));
        if (balance != 0) {
            token1.safeTransfer(recipient, balance);
        }
    }

    /// -----------------------------------------------------------------------
    /// Timeless yield tokens support
    /// -----------------------------------------------------------------------

    /// @notice Mints Timeless yield tokens using the underlying asset.
    /// @param gate The Gate contract to use for minting the yield tokens
    /// @param nytRecipient The recipient of the minted NYT
    /// @param pytRecipient The recipient of the minted PYT
    /// @param vault The vault to mint NYT and PYT for
    /// @param xPYT The xPYT contract to deposit the minted PYT into. Set to 0 to receive raw PYT instead.
    /// @param underlyingAmount The amount of underlying tokens to use
    /// @param useContractBalance Set to true to use the contract's token balance as token input
    /// @return mintAmount The amount of NYT and PYT minted (the amounts are equal)
    function enterWithUnderlying(
        Gate gate,
        address nytRecipient,
        address pytRecipient,
        address vault,
        IxPYT xPYT,
        uint256 underlyingAmount,
        bool useContractBalance
    ) external nonReentrant returns (uint256 mintAmount) {
        // transfer tokens in
        ERC20 underlying = gate.getUnderlyingOfVault(vault);
        if (!useContractBalance) {
            underlying.safeTransferFrom(msg.sender, address(this), underlyingAmount);
        }

        // mint yield tokens
        underlying.safeApprove(address(gate), underlyingAmount);
        mintAmount = gate.enterWithUnderlying(nytRecipient, pytRecipient, vault, xPYT, underlyingAmount);

        // reset allowance
        if (underlying.allowance(address(this), address(gate)) != 0) {
            underlying.safeApprove(address(gate), 0);
        }
    }

    /// @notice Mints Timeless yield tokens using the vault token.
    /// @param gate The Gate contract to use for minting the yield tokens
    /// @param nytRecipient The recipient of the minted NYT
    /// @param pytRecipient The recipient of the minted PYT
    /// @param vault The vault to mint NYT and PYT for
    /// @param xPYT The xPYT contract to deposit the minted PYT into. Set to 0 to receive raw PYT instead.
    /// @param vaultSharesAmount The amount of vault share tokens to use
    /// @param useContractBalance Set to true to use the contract's token balance as token input
    /// @return mintAmount The amount of NYT and PYT minted (the amounts are equal)
    function enterWithVaultShares(
        Gate gate,
        address nytRecipient,
        address pytRecipient,
        address vault,
        IxPYT xPYT,
        uint256 vaultSharesAmount,
        bool useContractBalance
    ) external nonReentrant returns (uint256 mintAmount) {
        // transfer tokens in
        ERC20 vaultToken = ERC20(vault);
        if (!useContractBalance) {
            vaultToken.safeTransferFrom(msg.sender, address(this), vaultSharesAmount);
        }

        // mint yield tokens
        vaultToken.safeApprove(address(gate), vaultSharesAmount);
        mintAmount = gate.enterWithVaultShares(nytRecipient, pytRecipient, vault, xPYT, vaultSharesAmount);

        // reset allowance
        if (vaultToken.allowance(address(this), address(gate)) != 0) {
            vaultToken.safeApprove(address(gate), 0);
        }
    }

    /// -----------------------------------------------------------------------
    /// WETH support
    /// -----------------------------------------------------------------------

    /// @notice Wraps the user's ETH input into WETH
    /// @dev Should be used as part of a multicall to convert the user's ETH input into WETH
    /// so that it can be swapped into other tokens.
    function wrapEthInput() external payable {
        weth.deposit{value: msg.value}();
    }

    /// -----------------------------------------------------------------------
    /// 0x support
    /// -----------------------------------------------------------------------

    /// @notice Swaps between two regular tokens using 0x. Leftover input tokens are refunded
    /// to refundRecipient.
    /// @dev Used in conjuction with the 0x API https://www.0x.org/docs/api
    /// @param tokenIn The input token
    /// @param tokenAmountIn The amount of token input
    /// @param tokenOut The output token
    /// @param minAmountOut The minimum acceptable token output amount, used for slippage checking.
    /// @param recipient The recipient of the token output
    /// @param refundRecipient The recipient of refunded input tokens
    /// @param useContractBalance Set to true to use the contract's token balance as token input
    /// @param deadline The Unix timestamp (in seconds) after which the call will be reverted
    /// @param swapData The call data to zeroExProxy to execute the swap, obtained from
    /// the https://api.0x.org/swap/v1/quote endpoint
    /// @return tokenAmountOut The amount of token output
    function doZeroExSwap(
        ERC20 tokenIn,
        uint256 tokenAmountIn,
        ERC20 tokenOut,
        uint256 minAmountOut,
        address recipient,
        address refundRecipient,
        bool useContractBalance,
        uint256 deadline,
        bytes calldata swapData
    ) external payable virtual nonReentrant returns (uint256 tokenAmountOut) {
        // check if input token equals output
        if (tokenIn == tokenOut) {
            revert BunniLpZapIn__SameToken();
        }

        // check deadline
        if (block.timestamp > deadline) {
            revert BunniLpZapIn__PastDeadline();
        }

        // transfer in input tokens
        if (!useContractBalance) {
            tokenIn.safeTransferFrom(msg.sender, address(this), tokenAmountIn);
        }

        // approve zeroExProxy
        tokenIn.safeApprove(zeroExProxy, tokenAmountIn);

        // do swap via zeroExProxy
        (bool success,) = zeroExProxy.call(swapData);
        if (!success) {
            revert BunniLpZapIn__ZeroExSwapFailed();
        }

        // check slippage
        tokenAmountOut = tokenOut.balanceOf(address(this));
        if (tokenAmountOut < minAmountOut) {
            revert BunniLpZapIn__InsufficientOutput();
        }

        // transfer output tokens to recipient
        if (recipient != address(this)) {
            tokenOut.safeTransfer(recipient, tokenAmountOut);
        }

        // refund input tokens
        uint256 balance = tokenIn.balanceOf(address(this));
        if (balance != 0) {
            tokenIn.safeTransfer(refundRecipient, balance);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.4;

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall {
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @title Interface for permit
/// @notice Interface used by DAI/CHAI for permit
interface IERC20PermitAllowed {
    /// @notice Approve the spender to spend some tokens via the holder signature
    /// @dev This is the permit interface used by DAI and CHAI
    /// @param holder The address of the token holder, the token owner
    /// @param spender The address of the token spender
    /// @param nonce The holder's nonce, increases at each call to permit
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param allowed Boolean that sets approval amount, true for type(uint256).max and false for 0
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
/// @dev These functions are expected to be embedded in multicalls to allow EOAs to approve a contract and call a function
/// that requires an approval in a single transaction.
abstract contract SelfPermit {
    function selfPermit(address token, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public payable {
        ERC20(token).permit(msg.sender, address(this), value, deadline, v, r, s);
    }

    function selfPermitIfNecessary(address token, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
        payable
    {
        if (ERC20(token).allowance(msg.sender, address(this)) < value) selfPermit(token, value, deadline, v, r, s);
    }

    function selfPermitAllowed(address token, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s)
        public
        payable
    {
        IERC20PermitAllowed(token).permit(msg.sender, address(this), nonce, expiry, true, v, r, s);
    }

    function selfPermitAllowedIfNecessary(address token, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s)
        external
        payable
    {
        if (ERC20(token).allowance(msg.sender, address(this)) < type(uint256).max) {
            selfPermitAllowed(token, nonce, expiry, v, r, s);
        }
    }
}