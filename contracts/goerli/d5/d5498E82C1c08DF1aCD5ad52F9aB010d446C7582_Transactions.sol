/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract Transactions{
    uint counter;

    event transfer(address from, address receiver, uint amount, string message, uint timestamp, string keyword);

    struct TransferStruct{
        address sender;
        address receiver;
        uint amount;
        uint timestamp;
        string message;
        string keyword;
    }

    TransferStruct[] transactions;

    function addtochain(address payable receiver, uint amount, string memory message, string memory keyword) public {
        counter += 1;
        transactions.push(TransferStruct(msg.sender, receiver, amount, block.timestamp, message, keyword));

        emit transfer(msg.sender, receiver, amount, message, block.timestamp, keyword);
    }

    function getalltran() public view returns (TransferStruct[] memory){
        return transactions;
    }

    function getcounter() public view returns (uint){
        return counter;
    }
}