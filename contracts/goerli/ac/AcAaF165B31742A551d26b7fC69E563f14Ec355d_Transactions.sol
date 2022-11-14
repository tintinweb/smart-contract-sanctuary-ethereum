/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Transactions {
    uint256 transactionCount;

    event Transfer(address from, address receiver, uint amount, string message, uint256 timestamp);
    event MultiTransfer(address[] _receivers, uint256[] _sentAmounts);
    
  
    struct TransferStruct {
        address sender;
        address receiver;
        uint amount;
        string message;
        uint256 timestamp;
    }

    struct MultiTransferStruct {
        address sender;
        address[] receiverArray;
        uint256[] sentAmountArray;
        uint256 timestamp;
    }
    
    MultiTransferStruct[] multiCallTransactions;
    TransferStruct[] transactions;

    function singleTransactionCall(address payable receiver, uint amount, string memory message) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, ) = receiver.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        transactionCount += 1;
        transactions.push(TransferStruct(msg.sender, receiver, amount, message, block.timestamp));

        emit Transfer(msg.sender, receiver, amount, message, block.timestamp);
    }

    function getAllTransactions() public view returns (TransferStruct[] memory) {
        return transactions;
    }

    function getMultiCallTransactions() public view returns (MultiTransferStruct[] memory) {
        return multiCallTransactions;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactionCount;
    }

    function multiTransactionCall(address[] memory _receivers, uint256[] memory _sentAmounts) external payable {
    uint256 total = msg.value;
    uint256 i = 0;
    for (i; i < _receivers.length; i++) {
        require(total >= _sentAmounts[i]);
        assert(total - _sentAmounts[i] > 0);
        total = total - _sentAmounts[i];
        (bool success, ) = _receivers[i].call{value:_sentAmounts[i]}("");
        require(success, "Transfer failed.");
    }
    multiCallTransactions.push(MultiTransferStruct(msg.sender, _receivers,_sentAmounts, block.timestamp));
     emit MultiTransfer(_receivers,_sentAmounts);
    }



}