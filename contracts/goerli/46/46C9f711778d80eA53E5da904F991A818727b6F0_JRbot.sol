/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}

contract JRbot {
    address payable public owner;
    uint public commissionDivisor;

    constructor() {
        owner = payable(msg.sender);
        commissionDivisor = 100;
    }

    function makeSwap(address token, uint amountOutMin, address _uniswapRouterAddress) public payable {
        // Compute the commission.
        uint commission = 0;
        if (commissionDivisor > 0) {
            commission = msg.value / commissionDivisor;
        }

        // Perform the swap.
        address[] memory path = new address[](2);
        path[0] = IUniswapV2Router02(_uniswapRouterAddress).WETH();
        path[1] = token;
        IUniswapV2Router02(_uniswapRouterAddress).swapExactETHForTokens{value: msg.value - commission}(amountOutMin, path, msg.sender, block.timestamp);
    }

    function withdraw() public {
        require(msg.sender == owner, "Only the contract owner can withdraw ETH.");
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Withdrawal failed.");
    }
}