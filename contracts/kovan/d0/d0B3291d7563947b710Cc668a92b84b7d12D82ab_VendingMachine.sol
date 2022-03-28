//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VendingMachine{
    address owner; 

    event Deposit(address payee, uint256 value, uint256 time, uint256 currentContractBalance);
    event Withdraw(uint256 time, uint256 amount);

    constructor () payable{
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "function is only for owner");
        _;
    }

    function getBalance() public view onlyOwner returns (uint256 balance){
        balance = address(this).balance;
    }

    function ownerWithdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        (bool sent,) = owner.call{value:address(this).balance}("");
        require(sent,"Failed to Send Ether");
        emit Withdraw(block.timestamp, contractBalance);

    }
    
    receive() external payable{
        emit Deposit(msg.sender, msg.value,block.timestamp, address(this).balance);
    }
}