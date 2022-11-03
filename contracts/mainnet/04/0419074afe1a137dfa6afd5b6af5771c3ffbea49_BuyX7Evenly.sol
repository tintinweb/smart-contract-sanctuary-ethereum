/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*

    Smart contract to buy all constallation tokens (X7101, X7102, X7103, X7104, X7105) equally at once.

*/

interface IUniswapV2Router {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256, address[] calldata, address, uint256) external payable;
    function WETH() external pure returns (address);
}

contract BuyX7Evenly {

    IUniswapV2Router public router;

    constructor(address router_) {
        router = IUniswapV2Router(router_);
    }

    /*
        slippagePercent: 1-100 to account for fee + price slippage
        deadline: the unix timestamp seconds before which the trades must complete. Try a number >= 30 seconds in the future.
    */
    function depositIntoX7SeriesTokens(uint256 slippagePercent, uint256 deadline) external payable {
        uint256 ethAmount = msg.value;
        uint256 perToken = ethAmount / 5;
        uint256 minTokens = perToken - (perToken * slippagePercent / 100);

        swapEthForTokens(address(0x7101a9392EAc53B01e7c07ca3baCa945A56EE105), perToken, minTokens, msg.sender, deadline); // X7101
        swapEthForTokens(address(0x7102DC82EF61bfB0410B1b1bF8EA74575bf0A105), perToken, minTokens, msg.sender, deadline); // X7102
        swapEthForTokens(address(0x7103eBdbF1f89be2d53EFF9B3CF996C9E775c105), perToken, minTokens, msg.sender, deadline); // X7103
        swapEthForTokens(address(0x7104D1f179Cc9cc7fb5c79Be6Da846E3FBC4C105), perToken, minTokens, msg.sender, deadline); // X7104
        swapEthForTokens(address(0x7105FAA4a26eD1c67B8B2b41BEc98F06Ee21D105), ethAmount - perToken * 4, minTokens, msg.sender, deadline); // X7105
    }

    function swapEthForTokens(address tokenAddress, uint256 ethAmount, uint256 minReceived, address recipient, uint256 deadline) internal {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = tokenAddress;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            minReceived,
            path,
            recipient,
            deadline
        );
    }
}