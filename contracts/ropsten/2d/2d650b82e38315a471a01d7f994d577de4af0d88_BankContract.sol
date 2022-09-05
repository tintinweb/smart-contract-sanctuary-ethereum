/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract BankContract
{ 
    struct Account {
        address owner;
        uint256 balance;
        uint256 accountCreatedTime;
    }

    mapping(address => Account) public TestBank;

    event balanceAdded(address owner , uint256 balance , uint256 timestamp);
    event withdrawalDone(address owner , uint256 balance , uint256 timestamp);

    modifier minimum(){
        require(msg.value >= 1 ether, "Doesn't follow minmum criteria");
        _;
    } 

    function accountCreated() public payable minimum{
        TestBank[msg.sender].owner = msg.sender;
        TestBank[msg.sender].balance = msg.value;
        TestBank[msg.sender].accountCreatedTime = block.timestamp;
        emit balanceAdded(msg.sender,msg.value,block.timestamp);
    }

    function deposit() public payable minimum{
        TestBank[msg.sender].balance = msg.value;
        emit balanceAdded(msg.sender,msg.value,block.timestamp);
    }

    function withdrawal() public payable {
        payable(msg.sender).transfer(TestBank[msg.sender].balance);
        emit withdrawalDone(msg.sender,TestBank[msg.sender].balance,block.timestamp);
    }
}