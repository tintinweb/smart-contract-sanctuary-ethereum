// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./DexRouter.sol";

contract BridgeETH {
    uint256 brigdeFee = 10;
    address TREASURY = 0xfC1cCf00fefF175E819DE4592e3286751a6b7f7c;
    address TROGE = 0x2462C9B00dA3bfb7832d7A9Dd867a51631d4e790;
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IDEXRouter public router;
    address pair;

    constructor() {
        // router = IPancakeSwapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); // bsc mainnet
        router = IDEXRouter(ROUTER);
        pair = IDEXFactory(router.factory()).getPair(TROGE, WBNB);
        if (pair == address(0)) {
            pair = IDEXFactory(router.factory()).createPair(TROGE, WBNB);
        }
    }

    function sendToBridge(uint256 amount) public returns (uint256 result) {
        result = amount - (amount * (brigdeFee)) / 100;
        IERC20(TROGE).transferFrom(msg.sender, TREASURY, result);
        buyBack((amount * (brigdeFee)) / 100);

        return result;
    }

    function buyBack(uint256 amount) public {
        IERC20(TROGE).approve(ROUTER, amount);
        address[] memory path = new address[](2);
        path[0] = TROGE;
        path[1] = WBNB;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IDEXRouter {
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