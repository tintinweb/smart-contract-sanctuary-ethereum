/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Recorder {
	struct transaction{
        string date;
        address key;
        uint id;
        string hash;
    }
	transaction[] private transactions;

	function RecordTransaction(string memory date, string memory hash, uint id, address key) public {
        transactions.push(transaction(date,key,id,hash));
	}

    function TransactionsByUser(address add) public view returns(uint) {
        uint count=0;
        for(uint i=0; i<transactions.length;i++){
            if (keccak256(abi.encode(transactions[i].key))==keccak256(abi.encode(add))) {
                count++;
            }
        }
        return count;
    }

    function TransactionsByDate(string memory date) public view returns(uint) {
        uint count=0;
        for(uint i=0; i<transactions.length;i++){
            if (keccak256(abi.encode(transactions[i].date))==keccak256(abi.encode(date))) {
                count++;
            }
        }
        return count;
    }

    function GetTransaction(string memory add, string memory date, uint id) public view returns(string memory) {
        for(uint i=0; i<transactions.length;i++){
            if (keccak256(abi.encode(transactions[i].date))==keccak256(abi.encode(date))&&keccak256(abi.encode(transactions[i].key))==keccak256(abi.encode(add))&&transactions[i].id==id) {
                return transactions[i].hash;
            }
        }
        return "no transaction found!";
    }
}