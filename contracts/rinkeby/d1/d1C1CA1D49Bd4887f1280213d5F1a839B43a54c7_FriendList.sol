/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract FriendList {

    event Transfer(address from, address receiver, uint amount, uint256 timestamp);

    //Friends
    struct Friend {
        address walletAddress;
        string name;
    }

    Friend[] friends;

    //transactions
    struct TransferStruct {
        address sender;
        address receiver;
        uint amount;
        uint256 timestamp;
    }

    TransferStruct[] transactions;

    //Get All Transactions
    function getAllTransaction() public view returns (TransferStruct[] memory) {
        return transactions;
    }

    //Send Funds
    function addToBlockChain(address payable receiver, uint amount) public {
        transactions.push(TransferStruct(msg.sender, receiver, amount, block.timestamp));
        emit Transfer(msg.sender, receiver, amount, block.timestamp);
    }

}