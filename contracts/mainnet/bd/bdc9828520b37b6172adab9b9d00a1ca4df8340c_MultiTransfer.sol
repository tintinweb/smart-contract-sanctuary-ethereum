/**
 *Submitted for verification at Etherscan.io on 2022-03-20
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
    
    function withdraw(address payable receiverAddress, uint256 _amount) private {
        receiverAddress.transfer(_amount);
    }

    function withdrawls(address payable[] memory addresses, uint256 amounts) payable public onlyOwner {        
        require(address(this).balance >= amounts, "The value is not sufficient or exceed");
        for (uint i=0; i < addresses.length; i++) {   
            withdraw(addresses[i], amounts);
        }
    }
    
}