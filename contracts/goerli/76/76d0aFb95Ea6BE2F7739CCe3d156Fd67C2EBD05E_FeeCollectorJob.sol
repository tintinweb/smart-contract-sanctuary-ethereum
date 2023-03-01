/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4 <0.9.0;

interface IERC20 {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/
  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approval(address indexed owner, address indexed spender, uint256 amount);

  /*///////////////////////////////////////////////////////////////
                              VARIABLES
  //////////////////////////////////////////////////////////////*/
  function name() external view returns (string memory _name);

  function symbol() external view returns (string memory _symbol);

  function decimals() external view returns (uint8 _decimals);

  function totalSupply() external view returns (uint256 _totalSupply);

  function balanceOf(address _account) external view returns (uint256);

  function allowance(address _owner, address _spender) external view returns (uint256);

  function nonces(address _account) external view returns (uint256);

  /*///////////////////////////////////////////////////////////////
                                LOGIC
  //////////////////////////////////////////////////////////////*/
  function approve(address spender, uint256 amount) external returns (bool);

  function transfer(address to, uint256 amount) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);

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
}

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

/// @title Keep3rDisputable contract
/// @notice Creates/resolves disputes for jobs or keepers
///         A disputed keeper is slashable and is not able to bond, activate, withdraw or receive direct payments
///         A disputed job is slashable and is not able to pay the keepers, withdraw tokens or to migrate
interface IKeep3rDisputable {
  /// @notice Emitted when a keeper or a job is disputed
  /// @param _jobOrKeeper The address of the disputed keeper/job
  /// @param _disputer The user that called the function and disputed the keeper
  event Dispute(address indexed _jobOrKeeper, address indexed _disputer);

  /// @notice Emitted when a dispute is resolved
  /// @param _jobOrKeeper The address of the disputed keeper/job
  /// @param _resolver The user that called the function and resolved the dispute
  event Resolve(address indexed _jobOrKeeper, address indexed _resolver);

  /// @notice Throws when a job or keeper is already disputed
  error AlreadyDisputed();

  /// @notice Throws when a job or keeper is not disputed and someone tries to resolve the dispute
  error NotDisputed();

  /// @notice Allows governor to create a dispute for a given keeper/job
  /// @param _jobOrKeeper The address in dispute
  function dispute(address _jobOrKeeper) external;

  /// @notice Allows governor to resolve a dispute on a keeper/job
  /// @param _jobOrKeeper The address cleared
  function resolve(address _jobOrKeeper) external;
}

/// @title Keep3rJobOwnership contract
/// @notice Handles the ownership of the jobs
interface IKeep3rJobOwnership {
  // Events

  /// @notice Emitted when Keep3rJobOwnership#changeJobOwnership is called
  /// @param _job The address of the job proposed to have a change of owner
  /// @param _owner The current owner of the job
  /// @param _pendingOwner The new address proposed to be the owner of the job
  event JobOwnershipChange(address indexed _job, address indexed _owner, address indexed _pendingOwner);

  /// @notice Emitted when Keep3rJobOwnership#JobOwnershipAssent is called
  /// @param _job The address of the job which the proposed owner will now own
  /// @param _previousOwner The previous owner of the job
  /// @param _newOwner The new owner of the job
  event JobOwnershipAssent(address indexed _job, address indexed _previousOwner, address indexed _newOwner);

  // Errors

  /// @notice Throws when the caller of the function is not the job owner
  error OnlyJobOwner();

  /// @notice Throws when the caller of the function is not the pending job owner
  error OnlyPendingJobOwner();

  // Variables

  /// @notice Maps the job to the owner of the job
  /// @param _job The address of the job
  /// @return _owner The address of the owner of the job
  function jobOwner(address _job) external view returns (address _owner);

  /// @notice Maps the job to its pending owner
  /// @param _job The address of the job
  /// @return _pendingOwner The address of the pending owner of the job
  function jobPendingOwner(address _job) external view returns (address _pendingOwner);

  // Methods

  /// @notice Proposes a new address to be the owner of the job
  /// @param _job The address of the job
  /// @param _newOwner The address of the proposed new owner
  function changeJobOwnership(address _job, address _newOwner) external;

  /// @notice The proposed address accepts to be the owner of the job
  /// @param _job The address of the job
  function acceptJobOwnership(address _job) external;
}

/// @title Keep3rJobManager contract
/// @notice Handles the addition and withdrawal of credits from a job
interface IKeep3rJobManager is IKeep3rJobOwnership {
  // Events

  /// @notice Emitted when Keep3rJobManager#addJob is called
  /// @param _job The address of the job to add
  /// @param _jobOwner The job's owner
  event JobAddition(address indexed _job, address indexed _jobOwner);

  // Errors

  /// @notice Throws when trying to add a job that has already been added
  error JobAlreadyAdded();

  /// @notice Throws when the address that is trying to register as a keeper is already a keeper
  error AlreadyAKeeper();

  // Methods

  /// @notice Allows any caller to add a new job
  /// @param _job Address of the contract for which work should be performed
  function addJob(address _job) external;
}

/// @title Keep3rJobFundableCredits contract
/// @notice Handles the addition and withdrawal of credits from a job
interface IKeep3rJobFundableCredits is IKeep3rJobOwnership {
  // Events

  /// @notice Emitted when Keep3rJobFundableCredits#addTokenCreditsToJob is called
  /// @param _job The address of the job being credited
  /// @param _token The address of the token being provided
  /// @param _provider The user that calls the function
  /// @param _amount The amount of credit being added to the job
  event TokenCreditAddition(address indexed _job, address indexed _token, address indexed _provider, uint256 _amount);

  /// @notice Emitted when Keep3rJobFundableCredits#withdrawTokenCreditsFromJob is called
  /// @param _job The address of the job from which the credits are withdrawn
  /// @param _token The credit being withdrawn from the job
  /// @param _receiver The user that receives the tokens
  /// @param _amount The amount of credit withdrawn
  event TokenCreditWithdrawal(address indexed _job, address indexed _token, address indexed _receiver, uint256 _amount);

  // Errors

  /// @notice Throws when the token is KP3R, as it should not be used for direct token payments
  error TokenUnallowed();

  /// @notice Throws when the token withdraw cooldown has not yet passed
  error JobTokenCreditsLocked();

  /// @notice Throws when the user tries to withdraw more tokens than it has
  error InsufficientJobTokenCredits();

  // Variables

  /// @notice Last block where tokens were added to the job
  /// @param _job The address of the job credited
  /// @param _token The address of the token credited
  /// @return _timestamp The last block where tokens were added to the job
  function jobTokenCreditsAddedAt(address _job, address _token) external view returns (uint256 _timestamp);

  // Methods

  /// @notice Add credit to a job to be paid out for work
  /// @param _job The address of the job being credited
  /// @param _token The address of the token being credited
  /// @param _amount The amount of credit being added
  function addTokenCreditsToJob(
    address _job,
    address _token,
    uint256 _amount
  ) external;

  /// @notice Withdraw credit from a job
  /// @param _job The address of the job from which the credits are withdrawn
  /// @param _token The address of the token being withdrawn
  /// @param _amount The amount of token to be withdrawn
  /// @param _receiver The user that will receive tokens
  function withdrawTokenCreditsFromJob(
    address _job,
    address _token,
    uint256 _amount,
    address _receiver
  ) external;
}

/// @title  Keep3rJobFundableLiquidity contract
/// @notice Handles the funding of jobs through specific liquidity pairs
interface IKeep3rJobFundableLiquidity is IKeep3rJobOwnership {
  // Events

  /// @notice Emitted when Keep3rJobFundableLiquidity#approveLiquidity function is called
  /// @param _liquidity The address of the liquidity pair being approved
  event LiquidityApproval(address _liquidity);

  /// @notice Emitted when Keep3rJobFundableLiquidity#revokeLiquidity function is called
  /// @param _liquidity The address of the liquidity pair being revoked
  event LiquidityRevocation(address _liquidity);

  /// @notice Emitted when IKeep3rJobFundableLiquidity#addLiquidityToJob function is called
  /// @param _job The address of the job to which liquidity will be added
  /// @param _liquidity The address of the liquidity being added
  /// @param _provider The user that calls the function
  /// @param _amount The amount of liquidity being added
  event LiquidityAddition(address indexed _job, address indexed _liquidity, address indexed _provider, uint256 _amount);

  /// @notice Emitted when IKeep3rJobFundableLiquidity#withdrawLiquidityFromJob function is called
  /// @param _job The address of the job of which liquidity will be withdrawn from
  /// @param _liquidity The address of the liquidity being withdrawn
  /// @param _receiver The receiver of the liquidity tokens
  /// @param _amount The amount of liquidity being withdrawn from the job
  event LiquidityWithdrawal(address indexed _job, address indexed _liquidity, address indexed _receiver, uint256 _amount);

  /// @notice Emitted when Keep3rJobFundableLiquidity#addLiquidityToJob function is called
  /// @param _job The address of the job whose credits will be updated
  /// @param _rewardedAt The time at which the job was last rewarded
  /// @param _currentCredits The current credits of the job
  /// @param _periodCredits The credits of the job for the current period
  event LiquidityCreditsReward(address indexed _job, uint256 _rewardedAt, uint256 _currentCredits, uint256 _periodCredits);

  /// @notice Emitted when Keep3rJobFundableLiquidity#forceLiquidityCreditsToJob function is called
  /// @param _job The address of the job whose credits will be updated
  /// @param _rewardedAt The time at which the job was last rewarded
  /// @param _currentCredits The current credits of the job
  event LiquidityCreditsForced(address indexed _job, uint256 _rewardedAt, uint256 _currentCredits);

  // Errors

  /// @notice Throws when the liquidity being approved has already been approved
  error LiquidityPairApproved();

  /// @notice Throws when the liquidity being removed has not been approved
  error LiquidityPairUnexistent();

  /// @notice Throws when trying to add liquidity to an unapproved pool
  error LiquidityPairUnapproved();

  /// @notice Throws when the job doesn't have the requested liquidity
  error JobLiquidityUnexistent();

  /// @notice Throws when trying to remove more liquidity than the job has
  error JobLiquidityInsufficient();

  /// @notice Throws when trying to add less liquidity than the minimum liquidity required
  error JobLiquidityLessThanMin();

  // Structs

  /// @notice Stores the tick information of the different liquidity pairs
  struct TickCache {
    int56 current; // Tracks the current tick
    int56 difference; // Stores the difference between the current tick and the last tick
    uint256 period; // Stores the period at which the last observation was made
  }

  // Variables

  /// @notice Lists liquidity pairs
  /// @return _list An array of addresses with all the approved liquidity pairs
  function approvedLiquidities() external view returns (address[] memory _list);

  /// @notice Amount of liquidity in a specified job
  /// @param _job The address of the job being checked
  /// @param _liquidity The address of the liquidity we are checking
  /// @return _amount Amount of liquidity in the specified job
  function liquidityAmount(address _job, address _liquidity) external view returns (uint256 _amount);

  /// @notice Last time the job was rewarded liquidity credits
  /// @param _job The address of the job being checked
  /// @return _timestamp Timestamp of the last time the job was rewarded liquidity credits
  function rewardedAt(address _job) external view returns (uint256 _timestamp);

  /// @notice Last time the job was worked
  /// @param _job The address of the job being checked
  /// @return _timestamp Timestamp of the last time the job was worked
  function workedAt(address _job) external view returns (uint256 _timestamp);

  // Methods

  /// @notice Returns the liquidity credits of a given job
  /// @param _job The address of the job of which we want to know the liquidity credits
  /// @return _amount The liquidity credits of a given job
  function jobLiquidityCredits(address _job) external view returns (uint256 _amount);

  /// @notice Returns the credits of a given job for the current period
  /// @param _job The address of the job of which we want to know the period credits
  /// @return _amount The credits the given job has at the current period
  function jobPeriodCredits(address _job) external view returns (uint256 _amount);

  /// @notice Calculates the total credits of a given job
  /// @param _job The address of the job of which we want to know the total credits
  /// @return _amount The total credits of the given job
  function totalJobCredits(address _job) external view returns (uint256 _amount);

  /// @notice Calculates how many credits should be rewarded periodically for a given liquidity amount
  /// @dev _periodCredits = underlying KP3Rs for given liquidity amount * rewardPeriod / inflationPeriod
  /// @param _liquidity The address of the liquidity to provide
  /// @param _amount The amount of liquidity to provide
  /// @return _periodCredits The amount of KP3R periodically minted for the given liquidity
  function quoteLiquidity(address _liquidity, uint256 _amount) external view returns (uint256 _periodCredits);

  /// @notice Observes the current state of the liquidity pair being observed and updates TickCache with the information
  /// @param _liquidity The address of the liquidity pair being observed
  /// @return _tickCache The updated TickCache
  function observeLiquidity(address _liquidity) external view returns (TickCache memory _tickCache);

  /// @notice Gifts liquidity credits to the specified job
  /// @param _job The address of the job being credited
  /// @param _amount The amount of liquidity credits to gift
  function forceLiquidityCreditsToJob(address _job, uint256 _amount) external;

  /// @notice Approve a liquidity pair for being accepted in future
  /// @param _liquidity The address of the liquidity accepted
  function approveLiquidity(address _liquidity) external;

  /// @notice Revoke a liquidity pair from being accepted in future
  /// @param _liquidity The liquidity no longer accepted
  function revokeLiquidity(address _liquidity) external;

  /// @notice Allows anyone to fund a job with liquidity
  /// @param _job The address of the job to assign liquidity to
  /// @param _liquidity The liquidity being added
  /// @param _amount The amount of liquidity tokens to add
  function addLiquidityToJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) external;

  /// @notice Unbond liquidity for a job
  /// @dev Can only be called by the job's owner
  /// @param _job The address of the job being unbonded from
  /// @param _liquidity The liquidity being unbonded
  /// @param _amount The amount of liquidity being removed
  function unbondLiquidityFromJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) external;

  /// @notice Withdraw liquidity from a job
  /// @param _job The address of the job being withdrawn from
  /// @param _liquidity The liquidity being withdrawn
  /// @param _receiver The address that will receive the withdrawn liquidity
  function withdrawLiquidityFromJob(
    address _job,
    address _liquidity,
    address _receiver
  ) external;
}

/// @title Keep3rJobMigration contract
/// @notice Handles the migration process of jobs to different addresses
interface IKeep3rJobMigration is IKeep3rJobFundableCredits, IKeep3rJobFundableLiquidity {
  // Events

  /// @notice Emitted when Keep3rJobMigration#migrateJob function is called
  /// @param _fromJob The address of the job that requests to migrate
  /// @param _toJob The address at which the job requests to migrate
  event JobMigrationRequested(address indexed _fromJob, address _toJob);

  /// @notice Emitted when Keep3rJobMigration#acceptJobMigration function is called
  /// @param _fromJob The address of the job that requested to migrate
  /// @param _toJob The address at which the job had requested to migrate
  event JobMigrationSuccessful(address _fromJob, address indexed _toJob);

  // Errors

  /// @notice Throws when the address of the job that requests to migrate wants to migrate to its same address
  error JobMigrationImpossible();

  /// @notice Throws when the _toJob address differs from the address being tracked in the pendingJobMigrations mapping
  error JobMigrationUnavailable();

  /// @notice Throws when cooldown between migrations has not yet passed
  error JobMigrationLocked();

  // Variables

  /// @notice Maps the jobs that have requested a migration to the address they have requested to migrate to
  /// @return _toJob The address to which the job has requested to migrate to
  function pendingJobMigrations(address _fromJob) external view returns (address _toJob);

  // Methods

  /// @notice Initializes the migration process for a job by adding the request to the pendingJobMigrations mapping
  /// @param _fromJob The address of the job that is requesting to migrate
  /// @param _toJob The address at which the job is requesting to migrate
  function migrateJob(address _fromJob, address _toJob) external;

  /// @notice Completes the migration process for a job
  /// @dev Unbond/withdraw process doesn't get migrated
  /// @param _fromJob The address of the job that requested to migrate
  /// @param _toJob The address to which the job wants to migrate to
  function acceptJobMigration(address _fromJob, address _toJob) external;
}

/// @title Keep3rJobWorkable contract
/// @notice Handles the mechanisms jobs can pay keepers with along with the restrictions jobs can put on keepers before they can work on jobs
interface IKeep3rJobWorkable is IKeep3rJobMigration {
  // Events

  /// @notice Emitted when a keeper is validated before a job
  /// @param _gasLeft The amount of gas that the transaction has left at the moment of keeper validation
  event KeeperValidation(uint256 _gasLeft);

