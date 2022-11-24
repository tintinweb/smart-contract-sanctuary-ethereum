/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

contract Owned {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(
            msg.sender == owner,
            "Only the owner of the smart contract can call this function"
        );
        _;
    }
}

contract Mortal is Owned {
    function kill() public onlyOwner{
        selfdestruct(payable(owner));
    }
}

contract Faucet is Mortal {

    event Deposit(address indexed from, uint amount);
    event Withdrawal(address indexed to, uint amount);

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
    
    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
    
    function withdraw(uint amount) public {
        require(amount <= 0.1 ether);
        require(
            address(this).balance >= amount,
            "Insufficient funds"
        );

        payable(msg.sender).transfer(amount);

        emit Withdrawal(msg.sender, amount);
    }
    
}