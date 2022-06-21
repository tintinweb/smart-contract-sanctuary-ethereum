// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./VotingPoll.sol";

contract VotingFactory {

    address private admin;
    event CreatedVotingPoll(string title, address indexed owner);
    address[] private s_votingPolls;
    string[] private s_votingTitles;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "Not Admin");
        _;
    }

    function createVotingPoll(string memory title, string[] memory options)
        external
        onlyAdmin
        returns (address votingPollAddress)
    {
        VotingPoll votingPoll = new VotingPoll(title, options, msg.sender);
        votingPollAddress = address(votingPoll);
        s_votingPolls.push(votingPollAddress);
        s_votingTitles.push(title);
        emit CreatedVotingPoll(title, msg.sender);
    }

    function getVotingPollTitles() external view returns(string[] memory) {
        return (s_votingTitles);
    }

    function getVotingPollById(uint256 id) external view returns(address) {
        return s_votingPolls[id];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract VotingPoll {
    string public s_title;
    string[] public s_options;
    address public s_owner;
    uint256[] public s_votes;
    mapping(address => bool) s_voted;

    event Vote(string option, uint256 value, address indexed voter);

    constructor(
        string memory title,
        string[] memory options,
        address owner
    ) {
        s_title = title;
        s_options = options;
        s_owner = owner;
        uint256[] memory votes = new uint256[](options.length);
        for (uint256 i = 0; i < options.length; i++) {
            votes[i] = 0;
        }
        s_votes = votes;
    }

    function vote(uint256 optionId) external {
        require(!s_voted[msg.sender], "already voted");
        s_voted[msg.sender] = true;
        s_votes[optionId] = s_votes[optionId] + 1;
        emit Vote(s_options[optionId], s_votes[optionId], msg.sender);
    }

    function getState()
        external
        view
        returns (
            string memory,
            string[] memory,
            address,
            uint256[] memory
        )
    {
        return (s_title, s_options, s_owner, s_votes);
    }

    function alreadyVoted(address user) external view returns (bool) {
        return s_voted[user];
    }

}