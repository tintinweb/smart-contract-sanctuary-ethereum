//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

contract Transactions {
    uint256 transactionCount;

    event Transfer(address from, address receiver, uint256 amount, uint256 timestamp);

    struct TransferStruct {
        address sender;
        address receiver;
        uint256 amount;
        uint256 timestamp;
    } 

    TransferStruct[] transactions;

    function addToBlockchain(address payable _receiver, uint256 _amount) public {
        transactionCount += 1;
        transactions.push(TransferStruct(msg.sender, _receiver, _amount, block.timestamp));
        emit Transfer(msg.sender, _receiver, _amount, block.timestamp);
    }

     function getAllTransactions() public view returns (TransferStruct[] memory) {
         return transactions;
    }

     function getTransactionCount() public view returns(uint256){
         return transactionCount;
    }
}