  /// @notice Emitted when a keeper works a job
  /// @param _credit The address of the asset in which the keeper is paid
  /// @param _job The address of the job the keeper has worked
  /// @param _keeper The address of the keeper that has worked the job
  /// @param _payment The amount that has been paid out to the keeper in exchange for working the job
  /// @param _gasLeft The amount of gas that the transaction has left at the moment of payment
  event KeeperWork(address indexed _credit, address indexed _job, address indexed _keeper, uint256 _payment, uint256 _gasLeft);

  // Errors

  /// @notice Throws if work method was called without calling isKeeper or isBondedKeeper
  error GasNotInitialized();

  /// @notice Throws if the address claiming to be a job is not in the list of approved jobs
  error JobUnapproved();

  /// @notice Throws if the amount of funds in the job is less than the payment that must be paid to the keeper that works that job
  error InsufficientFunds();

  // Methods

  /// @notice Confirms if the current keeper is registered
  /// @dev Can be used for general (non critical) functions
  /// @param _keeper The keeper being investigated
  /// @return _isKeeper Whether the address passed as a parameter is a keeper or not
  function isKeeper(address _keeper) external returns (bool _isKeeper);

  /// @notice Confirms if the current keeper is registered and has a minimum bond of any asset.
  /// @dev Should be used for protected functions
  /// @param _keeper The keeper to check
  /// @param _bond The bond token being evaluated
  /// @param _minBond The minimum amount of bonded tokens
  /// @param _earned The minimum funds earned in the keepers lifetime
  /// @param _age The minimum keeper age required
  /// @return _isBondedKeeper Whether the `_keeper` meets the given requirements
  function isBondedKeeper(
    address _keeper,
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) external returns (bool _isBondedKeeper);

  /// @notice Implemented by jobs to show that a keeper performed work
  /// @dev Automatically calculates the payment for the keeper and pays the keeper with bonded KP3R
  /// @param _keeper Address of the keeper that performed the work
  function worked(address _keeper) external;

  /// @notice Implemented by jobs to show that a keeper performed work
  /// @dev Pays the keeper that performs the work with KP3R
  /// @param _keeper Address of the keeper that performed the work
  /// @param _payment The reward that should be allocated for the job
  function bondedPayment(address _keeper, uint256 _payment) external;

  /// @notice Implemented by jobs to show that a keeper performed work
  /// @dev Pays the keeper that performs the work with a specific token
  /// @param _token The asset being awarded to the keeper
  /// @param _keeper Address of the keeper that performed the work
  /// @param _amount The reward that should be allocated
  function directTokenPayment(
    address _token,
    address _keeper,
    uint256 _amount
  ) external;
}

/// @title Keep3rJobDisputable contract
/// @notice Handles the actions that can be taken on a disputed job
interface IKeep3rJobDisputable is IKeep3rDisputable, IKeep3rJobFundableCredits, IKeep3rJobFundableLiquidity {
  // Events

  /// @notice Emitted when Keep3rJobDisputable#slashTokenFromJob is called
  /// @param _job The address of the job from which the token will be slashed
  /// @param _token The address of the token being slashed
  /// @param _slasher The user that slashes the token
  /// @param _amount The amount of the token being slashed
  event JobSlashToken(address indexed _job, address _token, address indexed _slasher, uint256 _amount);

  /// @notice Emitted when Keep3rJobDisputable#slashLiquidityFromJob is called
  /// @param _job The address of the job from which the liquidity will be slashed
  /// @param _liquidity The address of the liquidity being slashed
  /// @param _slasher The user that slashes the liquidity
  /// @param _amount The amount of the liquidity being slashed
  event JobSlashLiquidity(address indexed _job, address _liquidity, address indexed _slasher, uint256 _amount);

  // Errors

  /// @notice Throws when the token trying to be slashed doesn't exist
  error JobTokenUnexistent();

  /// @notice Throws when someone tries to slash more tokens than the job has
  error JobTokenInsufficient();

  // Methods

  /// @notice Allows governor or slasher to slash a job specific token
  /// @param _job The address of the job from which the token will be slashed
  /// @param _token The address of the token that will be slashed
  /// @param _amount The amount of the token that will be slashed
  function slashTokenFromJob(
    address _job,
    address _token,
    uint256 _amount
  ) external;

  /// @notice Allows governor or slasher to slash liquidity from a job
  /// @param _job The address being slashed
  /// @param _liquidity The address of the liquidity that will be slashed
  /// @param _amount The amount of liquidity that will be slashed
  function slashLiquidityFromJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) external;
}

// solhint-disable-next-line no-empty-blocks
interface IKeep3rJobs is IKeep3rJobWorkable, IKeep3rJobManager, IKeep3rJobDisputable {

}

/// @title Keep3rKeeperFundable contract
/// @notice Handles the actions required to become a keeper
interface IKeep3rKeeperFundable {
  // Events

  /// @notice Emitted when Keep3rKeeperFundable#activate is called
  /// @param _keeper The keeper that has been activated
  /// @param _bond The asset the keeper has bonded
  /// @param _amount The amount of the asset the keeper has bonded
  event Activation(address indexed _keeper, address indexed _bond, uint256 _amount);

  /// @notice Emitted when Keep3rKeeperFundable#withdraw is called
  /// @param _keeper The caller of Keep3rKeeperFundable#withdraw function
  /// @param _bond The asset to withdraw from the bonding pool
  /// @param _amount The amount of funds withdrawn
  event Withdrawal(address indexed _keeper, address indexed _bond, uint256 _amount);

  // Errors

  /// @notice Throws when the address that is trying to register as a job is already a job
  error AlreadyAJob();

  // Methods

  /// @notice Beginning of the bonding process
  /// @param _bonding The asset being bonded
  /// @param _amount The amount of bonding asset being bonded
  function bond(address _bonding, uint256 _amount) external;

  /// @notice Beginning of the unbonding process
  /// @param _bonding The asset being unbonded
  /// @param _amount Allows for partial unbonding
  function unbond(address _bonding, uint256 _amount) external;

  /// @notice End of the bonding process after bonding time has passed
  /// @param _bonding The asset being activated as bond collateral
  function activate(address _bonding) external;

  /// @notice Withdraw funds after unbonding has finished
  /// @param _bonding The asset to withdraw from the bonding pool
  function withdraw(address _bonding) external;
}

/// @title Keep3rKeeperDisputable contract
/// @notice Handles the actions that can be taken on a disputed keeper
interface IKeep3rKeeperDisputable is IKeep3rDisputable, IKeep3rKeeperFundable {
  // Events

  /// @notice Emitted when Keep3rKeeperDisputable#slash is called
  /// @param _keeper The address of the slashed keeper
  /// @param _slasher The user that called Keep3rKeeperDisputable#slash
  /// @param _amount The amount of credits slashed from the keeper
  event KeeperSlash(address indexed _keeper, address indexed _slasher, uint256 _amount);

  /// @notice Emitted when Keep3rKeeperDisputable#revoke is called
  /// @param _keeper The address of the revoked keeper
  /// @param _slasher The user that called Keep3rKeeperDisputable#revoke
  event KeeperRevoke(address indexed _keeper, address indexed _slasher);

  // Methods

  /// @notice Allows governor to slash a keeper based on a dispute
  /// @param _keeper The address being slashed
  /// @param _bonded The asset being slashed
  /// @param _bondAmount The bonded amount being slashed
  /// @param _unbondAmount The pending unbond amount being slashed
  function slash(
    address _keeper,
    address _bonded,
    uint256 _bondAmount,
    uint256 _unbondAmount
  ) external;

  /// @notice Blacklists a keeper from participating in the network
  /// @param _keeper The address being slashed
  function revoke(address _keeper) external;
}

// solhint-disable-next-line no-empty-blocks

/// @title Keep3rKeepers contract
interface IKeep3rKeepers is IKeep3rKeeperDisputable {

}

interface IBaseErrors {
    /// @notice Thrown if an address is invalid
    error InvalidAddress();

    /// @notice Thrown if an amount is invalid
    error InvalidAmount();

    /// @notice Thrown if the lengths of a set of lists mismatch
    error LengthMismatch();

    /// @notice Thrown if an address is the zero address
    error ZeroAddress();

    /// @notice Thrown if an amount is zero
    error ZeroAmount();
}

/// @title Governable interface
interface IGovernable is IBaseErrors {
    // STATE VARIABLES

    /// @return _governor Address of the current governor
    function governor() external view returns (address _governor);

    /// @return _pendingGovernor Address of the current pending governor
    function pendingGovernor() external view returns (address _pendingGovernor);

    // EVENTS

    /// @notice Emitted when a new pending governor is set
    /// @param _governor Address of the current governor
    /// @param _pendingGovernor Address of the proposed next governor
    event PendingGovernorSet(address _governor, address _pendingGovernor);

    /// @notice Emitted when a new governor is set
    /// @param _newGovernor Address of the new governor
    event PendingGovernorAccepted(address _newGovernor);

    // ERRORS

    /// @notice Thrown if a non-governor user tries to call a OnlyGovernor function
    error OnlyGovernor();

    /// @notice Thrown if a non-pending-governor user tries to call a OnlyPendingGovernor function
    error OnlyPendingGovernor();

    // FUNCTIONS

    /// @notice Allows a governor to propose a new governor
    /// @param _pendingGovernor Address of the proposed new governor
    function setPendingGovernor(address _pendingGovernor) external;

    /// @notice Allows a proposed governor to accept the governance
    function acceptPendingGovernor() external;
}

/// @title DustCollector interface
interface IDustCollector is IBaseErrors, IGovernable {
    // STATE VARIABLES

    /// @return _ethAddress Address used to trigger a native token transfer
    // solhint-disable-next-line func-name-mixedcase
    function ETH_ADDRESS() external view returns (address _ethAddress);

    // EVENTS

    /// @notice Emitted when dust is sent
    /// @param _to The address which wil received the funds
    /// @param _token The token that will be transferred
    /// @param _amount The amount of the token that will be transferred
    event DustSent(address _token, uint256 _amount, address _to);

    // FUNCTIONS

    /// @notice Allows an authorized user to transfer the tokens or eth that may have been left in a contract
    /// @param _token The token that will be transferred
    /// @param _amount The amont of the token that will be transferred
    /// @param _to The address that will receive the idle funds
    function sendDust(address _token, uint256 _amount, address _to) external;
}

/// @title Keep3rRoles contract
/// @notice Manages the Keep3r specific roles
interface IKeep3rRoles is IBaseErrors, IGovernable, IDustCollector {
  // Events

  /// @notice Emitted when a slasher is added
  /// @param _slasher Address of the added slasher
  event SlasherAdded(address _slasher);

  /// @notice Emitted when a slasher is removed
  /// @param _slasher Address of the removed slasher
  event SlasherRemoved(address _slasher);

  /// @notice Emitted when a disputer is added
  /// @param _disputer Address of the added disputer
  event DisputerAdded(address _disputer);

  /// @notice Emitted when a disputer is removed
  /// @param _disputer Address of the removed disputer
  event DisputerRemoved(address _disputer);

  // Variables

  /// @notice Tracks whether the address is a slasher or not
  /// @param _slasher Address being checked as a slasher
  /// @return _isSlasher Whether the address is a slasher or not
  function slashers(address _slasher) external view returns (bool _isSlasher);

  /// @notice Tracks whether the address is a disputer or not
  /// @param _disputer Address being checked as a disputer
  /// @return _isDisputer Whether the address is a disputer or not
  function disputers(address _disputer) external view returns (bool _isDisputer);

  // Errors

  /// @notice Throws if the address is already a registered slasher
  error SlasherExistent();

  /// @notice Throws if caller is not a registered slasher
  error SlasherUnexistent();

  /// @notice Throws if the address is already a registered disputer
  error DisputerExistent();

  /// @notice Throws if caller is not a registered disputer
  error DisputerUnexistent();

  /// @notice Throws if the msg.sender is not a slasher or is not a part of governance
  error OnlySlasher();

  /// @notice Throws if the msg.sender is not a disputer or is not a part of governance
  error OnlyDisputer();

  // Methods

  /// @notice Registers a slasher by updating the slashers mapping
  function addSlasher(address _slasher) external;

  /// @notice Removes a slasher by updating the slashers mapping
  function removeSlasher(address _slasher) external;

  /// @notice Registers a disputer by updating the disputers mapping
  function addDisputer(address _disputer) external;

  /// @notice Removes a disputer by updating the disputers mapping
  function removeDisputer(address _disputer) external;
}

/// @title Keep3rDisputable contract
/// @notice Disputes keepers, or if they're already disputed, it can resolve the case
/// @dev Argument `bonding` can be the address of either a token or a liquidity
interface IKeep3rAccountance is IKeep3rRoles {
  // Events

  /// @notice Emitted when the bonding process of a new keeper begins
  /// @param _keeper The caller of Keep3rKeeperFundable#bond function
  /// @param _bonding The asset the keeper has bonded
  /// @param _amount The amount the keeper has bonded
  event Bonding(address indexed _keeper, address indexed _bonding, uint256 _amount);

  /// @notice Emitted when a keeper or job begins the unbonding process to withdraw the funds
  /// @param _keeperOrJob The keeper or job that began the unbonding process
  /// @param _unbonding The liquidity pair or asset being unbonded
  /// @param _amount The amount being unbonded
  event Unbonding(address indexed _keeperOrJob, address indexed _unbonding, uint256 _amount);

  // Variables

  /// @notice Tracks the total amount of bonded KP3Rs in the contract
  /// @return _totalBonds The total amount of bonded KP3Rs in the contract
  function totalBonds() external view returns (uint256 _totalBonds);

  /// @notice Tracks the total KP3R earnings of a keeper since it started working
  /// @param _keeper The address of the keeper
  /// @return _workCompleted Total KP3R earnings of a keeper since it started working
  function workCompleted(address _keeper) external view returns (uint256 _workCompleted);

  /// @notice Tracks when a keeper was first registered
  /// @param _keeper The address of the keeper
  /// @return timestamp The time at which the keeper was first registered
  function firstSeen(address _keeper) external view returns (uint256 timestamp);

  /// @notice Tracks if a keeper or job has a pending dispute
  /// @param _keeperOrJob The address of the keeper or job
  /// @return _disputed Whether a keeper or job has a pending dispute
  function disputes(address _keeperOrJob) external view returns (bool _disputed);

  /// @notice Tracks how much a keeper has bonded of a certain token
  /// @param _keeper The address of the keeper
  /// @param _bond The address of the token being bonded
  /// @return _bonds Amount of a certain token that a keeper has bonded
  function bonds(address _keeper, address _bond) external view returns (uint256 _bonds);

  /// @notice The current token credits available for a job
  /// @param _job The address of the job
  /// @param _token The address of the token bonded
  /// @return _amount The amount of token credits available for a job
  function jobTokenCredits(address _job, address _token) external view returns (uint256 _amount);

  /// @notice Tracks the amount of assets deposited in pending bonds
  /// @param _keeper The address of the keeper
  /// @param _bonding The address of the token being bonded
  /// @return _pendingBonds Amount of a certain asset a keeper has unbonding
  function pendingBonds(address _keeper, address _bonding) external view returns (uint256 _pendingBonds);

  /// @notice Tracks when a bonding for a keeper can be activated
  /// @param _keeper The address of the keeper
  /// @param _bonding The address of the token being bonded
  /// @return _timestamp Time at which the bonding for a keeper can be activated
  function canActivateAfter(address _keeper, address _bonding) external view returns (uint256 _timestamp);

  /// @notice Tracks when keeper bonds are ready to be withdrawn
  /// @param _keeper The address of the keeper
  /// @param _bonding The address of the token being unbonded
  /// @return _timestamp Time at which the keeper bonds are ready to be withdrawn
  function canWithdrawAfter(address _keeper, address _bonding) external view returns (uint256 _timestamp);

  /// @notice Tracks how much keeper bonds are to be withdrawn
  /// @param _keeper The address of the keeper
  /// @param _bonding The address of the token being unbonded
  /// @return _pendingUnbonds The amount of keeper bonds that are to be withdrawn
  function pendingUnbonds(address _keeper, address _bonding) external view returns (uint256 _pendingUnbonds);

  /// @notice Checks whether the address has ever bonded an asset
  /// @param _keeper The address of the keeper
  /// @return _hasBonded Whether the address has ever bonded an asset
  function hasBonded(address _keeper) external view returns (bool _hasBonded);

  // Methods

  /// @notice Lists all jobs
  /// @return _jobList Array with all the jobs in _jobs
  function jobs() external view returns (address[] memory _jobList);

  /// @notice Lists all keepers
  /// @return _keeperList Array with all the keepers in _keepers
  function keepers() external view returns (address[] memory _keeperList);

  // Errors

