/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

//SPDX-License-Identifier: MIT

pragma abicoder v2;
pragma solidity ^0.8.7;

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
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
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

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

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

// File: contracts\interfaces\IPancakeRouter02.sol

pragma solidity >=0.6.2;

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
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
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: contracts\interfaces\IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

pragma solidity ^0.8.7;

contract honeyCheckerV5 {
    IPancakeRouter02 public router;
    uint256 approveInfinity =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    struct HoneyResponse {
        uint256 buyResult;
        uint256 tokenBalance2;
        uint256 sellResult;
        uint256 buyCost;
        uint256 sellCost;
        uint256 expectedAmount;
    }

    constructor() {}

    function honeyCheck00(
        address targetTokenAddress,
        address idexRouterAddres
    ) external payable returns (HoneyResponse memory response) {
        router = IPancakeRouter02(idexRouterAddres);

        IERC20 wCoin = IERC20(router.WETH()); // wETH
        IERC20 targetToken = IERC20(targetTokenAddress); //Test Token

        address[] memory buyPath = new address[](2);
        buyPath[0] = router.WETH();
        buyPath[1] = targetTokenAddress;

        address[] memory sellPath = new address[](2);
        sellPath[0] = targetTokenAddress;
        sellPath[1] = router.WETH();

        uint256[] memory amounts = router.getAmountsOut(msg.value, buyPath);

        uint256 expectedAmount = amounts[1];

        IWETH(router.WETH()).deposit{value: msg.value}();

        wCoin.approve(idexRouterAddres, approveInfinity);

        uint256 wCoinBalance = wCoin.balanceOf(address(this));

        uint256 startBuyGas = gasleft();

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            wCoinBalance,
            1,
            buyPath,
            address(this),
            block.timestamp + 10
        );

        uint256 buyResult = targetToken.balanceOf(address(this));

        uint256 finishBuyGas = gasleft();

        targetToken.approve(idexRouterAddres, approveInfinity);

        uint256 startSellGas = gasleft();

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            buyResult,
            1,
            sellPath,
            address(this),
            block.timestamp + 10
        );

        uint256 finishSellGas = gasleft();

        uint256 tokenBalance2 = targetToken.balanceOf(address(this));

        uint256 sellResult = wCoin.balanceOf(address(this));

        // uint256 buyCost = startBuyGas - finishBuyGas;
        // uint256 sellCost = startSellGas - finishSellGas;

        response = HoneyResponse(
            buyResult,
            tokenBalance2,
            sellResult,
            startBuyGas - finishBuyGas,
            startSellGas - finishSellGas,
            expectedAmount
        );

        return (response);
    }

    function honeyCheck11(
        address targetTokenAddress,
        address idexRouterAddres
    ) external payable returns (HoneyResponse memory response, uint256) {
        router = IPancakeRouter02(idexRouterAddres);

        IERC20 wCoin = IERC20(router.WETH()); // wETH
        IERC20 targetToken = IERC20(targetTokenAddress); //Test Token

        address[] memory buyPath = new address[](2);
        buyPath[0] = router.WETH();
        buyPath[1] = targetTokenAddress;

        address[] memory sellPath = new address[](2);
        sellPath[0] = targetTokenAddress;
        sellPath[1] = router.WETH();

        uint256[] memory amounts = router.getAmountsOut(msg.value, buyPath);

        uint256 expectedAmount = amounts[1];

        IWETH(router.WETH()).deposit{value: msg.value}();

        wCoin.approve(idexRouterAddres, approveInfinity);

        uint256 wCoinBalance = wCoin.balanceOf(address(this));

        uint256 startBuyGas = gasleft();

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            wCoinBalance,
            1,
            buyPath,
            address(this),
            block.timestamp + 10
        );

        uint256 buyResult = targetToken.balanceOf(address(this));

        uint256 finishBuyGas = gasleft();

        targetToken.approve(idexRouterAddres, approveInfinity);

        uint256 startSellGas = gasleft();

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            buyResult,
            1,
            sellPath,
            address(this),
            block.timestamp + 10
        );

        uint256 finishSellGas = gasleft();

        uint256 tokenBalance2 = targetToken.balanceOf(address(this));

        uint256 sellResult = wCoin.balanceOf(address(this));

        // uint256 buyCost = startBuyGas - finishBuyGas;
        // uint256 sellCost = startSellGas - finishSellGas;

        response = HoneyResponse(
            buyResult,
            tokenBalance2,
            sellResult,
            startBuyGas - finishBuyGas,
            startSellGas - finishSellGas,
            expectedAmount
        );

        return (response, sellResult);
    }

    function honeyCheck33(
        address targetTokenAddress,
        address idexRouterAddres
    ) external payable returns (uint256[6] memory) {
        router = IPancakeRouter02(idexRouterAddres);

        IERC20 wCoin = IERC20(router.WETH()); // wETH
        IERC20 targetToken = IERC20(targetTokenAddress); //Test Token

        address[] memory buyPath = new address[](2);
        buyPath[0] = router.WETH();
        buyPath[1] = targetTokenAddress;

        address[] memory sellPath = new address[](2);
        sellPath[0] = targetTokenAddress;
        sellPath[1] = router.WETH();

        uint256[] memory amounts = router.getAmountsOut(msg.value, buyPath);

        uint256 expectedAmount = amounts[1];

        IWETH(router.WETH()).deposit{value: msg.value}();

        wCoin.approve(idexRouterAddres, approveInfinity);

        uint256 wCoinBalance = wCoin.balanceOf(address(this));

        uint256 startBuyGas = gasleft();

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            wCoinBalance,
            1,
            buyPath,
            address(this),
            block.timestamp + 10
        );

        uint256 buyResult = targetToken.balanceOf(address(this));

        uint256 finishBuyGas = gasleft();

        targetToken.approve(idexRouterAddres, approveInfinity);

        uint256 startSellGas = gasleft();

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            buyResult,
            1,
            sellPath,
            address(this),
            block.timestamp + 10
        );

        uint256 finishSellGas = gasleft();

        uint256 tokenBalance2 = targetToken.balanceOf(address(this));

        uint256 sellResult = wCoin.balanceOf(address(this));

        // uint256 buyCost = startBuyGas - finishBuyGas;
        // uint256 sellCost = startSellGas - finishSellGas;
uint256[6] memory result=[  buyResult,
            tokenBalance2,
            sellResult,
            startBuyGas - finishBuyGas,
            startSellGas - finishSellGas,
            expectedAmount];
        return (result);
    }
}