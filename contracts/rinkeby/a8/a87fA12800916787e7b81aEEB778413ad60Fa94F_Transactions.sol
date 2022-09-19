//SPDX-License-Identifier: Unlicensed 
pragma solidity ^0.8.0;

contract Transactions {
    uint256 public transactionCount; 

    TransferStruct[] public transactions;

    event Transfer(address _from, address _receiver, uint amount, string _message, uint256 _timestamp, string _keyword);

    struct TransferStruct {
        address sender; 
        address receiver; 
        uint amount; 
        string message; 
        uint256 timestamp; 
        string keyword;
    }


    function addToBlockchain(address _payableReceiver, uint _amount, string memory _message, string memory _keyword) public {
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


}