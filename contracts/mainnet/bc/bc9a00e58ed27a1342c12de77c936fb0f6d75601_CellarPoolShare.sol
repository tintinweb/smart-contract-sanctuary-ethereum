/**
 *Submitted for verification at Etherscan.io on 2022-02-02
*/

// SPDX-License-Identifier: Apache-2.0
// VolumeFi Software, Inc.

pragma solidity 0.8.11;

/// Imported from Openzeppelin

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
}

/// Imported from Uniswap V3

interface INonfungiblePositionManager {

    /**
     * @notice The struct to mint a position
     * @member token0 The address of the token0 for a specific pool
     * @member token1 The address of the token1 for a specific pool
     * @member fee The fee associated with the pool
     * @member tickLower The lower end of the tick range for the position
     * @member tickUpper The higher end of the tick range for the position
     * @member amount0Desired The desired amount of token0 to be spent
     * @member amount1Desired The desired amount of token1 to be spent
     * @member amount0Min The minimum amount of token0 to spend, which serves as a slippage check
     * @member amount1Min The minimum amount of token1 to spend, which serves as a slippage check
     * @member recipient The account that should receive the tokens
     * @member deadline The time by which the transaction must be included to effect the change
     */
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /**
     * @notice The struct to increase liquidity of a position
     * @member tokenId The ID of the token for which liquidity is being increased
     * @member amount0Desired The desired amount of token0 to be spent
     * @member amount1Desired The desired amount of token1 to be spent
     * @member amount0Min The minimum amount of token0 to spend, which serves as a slippage check
     * @member amount1Min The minimum amount of token1 to spend, which serves as a slippage check
     * @member deadline The time by which the transaction must be included to effect the change
     */
    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /**
     * @notice The struct to decrease liquidity of a position
     * @member tokenId The ID of the token for which liquidity is being decreased
     * @member liquidity The amount by which liquidity will be decreased
     * @member amount0Min The minimum amount of token0 that should be accounted for the burned liquidity
     * @member amount1Min The minimum amount of token1 that should be accounted for the burned liquidity
     * @member deadline The time by which the transaction must be included to effect the change
     */
    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /**
     * @notice The struct to decrease liquidity of a position
     * @member tokenId The ID of the NFT for which tokens are being collected
     * @member recipient The account that should receive the tokens
     * @member amount0Min The minimum amount of token0 that should be accounted for the burned liquidity
     * @member amount1Min The minimum amount of token1 that should be accounted for the burned liquidity
     * @member deadline The time by which the transaction must be included to effect the change
     */
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params The params necessary to increase liquidity of a position,
    /// encoded as `IncreaseLiquidityParams` in calldata
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params The params necessary to decrease liquidity of a position
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params The params necessary to collect fee
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

/// Imported from Uniswap V3

interface ISwapRouter {
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

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}

/// Imported from Uniswap V3

interface IUniswapV3Factory {
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
}

/// Imported from Uniswap V3

interface IUniswapV3Pool {
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
}

/// Imported from Openzeppelin

library Address {
    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html
     * ?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "A");//"Address: low-level call failed"
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "B"//"Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "C"//"insufficient balance for call"
        );
        require(isContract(target), "D");//"Address: call to non-contract"

        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

/// Imported from Openzeppelin

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "E"//"approve non-zero to non-zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
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
        bytes memory returndata =
            address(token).functionCall(
                data,
                "F"//"SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                "G"//"ERC20 operation did not succeed"
            );
        }
    }
}

/// Imported from Uniswap V3

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

/// Imported from Uniswap V3

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
        unchecked{
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
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;

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
}

/// Imported from Uniswap V3

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;

    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick)
        internal
        pure
        returns (uint160 sqrtPriceX96)
    {
        unchecked{
            uint256 absTick =
                tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            require(absTick <= uint256(int256(MAX_TICK)), "H");

            uint256 ratio =
                absTick & 0x1 != 0
                    ? 0xfffcb933bd6fad37aa2d162d1a594001
                    : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0)
                ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0)
                ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0)
                ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0)
                ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0)
                ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0)
                ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0)
                ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0)
                ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0)
                ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0)
                ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0)
                ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0)
                ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0)
                ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0)
                ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0)
                ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0)
                ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0)
                ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0)
                ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0)
                ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160(
                (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
            );
        }
    }
}

/// Imported from Uniswap V3

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate =
            FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return
            toUint128(
                FullMath.mulDiv(
                    amount0,
                    intermediate,
                    sqrtRatioBX96 - sqrtRatioAX96
                )
            );
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return
            toUint128(
                FullMath.mulDiv(
                    amount1,
                    FixedPoint96.Q96,
                    sqrtRatioBX96 - sqrtRatioAX96
                )
            );
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount0
            );
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 =
                getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 =
                getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount1
            );
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

/// @title interface for CellarPoolShare
/// @author Steven Jung
interface ICellarPoolShare is IERC20 {

    /// @notice Result from mint or add liquidity in Uniswap V3
    /// @dev Used for decrease local memory variables.
    /// @member tokenId minted tokenId
    /// @member liquidity minted liquidity
    /// @member amount0 added amount of token0 into liquidity
    /// @member amount1 added amount of token1 into liquidity
    struct MintResult {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0;
        uint256 amount1;
    }

    /**
     * @notice The struct to increase liquidity of a position
     * @member amount0Desired The desired amount of token0 to be spent
     * @member amount1Desired The desired amount of token1 to be spent
     * @member amount0Min The minimum amount of token0 to spend, which serves as a slippage check
     * @member amount1Min The minimum amount of token1 to spend, which serves as a slippage check
     * @member deadline The time by which the transaction must be included to effect the change
     */
    struct CellarAddParams {
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /**
     * @notice The struct to decrease liquidity of a position
     * @member tokenAmount The amount of cellar token amount by which liquidity will be decreased
     * @member amount0Min The minimum amount of token0 that should be accounted for the burned liquidity
     * @member amount1Min The minimum amount of token1 that should be accounted for the burned liquidity
     * @member deadline The time by which the transaction must be included to effect the change
     */
    struct CellarRemoveParams {
        uint256 tokenAmount;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /**
     * @notice The struct to decrease liquidity of a position
     * @member tokenId The tokenId of Uniswap V3 NFLP
     * @member tickUpper The higher end of the tick range for the position
     * @member tickLower The lower end of the tick range for the position
     * @member weight The weight of the current Tick in cellar
     */
    struct CellarTickInfo {
        uint184 tokenId;
        int24 tickUpper;
        int24 tickLower;
        uint24 weight;
    }

