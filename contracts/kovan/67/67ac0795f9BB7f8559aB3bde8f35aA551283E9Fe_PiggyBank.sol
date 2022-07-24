// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract PiggyBank {
    address public owner;
    event Deposit(uint amount);
    event Withdraw(uint amount);

    constructor(){
        owner == payable(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner ,"you are not owner");
        _;
    }

    receive()external payable{
        emit Deposit(msg.value);
    }

    fallback() external payable{}

    function withdraw(uint amount) external onlyOwner{
        payable(msg.sender).transfer(amount);
        emit Withdraw(address(this).balance);
        selfdestruct(payable(owner));
    }
}