/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.11;

contract faucet{
    function withdraw(uint amount) public {
        require(amount <= 100000000000000000);
        payable(msg.sender).transfer(amount);
    }
    receive() external payable {}
}