/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Simple {
    address public owner;
    string public telegram;

    constructor(string memory _telegram) {
        owner = msg.sender;
        telegram = _telegram;
    }

    modifier onlyOwner(){
        require(owner == msg.sender, "You are not an OWNER!");
        _;
    }

    function setTelegram(string memory _telegram) public onlyOwner {
        telegram = _telegram;
    }
}