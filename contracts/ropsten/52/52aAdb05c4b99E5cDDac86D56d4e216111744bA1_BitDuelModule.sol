/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

/**
    ***********************************************************
    * Copyright (c) Avara Dev. 2022. (Telegram: @avara_cc)  *
    ***********************************************************

     ▄▄▄·  ▌ ▐· ▄▄▄· ▄▄▄   ▄▄▄·
    ▐█ ▀█ ▪█·█▌▐█ ▀█ ▀▄ █·▐█ ▀█
    ▄█▀▀█ ▐█▐█•▄█▀▀█ ▐▀▀▄ ▄█▀▀█
    ▐█ ▪▐▌ ███ ▐█ ▪▐▌▐█•█▌▐█ ▪▐▌
     ▀  ▀ . ▀   ▀  ▀ .▀  ▀ ▀  ▀  - Ethereum Network

    Avara - Always Vivid, Always Rising Above
    https://avara.cc/
    https://github.com/avara-cc
    https://github.com/avara-cc/AvaraETH/wiki
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data.
 */
abstract contract Context {
    /**
     * @dev Returns the value of the msg.sender variable.
     */
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Returns the value of the msg.data variable.
     */
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 */
abstract contract Ownable is Context {
    // Current owner address
    address private _owner;
    // Previous owner address
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the given address as the initial owner.
     */
    constructor(address initOwner) {
        _setOwner(initOwner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the previous owner.
     */
    function previousOwner() public view virtual returns (address) {
        return _previousOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: The caller is not the owner!");
        _;
    }

    /**
     * @dev Leaves the contract without an owner. It won't be possible to call `onlyOwner` functions anymore.
     * Can only be called by the current owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: The new owner is now, the zero address!");
        _setOwner(newOwner);
    }

    /**
     * @dev Sets the owner of the token to the given address.
     *
     * Emits an {OwnershipTransferred} event.
     */
    function _setOwner(address newOwner) private {
        _previousOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(_previousOwner, newOwner);
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the benefit is lost if 'b' is also tested.
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
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
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
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
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
}

/**
 * @title Pool state that never changes
 * @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
 */
interface IUniswapV3PoolImmutables {
    /**
     * @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
     * @return The contract address
     */
    function factory() external view returns (address);

    /**
     * @notice The first of the two tokens of the pool, sorted by address
     * @return The token contract address
     */
    function token0() external view returns (address);

    /**
     * @notice The second of the two tokens of the pool, sorted by address
     * @return The token contract address
     */
    function token1() external view returns (address);

    /** @notice The pool's fee in hundredths of a bip, i.e. 1e-6
     * @return The fee
     */
    function fee() external view returns (uint24);

    /**
     * @notice The pool tick spacing
     * @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
     * e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
     * This value is an int24 to avoid casting even though it is always positive.
     * @return The tick spacing
     */
    function tickSpacing() external view returns (int24);

    /**
     * @notice The maximum amount of position liquidity that can use any tick in the range
     * @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
     * also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
     * @return The max amount of liquidity per tick
     */
    function maxLiquidityPerTick() external view returns (uint128);
}

/**
 * @title Pool state that can change
 * @notice These methods compose the pool's state, and can change with any frequency including multiple times
 * per transaction
 */
interface IUniswapV3PoolState {
    /** @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
     * when accessed externally.
     * @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
     * tick The current tick of the pool, i.e. according to the last tick transition that was run.
     * This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
     * boundary.
     * observationIndex The index of the last oracle observation that was written,
     * observationCardinality The current maximum number of observations stored in the pool,
     * observationCardinalityNext The next maximum number of observations, to be updated when the observation.
     * feeProtocol The protocol fee for both tokens of the pool.
     * Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
     * is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
     * unlocked Whether the pool is currently locked to reentrancy
     */
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

    /**
     * @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
     * @dev This value can overflow the uint256
     */
    function feeGrowthGlobal0X128() external view returns (uint256);

    /**
     * @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
     * @dev This value can overflow the uint256
     */
    function feeGrowthGlobal1X128() external view returns (uint256);

    /**
     * @notice The amounts of token0 and token1 that are owed to the protocol
     * @dev Protocol fees will never exceed uint128 max in either token
     */
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /**
     * @notice The currently in range liquidity available to the pool
     * @dev This value has no relationship to the total liquidity across all ticks
     */
    function liquidity() external view returns (uint128);

    /**
     * @notice Look up information about a specific tick in the pool
     * @param tick The tick to look up
     * @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
     * tick upper,
     * liquidityNet how much liquidity changes when the pool price crosses the tick,
     * feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
     * feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
     * tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
     * secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
     * secondsOutside the seconds spent on the other side of the tick from the current tick,
     * initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
     * Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
     * In addition, these values are only relative and must be used only in comparison to previous snapshots for
     * a specific position.
     */
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

    /**
     * @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
     * function tickBitmap(int16 wordPosition) external view returns (uint256);

    /**
     * @notice Returns the information about a position by the position's key
     * @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
     * @return _liquidity The amount of liquidity in the position,
     * @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
     * @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
     * @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
     * @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
     */
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

    /**
     * @notice Returns data about a specific observation index
     * @param index The element of the observations array to fetch
     * @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
     * ago, rather than at a specific index in the array.
     * @return blockTimestamp The timestamp of the observation,
     * @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
     * @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
     * @return initialized whether the observation has been initialized and the values are safe to use
     */
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

/**
 * @title Pool state that is not stored
 * @notice Contains view functions to provide information about the pool that is computed rather than stored on the
 * blockchain. The functions here may have variable gas costs.
 */
interface IUniswapV3PoolDerivedState {
    /**
     * @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
     * @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
     * the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
     * you must call it with secondsAgos = [3600, 0].
     * @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
     * log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
     * @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
     * @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
     * @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
     * timestamp
     */
    function observe(uint32[] calldata secondsAgos)
    external
    view
    returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /**
     * @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
     * @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
     * I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
     * snapshot is taken and the second snapshot is taken.
     * @param tickLower The lower tick of the range
     * @param tickUpper The upper tick of the range
     * @return tickCumulativeInside The snapshot of the tick accumulator for the range
     * @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
     * @return secondsInside The snapshot of seconds per liquidity for the range
     */
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
    external
    view
    returns (
        int56 tickCumulativeInside,
        uint160 secondsPerLiquidityInsideX128,
        uint32 secondsInside
    );
}

/**
 * @title Permissionless pool actions
 * @notice Contains pool methods that can be called by anyone
 */
interface IUniswapV3PoolActions {
    /**
     * @notice Sets the initial price for the pool
     * @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
     * @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
     */
    function initialize(uint160 sqrtPriceX96) external;

    /**
     * @notice Adds liquidity for the given recipient/tickLower/tickUpper position
     * @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
     * in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
     * on tickLower, tickUpper, the amount of liquidity, and the current price.
     * @param recipient The address for which the liquidity will be created
     * @param tickLower The lower tick of the position in which to add liquidity
     * @param tickUpper The upper tick of the position in which to add liquidity
     * @param amount The amount of liquidity to mint
     * @param data Any data that should be passed through to the callback
     * @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
     * @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
     */
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /**
     * @notice Collects tokens owed to a position
     * @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
     * Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
     * amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
     * actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
     * @param recipient The address which should receive the fees collected
     * @param tickLower The lower tick of the position for which to collect fees
     * @param tickUpper The upper tick of the position for which to collect fees
     * @param amount0Requested How much token0 should be withdrawn from the fees owed
     * @param amount1Requested How much token1 should be withdrawn from the fees owed
     * @return amount0 The amount of fees collected in token0
     * @return amount1 The amount of fees collected in token1
     */
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /**
     * @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
     * @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
     * @dev Fees must be collected separately via a call to #collect
     * @param tickLower The lower tick of the position for which to burn liquidity
     * @param tickUpper The upper tick of the position for which to burn liquidity
     * @param amount How much liquidity to burn
     * @return amount0 The amount of token0 sent to the recipient
     * @return amount1 The amount of token1 sent to the recipient
     */
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /**
     * @notice Swap token0 for token1, or token1 for token0
     * @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
     * @param recipient The address to receive the output of the swap
     * @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
     * @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
     * @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
     * value after the swap. If one for zero, the price cannot be greater than this value after the swap
     * @param data Any data to be passed through to the callback
     * @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
     * @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
     */
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /**
     * @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
     * @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
     * @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
     * with 0 amount{0,1} and sending the donation amount(s) from the callback
     * @param recipient The address which will receive the token0 and token1 amounts
     * @param amount0 The amount of token0 to send
     * @param amount1 The amount of token1 to send
     * @param data Any data to be passed through to the callback
     */
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /**
     * @notice Increase the maximum number of price and liquidity observations that this pool will store
     * @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
     * the input observationCardinalityNext.
     * @param observationCardinalityNext The desired minimum number of observations for the pool to store
     */
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

/**
 * @title Permissioned pool actions
 * @notice Contains pool methods that may only be called by the factory owner
 */
interface IUniswapV3PoolOwnerActions {
    /**
     * @notice Set the denominator of the protocol's % share of the fees
     * @param feeProtocol0 new protocol fee for token0 of the pool
     * @param feeProtocol1 new protocol fee for token1 of the pool
     */
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /**
     * @notice Collect the protocol fee accrued to the pool
     * @param recipient The address to which collected protocol fees should be sent
     * @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
     * @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
     * @return amount0 The protocol fee collected in token0
     * @return amount1 The protocol fee collected in token1
     */
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

/**
 * @title Events emitted by a pool
 * @notice Contains all events emitted by the pool
 */
interface IUniswapV3PoolEvents {
    /**
     * @notice Emitted exactly once by a pool when #initialize is first called on the pool
     * @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
     * @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
     * @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
     */
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /**
     * @notice Emitted when liquidity is minted for a given position
     * @param sender The address that minted the liquidity
     * @param owner The owner of the position and recipient of any minted liquidity
     * @param tickLower The lower tick of the position
     * @param tickUpper The upper tick of the position
     * @param amount The amount of liquidity minted to the position range
     * @param amount0 How much token0 was required for the minted liquidity
     * @param amount1 How much token1 was required for the minted liquidity
     */
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /**
     * @notice Emitted when fees are collected by the owner of a position
     * @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
     * @param owner The owner of the position for which fees are collected
     * @param tickLower The lower tick of the position
     * @param tickUpper The upper tick of the position
     * @param amount0 The amount of token0 fees collected
     * @param amount1 The amount of token1 fees collected
     */
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /**
     * @notice Emitted when a position's liquidity is removed
     * @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
     * @param owner The owner of the position for which liquidity is removed
     * @param tickLower The lower tick of the position
     * @param tickUpper The upper tick of the position
     * @param amount The amount of liquidity to remove
     * @param amount0 The amount of token0 withdrawn
     * @param amount1 The amount of token1 withdrawn
     */
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /**
     * @notice Emitted by the pool for any swaps between token0 and token1
     * @param sender The address that initiated the swap call, and that received the callback
     * @param recipient The address that received the output of the swap
     * @param amount0 The delta of the token0 balance of the pool
     * @param amount1 The delta of the token1 balance of the pool
     * @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
     * @param liquidity The liquidity of the pool after the swap
     * @param tick The log base 1.0001 of price of the pool after the swap
     */
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /**
     * @notice Emitted by the pool for any flashes of token0/token1
     * @param sender The address that initiated the swap call, and that received the callback
     * @param recipient The address that received the tokens from flash
     * @param amount0 The amount of token0 that was flashed
     * @param amount1 The amount of token1 that was flashed
     * @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
     * @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
     */
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /**
     * @notice Emitted by the pool for increases to the number of observations that can be stored
     * @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
     * just before a mint/swap/burn.
     * @param observationCardinalityNextOld The previous value of the next observation cardinality
     * @param observationCardinalityNextNew The updated value of the next observation cardinality
     */
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /**
     * @notice Emitted when the protocol fee is changed by the pool
     * @param feeProtocol0Old The previous value of the token0 protocol fee
     * @param feeProtocol1Old The previous value of the token1 protocol fee
     * @param feeProtocol0New The updated value of the token0 protocol fee
     * @param feeProtocol1New The updated value of the token1 protocol fee
     */
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /**
     * @notice Emitted when the collected protocol fees are withdrawn by the factory owner
     * @param sender The address that collects the protocol fees
     * @param recipient The address that receives the collected protocol fees
     * @param amount0 The amount of token0 protocol fees that is withdrawn
     * @param amount0 The amount of token1 protocol fees that is withdrawn
     */
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

/**
 * @title The interface for a Uniswap V3 Pool
 * @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
 * to the ERC20 specification
 * @dev The pool interface is broken up into many smaller pieces
 */
interface IUniswapV3Pool is
IUniswapV3PoolImmutables,
IUniswapV3PoolState,
IUniswapV3PoolDerivedState,
IUniswapV3PoolActions,
IUniswapV3PoolOwnerActions,
IUniswapV3PoolEvents
{

}

interface IUniswapV3Router {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactInputSingle(
        IUniswapV3Router.ExactInputSingleParams memory params
    ) external returns (uint256 amountOut);

    function exactInput(
        IUniswapV3Router.ExactInputParams memory params
    ) external returns (uint256 amountOut);

    function exactOutputSingle(
        IUniswapV3Router.ExactOutputSingleParams memory params
    ) external returns (uint256 amountIn);

    function exactOutput(
        IUniswapV3Router.ExactOutputParams memory params
    ) external returns (uint256 amountIn);
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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

contract Avara is Context, IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;

    //
    // Reward, fee and wallet related variables.
    //
    mapping(address => uint256) private _rewardOwned;
    mapping(address => uint256) private _tokenOwned;
    mapping(address => bool)    private _isExcludedFromFee;
    mapping(address => bool)    private _isExcluded;
    mapping(address => mapping(address => uint256)) private _allowances;

    address[] private _excluded;
    address public _devWallet;

    //
    // Summary of the fees
    //
    uint256 private _bitDuelServiceFeeTotal;
    uint256 private _developerFeeTotal;
    uint256 private _eventFeeTotal;
    uint256 private _feeTotal;
    uint256 private _marketingFeeTotal;

    //
    // AvaraToken metadata
    //
    string private constant _name = "AVARA";
    string private constant _symbol = "AVR";
    uint8 private constant _decimals = 9;

    // 20% Maximum Total Fee (used for validation)
    uint256 public constant MAX_TOTAL_FEE = 2000;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _totalSupply = 500000000 * 10 ** uint256(_decimals);
    uint256 private _rewardSupply = (MAX - (MAX % _totalSupply));

    // 0.2% is going to the be the founding of the upcoming Events
    uint256 public _eventFee = 20;
    // 0.4% is going to Marketing.
    uint256 public _marketingFee = 40;
    // 0.4% is going to the Developers.
    uint256 public _developerFee = 40;
    // 1% service fee on BitDuel.
    uint256 public _bitDuelServiceFee = 100;

    // Sell pressure reduced by 15x
    uint256 public _sellPressureReductor = 1500;
    uint8 public _sellPressureReductorDecimals = 2;

    uint256 public _maxTxAmount = 250000000 * 10 ** uint256(_decimals);
    bool public _rewardEnabled = true;

    //
    // BitDuel
    //
    mapping(address => uint256) private _playerPool;
    address public _playerPoolWallet;

    // A constant, used for checking the connection between the server and the contract.
    string private constant _pong = "PONG";

    //
    // Liquidity related fields.
    //

    IUniswapV3Pool public _uniswapV3Pool;
    IUniswapV3Router public _uniswapV3Router;

    event BitDuelServiceFeeChanged(uint256 oldFee, uint256 newFee);
    event DeveloperFeeChanged(uint256 oldFee, uint256 newFee);
    event DevWalletChanged(address oldAddress, address newAddress);
    event EventFeeChanged(uint256 oldFee, uint256 newFee);
    event FallBack(address sender, uint value);
    event MarketingFeeChanged(uint256 oldFee, uint256 newFee);
    event MaxTransactionAmountChanged(uint256 oldAmount, uint256 newAmount);
    event PlayerPoolChanged(address oldAddress, address newAddress);
    event Received(address sender, uint value);
    event RewardEnabledStateChanged(bool oldState, bool newState);
    event SellPressureReductorChanged(uint256 oldReductor, uint256 newReductor);
    event SellPressureReductorDecimalsChanged(uint8 oldDecimals, uint8 newDecimals);
    event UniswapPoolChanged(address oldAddress, address newAddress);
    event UniswapRouterChanged(address oldAddress, address newAddress);

    /**
    * @dev Executed on a call to the contract with empty call data.
    */
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
    * @dev Executed on a call to the contract that does not match any of the contract functions.
    */
    fallback() external payable {
        emit FallBack(msg.sender, msg.value);
    }

    //
    // The token constructor.
    //

    constructor (address cOwner, address devWallet, address playerPoolWallet) Ownable(cOwner) {
        _devWallet = devWallet;
        _playerPoolWallet = playerPoolWallet;

        _rewardOwned[cOwner] = _rewardSupply;
        _uniswapV3Router = IUniswapV3Router(0xE592427A0AEce92De3Edee1F18E0157C05861564);

        // Exclude the system addresses from the fee.
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_devWallet] = true;

        emit Transfer(address(0), cOwner, _totalSupply);
    }

    //
    // Contract Modules
    //

    struct Module {
        string moduleName;
        string moduleVersion;
        address moduleAddress;
    }

    Module[] private modules;

    event ModuleAdded(address moduleAddress, string moduleName, string moduleVersion);
    event ModuleRemoved(string moduleName);

    /**
    * @dev Adds a module to the contract with the given ModuleName and Version on the given ModuleAddress.
    */
    function addModule(string memory moduleName, string memory moduleVersion, address moduleAddress) external onlyOwner {
        Module memory module;
        module.moduleVersion = moduleVersion;
        module.moduleAddress = moduleAddress;
        module.moduleName = moduleName;

        bool added = false;
        for (uint256 i = 0; i < modules.length; i++) {
            if (keccak256(abi.encodePacked(modules[i].moduleName)) == keccak256(abi.encodePacked(moduleName))) {
                modules[i] = module;
                added = true;
            }
        }

        if (!added) {
            modules.push(module);

            emit ModuleAdded(moduleAddress, moduleName, moduleVersion);
        }
    }

    /**
    * @dev Removes a module from the contract.
    */
    function removeModule(string memory moduleName) external onlyOwner {
        uint256 index;
        bool found = false;
        for (uint256 i = 0; i < modules.length; i++) {
            if (keccak256(abi.encodePacked(modules[i].moduleName)) == keccak256(abi.encodePacked(moduleName))) {
                index = i;
                found = true;
            }
        }

        if (found) {
            modules[index] = modules[modules.length - 1];
            delete modules[modules.length - 1];
            modules.pop();

            emit ModuleRemoved(moduleName);
        }
    }

    /**
    * @dev Retrieves a 2-tuple (success? + search result) by the given ModuleName.
    */
    function getModule(string memory moduleName) external view returns (bool, Module memory) {
        Module memory result;
        bool found = false;
        for (uint256 i = 0; i < modules.length; i++) {
            if (keccak256(abi.encodePacked(modules[i].moduleName)) == keccak256(abi.encodePacked(moduleName))) {
                result = modules[i];
                found = true;
            }
        }
        return (found, result);
    }

    /**
    * @dev A modifier that requires the message sender to be the owner of the contract or a Module on the contract.
    */
    modifier onlyOwnerOrModule() {
        bool isModule = false;
        for (uint256 i = 0; i < modules.length; i++) {
            if (modules[i].moduleAddress == _msgSender()) {
                isModule = true;
            }
        }

        require(isModule || owner() == _msgSender(), "The caller is not the owner nor an authenticated Avara module!");
        _;
    }

    //
    // BitDuel functions
    //

    /**
    * @dev Occasionally called (only) by the server to make sure that the connection with the contract is granted.
    */
    function ping() external view onlyOwnerOrModule returns (string memory) {
        return _pong;
    }

    /**
    * @dev A function used to withdraw from the player pool.
    */
    function withdraw(uint256 amount) external {
        require(_playerPool[_msgSender()] >= amount, "Invalid amount!");
        _transfer(_playerPoolWallet, _msgSender(), amount);
        _playerPool[_msgSender()] -= amount;
    }

    /**
    * @dev Retrieve the balance of a player from the player pool.
    */
    function balanceInPlayerPool(address playerAddress) external view returns (uint256) {
        return _playerPool[playerAddress];
    }

    /**
    * @dev Called by BitDuel after a won / lost game, to set the new balance of a user in the player pool.
    * The gas price is provided by BitDuel.
    */
    function setPlayerBalance(address playerAddress, uint256 balance) external onlyOwnerOrModule {
        _playerPool[playerAddress] = balance;
    }

    //
    // Reward and Token related functionalities
    //

    struct RewardValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rewardMarketingFee;
        uint256 rewardDeveloperFee;
        uint256 rewardEventFee;
        uint256 rewardBitDuelServiceFee;
    }

    struct TokenValues {
        uint256 tTransferAmount;
        uint256 bitDuelServiceFee;
        uint256 marketingFee;
        uint256 developerFee;
        uint256 eventFee;
    }

    /**
    * @dev Retrieves the Reward equivalent of the given Token amount. (With the Fees optionally included or excluded.)
    */
    function rewardFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _totalSupply, "The amount must be less than the supply!");

        if (!deductTransferFee) {
            uint256 currentRate = _getRate();
            (TokenValues memory tv) = _getTokenValues(tAmount, address(0));
            (RewardValues memory rv) = _getRewardValues(tAmount, tv, currentRate);

            return rv.rAmount;
        } else {
            uint256 currentRate = _getRate();
            (TokenValues memory tv) = _getTokenValues(tAmount, address(0));
            (RewardValues memory rv) = _getRewardValues(tAmount, tv, currentRate);

            return rv.rTransferAmount;
        }
    }

    /**
    * @dev Retrieves the Token equivalent of the given Reward amount.
    */
    function tokenFromReward(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rewardSupply, "The amount must be less than the total rewards!");

        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    /**
    * @dev Excludes an address from the Reward process.
    */
    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "The account is already excluded!");

        if (_rewardOwned[account] > 0) {
            _tokenOwned[account] = tokenFromReward(_rewardOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    /**
    * @dev Includes an address in the Reward process.
    */
    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "The account is already included!");

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tokenOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    /**
    * @dev Retrieves the Total Fees deducted to date.
    */
    function totalFees() public view returns (uint256) {
        return _feeTotal;
    }

    /**
    * @dev Retrieves the Total Marketing Fees deducted to date.
    */
    function totalMarketingFees() public view returns (uint256) {
        return _marketingFeeTotal;
    }

    /**
    * @dev Retrieves the Total Event Fees deducted to date.
    */
    function totalEventFees() public view returns (uint256) {
        return _eventFeeTotal;
    }

    /**
    * @dev Retrieves the Total Development Fees deducted to date.
    */
    function totalDevelopmentFees() public view returns (uint256) {
        return _developerFeeTotal;
    }

    /**
    * @dev Retrieves the Total BitDuel Service Fees deducted to date.
    */
    function totalBitDuelServiceFees() public view returns (uint256) {
        return _bitDuelServiceFeeTotal;
    }

    /**
    * @dev Excludes an address from the Fee process.
    */
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    /**
    * @dev Includes an address in the Fee process.
    */
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    /**
    * @dev Sets the given address as the Developer Wallet.
    */
    function setDevWallet(address devWallet) external onlyOwner {
        address oldAddress = _devWallet;
        _isExcludedFromFee[oldAddress] = false;
        _devWallet = devWallet;
        _isExcludedFromFee[_devWallet] = true;

        emit DevWalletChanged(oldAddress, _devWallet);
    }

    /**
    * @dev Sets the given address as the Player Pool Hot Wallet.
    */
    function setPlayerPoolWallet(address playerPoolWallet) external onlyOwner {
        address oldAddress = _playerPoolWallet;
        _playerPoolWallet = playerPoolWallet;

        emit PlayerPoolChanged(oldAddress, _playerPoolWallet);
    }

    /**
    * @dev Sets the Marketing Fee percentage.
    */
    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner {
        require(marketingFee.add(_developerFee).add(_eventFee) <= MAX_TOTAL_FEE, "Too high fees!");
        require(marketingFee.add(_developerFee).add(_eventFee).mul(_sellPressureReductor).div(10 ** uint256(_sellPressureReductorDecimals)) <= MAX_TOTAL_FEE, "Too harsh sell pressure reductor!");

        uint256 oldFee = _marketingFee;
        _marketingFee = marketingFee;

        emit MarketingFeeChanged(oldFee, _marketingFee);
    }

    /**
    * @dev Sets the Developer Fee percentage.
    */
    function setDeveloperFeePercent(uint256 developerFee) external onlyOwner {
        require(developerFee.add(_marketingFee).add(_eventFee) <= MAX_TOTAL_FEE, "Too high fees!");
        require(developerFee.add(_marketingFee).add(_eventFee).mul(_sellPressureReductor).div(10 ** uint256(_sellPressureReductorDecimals)) <= MAX_TOTAL_FEE, "Too harsh sell pressure reductor!");

        uint256 oldFee = _developerFee;
        _developerFee = developerFee;

        emit DeveloperFeeChanged(oldFee, _developerFee);
    }

    /**
    * @dev Sets the BitDuel Service Fee percentage.
    */
    function setBitDuelServiceFeePercent(uint256 bitDuelServiceFee) external onlyOwner {
        require(bitDuelServiceFee <= MAX_TOTAL_FEE, "Too high fee!");

        uint256 oldFee = _bitDuelServiceFee;
        _bitDuelServiceFee = bitDuelServiceFee;

        emit BitDuelServiceFeeChanged(oldFee, _bitDuelServiceFee);
    }

    /**
    * @dev Sets the Event Fee percentage.
    */
    function setEventFeePercent(uint256 eventFee) external onlyOwner {
        require(eventFee.add(_marketingFee).add(_developerFee) <= MAX_TOTAL_FEE, "Too high fees!");
        require(eventFee.add(_marketingFee).add(_developerFee).mul(_sellPressureReductor).div(10 ** uint256(_sellPressureReductorDecimals)) <= MAX_TOTAL_FEE, "Too harsh sell pressure reductor!");

        uint256 oldFee = _eventFee;
        _eventFee = eventFee;

        emit EventFeeChanged(oldFee, _eventFee);
    }

    /**
    * @dev Sets the value of the Sell Pressure Reductor.
    */
    function setSellPressureReductor(uint256 reductor) external onlyOwner {
        require(_eventFee.add(_marketingFee).add(_developerFee).mul(reductor).div(10 ** uint256(_sellPressureReductorDecimals)) <= MAX_TOTAL_FEE, "Too harsh sell pressure reductor!");

        uint256 oldReductor = _sellPressureReductor;
        _sellPressureReductor = reductor;

        emit SellPressureReductorChanged(oldReductor, _sellPressureReductor);
    }

    /**
    * @dev Sets the decimal points of the Sell Pressure Reductor.
    */
    function setSellPressureReductorDecimals(uint8 reductorDecimals) external onlyOwner {
        require(_eventFee.add(_marketingFee).add(_developerFee).mul(_sellPressureReductor).div(10 ** uint256(reductorDecimals)) <= MAX_TOTAL_FEE, "Too harsh sell pressure reductor!");

        uint8 oldReductorDecimals = _sellPressureReductorDecimals;
        _sellPressureReductorDecimals = reductorDecimals;

        emit SellPressureReductorDecimalsChanged(oldReductorDecimals, _sellPressureReductorDecimals);
    }

    /**
    * @dev Sets the maximum transaction amount. (calculated by the given percentage)
    */
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        uint256 oldAmount = _maxTxAmount;
        _maxTxAmount = _totalSupply.mul(maxTxPercent).div(100);

        emit MaxTransactionAmountChanged(oldAmount, _maxTxAmount);
    }

    /**
    * @dev Sets the value of the `_rewardEnabled` variable.
    */
    function setRewardEnabled(bool enabled) external onlyOwner {
        bool oldState = _rewardEnabled;
        _rewardEnabled = enabled;

        emit RewardEnabledStateChanged(oldState, _rewardEnabled);
    }

    /**
    * @dev Retrieves if the given address is excluded from the Fee process.
    */
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    /**
    * @dev Retrieves if the given address is excluded from the Reward process.
    */
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    /**
    * @dev Sets the given address as the Uniswap Router.
    */
    function setUniswapRouter(address r) external onlyOwner {
        address oldRouter = address(_uniswapV3Router);
        _uniswapV3Router = IUniswapV3Router(r);

        emit UniswapRouterChanged(oldRouter, address(_uniswapV3Router));
    }

    /**
    * @dev Sets the given address as the Uniswap Pool.
    */
    function setUniswapPool(address p) external onlyOwner {
        address oldPool = address(_uniswapV3Pool);
        _uniswapV3Pool = IUniswapV3Pool(p);

        emit UniswapPoolChanged(oldPool, address(_uniswapV3Pool));
    }

    //
    // The Implementation of the IERC20 Functions
    //

    /**
    * @dev A function used to retrieve the stuck eth from the contract.
    */
    function unstickEth(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Invalid amount!");
        payable(_msgSender()).transfer(amount);
    }

    /**
    * @dev A function used to retrieve the stuck tokens from the contract.
    */
    function unstickTokens(uint256 amount) external onlyOwner {
        require(balanceOf(address(this)) >= amount, "Invalid amount!");
        _transfer(address(this), _msgSender(), amount);
    }

    /**
    * @dev Retrieves the Total Supply of the token.
    */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Retrieves the Name of the token.
    */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
    * @dev Retrieves the Symbol of the token.
    */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Retrieves the Decimals of the token.
    */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
    * @dev Retrieves the Balance Of the given address.
    * Note: If the address is included in the Reward process, retrieves the Token equivalent of the held Reward amount.
    */
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tokenOwned[account];
        return tokenFromReward(_rewardOwned[account]);
    }

    /**
    * @dev Transfers the given Amount of tokens (minus the fees, if any) from the
    * Message Senders wallet to the Recipients wallet.
    *
    * Note: If the Recipient is the Player Pool Hot Wallet, the Message Sender will be able to play with
    * the transferred amount of Tokens on BitDuel.
    */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        if (recipient == _playerPoolWallet) {
            _playerPool[_msgSender()] += _transfer(_msgSender(), recipient, amount);
        } else {
            _transfer(_msgSender(), recipient, amount);
        }
        return true;
    }

    /**
    * @dev Retrieves the Allowance of the given Spender address in the given Owner wallet.
    */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
    * @dev Approves the given amount for the given Spender address in the Message Sender wallet.
    */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
    * @dev Transfers the given Amount of tokens from the Sender to the Recipient address
    * if the Sender approved on the Message Sender allowances.
    */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: The transfer amount exceeds the allowance."));
        return true;
    }

    //
    // Transfer and Approval processes
    //

    /**
    * @dev Approves the given amount for the given Spender address in the Owner wallet.
    */
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: Cannot approve from the zero address.");
        require(spender != address(0), "ERC20: Cannot approve to the zero address.");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Transfers from and to the given address the given amount of token.
     */
    function _transfer(address from, address to, uint256 amount) private returns (uint256) {
        require(from != address(0), "ERC20: Cannot transfer from the zero address.");
        require(to != address(0), "ERC20: Cannot transfer to the zero address.");
        require(amount > 0, "The transfer amount must be greater than zero!");

        if (from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "The transfer amount exceeds the maxTxAmount.");
        }

        bool takeFee = !(_isExcludedFromFee[from] || _isExcludedFromFee[to] || from == _playerPoolWallet);
        return _tokenTransfer(from, to, amount, takeFee);
    }

    /**
    * @dev Transfers the given Amount of tokens (minus the fees, if any) from the
    * Senders wallet to the Recipients wallet.
    */
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private returns (uint256) {
        uint256 previousBitDuelServiceFee = _bitDuelServiceFee;
        uint256 previousDeveloperFee = _developerFee;
        uint256 previousEventFee = _eventFee;
        uint256 previousMarketingFee = _marketingFee;

        if (!takeFee) {
            _bitDuelServiceFee = 0;
            _developerFee = 0;
            _eventFee = 0;
            _marketingFee = 0;
        }

        uint256 transferredAmount;
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            transferredAmount = _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            transferredAmount = _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            transferredAmount = _transferBothExcluded(sender, recipient, amount);
        } else {
            transferredAmount = _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) {
            _bitDuelServiceFee = previousBitDuelServiceFee;
            _developerFee = previousDeveloperFee;
            _eventFee = previousEventFee;
            _marketingFee = previousMarketingFee;
        }

        return transferredAmount;
    }

    /**
    * @dev The Transfer function used when both the Sender and Recipient is included in the Reward process.
    */
    function _transferStandard(address sender, address recipient, uint256 tAmount) private returns (uint256) {
        uint256 currentRate = _getRate();
        (TokenValues memory tv) = _getTokenValues(tAmount, recipient);
        (RewardValues memory rv) = _getRewardValues(tAmount, tv, currentRate);

        _rewardOwned[sender] = _rewardOwned[sender].sub(rv.rAmount);
        _rewardOwned[recipient] = _rewardOwned[recipient].add(rv.rTransferAmount);

        takeTransactionFee(_devWallet, tv, currentRate, recipient);
        if (_rewardEnabled) {
            _rewardFee(rv);
        }
        _countTotalFee(tv);
        emit Transfer(sender, recipient, tv.tTransferAmount);

        return tv.tTransferAmount;
    }

    /**
    * @dev The Transfer function used when both the Sender and Recipient is excluded from the Reward process.
    */
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private returns (uint256) {
        uint256 currentRate = _getRate();
        (TokenValues memory tv) = _getTokenValues(tAmount, recipient);
        (RewardValues memory rv) = _getRewardValues(tAmount, tv, currentRate);

        _tokenOwned[sender] = _tokenOwned[sender].sub(tAmount);
        _rewardOwned[sender] = _rewardOwned[sender].sub(rv.rAmount);
        _tokenOwned[recipient] = _tokenOwned[recipient].add(tv.tTransferAmount);
        _rewardOwned[recipient] = _rewardOwned[recipient].add(rv.rTransferAmount);

        takeTransactionFee(_devWallet, tv, currentRate, recipient);
        if (_rewardEnabled) {
            _rewardFee(rv);
        }
        _countTotalFee(tv);
        emit Transfer(sender, recipient, tv.tTransferAmount);

        return tv.tTransferAmount;
    }

    /**
    * @dev The Transfer function used when the Sender is included and the Recipient is excluded in / from the Reward process.
    */
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private returns (uint256) {
        uint256 currentRate = _getRate();
        (TokenValues memory tv) = _getTokenValues(tAmount, recipient);
        (RewardValues memory rv) = _getRewardValues(tAmount, tv, currentRate);

        _rewardOwned[sender] = _rewardOwned[sender].sub(rv.rAmount);
        _tokenOwned[recipient] = _tokenOwned[recipient].add(tv.tTransferAmount);
        _rewardOwned[recipient] = _rewardOwned[recipient].add(rv.rTransferAmount);

        takeTransactionFee(_devWallet, tv, currentRate, recipient);
        if (_rewardEnabled) {
            _rewardFee(rv);
        }
        _countTotalFee(tv);
        emit Transfer(sender, recipient, tv.tTransferAmount);

        return tv.tTransferAmount;
    }

    /**
    * @dev The Transfer function used when the Sender is excluded and the Recipient is included from / in the Reward process.
    */
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private returns (uint256) {
        uint256 currentRate = _getRate();
        (TokenValues memory tv) = _getTokenValues(tAmount, recipient);
        (RewardValues memory rv) = _getRewardValues(tAmount, tv, currentRate);

        _tokenOwned[sender] = _tokenOwned[sender].sub(tAmount);
        _rewardOwned[sender] = _rewardOwned[sender].sub(rv.rAmount);
        _rewardOwned[recipient] = _rewardOwned[recipient].add(rv.rTransferAmount);

        takeTransactionFee(_devWallet, tv, currentRate, recipient);
        if (_rewardEnabled) {
            _rewardFee(rv);
        }
        _countTotalFee(tv);
        emit Transfer(sender, recipient, tv.tTransferAmount);

        return tv.tTransferAmount;
    }

    /**
    * @dev Takes the Reward Fees from the Reward Supply.
    */
    function _rewardFee(RewardValues memory rv) private {
        _rewardSupply = _rewardSupply.sub(rv.rewardMarketingFee).sub(rv.rewardDeveloperFee).sub(rv.rewardEventFee).sub(rv.rewardBitDuelServiceFee);
    }

    /**
    * @dev Updates the Fee Counters by the Taken Fees.
    */
    function _countTotalFee(TokenValues memory tv) private {
        _marketingFeeTotal = _marketingFeeTotal.add(tv.marketingFee);
        _developerFeeTotal = _developerFeeTotal.add(tv.developerFee);
        _eventFeeTotal = _eventFeeTotal.add(tv.eventFee);
        _bitDuelServiceFeeTotal = _bitDuelServiceFeeTotal.add(tv.bitDuelServiceFee);
        _feeTotal = _feeTotal.add(tv.marketingFee).add(tv.developerFee).add(tv.eventFee).add(tv.bitDuelServiceFee);
    }

    /**
    * @dev Calculates the Token Values after taking the Fees.
    */
    function _getTokenValues(uint256 tAmount, address recipient) private view returns (TokenValues memory) {
        TokenValues memory tv;
        uint256 tTransferAmount = tAmount;

        if (recipient == _playerPoolWallet) {
            uint256 bitDuelServiceFee = tAmount.mul(_bitDuelServiceFee).div(10000);
            tTransferAmount = tTransferAmount.sub(bitDuelServiceFee);

            tv.tTransferAmount = tTransferAmount;
            tv.bitDuelServiceFee = bitDuelServiceFee;

            return (tv);
        }

        uint256 marketingFee = tAmount.mul(_marketingFee).div(10000);
        uint256 developerFee = tAmount.mul(_developerFee).div(10000);
        uint256 eventFee = tAmount.mul(_eventFee).div(10000);

        if (recipient == address(_uniswapV3Pool)) {
            marketingFee = marketingFee.mul(_sellPressureReductor).div(10 ** uint256(_sellPressureReductorDecimals));
            developerFee = developerFee.mul(_sellPressureReductor).div(10 ** uint256(_sellPressureReductorDecimals));
            eventFee = eventFee.mul(_sellPressureReductor).div(10 ** uint256(_sellPressureReductorDecimals));
        }

        tTransferAmount = tTransferAmount.sub(marketingFee).sub(developerFee).sub(eventFee);

        tv.tTransferAmount = tTransferAmount;
        tv.marketingFee = marketingFee;
        tv.developerFee = developerFee;
        tv.eventFee = eventFee;

        return (tv);
    }

    /**
    * @dev Calculates the Reward Values after taking the Fees.
    */
    function _getRewardValues(uint256 tAmount, TokenValues memory tv, uint256 currentRate) private pure returns (RewardValues memory) {
        RewardValues memory rv;

        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rewardBitDuelServiceFee = tv.bitDuelServiceFee.mul(currentRate);
        uint256 rewardMarketingFee = tv.marketingFee.mul(currentRate);
        uint256 rewardDeveloperFee = tv.developerFee.mul(currentRate);
        uint256 rewardEventFee = tv.eventFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rewardMarketingFee).sub(rewardDeveloperFee).sub(rewardEventFee).sub(rewardBitDuelServiceFee);

        rv.rAmount = rAmount;
        rv.rTransferAmount = rTransferAmount;
        rv.rewardBitDuelServiceFee = rewardBitDuelServiceFee;
        rv.rewardMarketingFee = rewardMarketingFee;
        rv.rewardDeveloperFee = rewardDeveloperFee;
        rv.rewardEventFee = rewardEventFee;

        return (rv);
    }

    /**
    * @dev Retrieves the Rate between the Reward and Token Supply.
    */
    function _getRate() private view returns (uint256) {
        (uint256 rewardSupply, uint256 tokenSupply) = _getCurrentSupply();
        return rewardSupply.div(tokenSupply);
    }

    /**
    * @dev Retrieves the current Reward and Token Supply.
    */
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rewardSupply = _rewardSupply;
        uint256 tokenSupply = _totalSupply;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rewardOwned[_excluded[i]] > rewardSupply || _tokenOwned[_excluded[i]] > tokenSupply) return (_rewardSupply, _totalSupply);
            rewardSupply = rewardSupply.sub(_rewardOwned[_excluded[i]]);
            tokenSupply = tokenSupply.sub(_tokenOwned[_excluded[i]]);
        }
        if (rewardSupply < _rewardSupply.div(_totalSupply)) return (_rewardSupply, _totalSupply);
        return (rewardSupply, tokenSupply);
    }

    /**
    * @dev Takes the given Fees.
    */
    function takeTransactionFee(address to, TokenValues memory tv, uint256 currentRate, address recipient) private {
        uint256 totalFee = recipient == _playerPoolWallet ? (tv.bitDuelServiceFee) : (tv.marketingFee + tv.developerFee + tv.eventFee);

        if (totalFee <= 0) {return;}

        uint256 rAmount = totalFee.mul(currentRate);
        _rewardOwned[to] = _rewardOwned[to].add(rAmount);
        if (_isExcluded[to]) {
            _tokenOwned[to] = _tokenOwned[to].add(totalFee);
        }
    }
}


