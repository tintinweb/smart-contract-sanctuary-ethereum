/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract KingOfTheHill {
    uint256 public dateOfGameStart;
    address[] public dynasty;
    uint32 public kingIndex;

    constructor() {
        dynasty.push(msg.sender);
        dateOfGameStart = block.timestamp;
    }

    function setKing(address _king) public {
        dynasty.push(_king);
        kingIndex=uint32(dynasty.length-1);
    }

    function makeMeTheKing() public {
        dynasty.push(msg.sender);
        kingIndex=uint32(dynasty.length-1);
    }
}