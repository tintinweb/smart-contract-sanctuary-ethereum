// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "../libraries/UniswapV2Library.sol";
import "../libraries/SafeMath.sol";
import "../libraries/TransferHelper.sol";
import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IERC20.sol";

interface ITreasuryXOX {
    function swapUSDtoXOX(address from, address ref, uint256 amount) external;
}

contract UniswapV2RouterETH is IUniswapV2Router {
    using SafeMathUniswap for uint256;

    address public immutable override factory;
    address public override pair;
    address private token0; // XOX
    address private treasury; // wallet profit
    address private trading; // wallet trading
    address private admin;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "XOXSwapRouter: EXPIRED");
        _;
    }

    constructor(address _factory, address _treasury, address _trading) public {
        factory = _factory;
        pair = IUniswapV2Factory(_factory).pair();
        token0 = IUniswapV2Pair(pair).token0();
        treasury = _treasury;
        admin = msg.sender;
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal view returns (uint256 amountA, uint256 amountB) {
        (uint256 reserveA, uint256 reserveB, ) = UniswapV2LibraryETH
            .getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = UniswapV2LibraryETH.quote(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    "XOXSwapRouter: INSUFFICIENT_B_AMOUNT"
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = UniswapV2LibraryETH.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= amountAMin,
                    "XOXSwapRouter: INSUFFICIENT_A_AMOUNT"
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256 amountA, uint256 amountB, uint256 liquidity)
    {
        (amountA, amountB) = _addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        public
        virtual
        override
        ensure(deadline)
        returns (uint256 amountA, uint256 amountB)
    {
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IUniswapV2Pair(pair).burn(to);
        (amountA, amountB) = tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);
        require(amountA >= amountAMin, "XOXSwapRouter: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "XOXSwapRouter: INSUFFICIENT_B_AMOUNT");
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountA, uint256 amountB) {
        uint256 value = approveMax ? uint256(-1) : liquidity;
        IUniswapV2Pair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        (amountA, amountB) = removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256 amountOut,
        address tokenIn,
        address _to
    ) internal virtual {
        (uint256 amount0Out, uint256 amount1Out) = tokenIn == token0
            ? (uint256(0), amountOut)
            : (amountOut, uint256(0));
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, _to, new bytes(0));
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address ref,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        if (msg.sender == trading) {
            amounts = UniswapV2LibraryETH.getAmountsOutSwap(
                factory,
                amountIn,
                path
            );
            require(
                amounts[1] >= amountOutMin,
                "XOXSwapRouter: INSUFFICIENT_OUTPUT_AMOUNT"
            );
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                pair,
                amounts[0]
            );
            _swap(amounts[1], path[0], msg.sender);
            return amounts;
        }
        // casse swap BUSD -> XOX
        if (path[0] != token0) {
            require(ref != msg.sender, "XOXSwapRouter: ref valid");
            amounts = UniswapV2LibraryETH.getAmountsOut(
                factory,
                amountIn,
                path
            );
            require(
                amounts[1] >= amountOutMin,
                "XOXSwapRouter: INSUFFICIENT_OUTPUT_AMOUNT"
            );
            uint256 taxFee = amounts[0].mul(10) / 100;
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                treasury,
                taxFee
            ); // send profitWallet
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                pair,
                amounts[0].sub(taxFee)
            ); // send PAIR to swap
            _swap(amounts[1], path[0], msg.sender);
            // update treasury
            ITreasuryXOX(treasury).swapUSDtoXOX(msg.sender, ref, amounts[0]);
        } else {
            // case swap XOX -> BUSD
            amounts = UniswapV2LibraryETH.getAmountsOutSwap(
                factory,
                amountIn,
                path
            );
            require(
                (amounts[1].mul(90) / 100) >= amountOutMin,
                "XOXSwapRouter: INSUFFICIENT_OUTPUT_AMOUNT"
            );
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                pair,
                amounts[0]
            );
            _swap(amounts[1], path[0], msg.sender);
        }
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address ref,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        if (msg.sender == trading) {
            amounts = UniswapV2LibraryETH.getAmountsInSwap(
                factory,
                amountOut,
                path
            );
            require(
                amounts[0] <= amountInMax,
                "XOXSwapRouter: EXCESSIVE_INPUT_AMOUNT"
            );
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                pair,
                amounts[0]
            );
            _swap(amounts[1], path[0], msg.sender);
        }
        // casse swap BUSD -> XOX
        if (path[0] != token0) {
            require(ref != msg.sender, "XOXSwapRouter: ref valid");
            amounts = UniswapV2LibraryETH.getAmountsIn(
                factory,
                amountOut,
                path
            );
            require(
                amounts[0] <= amountInMax,
                "XOXSwapRouter: EXCESSIVE_INPUT_AMOUNT"
            );
            uint256 taxFee = amounts[0].mul(10) / 100;
            TransferHelper.safeTransferFrom(path[0], msg.sender, pair, taxFee); // send profitWallet
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                pair,
                amounts[0].sub(taxFee)
            ); // send PAIR to swap
            _swap(amounts[1], path[0], msg.sender);
            // update treasury
            ITreasuryXOX(treasury).swapUSDtoXOX(msg.sender, ref, amounts[0]);
        } else {
            // case swap XOX -> BUSD
            amounts = UniswapV2LibraryETH.getAmountsInSwap(
                factory,
                amountOut,
                path
            );
            require(
                amounts[0] <= amountInMax,
                "XOXSwapRouter: EXCESSIVE_INPUT_AMOUNT"
            );
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                pair,
                amounts[0]
            );
            _swap(amounts[1], path[0], msg.sender);
            // update treasury
        }
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) public pure virtual override returns (uint256 amountB) {
        return UniswapV2LibraryETH.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure virtual override returns (uint256 amountOut) {
        return
            UniswapV2LibraryETH.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure virtual override returns (uint256 amountIn) {
        return
            UniswapV2LibraryETH.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(
        uint256 amountIn,
        address[] memory path
    ) public view virtual override returns (uint256[] memory amounts) {
        return UniswapV2LibraryETH.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(
        uint256 amountOut,
        address[] memory path
    ) public view virtual override returns (uint256[] memory amounts) {
        return UniswapV2LibraryETH.getAmountsIn(factory, amountOut, path);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";

import "./SafeMath.sol";

library UniswapV2LibraryBSC {
    using SafeMathUniswap for uint256;

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    )
        internal
        view
        returns (
            uint256 reserveA,
            uint256 reserveB,
            address token0
        )
    {
        address pair = IUniswapV2Factory(factory).pair();
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair)
            .getReserves();
        token0 = IUniswapV2Pair(pair).token0();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(9975);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(10000);
        uint256 denominator = reserveOut.sub(amountOut).mul(9975);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length == 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](2);
        amounts[0] = amountIn;
        (uint256 reserveIn, uint256 reserveOut, address xox) = getReserves(
            factory,
            path[0],
            path[1]
        );
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        if (path[0] == xox) {
            uint256 amountInWithFee = amountIn.mul(9975);
            uint256 numerator = amountInWithFee.mul(reserveOut);
            uint256 denominator = reserveIn.mul(10000).add(amountInWithFee);
            amounts[1] = (numerator / denominator).mul(90) / 100;
        } else {
            amountIn = amountIn.mul(90) / 100;
            uint256 amountInWithFee = amountIn.mul(9975);
            uint256 numerator = amountInWithFee.mul(reserveOut);
            uint256 denominator = reserveIn.mul(10000).add(amountInWithFee);
            amounts[1] = numerator / denominator;
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length == 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](2);
        amounts[1] = amountOut;
        (uint256 reserveIn, uint256 reserveOut, address xox) = getReserves(
            factory,
            path[0],
            path[1]
        );

        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        if (path[0] == xox) {
            amountOut = amountOut.mul(100) / 90;
            uint256 numerator = reserveIn.mul(amountOut).mul(10000);
            uint256 denominator = reserveOut.sub(amountOut).mul(9975);
            amounts[0] = (numerator / denominator).add(1);
        } else {
            uint256 numerator = reserveIn.mul(amountOut).mul(10000);
            uint256 denominator = reserveOut.sub(amountOut).mul(9975);
            amounts[0] = ((numerator / denominator).add(1)).mul(100) / 90;
        }
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOutSwap(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length == 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](2);
        amounts[0] = amountIn;
        (uint256 reserveIn, uint256 reserveOut,) = getReserves(
            factory,
            path[0],
            path[1]
        );
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amounts[1] = getAmountOut(amounts[0], reserveIn, reserveOut);
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsInSwap(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length == 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](2);
        amounts[1] = amountOut;
        (uint256 reserveIn, uint256 reserveOut,) = getReserves(
            factory,
            path[0],
            path[1]
        );

        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amounts[0] = getAmountIn(amounts[1], reserveIn, reserveOut);
    }
}

library UniswapV2LibraryETH {
    using SafeMathUniswap for uint256;

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    )
        internal
        view
        returns (
            uint256 reserveA,
            uint256 reserveB,
            address token0
        )
    {
        address pair = IUniswapV2Factory(factory).pair();
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair)
            .getReserves();
        token0 = IUniswapV2Pair(pair).token0();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length == 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](2);
        amounts[0] = amountIn;
        (uint256 reserveIn, uint256 reserveOut, address xox) = getReserves(
            factory,
            path[0],
            path[1]
        );
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        if (path[0] == xox) {
            uint256 amountInWithFee = amountIn.mul(997);
            uint256 numerator = amountInWithFee.mul(reserveOut);
            uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
            amounts[1] = (numerator / denominator).mul(90) / 100;
        } else {
            amountIn = amountIn.mul(90) / 100;
            uint256 amountInWithFee = amountIn.mul(997);
            uint256 numerator = amountInWithFee.mul(reserveOut);
            uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
            amounts[1] = numerator / denominator;
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length == 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](2);
        amounts[1] = amountOut;
        (uint256 reserveIn, uint256 reserveOut, address xox) = getReserves(
            factory,
            path[0],
            path[1]
        );

        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        if (path[0] == xox) {
            amountOut = amountOut.mul(100) / 90;
            uint256 numerator = reserveIn.mul(amountOut).mul(1000);
            uint256 denominator = reserveOut.sub(amountOut).mul(997);
            amounts[0] = (numerator / denominator).add(1);
        } else {
            uint256 numerator = reserveIn.mul(amountOut).mul(1000);
            uint256 denominator = reserveOut.sub(amountOut).mul(997);
            amounts[0] = ((numerator / denominator).add(1)).mul(100) / 90;
        }
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOutSwap(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length == 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](2);
        amounts[0] = amountIn;
        (uint256 reserveIn, uint256 reserveOut,) = getReserves(
            factory,
            path[0],
            path[1]
        );
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amounts[1] = getAmountOut(amounts[0], reserveIn, reserveOut);
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsInSwap(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length == 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](2);
        amounts[1] = amountOut;
        (uint256 reserveIn, uint256 reserveOut,) = getReserves(
            factory,
            path[0],
            path[1]
        );

        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amounts[0] = getAmountIn(amounts[1], reserveIn, reserveOut);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function pair() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair);

    function xox() external view returns (address);
    function usd() external view returns (address);
    function pair() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IERC20Uniswap {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}