    /// @notice Used for decrease local memory variables.
    struct UintPair {
        uint256 a;
        uint256 b;
    }

    /**
     * @notice Used for decrease local memory variables.
     * @member collect0 collected token0
     * @member collect1 collected token1
     * @member management0 management fee of token0
     * @member management1 management fee of token1
     * @member performance0 performance fee of token0
     * @member performance1 performance fee of token1
     */
    struct CellarFees {
        uint256 collect0;
        uint256 collect1;
        uint256 management0;
        uint256 management1;
        uint256 performance0;
        uint256 performance1;
    }
 
    /// @notice Emitted when liquidity is increased for cellar
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event AddedLiquidity(
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when liquidity is decreased from cellar
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was collected from the decrease in liquidity
    /// @param amount1 The amount of token1 that was collected from the decrease in liquidity
    event RemovedLiquidity(
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when reinvest swap fees into cellar for checking fees
    /// @param fees0 collected token0
    /// @param fees1 collected token1
    /// @param managementFee0 management fee of token0
    /// @param managementFee1 management fee of token1
    /// @param performanceFee0 performance fee of token0
    /// @param performanceFee1 performance fee of token1
    /// @param amount0 invested amount into liquidity of token0
    /// @param amount1 invested amount into liquidity of token1
    event Reinvest (
        uint256 fees0,
        uint256 fees1,
        uint256 managementFee0,
        uint256 managementFee1,
        uint256 performanceFee0,
        uint256 performanceFee1,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when rebalance ticks of cellar for checking fees
    /// @param fees0 collected token0
    /// @param fees1 collected token1
    /// @param managementFee0 management fee of token0
    /// @param managementFee1 management fee of token1
    /// @param performanceFee0 performance fee of token0
    /// @param performanceFee1 performance fee of token1
    /// @param amount0 invested amount into liquidity of token0
    /// @param amount1 invested amount into liquidity of token1
    event Rebalance (
        uint256 fees0,
        uint256 fees1,
        uint256 managementFee0,
        uint256 managementFee1,
        uint256 performanceFee0,
        uint256 performanceFee1,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when update validator setting
    /// @param validator validator address to add or remove
    /// @param value true to add, false to remove
    event SetValidator (
        address validator,
        bool value
    );

    event SetAdjuster (
        address adjuster,
        bool value
    );

    /// @notice Emitted when transfer ownership
    /// @param newOwner new owner address
    event TransferOwnership (
        address newOwner
    );

    /// @notice Emitted when update performance fee
    /// @param newFee new performance fee
    event SetPerformanceFee (
        uint256 newFee
    );

    /// @notice Emitted when update performance fee
    /// @param newFee new performance fee
    event SetManagementFee (
        uint256 newFee
    );

    error Stopped();
    error NotWorking();
    error NotPaused();
    error OverDeposit();
    error UnsortedTokens();
    error ZeroWeight();
    error NonEmptyTokenId();
    error WrongTickTier();
    error NonPermission();
    error Reentrance();
    error InsufficientAmount();
    error HighSlippage();
    error InvalidTokenId();
    error InvalidInput();
    error TransferToZeroAddress();
    error TransferFromZeroAddress();
    error MintToZeroAddress();
    error BurnFromZeroAddress();
    error ApproveToZeroAddress();
    error ApproveFromZeroAddress();

    /// @notice Adding Liquidity For Uniswap V3 NFLP
    /// @param cellarParams parameter for adding liquidity
    function addLiquidityForUniV3(CellarAddParams calldata cellarParams)
        external
        payable;

    /// @notice Adding Liquidity For Uniswap V3 NFLP
    /// @param cellarParams parameter for removing liquidity
    function removeLiquidityFromUniV3(CellarRemoveParams calldata cellarParams)
        external;

    /// @notice Update cellar tick info
    /// @param _cellarTickInfo new tick tier information
    function rebalance(CellarTickInfo[] memory _cellarTickInfo, uint256 currentPrice) external;

    /// @notice collect fee and reinvest in liquidity
    function reinvest(uint256 currentPriceX96) external;

    /// @notice set validator
    /// @param _validator address to add or remove from validator list
    /// @param value add/remove option
    function setValidator(address _validator, bool value) external;

    /// @notice set adjuster
    /// @param _adjuster address to add or remove from adjuster list
    /// @param value add/remove option
    function setAdjuster(address _adjuster, bool value) external;

    /// @notice transfer ownership to new address
    /// @param newOwner address of new owner
    function transferOwnership(address newOwner) external;

    /// @notice update management fee
    /// @param newFee new management fee value
    function setManagementFee(uint256 newFee) external;

    /// @notice update performance fee
    /// @param newFee new performance fee value
    function setPerformanceFee(uint256 newFee) external;

    /**
     * @dev Returns owner address
     */
    function owner() external view returns (address);

    /**
     * @dev Returns name of the token as ERC20
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns symbol of the token as ERC20
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns cellar tick info struct array
     */
    function getCellarTickInfo() external view returns (CellarTickInfo[] memory);

    /**
     * @dev Returns decimals of the token as ERC20
     */
    function decimals() external pure returns (uint8);
}

interface IWETH {

    /**
     * @dev wrap ETH into WETH
     */
    function deposit() external payable;

    /**
     * @dev unwrap WETH into ETH
     */
    function withdraw(uint256) external;
}

/// @title BlockLock base contract to prevent flash loan attack
contract BlockLock {
    error Locked();
    // how many blocks are the functions locked for
    uint256 private constant BLOCK_LOCK_COUNT = 1;
    // last block for which this address is timelocked
    mapping(address => uint256) public lastLockedBlock;
    // modifier to prevent flash loan attack
    modifier notLocked(address lockedAddress) {
        if (lastLockedBlock[lockedAddress] > block.number) revert Locked();
        lastLockedBlock[lockedAddress] = block.number + BLOCK_LOCK_COUNT;
        _;
    }
}

/// @notice AggregatorV3Interface from Chainlink token price oracle
interface AggregatorV3Interface {
    /**
     * @dev get token price from chainlink price oracle
     */
    function latestAnswer() external view returns(int256);
}


/**
 * @title Sommelier Cellar Pool Share contract
 * @notice Main Cellar Pool share contract for Sommelier Network
 * @author VolumeFi Software
 */

contract CellarPoolShare is ICellarPoolShare, BlockLock {

    enum Status {
        Working,
        Paused,
        Stopped
    }

    using SafeERC20 for IERC20;

    // Set the Uniswap V3 contract Addresses.
    address private constant _NONFUNGIBLEPOSITIONMANAGER = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    address private constant _UNISWAPV3FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    address private constant _SWAPROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    address private constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 private constant _DOMINATOR = 10000;

    uint256 private constant _YEAR = 31556952;

    uint256 private constant _TOLERANCE = 25; // 0.5% slippage -> 1.0025 tolerance of sqrtPrice

    // Declare the variables and mappings
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public validator;

    mapping(address => bool) public adjuster;

    uint256 private _totalSupply;
    address private _owner;
    bool private _isEntered;
    Status public status;
    string private _name;
    string private _symbol;

    address public immutable token0;
    address public immutable token1;
    uint24 public immutable feeLevel;
    CellarTickInfo[] public cellarTickInfo;
    uint256 public lastManageTimestamp;
    uint256 public performanceFee = 0;
    uint256 public managementFee = 0;


    modifier onlyOwner() {
        if (msg.sender != _owner) revert NonPermission();
        _;
    }

    modifier onlyValidator() {
        if (!validator[msg.sender]) revert NonPermission();
        _;
    }

    modifier nonReentrant() {
        if (_isEntered) revert Reentrance();
        _isEntered = true;
        _;
        _isEntered = false;
    }

    /**
     * @notice Create the constructor that identifies 
     * the toke names, symbols, and address for each token 
     * pair of any Uniswap v3 AMM
     */

    constructor(
        string memory name_,
        string memory symbol_,
        address _token0,
        address _token1,
        uint24 _feeLevel,
        CellarTickInfo[] memory _cellarTickInfo
    ) {
        _name = name_;
        _symbol = symbol_;
        if (_token0 >= _token1) {
            revert UnsortedTokens();
        }
        token0 = _token0;
        token1 = _token1;
        feeLevel = _feeLevel;
        for (uint256 i = 0; i < _cellarTickInfo.length; i++) {
            if (_cellarTickInfo[i].weight == 0) revert ZeroWeight();
            if (_cellarTickInfo[i].tokenId != 0) revert NonEmptyTokenId();
            if (_cellarTickInfo[i].tickUpper <= _cellarTickInfo[i].tickLower) revert WrongTickTier();
            if (i > 0) {
                if (_cellarTickInfo[i].tickUpper > _cellarTickInfo[i - 1].tickLower) revert WrongTickTier();
            }
            cellarTickInfo.push(
                CellarTickInfo({
                    tokenId: 0,
                    tickUpper: _cellarTickInfo[i].tickUpper,
                    tickLower: _cellarTickInfo[i].tickLower,
                    weight: _cellarTickInfo[i].weight
                })
            );
        }
        lastManageTimestamp = block.timestamp;
        _owner = msg.sender;
        validator[msg.sender] = true;
        adjuster[msg.sender] = true;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function addLiquidityForUniV3(CellarAddParams calldata cellarParams)
        external
        payable
        override
        nonReentrant
        notLocked(msg.sender)
    {
        if (status != Status.Working) {
            revert NotWorking();
        }
        if (token0 == _WETH) {
            if (msg.value >= cellarParams.amount0Desired) {
                if (msg.value > cellarParams.amount0Desired) {
                    payable(msg.sender).transfer(
                        msg.value - cellarParams.amount0Desired
                    );
                }
                IWETH(_WETH).deposit{value: cellarParams.amount0Desired}();
            } else {
                IERC20(_WETH).safeTransferFrom(
                    msg.sender,
                    address(this),
                    cellarParams.amount0Desired
                );
                if (msg.value > 0) {
                    payable(msg.sender).transfer(msg.value);
                }
            }
            IERC20(token1).safeTransferFrom(
                msg.sender,
                address(this),
                cellarParams.amount1Desired
            );
        } else if (token1 == _WETH) {
            if (msg.value >= cellarParams.amount1Desired) {
                if (msg.value > cellarParams.amount1Desired) {
                    payable(msg.sender).transfer(
                        msg.value - cellarParams.amount1Desired
                    );
                }
                IWETH(_WETH).deposit{value: cellarParams.amount1Desired}();
            } else {
                IERC20(_WETH).safeTransferFrom(
                    msg.sender,
                    address(this),
                    cellarParams.amount1Desired
                );
                if (msg.value > 0) {
                    payable(msg.sender).transfer(msg.value);
                }
            }
            IERC20(token0).safeTransferFrom(
                msg.sender,
                address(this),
                cellarParams.amount0Desired
            );
        } else {
            IERC20(token0).safeTransferFrom(
                msg.sender,
                address(this),
                cellarParams.amount0Desired
            );
            IERC20(token1).safeTransferFrom(
                msg.sender,
                address(this),
                cellarParams.amount1Desired
            );
        }

        (
            uint256 inAmount0,
            uint256 inAmount1,
            uint128 liquidityBefore,
            uint128 liquiditySum
        ) = _addLiquidity(cellarParams);

        if (liquidityBefore == 0) {
            _mint(msg.sender, liquiditySum);
        } else {
            _mint(
                msg.sender,
                FullMath.mulDiv(liquiditySum, _totalSupply, liquidityBefore)
            );
        }

        if (inAmount0 < cellarParams.amount0Min || inAmount1 < cellarParams.amount1Min) revert InsufficientAmount();

        uint256 retAmount0 = cellarParams.amount0Desired - inAmount0;
        uint256 retAmount1 = cellarParams.amount1Desired - inAmount1;

        if (retAmount0 > 0) {
            if (token0 == _WETH) {
                IWETH(_WETH).withdraw(retAmount0);
                payable(msg.sender).transfer(retAmount0);
            } else {
                IERC20(token0).safeTransfer(msg.sender, retAmount0);
            }
        }
        if (retAmount1 > 0) {
            if (token1 == _WETH) {
                IWETH(_WETH).withdraw(retAmount1);
                payable(msg.sender).transfer(retAmount1);
            } else {
                IERC20(token1).safeTransfer(msg.sender, retAmount1);
            }
        }
        emit AddedLiquidity(liquiditySum, inAmount0, inAmount1);
    }

    function removeLiquidityFromUniV3(
        CellarRemoveParams calldata cellarParams
    ) external override nonReentrant notLocked(msg.sender) {
        (uint256 outAmount0, uint256 outAmount1, uint128 liquiditySum, ) =
            _removeLiquidity(cellarParams, false);
        _burn(msg.sender, cellarParams.tokenAmount);

        if (outAmount0 < cellarParams.amount0Min || outAmount1 < cellarParams.amount1Min) revert InsufficientAmount();

        if (token0 == _WETH) {
            IWETH(_WETH).withdraw(outAmount0);
            payable(msg.sender).transfer(outAmount0);
            IERC20(token1).safeTransfer(msg.sender, outAmount1);
        } else {
            IERC20(token0).safeTransfer(msg.sender, outAmount0);
            if (token1 == _WETH) {
                IWETH(_WETH).withdraw(outAmount1);
                payable(msg.sender).transfer(outAmount1);
            } else {
                IERC20(token1).safeTransfer(msg.sender, outAmount1);
            }
        }
        emit RemovedLiquidity(
            liquiditySum,
            outAmount0,
            outAmount1
        );
    }

    function _midSwap(
        address _token0, address _token1,
        uint256 inAmount0, uint256 inAmount1,
        uint256 balance0, uint256 balance1,
        uint256 sqrtPriceX96
    )
        private
    {
            uint256 swapAmount;
            // nothing added means either token exists and price range is not out of range for the token.
            // the case is balance0 > 0, balance1 = 0, swap half amount of token0 into token1
            if (inAmount0 == 0 && inAmount1 == 0) {
                swapAmount = balance0 / 2;
            }
            // calculate swap amount from bal0, bal1, in0, in1.
            // bal0, bal1 are token balance to add. in0, in1 are added balance in the first adding liquidity.
            // approximated result because in swapping, because the price changes.
            else {
                swapAmount = (balance0* inAmount1 - balance1 * inAmount0)
                    /
                    (FullMath.mulDiv(
                        FullMath.mulDiv(
                            inAmount0,
                            sqrtPriceX96,
                            FixedPoint96.Q96),
                        sqrtPriceX96,
                        FixedPoint96.Q96)
                    + inAmount1);
            }
            IERC20(_token0).safeApprove(_SWAPROUTER, swapAmount);
            try ISwapRouter(_SWAPROUTER).exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: _token0,
                    tokenOut: _token1,
                    fee: feeLevel,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: swapAmount,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            ) {} catch {}
            IERC20(_token0).safeApprove(_SWAPROUTER, 0);
    }

    /**
     * @notice invest token into Uniswap V3 liquidity
     * @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
     * @return totalInAmount0 token0 amount added into liquidity
     * @return totalInAmount1 token1 amount added into liquidity
     */
    function _invest(uint160 sqrtPriceX96)
        private
        nonReentrant
        returns (
            uint256 totalInAmount0,
            uint256 totalInAmount1
        )
    {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        (uint256 inAmount0, uint256 inAmount1, , ) =
            _addLiquidity(
                CellarAddParams({
                    amount0Desired: balance0,
                    amount1Desired: balance1,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                })
            );
        balance0 = balance0 - inAmount0;
        balance1 = balance1 - inAmount1;

        totalInAmount0 = totalInAmount0 + inAmount0;
        totalInAmount1 = totalInAmount1 + inAmount1;
        // uint256 swapAmount;
        // b0 / b1 > i0 / i1 means token0 will remain. swap some token0 into token1
        if (balance0 * inAmount1 > balance1 * inAmount0 || (inAmount0 == 0 && inAmount1 == 0 && balance0 > balance1)) {
            _midSwap(token0, token1, inAmount0, inAmount1, balance0, balance1, sqrtPriceX96);
        }
        // b0 / b1 < i0 / i1 means token1 will remain. swap some token1 into token0
        if (balance0 * inAmount1 < balance1 * inAmount0 || (inAmount0 == 0 && inAmount1 == 0 && balance0 < balance1)) {
            uint256 revertedSqrtPriceX96 = FullMath.mulDiv(FixedPoint96.Q96, FixedPoint96.Q96, sqrtPriceX96);
            _midSwap(token1, token0, inAmount1, inAmount0, balance1, balance0, revertedSqrtPriceX96);
        }
        (inAmount0, inAmount1, , ) =
            _addLiquidity(
                CellarAddParams({
                    amount0Desired: IERC20(token0).balanceOf(address(this)),
                    amount1Desired: IERC20(token1).balanceOf(address(this)),
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                })
            );

        totalInAmount0 += inAmount0;
        totalInAmount1 += inAmount1;
    }

    /**
     * @notice get management fee from NFLP
     * @param tokenId The ID of the token to get management fee
     * @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
     * @param duration duration since last collecting management fee
     * @return feeAmount0 token0 fee amount
     * @return feeAmount1 token1 fee amount
     */
    function getManagementFee(uint256 tokenId, uint160 sqrtPriceX96, uint256 duration)
        internal
        view
        returns (uint256 feeAmount0, uint256 feeAmount1)
    {
        (, , , , , int24 tickLower, int24 tickUpper, uint128 liquidity, , , , ) =
            INonfungiblePositionManager(_NONFUNGIBLEPOSITIONMANAGER)
                .positions(tokenId);
        uint160 sqrtPriceAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtPriceBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        (uint256 amount0, uint256 amount1) =
            LiquidityAmounts.getAmountsForLiquidity(sqrtPriceX96, sqrtPriceAX96, sqrtPriceBX96, liquidity);
        feeAmount0 = amount0 * managementFee * duration / _YEAR / _DOMINATOR;
        feeAmount1 = amount1 * managementFee * duration / _YEAR / _DOMINATOR;
    }

    function reinvest(uint256 currentPriceX96) external override onlyValidator notLocked(msg.sender) {
        uint256 weightSum;
        uint256 balance0;
        uint256 balance1;
        uint256 fee0;
        uint256 fee1;
        uint256 duration = block.timestamp - lastManageTimestamp;
        (uint160 sqrtPriceX96, , , , , , ) =
            IUniswapV3Pool(
                IUniswapV3Factory(_UNISWAPV3FACTORY).getPool(
                    token0,
                    token1,
                    feeLevel
                )
            )
                .slot0();
        unchecked{
            if (uint256(sqrtPriceX96) - currentPriceX96 >= currentPriceX96 * _TOLERANCE / _DOMINATOR
                && currentPriceX96 - uint256(sqrtPriceX96) >= currentPriceX96 * _TOLERANCE / _DOMINATOR)
                revert HighSlippage();
        }
        for (uint256 index = 0; index < cellarTickInfo.length; index++) {
            if (cellarTickInfo[index].tokenId == 0) revert InvalidTokenId();
            weightSum += cellarTickInfo[index].weight;
            (uint256 amount0, uint256 amount1) =
                INonfungiblePositionManager(_NONFUNGIBLEPOSITIONMANAGER).collect(
                    INonfungiblePositionManager.CollectParams({
                        tokenId: cellarTickInfo[index].tokenId,
                        recipient: address(this),
                        amount0Max: type(uint128).max,
                        amount1Max: type(uint128).max
                    })
                );
            balance0 += amount0;
            balance1 += amount1;
            (uint256 mFee0, uint256 mFee1) = getManagementFee(cellarTickInfo[index].tokenId, sqrtPriceX96, duration);
            fee0 += mFee0;
            fee1 += mFee1;
        }
        uint256 mgmtFee0 = fee0;
        uint256 mgmtFee1 = fee1;
        uint256 perfFee0 = balance0 * performanceFee / _DOMINATOR;
        uint256 perfFee1 = balance1 * performanceFee / _DOMINATOR;
        fee0 += perfFee0;
        fee1 += perfFee1;
        if (fee0 > balance0) {
            fee0 = balance0;
            if (mgmtFee0 < balance0) {
                perfFee0 = balance0 - mgmtFee0;
            } else {
                mgmtFee0 = balance0;
                perfFee0 = 0;
            }
        }
        if (fee1 > balance1) {
            fee1 = balance1;
            if (mgmtFee1 < balance1) {
                perfFee1 = balance1 - mgmtFee1;
            } else {
                mgmtFee1 = balance1;
                perfFee1 = 0;
            }
        }
        lastManageTimestamp = block.timestamp;
        if (fee0 > 0) {
            IERC20(token0).safeTransfer(_owner, fee0);
        }
        if (fee1 > 0) {
            IERC20(token1).safeTransfer(_owner, fee1);
        }
        (uint256 investedAmount0, uint256 investedAmount1) = _invest(sqrtPriceX96);

        emit Reinvest(
            balance0,
            balance1,
            mgmtFee0,
            mgmtFee1,
            perfFee0,
            perfFee1,
            investedAmount0,
            investedAmount1
        );
    }

    function rebalance(CellarTickInfo[] memory _cellarTickInfo, uint256 currentPriceX96)
        external
        override
        notLocked(msg.sender)
    {
        if (!adjuster[msg.sender]) revert NonPermission();
        (uint160 sqrtPriceX96, , , , , , ) =
            IUniswapV3Pool(
                IUniswapV3Factory(_UNISWAPV3FACTORY).getPool(
                    token0,
                    token1,
                    feeLevel
                )
            )
                .slot0();
        unchecked{
            if (uint256(sqrtPriceX96) - currentPriceX96 >= currentPriceX96 * _TOLERANCE / _DOMINATOR
                && currentPriceX96 - uint256(sqrtPriceX96) >= currentPriceX96 * _TOLERANCE / _DOMINATOR)
                revert HighSlippage();
        }
        CellarRemoveParams memory removeParams =
            CellarRemoveParams({
                tokenAmount: _totalSupply,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        (, , , CellarFees memory cellarFees) =
            _removeLiquidity(removeParams, true);
        lastManageTimestamp = block.timestamp;

        uint256 fee0 = cellarFees.management0 + cellarFees.performance0;
        uint256 fee1 = cellarFees.management1 + cellarFees.performance1;
        if (fee0 > cellarFees.collect0) {
            fee0 = cellarFees.collect0;
            if (cellarFees.management0 < cellarFees.collect0) {
                cellarFees.performance0 = cellarFees.collect0 - cellarFees.management0;
            } else {
                cellarFees.management0 = cellarFees.collect0;
                cellarFees.performance0 = 0;
            }
        }
        if (fee1 > cellarFees.collect1) {
            fee1 = cellarFees.collect1;
            if (cellarFees.management1 < cellarFees.collect1) {
                cellarFees.performance1 = cellarFees.collect1 - cellarFees.management1;
            } else {
                cellarFees.management1 = cellarFees.collect1;
                cellarFees.performance1 = 0;
            }
        }

        if (fee0 > 0) {
            IERC20(token0).safeTransfer(_owner, fee0);
        }
        if (fee1 > 0) {
            IERC20(token1).safeTransfer(_owner, fee1);
        }
        for (uint256 i = 0; i < cellarTickInfo.length; i++) {
            INonfungiblePositionManager(_NONFUNGIBLEPOSITIONMANAGER).burn(
                cellarTickInfo[i].tokenId
            );
        }
        delete cellarTickInfo;
        for (uint256 i = 0; i < _cellarTickInfo.length; i++) {
            if (_cellarTickInfo[i].tickUpper <= _cellarTickInfo[i].tickLower) revert WrongTickTier();
            if (i > 0) {
                if (_cellarTickInfo[i].tickUpper > _cellarTickInfo[i - 1].tickLower) revert WrongTickTier();
            }
            if (_cellarTickInfo[i].weight == 0) revert ZeroWeight();
            if (_cellarTickInfo[i].tokenId != 0) revert NonEmptyTokenId();
            cellarTickInfo.push(_cellarTickInfo[i]);
        }

        (uint256 investedAmount0, uint256 investedAmount1) = _invest(sqrtPriceX96);

        emit Rebalance(
            cellarFees.collect0,
            cellarFees.collect1,
            cellarFees.management0,
            cellarFees.management1,
            cellarFees.performance0,
            cellarFees.performance1,
            investedAmount0,
            investedAmount1
        );
    }

    function setValidator(address _validator, bool value) external override onlyOwner {
        if (_validator == address(0)) revert InvalidInput();
        validator[_validator] = value;
        emit SetValidator(_validator, value);
    }

    function setAdjuster(address _adjuster, bool value) external override onlyOwner {
        if (_adjuster == address(0)) revert InvalidInput();
        adjuster[_adjuster] = value;
        emit SetAdjuster(_adjuster, value);
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        if (newOwner == address(0)) revert InvalidInput();
        _owner = newOwner;
        validator[newOwner] = true;
        adjuster[newOwner] = true;
        emit TransferOwnership(newOwner);
    }

    function setManagementFee(uint256 newFee) external override onlyOwner {
        if (newFee >= _DOMINATOR) revert InvalidInput();
        managementFee = newFee;
        emit SetManagementFee(newFee);
    }

    function setPerformanceFee(uint256 newFee) external override onlyOwner {
        if (newFee >= _DOMINATOR) revert InvalidInput();
        performanceFee = newFee;
        emit SetPerformanceFee(newFee);
    }

    function pause() external {
        if (!adjuster[msg.sender]) revert NonPermission();
        if (status != Status.Working) {
            revert NotWorking();
        }
        status = Status.Paused;
    }

    function resume() external {
        if (!adjuster[msg.sender]) revert NonPermission();
        if (status != Status.Paused) {
            revert NotPaused();
        }
        status = Status.Working;
    }

    function stop() external {
        if (!adjuster[msg.sender]) revert NonPermission();
        if (status == Status.Stopped) {
            revert Stopped();
        }
        status = Status.Stopped;
    }

    function owner() external view override returns (address) {
        return _owner;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner_][spender];
    }

    function getCellarTickInfo()
        external
        view
        override
        returns (CellarTickInfo[] memory)
    {
        return cellarTickInfo;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        if (sender == address(0)) revert TransferFromZeroAddress();
        if (recipient == address(0)) revert TransferToZeroAddress();

        _balances[sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        if (account == address(0)) revert MintToZeroAddress();

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        if (account == address(0)) revert BurnFromZeroAddress();

        _balances[account] -= amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner_,
        address spender,
        uint256 amount
    ) internal {
        if (owner_ == address(0)) revert ApproveFromZeroAddress();
        if (spender == address(0)) revert ApproveToZeroAddress();

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    /**
     * @notice get weight information of positions
     * @dev every position has its weight but it is for liquidity weight, not token amount weight.
     *      this function calculates token amount weight and sum of weights from liquidity weight.
     * @param _cellarTickInfo cellar tick info struct array
     * @return weightSum0 sum of weights for token0
     * @return weightSum1 sum of weights for token1
     * @return liquidityBefore total liquidity of all positions
     * @return weight0 weights array for token0
     * @return weight1 weights array for token1
     */
    function _getWeightInfo(CellarTickInfo[] memory _cellarTickInfo)
        internal
        view
        returns (
            uint256 weightSum0,
            uint256 weightSum1,
            uint128 liquidityBefore,
            uint256[] memory weight0,
            uint256[] memory weight1
        )
    {
        weight0 = new uint256[](_cellarTickInfo.length);
        weight1 = new uint256[](_cellarTickInfo.length);
        (uint160 sqrtPriceX96, int24 currentTick, , , , , ) =
            IUniswapV3Pool(
                IUniswapV3Factory(_UNISWAPV3FACTORY).getPool(
                    token0,
                    token1,
                    feeLevel
                )
            )
                .slot0();
        UintPair memory sqrtPrice0;
        // price of ticks is increasing through ticks.
        // At the first tick, token0 weight is maximum. Last tick, token1 weight is maximum.

        uint256 weight00;// token0 maximum weight
        uint256 weight10;// token1 maximum weight

        sqrtPrice0.a = TickMath.getSqrtRatioAtTick(
            _cellarTickInfo[0].tickLower
        );
        sqrtPrice0.b = TickMath.getSqrtRatioAtTick(
            _cellarTickInfo[0].tickUpper
        );
        weight00 = _cellarTickInfo[0].weight; // first position
        weight10 = _cellarTickInfo[_cellarTickInfo.length - 1].weight; // last position

        // calculate token weight from liquidity weight per tick position
        for (uint256 i = 0; i < _cellarTickInfo.length; i++) {
            if (_cellarTickInfo[i].tokenId > 0) {
                (, , , , , , , uint128 liquidity, , , , ) =
                    INonfungiblePositionManager(_NONFUNGIBLEPOSITIONMANAGER)
                        .positions(_cellarTickInfo[i].tokenId);
                liquidityBefore += liquidity;
            }

            UintPair memory sqrtCurrentTickPriceX96;
            sqrtCurrentTickPriceX96.a = TickMath.getSqrtRatioAtTick(
                _cellarTickInfo[i].tickLower
            );
            sqrtCurrentTickPriceX96.b = TickMath.getSqrtRatioAtTick(
                _cellarTickInfo[i].tickUpper
            );
            // current tick is less than tickLower of the position.
            // token1 amount is 0, So consider token0 amount and weight only.
            if (currentTick <= _cellarTickInfo[i].tickLower) {
                weight0[i] = // weight for token0
                    (FullMath.mulDiv(
                        FullMath.mulDiv(
                            FullMath.mulDiv(
                                sqrtPrice0.a,
                                sqrtPrice0.b,
                                sqrtPrice0.b - sqrtPrice0.a
                            ),
                            sqrtCurrentTickPriceX96.b -
                                sqrtCurrentTickPriceX96.a,
                            sqrtCurrentTickPriceX96.b
                        ),
                        FixedPoint96.Q96,
                        sqrtCurrentTickPriceX96.a
                    ) // token0 amount
                     * _cellarTickInfo[i].weight) /
                    weight00;
                weightSum0 += weight0[i];
            // current tick is greater than tickLower of the position.
            // token0 amount is 0, So consider token1 amount and weight only.
            } else if (currentTick >= _cellarTickInfo[i].tickUpper) {
                weight1[i] = // weight for token1
                    (FullMath.mulDiv(
                        sqrtCurrentTickPriceX96.b - sqrtCurrentTickPriceX96.a,
                        FixedPoint96.Q96,
                        sqrtPrice0.b - sqrtPrice0.a
                    ) * _cellarTickInfo[i].weight) /
                    weight10;
                weightSum1 += weight1[i];
            // current tick is in the range, recalculate both tokens weight.
            } else {
                weight0[i] =
                    (FullMath.mulDiv(
                        FullMath.mulDiv(
                            FullMath.mulDiv(
                                sqrtPrice0.a,
                                sqrtPrice0.b,
                                sqrtPrice0.b - sqrtPrice0.a
                            ),
                            sqrtCurrentTickPriceX96.b - sqrtPriceX96,
                            sqrtCurrentTickPriceX96.b
                        ),
                        FixedPoint96.Q96,
                        sqrtPriceX96
                    ) * _cellarTickInfo[i].weight) /
                    weight00;

                weight1[i] =
                    (FullMath.mulDiv(
                        sqrtPriceX96 - sqrtCurrentTickPriceX96.a,
                        FixedPoint96.Q96,
                        sqrtPrice0.b - sqrtPrice0.a
                    ) * _cellarTickInfo[i].weight) /
                    weight10;
                weightSum0 += weight0[i];
                weightSum1 += weight1[i];
            }
        }
    }

    /**
     * @notice modify weight information of positions
     * @dev some positions consist of either token.
     *      that's why if we distribute tokens according to the weights, some tokens will remain.
     *      so we remove weights from the weight sum if the position doesn't include either token.
     * @param _cellarTickInfo cellar tick info struct array
     * @param amount0Desired token0 amount to add liquidity
     * @param amount1Desired token1 amount to add liquidity
     * @param weightSum0 sum of weights for token0
     * @param weightSum1 sum of weights for token1
     * @param weight0 token0 weight array
     * @param weight1 token1 weight array
     * @return newWeightSum0 updated sum of weights for token0
     * @return newWeightSum1 updated sum of weights for token1
     */
    function _modifyWeightInfo(
        CellarTickInfo[] memory _cellarTickInfo,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 weightSum0,
        uint256 weightSum1,
        uint256[] memory weight0,
        uint256[] memory weight1
    ) internal view returns (uint256 newWeightSum0, uint256 newWeightSum1) {
        if (_cellarTickInfo.length == 1) {
            return (weightSum0, weightSum1);
        }

        UintPair memory liquidity;
        (uint160 sqrtPriceX96, , , , , , ) =
            IUniswapV3Pool(
                IUniswapV3Factory(_UNISWAPV3FACTORY).getPool(
                    token0,
                    token1,
                    feeLevel
                )
            )
                .slot0();
        liquidity.a = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(_cellarTickInfo[0].tickLower),
            TickMath.getSqrtRatioAtTick(_cellarTickInfo[0].tickUpper),
            FullMath.mulDiv(amount0Desired, weight0[0], weightSum0),
            FullMath.mulDiv(amount1Desired, weight1[0], weightSum1)
        );
        uint256 tickLength = _cellarTickInfo.length - 1;
        liquidity.b = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(_cellarTickInfo[tickLength].tickLower),
            TickMath.getSqrtRatioAtTick(_cellarTickInfo[tickLength].tickUpper),
            FullMath.mulDiv(amount0Desired, weight0[tickLength], weightSum0),
            FullMath.mulDiv(amount1Desired, weight1[tickLength], weightSum1)
        );

        if (
            liquidity.a * _cellarTickInfo[tickLength].weight >
            liquidity.b * _cellarTickInfo[0].weight
        ) {
            if (liquidity.b * _cellarTickInfo[0].weight > 0) {
                newWeightSum0 = FullMath.mulDiv(
                    weightSum0,
                    liquidity.a * _cellarTickInfo[tickLength].weight,
                    liquidity.b * _cellarTickInfo[0].weight
                );
            }
            else {
                newWeightSum0 = 0;
            }
            newWeightSum1 = weightSum1;
        } else {
            newWeightSum0 = weightSum0;
            if (liquidity.a * _cellarTickInfo[tickLength].weight > 0) {
                newWeightSum1 = FullMath.mulDiv(
                    weightSum1,
                    liquidity.b * _cellarTickInfo[0].weight,
                    liquidity.a * _cellarTickInfo[tickLength].weight
                );
            }
            else {
                newWeightSum1 = 0;
            }
        }
    }

    /**
     * @notice add liquidity into Uniswap positions
     * @param cellarParams params struct to add liquidity
     * @return inAmount0 token0 amount added into liquidity
     * @return inAmount1 token1 amount added into liquidity
     * @return liquidityBefore liquidity sum before add liquidity
     * @return liquiditySum liquidity sum after add liquidity
     */
    function _addLiquidity(CellarAddParams memory cellarParams)
        internal
        returns (
            uint256 inAmount0,
            uint256 inAmount1,
            uint128 liquidityBefore,
            uint128 liquiditySum
        )
    {
        CellarTickInfo[] memory _cellarTickInfo = cellarTickInfo;
        IERC20(token0).safeApprove(
            _NONFUNGIBLEPOSITIONMANAGER,
            cellarParams.amount0Desired
        );
        IERC20(token1).safeApprove(
            _NONFUNGIBLEPOSITIONMANAGER,
            cellarParams.amount1Desired
        );

        uint256 weightSum0;
        uint256 weightSum1;
        uint256[] memory weight0 = new uint256[](_cellarTickInfo.length);
        uint256[] memory weight1 = new uint256[](_cellarTickInfo.length);

        (
            weightSum0,
            weightSum1,
            liquidityBefore,
            weight0,
            weight1
        ) = _getWeightInfo(_cellarTickInfo);
        if (weightSum0 > 0 && weightSum1 > 0) {
            (weightSum0, weightSum1) = _modifyWeightInfo(
                _cellarTickInfo,
                cellarParams.amount0Desired,
                cellarParams.amount1Desired,
                weightSum0,
                weightSum1,
                weight0,
                weight1
            );
        }

        for (uint256 i = 0; i < _cellarTickInfo.length; i++) {
            INonfungiblePositionManager.MintParams memory mintParams =
                INonfungiblePositionManager.MintParams({
                    token0: token0,
                    token1: token1,
                    fee: feeLevel,
                    tickLower: _cellarTickInfo[i].tickLower,
                    tickUpper: _cellarTickInfo[i].tickUpper,
                    amount0Desired: 0,
                    amount1Desired: 0,
                    amount0Min: 0,
                    amount1Min: 0,
                    recipient: address(this),
                    deadline: cellarParams.deadline
                });

                INonfungiblePositionManager.IncreaseLiquidityParams
                    memory increaseLiquidityParams
             =
                INonfungiblePositionManager.IncreaseLiquidityParams({
                    tokenId: _cellarTickInfo[i].tokenId,
                    amount0Desired: 0,
                    amount1Desired: 0,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: cellarParams.deadline
                });
            if (weightSum0 > 0) {
                mintParams.amount0Desired = FullMath.mulDiv(
                    cellarParams.amount0Desired,
                    weight0[i],
                    weightSum0
                );
                increaseLiquidityParams.amount0Desired = mintParams
                    .amount0Desired;
                mintParams.amount0Min = FullMath.mulDiv(
                    cellarParams.amount0Min,
                    weight0[i],
                    weightSum0
                );
                increaseLiquidityParams.amount0Min = mintParams.amount0Min;
            }
            if (weightSum1 > 0) {
                mintParams.amount1Desired = FullMath.mulDiv(
                    cellarParams.amount1Desired,
                    weight1[i],
                    weightSum1
                );
                increaseLiquidityParams.amount1Desired = mintParams
                    .amount1Desired;
                mintParams.amount1Min = FullMath.mulDiv(
                    cellarParams.amount1Min,
                    weight1[i],
                    weightSum1
                );
                increaseLiquidityParams.amount1Min = mintParams.amount1Min;
            }
            if (
                mintParams.amount0Desired > 0 || mintParams.amount1Desired > 0
            ) {
                MintResult memory mintResult;
                if (_cellarTickInfo[i].tokenId == 0) {

                    try INonfungiblePositionManager(_NONFUNGIBLEPOSITIONMANAGER)
                        .mint(mintParams) returns (uint256 r1, uint128 r2, uint256 r3, uint256 r4) {
                        mintResult.tokenId = r1;
                        mintResult.liquidity = r2;
                        mintResult.amount0 = r3;
                        mintResult.amount1 = r4;
                    } catch {}

                    cellarTickInfo[i].tokenId = uint184(mintResult.tokenId);

                    inAmount0 = inAmount0 + mintResult.amount0;
                    inAmount1 = inAmount1 + mintResult.amount1;
                    liquiditySum += mintResult.liquidity;
                } else {
                    try INonfungiblePositionManager(_NONFUNGIBLEPOSITIONMANAGER)
                        .increaseLiquidity(increaseLiquidityParams) returns (uint128 r1, uint256 r2, uint256 r3) {
                        mintResult.liquidity = r1;
                        mintResult.amount0 = r2;
                        mintResult.amount1 = r3;
                    } catch {}
                    inAmount0 = inAmount0 + mintResult.amount0;
                    inAmount1 = inAmount1 + mintResult.amount1;
                    liquiditySum += mintResult.liquidity;
                }
            }
        }
        IERC20(token0).safeApprove(_NONFUNGIBLEPOSITIONMANAGER, 0);
        IERC20(token1).safeApprove(_NONFUNGIBLEPOSITIONMANAGER, 0);
    }

    /**
     * @notice remove liquidity from Uniswap positions
     * @param cellarParams params struct to add liquidity
     * @param getFee true if calculate fee and return as cellarFees param
            set false when don't need fee calculation for saving gas.
     * @return outAmount0 token0 amount added into liquidity
     * @return outAmount1 token1 amount added into liquidity
     * @return liquiditySum liquidity sum after add liquidity
     * @return cellarFees fee information struct when getFee is true, otherwise empty
     */
    function _removeLiquidity(CellarRemoveParams memory cellarParams, bool getFee)
        internal
        returns (
            uint256 outAmount0,
            uint256 outAmount1,
            uint128 liquiditySum,
            CellarFees memory cellarFees
        )
    {
        CellarTickInfo[] memory _cellarTickInfo = cellarTickInfo;
        uint256 duration = block.timestamp - lastManageTimestamp;
        (uint160 sqrtPriceX96, , , , , , ) =
            IUniswapV3Pool(
                IUniswapV3Factory(_UNISWAPV3FACTORY).getPool(
                    token0,
                    token1,
                    feeLevel
                )
            )
                .slot0();
        for (uint256 i = 0; i < _cellarTickInfo.length; i++) {
            (, , , , , , , uint128 liquidity, , , , ) =
                INonfungiblePositionManager(_NONFUNGIBLEPOSITIONMANAGER)
                    .positions(_cellarTickInfo[i].tokenId);
            uint128 outLiquidity =
                uint128(
                    FullMath.mulDiv(
                        liquidity,
                        cellarParams.tokenAmount,
                        _totalSupply
                    )
                );

                INonfungiblePositionManager.DecreaseLiquidityParams
                    memory decreaseLiquidityParams
             =
                INonfungiblePositionManager.DecreaseLiquidityParams({
                    tokenId: _cellarTickInfo[i].tokenId,
                    liquidity: outLiquidity,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: cellarParams.deadline
                });
            UintPair memory amount;
            (amount.a, amount.b) =
                INonfungiblePositionManager(_NONFUNGIBLEPOSITIONMANAGER)
                    .decreaseLiquidity(decreaseLiquidityParams);
            UintPair memory collectAmount;
            (collectAmount.a, collectAmount.b) =
                INonfungiblePositionManager(_NONFUNGIBLEPOSITIONMANAGER).collect(
                    INonfungiblePositionManager.CollectParams({
                        tokenId: _cellarTickInfo[i].tokenId,
                        recipient: address(this),
                        amount0Max: type(uint128).max,
                        amount1Max: type(uint128).max
                    })
                );
            outAmount0 = outAmount0 + amount.a;
            outAmount1 = outAmount1 + amount.b;
            liquiditySum += outLiquidity;
            if (getFee) {
                cellarFees.collect0 = cellarFees.collect0 + collectAmount.a - amount.a;
                cellarFees.collect1 = cellarFees.collect1 + collectAmount.b - amount.b;
                (amount.a, amount.b) = getManagementFee(_cellarTickInfo[i].tokenId, sqrtPriceX96, duration);
                cellarFees.management0 = cellarFees.management0 + amount.a;
                cellarFees.management1 = cellarFees.management1 + amount.b;
            }
        }
        if (getFee) {
            cellarFees.performance0 = cellarFees.collect0 * performanceFee / _DOMINATOR;
            cellarFees.performance1 = cellarFees.collect1 * performanceFee / _DOMINATOR;
        }
    }

    receive() external payable {
        require(msg.sender == _WETH);
    }
}