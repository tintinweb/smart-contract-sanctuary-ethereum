/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract PiggyBank {
    address public owner;
    bool public isOver;
    string public desc;
    uint64 public endTime;

    constructor(
        address _owner,
        string memory _desc,
        uint64 _endTime
    ) {
        owner = _owner;
        desc = _desc;
        endTime = _endTime;
    }

    function deposit() public payable {
        require(!isOver, "This piggy bank in over!");
    }

    function withdraw() internal {
        require(msg.sender == owner, "You are not an owner!");
        require(endTime < block.timestamp, "Now is to early!");
        payable(owner).transfer(address(this).balance);
        isOver = true;
    }
}