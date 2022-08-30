/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

contract PoolMatrixGame {

    address public owner;
    uint256 balance;
    uint8 level;
    address referrer;

    event ContractCreated(string msg, address indexed owner);
    event TestEvent(string msg);
    event PaymentReceived(string msg, address indexed owner, address indexed sender, uint value);
    event Widthdrawn(string msg, uint amount, address indexed destAddr);
    event PrintBalanceEvent(string msg, uint256 balance, address indexed owner);
    event Fireslot(address indexed account, uint8 indexed level, uint256 amount);

    struct User {
        address referrer;
    }

    mapping (address => User) internal users;

    constructor() public {
        owner = msg.sender;
        emit ContractCreated("Contract has been created", owner);
    }

    receive() payable external {
        emit PaymentReceived("Payment received!", users[msg.sender].referrer, msg.sender, msg.value);
        balance += msg.value;
    }

    fallback() external payable {
        emit PaymentReceived("Fallback function executed", users[msg.sender].referrer, msg.sender, msg.value);
    }

    function test() public {
        emit TestEvent("Hello world!");
    }

    function withdraw(uint amount, address payable destAddr) public {
        destAddr.transfer(amount);
        balance -= amount;
        emit Widthdrawn("Cost has been widhdrawn", amount, destAddr);
    }

    function printBalance() public {
        emit PrintBalanceEvent("Balance is:", balance, owner);
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    function getBalance() public view returns(uint256) {
        return balance;
    }

    function buyFireslot(uint8 newLevel, address newReferrer) public {
        //User storage user = users[msg.sender];

        //user.referrer = newReferrer;

        /*payable(msg.sender).transfer(msg.value / 4);*/
        referrer = newReferrer;
        level = newLevel;
    }

    function getReferrer() public view returns(address) {
        return referrer;
    }

    function getUserReferrer(address userAddr) public view returns(address) {
        return users[userAddr].referrer;
    }

    function setUserRefferer(address userAddr, address referrerAddr) public {
        referrer = referrerAddr;
        users[userAddr].referrer = referrerAddr;
    }

    function setUserRefferer2(address userAddr, address referrerAddr) public {
        users[userAddr].referrer = referrerAddr;
    }

    function setUserRefferer3(address referrerAddr) public {
        referrer = referrerAddr;
    }

    function setRefferer(address referrerAddr) public {
        referrer = referrerAddr;
    }

    function testData() public payable {
        referrer = abi.decode(msg.data, (address));
        emit TestEvent("test data executed!");
    }
}