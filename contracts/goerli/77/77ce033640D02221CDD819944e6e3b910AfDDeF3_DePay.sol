/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
contract DePay{
    
    
    mapping(address => uint) public balance;
    mapping(address=> mapping(address => uint)) public paidTo;
    mapping(address=> mapping(address => uint)) public ReceivedFrom;
    mapping(address=> address[]) public paidArr;
    mapping(address=> address[]) public receivedArr;
 event transactionData(address indexed _from,uint amount, address indexed _to,uint date,uint time,string purpose);


     function addFund() public payable {
        require(msg.value>0,"transaction with 0 eth is not allowed");
        balance[msg.sender]+=msg.value;
    }



     function pay(address payable _to,uint amount,uint date,uint time,string memory purpose) public payable {
        require(amount<balance[msg.sender],"Insufficient funds");
        require(amount>0,"transaction with 0 eth is not allowed");
        require(_to!=msg.sender,"You cannot pay money to yourself");
        _to.transfer(amount);
        balance[msg.sender]-=amount;
        if(paidTo[msg.sender][_to]==0)
        {
            paidArr[msg.sender].push(_to);
            receivedArr[_to].push(msg.sender);
        }
        paidTo[msg.sender][_to]+=amount;
        ReceivedFrom[_to][msg.sender]+=amount;
        emit transactionData(msg.sender,amount,_to,date,time,purpose);
    }



     function withdraw(uint amount) public payable {
       require(amount<balance[msg.sender],"Insufficient funds");
       require(amount>0,"transaction with 0 eth is not allowed");
      (payable (msg.sender)).transfer(amount);
        balance[msg.sender]-=amount;
    }








     function numberOfPeopleIPaid()public view returns(uint){
       return(paidArr[msg.sender].length);
   }



     function numberOfPeopleWhoPaidMe()public view returns(uint){
       return(receivedArr[msg.sender].length);
   }
}