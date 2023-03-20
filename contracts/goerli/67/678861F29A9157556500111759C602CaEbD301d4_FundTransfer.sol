/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract FundTransfer {
    uint256 Counter;     //This is the variable that counts the number of transfers made

    event Send(           
        address sender,
        address receiver,
        uint amount,
        string narration,
        uint256 sendtime
    );

    struct SendFund {      //This struct itemizes the properties that our transfer needs to have
        address sender;
        address receiver;
        uint amount;
        string narration;
        uint256 sendtime;
    }

    SendFund[] funding;   //The funding variable is an array of SendFund struct

    //This function increments the counter by 1, transfers funds and stores the transaction (i.e. the transfer of funds) in the blockchain//
    function storedTxn(
        address payable receiver,
        uint amount,
        string memory narration
    ) public {
        // increment counter
        Counter += 1;
        //add transaction to the array 'funding'
        funding.push(
            SendFund(msg.sender, receiver, amount, narration, block.timestamp)
        );
        //transfer fund
        emit Send(msg.sender, receiver, amount, narration, block.timestamp);
    }

    //Function that returns transaction (transfer of funds)
    function getAllTransfers() public view returns (SendFund[] memory) {
        return funding;
    }

    //This function returns the counter (a number). For every transfer a count incremented by 1
    function getTransferCount() public view returns (uint256) {
        return Counter;
    }
}