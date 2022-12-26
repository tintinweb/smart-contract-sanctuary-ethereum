/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract RewardVault {
    address owner;
    address to;
    
    constructor() {
        owner = msg.sender;
        setTo(owner);
    }

    fallback() payable external {
    }

    receive() payable external {
    }

    function withdraw() public {
        payable(to).transfer(address(this).balance);
    }

    function setTo(address to_) public {
        require(owner == msg.sender, "not owner");
        to = to_;
    }
}