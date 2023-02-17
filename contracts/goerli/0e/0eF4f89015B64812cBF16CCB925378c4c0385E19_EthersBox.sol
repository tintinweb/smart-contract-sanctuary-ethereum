/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract EthersBox {
    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
    }

    function claim() public {
        require(address(this).balance >= 1 gwei, "Fund too little");
        payable(owner).transfer(address(this).balance);
    }
}