/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Buy{
    uint256 public balance;

    event ListenSellOrBuy(uint256 buyOrSell, uint256 amount, address trader);

    function buy() public {
        balance += 1;
        emit ListenSellOrBuy(0, 1, msg.sender);
    }
}