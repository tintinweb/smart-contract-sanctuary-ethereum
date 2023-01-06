/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
 

contract EtherStore {
    mapping(address => uint) public balances;
    mapping(address => uint) public totalBalances;
    mapping(address => bool) public accExists;
    address payable owner;
    uint256 depositAmount = 1000000000000000; // 0.001 eth

    constructor() {
        owner = payable(msg.sender);
    }
    modifier onlyowner() {
    require(msg.sender == owner, "Only the owner can execute this function");
    _;
  }
    function createAccount() public {
        accExists[msg.sender] = true;
        totalBalances[msg.sender] = address(msg.sender).balance;
    }


    function deposit() public payable {
        require(accExists[msg.sender] || (msg.sender == owner), "Cant deposit, Account doesnt exist");
        require ((msg.value == depositAmount) || (msg.sender == owner), "Greater than the deposit limit");
        require (balances[msg.sender] == 0 || (msg.sender == owner) , "More than one deposit");
        totalBalances[msg.sender] = address(msg.sender).balance;
        balances[msg.sender] += msg.value;

    }

    function withdraw() public {
        require(accExists[msg.sender] || (msg.sender == owner), "Cant Withdraw, Account doesnt exist");
        uint bal = balances[msg.sender];
        require(bal > 0, "No Balance in This Smart contract");
        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send Ether to the withdrawer");

        balances[msg.sender] = 0;
    }
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }



    function checkForSuccess (address _user) public view returns(bool){
        return ((accExists[_user]) && (address(this).balance == 0) && (address(_user).balance > totalBalances[_user]));
    }

    function withdrawToOwner() public onlyowner{
        uint balance = address(this).balance;
        require(owner.send(balance), "Failed to send Ether");
}

}