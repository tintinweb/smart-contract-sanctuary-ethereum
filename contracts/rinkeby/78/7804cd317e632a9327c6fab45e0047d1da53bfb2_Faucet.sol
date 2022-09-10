/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Faucet {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }
    function send () external payable {
        require(msg.sender == owner, "Only the owner can send it :)");
    }

    function request ()external {
        address payable to = payable(msg.sender);

        if (address(this).balance >= 0.01 ether) {
            to.transfer (0.01 ether);
        }
    }
    function getBalance() external view returns (uint256) {
        return address(this).balance;

        }

    function whitdraw() external {
       require(msg.sender == owner, "Sorry you are not the owner :( ");
       
       address payable to = payable(msg.sender);
       uint balance = address(this).balance;

       to.transfer(balance);
    
        }
    
    function transferOwnership(address newOwner) public {
            require(msg.sender == owner);
            owner = newOwner;
       }
    
    
 
    


    }