/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract GetTheEth{

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function transfer(address to, uint256 amount) public {
        require(msg.sender==owner);
        payable(to).transfer(amount);
    }

    receive() external payable {
       
    }
}