/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IERC20 {
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint amount) external returns (bool);
}

interface IWETH {
    function withdraw(uint) external;
}

contract OGzRouterV2 {
    address private constant OGz = 0xB7BDa6a89e724f63572Ce68FdDc1a6d1d5D24BCf;
    address private constant PAIR = 0x173a958B4381F72381C3A1099bF715D0AcD82309;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private immutable FEE;

    uint256 public constant feePercent = 2;

    constructor() { FEE = msg.sender; }

    receive() external payable {
        require(msg.sender == WETH);
    }

    function swapExactOGzForETH(uint amountToken, uint ethOutMin)
        external
        returns (uint ethOut)
    {
        ethOut = getAmountOut(amountToken);
        require(ethOut >= ethOutMin);

        IERC20(OGz).transferFrom(msg.sender, address(this), amountToken);
        IERC20(OGz).transfer(PAIR, amountToken);

        IUniswapV2Pair(PAIR).swap(0, ethOut, address(this), new bytes(0));
        IWETH(WETH).withdraw(ethOut);

        uint256 fee = ethOut * feePercent / 100;
        safeTransferETH(msg.sender, ethOut - fee);
    }

    function getAmountOut(uint amountIn) public view returns (uint amountOut) {
        (uint reserveIn, uint reserveOut,) = IUniswapV2Pair(PAIR).getReserves();
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success);
    }

    function withdraw() external {
        require(msg.sender == FEE);
        safeTransferETH(msg.sender, address(this).balance);
    }
}