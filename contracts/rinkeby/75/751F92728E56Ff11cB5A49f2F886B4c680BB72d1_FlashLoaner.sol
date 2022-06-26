/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

library UniswapV2Library {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address targetPair,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(targetPair)
            .getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
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
        address targetPair,
        uint256 amountIn,
        address[2] memory path
    ) internal view returns (uint256[2] memory amounts) {
        amounts[0] = amountIn;
        (uint256 reserveIn, uint256 reserveOut) = getReserves(
            targetPair,
            path[0],
            path[1]
        );
        amounts[1] = getAmountOut(amounts[0], reserveIn, reserveOut);
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address targetPair,
        uint256 amountOut,
        address[2] memory path
    ) internal view returns (uint256[2] memory amounts) {
        amounts[1] = amountOut;
        (uint256 reserveIn, uint256 reserveOut) = getReserves(
            targetPair,
            path[1],
            path[0]
        );
        amounts[0] = getAmountIn(amounts[1], reserveIn, reserveOut);
    }
}

interface IERC20 {
    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);
}

interface IWETH {
    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function balanceOf(address owner) external view returns (uint256);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

contract FlashLoaner is IUniswapV2Callee {
    address immutable SushiFactory;
    address immutable UniswapFactory;
    address immutable WETH;
    address immutable Owner;

    event Withdraw(address token, uint256 amount);
    event Earn(uint256 earnValue);
    event Deposit(address sender, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == Owner, "Only owner");
        _;
    }

    constructor() {
        SushiFactory = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
        UniswapFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        Owner = msg.sender;
    }

    struct GasCost {
        uint256 gasLimit;
        uint256 gasPrice;
    }

    function decodeGasCost(bytes memory data)
        public
        pure
        returns (GasCost memory)
    {
        return abi.decode(data, (GasCost));
    }

    function uniswapV2Call(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        // only loan token, to swap weth and withdraw to eth
        require(_amount0 == 0 || _amount1 == 0);
        address[2] memory path;
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();

        // path[1] always is weth
        path[0] = _amount0 == 0 ? token1 : token0;
        path[1] = _amount0 == 0 ? token0 : token1;
        require(path[1] == WETH, "uniswapV2Call:path[1] must equals weth");
        uint256 amountToken = _amount0 == 0 ? _amount1 : _amount0;
        address targetPair;
        if (IUniswapV2Pair(msg.sender).factory() == SushiFactory) {
            targetPair = IUniswapV2Factory(UniswapFactory).getPair(
                token0,
                token1
            );
        } else {
            targetPair = IUniswapV2Factory(SushiFactory).getPair(
                token0,
                token1
            );
        }
        uint256 amountReceived = swapExactTokensForTokens(
            targetPair,
            amountToken,
            0,
            path,
            address(this)
        )[1];

        // no need for require() check, if amount required is not sent sushiRouter will revert
        uint256 amountRequired = UniswapV2Library.getAmountsIn(
            msg.sender,
            amountToken,
            path
        )[0];

        GasCost memory gasCost = decodeGasCost(_data);
        uint256 earnValue = amountReceived -
            amountRequired -
            gasCost.gasLimit *
            gasCost.gasPrice;

        require(earnValue > 0, "Revert: Not earn!");

        IERC20(path[1]).transfer(msg.sender, amountRequired);
        IWETH(WETH).withdraw(IWETH(WETH).balanceOf(address(this)));
        payable(_sender).transfer(address(this).balance);
        emit Earn(
            earnValue
        );
    }

    function withdrawToken(address token, uint256 amount) public onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
        emit Withdraw(token, amount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
        emit Withdraw(address(0), amount);
    }

    function swapExactTokensForTokens(
        address targetPair,
        uint256 amountIn,
        uint256 amountOutMin,
        address[2] memory path,
        address to
    ) internal returns (uint256[2] memory amounts) {
        amounts = UniswapV2Library.getAmountsOut(targetPair, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IERC20(path[0]).transfer(targetPair, amounts[0]);
        _swap(targetPair, amounts, path, to);
    }

    // **** SWAP ****
    function _swap(
        address targetPair,
        uint256[2] memory amounts,
        address[2] memory path,
        address to
    ) internal virtual {
        (address token0, ) = UniswapV2Library.sortTokens(path[0], path[1]);
        uint256 amountOut = amounts[1];
        (uint256 amount0Out, uint256 amount1Out) = path[0] == token0
            ? (uint256(0), amountOut)
            : (amountOut, uint256(0));
        IUniswapV2Pair(targetPair).swap(
            amount0Out,
            amount1Out,
            to,
            new bytes(0)
        );
    }

    fallback() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
}