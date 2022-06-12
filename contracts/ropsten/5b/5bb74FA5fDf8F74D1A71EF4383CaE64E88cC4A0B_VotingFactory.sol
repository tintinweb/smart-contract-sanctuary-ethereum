// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./VotingPoll.sol";

contract VotingFactory {
    address[] public allPolls;
    string[] public titles;
    uint pollCounts;
    
    event PollCreated(address deployer, address addr);

    constructor () {
        pollCounts = 0;
    }

    function getAllPolls() external view returns(address[] memory) {
        return allPolls;
    }

    function getTitles() external view returns(string[] memory) {
        return titles;
    }

    function newVotingPoll(string memory _title, string[] memory _options) external returns(address votingPoll) {
        votingPoll = address(new VotingPoll(msg.sender, _title, _options));
        allPolls.push(votingPoll);
        titles.push(_title);
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

    address private owner;
    string public votingTitle;
    string[] public options;
    bool public votingStatus;
    mapping(address => uint) multipleCheck;
    mapping(uint => uint) votingResult;

    constructor (address _creater, string memory _title, string[] memory _options) {
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

    function getResult(uint _id) external view returns(uint) {
        return votingResult[_id];
    }

    function getMultiCheck(address _user) external view returns(uint) {
        return multipleCheck[_user];
    }

    function pauseVoting () external {
        require(msg.sender == owner, "You're not owner!");
        require(votingStatus == true, "This voting was finished before.");
        votingStatus = false;
    }

    function voting(uint _value) external {
        require(multipleCheck[msg.sender] == 0 , "Can't join twice in one poll");
        require(votingStatus == true, "This vote is already finished.");
        multipleCheck[msg.sender] ++;
        votingResult[_value]++;
    }
}