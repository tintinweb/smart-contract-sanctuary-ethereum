/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error NotEnoughMoney();

contract Donation {
    struct Memo {
        string name;
        string message;
        uint256 timestamp;
        address from;
    }

    Memo[] memos;

    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    function Pey(string memory _name, string memory _message) public payable {
        if (msg.value > 0) {
            memos.push(Memo(_name, _message, block.timestamp, msg.sender));
            owner.transfer(msg.value);
        } else {
            revert NotEnoughMoney();
        }
    }

    function getMemo() public view returns (Memo[] memory) {
        return memos;
    }
}