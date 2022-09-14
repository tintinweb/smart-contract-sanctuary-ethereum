/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Counter{
    uint private count;
    uint private totalTransactions;

    event TransactionEvent(address wallet, uint256 date, uint count);

    struct Transaction {
        address walletAddress;
        uint count;
        uint256 date;
    }

    mapping(uint => Transaction) public history;

    modifier storeTransaction() {
        _;
        history[totalTransactions] = Transaction(msg.sender, count, block.timestamp);
        totalTransactions++;
        emit TransactionEvent(msg.sender, block.timestamp, count);
    }

    function getCount() public view returns(uint) {
        return count;
    }
    
    function getHistory() public view returns(Transaction[] memory){
        Transaction[] memory pastHistory = new Transaction[](totalTransactions);
        for(uint i=0;i<totalTransactions;i++){
            pastHistory[i] = history[i];
        }
        return pastHistory;
    }

    function increase() public storeTransaction{
        count++;
    }

    function decrease() public storeTransaction{
        count--;
    }

    function setCount(uint _newCount) public storeTransaction{
        count = _newCount;
    }
}