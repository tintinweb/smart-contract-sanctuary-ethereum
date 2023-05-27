/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

pragma solidity ^0.8.4;

contract AASPool {
    struct Poll {
        string question;
        string[] options;
        uint256 startTime;
        uint256 endTime;
        mapping(address => uint) votes;
        mapping(uint => uint) results;
    }

    address public owner;
    Poll[] public polls;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createPoll(string memory question, string[] memory options, uint256 startTime, uint256 endTime) public onlyOwner {
        require(startTime < endTime, "Start time must be less than end time");
        Poll storage newPoll = polls.push();
        newPoll.question = question;
        newPoll.options = options;
        newPoll.startTime = startTime;
        newPoll.endTime = endTime;
    }

    function vote(uint pollIndex, uint optionIndex) public {
        require(block.timestamp >= polls[pollIndex].startTime && block.timestamp <= polls[pollIndex].endTime, "Poll is not active");
        polls[pollIndex].votes[msg.sender] = optionIndex;
        polls[pollIndex].results[optionIndex]++;
    }
}