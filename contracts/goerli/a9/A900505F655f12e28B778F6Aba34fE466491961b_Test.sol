/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract Test {
    address public yourToken;
    uint256 public tokensPerEth = 100;

    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);

    function buyTokens() public payable {
        uint256 amount = msg.value * tokensPerEth;

        emit BuyTokens(msg.sender, msg.value, amount);
    }

    receive() external payable {}
}