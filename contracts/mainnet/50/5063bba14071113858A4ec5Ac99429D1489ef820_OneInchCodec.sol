// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "../interfaces/IERC20.sol";
import "../interfaces/ICodec.sol";
import "../interfaces/IUniswapV3Pool.sol";
import "../interfaces/IUniswapV2Pair.sol";

contract OneInchCodec is ICodec {
    uint256 private constant _ONE_FOR_ZERO_MASK = 1 << 255;
    uint256 private constant _REVERSE_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;

    struct OrderRFQ {
        // lowest 64 bits is the order id, next 64 bits is the expiration timestamp
        // highest bit is unwrap WETH flag which is set on taker's side
        // [unwrap eth(1 bit) | unused (127 bits) | expiration timestamp(64 bits) | orderId (64 bits)]
        uint256 info;
        IERC20 makerAsset;
        IERC20 takerAsset;
        address maker;
        address allowedSender; // equals to Zero address on public orders
        uint256 makingAmount;
        uint256 takingAmount;
    }

    struct SwapDesc {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    function decodeCalldata(ICodec.SwapDescription calldata _swap)
        external
        view
        returns (
            uint256 amountIn,
            address tokenIn,
            address tokenOut
        )
    {
        bytes4 selector = bytes4(_swap.data);
        if (selector == 0xb0431182) {
            // "b0431182": "clipperSwap(address srcToken, address dstToken, uint256 amount, uint256 minReturn)",
            (address srcToken, address dstToken, uint256 amount, ) = abi.decode(
                (_swap.data[4:]),
                (address, address, uint256, uint256)
            );
            return (amount, srcToken, dstToken);
        } else if (selector == 0xd0a3b665) {
            // "d0a3b665": "fillOrderRFQ((uint256 info, address makerAsset, address takerAsset, address maker, address allowedSender, uint256 makingAmount, uint256 takingAmount) order, bytes signature, uint256 makingAmount, uint256 takingAmount)",
            (OrderRFQ memory order, , , ) = abi.decode((_swap.data[4:]), (OrderRFQ, bytes, uint256, uint256));
            return (order.makingAmount, address(order.makerAsset), address(order.takerAsset));
        } else if (selector == 0x7c025200) {
            // "7c025200": "swap(address caller,(address srcToken, address dstToken, address srcReceiver, address dstReceiver, uint256 amount, uint256 minReturnAmount, uint256 flags, bytes permit) desc, bytes data)",
            (, SwapDesc memory desc, ) = abi.decode((_swap.data[4:]), (address, SwapDesc, bytes));
            return (desc.amount, address(desc.srcToken), address(desc.dstToken));
        } else if (selector == 0xe449022e) {
            // "e449022e": "uniswapV3Swap(uint256 amount,uint256 minReturn,uint256[] pools)",
            (uint256 amount, , uint256[] memory pools) = abi.decode((_swap.data[4:]), (uint256, uint256, uint256[]));
            (address srcToken, ) = decodeV3Pool(pools[0]);
            (, address dstToken) = decodeV3Pool(pools[pools.length - 1]);
            return (amount, srcToken, dstToken);
        } else if (selector == 0x2e95b6c8) {
            // "2e95b6c8": "unoswap(address srcToken, uint256 amount, uint256 minReturn, bytes32[] pools)"
            (address srcToken, uint256 amount, , bytes32[] memory pools) = abi.decode(
                (_swap.data[4:]),
                (address, uint256, uint256, bytes32[])
            );
            (, address dstToken) = decodeV2Pool(uint256(pools[pools.length - 1]));
            return (amount, srcToken, dstToken);
        } else {
            // error, unknown selector
            revert("unknown selector");
        }
    }

    function encodeCalldataWithOverride(
        bytes calldata _data,
        uint256 _amountInOverride,
        address _receiverOverride
    ) external pure returns (bytes memory swapCalldata) {
        bytes4 selector = bytes4(_data);
        if (selector == 0xb0431182) {
            // "b0431182": "clipperSwap(address srcToken, address dstToken, uint256 amount, uint256 minReturn)",
            (address srcToken, address dstToken, , uint256 minReturn) = abi.decode(
                (_data[4:]),
                (address, address, uint256, uint256)
            );
            return abi.encodeWithSelector(selector, srcToken, dstToken, _amountInOverride, minReturn);
        } else if (selector == 0xd0a3b665) {
            // "d0a3b665": "fillOrderRFQ((uint256 info, address makerAsset, address takerAsset, address maker, address allowedSender, uint256 makingAmount, uint256 takingAmount) order, bytes signature, uint256 makingAmount, uint256 takingAmount)",
            (OrderRFQ memory order, bytes memory signature, , uint256 takingAmount) = abi.decode(
                (_data[4:]),
                (OrderRFQ, bytes, uint256, uint256)
            );
            order.makingAmount = _amountInOverride;
            return abi.encodeWithSelector(selector, order, signature, _amountInOverride, takingAmount);
        } else if (selector == 0x7c025200) {
            // "7c025200": "swap(address caller,(address srcToken, address dstToken, address srcReceiver, address dstReceiver, uint256 amount, uint256 minReturnAmount, uint256 flags, bytes permit) desc, bytes data)",
            (address caller, SwapDesc memory desc, bytes memory data) = abi.decode(
                (_data[4:]),
                (address, SwapDesc, bytes)
            );
            desc.dstReceiver = payable(_receiverOverride);
            desc.amount = _amountInOverride;
            return abi.encodeWithSelector(selector, caller, desc, data);
        } else if (selector == 0xe449022e) {
            // "e449022e": "uniswapV3Swap(uint256 amount,uint256 minReturn,uint256[] pools)",
            (, uint256 minReturn, uint256[] memory pools) = abi.decode((_data[4:]), (uint256, uint256, uint256[]));
            return abi.encodeWithSelector(selector, _amountInOverride, minReturn, pools);
        } else if (selector == 0x2e95b6c8) {
            // "2e95b6c8": "unoswap(address srcToken, uint256 amount, uint256 minReturn, bytes32[] pools)"
            (address srcToken, , uint256 minReturn, bytes32[] memory pools) = abi.decode(
                (_data[4:]),
                (address, uint256, uint256, bytes32[])
            );
            return abi.encodeWithSelector(selector, srcToken, _amountInOverride, minReturn, pools);
        } else {
            // error, unknown selector
            revert("unknown selector");
        }
    }

    function decodeV3Pool(uint256 pool) private view returns (address srcToken, address dstToken) {
        bool zeroForOne = pool & _ONE_FOR_ZERO_MASK == 0;
        address poolAddr = address(uint160(pool));
        if (zeroForOne) {
            return (IUniswapV3Pool(poolAddr).token0(), IUniswapV3Pool(poolAddr).token1());
        } else {
            return (IUniswapV3Pool(poolAddr).token1(), IUniswapV3Pool(poolAddr).token0());
        }
    }

    function decodeV2Pool(uint256 pool) private view returns (address srcToken, address dstToken) {
        bool zeroForOne = pool & _REVERSE_MASK == 0;
        address poolAddr = address(uint160(pool));
        if (zeroForOne) {
            return (IUniswapV2Pair(poolAddr).token0(), IUniswapV2Pair(poolAddr).token1());
        } else {
            return (IUniswapV2Pair(poolAddr).token1(), IUniswapV2Pair(poolAddr).token0());
        }
    }
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface ICodec {
    struct SwapDescription {
        address dex; // the DEX to use for the swap, zero address implies no swap needed
        bytes data; // the data to call the dex with
    }

    function decodeCalldata(SwapDescription calldata swap)
        external
        view
        returns (
            uint256 amountIn,
            address tokenIn,
            address tokenOut
        );

    function encodeCalldataWithOverride(
        bytes calldata data,
        uint256 amountInOverride,
        address receiverOverride
    ) external pure returns (bytes memory swapCalldata);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

interface IUniswapV3Pool {
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

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
    function token0() external view returns (address);
    function token1() external view returns (address);

}