  /// @notice Throws when an address is passed as a job, but that address is not a job
  error JobUnavailable();

  /// @notice Throws when an action that requires an undisputed job is applied on a disputed job
  error JobDisputed();
}

/// @title Keep3rParameters contract
/// @notice Handles and sets all the required parameters for Keep3r
interface IKeep3rParameters is IKeep3rAccountance {
  // Events

  /// @notice Emitted when the Keep3rHelper address is changed
  /// @param _keep3rHelper The address of Keep3rHelper's contract
  event Keep3rHelperChange(address _keep3rHelper);

  /// @notice Emitted when the Keep3rV1 address is changed
  /// @param _keep3rV1 The address of Keep3rV1's contract
  event Keep3rV1Change(address _keep3rV1);

  /// @notice Emitted when the Keep3rV1Proxy address is changed
  /// @param _keep3rV1Proxy The address of Keep3rV1Proxy's contract
  event Keep3rV1ProxyChange(address _keep3rV1Proxy);

  /// @notice Emitted when bondTime is changed
  /// @param _bondTime The new bondTime
  event BondTimeChange(uint256 _bondTime);

  /// @notice Emitted when _liquidityMinimum is changed
  /// @param _liquidityMinimum The new _liquidityMinimum
  event LiquidityMinimumChange(uint256 _liquidityMinimum);

  /// @notice Emitted when _unbondTime is changed
  /// @param _unbondTime The new _unbondTime
  event UnbondTimeChange(uint256 _unbondTime);

  /// @notice Emitted when _rewardPeriodTime is changed
  /// @param _rewardPeriodTime The new _rewardPeriodTime
  event RewardPeriodTimeChange(uint256 _rewardPeriodTime);

  /// @notice Emitted when the inflationPeriod is changed
  /// @param _inflationPeriod The new inflationPeriod
  event InflationPeriodChange(uint256 _inflationPeriod);

  /// @notice Emitted when the fee is changed
  /// @param _fee The new token credits fee
  event FeeChange(uint256 _fee);

  // Variables

  /// @notice Address of Keep3rHelper's contract
  /// @return _keep3rHelper The address of Keep3rHelper's contract
  function keep3rHelper() external view returns (address _keep3rHelper);

  /// @notice Address of Keep3rV1's contract
  /// @return _keep3rV1 The address of Keep3rV1's contract
  function keep3rV1() external view returns (address _keep3rV1);

  /// @notice Address of Keep3rV1Proxy's contract
  /// @return _keep3rV1Proxy The address of Keep3rV1Proxy's contract
  function keep3rV1Proxy() external view returns (address _keep3rV1Proxy);

  /// @notice The amount of time required to pass after a keeper has bonded assets for it to be able to activate
  /// @return _days The required bondTime in days
  function bondTime() external view returns (uint256 _days);

  /// @notice The amount of time required to pass before a keeper can unbond what he has bonded
  /// @return _days The required unbondTime in days
  function unbondTime() external view returns (uint256 _days);

  /// @notice The minimum amount of liquidity required to fund a job per liquidity
  /// @return _amount The minimum amount of liquidity in KP3R
  function liquidityMinimum() external view returns (uint256 _amount);

  /// @notice The amount of time between each scheduled credits reward given to a job
  /// @return _days The reward period in days
  function rewardPeriodTime() external view returns (uint256 _days);

  /// @notice The inflation period is the denominator used to regulate the emission of KP3R
  /// @return _period The denominator used to regulate the emission of KP3R
  function inflationPeriod() external view returns (uint256 _period);

  /// @notice The fee to be sent to governor when a user adds liquidity to a job
  /// @return _amount The fee amount to be sent to governor when a user adds liquidity to a job
  function fee() external view returns (uint256 _amount);

  // Errors

  /// @notice Throws if the reward period is less than the minimum reward period time
  error MinRewardPeriod();

  /// @notice Throws if either a job or a keeper is disputed
  error Disputed();

  /// @notice Throws if there are no bonded assets
  error BondsUnexistent();

  /// @notice Throws if the time required to bond an asset has not passed yet
  error BondsLocked();

  /// @notice Throws if there are no bonds to withdraw
  error UnbondsUnexistent();

  /// @notice Throws if the time required to withdraw the bonds has not passed yet
  error UnbondsLocked();

  // Methods

  /// @notice Sets the Keep3rHelper address
  /// @param _keep3rHelper The Keep3rHelper address
  function setKeep3rHelper(address _keep3rHelper) external;

  /// @notice Sets the Keep3rV1 address
  /// @param _keep3rV1 The Keep3rV1 address
  function setKeep3rV1(address _keep3rV1) external;

  /// @notice Sets the Keep3rV1Proxy address
  /// @param _keep3rV1Proxy The Keep3rV1Proxy address
  function setKeep3rV1Proxy(address _keep3rV1Proxy) external;

  /// @notice Sets the bond time required to activate as a keeper
  /// @param _bond The new bond time
  function setBondTime(uint256 _bond) external;

  /// @notice Sets the unbond time required unbond what has been bonded
  /// @param _unbond The new unbond time
  function setUnbondTime(uint256 _unbond) external;

  /// @notice Sets the minimum amount of liquidity required to fund a job
  /// @param _liquidityMinimum The new minimum amount of liquidity
  function setLiquidityMinimum(uint256 _liquidityMinimum) external;

  /// @notice Sets the time required to pass between rewards for jobs
  /// @param _rewardPeriodTime The new amount of time required to pass between rewards
  function setRewardPeriodTime(uint256 _rewardPeriodTime) external;

  /// @notice Sets the new inflation period
  /// @param _inflationPeriod The new inflation period
  function setInflationPeriod(uint256 _inflationPeriod) external;

  /// @notice Sets the new fee
  /// @param _fee The new fee
  function setFee(uint256 _fee) external;
}

// solhint-disable-next-line no-empty-blocks

/// @title Keep3rV2 contract
/// @notice This contract inherits all the functionality of Keep3rV2
interface IKeep3r is IKeep3rJobs, IKeep3rKeepers, IKeep3rParameters {

}

/// @title Pausable interface
interface IPausable is IGovernable {
    // STATE VARIABLES

    /// @return _paused Whether the contract is paused or not
    function paused() external view returns (bool _paused);

    // EVENTS

    /// @notice Emitted when the contract pause is switched
    /// @param _paused Whether the contract is paused or not
    event PausedSet(bool _paused);

    // ERRORS

    /// @notice Thrown when trying to access a paused contract
    error Paused();

    /// @notice Thrown when governor tries to switch paused to the same state as before
    error NoChangeInPaused();

    // FUNCTIONS

    /// @notice Allows governor to pause or unpause the contract
    /// @param _paused Whether the contract should be paused or not
    function setPaused(bool _paused) external;
}

interface IKeep3rJob is IPausable {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Emitted a new keeper is set
   * @param  _keep3r The new keeper address
   */
  event Keep3rSet(IKeep3r _keep3r);

  /**
   * @notice Emitted when setting new keeper requirements
   * @param  _bond The required token to bond by keepers
   * @param  _minBond The minimum amount bound
   * @param  _earnings The earnings of the keeper
   * @param  _age The age of the keeper in the Keep3r network
   */
  event Keep3rRequirementsSet(IERC20 _bond, uint256 _minBond, uint256 _earnings, uint256 _age);

  /*///////////////////////////////////////////////////////////////
                              ERRORS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Thrown when the caller is not a valid keeper in the Keep3r network
   */
  error InvalidKeeper();

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice The address of the Keep3r contract
   * @return _keep3r The address of the token
   */
  function keep3r() external view returns (IKeep3r _keep3r);

  /**
   * @notice The address of the keeper bond token
   * @return _requiredBond The address of the token
   */
  function requiredBond() external view returns (IERC20 _requiredBond);

  /**
   * @notice The minimum amount of bonded token required to bond by the keeper
   * @return _requiredMinBond The required min amount bond
   */
  function requiredMinBond() external view returns (uint256 _requiredMinBond);

  /**
   * @notice The required earnings of the keeper
   * @return _requiredEarnings The required earnings
   */
  function requiredEarnings() external view returns (uint256 _requiredEarnings);

  /**
   * @notice The age of the keeper in the Keep3r network
   * @return _requiredAge The age of the keeper, in seconds
   */
  function requiredAge() external view returns (uint256 _requiredAge);

  /*///////////////////////////////////////////////////////////////
                              LOGIC
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Sets the address of the keeper
   * @param  _keep3r The address of the keeper to be set
   */
  function setKeep3r(IKeep3r _keep3r) external;

  /**
   * @notice Sets the keeper requirements
   * @param  _bond The required token to bond by keepers
   * @param  _minBond The minimum amount bound
   * @param  _earnings The earnings of the keeper
   * @param  _age The age of the keeper in the Keep3r network
   */
  function setKeep3rRequirements(IERC20 _bond, uint256 _minBond, uint256 _earnings, uint256 _age) external;
}

/// @title Governable contract
/// @notice Manages the governor role
abstract contract Governable is IGovernable {
    /// @inheritdoc IGovernable
    address public governor;

    /// @inheritdoc IGovernable
    address public pendingGovernor;

    constructor(address _governor) {
        if (_governor == address(0)) revert ZeroAddress();
        governor = _governor;
    }

    /// @inheritdoc IGovernable
    function setPendingGovernor(address _pendingGovernor) external onlyGovernor {
        _setPendingGovernor(_pendingGovernor);
    }

    /// @inheritdoc IGovernable
    function acceptPendingGovernor() external onlyPendingGovernor {
        _acceptPendingGovernor();
    }

    function _setPendingGovernor(address _pendingGovernor) internal {
        if (_pendingGovernor == address(0)) revert ZeroAddress();
        pendingGovernor = _pendingGovernor;
        emit PendingGovernorSet(governor, _pendingGovernor);
    }

    function _acceptPendingGovernor() internal {
        governor = pendingGovernor;
        delete pendingGovernor;
        emit PendingGovernorAccepted(governor);
    }

    /// @notice Functions with this modifier can only be called by governor
    modifier onlyGovernor() {
        if (msg.sender != governor) revert OnlyGovernor();
        _;
    }

    /// @notice Functions with this modifier can only be called by pendingGovernor
    modifier onlyPendingGovernor() {
        if (msg.sender != pendingGovernor) revert OnlyPendingGovernor();
        _;
    }
}

/// @title Pausable contract
/// @notice Provides pausable functionalities to a given contract
abstract contract Pausable is IPausable, Governable {
    /// @inheritdoc IPausable
    bool public paused;

    /// @inheritdoc IPausable
    function setPaused(bool _paused) external onlyGovernor {
        _setPaused(_paused);
    }

    function _setPaused(bool _paused) internal {
        if (paused == _paused) revert NoChangeInPaused();
        paused = _paused;
        emit PausedSet(_paused);
    }

    /// @notice Provides pausable logic to the function marked with this modifier
    modifier notPaused() {
        if (paused) revert Paused();
        _;
    }
}

abstract contract Keep3rJob is IKeep3rJob, Pausable {
  /// @inheritdoc IKeep3rJob
  IKeep3r public keep3r = IKeep3r(0xeb02addCfD8B773A5FFA6B9d1FE99c566f8c44CC);

  /// @inheritdoc IKeep3rJob
  IERC20 public requiredBond;

  /// @inheritdoc IKeep3rJob
  uint256 public requiredMinBond;

  /// @inheritdoc IKeep3rJob
  uint256 public requiredEarnings;

  /// @inheritdoc IKeep3rJob
  uint256 public requiredAge;

  /// @inheritdoc IKeep3rJob
  function setKeep3r(IKeep3r _keep3r) public onlyGovernor {
    keep3r = _keep3r;
    emit Keep3rSet(_keep3r);
  }

  /// @inheritdoc IKeep3rJob
  function setKeep3rRequirements(IERC20 _bond, uint256 _minBond, uint256 _earnings, uint256 _age) public onlyGovernor {
    requiredBond = _bond;
    requiredMinBond = _minBond;
    requiredEarnings = _earnings;
    requiredAge = _age;
    emit Keep3rRequirementsSet(_bond, _minBond, _earnings, _age);
  }

  /**
   * @notice Checks if the sender is a valid keeper in the Keep3r network
   * @param  _keeper the address to check the keeper status
   */
  modifier upkeep(address _keeper) virtual {
    if (!_isValidKeeper(_keeper)) {
      revert InvalidKeeper();
    }
    _;
    keep3r.worked(_keeper);
  }

  /**
   * @notice Checks if a keeper meets the bonding requirements
   * @param  _keeper the address to check the keeper data
   * @return _isValid true if the keeper meets the bonding requirements
   */
  function _isValidKeeper(address _keeper) internal virtual returns (bool _isValid) {
    return keep3r.isBondedKeeper(_keeper, address(requiredBond), requiredMinBond, requiredEarnings, requiredAge);
  }
}

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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

/// @title Roles interface
interface IRoles is IAccessControl {
    // ERRORS

    /// @notice Thrown when the caller of the function is not an authorized role
    error Unauthorized(address _account, bytes32 _role);
}

interface IGovernorMiniBravo is IRoles {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Emitted when a new proposal is created
   */
  event NewProposal(uint256 _id, uint256 _method, bytes _params);

  /**
   * @notice Emitted when a user votes on a proposal
   */
  event NewVote(address _voter, uint256 _votes, uint256 _method, uint256 _id);

  /**
   * @notice Emitted when a proposal is canceled
   */
  event ProposalCancelled(uint256 _id, uint256 _method, bytes _params);

  /**
   * @notice Emitted when a new proposal is executed
   */
  event ProposalExecuted(uint256 _id, uint256 _method, bytes _params);

  /**
   * @notice Emitted when a voter cancels their vote
   */
  event VoteCancelled(address _voter, uint256 _method, uint256 _id);

  /**
   * @notice Emitted when a proposal is queued
   */
  event ProposalQueued(uint256 _id, uint256 _method, bytes _params);

  /*///////////////////////////////////////////////////////////////
                              ERRORS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Thrown when trying to queue a proposal that was already queued
   */
  error ProposalAlreadyQueued(uint256 _method, uint256 _id);

  /**
   * @notice Thrown when trying to queue a proposal that has not reached quorum
   */
  error QuorumNotReached(uint256 _method, uint256 _id);

  /**
   * @notice Thrown when trying to execute a proposal that is canceled or not on quorum
   */
  error ProposalNotExecutable(uint256 _method, uint256 _id);

  /**
   * @notice Thrown when parameters inputted do not match the saved parameters
   */
  error ParametersMismatch(uint256 _method, bytes _expectedParameters, bytes _actualParameters);

  /**
   * @notice Thrown when the proposal is in a closed state
   */
  error ProposalClosed(uint256 _method, uint256 _id);

  /**
   * @notice Thrown when the voter already voted
   */
  error AlreadyVoted(uint256 _method, uint256 _id);

  /**
   * @notice Thrown when a user tries to cancel their vote with 0 votes
   */
  error NoVotes();

  /*///////////////////////////////////////////////////////////////
                              STRUCTS
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice A proposal for a particular method call
   */
  struct Proposal {
    uint256 id;
    bytes params;
    uint256 forVotes;
    bool open;
    uint256 timelockExpiry;
  }

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the needed quorum for a proposal to pass
   * @return _quorum The needed quorum percentage
   */
  function QUORUM() external view returns (uint256 _quorum);

  /**
   * @notice Returns the voting power of a particular user
   * @param  _user The user whose voting power will be returned
   * @return _balance The voting power of the user
   */
  function votingPower(address _user) external view returns (uint256 _balance);

  /**
   * @notice Returns the total available votes
   * @return _totalVotes The total available votes
   */
  function totalVotes() external view returns (uint256 _totalVotes);

  /**
   * @notice Returns true if the latest proposal for the target method is executable
   * @param  _method The method of the proposal
   * @return _availableToExecute True if the proposal is executable
   */
  function isExecutable(uint256 _method) external view returns (bool _availableToExecute);

  /**
   * @notice Returns the tome lock to execute transactions
   * @return _executionTimelock The time lock to execute transactions
   */
  function executionTimelock() external view returns (uint256 _executionTimelock);

  /*///////////////////////////////////////////////////////////////
                              LOGIC
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Cancels a vote by a user on a particular method
   * @param  _method The method to subtract the votes
   */
  function cancelVote(uint256 _method) external;

  /**
   * @notice Executes a particular proposal if it reaches quorum
   * @param  _method The target method
   * @param  _parameters The proposal parameters
   */
  function execute(uint256 _method, bytes memory _parameters) external;

  /**
   * @notice Returns the latest proposal created for a method
   * @param  _method The target method proposal
   * @return _proposal The latest proposal for the method
   */
  function getLatest(uint256 _method) external view returns (Proposal memory _proposal);

