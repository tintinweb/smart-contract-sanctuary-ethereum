/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Faucet {
    function withdraw(uint withdrawAmount) public {
        require(withdrawAmount < 100000000000000000);
        payable(msg.sender).transfer(withdrawAmount);
    }

    receive () external payable {}
}