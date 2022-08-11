/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract RewardDistribute {
    address owner;
    
    constructor() {
        owner = msg.sender;
    }

    fallback() payable external {
    }

    receive() payable external {
    }

    function withdraw() public {
        require(msg.sender == owner, "not owner");
        payable(msg.sender).transfer(address(this).balance);
    }
}