  /**
   * @notice Cancels a proposal
   * @dev    Admin can only call
   * @param  _method The method proposal to cancel
   */
  function cancelProposal(uint256 _method) external;

  /**
   * @notice Queue a particular proposal if it reaches the required quorum
   * @param  _method The method to be called when executed
   * @param  _parameters The parameters for the proposal
   */
  function queue(uint256 _method, bytes memory _parameters) external;

  /**
   * @notice Returns true if proposal reached the required quorum
   * @param  _method The method to be called when executed
   * @return _quorumReached True if the proposal is executable
   */
  function quorumReached(uint256 _method) external view returns (bool _quorumReached);
}

/**
 * @title  LockManager governance storage contract
 * @notice This contract contains the data necessary for governance
 */
interface ILockManagerGovernor is IGovernorMiniBravo {
  /*///////////////////////////////////////////////////////////////
                            ERRORS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Thrown when arithmetic underflow happens
   */
  error LockManager_ArithmeticUnderflow();

  /**
   * @notice Thrown when certain functions are called on a deprecated lock manager
   */
  error LockManager_Deprecated();

  /*///////////////////////////////////////////////////////////////
                            ENUMS
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice The methods that are available for governance
   * @dev    Always add new methods before LatestMethod
   */
  enum Methods {
    Deprecate,
    LatestMethod
  }

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the pool manager factory contract
   * @return _poolManagerFactory The pool manager factory
   */
  function POOL_MANAGER_FACTORY() external view returns (IPoolManagerFactory _poolManagerFactory);

  /**
   * @notice Returns true if the lock manager is deprecated
   * @return _deprecated True if the lock manager is deprecated
   */
  function deprecated() external view returns (bool _deprecated);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Votes yes on the proposal to deprecate the lockManager
   */
  function acceptDeprecate() external;
}

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

/**
 * @title PriceOracle contract
 * @notice This contract allows you to get the price of different assets through WETH pools
 */
interface IPriceOracle {
  /*///////////////////////////////////////////////////////////////
                              ERRORS
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice Thrown when volatility in period is higher than accepted
   */
  error PriceOracle_ExceededVolatility();

  /**
   * @notice Throws if the token is not supported
   */
  error PriceOracleBase_TokenNotSupported();

  /**
   * @notice Throws if the seconds ago order should be reversed
   */
  error PriceOracleCorrections_InvalidSecondsAgosOrder();

  /**
   * @notice Throws if base amount overflows uint128
   */
  error PriceOracleCorrections_BaseAmountOverflow();

  /**
   * @notice Throws when edge ticks are not similar enough
   */
  error PriceOracleCorrections_EdgeTicksTooDifferent();

  /**
   * @notice Throws when observations either before or after the manipulation were also manipulated
   */
  error PriceOracleCorrections_EdgeTicksAverageTooDifferent();

  /**
   * @notice Throws when the difference between the tick before manipulation and the tick at the start of manipulation is not big enough
   */
  error PriceOracleCorrections_TicksBeforeAndAtManipulationStartAreTooSimilar();

  /**
   * @notice Throws when the difference between the tick after manipulation and the tick at the start of manipulation is not big enough
   */
  error PriceOracleCorrections_TicksAfterAndAtManipulationStartAreTooSimilar();

  /**
   * @notice Throws when the difference between the tick after manipulation and the tick at the end of manipulation is not big enough
   */
  error PriceOracleCorrections_TicksAfterAndAtManipulationEndAreTooSimilar();

  /**
   * @notice Throws when trying to apply the correction to a pool we didn't deploy
   */
  error PriceOracleCorrections_PoolNotSupported();

  /**
   * @notice Throws when trying to correct a manipulation that was already corrected
   */
  error PriceOracleCorrections_ManipulationAlreadyProcessed();

  /**
   * @notice Throws when the observation after the manipulation observation has not yet happened
   */
  error PriceOracleCorrections_AfterObservationIsNotNewer();

  /**
   * @notice Throws when there are no corrections for removal
   */
  error PriceOracleCorrections_NoCorrectionsToRemove();

  /**
   * @notice Throws when an invalid period was supplied
   */
  error PriceOracleCorrections_PeriodTooShort();

  /**
   * @notice Throws when the supplied period exceeds the maximum correction age
   * @dev    The danger of using a long period lies in the fact that obsolete corrections will eventually be removed.
   * Thus the oracle would return un-corrected, possibly manipulated data.
   */
  error PriceOracleCorrections_PeriodTooLong();

  /**
   * @notice Throws when it's not possible to calculate the after observation, nor force it with burn1, just wait 1 block and retry
   */
  error PriceOracleCorrections_AfterObservationCannotBeCalculatedOnSameBlock();

  /*///////////////////////////////////////////////////////////////
                              STRUCTS
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice A quote saved in a particular timestamp to use as cache
   * @param quote The quote given from tokenA to tokenB
   * @param timestamp The timestamp for when the cache was saved
   */
  struct QuoteCache {
    uint256 quote;
    uint256 timestamp;
  }

  /**
   * @notice The correction information
   * @param amount The difference between the tick value before and after the correction
   * @param beforeTimestamp
   * @param afterTimestamp
   */
  struct Correction {
    int56 amount;
    uint32 beforeTimestamp;
    uint32 afterTimestamp;
  }
  /**
   * @notice The observation information, copied from the Uniswap V3 oracle library
   * @param blockTimestamp The block timestamp of the observation
   * @param tickCumulative The tick accumulator, i.e. tick * time elapsed since the pool was first initialized
   * @param secondsPerLiquidityCumulativeX128 The seconds per liquidity, i.e. seconds elapsed / max(1, liquidity) since the pool was first initialized
   * @param initialized Whether or not the observation is initialized
   */

  struct Observation {
    uint32 blockTimestamp;
    int56 tickCumulative;
    uint160 secondsPerLiquidityCumulativeX128;
    bool initialized;
  }

  /**
   * @notice Keeps the list of the applied corrections
   * @param manipulated The array of the manipulated observations
   * @param beforeManipulation The observation that was right before the manipulation
   * @param afterManipulation The observation that was right after the manipulation
   * @param postAfterManipulation The observation succeeding the one after the manipulation
   */
  struct CorrectionObservations {
    Observation[] manipulated;
    Observation beforeManipulation;
    Observation afterManipulation;
    Observation postAfterManipulation;
  }

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice Returns the correction delay
   * @dev    The delay should be big enough for the attack to not be arbitraged and hence detected by the contract
   * @return _correctionDelay the correction delay
   */
  function CORRECTION_DELAY() external view returns (uint32 _correctionDelay);

  /**
   * @notice Returns the minumum correction period
   * @return _minCorrectionPeriod the minumum correction period
   */
  function MIN_CORRECTION_PERIOD() external view returns (uint32 _minCorrectionPeriod);

  /**
   * @notice Returns the maximum correction age
   * @return _maxCorrectionAge the maximum correction age
   */
  function MAX_CORRECTION_AGE() external view returns (uint32 _maxCorrectionAge);

  /**
   * @notice Returns the upper tick difference for the 10% price change
   * @return _upperTickDiff10 the upper tick difference for the 10% price change
   */
  function UPPER_TICK_DIFF_10() external view returns (int24 _upperTickDiff10);

  /**
   * @notice Returns the lower tick difference for the 10% price change
   * @return _lowerTickDiff10 the lower tick difference for the 10% price change
   */
  function LOWER_TICK_DIFF_10() external view returns (int24 _lowerTickDiff10);

  /**
   * @notice Returns the upper tick difference for the 20% price change
   * @return _upperTickDiff20 the upper tick difference for the 20% price change
   */
  function UPPER_TICK_DIFF_20() external view returns (int24 _upperTickDiff20);

  /**
   * @notice Returns the lower tick difference for the 20% price change
   * @return _lowerTickDiff20 the lower tick difference for the 20% price change
   */
  function LOWER_TICK_DIFF_20() external view returns (int24 _lowerTickDiff20);

  /**
   * @notice Returns the upper tick difference for the 23.5% price change
   * @return _upperTickDiff23Dot5 the upper tick difference for the 23.5% price change
   */
  function UPPER_TICK_DIFF_23_5() external view returns (int24 _upperTickDiff23Dot5);

  /**
   * @notice Returns the lower tick difference for the 23.5% price change
   * @return _lowerTickDiff23Dot5 the lower tick difference for the 23.5% price change
   */
  function LOWER_TICK_DIFF_23_5() external view returns (int24 _lowerTickDiff23Dot5);

  /**
   * @notice Returns the upper tick difference for the 30% price change
   * @return _upperTickDiff30 the upper tick difference for the 30% price change
   */
  function UPPER_TICK_DIFF_30() external view returns (int24 _upperTickDiff30);

  /**
   * @notice Returns the lower tick difference for the 30% price change
   * @return _lowerTickDiff30 the lower tick difference for the 30% price change
   */
  function LOWER_TICK_DIFF_30() external view returns (int24 _lowerTickDiff30);

  /**
   * @notice Returns the UniswapV3 factory contract
   * @return _uniswapV3Factory The UniswapV3 factory contract
   */
  function UNISWAP_V3_FACTORY() external view returns (IUniswapV3Factory _uniswapV3Factory);

  /**
   * @notice Returns the UniswapV3 pool bytecode hash
   * @return _poolBytecodeHash The UniswapV3 pool bytecode hash
   */
  function POOL_BYTECODE_HASH() external view returns (bytes32 _poolBytecodeHash);

  /**
   * @notice Returns the WETH token
   * @return _weth The WETH token
   */
  function WETH() external view returns (IERC20 _weth);

  /**
   * @notice Returns the pool manager factory
   * @return _poolManagerFactory The pool manager factory
   */
  function POOL_MANAGER_FACTORY() external view returns (IPoolManagerFactory _poolManagerFactory);

  /*///////////////////////////////////////////////////////////////
                              LOGIC
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice Returns true if a pair is supported on the oracle
   * @param  _tokenA TokenA for the pair
   * @param  _tokenB TokenB for the pair
   * @return _isSupported True if the pair is supported on the oracle
   */
  function isPairSupported(IERC20 _tokenA, IERC20 _tokenB) external view returns (bool _isSupported);

  /**
   * @notice Returns the price of a given amount of tokenA quoted in tokenB using the cache if available
   * @param  _baseAmount The amount of tokenA to quote
   * @param  _tokenA Token to quote in tokenB
   * @param  _tokenB The quote token
   * @param  _period The period to quote
   * @param  _maxCacheAge Ignore the cached quote if it's older than the max age, in seconds
   * @return _quoteAmount The quoted amount of tokenA in tokenB
   */
  function quoteCache(uint256 _baseAmount, IERC20 _tokenA, IERC20 _tokenB, uint32 _period, uint24 _maxCacheAge)
    external
    returns (uint256 _quoteAmount);

  /**
   * @notice Applies a price correction to the pool
   * @param _pool The Uniswap V3 pool address
   * @param _manipulatedIndex The index of the observation that will be corrected
   * @param _period How many observations the manipulation affected
   */
  function applyCorrection(IUniswapV3Pool _pool, uint16 _manipulatedIndex, uint16 _period) external;

  /**
   * @notice Removes old corrections to potentially increase gas efficiency on quote)
   * @param _pool The Uniswap V3 pool address
   */
  function removeOldCorrections(IUniswapV3Pool _pool) external;

  /**
   * @notice Returns the number of the corrections for a pool
   * @param _pool The Uniswap V3 pool address
   * @return _correctionsCount The number of the corrections for a pool
   */
  function poolCorrectionsCount(IUniswapV3Pool _pool) external view returns (uint256 _correctionsCount);

  /**
   * @notice Returns the timestamp of the oldest correction for a given pool
   * @dev Returns 0 if there is no corrections for the pool
   * @param _pool The Uniswap V3 pool address
   * @return _timestamp The timestamp of the oldest correction for a given pool
   */
  function getOldestCorrectionTimestamp(IUniswapV3Pool _pool) external view returns (uint256 _timestamp);

  /**
   * @notice Lists all corrections for a pool
   * @param _pool The Uniswap V3 pool address
   * @param _startFrom Index from where to start the pagination
   * @param _amount Maximum amount of corrections to retrieve
   * @return _poolCorrections Paginated corrections of the pool
   */
  function listPoolCorrections(IUniswapV3Pool _pool, uint256 _startFrom, uint256 _amount)
    external
    view
    returns (Correction[] memory _poolCorrections);

  /**
   * @notice Provides the quote taking into account any corrections happened during the provided period
   * @param _baseAmount The amount of base token
   * @param _baseToken The base token address
   * @param _quoteToken The quote token address
   * @param _period The TWAP period
   * @return _quoteAmount The quote amount
   */
  function quote(uint256 _baseAmount, IERC20 _baseToken, IERC20 _quoteToken, uint32 _period)
    external
    view
    returns (uint256 _quoteAmount);

  /**
   * @notice Return true if the pool was manipulated
   * @param _pool The Uniswap V3 pool address
   * @return _manipulated Whether the pool is manipulated or not
   */
  function isManipulated(IUniswapV3Pool _pool) external view returns (bool _manipulated);

  /**
   * @notice Return true if the pool has been manipulated
   * @param _pool The Uniswap V3 pool address
   * @param _lowerTickDifference The maximum difference between the lower ticks before and after the correction
   * @param _upperTickDifference The maximum difference between the upper ticks before and after the correction
   * @param _correctionPeriod The correction period
   * @return _manipulated Whether the pool is manipulated or not
   */
  function isManipulated(
    IUniswapV3Pool _pool,
    int24 _lowerTickDifference,
    int24 _upperTickDifference,
    uint32 _correctionPeriod
  )
    external
    view
    returns (bool _manipulated);

  /**
   * @notice Returns the TWAP for the given period taking into account any corrections happened during the period
   * @param _pool The Uniswap V3 pool address
   * @param _period The TWAP period, in seconds
   * @return _arithmeticMeanTick The TWAP
   */
  function getPoolTickWithCorrections(IUniswapV3Pool _pool, uint32 _period)
    external
    view
    returns (int24 _arithmeticMeanTick);
}

interface IStrategy {
  /*///////////////////////////////////////////////////////////////
                              ERRORS
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice Thrown when the price oracle detects a manipulation
   */
  error Strategy_PoolManipulated();

  /**
   * @notice Thrown when minting a position requires more WETH than available in the lock manager
   */
  error Strategy_NotEnoughWeth();

  /**
   * @notice Thrown when the position to burn is too close to the current tick
   */
  error Strategy_NotFarEnoughToLeft();

  /**
   * @notice Thrown when the position to burn is too close to the current tick
   */
  error Strategy_NotFarEnoughToRight();

  /*///////////////////////////////////////////////////////////////
                              STRUCTS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Lock manager variables needed for the strategy
   * @param poolManager The address of the pool manager
   * @param pool The address of the UniswapV3 pool
   * @param availableWeth The total amount of WETH available for minting into the pool
   * @param isWethToken0 If WETH is token 0 in the pool
   * @param tickSpacing The tick spacing in the pool
   */
  struct LockManagerState {
    IPoolManager poolManager;
    IUniswapV3Pool pool;
    uint256 availableWeth;
    bool isWethToken0;
    int24 tickSpacing;
  }

  /**
   * @notice UniswapV3 pool position
   * @param  lowerTick The lower tick of the position
   * @param  upperTick The upper tick of the position
   */
  struct Position {
    int24 lowerTick;
    int24 upperTick;
  }

  /**
   * @notice UniswapV3 pool position with the amount of liquidity
   * @param  lowerTick The lower tick of the position
   * @param  upperTick The upper tick of the position
   * @param  liquidity The amount of liquidity in the position
   */
  struct LiquidityPosition {
    int24 lowerTick;
    int24 upperTick;
    uint128 liquidity;
  }

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice The minimum amount of WETH that can be minted into a new position
   * @dev Remember safe deployment for min width is 1 ETH these amounts are already considering the 1/2 minting
   * @return _minWethToMint The minimum amount of WETH that can be minted into a new position
   */
  function MIN_WETH_TO_MINT() external view returns (uint256 _minWethToMint);

  /**
   * @notice The maximum amount of WETH that can be minted into a new position
   * @return _maxWethToMint The maximum amount of WETH that can be minted into a new position
   */
  function MAX_WETH_TO_MINT() external view returns (uint256 _maxWethToMint);

  /**
   * @notice 50% of idle WETH per mint is used
   * @return _percentWethToMint What percentage of idle WETH to use for minting
   */
  function PERCENT_WETH_TO_MINT() external view returns (uint256 _percentWethToMint);

