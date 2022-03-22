/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiTransfer {
    
    address owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function charge() payable public {
        
    }

    constructor() payable{
        owner = msg.sender; 
    }

    function withdrawls(address payable[] memory addresses, uint256 amount) public onlyOwner {        
        for (uint i=0; i < addresses.length; i++) {   
            addresses[i].transfer(amount);
        }
    }
    
}