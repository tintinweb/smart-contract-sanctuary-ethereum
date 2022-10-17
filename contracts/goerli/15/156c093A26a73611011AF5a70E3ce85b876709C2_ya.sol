//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "IUniswapV2Router02.sol";
import "IUniswapV2Pair.sol";
import "IUniswapV2Factory.sol";
import "IUniswapV2Library.sol";
import "IERC20.sol";
import "ITransferHelper.sol";
import "IWETH.sol";

contract ya {
    address public dai_token;
    address public weth_token;
    address public factoryy;
    address public UniswapRouter;
    address public SushiswapRouter;
    address public paraswapRouter;
    address public shibaswapRouter;
    address public pancakeswapRouter;
    address payable public owner;

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
        factoryy = _factory;
        UniswapRouter = _UniswapRouter;
        SushiswapRouter = _SushiswapRouter;
        paraswapRouter = _paraswapRouter;
        shibaswapRouter = _shibaswapRouter;
        pancakeswapRouter = _pancakeswapRouter;
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    function performArb() public onlyOwner {
        uint256 amount = IERC20(dai_token).balanceOf(address(this));
        Dex dexIndex = HighestExchange(amount);
        if (dexIndex == Dex.Sushiwap) {
            if (
                isProfitable(
                    SushiswapRouter,
                    UniswapRouter,
                    dai_token,
                    weth_token,
                    amount
                )
            ) {
                uint256 camein = doSwap(
                    SushiswapRouter,
                    dai_token,
                    weth_token,
                    amount
                );
                doSwap(UniswapRouter, weth_token, dai_token, camein);
            }
        } else if (dexIndex == Dex.Uniswap) {
            if (
                isProfitable(
                    UniswapRouter,
                    SushiswapRouter,
                    dai_token,
                    weth_token,
                    amount
                )
            ) {
                uint256 camein = doSwap(
                    UniswapRouter,
                    weth_token,
                    dai_token,
                    amount
                );

                doSwap(SushiswapRouter, dai_token, weth_token, camein);
            }
        } else {}
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
        address pairaddress = IUniswapV2Factory(factoryy).getPair(
            dai_token,
            weth_token
        );
        address token0 = IUniswapV2Pair(pairaddress).token0();
        address token1 = IUniswapV2Pair(pairaddress).token1();
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        uint256 amountout = IUniswapV2Router02(UniswapRouter).getAmountsOut(
            amm,
            path
        )[1];
        return amountout;
    }

    function getDAi_Eth_Sushiswap(uint256 amm) public view returns (uint256) {
        address pairaddress = IUniswapV2Factory(factoryy).getPair(
            dai_token,
            weth_token
        );
        address token0 = IUniswapV2Pair(pairaddress).token0();
        address token1 = IUniswapV2Pair(pairaddress).token1();
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        uint256 amountout = IUniswapV2Router02(SushiswapRouter).getAmountsOut(
            amm,
            path
        )[1];
        return amountout;
    }

    function approveMytoken(
        address token,
        address router,
        uint256 amounnt
    ) public returns (bool) {
        return IERC20(token).approve(router, amounnt);
    }

    function MyWethBalance() public view returns (uint256) {
        uint256 ayoo = IERC20(weth_token).balanceOf(owner);

        return ayoo;
    }

    function contractWethBalance() public view returns (uint256) {
        uint256 ayoo = IERC20(weth_token).balanceOf(address(this));

        return ayoo;
    }

    function myDaiBalance() public view returns (uint256) {
        uint256 ayoo = IERC20(dai_token).balanceOf(owner);
        return ayoo;
    }

    function getWethtoContract() public view onlyOwner returns (string memory) {
        return IWETH(weth_token).name();
    }

    function performWithdrawWeth() public onlyOwner {
        IWETH(weth_token).withdraw(IERC20(weth_token).balanceOf(address(this)));
    }

    function fundContract() public payable {}

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getContractBalanceEth() public view returns (uint256) {
        return address(this).balance;
    }

    function performSafeApprove(
        address token,
        address router,
        uint256 amoun
    ) public onlyOwner returns (bool) {
        return IERC20(token).approve(router, amoun);
    }

    function doSwap(
        address router,
        address first,
        address second,
        uint256 amount
    ) public onlyOwner returns (uint256) {
        uint256 minAmountOut = (getPrice(router, first, second, amount) * 50) /
            100;

        address pairaddress = IUniswapV2Factory(factoryy).getPair(
            first,
            second
        );

        address token0 = IUniswapV2Pair(pairaddress).token0();
        address token1 = IUniswapV2Pair(pairaddress).token1();
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        performSafeApprove(token0, router, amount);
        // IERC20(token).approve(router, amoun);
        IERC20(token0).allowance(owner, router);

        uint256 amountt = IUniswapV2Router02(router).swapExactTokensForTokens(
            amount,
            minAmountOut,
            path,
            msg.sender,
            block.timestamp
        )[1];
        return amountt;
    }

    function isProfitable(
        address router1,
        address router2,
        address first,
        address second,
        uint256 amount
    ) public view returns (bool) {
        address pairaddress = IUniswapV2Factory(factoryy).getPair(
            first,
            second
        );

        address token0 = IUniswapV2Pair(pairaddress).token0();
        address token1 = IUniswapV2Pair(pairaddress).token1();
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        address[] memory path1 = new address[](2);
        path1[1] = token0;
        path1[0] = token1;
        uint256 price1 = IUniswapV2Router02(router1).getAmountsOut(
            amount,
            path
        )[1];
        uint256 price2 = IUniswapV2Router02(router2).getAmountsOut(
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
        address pairaddress = IUniswapV2Factory(factoryy).getPair(
            first,
            second
        );

        address token0 = IUniswapV2Pair(pairaddress).token0();
        address token1 = IUniswapV2Pair(pairaddress).token1();
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        uint256 price = IUniswapV2Router02(router).getAmountsOut(amount, path)[
            1
        ];
        return price;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "ITransferHelper.sol";

interface IUniswapV2Router02 {
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

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
pragma solidity ^0.8.6;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "IUniswapV2Pair.sol";

import "SafeMath.sol";

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

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            pairFor(factory, tokenA, tokenB)
        ).getReserves();
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
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IWETH {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 value)
        external
        returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    function deposit() external;

    function withdraw(uint256 wad) external;
}