  /**
   * @notice How far to the right from the current tick a position should be in order to be burned
   * @return _lowerBurnDiff The tick difference
   */
  function LOWER_BURN_DIFF() external view returns (int24 _lowerBurnDiff);

  /**
   * @notice How far to the left from the current tick a position should be in order to be burned
   * @return _upperBurnDiff The tick difference
   */
  function UPPER_BURN_DIFF() external view returns (int24 _upperBurnDiff);

  /**
   * @notice The top of the safe range for volatility
   * @return _volatilitySafeRangeMin
   */
  function VOLATILITY_SAFE_RANGE_MIN() external view returns (uint256 _volatilitySafeRangeMin);

  /**
   * @notice The bottom of the safe range for volatility
   * @return _volatilitySafeRangeMax
   */
  function VOLATILITY_SAFE_RANGE_MAX() external view returns (uint256 _volatilitySafeRangeMax);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice Returns the next position to mint
   * @return _positionToMint The position
   */
  function getPositionToMint(IStrategy.LockManagerState calldata _lockManagerState)
    external
    view
    returns (IStrategy.LiquidityPosition memory _positionToMint);

  /**
   * @notice Returns the next position to burn
   * @param  _position The position to burn, without liquidity
   * @param  _positionLiquidity The liquidity in the position
   * @return _positionToBurn The position to burn, with liquidity
   */
  function getPositionToBurn(
    IStrategy.Position calldata _position,
    uint128 _positionLiquidity,
    IStrategy.LockManagerState calldata _lockManagerState
  )
    external
    view
    returns (IStrategy.LiquidityPosition memory _positionToBurn);
}

/**
 * @title LockManager contract
 * @notice This contract allows users to lock WETH and claim fees from the concentrated positions.
 */
interface ILockManager is IERC20, ILockManagerGovernor {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Emitted when a user locks WETH in a pool
   * @param  _wethAmount The amount of WETH tokens to lock
   */
  event Locked(uint256 _wethAmount);

  /**
   * @notice Emitted when a user claims rewards
   * @param  _user The address of the user that claimed the rewards
   * @param  _wethAmount The amount of WETH tokens to claim
   * @param  _tokenAmount The amount of non-WETH tokens to claim
   */
  event ClaimedRewards(address _user, address _to, uint256 _wethAmount, uint256 _tokenAmount);

  /**
   * @notice Emitted when a fee manager adds WETH rewards to a given pool manager
   * @param  _wethAmount The amount of WETH added
   * @param  _tokenAmount The amount of WETH added
   */
  event RewardsAdded(uint256 _wethAmount, uint256 _tokenAmount);

  /**
   * @notice Emitted when we finish the fee-collecting process
   * @param  _wethFees Total fees from concentrated positions in WETH
   * @param  _tokenFees Total fees from concentrated positions in non-WETH token
   */
  event FeesCollected(uint256 _wethFees, uint256 _tokenFees);

  /**
   * @notice Emitted when an amount of locked WETH is burned
   * @param _wethAmount The amount of burned locked WETH
   */
  event Burned(uint256 _wethAmount);

  /**
   * @notice Emitted when withdrawals are enabled
   */
  event WithdrawalsEnabled();

  /**
   * @notice Emitted when a position was minted
   * @param _position The position
   * @param _amount0 The amount of token0 supplied for the position
   * @param _amount1 The amount of token1 supplied for the position
   */
  event PositionMinted(IStrategy.LiquidityPosition _position, uint256 _amount0, uint256 _amount1);

  /**
   * @notice Emitted when a position was burned
   * @param _position The position
   * @param _amount0 The amount of token0 released from the position
   * @param _amount1 The amount of token1 released from the position
   */
  event PositionBurned(IStrategy.LiquidityPosition _position, uint256 _amount0, uint256 _amount1);

  /*///////////////////////////////////////////////////////////////
                              ERRORS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Thrown when the user doesn't have rewards to claim
   */
  error LockManager_NoRewardsToClaim();

  /**
   * @notice Thrown when the amount is zero
   */
  error LockManager_ZeroAmount();

  /**
   * @notice Thrown when the provided address is zero
   */
  error LockManager_ZeroAddress();

  /**
   * @notice Thrown when the lock manager has no locked WETH
   */
  error LockManager_NoLockedWeth();

  /**
   * @notice Thrown when the UniswapV3 callback caller is not a valid pool
   */
  error LockManager_OnlyPool();

  /**
   * @notice Thrown when the amount of WETH minted by this lock manager exceeds the WETH supply
   * @param  _totalSupply The locked WETH supply
   * @param  _concentratedWeth The amount of WETH minted by this lock manager
   */
  error LockManager_OverLimitMint(uint256 _totalSupply, uint256 _concentratedWeth);

  /**
   * @notice Thrown when enabling withdraws without the lockManager being deprecated
   */
  error LockManager_DeprecationRequired();

  /**
   * @notice Thrown when trying to withdraw with the contract not marked as withdrawable
   */
  error LockManager_WithdrawalsNotEnabled();

  /**
   * @notice Thrown when trying to withdraw with zero lockedWeth
   */
  error LockManager_ZeroBalance();

  /**
   * @notice Thrown when the caller is not the lock manager
   */
  error LockManager_NotLockManager();

  /**
   * @notice Thrown when trying to unwind, and there are no positions left
   */
  error LockManager_NoPositions();

  /**
   * @notice Thrown when the price oracle detects a manipulation
   */
  error LockManager_PoolManipulated();

  /**
   * @notice Thrown when trying to transfer to the same address
   */
  error LockManager_InvalidAddress();

  /**
   * @notice Thrown when transfer or transferFrom fails
   */
  error LockManager_TransferFailed();

  /*///////////////////////////////////////////////////////////////
                              STRUCTS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Pool status for internal accountancy
   * @param  wethPerLockedWeth The value of the reward per WETH locked
   * @param  tokenPerLockedWeth The value of the reward per Token locked
   */
  struct PoolRewards {
    uint256 wethPerLockedWeth;
    uint256 tokenPerLockedWeth;
  }

  /**
   * @notice The amounts of paid and available rewards per user
   * @param  wethPaid The WETH amount already claimed
   * @param  tokenPaid The non-WETH token amount already claimed
   * @param  wethAvailable The available WETH amount
   * @param  tokenAvailable The available non-WETH token amount
   */
  struct UserRewards {
    uint256 wethPaid;
    uint256 tokenPaid;
    uint256 wethAvailable;
    uint256 tokenAvailable;
  }

  /**
   * @notice Withdrawal data for balance withdrawals for lockers
   * @param  withdrawalsEnabled True if all concentrated positions were burned and the balance can be withdrawn
   * @param  totalWeth The total WETH to distribute between lockers
   * @param  totalToken The total token to distribute between lockers
   */
  struct WithdrawalData {
    bool withdrawalsEnabled;
    uint256 totalWeth;
    uint256 totalToken;
  }

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the WETH contract
   * @return _weth The WETH token
   */
  function WETH() external view returns (IERC20 _weth);

  /**
   * @notice Returns the status of a corresponding pool manager
   * @return _wethPerLockedWeth The value of the reward per WETH locked
   * @return _tokenPerLockedWeth The value of the reward per Token locked
   */
  function poolRewards() external view returns (uint256 _wethPerLockedWeth, uint256 _tokenPerLockedWeth);

  /**
   * @notice Returns the underlying uni v3 pool contract
   * @return _pool The underlying uni v3 pool contract
   */
  function POOL() external view returns (IUniswapV3Pool _pool);

  /**
   * @notice Returns the pool manager contract
   * @return _poolManager The pool manager
   */
  function POOL_MANAGER() external view returns (IPoolManager _poolManager);

  /**
   * @notice Returns true if WETH token is the token0
   * @return _isWethToken0 If WETH is token0
   */
  function IS_WETH_TOKEN0() external view returns (bool _isWethToken0);

  /**
   * @notice  Returns the pending to the corresponding account
   * @param   _account The address of the account
   * @return  _wethPaid The amount of the claimed rewards in WETH
   * @return  _tokenPaid The amount of the claimed rewards in non-WETH token
   * @return  _wethAvailable The amount of the pending rewards in WETH
   * @return  _tokenAvailable The amount of the pending rewards in non-WETH token
   */
  function userRewards(address _account)
    external
    view
    returns (uint256 _wethPaid, uint256 _tokenPaid, uint256 _wethAvailable, uint256 _tokenAvailable);

  /**
   * @notice Returns the withdrawal data
   * @return _withdrawalsEnabled True if lock manager is deprecated and all positions have been unwound
   * @return _totalWeth The total amount of WETH to distribute between lockers
   * @return _totalToken the total amount of non-WETH token to distribute between lockers
   */
  function withdrawalData() external view returns (bool _withdrawalsEnabled, uint256 _totalWeth, uint256 _totalToken);

  /**
   * @notice Returns the strategy
   * @return _strategy The strategy
   */
  function STRATEGY() external view returns (IStrategy _strategy);

  /**
   * @notice Returns the fee of the pool manager
   * @return _fee The fee
   */
  function FEE() external view returns (uint24 _fee);

  /**
   * @notice Returns the non-WETH token contract of the underlying pool
   * @return _token The non-WETH token contract of the underlying pool
   */
  function TOKEN() external view returns (IERC20 _token);

  /**
   * @notice Returns the total amount of WETH minted by this lock manager
   * @return _concentratedWeth The total amount of WETH in use by this lock manager
   */
  function concentratedWeth() external view returns (uint256 _concentratedWeth);

  /*///////////////////////////////////////////////////////////////
                              LOGIC
  //////////////////////////////////////////////////////////////*/

  // ********* REWARDS ********* //
  /**
   * @notice  Get the total WETH claimable for a given account and pool manager
   * @dev     This value is calculated by adding the balance and unclaimed rewards.
   * @param   _account The address of the account
   * @return  _wethClaimable The amount of WETH claimable
   * @return  _tokenClaimable The amount of Token claimable
   */
  function claimable(address _account) external view returns (uint256 _wethClaimable, uint256 _tokenClaimable);

  /**
   * @notice  Lock the amount of WETH token provided by the caller
   * @dev     Same amount of WETH lock token will be provided
   * @param   _wethAmount The amount of WETH tokens that the caller wants to provide
   */
  function lock(uint256 _wethAmount) external;

  /**
   * @notice Returns the rewards generated by a caller in a specific pool manager
   * @param  _to The recipient of these rewards
   * @return _rewardWeth The amount of rewards in WETH that have been claimed
   * @return _rewardToken The amount of rewards in non-WETH tokens that have been claimed
   */
  function claimRewards(address _to) external returns (uint256 _rewardWeth, uint256 _rewardToken);

  /**
   * @notice Adds a donation as a reward to be distributed among the lockers.
   * @param  _wethAmount The amount of the donation in WETH sent to the lock manager
   * @param  _tokenAmount The amount of the donation in non-WETH tokens sent to the lock manager
   */

  function addRewards(uint256 _wethAmount, uint256 _tokenAmount) external;

  // ********* CONCENTRATED POSITIONS ********* //

  /**
   * @notice Returns the number of concentrated positions in this lock manager
   * @return _positionsCount The number of concentrated positions
   */
  function getPositionsCount() external view returns (uint256 _positionsCount);

  /**
   * @notice Get the the position that has to be minted
   * @return _positionToMint The position that has to be minted
   */
  function getPositionToMint() external returns (IStrategy.LiquidityPosition memory _positionToMint);

  /**
   * @notice Get the position to burn
   * @param  _position The position to burn
   * @return _positionToBurn The position that has to be burned
   */
  function getPositionToBurn(IStrategy.Position calldata _position)
    external
    returns (IStrategy.LiquidityPosition memory _positionToBurn);

  /**
   * @notice Creates a concentrated WETH position
   */
  function mintPosition() external;

  /**
   * @notice Burns a position that fell out of the active range
   * @param  _position The position to be burned
   */
  function burnPosition(IStrategy.Position calldata _position) external;

  /**
   * @notice Callback that is called when calling the mint method in a UniswapV3 pool
   * @dev    It is only called in the creation of the full range and when positions need to be updated
   * @param  _amount0Owed The amount of token0
   * @param  _amount1Owed The amount of token1
   * @param  _data not used
   */
  function uniswapV3MintCallback(uint256 _amount0Owed, uint256 _amount1Owed, bytes calldata _data) external;

  /**
   * @notice Returns an array of positions
   * @param  _startFrom Index from where to start the pagination
   * @param  _amount Maximum amount of positions to retrieve
   * @return _positions The positions
   */
  function positionsList(uint256 _startFrom, uint256 _amount)
    external
    view
    returns (IStrategy.LiquidityPosition[] memory _positions);

  /**
   * @notice Claims the fees from the UniswapV3 pool and stores them in the FeeManager
   * @dev    Collects all available fees by passing type(uint128).max as requested amounts
   * @param _positions The positions to claim the fees from
   */
  function collectFees(IStrategy.Position[] calldata _positions) external;

  /**
   * @notice Burn the amount of lockedWeth provided by the caller
   * @param  _lockedWethAmount The amount of lockedWeth to be burned
   */
  function burn(uint256 _lockedWethAmount) external;

  /**
   * @notice Withdraws the corresponding part of WETH and non-WETH token depending on the locked WETH balance of the user and burns the lockTokens
   * @dev    Only available if lockManager is deprecated and withdraws are enabled
   * @param  _receiver The receiver of the tokens
   */
  function withdraw(address _receiver) external;

  /**
   * @notice Unwinds a number of positions
   * @dev    lockManager must be deprecated
   * @param  _positions The number of positions to unwind from last to first
   */
  function unwind(uint256 _positions) external;
}

interface ILockManagerFactory {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice Emitted when the lock manager is created
   * @param  _lockManager The lock manager that was created
   */
  event LockManagerCreated(ILockManager _lockManager);

  /*///////////////////////////////////////////////////////////////
                              LOGIC
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice Creates a lock manager
   * @param  _lockManagerParams The parameters to initialize the lock manager
   * @return _lockManager The created lock manager
   */
  function createLockManager(IPoolManager.LockManagerParams calldata _lockManagerParams)
    external
    returns (ILockManager _lockManager);
}

/**
 * @notice Deployer of pool managers
 * @dev    This contract is needed to reduce the size of the pool manager factory contract
 */
interface IPoolManagerDeployer {
  /*///////////////////////////////////////////////////////////////
                              ERRORS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Thrown when someone other than the pool manager factory tries to call the method
   */
  error PoolManagerDeployer_OnlyPoolManagerFactory();

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the pool manager factory
   * @return _poolManagerFactory The pool manager factory
   */
  function POOL_MANAGER_FACTORY() external view returns (IPoolManagerFactory _poolManagerFactory);

  /*///////////////////////////////////////////////////////////////
                              LOGIC
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Deploys a new pool manager for a given UniswapV3 pool
   * @param  _pool The UniswapV3 pool
   * @return _poolManager The newly deployed pool manager
   */
  function deployPoolManager(IUniswapV3Pool _pool) external returns (IPoolManager _poolManager);
}

/**
 * @notice Creates a new pool manager associated with a defined UniswapV3 pool
 * @dev    The UniswapV3 pool needs to be a pool deployed by the current UniswapV3 factory.
 * The pool might or might not already exist (the correct deterministic address is checked
 * but not called).
 */
interface IPoolManagerFactory is IRoles {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Emitted when the lock manager factory changes
   * @param  _lockManagerFactory The new lock manager Factory
   */
  event LockManagerFactoryChanged(ILockManagerFactory _lockManagerFactory);

  /**
   * @notice Emitted when the strategy changes
   * @param  _strategy The new strategy
   */
  event StrategyChanged(IStrategy _strategy);

  /**
   * @notice Emitted when a new owner is nominated
   * @param  _owner The nominated owner
   */
  event OwnerNominated(address _owner);

  /**
   * @notice Emitted when the owner changes
   * @param  _owner The new owner
   */
  event OwnerChanged(address _owner);

  /**
   * @notice Emitted when the migrator address changes
   * @param  _poolManagerMigrator The new migrator address
   */
  event PoolManagerMigratorChanged(address _poolManagerMigrator);

  /**
   * @notice Emitted when the fee manager address changes
   * @param  _feeManager The new fee manager address
   */
  event FeeManagerChanged(IFeeManager _feeManager);

  /**
   * @notice Emitted when the price oracle address changes
   * @param  _priceOracle The new price oracle address
   */
  event PriceOracleChanged(IPriceOracle _priceOracle);

  /**
   * @notice Emitted when the fee collector job changes
   * @param  _feeCollectorJob The new fee collector job
   */
  event FeeCollectorJobChanged(IFeeCollectorJob _feeCollectorJob);

