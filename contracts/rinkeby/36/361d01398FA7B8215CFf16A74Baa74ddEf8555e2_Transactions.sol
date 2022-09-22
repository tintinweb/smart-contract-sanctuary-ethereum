//SPDX-License-Identifier: Unlicensed 
pragma solidity ^0.8.0;

contract Transactions {
    uint256 public transactionCount; 

    TransferStruct[] public transactions;
    uint256 public peopleSubs = 0;
    mapping(address => bool) public addressPaid; 


    event Transfer(address _from, address _receiver, uint amount, string _message, uint256 _timestamp, string _keyword);

    struct Paid {
        address sender; 
        uint amount; 
        uint256 timestamp;
    }

    struct TransferStruct {
        address sender; 
        address receiver; 
        uint amount; 
        string message; 
        uint256 timestamp; 
        string keyword;
    }


    function addToBlockchain(address _payableReceiver, uint _amount, string memory _message, string memory _keyword) public payable  {
        transactionCount++;
        transactions.push(TransferStruct(msg.sender, _payableReceiver, _amount, _message, block.timestamp, _keyword));
        emit Transfer(msg.sender, _payableReceiver, _amount, _message, block.timestamp, _keyword);
    }
    
    function getAllTransactions() public view returns(TransferStruct[] memory) {
        return transactions;
    }
    
    function getTransactionCount() public view returns (uint256) {
        return transactionCount;
    }

    function hasPaid(address _from) public payable returns (bool) {
        addressPaid[_from] = true;
        peopleSubs ++;
        return true;
    }

    function getPaidList() public returns (string[] memory paidList) {
        // have to get the id's from mapping, then 
        // then return that list to the user, from there the user will search
        // if they are eligible for the information that is later shown. 
        
        // return  ;
    }

}