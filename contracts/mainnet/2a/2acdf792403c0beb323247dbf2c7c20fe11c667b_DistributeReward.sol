/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract DistributeReward {
    address owner;
    
    constructor() {
        owner = msg.sender;
    }

    fallback() payable external {
    }

    receive() payable external {
    }

    function withdraw() public {
        payable(owner).transfer(address(this).balance);
    }
}