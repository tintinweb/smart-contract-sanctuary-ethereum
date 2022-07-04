/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


contract SendFunds {

    event NewTxn(address indexed to, uint256 amount, uint256 timestamp);

    struct SentTransaction {
        address reciever;
        uint256 amount;
        uint256 timestamp;
    }

    SentTransaction[] allTxn;

    function sendFunds(address payable _to, uint256 amount) public payable {
        require(amount <= address(this).balance, "not enough funds");
        (bool success, ) = _to.call{value: amount}("");
        require(success, "Unable to send Ether");
        allTxn.push(SentTransaction(_to, amount, block.timestamp));
        emit NewTxn(_to, amount, block.timestamp);
    }

    function getAllTxn() public view returns (SentTransaction[] memory) {
        return allTxn;
    }
}