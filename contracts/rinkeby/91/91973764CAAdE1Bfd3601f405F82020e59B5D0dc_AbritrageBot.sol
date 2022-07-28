/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: MIT
// File: contracts/interfaces/IUniswapV2.sol


pragma solidity >=0.6.12;

interface IUniswapV2Pair {
    function token0() external pure returns (address);
    function token1() external pure returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Library {
    function getAmountsIn(address factory, uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Factory {
    function getPair(address token0, address token1) external pure returns (address);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ;
}

// File: contracts/libs/SafeMath.sol

pragma solidity >=0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
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

// File: contracts/libs/UniswapV2Library.sol

pragma solidity >=0.5.0;


library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: contracts/interfaces/IERC20.sol


pragma solidity >=0.6.12;

interface IERC20 {
    function transfer(address receiver, uint256 amount) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

// File: contracts/AbritrageBot.sol


pragma solidity >=0.6.12;



contract AbritrageBot {
    address owner;

    // tokens addresses
    IUniswapV2Pair loanTargetPool;
    address loanToken;
    uint256 loanAmount;

    // uniswap factory and router addresses
    IUniswapV2Router loanTargetRouter;
    IUniswapV2Factory loanTargetFactory;
    IUniswapV2Library loanTargetDexLibrary;

    IUniswapV2Router tradeTargetRouter;

    constructor() {
        owner = msg.sender;
    }

    function call(
        address loanToken_,
        uint256 loanAmount_,
        address loanTargetPool_,

        address loanTargetFactory_,
        address loanTargetRouter_,
        address loanTargetDexLibrary_,
        address tradeTargetRouter_
    ) public {
        loanToken = loanToken_;
        loanAmount = loanAmount_;

        loanTargetPool = IUniswapV2Pair(loanTargetPool_);

        loanTargetFactory = IUniswapV2Factory(loanTargetFactory_);
        loanTargetRouter = IUniswapV2Router(loanTargetRouter_);
        loanTargetDexLibrary = IUniswapV2Library(loanTargetDexLibrary_);
        tradeTargetRouter = IUniswapV2Router(tradeTargetRouter_);

        // loan token
        address loanPairToken0 = loanTargetPool.token0();
        uint256 amount0Out = loanPairToken0 == loanToken_ ? 0 : loanAmount_;
        uint256 amount1Out = loanPairToken0 == loanToken_ ? loanAmount_ : 0;

        bytes memory data = abi.encode(loanToken_, loanAmount_);
        loanTargetPool.swap(amount0Out, amount1Out, address(this), data);
    }

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) public {
        address[] memory loanPath = new address[](2);
        address[] memory tradePath = new address[](2);
        uint256 loanAmountGiven;
        {
            // scope for token{0,1}, avoids stack too deep errors
            address token0 = IUniswapV2Pair(msg.sender).token0(); // fetch the address of token0
            address token1 = IUniswapV2Pair(msg.sender).token1(); // fetch the address of token1
            assert(
                msg.sender ==
                    IUniswapV2Factory(loanTargetFactory).getPair(token0, token1)
            ); // ensure that msg.sender is a V2 pair

            assert(amount0 == 0 || amount1 == 0); // this strategy is unidirectional

            loanPath[0] = amount0 == 0 ? token0 : token1;
            loanPath[1] = amount0 == 0 ? token1 : token0;

            tradePath[0] = loanPath[1];
            tradePath[1] = loanPath[0];
            loanAmountGiven = amount0 == 0 ? amount1 : amount0;
        }

        // swap on apeswap and repay loan back to pancakeswap

        uint256 amountRequired = UniswapV2Library.getAmountsIn(
            address(loanTargetFactory),
            loanAmountGiven,
            loanPath
        )[0];

        IERC20(tradePath[0]).approve(address(tradeTargetRouter), loanAmount);
        uint256 amountReceived = tradeTargetRouter.swapExactTokensForTokens(
            loanAmountGiven,
            amountRequired,
            tradePath,
            address(this),
            block.timestamp
        )[tradePath.length - 1];

        assert(amountReceived > amountRequired); // fail if we didn't get enough tokens back to repay our flash loan
        assert(IERC20(tradePath[1]).transfer(msg.sender, amountRequired)); // return tokens to pay back aux
        assert(
            IERC20(tradePath[1]).transfer(owner, amountReceived - amountRequired)
        ); // keep the rest! (tokens)
    }
}