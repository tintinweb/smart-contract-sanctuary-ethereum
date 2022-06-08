/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Transactions {
    uint256 transactionCount;

    event Transfer(address from, address receiver,uint amount , string name,string surname, uint256 timestamp, string idnumber);

    struct TransferStruct {
        address sender;
        address receiver;
        uint amount;
        string name;
        string surname;
        uint256 timestamp;
        string idnumber;
    }

//array of transaction
  TransferStruct[] transaction;

  function addToBlockchain(address payable receiver, uint amount, string memory name,string memory surname, string memory idnumber) public{
    transactionCount +=1;
    transaction.push(TransferStruct(msg.sender,receiver,amount,name,surname,block.timestamp,idnumber ));
    
    emit Transfer(msg.sender,receiver,amount,name,surname,block.timestamp,idnumber );
  
  }

    function getAllTransactgion() public view returns(TransferStruct[] memory){
      return transaction;

  }

    function getTransactionCount() public view returns(uint256){
      return transactionCount;

  }


}