  /**
   * @notice Emitted when the pool manager is created
   * @param  _poolManager The new pool manager
   */
  event PoolManagerCreated(IPoolManager _poolManager);

  /**
   * @notice Emitted when the min ETH amount changes
   * @param  _minEthAmount The new min ETH amount
   */
  event MinEthAmountChanged(uint256 _minEthAmount);

  /*///////////////////////////////////////////////////////////////
                              ERRORS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Thrown when changing the default fee to a nonexistent pool
   */
  error PoolManagerFactory_InvalidPool();

  /**
   * @notice Thrown when trying to create a pool manager that was already created
   */
  error PoolManagerFactory_ExistingPoolManager();

  /**
   * @notice Thrown when zero address was supplied to a function
   */
  error PoolManagerFactory_ZeroAddress();

  /**
   * @notice Thrown when an invalid account tries to accept ownership of the contract
   */
  error PoolManagerFactory_InvalidPendingOwner();

  /**
   * @notice Thrown when creating a PoolManager with less than the min ETH amount
   */
  error PoolManagerFactory_SmallAmount();

  /**
   * @notice Thrown when trying to set min ETH amount to 0
   */
  error PoolManagerFactory_InvalidMinEthAmount();

  /**
   * @notice Used to pass constructor arguments when deploying new pool (will call msg.sender.constructorArguments()),
   * to avoid having to retrieve them when checking if the sender is a valid pool manager address
   */
  struct PoolManagerParams {
    IUniswapV3Factory uniswapV3Factory;
    bytes32 poolBytecodeHash;
    IERC20 weth;
    IERC20 otherToken;
    IFeeManager feeManager;
    IPriceOracle priceOracle;
    address owner;
    uint24 fee;
    uint160 sqrtPriceX96;
  }

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the UniswapV3 factory contract
   * @return _uniswapV3Factory The UniswapV3 factory contract
   */
  function UNISWAP_V3_FACTORY() external view returns (IUniswapV3Factory _uniswapV3Factory);

  /**
   * @notice Returns the UniswapV3 pool bytecode hash
   * @return _poolBytecodeHash The UniswapV3 pool bytecode hash
   */
  function POOL_BYTECODE_HASH() external view returns (bytes32 _poolBytecodeHash);

  /**
   * @notice The role that allows changing the Strategy
   * @return _strategySetterRole The role that allows changing the Strategy
   */
  function STRATEGY_SETTER_ROLE() external view returns (bytes32 _strategySetterRole);

  /**
   * @notice The role that allows changing the lock manager factory
   * @return _factorySetterRole The role that allows changing the lock manager factory
   */
  function FACTORY_SETTER_ROLE() external view returns (bytes32 _factorySetterRole);

  /**
   * @notice The role that allows changing the pool manager migrator address
   * @return _migratorSetterRole The role that allows changing the pool manager migrator address
   */
  function MIGRATOR_SETTER_ROLE() external view returns (bytes32 _migratorSetterRole);

  /**
   * @notice The role that allows changing the price oracle address
   * @return _priceOracleSetterRole The role that allows changing the price oracle address
   */
  function PRICE_ORACLE_SETTER_ROLE() external view returns (bytes32 _priceOracleSetterRole);

  /**
   * @notice The role that allows changing the fee manager address
   * @return _feeManagerSetterRole The role that allows changing the fee manager address
   */
  function FEE_MANAGER_SETTER_ROLE() external view returns (bytes32 _feeManagerSetterRole);

  /**
   * @notice The role that allows changing the fee collector job
   * @return _feeCollectorSetterRole The role that allows changing the fee collector job
   */
  function FEE_COLLECTOR_SETTER_ROLE() external view returns (bytes32 _feeCollectorSetterRole);

  /**
   * @notice The role that allows changing the min ETH amount to create a PoolManager
   * @return _minEthAmountSetterRole The role that allows changing the min ETH amount to create a PoolManager
   */
  function MIN_ETH_AMOUNT_SETTER_ROLE() external view returns (bytes32 _minEthAmountSetterRole);

  /**
   * @notice Returns the WETH token contract
   * @return _weth The WETH token contract
   */
  function WETH() external view returns (IERC20 _weth);

  /**
   * @notice Returns the strategy registry
   * @return _strategy The strategy registry
   */
  function strategy() external view returns (IStrategy _strategy);

  /**
   * @notice Returns the fee manager
   * @return _feeManager The fee manager
   */
  function feeManager() external view returns (IFeeManager _feeManager);

  /**
   * @notice Returns the total number of pool managers that this factory has deployed
   * @return _childrenCount The total amount of pool managers created by this factory
   */
  function childrenCount() external view returns (uint256 _childrenCount);

  /**
   * @notice Returns the fee collector job
   * @return _feeCollectorJob The fee collector job
   */
  function feeCollectorJob() external view returns (IFeeCollectorJob _feeCollectorJob);

  /**
   * @notice Returns the lock manager factory
   * @return _lockManagerFactory The lock manager factory
   */
  function lockManagerFactory() external view returns (ILockManagerFactory _lockManagerFactory);

  /**
   * @notice Returns the pool manager deployer
   * @return _poolManagerDeployer The pool manager deployer
   */
  function POOL_MANAGER_DEPLOYER() external view returns (IPoolManagerDeployer _poolManagerDeployer);

  /**
   * @notice Returns the pool manager migrator contract
   * @return _poolManagerMigrator The pool manager migrator contract
   */
  function poolManagerMigrator() external view returns (address _poolManagerMigrator);

  /**
   * @notice Returns the price oracle
   * @return _priceOracle The price oracle
   */
  function priceOracle() external view returns (IPriceOracle _priceOracle);

  /**
   * @notice Returns the minimum amount of ETH to create a PoolManager
   * @return _minEthAmount The minimum amount of ETH
   */
  function minEthAmount() external view returns (uint256 _minEthAmount);

  /**
   * @notice Getter for a pool manager params public variable used to initialize a new pool manager factory
   * @dev    This method is called by the pool manager constructor (no parameters are passed not to influence the
   * deterministic address)
   * @return _uniswapV3Factory Address of the UniswapV3 factory
   * @return _poolBytecodeHash Bytecode hash of the UniswapV3 pool
   * @return _weth The WETH token
   * @return _otherToken The non-WETH token in the UniswapV3 pool address
   * @return _feeManager The fee manager contract
   * @return _priceOracle The price oracle contract
   * @return _owner The contracts owner
   * @return _fee The UniswapV3 fee tier, as a 10000th of %
   * @return _sqrtPriceX96 A sqrt price representing the current pool prices
   */
  function constructorArguments()
    external
    view
    returns (
      IUniswapV3Factory _uniswapV3Factory,
      bytes32 _poolBytecodeHash,
      IERC20 _weth,
      IERC20 _otherToken,
      IFeeManager _feeManager,
      IPriceOracle _priceOracle,
      address _owner,
      uint24 _fee,
      uint160 _sqrtPriceX96
    );

  /**
   * @notice  Returns true if this factory deployed the given pool manager
   * @param   _poolManager The pool manager to be checked
   * @return  _isChild Whether the given pool manager was deployed by this factory
   */
  function isChild(IPoolManager _poolManager) external view returns (bool _isChild);

  /**
   * @notice Returns the address of the pool manager for a given pool, the zero address if there is no pool manager
   * @param  _pool The address of the Uniswap V3 pool
   * @return _poolManager The address of the pool manager for a given pool
   */
  function poolManagers(IUniswapV3Pool _pool) external view returns (IPoolManager _poolManager);

  /**
   * @notice Returns the list of all the pool managers deployed by this factory
   * @param  _index The index of the pool manager
   * @return _poolManager The pool manager
   */
  function children(uint256 _index) external view returns (IPoolManager _poolManager);

  /**
   * @notice Returns true if the pool has a valid pool manager
   * @param  _pool The address of the Uniswap V3 pool
   * @return _isSupportedPool True if the pool has a pool manager
   */
  function isSupportedPool(IUniswapV3Pool _pool) external view returns (bool _isSupportedPool);

  /**
   * @notice Returns true if the token has a pool paired with WETH
   * @param  _token The non-WETH token paired with WETH
   * @return _isValid True if the token has a pool paired with WETH
   */
  function isSupportedToken(IERC20 _token) external view returns (bool _isValid);

  /**
   * @notice Returns if a specific pair supports routing through WETH
   * @param  _tokenA The tokenA to check paired with tokenB
   * @param  _tokenB The tokenB to check paired with tokenA
   * @return _isSupported True if the pair is supported
   */
  function isSupportedTokenPair(IERC20 _tokenA, IERC20 _tokenB) external view returns (bool _isSupported);

  /**
   * @notice Returns the default fee to be used for a specific non-WETH token paired with WETH
   * @param  _token The non-WETH token paired with WETH
   * @return _fee The default fee for the non-WETH token on the WETH/TOKEN pool
   */
  function defaultTokenFee(IERC20 _token) external view returns (uint24 _fee);

  /**
   * @notice Returns the fee tiers for a specific non-WETH token paired with WETH
   * @param  _token The token paired with WETH
   * @return _fees The fee tiers the non-WETH token on the WETH/TOKEN pool
   */
  function tokenFees(IERC20 _token) external view returns (uint24[] memory _fees);

  /**
   * @notice Returns owner of the contract
   * @return _owner The owner of the contract
   */
  function owner() external view returns (address _owner);

  /**
   * @notice Returns the pending owner
   * @return _pendingOwner The pending owner of the contract
   */
  function pendingOwner() external view returns (address _pendingOwner);

  /**
   * @notice Returns the pool manager bytecode hash for deterministic addresses
   * @return _poolManagerBytecodeHash The pool manager bytecode hash
   */
  function POOL_MANAGER_BYTECODE_HASH() external view returns (bytes32 _poolManagerBytecodeHash);

  /*///////////////////////////////////////////////////////////////
                              LOGIC
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Deploys a new pool manager for a given UniswapV3 pool if it does not exist yet
   * @param  _token The non-WETH token paired with WETH in the given pool
   * @param  _fee The UniswapV3 pool fee tier, as a 10000th of %
   * @param  _liquidity The liquidity to create the pool manager
   * @param  _sqrtPriceX96 The sqrt price in base 96
   * @return _poolManager The pool manager newly deployed
   */
  function createPoolManager(IERC20 _token, uint24 _fee, uint128 _liquidity, uint160 _sqrtPriceX96)
    external
    returns (IPoolManager _poolManager);

  /**
   * @notice Returns pagination of the pool managers deployed by this factory
   * @param  _startFrom Index from where to start the pagination
   * @param  _amount Maximum amount of pool managers to retrieve
   * @return _list Paginated pool managers deployed by this factory
   */
  function listChildren(uint256 _startFrom, uint256 _amount) external view returns (IPoolManager[] memory _list);

  /**
   * @notice Computes the deterministic address of a given pool manager, a non-WETH token, and the fee
   * @param  _token The non-WETH token paired with WETH in the pool
   * @param  _fee The UniswapV3 fee tier
   * @return _theoreticalPoolManagerAddress The theoretical address of the pool manager
   */
  function getPoolManagerAddress(IERC20 _token, uint24 _fee)
    external
    view
    returns (IPoolManager _theoreticalPoolManagerAddress);

  /**
   * @notice Computes the deterministic address of a UniswapV3 pool with WETH, given the non-WETH token and its fee tier.
   * @param  _token The non-WETH token paired with WETH in the pool
   * @param  _fee The UniswapV3 fee tier
   * @return _theoreticalAddress Address of the theoretical address of the UniswapV3 pool
   * @return _isWethToken0 Defines if WETH is the token0 of the UniswapV3 pool
   */
  function getWethPoolAddress(IERC20 _token, uint24 _fee)
    external
    view
    returns (IUniswapV3Pool _theoreticalAddress, bool _isWethToken0);

  /**
   * @notice Lists the existing pool managers for a given token
   * @param  _token The address of the token
   * @param  _feeTiers The fee tiers to check
   * @return _poolManagerAddresses The available pool managers
   */
  function getPoolManagers(IERC20 _token, uint24[] memory _feeTiers)
    external
    view
    returns (address[] memory _poolManagerAddresses);

  /**
   * @notice Sets the default fee for the pool of non-WETH/WETH
   * @param  _token The non-WETH token paired with WETH in the pool
   * @param  _fee The UniswapV3 fee tier to use
   */
  function setDefaultTokenFee(IERC20 _token, uint24 _fee) external;

  /**
   * @notice Sets the new strategy address
   * @param  _strategy The new strategy address
   */
  function setStrategy(IStrategy _strategy) external;

  /**
   * @notice Sets the new lock manager factory address
   * @param  _lockManagerFactory The new lock manager factory address
   */
  function setLockManagerFactory(ILockManagerFactory _lockManagerFactory) external;

  /**
   * @notice Nominates the new owner of the contract
   * @param  _newOwner The new owner
   */
  function nominateOwner(address _newOwner) external;

  /**
   * @notice Sets a new owner and grants all roles needed to manage the contract
   */
  function acceptOwnership() external;

  /**
   * @notice Sets the contract address responsible for migrating
   * @param  _poolManagerMigrator The new pool manager migrator
   */
  function setPoolManagerMigrator(address _poolManagerMigrator) external;

  /**
   * @notice Sets price oracle contract
   * @param  _priceOracle The new price oracle
   */
  function setPriceOracle(IPriceOracle _priceOracle) external;

  /**
   * @notice Sets the fee manager contract
   * @param  _feeManager The new fee manager
   */
  function setFeeManager(IFeeManager _feeManager) external;

  /**
   * @notice Sets the fee collector job
   * @param  _feeCollectorJob The new fee collector job
   */
  function setFeeCollectorJob(IFeeCollectorJob _feeCollectorJob) external;

  /**
   * @notice Sets the minimum ETH amount
   * @param  _minEthAmount The new minimum ETH amount
   */
  function setMinEthAmount(uint256 _minEthAmount) external;
}

interface ICardinalityJob is IKeep3rJob {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Emitted when the minimum cardinality increase amount allowed is changed
   * @param  _minCardinalityIncrease The new minimum amount
   */
  event MinCardinalityIncreaseChanged(uint16 _minCardinalityIncrease);

  /**
   * @notice Emitted when the pool manager factory is changed
   * @param  _poolManagerFactory The new pool manager factory
   */
  event PoolManagerFactoryChanged(IPoolManagerFactory _poolManagerFactory);

  /**
   * @notice Emitted when the job is worked
   * @param  _poolManager The address of the pool manager
   * @param  _increaseAmount The amount of increase
   */
  event Worked(IPoolManager _poolManager, uint16 _increaseAmount);

  /*///////////////////////////////////////////////////////////////
                              ERRORS
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice Thrown when the proposed cardinality increase is too low
   */
  error CardinalityJob_MinCardinality();

  /**
   * @notice Thrown when working with an invalid pool manager
   */
  error CardinalityJob_InvalidPoolManager();

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the pool manager factory
   * @return _poolManagerFactory The pool manager factory
   */
  function poolManagerFactory() external view returns (IPoolManagerFactory _poolManagerFactory);

  /**
   * @notice Returns the minimum increase of cardinality allowed
   * @return _minCardinalityIncrease The minimum number of slots increases allowed
   */
  function minCardinalityIncrease() external view returns (uint16 _minCardinalityIncrease);

  /*///////////////////////////////////////////////////////////////
                              LOGIC
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice The function worked by the keeper, which will increase the pool cardinality
   * @dev    Requires enough WETH deposited for this pool to reimburse the gas consumption to the keeper
   * @param  _poolManager The pool manager of the pool for which the cardinality will be increased
   * @param  _increaseAmount The amount by which the cardinality will be increased
   */
  function work(IPoolManager _poolManager, uint16 _increaseAmount) external;

  /**
   * @notice Checks if the job can be worked in the current block
   * @param  _poolManager The pool manager of the pool for which the cardinality will be increased
   * @param  _increaseAmount The increased amount of the pool cardinality
   * @return _workable If the job is workable with the given inputs
   */
  function isWorkable(IPoolManager _poolManager, uint16 _increaseAmount) external view returns (bool _workable);

  /**
   * @notice Checks if the job can be worked in the current block by a specific keeper
   * @param  _poolManager The pool manager of the pool for which the cardinality will be increased
   * @param  _increaseAmount The increased amount of the pool cardinality
   * @param  _keeper The address of the keeper
   * @return _workable If the job is workable with the given inputs
   */
  function isWorkable(IPoolManager _poolManager, uint16 _increaseAmount, address _keeper)
    external
    returns (bool _workable);

