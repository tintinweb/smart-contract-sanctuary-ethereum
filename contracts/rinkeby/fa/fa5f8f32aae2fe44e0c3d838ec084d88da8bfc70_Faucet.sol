/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Faucet {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }
    function send () external payable {
        require(msg.sender == owner, "Only the owner can to this call");
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
       require(msg.sender == owner, "Only the owner can to this call");
       
       address payable to = payable(msg.sender);
       uint balance = address(this).balance;

       to.transfer(balance);
    
        }
}