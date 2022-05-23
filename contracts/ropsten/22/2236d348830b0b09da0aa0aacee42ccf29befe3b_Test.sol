/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

contract Test {

    string public greeting = "HelloWorld!";

    function withdraw(uint256 amount) public {
        require(amount <= address(this).balance);
        msg.sender.transfer(amount);
    }

    receive() external payable {}

}