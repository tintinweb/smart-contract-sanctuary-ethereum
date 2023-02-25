// SPDX-License-Identifier: UNLICENSED
pragma solidity = 0.8.17;

contract Crowdfunding {
    address payable public owner;
    uint public goal;
    uint public raised;
    mapping(address => uint) public contributions;

    constructor(uint _goal) {
        owner = payable(msg.sender);
        goal = _goal;
    }

    function contribute() public payable {
        require(raised < goal, "Goal already reached");
        contributions[msg.sender] += msg.value;
        raised += msg.value;
    }

    function withdraw() public {
        require(msg.sender == owner, "Only owner can withdraw");
        require(raised >= goal, "Goal not reached yet");
        owner.transfer(address(this).balance);
    }
}