// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./VotingPoll.sol";

contract VotingFactory {
    struct PollInfo {
        string title;
        address votingPoll;        
    }
    
    PollInfo[] public votingPollsList;
    
    event PollCreated(address deployer, string title, address addr);

    constructor () {
        
    }

    function newVotingPoll(string memory _title, string[] memory _options) external {        
        address pollAddress = address(new VotingPoll(msg.sender, _title, _options, votingPollsList.length));
        votingPollsList.push(
            PollInfo({
                title: _title,
                votingPoll: pollAddress                
            })
        );
        emit PollCreated(msg.sender, _title, pollAddress);        
    }

    function getPollsCount () external view returns(uint256) {
        return votingPollsList.length;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract VotingPoll {

    address private owner;
    string public votingTitle;
    string[] public options;
    uint256 public pollId;
    bool public votingStatus;
    mapping(address => bool) userVoted;
    mapping(uint256 => uint256) votingResult;

    constructor (address _creater, string memory _title, string[] memory _options, uint256 _id) {
        owner = _creater;
        votingTitle = _title;
        options = _options;        
        pollId = _id;
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

    function getOptionCounts() external view returns(uint256) {
        return options.length;
    }

    function getResult(uint256 _optionId) external view returns(uint256) {
        return votingResult[_optionId];
    }

    function getMultiCheck(address _from) external view returns(bool) {
        return userVoted[_from];
    }

    function pauseVoting () external {
        require(msg.sender == owner, "You're not owner!");
        require(votingStatus == true, "This voting was finished before.");
        votingStatus = false;
    }

    function voting(uint _optionId) external {
        require(!userVoted[msg.sender], "Can't join twice in one poll");
        require(votingStatus == true, "This vote is already finished.");
        userVoted[msg.sender] = true;
        votingResult[_optionId]++;
    }
}