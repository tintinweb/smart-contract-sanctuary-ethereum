/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Waste {

    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    address private owner;
        
    address payable[] accounts;
    
    modifier isOwner() {        
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {        
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
    }

    function addAccount(address payable account) public isOwner {
        accounts.push(account);
    }

    function payAddressesEvenly(uint numberOfPaymentsPerAddress) public payable {  
        require(accounts.length > 0, "No accounts to pay");
        uint256 amountPerAddress = msg.value/accounts.length;        
        uint256 amountPerIteration = amountPerAddress/numberOfPaymentsPerAddress;
        uint256 iterations = numberOfPaymentsPerAddress * accounts.length;
        for (uint i = 0; i < iterations; i++){      
            uint currentIndex = i % accounts.length;
            accounts[currentIndex].transfer(amountPerIteration);
        }
    }       

    function payAddressesEvenly(address payable address1, address payable address2, address payable address3) public payable {
        address1.transfer(msg.value/3);
        address2.transfer(msg.value/3);
        address3.transfer(msg.value/3);
    }
}