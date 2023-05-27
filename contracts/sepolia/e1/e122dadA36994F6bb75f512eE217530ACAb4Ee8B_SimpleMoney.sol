//SPDX-License-Identifier: MIT
pragma solidity  ^0.8.4;     // tells the version of solidity you are using

contract SimpleMoney{
    mapping(address => uint) public ledger;

    function deposit() external payable{
        ledger[msg.sender] += msg.value;
    }

    function withdraw(uint amt) external {
        require(amt != 0, "amount can't be 0");  //error or throw an exception
        require(amt <= ledger[msg.sender], "INSUFFICIENT BALANCE");
        //uint sendable = amt > ledger[msg.sender] ? ledger[msg.sender] : amt;
        ledger[msg.sender] -= amt;
        payable(msg.sender).transfer(amt);


    }


}