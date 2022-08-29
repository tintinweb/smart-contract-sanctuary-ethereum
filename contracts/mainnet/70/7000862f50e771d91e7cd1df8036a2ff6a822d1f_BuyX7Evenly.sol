/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*

 buyx7evenly.sol

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

        swapEthForTokens(address(0x7001629B8BF9A5D5F204B6d464a06f506fBFA105), perToken, minTokens, msg.sender, deadline);
        swapEthForTokens(address(0x70021e5edA64e68F035356Ea3DCe14ef87B6F105), perToken, minTokens, msg.sender, deadline);
        swapEthForTokens(address(0x70036Ddf2F2850f6d1B9D78D652776A0d1caB105), perToken, minTokens, msg.sender, deadline);
        swapEthForTokens(address(0x70041dB5aCDf2F8aa648A000FA4A87067AbAE105), perToken, minTokens, msg.sender, deadline);
        swapEthForTokens(address(0x7005D9011F4275747D5cb38bC3deB0C46EdbD105), ethAmount - perToken * 4, minTokens, msg.sender, deadline);
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