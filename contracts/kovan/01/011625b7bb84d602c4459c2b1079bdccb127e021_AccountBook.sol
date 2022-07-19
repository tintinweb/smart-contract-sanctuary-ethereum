/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

pragma solidity ^0.8.15;
// SPDX-License-Identifier: MIT

contract AccountBook{

    mapping(address => uint) public Balance;
    mapping(address => uint) public LastCheckTime;
    mapping(address => uint) public BlockNumber;
    mapping(address => bytes32) public TransactionHash;

    // address[] MyArray;
    
    event Deposit(address Depositor, uint Amount, uint TimeStamp);
    event Withdraw(address Receiver, uint Amount, uint TimeStamp);

    function depositEther() public payable returns(bytes32){

        require(msg.value > 0, "You need to deposit more amount");
        Balance[msg.sender] += msg.value;
        LastCheckTime[msg.sender] = block.timestamp;

        BlockNumber[msg.sender] = block.number;
        TransactionHash[msg.sender]= blockhash(block.number);
        emit Deposit(msg.sender, msg.value, block.timestamp);
        // MyArray.push(payable(msg.sender));
        return TransactionHash[msg.sender];
    }

    function withdrawEther(uint amount) public returns(bytes32) {
        if((block.timestamp - LastCheckTime[msg.sender]) < 60){
            return 0;
        }
        else {
        require(amount > 0, "Enter More Amount");
        require(Balance[msg.sender] - amount >= 0, "Cannot Withdraw Amount. Amount is greater then account balance.");
        Balance[msg.sender] -= amount;              //This will deduct the amount from the balance
        payable(msg.sender).transfer(amount);       //This will transfer the amount back to the user
        emit Withdraw(msg.sender, amount, block.timestamp);
        BlockNumber[msg.sender] = block.number;
        TransactionHash[msg.sender]= blockhash(block.number);
      

        return TransactionHash[msg.sender];
        }
    }

    function getBalance() public view returns(uint){
        return Balance[msg.sender];                //Returns the balance of the user
    }

    function viewTransaction() public view returns(bytes32){
        // block.Log();
        // address.call(bytes) returns(bool, bytes memory);
    //    return BlockNumber[msg.sender];
            // return MyArray.push(msg.sender)    ;
            return  TransactionHash[msg.sender];
    }
}