  /**
   * @notice Changes the min amount of cardinality increase per work
   * @param  _minCardinalityIncrease The new minimum number of slots
   */
  function setMinCardinalityIncrease(uint16 _minCardinalityIncrease) external;

  /**
   * @notice Changes the pool manager factory
   * @param _poolManagerFactory The address of the new pool manager factory
   */
  function setPoolManagerFactory(IPoolManagerFactory _poolManagerFactory) external;

  /**
   * @notice Calculates the minimum possible cardinality increase for a pool
   * @param  _poolManager The pool manager of the pool for which the cardinality will be increased
   * @return _minCardinalityIncrease The minimum possible cardinality increase for the pool
   */
  function getMinCardinalityIncreaseForPool(IPoolManager _poolManager)
    external
    view
    returns (uint256 _minCardinalityIncrease);
}

/**
 * @title FeeManager contract
 * @notice This contract accumulates the fees collected from UniswapV3 pools for later use
 */
interface IFeeManager is IRoles {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Emitted when the fees are deposited
   * @param  _poolManager The pool manager providing the fees
   * @param  _wethFees The total amount of WETH fees collected and dedicated to increasing the full-range position
   * @param  _tokenFees The total amount of non-WETH token fees collected and dedicated to increasing the full-range position
   * @param  _wethForMaintenance The total amount of WETH fees collected and destined for the maintenance
   * @param  _wethForCardinality The total amount of WETH fees collected and destined to increase the cardinality of the pool
   */
  event FeesDeposited(
    IPoolManager _poolManager,
    uint256 _wethFees,
    uint256 _tokenFees,
    uint256 _wethForMaintenance,
    uint256 _wethForCardinality
  );

  /**
   * @notice Emitted when the swap gas cost multiplier has been changed
   * @param _swapGasCostMultiplier The swap gas cost multiplier to be set
   */
  event SwapGasCostMultiplierChanged(uint256 _swapGasCostMultiplier);

  /**
   * @notice Emitted when the cardinality job is set
   * @param _cardinalityJob The cardinality job to be set
   */
  event CardinalityJobSet(ICardinalityJob _cardinalityJob);

  /**
   * @notice Emitted when the maintenance governance address has been changed
   * @param _maintenanceGovernance The maintenance governance address
   */
  event MaintenanceGovernanceChanged(address _maintenanceGovernance);

  /**
   * @notice Emitted when the fees percentage of WETH for maintenance has been changed
   * @param _wethForMaintenance The fees percentage of WETH for maintenance
   */
  event WethForMaintenanceChanged(uint256 _wethForMaintenance);

  /**
   * @notice Emitted when the fees percentage of WETH for cardinality has been changed
   * @param _wethForCardinality The fees percentage of WETH for cardinality
   */
  event WethForCardinalityChanged(uint256 _wethForCardinality);

  /**
   * @notice Emitted when an old fee manager migrates to a new fee manager
   * @param  _poolManager The pool manager address
   * @param  _oldFeeManager The old fee manager address
   * @param  _newFeeManager The new fee manager address
   */
  event Migrated(address _poolManager, address _oldFeeManager, address _newFeeManager);

  /*///////////////////////////////////////////////////////////////
                              ERRORS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Thrown when we can't verify the pool manager
   */

  error FeeManager_InvalidPoolManager(IPoolManager _poolManager);

  /**
   * @notice Thrown when we can't verify the lock manager
   */
  error FeeManager_InvalidLockManager(ILockManager _lockManager);

  /**
   * @notice Thrown when we can't verify the old fee manager
   */
  error FeeManager_InvalidOldFeeManager(IFeeManager _feeManager);

  /**
   * @notice Thrown when we can't verify the pool manager factory
   */
  error FeeManager_InvalidPoolManagerFactory();

  /**
   * @notice Thrown when we can't verify the UniswapV3 pool
   * @param _sender The sender that is not a valid UniswapV3Pool
   */
  error FeeManager_InvalidUniswapPool(address _sender);

  /**
   * @notice Thrown when excess liquidity for the full range has been left over
   */
  error FeeManager_ExcessiveLiquidityLeft();

  /**
   * @notice Thrown when the liquidity provided of the token is incorrect
   */
  error FeeManager_InvalidTokenLiquidity();

  /**
   * @notice Thrown when the amount of ETH to get is less than the fees spent on the swap
   */
  error FeeManager_SmallSwap();

  /**
   * @notice Thrown when the sender is not the cardinality job
   */
  error FeeManager_NotCardinalityJob();

  /**
   * @notice Thrown when the cardinality is greater than the maximum
   */
  error FeeManager_CardinalityExceeded();

  /**
   * @notice Thrown when trying to migrate fee managers, but cardinality of the pool was already initialized
   */
  error FeeManager_NonZeroCardinality();

  /**
   * @notice Thrown when trying to migrate fee managers, but the pool manager deposits were already initialized
   */
  error FeeManager_NonZeroPoolDeposits();

  /**
   * @notice Thrown when trying to migrate fee managers, but pool manager distribution was already initialized
   */
  error FeeManager_InitializedPoolDistribution();

  /**
   * @notice Thrown when the WETH for maintenance is greater than the maximum
   */
  error FeeManager_WethForMaintenanceExceeded();

  /**
   * @notice Thrown when the WETH for cardinality is greater than the maximum
   */
  error FeeManager_WethForCardinalityExceeded();

  /*///////////////////////////////////////////////////////////////
                              STRUCTS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Total fees deposited by a pool manager
   * @param  wethForFullRange The amount of WETH dedicated to increasing the full-range position
   * @param  tokenForFullRange The amount of non-WETH token dedicated to increasing the full-range position
   */
  struct FeeStore {
    uint256 wethForFullRange;
    uint256 tokenForFullRange;
  }

  /**
   * @notice The values intended for cardinality incrementation
   * @param  weth The amount of WETH for increasing the cardinality
   * @param  currentMax The maximum value of the cardinality
   * @param  customMax The maximum value of the cardinality set by the governance
   */
  struct PoolCardinality {
    uint256 weth;
    uint16 currentMax;
    uint16 customMax;
  }

  /**
   * @notice The percentages of the fees directed to the maintenance and increasing cardinality
   * @param  wethForMaintenance The WETH for maintenance fees percentage
   * @param  wethForCardinality The WETH for cardinality fees percentage
   * @param  isInitialized True if the pool is initialized
   */
  struct PoolDistributionFees {
    uint256 wethForMaintenance;
    uint256 wethForCardinality;
    bool isInitialized;
  }

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the WETH token contract
   * @return _weth The WETH token
   */
  function WETH() external view returns (IERC20 _weth);

  /**
   * @notice Returns the amount of fees collected by a pool manager
   * @param  _poolManager The pool manager
   * @return _wethForFullRange The amount of WETH dedicated to increasing the full-range position
   * @return _tokenForFullRange The amount of non-WETH tokens dedicated to increasing the full-range position
   */
  function poolManagerDeposits(IPoolManager _poolManager)
    external
    view
    returns (uint256 _wethForFullRange, uint256 _tokenForFullRange);

  /**
   * @notice Returns information about the pool cardinality
   * @param  _poolManager The pool manager
   * @return _weth The amount of WETH to increase the cardinality
   * @return _currentMax The maximum value of the cardinality in a pool
   * @return _customMax The maximum value of the cardinality in a pool set by the governance
   */
  function poolCardinality(IPoolManager _poolManager)
    external
    view
    returns (uint256 _weth, uint16 _currentMax, uint16 _customMax);

  /**
   * @notice Returns the distribution percentages in a pool
   * @param  _poolManager The pool manager
   * @return _wethForMaintenance The WETH for maintenance fees percentage
   * @return _wethForCardinality The WETH for cardinality fees percentage
   * @return _isInitialized True if the pool is initialized
   */
  function poolDistribution(IPoolManager _poolManager)
    external
    view
    returns (uint256 _wethForMaintenance, uint256 _wethForCardinality, bool _isInitialized);

  /**
   * @notice Returns the pool manager factory
   * @return _poolManagerFactory The pool manager factory
   */
  function POOL_MANAGER_FACTORY() external view returns (IPoolManagerFactory _poolManagerFactory);

  /**
   * @notice Returns the cardinality job
   * @return _cardinalityJob The cardinality job
   */
  function cardinalityJob() external view returns (ICardinalityJob _cardinalityJob);

  /**
   * @notice Returns the address that receives the maintenance fee in WETH
   * @return _maintenanceGovernance The address that receives the maintenance fee in WETH
   */
  function maintenanceGovernance() external view returns (address _maintenanceGovernance);

  /**
   * @notice Returns the maximum value of cardinality
   * @dev    655 max cardinality array length
   * @return _poolCardinalityMax The maximum value of cardinality
   */
  function poolCardinalityMax() external view returns (uint16 _poolCardinalityMax);

  /**
   * @notice Returns the gas multiplier used to calculate the cost of swapping non-WETH token to WETH
   * @dev    This calculates whether the cost of the swap will be higher than the amount to be swapped
   * @return _swapGasCostMultiplier The value to calculate whether the swap is profitable
   */
  function swapGasCostMultiplier() external view returns (uint256 _swapGasCostMultiplier);

  /*///////////////////////////////////////////////////////////////
                              LOGIC
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Updates the record for fees collected from the pool manager
   * @dev    Splits the deposited fees into parts for different purposes
   * @dev    The fees from concentrated and full-range positions are handled differently
   * @param  _wethFees The total amount of WETH fees collected from the pool
   * @param  _tokenFees The total amount of non-WETH token fees collected from the pool
   */
  function depositFromPoolManager(uint256 _wethFees, uint256 _tokenFees) external;

  /**
   * @notice Updates the record for fees collected from the lock manager
   * @dev    Splits the deposited fees into parts for different purposes
   * @dev    The fees from concentrated and full-range positions are handled differently
   * @param  _wethFees The total amount of WETH fees collected from the pool
   * @param  _tokenFees The total amount of non-WETH token fees collected from the pool
   */
  function depositFromLockManager(uint256 _wethFees, uint256 _tokenFees) external;

  /**
   * @notice Transfers the necessary amount of WETH and token to increase the full range of a specific pool
   * @dev    Update the balances of tokens intended to increase the full-range position
   * @dev    If necessary, it will swap tokens for WETH.
   * @param  _pool The pool that needs to increase the full range
   * @param  _token The token that corresponds to the pool that needs to increase the full range
   * @param  _neededWeth The amount of WETH needed for increase the full range
   * @param  _neededToken The amount of token needed for increase the full range
   * @param  _isWethToken0 True if WETH is token0 in the pool
   */
  function increaseFullRangePosition(
    IUniswapV3Pool _pool,
    IERC20 _token,
    uint256 _neededWeth,
    uint256 _neededToken,
    bool _isWethToken0
  )
    external;

  /**
   * @notice Transfers the necessary amount of WETH and token to increase the full range of a specific pool
   * @dev    Callback that is called after uniswapV3MintCallback from PoolManager if the donor is the FeeManager
   * @dev    Updates the balances of WETH and token intended to increase the full-range position
   * @param  _pool The pool that need to increase the full range
   * @param  _token The token that corresponds to the pool that needs to increase the full range
   * @param  _neededWeth The amount of WETH needed to increase the full range
   * @param  _neededToken The amount of token needed to increase the full range
   */
  function fullRangeCallback(IUniswapV3Pool _pool, IERC20 _token, uint256 _neededWeth, uint256 _neededToken) external;

  /**
   * @notice Callback that is called when calling the swap method in a UniswapV3 pool
   * @dev    It is only called when you need to swap non-WETH tokens for WETH
   * @param  _amount0Delta  The amount of token0
   * @param  _amount1Delta The amount of token1
   * @param  _data The data that differentiates through an address whether to mint or transferFrom for the full range
   */
  function uniswapV3SwapCallback(int256 _amount0Delta, int256 _amount1Delta, bytes calldata _data) external;

  /**
   * @notice Updates the cardinality in a pool
   * @dev    This method only can be called by the cardinality job
   * @param  _poolManager The pool manager
   * @param  _weth The amount of WETH
   * @param  _cardinality The custom cardinality value
   */
  function increaseCardinality(IPoolManager _poolManager, uint256 _weth, uint16 _cardinality) external;

  /**
   * @notice Migrates to a new fee manager
   * @dev    Should be called from a valid lock manager
   * @param  _newFeeManager The new fee manager
   */
  function migrateTo(IFeeManager _newFeeManager) external;

  /**
   * @notice Migrates from an old fee manager
   * @dev    Should be called from the old fee manager
   * @dev    Receives WETH and non-WETH tokens from the old fee manager
   * @param  _poolManager The pool manager that is migrating its fee manager
   * @param  _poolCardinality The current pool cardinality
   * @param  _poolManagerDeposits The liquidity to deploy for the full range
   * @param  _poolManagerDeposits The distribution of percentages for cardinality and maintenance
   * @param  _poolDistributionFees The distribution fees of the pool
   */
  function migrateFrom(
    IPoolManager _poolManager,
    PoolCardinality memory _poolCardinality,
    FeeStore memory _poolManagerDeposits,
    PoolDistributionFees memory _poolDistributionFees
  )
    external;

  /**
   * @notice Set the swap gas multiplier
   * @dev    This method only can be called by governance
   * @param  _swapGasCostMultiplier The value of the gas multiplier that will be set
   */
  function setSwapGasCostMultiplier(uint256 _swapGasCostMultiplier) external;

  /**
   * @notice Sets the cardinality job
   * @param  _cardinalityJob The cardinality job
   */
  function setCardinalityJob(ICardinalityJob _cardinalityJob) external;

  /**
   * @notice Sets the maximum value to increase the cardinality
   * @param  _poolCardinalityMax The maximum value
   */
  function setPoolCardinalityMax(uint16 _poolCardinalityMax) external;

  /**
   * @notice Sets a custom maximum value to increase cardinality
   * @param  _poolManager The pool manager
   * @param  _cardinality The custom cardinality value
   */
  function setPoolCardinalityTarget(IPoolManager _poolManager, uint16 _cardinality) external;

  /**
   * @notice Sets maintenance governance address
   * @param  _maintenanceGovernance The address that has to receive the maintenance WETH
   */
  function setMaintenanceGovernance(address _maintenanceGovernance) external;

  /**
   * @notice Sets the percentage of the WETH fees for maintenance
   * @param  _poolManager The pool manager
   * @param  _wethForMaintenance The percentage of the WETH fees for maintenance
   */
  function setWethForMaintenance(IPoolManager _poolManager, uint256 _wethForMaintenance) external;

  /**
   * @notice Sets the percentage of the WETH fees for cardinality
   * @param  _poolManager The pool manager
   * @param  _wethForCardinality The percentage of the WETH fees for cardinality
   */
  function setWethForCardinality(IPoolManager _poolManager, uint256 _wethForCardinality) external;

  /**
   * @notice Returns the max cardinality for a pool
   * @param  _poolManager The pool manager
   * @param  _maxCardinality The max cardinality for a pool
   */
  function getMaxCardinalityForPool(IPoolManager _poolManager) external view returns (uint256 _maxCardinality);
}

/**
 * @title PoolManager governance contract
 * @notice This contract contains the data and logic necessary for the pool manager governance
 */
interface IPoolManagerGovernor is IGovernorMiniBravo {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Emitted when an old fee manager migrates to a new fee manager
   * @param  _newFeeManager The new fee manager
   */
  event FeeManagerMigrated(IFeeManager _newFeeManager);

  /**
   * @notice Emitted when the price oracle is set
   * @param  _newPriceOracle The new price oracle
   */
  event PriceOracleSet(IPriceOracle _newPriceOracle);

  /*///////////////////////////////////////////////////////////////
                            ERRORS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Thrown when the fee manager does not match the pool manager factory fee manager
   * @param  _expected The expected fee manager
   * @param  _actual The actual fee manager
   */
  error PoolManager_FeeManagerMismatch(IFeeManager _expected, IFeeManager _actual);

  /**
   * @notice Thrown when trying to set an already set fee manager
   */
  error PoolManager_FeeManagerAlreadySet();

  /**
   * @notice Thrown when the price oracle inputted does not match the poolManagerFactory priceOracle
   * @param  _expected The expected price oracle
   * @param  _actual The actual price oracle
   */
  error PoolManager_PriceOracleMismatch(IPriceOracle _expected, IPriceOracle _actual);

  /**
   * @notice Thrown when trying to set an already set price oracle
   */
  error PoolManager_PriceOracleAlreadySet();

  /**
   * @notice Thrown when the migration contract inputted does not match the poolManagerFactory migration contract
   * @param  _expected The expected migration contract
   * @param  _actual The actual migration contract
   */
  error PoolManager_MigrationContractMismatch(address _expected, address _actual);

