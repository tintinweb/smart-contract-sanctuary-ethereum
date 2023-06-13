// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.9;
pragma abicoder v2;

import "./SwapRouter.sol";
import "./UniswapV3Router.sol";
import "./UniswapV2Router.sol";
import "./libraries/SwapPath.sol";
import "./libraries/Protocols.sol";
import "./interfaces/ISwapRouterHub.sol";
import "./CurveRouter.sol";
import "./AbstractSelfPermit2612.sol";

/// @title Gridex, Curve, UniswapV2 and UniswapV3 Swap Router
contract SwapRouterHub is
    SwapRouter,
    UniswapV3Router,
    UniswapV2Router,
    ISwapRouterHub,
    CurveRouter,
    AbstractSelfPermit2612
{
    using SwapPath for bytes;

    constructor(
        address _gridexGridFactory,
        address _uniswapV3PoolFactory,
        address _uniswapV2PoolFactory,
        address _weth9
    )
        AbstractPayments(_gridexGridFactory, _weth9)
        UniswapV3Router(_uniswapV3PoolFactory)
        UniswapV2Router(_uniswapV2PoolFactory)
    {}

    /// @inheritdoc ISwapRouterHub
    function exactMixedInput(
        ExactMixedInputParameters memory parameters
    ) public payable override checkDeadline(parameters.deadline) returns (uint256 amountOut) {
        // msg.sender pays for the first hop
        address payer = _msgSender();
        uint256 i = 0;
        while (true) {
            bool hasMultipleGrids = parameters.path.hasMultipleGrids();
            if (parameters.path.getProtocol() == Protocols.GRIDEX) {
                parameters.amountIn = exactInputInternal(
                    parameters.amountIn,
                    hasMultipleGrids ? address(this) : parameters.recipient, // this contract keep the token of intermediate swaps within the path
                    0,
                    SwapCallbackData({
                        path: parameters.path.getFirstGrid(), // only the first grid in the path is necessary
                        payer: payer
                    })
                );
            } else if (parameters.path.getProtocol() == Protocols.UNISWAPV3) {
                parameters.amountIn = uniswapV3ExactInputInternal(
                    parameters.amountIn,
                    hasMultipleGrids ? address(this) : parameters.recipient, // this contract keep the token of intermediate swaps within the path
                    0,
                    UniswapV3SwapCallbackData({
                        path: parameters.path.getFirstGrid(), // only the first grid in the path is necessary
                        payer: payer
                    })
                );
            } else if (parameters.path.getProtocol() == Protocols.UNISWAPV2) {
                parameters.amountIn = uniswapV2ExactInputInternal(
                    parameters.amountIn,
                    parameters.path,
                    payer,
                    hasMultipleGrids ? address(this) : parameters.recipient
                );
            } else {
                if (i == 0) pay(parameters.path.getTokenA(), payer, address(this), parameters.amountIn);

                parameters.amountIn = curveExactInputInternal(
                    parameters.amountIn,
                    parameters.path,
                    parameters.path.getProtocol(),
                    hasMultipleGrids ? address(this) : parameters.recipient
                );
            }

            // decide whether to continue or terminate
            if (hasMultipleGrids) {
                unchecked {
                    i++;
                }
                // at this point, the caller has paid
                payer = address(this);
                parameters.path = parameters.path.skipToken();
            } else {
                amountOut = parameters.amountIn;
                break;
            }
        }
        // SR_TLR: too little received
        require(amountOut >= parameters.amountOutMinimum, "SR_TLR");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/// @dev Backward compatible EIP-2612 contract definitions.
//  For more information, please refer to https://eips.ethereum.org/EIPS/eip-2612#backwards-compatibility
interface IPermit2612Compatible {
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

/// @dev Base contract for supporting the EIP-2612 specification.
/// For more information, please refer to https://eips.ethereum.org/EIPS/eip-2612
abstract contract AbstractSelfPermit2612 {
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        IERC20Permit(token).permit(msg.sender, address(this), value, deadline, v, r, s);
    }

    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        if (IERC20(token).allowance(msg.sender, address(this)) < value)
            IERC20Permit(token).permit(msg.sender, address(this), value, deadline, v, r, s);
    }

    function selfPermitCompatible(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        IPermit2612Compatible(token).permit(msg.sender, address(this), nonce, expiry, true, v, r, s);
    }

    function selfPermitCompatibleIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        if (IERC20(token).allowance(msg.sender, address(this)) < type(uint256).max)
            IPermit2612Compatible(token).permit(msg.sender, address(this), nonce, expiry, true, v, r, s);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./AbstractPayments.sol";
import "./interfaces/ICurvePool.sol";
import "./libraries/SwapPath.sol";
import "./libraries/Protocols.sol";

abstract contract CurveRouter is AbstractPayments {
    using SwapPath for bytes;

    struct CurvePayload {
        /// @dev The address of the Curve pool contract that the quote is being requested for
        address poolAddress;
        /// @dev The address of the swap contract that will be used to execute the token swap.
        address swapAddress;
        /// @dev The index of the input token in the Curve pool
        uint8 tokenInIndex;
        /// @dev The index of the output token in the Curve pool
        uint8 tokenOutIndex;
    }

    mapping(address => mapping(address => bool)) private approved;
    uint256 private constant DEFAULT_APPROVED = type(uint256).max;

    function _decodePath(
        bytes memory path
    ) internal pure returns (address tokenIn, address tokenOut, CurvePayload memory payload) {
        (
            tokenIn,
            tokenOut,
            payload.poolAddress,
            payload.swapAddress,
            payload.tokenInIndex,
            payload.tokenOutIndex
        ) = path.decodeFirstCurvePool();
    }

    function curveExactInputInternal(
        uint256 amountIn,
        bytes memory path,
        uint8 protocol,
        address recipient
    ) internal returns (uint256 amountOut) {
        (address tokenIn, address tokenOut, CurvePayload memory payload) = _decodePath(path);
        if (!approved[tokenIn][payload.poolAddress]) {
            IERC20(tokenIn).approve(payload.poolAddress, DEFAULT_APPROVED);
            approved[tokenIn][payload.poolAddress] = true;
        }

        if (protocol == Protocols.CURVE1) {
            ICurvePool(payload.poolAddress).exchange(
                int128(int8(payload.tokenInIndex)),
                int128(int8(payload.tokenOutIndex)),
                amountIn,
                0
            );
        } else if (protocol == Protocols.CURVE2) {
            ICurvePool(payload.poolAddress).exchange_underlying(
                int128(int8(payload.tokenInIndex)),
                int128(int8(payload.tokenOutIndex)),
                amountIn,
                0
            );
        } else if (protocol == Protocols.CURVE3) {
            ICurveCryptoPool(payload.poolAddress).exchange(
                uint256(payload.tokenInIndex),
                uint256(payload.tokenOutIndex),
                amountIn,
                0
            );
        } else if (protocol == Protocols.CURVE4) {
            ICurveCryptoPool(payload.poolAddress).exchange_underlying(
                uint256(payload.tokenInIndex),
                uint256(payload.tokenOutIndex),
                amountIn,
                0
            );
        } else if (protocol == Protocols.CURVE7) {
            uint256[2] memory _amounts;
            _amounts[payload.tokenInIndex] = amountIn;
            ICurveBasePool2Coins(payload.poolAddress).add_liquidity(_amounts, 0);
        } else if (protocol == Protocols.CURVE8) {
            uint256[3] memory _amounts;
            _amounts[payload.tokenInIndex] = amountIn;
            ICurveBasePool3Coins(payload.poolAddress).add_liquidity(_amounts, 0);
        } else if (protocol == Protocols.CURVE9) {
            uint256[3] memory _amounts;
            _amounts[payload.tokenInIndex] = amountIn;
            ICurveLendingBasePool3Coins(payload.poolAddress).add_liquidity(_amounts, 0, true);
        } else if (protocol == Protocols.CURVE10) {
            ICurveBasePool3Coins(payload.poolAddress).remove_liquidity_one_coin(
                amountIn,
                int128(int8(payload.tokenOutIndex)),
                0
            );
        } else if (protocol == Protocols.CURVE11) {
            ICurveLendingBasePool3Coins(payload.poolAddress).remove_liquidity_one_coin(
                amountIn,
                int128(int8(payload.tokenOutIndex)),
                0,
                true
            );
        } else if (protocol == Protocols.CURVE5) {
            ICurveLendingBasePoolMetaZap(payload.poolAddress).exchange_underlying(
                payload.swapAddress,
                int128(int8(payload.tokenInIndex)),
                int128(int8(payload.tokenOutIndex)),
                amountIn,
                0
            );
        } else if (protocol == Protocols.CURVE6) {
            ICurveCryptoMetaZap(payload.poolAddress).exchange(
                payload.swapAddress,
                uint256(payload.tokenInIndex),
                uint256(payload.tokenOutIndex),
                amountIn,
                0,
                false
            );
        } else {
            // CRQ_IP: invalid protocol
            revert("CRQ_IP");
        }
        amountOut = IERC20(tokenOut).balanceOf(address(this));
        if (recipient != address(this)) pay(tokenOut, address(this), recipient, amountOut);
    }

    function approveToCurvePool(address token, address poolAddress) external {
        IERC20(token).approve(poolAddress, DEFAULT_APPROVED);
        approved[token][poolAddress] = true;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./ISwapRouter.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV3Router.sol";

interface ISwapRouterHub is ISwapRouter, IUniswapV2Router, IUniswapV3Router {
    struct ExactMixedInputParameters {
        /// @dev The path of tokens to trade, encoded as SwapPath.
        bytes path;
        /// @dev The address that will receive the output tokens.
        address recipient;
        /// @dev The deadline of the transaction execution.
        uint256 deadline;
        /// @dev The amount of the first token to trade.
        uint256 amountIn;
        /// @dev The minimum amount of the last token to receive. Reverts if actual amount received is less than this value.
        uint256 amountOutMinimum;
    }

    /// @notice This function executes a mixed input swap transaction with the specified input parameters.
    /// @param parameters The parameters necessary for the swap, encoded as `ExactMixedInputParameters` in calldata
    /// @return amountOut The amount of the received token
    function exactMixedInput(
        ExactMixedInputParameters calldata parameters
    ) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library Protocols {
    uint8 internal constant GRIDEX = 1;
    uint8 internal constant UNISWAPV3 = 2;
    uint8 internal constant UNISWAPV2 = 3;
    uint8 internal constant CURVE = 4;
    uint8 internal constant CURVE1 = 5;
    uint8 internal constant CURVE2 = 6;
    uint8 internal constant CURVE3 = 7;
    uint8 internal constant CURVE4 = 8;
    uint8 internal constant CURVE5 = 9;
    uint8 internal constant CURVE6 = 10;
    uint8 internal constant CURVE7 = 11;
    uint8 internal constant CURVE8 = 12;
    uint8 internal constant CURVE9 = 13;
    uint8 internal constant CURVE10 = 14;
    uint8 internal constant CURVE11 = 15;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./BytesLib.sol";
import "./Protocols.sol";

/// @title Functions for manipulating path data for multihop swaps
library SwapPath {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded token index
    uint256 private constant TOKEN_INDEX_SIZE = 1;

    /// @dev The length of the bytes encoded protocol
    uint256 private constant PROTOCOL_SIZE = 1;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;

    /// @dev The length of the bytes encoded resolution
    uint256 private constant RESOLUTION_SIZE = 3;

    /// @dev The offset of the encoded resolution -- 21
    uint256 private constant RESOLUTION_OFFSET = ADDR_SIZE + PROTOCOL_SIZE;

    /// @dev The size of the resolution payload --4
    uint256 private constant RESOLUTION_PAYLOAD_SIZE = PROTOCOL_SIZE + RESOLUTION_SIZE;

    /// @dev The offset of a single token address and resolution payload
    uint256 private constant RESOLUTION_PAYLOAD_NEXT_OFFSET = ADDR_SIZE + RESOLUTION_PAYLOAD_SIZE;

    /// @dev The offset of the encoded resolution payload grid key
    uint256 private constant RESOLUTION_PAYLOAD_POP_OFFSET = RESOLUTION_PAYLOAD_NEXT_OFFSET + ADDR_SIZE;

    /// @dev The offset of the encoded swap address in the curve payload
    uint256 private constant CURVE_PAYLOAD_SWAP_ADDRESS_OFFSET = RESOLUTION_OFFSET + ADDR_SIZE;

    /// @dev The offset of the encoded token A index in the curve payload
    uint256 private constant CURVE_PAYLOAD_TOKEN_A_INDEX_OFFSET = CURVE_PAYLOAD_SWAP_ADDRESS_OFFSET + ADDR_SIZE;

    /// @dev The offset of the encoded token B index in the curve payload
    uint256 private constant CURVE_PAYLOAD_TOKEN_B_INDEX_OFFSET = CURVE_PAYLOAD_TOKEN_A_INDEX_OFFSET + TOKEN_INDEX_SIZE;

    /// @dev The size of the curve payload
    uint256 private constant CURVE_PAYLOAD_SIZE = PROTOCOL_SIZE + ADDR_SIZE * 2 + TOKEN_INDEX_SIZE * 2;

    /// @dev The offset of a single token address and curve payload
    uint256 private constant CURVE_PAYLOAD_NEXT_OFFSET = ADDR_SIZE + CURVE_PAYLOAD_SIZE;

    /// @dev The offset of an encoded curve payload grid key
    uint256 private constant CURVE_PAYLOAD_POP_OFFSET = CURVE_PAYLOAD_NEXT_OFFSET + ADDR_SIZE;

    /// @notice Returns true if the path contains two or more grids
    /// @param path The encoded swap path
    /// @return True if path contains two or more grids, otherwise false
    function hasMultipleGrids(bytes memory path) internal pure returns (bool) {
        if (getProtocol(path) < Protocols.CURVE) {
            return path.length > RESOLUTION_PAYLOAD_POP_OFFSET;
        } else {
            return path.length > CURVE_PAYLOAD_POP_OFFSET;
        }
    }

    /// @notice Decodes the first grid in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given grid
    /// @return tokenB The second token of the given grid
    /// @return resolution The resolution of the given grid
    function decodeFirstGrid(
        bytes memory path
    ) internal pure returns (address tokenA, address tokenB, int24 resolution) {
        tokenA = path.toAddress(0);
        resolution = int24(path.toUint24(RESOLUTION_OFFSET));
        tokenB = path.toAddress(RESOLUTION_PAYLOAD_NEXT_OFFSET);
    }

    /// @notice Decodes the first curve pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return poolAddress The address of the given pool
    /// @return swapAddress The swap address only for curve protocol
    /// @return tokenAIndex The index of the tokenA
    /// @return tokenBIndex The index of the tokenB
    function decodeFirstCurvePool(
        bytes memory path
    )
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            address poolAddress,
            address swapAddress,
            uint8 tokenAIndex,
            uint8 tokenBIndex
        )
    {
        tokenA = path.toAddress(0);
        poolAddress = path.toAddress(RESOLUTION_OFFSET);
        swapAddress = path.toAddress(CURVE_PAYLOAD_SWAP_ADDRESS_OFFSET);
        tokenAIndex = uint8(path[CURVE_PAYLOAD_TOKEN_A_INDEX_OFFSET]);
        tokenBIndex = uint8(path[CURVE_PAYLOAD_TOKEN_B_INDEX_OFFSET]);
        tokenB = path.toAddress(CURVE_PAYLOAD_NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first grid in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first grid in the path
    function getFirstGrid(bytes memory path) internal pure returns (bytes memory) {
        if (getProtocol(path) < Protocols.CURVE) return path.slice(0, RESOLUTION_PAYLOAD_POP_OFFSET);
        else return path.slice(0, CURVE_PAYLOAD_POP_OFFSET);
    }

    /// @notice Skips the token and the payload element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + payload elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        if (getProtocol(path) < Protocols.CURVE)
            return path.slice(RESOLUTION_PAYLOAD_NEXT_OFFSET, path.length - RESOLUTION_PAYLOAD_NEXT_OFFSET);
        else return path.slice(CURVE_PAYLOAD_NEXT_OFFSET, path.length - CURVE_PAYLOAD_NEXT_OFFSET);
    }

    /// @notice Returns the protocol identifier for the given path
    /// @param path The encoded swap path
    /// @return The protocol identifier
    function getProtocol(bytes memory path) internal pure returns (uint8) {
        return uint8(path[ADDR_SIZE]);
    }

    /// @notice Returns the first token address for the given path
    /// @param path The encoded swap path
    /// @return The first token address
    function getTokenA(bytes memory path) internal pure returns (address) {
        return path.toAddress(0);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./AbstractPayments.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./libraries/UniswapV2Library.sol";
import "./libraries/SwapPath.sol";

/// @title Uniswap V2 Swap Router
/// @notice A stateless execution router adapted for the Uniswap V2 protocol
abstract contract UniswapV2Router is IUniswapV2Router, AbstractPayments {
    using SwapPath for bytes;
    address public immutable uniswapV2PoolFactory;

    constructor(address _uniswapV2PoolFactory) {
        uniswapV2PoolFactory = _uniswapV2PoolFactory;
    }

    // supports fee-on-transfer tokens
    // requires the initial amount to have already been sent to the first pair
    function _swap(address[] memory path, address _to) private {
        unchecked {
            for (uint256 i; i < path.length - 1; i++) {
                (address input, address output) = (path[i], path[i + 1]);
                address to = i < path.length - 2
                    ? UniswapV2Library.pairFor(uniswapV2PoolFactory, output, path[i + 2])
                    : _to;
                _swapOnce(input, output, to);
            }
        }
    }

    function _swapOnce(address input, address output, address recipient) private {
        (address token0, ) = UniswapV2Library.sortTokens(input, output);
        IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(uniswapV2PoolFactory, input, output));
        uint256 amountInput;
        uint256 amountOutput;
        // scope to avoid stack too deep errors
        {
            (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
            (uint256 reserveInput, uint256 reserveOutput) = input == token0
                ? (reserve0, reserve1)
                : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
            amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
        }
        (uint256 amount0Out, uint256 amount1Out) = input == token0
            ? (uint256(0), amountOutput)
            : (amountOutput, uint256(0));

        pair.swap(amount0Out, amount1Out, recipient, new bytes(0));
    }

    function uniswapV2ExactInputInternal(
        uint256 amountIn,
        bytes memory path,
        address payer,
        address recipient
    ) internal returns (uint256 amountOut) {
        (address input, address output, ) = path.decodeFirstGrid();
        pay(input, payer, UniswapV2Library.pairFor(uniswapV2PoolFactory, input, output), amountIn);
        uint256 balanceBefore = IERC20(output).balanceOf(recipient);
        _swapOnce(input, output, recipient);
        amountOut = IERC20(output).balanceOf(recipient) - balanceBefore;
    }

    /// @inheritdoc IUniswapV2Router
    function uniswapV2ExactInput(
        uint256 amountIn,
        uint256 amountOutMinimum,
        address[] calldata path,
        address to
    ) external payable override returns (uint256 amountOut) {
        pay(path[0], _msgSender(), UniswapV2Library.pairFor(uniswapV2PoolFactory, path[0], path[1]), amountIn);

        // allows swapping to the router address with address 0
        to = to == address(0) ? address(this) : to;

        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);

        _swap(path, to);

        amountOut = IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore;
        // UV2R_TLR: too little received
        require(amountOut >= amountOutMinimum, "UV2R_TLR");
    }

    /// @inheritdoc IUniswapV2Router
    function uniswapV2ExactOutput(
        uint256 amountOut,
        uint256 amountInMaximum,
        address[] calldata path,
        address to
    ) external payable override returns (uint256 amountIn) {
        amountIn = UniswapV2Library.getAmountsIn(uniswapV2PoolFactory, amountOut, path)[0];
        // UV2R_TMR: Too much requested
        require(amountIn <= amountInMaximum, "UV2R_TMR");

        pay(path[0], _msgSender(), UniswapV2Library.pairFor(uniswapV2PoolFactory, path[0], path[1]), amountIn);

        // allows swapping to the router address with address 0
        to = to == address(0) ? address(this) : to;

        _swap(path, to);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./AbstractPayments.sol";
import "./interfaces/IUniswapV3Router.sol";
import "./interfaces/IUniswapV3PoolMinimum.sol";
import "./libraries/SwapPath.sol";
import "./libraries/UniswapV3PoolAddress.sol";
import "./libraries/UniswapV3CallbackValidator.sol";
import "./libraries/Ratio.sol";

/// @title Uniswap V3 Swap Router
/// @notice A stateless execution router adapted for the Uniswap V3 protocol
abstract contract UniswapV3Router is IUniswapV3Router, AbstractPayments {
    using SwapPath for bytes;
    using SafeCast for uint256;

    uint256 private constant DEFAULT_AMOUNT_IN_CACHED = type(uint256).max;

    uint256 private amountInCached;

    address public immutable uniswapV3PoolFactory;

    constructor(address _uniswapV3PoolFactory) {
        uniswapV3PoolFactory = _uniswapV3PoolFactory;
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }

    /// @dev Returns the pool for the given token pair and fee. The pool contract may or may not exist.
    function getUniswapV3Pool(address tokenA, address tokenB, int24 fee) private view returns (IUniswapV3PoolMinimum) {
        return
            IUniswapV3PoolMinimum(
                UniswapV3PoolAddress.computeAddress(
                    uniswapV3PoolFactory,
                    UniswapV3PoolAddress.poolKey(tokenA, tokenB, uint24(fee))
                )
            );
    }

    struct UniswapV3SwapCallbackData {
        bytes path;
        address payer;
    }

    /// @inheritdoc IUniswapV3Router
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata _data) external override {
        // swaps which are entirely contained within zero liquidity regions are not supported
        require(amount0Delta > 0 || amount1Delta > 0);
        UniswapV3SwapCallbackData memory data = abi.decode(_data, (UniswapV3SwapCallbackData));
        (address tokenIn, address tokenOut, int24 fee) = data.path.decodeFirstGrid();
        UniswapV3CallbackValidator.validate(uniswapV3PoolFactory, tokenIn, tokenOut, uint24(fee));

        (bool isExactInput, uint256 amountToPay) = amount0Delta > 0
            ? (tokenIn < tokenOut, uint256(amount0Delta))
            : (tokenOut < tokenIn, uint256(amount1Delta));

        if (isExactInput) pay(tokenIn, data.payer, _msgSender(), amountToPay);
        else {
            // either initiate the next swap or pay
            if (data.path.hasMultipleGrids()) {
                data.path = data.path.skipToken();
                uniswapV3ExactOutputInternal(amountToPay, _msgSender(), 0, data);
            } else {
                amountInCached = amountToPay;
                // note that tokenOut is actually tokenIn because exactOutput swaps are executed in reverse order
                pay(tokenOut, data.payer, _msgSender(), amountToPay);
            }
        }
    }

    /// @dev Performs a single exact input swap
    function uniswapV3ExactInputInternal(
        uint256 amountIn,
        address recipient,
        uint160 sqrtPriceLimitX96,
        UniswapV3SwapCallbackData memory data
    ) internal returns (uint256 amountOut) {
        // allow swapping to the router address with address 0
        recipient = recipient == address(0) ? address(this) : recipient;

        (address tokenIn, address tokenOut, int24 fee) = data.path.decodeFirstGrid();

        bool zeroForOne = tokenIn < tokenOut;

        (int256 amount0, int256 amount1) = getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            recipient,
            zeroForOne,
            amountIn.toInt256(),
            sqrtPriceLimitX96 == 0
                ? (zeroForOne ? Ratio.MIN_SQRT_RATIO_PLUS_ONE : Ratio.MAX_SQRT_RATIO_MINUS_ONE)
                : sqrtPriceLimitX96,
            abi.encode(data)
        );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    /// @inheritdoc IUniswapV3Router
    function uniswapV3ExactInputSingle(
        UniswapV3ExactInputSingleParameters calldata parameters
    ) external payable override checkDeadline(parameters.deadline) returns (uint256 amountOut) {
        amountOut = uniswapV3ExactInputInternal(
            parameters.amountIn,
            parameters.recipient,
            parameters.sqrtPriceLimitX96,
            UniswapV3SwapCallbackData({
                path: abi.encodePacked(parameters.tokenIn, uint8(0), parameters.fee, parameters.tokenOut),
                payer: _msgSender()
            })
        );
        // UV3R_TLR: too little received
        require(amountOut >= parameters.amountOutMinimum, "UV3R_TLR");
    }

    /// @inheritdoc IUniswapV3Router
    function uniswapV3ExactInput(
        UniswapV3ExactInputParameters memory parameters
    ) external payable override checkDeadline(parameters.deadline) returns (uint256 amountOut) {
        // the first hop is paid for by msg.sender
        address payer = _msgSender();

        while (true) {
            bool hasMultipleGrids = parameters.path.hasMultipleGrids();

            // the output of the previous swap is used as the input of the subsequent swap
            parameters.amountIn = uniswapV3ExactInputInternal(
                parameters.amountIn,
                hasMultipleGrids ? address(this) : parameters.recipient, // this contract keep the token of intermediate swaps within the path
                0,
                UniswapV3SwapCallbackData({
                    path: parameters.path.getFirstGrid(), // only the first pool in the path is necessary
                    payer: payer
                })
            );

            // decide whether to continue or terminate
            if (hasMultipleGrids) {
                // at this point, the caller has paid
                payer = address(this);
                parameters.path = parameters.path.skipToken();
            } else {
                amountOut = parameters.amountIn;
                break;
            }
        }
        // UV3R_TLR: too little received
        require(amountOut >= parameters.amountOutMinimum, "UV3R_TLR");
    }

    /// @dev Performs a single exact output swap
    function uniswapV3ExactOutputInternal(
        uint256 amountOut,
        address recipient,
        uint160 sqrtPriceLimitX96,
        UniswapV3SwapCallbackData memory data
    ) internal returns (uint256 amountIn) {
        // allow swapping to the router address with address 0
        recipient = recipient == address(0) ? address(this) : recipient;

        (address tokenOut, address tokenIn, int24 fee) = data.path.decodeFirstGrid();

        bool zeroForOne = tokenIn < tokenOut;

        (int256 amount0Delta, int256 amount1Delta) = getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            recipient,
            zeroForOne,
            -amountOut.toInt256(),
            sqrtPriceLimitX96 == 0
                ? (zeroForOne ? Ratio.MIN_SQRT_RATIO_PLUS_ONE : Ratio.MAX_SQRT_RATIO_MINUS_ONE)
                : sqrtPriceLimitX96,
            abi.encode(data)
        );

        uint256 amountOutReceived;
        (amountIn, amountOutReceived) = zeroForOne
            ? (uint256(amount0Delta), uint256(-amount1Delta))
            : (uint256(amount1Delta), uint256(-amount0Delta));
        // technically, it is possible to not receive all of the output amount,
        // so if PriceLimit is not specified, this possibility needs to be eliminated immediately
        if (sqrtPriceLimitX96 == 0) require(amountOutReceived == amountOut, "UV3R_IAOR"); // UV3R_IAOR: invalid amount out received
    }

    /// @inheritdoc IUniswapV3Router
    function uniswapV3ExactOutputSingle(
        UniswapV3ExactOutputSingleParameters calldata parameters
    ) external payable override checkDeadline(parameters.deadline) returns (uint256 amountIn) {
        // avoid an SLOAD by using the swap return data
        amountIn = uniswapV3ExactOutputInternal(
            parameters.amountOut,
            parameters.recipient,
            parameters.sqrtPriceLimitX96,
            UniswapV3SwapCallbackData({
                path: abi.encodePacked(parameters.tokenOut, uint8(0), parameters.fee, parameters.tokenIn),
                payer: _msgSender()
            })
        );

        // UV3R_TMR: too much requested
        require(amountIn <= parameters.amountInMaximum, "UV3R_TMR");
        // must be reset, despite remaining unused in the single hop case
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }

    /// @inheritdoc IUniswapV3Router
    function uniswapV3ExactOutput(
        UniswapV3ExactOutputParameters calldata parameters
    ) external payable override checkDeadline(parameters.deadline) returns (uint256 amountIn) {
        uniswapV3ExactOutputInternal(
            parameters.amountOut,
            parameters.recipient,
            0,
            UniswapV3SwapCallbackData({path: parameters.path, payer: _msgSender()})
        );

        amountIn = amountInCached;
        // UV3R_TMR: too much requested
        require(amountIn <= parameters.amountInMaximum, "UV3R_TMR");
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@gridexprotocol/core/contracts/interfaces/IGrid.sol";
import "@gridexprotocol/core/contracts/interfaces/callback/IGridSwapCallback.sol";
import "@gridexprotocol/core/contracts/libraries/GridAddress.sol";
import "@gridexprotocol/core/contracts/libraries/CallbackValidator.sol";
import "@gridexprotocol/core/contracts/libraries/BoundaryMath.sol";
import "./interfaces/ISwapRouter.sol";
import "./libraries/SwapPath.sol";
import "./AbstractPayments.sol";
import "./Multicall.sol";

/// @title Gridex Swap Router
/// @notice A stateless execution router adapted for the gridex protocol
abstract contract SwapRouter is IGridSwapCallback, ISwapRouter, AbstractPayments, Multicall {
    using SwapPath for bytes;
    using SafeCast for uint256;

    /// @dev This constant is used as a placeholder value for amountInCached; as the computed amount (for
    /// an exact output swap), will never reach this value
    uint256 private constant DEFAULT_AMOUNT_IN_CACHED = type(uint256).max;

    /// @dev Transient storage variable used for returning the computed amount in for an exact output swap.
    uint256 private amountInCached;

    constructor() {
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }

    /// @dev Returns the grid for the given token pair and resolution. The grid contract may or may not exist.
    function getGrid(address tokenA, address tokenB, int24 resolution) private view returns (IGrid) {
        return IGrid(GridAddress.computeAddress(gridFactory, GridAddress.gridKey(tokenA, tokenB, resolution)));
    }

    struct SwapCallbackData {
        bytes path;
        address payer;
    }

    /// @inheritdoc IGridSwapCallback
    function gridexSwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata _data) external override {
        // swaps which are entirely contained within zero liquidity regions are not supported
        // SR_IAD: invalid amount delta
        require(amount0Delta > 0 || amount1Delta > 0, "SR_IAD");
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        (address tokenIn, address tokenOut, int24 resolution) = data.path.decodeFirstGrid();
        CallbackValidator.validate(gridFactory, GridAddress.gridKey(tokenIn, tokenOut, resolution));

        (bool isExactInput, uint256 amountToPay) = amount0Delta > 0
            ? (tokenIn < tokenOut, uint256(amount0Delta))
            : (tokenOut < tokenIn, uint256(amount1Delta));
        if (isExactInput) pay(tokenIn, data.payer, _msgSender(), amountToPay);
        else {
            // either initiate the next swap or pay
            if (data.path.hasMultipleGrids()) {
                data.path = data.path.skipToken();
                exactOutputInternal(amountToPay, _msgSender(), 0, data);
            } else {
                amountInCached = amountToPay;
                // swap in/out because the exact output swaps are reversed
                tokenIn = tokenOut;
                pay(tokenIn, data.payer, _msgSender(), amountToPay);
            }
        }
    }

    /// @dev Performs a single exact input swap
    function exactInputInternal(
        uint256 amountIn,
        address recipient,
        uint160 priceLimitX96,
        SwapCallbackData memory data
    ) internal returns (uint256 amountOut) {
        // allow swapping to the router address with address 0
        recipient = recipient == address(0) ? address(this) : recipient;

        (IGrid grid, bool zeroForOne) = _decodeGridForExactInput(data);

        (int256 amount0, int256 amount1) = grid.swap(
            recipient,
            zeroForOne,
            amountIn.toInt256(),
            priceLimitX96 == 0 ? (zeroForOne ? BoundaryMath.MIN_RATIO : BoundaryMath.MAX_RATIO) : priceLimitX96,
            abi.encode(data)
        );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    function _decodeGridForExactInput(SwapCallbackData memory data) private view returns (IGrid grid, bool zeroForOne) {
        (address tokenIn, address tokenOut, int24 resolution) = data.path.decodeFirstGrid();
        return (getGrid(tokenIn, tokenOut, resolution), tokenIn < tokenOut);
    }

    /// @inheritdoc ISwapRouter
    function exactInputSingle(
        ExactInputSingleParameters calldata parameters
    ) external payable override checkDeadline(parameters.deadline) returns (uint256 amountOut) {
        amountOut = exactInputInternal(
            parameters.amountIn,
            parameters.recipient,
            parameters.priceLimitX96,
            SwapCallbackData({
                path: abi.encodePacked(parameters.tokenIn, uint8(0), parameters.resolution, parameters.tokenOut),
                payer: _msgSender()
            })
        );
        // SR_TLR: too little received
        require(amountOut >= parameters.amountOutMinimum, "SR_TLR");
    }

    /// @inheritdoc ISwapRouter
    function exactInput(
        ExactInputParameters memory parameters
    ) external payable override checkDeadline(parameters.deadline) returns (uint256 amountOut) {
        // msg.sender pays for the first hop
        address payer = _msgSender();

        while (true) {
            bool hasMultipleGrids = parameters.path.hasMultipleGrids();

            // the output of the previous swap is used as the input of the subsequent swap.
            parameters.amountIn = exactInputInternal(
                parameters.amountIn,
                hasMultipleGrids ? address(this) : parameters.recipient, // this contract keep the token of intermediate swaps within the path
                0,
                SwapCallbackData({
                    path: parameters.path.getFirstGrid(), // only the first grid in the path is necessary
                    payer: payer
                })
            );

            // decide whether to continue or terminate
            if (hasMultipleGrids) {
                // at this point, the caller has paid
                payer = address(this);
                parameters.path = parameters.path.skipToken();
            } else {
                amountOut = parameters.amountIn;
                break;
            }
        }
        // SR_TLR: too little received
        require(amountOut >= parameters.amountOutMinimum, "SR_TLR");
    }

    /// @dev Performs a single exact output swap
    function exactOutputInternal(
        uint256 amountOut,
        address recipient,
        uint160 priceLimitX96,
        SwapCallbackData memory data
    ) private returns (uint256 amountIn) {
        // allow swapping to the router address with address 0
        recipient = recipient == address(0) ? address(this) : recipient;

        (IGrid grid, bool zeroForOne) = _decodeGridForExactOutput(data);

        (int256 amount0Delta, int256 amount1Delta) = grid.swap(
            recipient,
            zeroForOne,
            -amountOut.toInt256(),
            priceLimitX96 == 0 ? (zeroForOne ? BoundaryMath.MIN_RATIO : BoundaryMath.MAX_RATIO) : priceLimitX96,
            abi.encode(data)
        );

        uint256 amountOutReceived;
        (amountIn, amountOutReceived) = zeroForOne
            ? (uint256(amount0Delta), uint256(-amount1Delta))
            : (uint256(amount1Delta), uint256(-amount0Delta));
        // technically, it is possible to not receive all of the output amount,
        // so if PriceLimit is not specified, this possibility needs to be eliminated immediately
        if (priceLimitX96 == 0) require(amountOutReceived == amountOut, "SR_IAOR"); // SR_IAOR: invalid amount out received
    }

    function _decodeGridForExactOutput(
        SwapCallbackData memory data
    ) private view returns (IGrid grid, bool zeroForOne) {
        (address tokenOut, address tokenIn, int24 resolution) = data.path.decodeFirstGrid();
        return (getGrid(tokenIn, tokenOut, resolution), tokenIn < tokenOut);
    }

    /// @inheritdoc ISwapRouter
    function exactOutputSingle(
        ExactOutputSingleParameters calldata parameters
    ) external payable override checkDeadline(parameters.deadline) returns (uint256 amountIn) {
        // avoid an SLOAD by using the swap return data
        amountIn = exactOutputInternal(
            parameters.amountOut,
            parameters.recipient,
            parameters.priceLimitX96,
            SwapCallbackData({
                path: abi.encodePacked(parameters.tokenOut, uint8(0), parameters.resolution, parameters.tokenIn),
                payer: _msgSender()
            })
        );

        // SR_TMR: too much requested
        require(amountIn <= parameters.amountInMaximum, "SR_TMR");
        // must be reset, despite remaining unused in the single hop case
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }

    /// @inheritdoc ISwapRouter
    function exactOutput(
        ExactOutputParameters calldata parameters
    ) external payable override checkDeadline(parameters.deadline) returns (uint256 amountIn) {
        // the payer is fixed as _msgSender() here, this is a non-issue as they only pay for the “final” exactOutput
        // swap, which happens first, swaps that follow are paid within nested callbacks
        exactOutputInternal(
            parameters.amountOut,
            parameters.recipient,
            0,
            SwapCallbackData({path: parameters.path, payer: _msgSender()})
        );

        amountIn = amountInCached;
        // SR_TMR: too much requested
        require(amountIn <= parameters.amountInMaximum, "SR_TMR");
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity ^0.8.0;

library BytesLib {
    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IUniswapV3Router {
    struct UniswapV3ExactInputSingleParameters {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;

    function uniswapV3ExactInputSingle(
        UniswapV3ExactInputSingleParameters calldata parameters
    ) external payable returns (uint256 amountOut);

    struct UniswapV3ExactInputParameters {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function uniswapV3ExactInput(
        UniswapV3ExactInputParameters calldata parameters
    ) external payable returns (uint256 amountOut);

    struct UniswapV3ExactOutputSingleParameters {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function uniswapV3ExactOutputSingle(
        UniswapV3ExactOutputSingleParameters calldata parameters
    ) external payable returns (uint256 amountIn);

    struct UniswapV3ExactOutputParameters {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function uniswapV3ExactOutput(
        UniswapV3ExactOutputParameters calldata parameters
    ) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IUniswapV2Router {
    function uniswapV2ExactInput(
        uint256 amountIn,
        uint256 amountOutMinimum,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountOut);

    function uniswapV2ExactOutput(
        uint256 amountOut,
        uint256 amountInMaximum,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@gridexprotocol/core/contracts/interfaces/callback/IGridSwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Gridex
interface ISwapRouter is IGridSwapCallback {
    struct ExactInputSingleParameters {
        /// @dev Address of the input token
        address tokenIn;
        /// @dev Address of the output token
        address tokenOut;
        /// @dev The resolution of the pool to swap on
        int24 resolution;
        /// @dev Address to receive swapped tokens
        address recipient;
        /// @dev The deadline of the transaction execution
        uint256 deadline;
        /// @dev The amount of the input token to swap
        uint256 amountIn;
        /// @dev The minimum amount of the last token to receive. Reverts if actual amount received is less than this value.
        uint256 amountOutMinimum;
        /// @dev If zero for one, the price cannot be less than this value after the swap. If one for zero,
        /// the price cannot be greater than this value after the swap
        uint160 priceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param parameters The parameters necessary for the swap, encoded as `ExactInputSingleParameters` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParameters calldata parameters
    ) external payable returns (uint256 amountOut);

    struct ExactInputParameters {
        /// @dev Path of tokens to swap
        bytes path;
        /// @dev Address to receive swapped tokens
        address recipient;
        /// @dev The deadline of the transaction execution
        uint256 deadline;
        /// @dev The amount of the input token to swap
        uint256 amountIn;
        /// @dev The minimum amount of the last token to receive. Reverts if actual amount received is less than this value.
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param parameters The parameters necessary for the multi-hop swap, encoded as `ExactInputParameters` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParameters calldata parameters) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParameters {
        /// @dev Address of the input token
        address tokenIn;
        /// @dev Address of the output token
        address tokenOut;
        /// @dev The resolution of the pool to swap on
        int24 resolution;
        /// @dev Address to receive swapped tokens
        address recipient;
        /// @dev The deadline of the transaction execution
        uint256 deadline;
        /// @dev The amount of the output token to receive
        uint256 amountOut;
        /// @dev The maximum amount of input tokens to spend. Reverts if actual amount spent is greater than this value.
        uint256 amountInMaximum;
        /// @dev If zero for one, the price cannot be less than this value after the swap. If one for zero,
        /// the price cannot be greater than this value after the swap
        uint160 priceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param parameters The parameters necessary for the swap, encoded as `ExactOutputSingleParameters` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(
        ExactOutputSingleParameters calldata parameters
    ) external payable returns (uint256 amountIn);

    struct ExactOutputParameters {
        /// @dev Path of tokens to swap
        bytes path;
        /// @dev Address to receive swapped tokens
        address recipient;
        /// @dev The deadline of the transaction execution
        uint256 deadline;
        /// @dev The amount of the output token to receive
        uint256 amountOut;
        /// @dev The maximum amount of input tokens to spend. Reverts if actual amount spent is greater than this value.
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param parameters The parameters necessary for the multi-hop swap, encoded as `ExactOutputParameters` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParameters calldata parameters) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library Ratio {
    uint160 internal constant MIN_SQRT_RATIO_PLUS_ONE = 4295128739 + 1;
    uint160 internal constant MAX_SQRT_RATIO_MINUS_ONE = 1461446703485210103287273052203988822378723970342 - 1;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./UniswapV3PoolAddress.sol";

library UniswapV3CallbackValidator {
    function validate(address poolFactory, address tokenA, address tokenB, uint24 fee) internal view {
        validate(poolFactory, UniswapV3PoolAddress.poolKey(tokenA, tokenB, fee));
    }

    function validate(address poolFactory, UniswapV3PoolAddress.PoolKey memory poolKey) internal view {
        // CV_IC: invalid caller
        require(UniswapV3PoolAddress.computeAddress(poolFactory, poolKey) == msg.sender, "CV_IC");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";

library UniswapV3PoolAddress {
    bytes32 internal constant POOL_BYTES_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    function poolKey(address tokenA, address tokenB, uint24 fee) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);

        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    function computeAddress(address factory, PoolKey memory key) internal pure returns (address) {
        require(key.token0 < key.token1);
        return
            Create2.computeAddress(
                keccak256(abi.encode(key.token0, key.token1, key.fee)),
                POOL_BYTES_CODE_HASH,
                factory
            );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IUniswapV3PoolMinimum {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

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

    function tickBitmap(int16 wordPosition) external view returns (uint256);

    function tickSpacing() external view returns (int24);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@gridexprotocol/core/contracts/interfaces/IWETHMinimum.sol";
import "./interfaces/IPayments.sol";

abstract contract AbstractPayments is IPayments, Context {
    /// @dev The address of IGridFactory
    address public immutable gridFactory;
    /// @dev The address of IWETHMinimum
    address public immutable weth9;

    constructor(address _gridFactory, address _weth9) {
        // AP_NC: not contract
        require(Address.isContract(_gridFactory), "AP_NC");
        require(Address.isContract(_weth9), "AP_NC");

        gridFactory = _gridFactory;
        weth9 = _weth9;
    }

    modifier checkDeadline(uint256 deadline) {
        // AP_TTO: transaction too old
        require(block.timestamp <= deadline, "AP_TTO");
        _;
    }

    receive() external payable {
        // AP_WETH9: not WETH9
        require(_msgSender() == weth9, "AP_WETH9");
    }

    /// @inheritdoc IPayments
    function unwrapWETH9(uint256 amountMinimum, address recipient) public payable override {
        uint256 balanceWETH9 = IWETHMinimum(weth9).balanceOf(address(this));
        // AP_IWETH9: insufficient WETH9
        require(balanceWETH9 >= amountMinimum, "AP_IWETH9");

        if (balanceWETH9 > 0) {
            IWETHMinimum(weth9).withdraw(balanceWETH9);
            Address.sendValue(payable(recipient), balanceWETH9);
        }
    }

    /// @inheritdoc IPayments
    function sweepToken(address token, uint256 amountMinimum, address recipient) public payable override {
        uint256 balanceToken = IERC20(token).balanceOf(address(this));
        // AP_ITKN: insufficient token
        require(balanceToken >= amountMinimum, "AP_ITKN");

        if (balanceToken > 0) SafeERC20.safeTransfer(IERC20(token), recipient, balanceToken);
    }

    /// @inheritdoc IPayments
    function refundNativeToken() external payable {
        if (address(this).balance > 0) Address.sendValue(payable(_msgSender()), address(this).balance);
    }

    /// @dev Pays the token to the recipient
    /// @param token The token to pay
    /// @param payer The address of the payment token
    /// @param recipient The address that will receive the payment
    /// @param amount The amount to pay
    function pay(address token, address payer, address recipient, uint256 amount) internal {
        if (token == weth9 && address(this).balance >= amount) {
            // pay with WETH9
            Address.sendValue(payable(weth9), amount);
            IWETHMinimum(weth9).transfer(recipient, amount);
        } else if (payer == address(this)) SafeERC20.safeTransfer(IERC20(token), recipient, amount);
        else SafeERC20.safeTransferFrom(IERC20(token), payer, recipient, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

library UniswapV2Library {
    bytes32 internal constant POOL_BYTES_CODE_HASH = 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB);
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0));
    }

    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = Create2.computeAddress(keccak256(abi.encodePacked(token0, token1)), POOL_BYTES_CODE_HASH, factory);
    }

    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        // UV2L_IIA: insufficient input amount
        require(amountIn > 0, "UV2L_IIA");
        require(reserveIn > 0 && reserveOut > 0);
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        // UV2L_IOA: insufficient output amount
        require(amountOut > 0, "UV2L_IOA");
        require(reserveIn > 0 && reserveOut > 0);
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }

    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2);
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

abstract contract Multicall {
    function multicall(bytes[] calldata data) external payable virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        unchecked {
            for (uint256 i = 0; i < data.length; i++) {
                results[i] = _functionDelegateCall(data[i]);
            }
        }

        return results;
    }

    function _functionDelegateCall(bytes memory data) private returns (bytes memory) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(this).delegatecall(data);
        // M_LDCF: low-level delegate call failed
        return Address.verifyCallResult(success, returndata, "M_LDCF");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library BoundaryMath {
    int24 public constant MIN_BOUNDARY = -527400;
    int24 public constant MAX_BOUNDARY = 443635;

    /// @dev The minimum value that can be returned from #getPriceX96AtBoundary. Equivalent to getPriceX96AtBoundary(MIN_BOUNDARY)
    uint160 internal constant MIN_RATIO = 989314;
    /// @dev The maximum value that can be returned from #getPriceX96AtBoundary. Equivalent to getPriceX96AtBoundary(MAX_BOUNDARY)
    uint160 internal constant MAX_RATIO = 1461300573427867316570072651998408279850435624081;

    /// @dev Checks if a boundary is divisible by a resolution
    /// @param boundary The boundary to check
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    /// @return isValid Whether or not the boundary is valid
    function isValidBoundary(int24 boundary, int24 resolution) internal pure returns (bool isValid) {
        return boundary % resolution == 0;
    }

    /// @dev Checks if a boundary is within the valid range
    /// @param boundary The boundary to check
    /// @return inRange Whether or not the boundary is in range
    function isInRange(int24 boundary) internal pure returns (bool inRange) {
        return boundary >= MIN_BOUNDARY && boundary <= MAX_BOUNDARY;
    }

    /// @dev Checks if a price is within the valid range
    /// @param priceX96 The price to check, as a Q64.96
    /// @return inRange Whether or not the price is in range
    function isPriceX96InRange(uint160 priceX96) internal pure returns (bool inRange) {
        return priceX96 >= MIN_RATIO && priceX96 <= MAX_RATIO;
    }

    /// @notice Calculates the price at a given boundary
    /// @dev priceX96 = pow(1.0001, boundary) * 2**96
    /// @param boundary The boundary to calculate the price at
    /// @return priceX96 The price at the boundary, as a Q64.96
    function getPriceX96AtBoundary(int24 boundary) internal pure returns (uint160 priceX96) {
        unchecked {
            uint256 absBoundary = boundary < 0 ? uint256(-int256(boundary)) : uint24(boundary);

            uint256 ratio = absBoundary & 0x1 != 0
                ? 0xfff97272373d413259a46990580e213a
                : 0x100000000000000000000000000000000;
            if (absBoundary & 0x2 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absBoundary & 0x4 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absBoundary & 0x8 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absBoundary & 0x10 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absBoundary & 0x20 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absBoundary & 0x40 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absBoundary & 0x80 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absBoundary & 0x100 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absBoundary & 0x200 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absBoundary & 0x400 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absBoundary & 0x800 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absBoundary & 0x1000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absBoundary & 0x2000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absBoundary & 0x4000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absBoundary & 0x8000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absBoundary & 0x10000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absBoundary & 0x20000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absBoundary & 0x40000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;
            if (absBoundary & 0x80000 != 0) ratio = (ratio * 0x149b34ee7ac263) >> 128;

            if (boundary > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 and rounds up to go from a Q128.128 to a Q128.96.
            // due to out boundary input limitations, we then proceed to downcast as the
            // result will always fit within 160 bits.
            // we round up in the division so that getBoundaryAtPriceX96 of the output price is always consistent
            priceX96 = uint160((ratio + 0xffffffff) >> 32);
        }
    }

    /// @notice Calculates the boundary at a given price
    /// @param priceX96 The price to calculate the boundary at, as a Q64.96
    /// @return boundary The boundary at the price
    function getBoundaryAtPriceX96(uint160 priceX96) internal pure returns (int24 boundary) {
        unchecked {
            uint256 ratio = uint256(priceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log10001 = log_2 * 127869479499801913173570;
            // 128.128 number

            int24 boundaryLow = int24((log10001 - 1701496478404566090792001455681771637) >> 128);
            int24 boundaryHi = int24((log10001 + 289637967442836604689790891002483458648) >> 128);

            boundary = boundaryLow == boundaryHi ? boundaryLow : getPriceX96AtBoundary(boundaryHi) <= priceX96
                ? boundaryHi
                : boundaryLow;
        }
    }

    /// @dev Returns the lower boundary for the given boundary and resolution.
    /// The lower boundary may not be valid (if out of the boundary range)
    /// @param boundary The boundary to get the lower boundary for
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    /// @return boundaryLower The lower boundary for the given boundary and resolution
    function getBoundaryLowerAtBoundary(int24 boundary, int24 resolution) internal pure returns (int24 boundaryLower) {
        unchecked {
            return boundary - (((boundary % resolution) + resolution) % resolution);
        }
    }

    /// @dev Rewrite the lower boundary that is not in the range to a valid value
    /// @param boundaryLower The lower boundary to rewrite
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    /// @return validBoundaryLower The valid lower boundary
    function rewriteToValidBoundaryLower(
        int24 boundaryLower,
        int24 resolution
    ) internal pure returns (int24 validBoundaryLower) {
        unchecked {
            if (boundaryLower < MIN_BOUNDARY) return boundaryLower + resolution;
            else if (boundaryLower + resolution > MAX_BOUNDARY) return boundaryLower - resolution;
            else return boundaryLower;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./GridAddress.sol";

library CallbackValidator {
    /// @dev Validates the `msg.sender` is the canonical grid address for the given parameters
    /// @param gridFactory The address of the grid factory
    /// @param gridKey The grid key to compute the canonical address for the grid
    function validate(address gridFactory, GridAddress.GridKey memory gridKey) internal view {
        // CV_IC: invalid caller
        require(GridAddress.computeAddress(gridFactory, gridKey) == msg.sender, "CV_IC");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";

library GridAddress {
    bytes32 internal constant GRID_BYTES_CODE_HASH = 0x884a6891a166f885bf6f0a3b330a25e41d1761a5aa091110a229d9a0e34b2c36;

    struct GridKey {
        address token0;
        address token1;
        int24 resolution;
    }

    /// @notice Constructs the grid key for the given parameters
    /// @dev tokenA and tokenB may be passed in, in the order of either token0/token1 or token1/token0
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    /// @return key The grid key to compute the canonical address for the grid
    function gridKey(address tokenA, address tokenB, int24 resolution) internal pure returns (GridKey memory key) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);

        return GridKey(tokenA, tokenB, resolution);
    }

    /// @dev Computes the CREATE2 address for a grid with the given parameters
    /// @param gridFactory The address of the grid factory
    /// @param key The grid key to compute the canonical address for the grid
    /// @return grid The computed address
    function computeAddress(address gridFactory, GridKey memory key) internal pure returns (address grid) {
        require(key.token0 < key.token1);
        return
            Create2.computeAddress(
                keccak256(abi.encode(key.token0, key.token1, key.resolution)),
                GRID_BYTES_CODE_HASH,
                gridFactory
            );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Callback for IGrid#swap
/// @notice Any contract that calls IGrid#swap must implement this interface
interface IGridSwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IGrid#swap
    /// @dev In this implementation, you are required to pay the grid tokens owed for the swap.
    /// The caller of the method must be a grid deployed by the canonical GridFactory.
    /// If there is no token swap, both amount0Delta and amount1Delta are 0
    /// @param amount0Delta The grid will send or receive the amount of token0 upon completion of the swap.
    /// In the receiving case, the callback must send this amount of token0 to the grid
    /// @param amount1Delta The grid will send or receive the quantity of token1 upon completion of the swap.
    /// In the receiving case, the callback must send this amount of token1 to the grid
    /// @param data Any data passed through by the caller via the IGrid#swap call
    function gridexSwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IGridStructs.sol";
import "./IGridParameters.sol";

/// @title The interface for Gridex grid
interface IGrid {
    ///==================================== Grid States  ====================================

    /// @notice The first token in the grid, after sorting by address
    function token0() external view returns (address);

    /// @notice The second token in the grid, after sorting by address
    function token1() external view returns (address);

    /// @notice The step size in initialized boundaries for a grid created with a given fee
    function resolution() external view returns (int24);

    /// @notice The fee paid to the grid denominated in hundredths of a bip, i.e. 1e-6
    function takerFee() external view returns (int24);

    /// @notice The 0th slot of the grid holds a lot of values that can be gas-efficiently accessed
    /// externally as a single method
    /// @return priceX96 The current price of the grid, as a Q64.96
    /// @return boundary The current boundary of the grid
    /// @return blockTimestamp The time the oracle was last updated
    /// @return unlocked Whether the grid is unlocked or not
    function slot0() external view returns (uint160 priceX96, int24 boundary, uint32 blockTimestamp, bool unlocked);

    /// @notice Returns the boundary information of token0
    /// @param boundary The boundary of the grid
    /// @return bundle0Id The unique identifier of bundle0
    /// @return bundle1Id The unique identifier of bundle1
    /// @return makerAmountRemaining The remaining amount of token0 that can be swapped out,
    /// which is the sum of bundle0 and bundle1
    function boundaries0(
        int24 boundary
    ) external view returns (uint64 bundle0Id, uint64 bundle1Id, uint128 makerAmountRemaining);

    /// @notice Returns the boundary information of token1
    /// @param boundary The boundary of the grid
    /// @return bundle0Id The unique identifier of bundle0
    /// @return bundle1Id The unique identifier of bundle1
    /// @return makerAmountRemaining The remaining amount of token1 that can be swapped out,
    /// which is the sum of bundle0 and bundle1
    function boundaries1(
        int24 boundary
    ) external view returns (uint64 bundle0Id, uint64 bundle1Id, uint128 makerAmountRemaining);

    /// @notice Returns 256 packed boundary initialized boolean values for token0
    function boundaryBitmaps0(int16 wordPos) external view returns (uint256 word);

    /// @notice Returns 256 packed boundary initialized boolean values for token1
    function boundaryBitmaps1(int16 wordPos) external view returns (uint256 word);

    /// @notice Returns the amount owed for token0 and token1
    /// @param owner The address of owner
    /// @return token0 The amount of token0 owed
    /// @return token1 The amount of token1 owed
    function tokensOweds(address owner) external view returns (uint128 token0, uint128 token1);

    /// @notice Returns the information of a given bundle
    /// @param bundleId The unique identifier of the bundle
    /// @return boundaryLower The lower boundary of the bundle
    /// @return zero When zero is true, it represents token0, otherwise it represents token1
    /// @return makerAmountTotal The total amount of token0 or token1 that the maker added
    /// @return makerAmountRemaining The remaining amount of token0 or token1 that can be swapped out from the makers
    /// @return takerAmountRemaining The remaining amount of token0 or token1 that have been swapped in from the takers
    /// @return takerFeeAmountRemaining The remaining amount of fees that takers have paid in
    function bundles(
        uint64 bundleId
    )
        external
        view
        returns (
            int24 boundaryLower,
            bool zero,
            uint128 makerAmountTotal,
            uint128 makerAmountRemaining,
            uint128 takerAmountRemaining,
            uint128 takerFeeAmountRemaining
        );

    /// @notice Returns the information of a given order
    /// @param orderId The unique identifier of the order
    /// @return bundleId The unique identifier of the bundle -- represents which bundle this order belongs to
    /// @return owner The address of the owner of the order
    /// @return amount The amount of token0 or token1 to add
    function orders(uint256 orderId) external view returns (uint64 bundleId, address owner, uint128 amount);

    ///==================================== Grid Actions ====================================

    /// @notice Initializes the grid with the given parameters
    /// @dev The caller of this method receives a callback in the form of
    /// IGridPlaceMakerOrderCallback#gridexPlaceMakerOrderCallback.
    /// When initializing the grid, token0 and token1's liquidity must be added simultaneously.
    /// @param parameters The parameters used to initialize the grid
    /// @param data Any data to be passed through to the callback
    /// @return orderIds0 The unique identifiers of the orders for token0
    /// @return orderIds1 The unique identifiers of the orders for token1
    function initialize(
        IGridParameters.InitializeParameters memory parameters,
        bytes calldata data
    ) external returns (uint256[] memory orderIds0, uint256[] memory orderIds1);

    /// @notice Swaps token0 for token1, or vice versa
    /// @dev The caller of this method receives a callback in the form of IGridSwapCallback#gridexSwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The swap direction, true for token0 to token1 and false otherwise
    /// @param amountSpecified The amount of the swap, configured as an exactInput (positive)
    /// or an exactOutput (negative)
    /// @param priceLimitX96 Swap price limit: if zeroForOne, the price will not be less than this value after swap,
    /// if oneForZero, it will not be greater than this value after swap, as a Q64.96
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The balance change of the grid's token0. When negative, it will reduce the balance
    /// by the exact amount. When positive, it will increase by at least this amount
    /// @return amount1 The balance change of the grid's token1. When negative, it will reduce the balance
    /// by the exact amount. When positive, it will increase by at least this amount.
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 priceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Places a maker order on the grid
    /// @dev The caller of this method receives a callback in the form of
    /// IGridPlaceMakerOrderCallback#gridexPlaceMakerOrderCallback
    /// @param parameters The parameters used to place the maker order
    /// @param data Any data to be passed through to the callback
    /// @return orderId The unique identifier of the order
    function placeMakerOrder(
        IGridParameters.PlaceOrderParameters memory parameters,
        bytes calldata data
    ) external returns (uint256 orderId);

    /// @notice Places maker orders on the grid
    /// @dev The caller of this method receives a callback in the form of
    /// IGridPlaceMakerOrderCallback#gridexPlaceMakerOrderCallback
    /// @param parameters The parameters used to place the maker orders
    /// @param data Any data to be passed through to the callback
    /// @return orderIds The unique identifiers of the orders
    function placeMakerOrderInBatch(
        IGridParameters.PlaceOrderInBatchParameters memory parameters,
        bytes calldata data
    ) external returns (uint256[] memory orderIds);

    /// @notice Settles a maker order
    /// @param orderId The unique identifier of the order
    /// @return amount0 The amount of token0 that the maker received
    /// @return amount1 The amount of token1 that the maker received
    function settleMakerOrder(uint256 orderId) external returns (uint128 amount0, uint128 amount1);

    /// @notice Settle maker order and collect
    /// @param recipient The address to receive the output of the settlement
    /// @param orderId The unique identifier of the order
    /// @param unwrapWETH9 Whether to unwrap WETH9 to ETH
    /// @return amount0 The amount of token0 that the maker received
    /// @return amount1 The amount of token1 that the maker received
    function settleMakerOrderAndCollect(
        address recipient,
        uint256 orderId,
        bool unwrapWETH9
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Settles maker orders and collects in a batch
    /// @param recipient The address to receive the output of the settlement
    /// @param orderIds The unique identifiers of the orders
    /// @param unwrapWETH9 Whether to unwrap WETH9 to ETH
    /// @return amount0Total The total amount of token0 that the maker received
    /// @return amount1Total The total amount of token1 that the maker received
    function settleMakerOrderAndCollectInBatch(
        address recipient,
        uint256[] memory orderIds,
        bool unwrapWETH9
    ) external returns (uint128 amount0Total, uint128 amount1Total);

    /// @notice For flash swaps. The caller borrows assets and returns them in the callback of the function,
    /// in addition to a fee
    /// @dev The caller of this function receives a callback in the form of IGridFlashCallback#gridexFlashCallback
    /// @param recipient The address which will receive the token0 and token1
    /// @param amount0 The amount of token0 to receive
    /// @param amount1 The amount of token1 to receive
    /// @param data Any data to be passed through to the callback
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;

    /// @notice Collects tokens owed
    /// @param recipient The address to receive the collected fees
    /// @param amount0Requested The maximum amount of token0 to send.
    /// Set to 0 if fees should only be collected in token1.
    /// @param amount1Requested The maximum amount of token1 to send.
    /// Set to 0 if fees should only be collected in token0.
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface ICurvePool {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external payable;

    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external payable;

    function get_dy(int128 i, int128 j, uint256 amount) external view returns (uint256);

    function get_dy_underlying(int128 i, int128 j, uint256 amount) external view returns (uint256);
}

interface ICurveLendingBasePoolMetaZap {
    function exchange_underlying(address pool, int128 i, int128 j, uint256 dx, uint256 min_dy) external;
}

interface ICurveLendingBasePool3Coins {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount, bool use_underlying) external;

    function calc_token_amount(uint256[3] memory amounts, bool is_deposit) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 i,
        uint256 min_amount,
        bool use_underlying
    ) external returns (uint256);

    function calc_withdraw_one_coin(uint256 token_amount, int128 i) external view returns (uint256);
}

interface ICurveCryptoPool {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external payable;

    function exchange_underlying(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external payable;

    function get_dy(uint256 i, uint256 j, uint256 amount) external view returns (uint256);

    function get_dy_underlying(uint256 i, uint256 j, uint256 amount) external view returns (uint256);
}

interface ICurveCryptoMetaZap {
    function get_dy(address pool, uint256 i, uint256 j, uint256 dx) external view returns (uint256);

    function exchange(address pool, uint256 i, uint256 j, uint256 dx, uint256 min_dy, bool use_eth) external payable;
}

interface ICurveBasePool3Coins {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;

    function calc_token_amount(uint256[3] memory amounts, bool is_deposit) external view returns (uint256);

    function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external;

    function calc_withdraw_one_coin(uint256 token_amount, int128 i) external view returns (uint256);
}

interface ICurveBasePool2Coins {
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external;

    function calc_token_amount(uint256[2] memory amounts, bool is_deposit) external view returns (uint256);

    function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external;

    function calc_withdraw_one_coin(uint256 token_amount, int128 i) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

// EIP-2612 is Final as of 2022-11-01. This file is deprecated.

import "./IERC20Permit.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any native token(e.g. ETH) balance held by this contract to the `msg.sender`
    /// @dev This method is suitable for the following 2 scenarios:
    /// 1. When using exactInput, the inputted Ether is not fully consumed due to insufficient liquidity so,
    ///    remaining Ether can be withdrawn through this method
    /// 2. When using exactOutput, the inputted Ether is not fully consumed because the slippage settings
    /// are too high, henceforth, the remaining Ether can be withdrawn through this method
    function refundNativeToken() external payable;

    /// @notice Transfers the full amount of a token held by this contract to a recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the tokens which will be transferred to the `recipient`
    /// @param amountMinimum The minimum amount of tokens required for a transfer
    /// @param recipient The destination address of the tokens
    function sweepToken(address token, uint256 amountMinimum, address recipient) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IWETHMinimum {
    function deposit() external payable;

    function transfer(address dst, uint256 wad) external returns (bool);

    function withdraw(uint256) external;

    function approve(address guy, uint256 wad) external returns (bool);

    function balanceOf(address dst) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IGridParameters {
    /// @dev Parameters for initializing the grid
    struct InitializeParameters {
        /// @dev The initial price of the grid, as a Q64.96.
        /// Price is represented as an amountToken1/amountToken0 Q64.96 value.
        uint160 priceX96;
        /// @dev The address to receive orders
        address recipient;
        /// @dev Represents the order parameters for token0
        BoundaryLowerWithAmountParameters[] orders0;
        /// @dev Represents the order parameters for token1
        BoundaryLowerWithAmountParameters[] orders1;
    }

    /// @dev Parameters for placing an order
    struct PlaceOrderParameters {
        /// @dev The address to receive the order
        address recipient;
        /// @dev When zero is true, it represents token0, otherwise it represents token1
        bool zero;
        /// @dev The lower boundary of the order
        int24 boundaryLower;
        /// @dev The amount of token0 or token1 to add
        uint128 amount;
    }

    struct PlaceOrderInBatchParameters {
        /// @dev The address to receive the order
        address recipient;
        /// @dev When zero is true, it represents token0, otherwise it represents token1
        bool zero;
        BoundaryLowerWithAmountParameters[] orders;
    }

    struct BoundaryLowerWithAmountParameters {
        /// @dev The lower boundary of the order
        int24 boundaryLower;
        /// @dev The amount of token0 or token1 to add
        uint128 amount;
    }

    /// @dev Status during swap
    struct SwapState {
        /// @dev When true, token0 is swapped for token1, otherwise token1 is swapped for token0
        bool zeroForOne;
        /// @dev The remaining amount of the swap, which implicitly configures
        /// the swap as exact input (positive), or exact output (negative)
        int256 amountSpecifiedRemaining;
        /// @dev The calculated amount to be inputted
        uint256 amountInputCalculated;
        /// @dev The calculated amount of fee to be inputted
        uint256 feeAmountInputCalculated;
        /// @dev The calculated amount to be outputted
        uint256 amountOutputCalculated;
        /// @dev The price of the grid, as a Q64.96
        uint160 priceX96;
        uint160 priceLimitX96;
        /// @dev The boundary of the grid
        int24 boundary;
        /// @dev The lower boundary of the grid
        int24 boundaryLower;
        uint160 initializedBoundaryLowerPriceX96;
        uint160 initializedBoundaryUpperPriceX96;
        /// @dev Whether the swap has been completed
        bool stopSwap;
    }

    struct SwapForBoundaryState {
        /// @dev The price indicated by the lower boundary, as a Q64.96
        uint160 boundaryLowerPriceX96;
        /// @dev The price indicated by the upper boundary, as a Q64.96
        uint160 boundaryUpperPriceX96;
        /// @dev The price indicated by the lower or upper boundary, as a Q64.96.
        /// When using token0 to exchange token1, it is equal to boundaryLowerPriceX96,
        /// otherwise it is equal to boundaryUpperPriceX96
        uint160 boundaryPriceX96;
        /// @dev The price of the grid, as a Q64.96
        uint160 priceX96;
    }

    struct UpdateBundleForTakerParameters {
        /// @dev The amount to be swapped in to bundle0
        uint256 amountInUsed;
        /// @dev The remaining amount to be swapped in to bundle1
        uint256 amountInRemaining;
        /// @dev The amount to be swapped out to bundle0
        uint128 amountOutUsed;
        /// @dev The remaining amount to be swapped out to bundle1
        uint128 amountOutRemaining;
        /// @dev The amount to be paid to bundle0
        uint128 takerFeeForMakerAmountUsed;
        /// @dev The amount to be paid to bundle1
        uint128 takerFeeForMakerAmountRemaining;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IGridStructs {
    struct Bundle {
        int24 boundaryLower;
        bool zero;
        uint128 makerAmountTotal;
        uint128 makerAmountRemaining;
        uint128 takerAmountRemaining;
        uint128 takerFeeAmountRemaining;
    }

    struct Boundary {
        uint64 bundle0Id;
        uint64 bundle1Id;
        uint128 makerAmountRemaining;
    }

    struct Order {
        uint64 bundleId;
        address owner;
        uint128 amount;
    }

    struct TokensOwed {
        uint128 token0;
        uint128 token1;
    }

    struct Slot0 {
        uint160 priceX96;
        int24 boundary;
        uint32 blockTimestamp;
        bool unlocked;
    }
}