//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "IUniswapV2Router01.sol";
import "IUniswapV2Pair.sol";
import "IUniswapV2Factory.sol";
import "IERC20.sol";

contract fullflash {
    address public dai_token;
    address public weth_token;
    address public factory;
    address public UniswapRouter;
    address public SushiswapRouter;
    address public paraswapRouter;
    address public shibaswapRouter;
    address public pancakeswapRouter;

    enum Dex {
        Uniswap,
        Sushiwap,
        Paraswap,
        Shibaswap,
        Pancakeswap,
        None
    }

    constructor(
        address _dai_token,
        address _weth_token,
        address _factory,
        address _UniswapRouter,
        address _SushiswapRouter,
        address _paraswapRouter,
        address _shibaswapRouter,
        address _pancakeswapRouter
    ) {
        dai_token = _dai_token;
        weth_token = _weth_token;
        factory = _factory;
        UniswapRouter = _UniswapRouter;
        SushiswapRouter = _SushiswapRouter;
        paraswapRouter = _paraswapRouter;
        shibaswapRouter = _shibaswapRouter;
        pancakeswapRouter = _pancakeswapRouter;
    }

    function HighestExchange(uint256 amount) public view returns (Dex) {
        uint256 forUni = getDAi_Eth_Uniswap(amount);
        uint256 forSushi = getDAi_Eth_Sushiswap(amount);

        if (forUni > forSushi) {
            return Dex.Uniswap;
        }
        if (forSushi > forUni) {
            return Dex.Sushiwap;
        } else {
            return Dex.None;
        }
    }

    function getDAi_Eth_Uniswap(uint256 amm) public view returns (uint256) {
        address pairaddress = IUniswapV2Factory(factory).getPair(
            dai_token,
            weth_token
        );

        address token0 = IUniswapV2Pair(pairaddress).token0();
        address token1 = IUniswapV2Pair(pairaddress).token1();
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        uint256 amountout = IUniswapV2Router01(UniswapRouter).getAmountsOut(
            amm,
            path
        )[1];
        return amountout;
    }

    function getDAi_Eth_Sushiswap(uint256 amm) public view returns (uint256) {
        address pairaddress = IUniswapV2Factory(factory).getPair(
            dai_token,
            weth_token
        );

        address token0 = IUniswapV2Pair(pairaddress).token0();
        address token1 = IUniswapV2Pair(pairaddress).token1();
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        uint256 amountout = IUniswapV2Router01(SushiswapRouter).getAmountsOut(
            amm,
            path
        )[1];
        return amountout;
    }

    function doSwap(
        address router,
        address first,
        address second,
        uint256 amount
    ) internal returns (uint256) {
        IERC20(first).approve(router, amount);

        uint256 minAmountOut = (getPrice(router, first, second, amount) * 95) /
            100;

        address pairaddress = IUniswapV2Factory(factory).getPair(first, second);

        address token0 = IUniswapV2Pair(pairaddress).token0();
        address token1 = IUniswapV2Pair(pairaddress).token1();
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        uint256 amountout = IUniswapV2Router01(router).swapExactTokensForTokens(
            amount,
            minAmountOut,
            path,
            address(this),
            block.timestamp
        )[1];
        return amountout;
    }

    function isProfitable(
        address router1,
        address router2,
        address first,
        address second,
        uint256 amount
    ) public view returns (bool) {
        address pairaddress = IUniswapV2Factory(factory).getPair(first, second);

        address token0 = IUniswapV2Pair(pairaddress).token0();
        address token1 = IUniswapV2Pair(pairaddress).token1();
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        address[] memory path1 = new address[](2);
        path1[1] = token0;
        path1[0] = token1;
        uint256 price1 = IUniswapV2Router01(router1).getAmountsOut(
            amount,
            path
        )[1];
        uint256 price2 = IUniswapV2Router01(router2).getAmountsOut(
            price1,
            path1
        )[1];
        uint256 profit = price2 - amount;
        uint256 fee = (2 * (amount * 3)) / 1000;
        if (profit > fee) {
            return true;
        } else {
            return false;
        }
    }

    function getPrice(
        address router,
        address first,
        address second,
        uint256 amount
    ) public view returns (uint256) {
        address pairaddress = IUniswapV2Factory(factory).getPair(first, second);

        address token0 = IUniswapV2Pair(pairaddress).token0();
        address token1 = IUniswapV2Pair(pairaddress).token1();
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        uint256 price = IUniswapV2Router01(router).getAmountsOut(amount, path)[
            1
        ];
        return price;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
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

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

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

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

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

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

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

//SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}