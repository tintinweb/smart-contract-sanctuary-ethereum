/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract PiggyBank {
    address public owner;
    bool public isOver;
    string public desc;

    constructor(address _owner, string memory _desc) {
        owner = _owner;
        desc = _desc;
    }

    function deposit() public payable {
        require(!isOver, "This piggy bank in over!");
    }

    function withdraw() public {
        require(msg.sender == owner, "You are not an owner!");
        require(isWithdrawAvailable(), "You can't do withdraw yet");
        payable(owner).transfer(address(this).balance);
        isOver = true;
    }

    function isWithdrawAvailable() public view virtual returns (bool) {}
}

contract TimePiggyBank is PiggyBank {
    uint64 public endTime;

    constructor(
        address _owner,
        string memory _desc,
        uint64 _endTime
    ) PiggyBank(_owner, _desc) {
        endTime = _endTime;
    }

    function isWithdrawAvailable() public view override returns (bool) {
        return endTime < block.timestamp;
    }
}