/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

pragma solidity ^0.8.15;
// SPDX-License-Identifier: MIT

contract AccountBook{

    mapping(address => uint) public Balance;
    mapping(address => uint) public LastCheckTime;

    event Deposit(address Depositor, uint Amount, uint TimeStamp);
    event Withdraw(address Receiver, uint Amount, uint TimeStamp);

    function depositEther() public payable {

        require(msg.value > 0, "You need to deposit more amount");
        Balance[msg.sender] += msg.value;
        LastCheckTime[msg.sender] = block.timestamp;
        
        emit Deposit(msg.sender, msg.value, block.timestamp);

    }

    function withdrawEther(uint amount) public returns(uint) {
        if((block.timestamp - LastCheckTime[msg.sender]) < 60){
            return 0;
        }
        else {
        require(amount > 0, "Enter More Amount");
        require(Balance[msg.sender] - amount >= 0, "Cannot Withdraw Amount. Amount is greater then account balance.");
        Balance[msg.sender] -= amount;              //This will deduct the amount from the balance
        payable(msg.sender).transfer(amount);       //This will transfer the amount back to the user
        emit Withdraw(msg.sender, amount, block.timestamp);
        return block.timestamp;
        }
    }

    function getBalance() public view returns(uint){
        return Balance[msg.sender];                //Returns the balance of the user
    }

    // function getEvent() public view{

    // }
}