abstract contract AvaraModule is Ownable {

    Avara private _baseContract;
    string private _moduleName;
    string private _moduleVersion;

    constructor(address cOwner, address baseContract, string memory name, string memory version) Ownable(cOwner) {
        _baseContract = Avara(payable(baseContract));
        require(_baseContract.owner() == cOwner, "The module deployer must be the owner of the base contract!");

        _moduleName = name;
        _moduleVersion = version;
    }

    /**
     * @dev Returns the module name.
     */
    function moduleName() external view returns (string memory) {
        return _moduleName;
    }

    /**
     * @dev Returns the module version.
     */
    function moduleVersion() external view returns (string memory) {
        return _moduleVersion;
    }

    /**
     * @dev Returns the base contract.
     */
    function getBaseContract() internal view returns (Avara) {
        return _baseContract;
    }

}

contract BitDuelModule is AvaraModule {
    using SafeMath for uint256;

    mapping(address => bool) public _isGameMaster;

    event GameMasterAdded(address gmAddress);
    event GameMasterRemoved(address gmAddress);
    event PlayerMigrated(address oldAddress, address newAddress);
    event PlayerBalanceChangedByGM(address gmAddress, address playerAddress, uint256 oldBalance, uint256 newBalance, string action);

    constructor(address cOwner, address baseContract) AvaraModule(cOwner, baseContract, "BitDuel", "0.0.2") {
        _isGameMaster[cOwner] = true;
    }

    modifier onlyGM() {
        require(_isGameMaster[_msgSender()], "The caller is not a Game Master!");
        _;
    }

    /**
    * @dev Occasionally called (only) by the server to make sure that the connection with the module and main contract is granted.
    */
    function ping() external view onlyOwner returns (string memory) {
        return getBaseContract().ping();
    }

    /**
    * @dev Called by a BitDuel GM after a won / lost game, to add to the balance of a user in the player pool.
    * The gas price is provided by BitDuel.
    */
    function addToPlayerBalance(address playerAddress, uint256 amount) external onlyGM {
        uint256 oldBalance = getBaseContract().balanceInPlayerPool(playerAddress);
        uint256 newBalance = oldBalance + amount;

        getBaseContract().setPlayerBalance(playerAddress, newBalance);

        emit PlayerBalanceChangedByGM(_msgSender(), playerAddress, oldBalance, newBalance, "Add");
    }

    /**
    * @dev Called by a BitDuel GM after a won / lost game, to deduct from the balance of a user in the player pool.
    * The gas price is provided by BitDuel.
    */
    function deductFromPlayerBalance(address playerAddress, uint256 amount) external onlyGM {
        require(amount <= getBaseContract().balanceInPlayerPool(playerAddress), "Insufficient funds!");

        uint256 oldBalance = getBaseContract().balanceInPlayerPool(playerAddress);
        uint256 newBalance = oldBalance - amount;

        getBaseContract().setPlayerBalance(playerAddress, newBalance);

        emit PlayerBalanceChangedByGM(_msgSender(), playerAddress, oldBalance, newBalance, "Deduct");
    }

    /**
    * @dev Called by BitDuel to migrate the user onto another address.
    */
    function migratePlayerToAddress(address from, address newAddress) external {
        require(_msgSender() == from || _msgSender() == owner(), "Invalid old address!");
        getBaseContract().setPlayerBalance(newAddress, getBaseContract().balanceInPlayerPool(newAddress) + getBaseContract().balanceInPlayerPool(from));
        getBaseContract().setPlayerBalance(from, uint256(0));

        emit PlayerMigrated(from, newAddress);
    }

    /**
    * @dev Called by BitDuel to add an address to the Game Masters.
    */
    function addGameMaster(address gmAddress) public onlyOwner {
        require(!_isGameMaster[gmAddress], "The address is already a Game Master!");
        _isGameMaster[gmAddress] = true;

        emit GameMasterAdded(gmAddress);
    }

    /**
    * @dev Called by BitDuel to remove an address from the Game Masters.
    */
    function removeGameMaster(address gmAddress) public onlyOwner {
        require(_isGameMaster[gmAddress], "The address is not a Game Master!");
        _isGameMaster[gmAddress] = false;

        emit GameMasterRemoved(gmAddress);
    }

}