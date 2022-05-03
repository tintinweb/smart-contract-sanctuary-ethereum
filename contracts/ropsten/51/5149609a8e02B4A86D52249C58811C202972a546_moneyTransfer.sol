/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract moneyTransfer {
    address public owner;

    struct recordStruct {
        address addr;
        uint256 amount;
        uint256 time;
        bool isReceived;
    }

    mapping(address => recordStruct[]) records;
    event moneySended(address from, address to, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function sendMoney(address payable to)
        public
        payable
        returns (string memory)
    {
        uint256 amount = msg.value;
        bool isDone = to.send(amount);
        if (isDone == true) {
            emit moneySended(msg.sender, to, amount);
            recordStruct memory tempObjForSender = recordStruct(
                to,
                amount,
                block.timestamp,
                false
            );
            recordStruct memory tempObjReceiver = recordStruct(
                msg.sender,
                amount,
                block.timestamp,
                true
            );
            records[msg.sender].push(tempObjForSender);
            records[to].push(tempObjReceiver);
            return ("Your Money Is Transfered");
        } else {
            return ("Transaction Failed");
        }
    }

    function showBalance() public view returns (uint256) {
        return msg.sender.balance;
    }

    function myRecords() public view returns (recordStruct[] memory) {
        return (records[msg.sender]);
    }

    function myAddress() public view returns (address) {
        return (msg.sender);
    }
}