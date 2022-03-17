/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Voting {

    // votes[สีแดง] = 4
    // votes[สีม่วง] = 0
    mapping (string => uint256) public votes;

    // title[0] = สีแดง
    // title[1] = สีม่วง
    string [] public title;

    address public owner;
    constructor() {
        owner = msg.sender;
    }

    // _title = สีแดง
    function createTitle(string memory _title) public {
        require(owner == msg.sender, "Only owner can create title.");
        title.push(_title);
        votes[_title] = 0;
    }

    function vote(string memory _title) public {
        votes[_title] += 1;
    }

    function checkLength() public view returns(uint) {
        return title.length;
    }
}