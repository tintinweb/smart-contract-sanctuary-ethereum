/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

contract Wallet {
    // Let one person able to send and withdraw from wallet
    // Single person eth wallet
    // Implement "deposit" and "withdraw" functions
    // Implement "balanceOf" to retrieve the current balance in the wallet

    address payable public owner;

    constructor(address payable _owner) {
        owner = _owner;
    }

    function deposit() payable public {

    }

    function withdraw(address payable receiver, uint amount) public {
        require(msg.sender == owner, "You are not the owner of this wallet");
        
        receiver.transfer(amount);
    }

    function balanceOf() public view returns(uint) {
        return address(this).balance;
    }

}