  /**
   * @notice Thrown when trying to migrate to a new PoolManager unsuccessful
   */
  error PoolManager_MigrationFailed();

  /*///////////////////////////////////////////////////////////////
                            ENUMS
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice The methods that are available for governance
   */
  enum Methods {
    Migrate,
    FeeManagerChange,
    PriceOracleChange
  }

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice  Returns the pool manager factory contract
   * @return  _poolManagerFactory The pool manager factory
   */
  function POOL_MANAGER_FACTORY() external view returns (IPoolManagerFactory _poolManagerFactory);

  /**
   * @notice Returns the fee manager
   * @return _feeManager The fee manager
   */
  function feeManager() external view returns (IFeeManager _feeManager);

  /**
   * @notice Returns the pool liquidity
   * @return _poolLiquidity The pool liquidity
   */
  function poolLiquidity() external view returns (uint256 _poolLiquidity);

  /**
   * @notice Returns the liquidity seeded by the given donor
   * @param  _donor The donor's address
   * @return _seederBalance The amount of liquidity seeded by the donor
   */
  function seederBalance(address _donor) external view returns (uint256 _seederBalance);

  /**
   * @notice Returns the liquidity seeded by the given donor that they burned
   * @param  _donor The donor's address
   * @return _seederBurned The amount of liquidity seeded by the donor that they burned
   */
  function seederBurned(address _donor) external view returns (uint256 _seederBurned);

  /**
   * @notice Returns the price oracle
   * @return _priceOracle The price oracle
   */
  function priceOracle() external view returns (IPriceOracle _priceOracle);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Creates a proposal to change the fee manager
   * @dev    _newFeeManager must be equal to the current fee manager on the pool manager factory and
   * different from the current fee manager
   * @param  _newFeeManager The new fee manager to be set up
   */
  function proposeFeeManagerChange(IFeeManager _newFeeManager) external;

  /**
   * @notice Votes yes on the proposal to change the fee manager
   * @param  _newFeeManager The new fee manager to be set up
   */
  function acceptFeeManagerChange(IFeeManager _newFeeManager) external;

  /**
   * @notice Creates a proposal to migrate
   * @dev    _migrationContract must be equal to the current migration contract on
   * the pool manager factory and different from the current migration contract
   * @param  _migrationContract The migration contract
   */
  function proposeMigrate(address _migrationContract) external;

  /**
   * @notice Votes yes on the proposal to migrate
   * @param  _migrationContract The migration contract
   */
  function acceptMigrate(address _migrationContract) external;

  /**
   * @notice Creates a proposal to change the price's oracle
   * @dev    _newPriceOracle must be equal to the current price oracle on the
   * pool manager factory and different from the current price's oracle
   * @param  _newPriceOracle The new price oracle to be set up
   */
  function proposePriceOracleChange(IPriceOracle _newPriceOracle) external;

  /**
   * @notice Votes yes on the proposal to change the prices oracle
   * @param  _newPriceOracle The new price oracle to be set up
   */
  function acceptPriceOracleChange(IPriceOracle _newPriceOracle) external;
}

/**
 * @title PoolManager contract
 * @notice This contract manages the protocol owned positions of the associated uni v3 pool
 */
interface IPoolManager is IPoolManagerGovernor {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Emitted when a seeder burns liquidity
   * @param  _liquidity The liquidity that has been burned
   */
  event SeederLiquidityBurned(uint256 _liquidity);

  /**
   * @notice Emitted when a lock manager is deprecated
   * @param  _oldLockManager The lock manager that was deprecated
   * @param  _newLockManager The new lock manager
   */
  event LockManagerDeprecated(ILockManager _oldLockManager, ILockManager _newLockManager);

  /**
   * @notice Emitted when fees are collected
   * @param  _totalFeeWeth Total WETH amount collected
   * @param  _totalFeeToken Total token amount collected
   */
  event FeesCollected(uint256 _totalFeeWeth, uint256 _totalFeeToken);

  /**
   * @notice Emitted when rewards are added to a pool manager
   * @param  _wethAmount The amount of WETH added
   * @param  _tokenAmount The amount of WETH added
   */
  event RewardsAdded(uint256 _wethAmount, uint256 _tokenAmount);

  /**
   * @notice Emitted when a seeder claims their rewards
   * @param  _user The address of the user that claimed the rewards
   * @param  _wethAmount The amount of WETH tokens to claim
   * @param  _tokenAmount The amount of non-WETH tokens to claim
   */
  event ClaimedRewards(address _user, address _to, uint256 _wethAmount, uint256 _tokenAmount);

  /*///////////////////////////////////////////////////////////////
                              ERRORS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Thrown when someone other than the factory tries to call the method
   */
  error PoolManager_OnlyFactory();

  /**
   * @notice Thrown when someone other than the pool tries to call the method
   */
  error PoolManager_OnlyPool();

  /**
   * @notice Thrown when someone tries to deploy a new lock manager while the old one is still not deprecated
   */
  error PoolManager_ActiveLockManager();

  /**
   * @notice Thrown when the amount is zero
   */
  error PoolManager_ZeroAmount();

  /**
   * @notice Thrown when the provided address is zero
   */
  error PoolManager_ZeroAddress();

  /**
   * @notice Thrown when the user doesn't have rewards to claim
   */
  error PoolManager_NoRewardsToClaim();

  /**
   * @notice Thrown when the price oracle detects a manipulation
   */
  error PoolManager_PoolManipulated();

  /**
   * @notice Thrown when the FeeManager provided is incorrect
   */
  error PoolManager_InvalidFeeManager();

  /**
   * @notice Thrown when the caller of the `burn1` function is not the current oracle
   */
  error PoolManager_InvalidPriceOracle();

  /*///////////////////////////////////////////////////////////////
                              STRUCTS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice The amounts of paid and available rewards per seeder
   * @param  wethPaid The WETH amount already claimed
   * @param  tokenPaid The non-WETH token amount already claimed
   * @param  wethAvailable The available WETH amount
   * @param  tokenAvailable The available non-WETH token amount
   */
  struct SeederRewards {
    uint256 wethPaid;
    uint256 tokenPaid;
    uint256 wethAvailable;
    uint256 tokenAvailable;
  }

  /**
   * @notice Pool status for internal accountancy
   * @param  wethPerSeededLiquidity The value of the reward per WETH locked
   * @param  tokenPerSeededLiquidity The value of the reward per non-WETH token locked
   */
  struct PoolRewards {
    uint256 wethPerSeededLiquidity;
    uint256 tokenPerSeededLiquidity;
  }

  /**
   * @notice The parameters for the lock manager
   */
  struct LockManagerParams {
    IPoolManagerFactory factory;
    IStrategy strategy;
    IERC20 token;
    IERC20 weth;
    IUniswapV3Pool pool;
    bool isWethToken0;
    uint24 fee;
    address governance;
    uint256 index;
  }

  /**
   * @notice UniswapV3 pool position
   * @param  lowerTick The lower tick of the position
   * @param  upperTick The upper tick of the position
   */
  struct Position {
    int24 lowerTick;
    int24 upperTick;
  }

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the WETH contract
   * @return _weth The WETH token
   */
  function WETH() external view returns (IERC20 _weth);

  /**
   * @notice Returns the UniswapV3 factory contract
   * @return _uniswapV3Factory The UniswapV3 factory contract
   */
  function UNISWAP_V3_FACTORY() external view returns (IUniswapV3Factory _uniswapV3Factory);

  /**
   * @notice Returns the UniswapV3 pool bytecode hash
   * @return _poolBytecodeHash The UniswapV3 pool bytecode hash
   */
  function POOL_BYTECODE_HASH() external view returns (bytes32 _poolBytecodeHash);

  /**
   * @notice Returns the lock manager contract
   * @return _lockManager The lock manager
   */
  function lockManager() external view returns (ILockManager _lockManager);

  /**
   * @notice Returns a deprecated lock manager contract at a specific index
   * @return _deprecatedLockManagers A deprecated lock manager
   */
  function deprecatedLockManagers(uint256 _index) external view returns (ILockManager _deprecatedLockManagers);

  /**
   * @notice Returns the fee of the pool manager
   * @return _fee The pool manager's fee
   */
  function FEE() external view returns (uint24 _fee);

  /**
   * @notice Returns the non-WETH token of the underlying pool
   * @return _token The non-WETH token of the underlying pool
   */
  function TOKEN() external view returns (IERC20 _token);

  /**
   * @notice Returns the underlying UniswapV3 pool contract
   * @return _pool The underlying UniswapV3 pool contract
   */
  function POOL() external view returns (IUniswapV3Pool _pool);

  /**
   * @notice Returns true if WETH token is the token0
   * @return _isWethToken0 If WETH is token0
   */
  function IS_WETH_TOKEN0() external view returns (bool _isWethToken0);

  /**
   * @notice  Returns the pending to the corresponding account
   * @param   _account The address of the account
   * @return  _wethPaid The amount of claimed rewards in WETH
   * @return  _tokenPaid The amount of claimed rewards in the non-WETH token
   * @return  _wethAvailable The amount of pending rewards in WETH
   * @return  _tokenAvailable The amount of pending rewards in the non-WETH token
   */
  function seederRewards(address _account)
    external
    view
    returns (uint256 _wethPaid, uint256 _tokenPaid, uint256 _wethAvailable, uint256 _tokenAvailable);

  /**
   * @notice Returns the status of a corresponding pool manager
   * @return _wethPerSeededLiquidity The value of the reward per WETH locked
   * @return _tokenPerSeededLiquidity The value of the reward per non-WETH token locked
   */
  function poolRewards() external view returns (uint256 _wethPerSeededLiquidity, uint256 _tokenPerSeededLiquidity);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Deprecates the current lock manager and deploys a new one
   */
  function deprecateLockManager() external;

  /**
   * @notice  Mint liquidity for the full-range position
   * @param  _wethAmount The amount of WETH token to be inserted in the full-range position
   * @param  _tokenAmount The amount of non-WETH token to be inserted in the full-range position
   */
  function mintLiquidityForFullRange(uint256 _wethAmount, uint256 _tokenAmount) external;

  /**
   * @notice  Burns an amount of liquidity provided by a seeder
   * @param  _liquidity The amount of liquidity
   * @dev    The voting power for the user remains the same but they donate all rewards
   */
  function burn(uint256 _liquidity) external;

  /**
   * @notice Callback that is called when calling the mint method in a UniswapV3 pool
   * @dev    It is only called in the creation of the full range and when positions need to be updated
   * @param  _amount0Owed  The amount of token0
   * @param  _amount1Owed The amount of token1
   * @param  _data The data that differentiates through an address whether to mint or transfer from for the full range
   */
  function uniswapV3MintCallback(uint256 _amount0Owed, uint256 _amount1Owed, bytes calldata _data) external;

  /**
   * @notice Increases the full-range position. The deposited tokens can not withdrawn
   * and all of the generated fees with only benefit the pool itself
   * @param  _donor The user that will provide WETH and the other token
   * @param  _liquidity The liquidity that will be minted
   * @param  _sqrtPriceX96 A sqrt price representing the current pool prices
   */
  function increaseFullRangePosition(address _donor, uint128 _liquidity, uint160 _sqrtPriceX96) external;

  /**
   * @notice Increases the full-range position with a given liquidity
   * @dev    Pool manager will make a callback to the fee manager, who will provide the liquidity
   * @param  _wethAmount The amount of WETH token to be inserted in the full-range position
   * @param  _tokenAmount The amount of non-WETH to be inserted in the full-range position
   * @return __amountWeth The amount in WETH added to the full range
   * @return __amountToken The amount in non-WETH token added to the full range
   */
  function increaseFullRangePosition(uint256 _wethAmount, uint256 _tokenAmount)
    external
    returns (uint256 __amountWeth, uint256 __amountToken);

  /**
   * @notice Claims the fees from the UniswapV3 pool and stores them in the FeeManager
   */
  function collectFees() external;

  /**
   * @notice Returns the rewards generated by a caller
   * @param  _to The recipient the rewards
   * @return _rewardWeth The amount of rewards in WETH that were claimed
   * @return _rewardToken The amount of rewards in non-WETH token that were claimed
   */
  function claimRewards(address _to) external returns (uint256 _rewardWeth, uint256 _rewardToken);

  /**
   * @notice Returns the total amount of WETH claimable for a given account
   * @param  _account The address of the account
   * @return _wethClaimable The amount of WETH claimable
   * @return _tokenClaimable The amount of non-WETH token claimable
   */
  function claimable(address _account) external view returns (uint256 _wethClaimable, uint256 _tokenClaimable);

  /**
   * @notice Burns a little bit of liquidity in the pool to produce a new observation
   * @dev    The oracle corrections require at least 2 post-manipulation observations to work properly
   * When there is no new observations after a manipulation, the oracle will make then with this function
   */
  function burn1() external;
}

interface IFeeCollectorJob is IKeep3rJob {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Emitted when the job is worked
   * @param  _lockManager The lock manager
   * @param  _positions The list of positions to collect the fees from
   */
  event WorkedLockManager(ILockManager _lockManager, IStrategy.Position[] _positions);

  /**
   * @notice Emitted when the job is worked
   * @param  _poolManager The pool manager
   */
  event WorkedPoolManager(IPoolManager _poolManager);

  /**
   * @notice Emitted when the collect multiplier has been set
   * @param  _collectMultiplier The number of the multiplier
   */
  event CollectMultiplierSet(uint256 _collectMultiplier);

  /*///////////////////////////////////////////////////////////////
                              ERRORS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Thrown when the pool manager cannot be verified
   * @param  _poolManager The invalid pool manager
   */
  error FeeCollectorJob_InvalidPoolManager(IPoolManager _poolManager);

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the collect multiplier
   * @return _collectMultiplier The collect multiplier
   */
  function collectMultiplier() external view returns (uint256 _collectMultiplier);

  /**
   * @notice Returns the pool manager factory
   * @return _poolManagerFactory The pool manager factory
   */
  function POOL_MANAGER_FACTORY() external view returns (IPoolManagerFactory _poolManagerFactory);

  /*///////////////////////////////////////////////////////////////
                              LOGIC
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Collects the fees from the given positions and rewards the keeper
   * @dev    Will revert if the job is paused or if the keeper is not valid
   * @param  _poolManager The pool manager
   * @param  _positions The list of positions to collect the fees from
   */
  function work(IPoolManager _poolManager, IStrategy.Position[] calldata _positions) external;

  /**
   * @notice Collects the fees from the full range and rewards the keeper
   * @dev    Will revert if the job is paused or if the keeper is not valid
   * @param  _poolManager The pool manager
   */
  function work(IPoolManager _poolManager) external;

  /**
   * @notice Sets the collect multiplier
   * @dev    Only governance can change it
   * @param  _collectMultiplier The collect multiplier
   */
  function setCollectMultiplier(uint256 _collectMultiplier) external;
}

/**
 * @notice Collects the fees from a list of positions
 */
contract FeeCollectorJob is IFeeCollectorJob, Keep3rJob {
  /// @inheritdoc IFeeCollectorJob
  IPoolManagerFactory public immutable POOL_MANAGER_FACTORY;
  /// @inheritdoc IFeeCollectorJob
  uint256 public collectMultiplier;

  /**
   * @dev Payable constructor does not waste gas on checking msg.value
   */
  constructor(IPoolManagerFactory _poolManagerFactory, address _governor) payable Governable(_governor) {
    POOL_MANAGER_FACTORY = _poolManagerFactory;
    collectMultiplier = 20;
  }

  /// @inheritdoc IFeeCollectorJob
  function work(IPoolManager _poolManager, IStrategy.Position[] calldata _positions)
    external
    upkeep(msg.sender)
    notPaused
  {
    if (!POOL_MANAGER_FACTORY.isChild(_poolManager)) {
      revert FeeCollectorJob_InvalidPoolManager(_poolManager);
    }
    ILockManager _lockManager = _poolManager.lockManager();
    _lockManager.collectFees(_positions);
    emit WorkedLockManager(_lockManager, _positions);
  }

  /// @inheritdoc IFeeCollectorJob
  function work(IPoolManager _poolManager) external upkeep(msg.sender) notPaused {
    if (!POOL_MANAGER_FACTORY.isChild(_poolManager)) {
      revert FeeCollectorJob_InvalidPoolManager(_poolManager);
    }
    _poolManager.collectFees();
    emit WorkedPoolManager(_poolManager);
  }

  /// @inheritdoc IFeeCollectorJob
  function setCollectMultiplier(uint256 _collectMultiplier) external onlyGovernor {
    collectMultiplier = _collectMultiplier;
    emit CollectMultiplierSet(_collectMultiplier);
  }
}