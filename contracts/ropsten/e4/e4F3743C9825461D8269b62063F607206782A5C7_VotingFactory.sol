// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./VotingPoll.sol";

contract VotingFactory {
    address[] public allPolls;
    
    event PollCreated(address deployer, address addr);

    constructor () {
    }

    function getAllPolls() external view returns(address[] memory){
        return allPolls;
    }

    function newVotingPoll(string memory _title, string[] memory _options) external returns(address votingPoll) {
        votingPoll = address(new VotingPoll(msg.sender, _title, _options));
        allPolls.push(votingPoll);
        emit PollCreated(msg.sender, votingPoll);
        return votingPoll;
    }

    function getPollsCount () external view returns(uint256 cnt) {
        return allPolls.length;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "./VotingFactory.sol";

contract VotingPoll {

    struct vote {
        address joiner;
        uint result;
    }
    uint256 joiners;
    mapping(address => uint) multipleCheck;
    address private owner;
    vote[] voteResult;
    string public votingTitle;
    string[] public options;
    bool public votingStatus;

    constructor (address _creater, string memory _title, string[] memory _options) {
        joiners = 0;
        owner = _creater;
        votingTitle = _title;
        options = _options;
        votingStatus = true;
    }

    function getOwner() external view returns(address) {
        return owner;
    }

    function getTitle() external view returns(string memory) {
        return votingTitle;
    }

    function getOptions() external view returns(string[] memory) {
        return options;
    }
    
    function getStatus() external view returns(bool) {
        return votingStatus;
    }

    function getOptionCounts() external view returns(uint) {
        return options.length;
    }

    function getResult() external view returns(vote[] memory) {
        return voteResult;
    }

    function pauseVoting () external {
        require(msg.sender == owner, "You're not owner!");
        require(votingStatus == true, "This voting was finished before.");
        votingStatus = false;
    }

    function voting(uint _value) external {
        require(multipleCheck[msg.sender] == 0 , "Can't join twice in one poll");
        require(votingStatus == true, "This vote is already finished.");
        multipleCheck[msg.sender] = _value;
        vote storage temp = voteResult[joiners];
        temp.joiner = msg.sender;
        temp.result = _value;
        joiners++;
    }
}