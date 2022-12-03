// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Polling {
    /* TYPE DECLARATIONS */
    struct Poll {
        address pollOwner;
        string question;
        PollState pollState;
        uint256 id;
        uint256[] votes;
        string[] options;
    }

    enum PollState {
        OPEN,
        CLOSED
    }

    /* STATE VARIABLES */
    address public owner;
    uint256[] public ids;
    mapping(uint256 => Poll) idToPoll;
    mapping(address => uint256[]) addressToIds;
    mapping(address => mapping(uint256 => bool)) addressToVoted;
    uint256 currentId = 0;

    modifier onlyPollOwner(uint256 _pollId) {
        require(
            idToPoll[_pollId].pollOwner == msg.sender,
            "Function caller is not poll owner"
        );
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function createPoll(
        string memory _question,
        string[] memory _options
    ) external {
        require(_options.length > 1 && _options.length <= 4);
        Poll memory poll;
        poll.pollOwner = msg.sender;
        poll.id = currentId;
        poll.question = _question;
        poll.options = _options;
        idToPoll[currentId] = poll;
        addressToIds[msg.sender].push(currentId);
        currentId++;
    }

    function vote(uint8 _voteIndex, uint256 _pollId) external {
        require(
            _voteIndex >= 0 &&
                _voteIndex <= idToPoll[_pollId].options.length - 1,
            "Selected index is out of range"
        );
        require(
            addressToVoted[msg.sender][_pollId] == false,
            "Function caller has already voted on the poll"
        );
        require(
            idToPoll[_pollId].pollState == PollState.OPEN,
            "Poll has closed"
        );
        require(
            idToPoll[_voteIndex].pollOwner != address(0),
            "Poll doesn't exist"
        );
        idToPoll[_pollId].votes[_voteIndex] += 1;
        addressToVoted[msg.sender][_pollId] = true;
    }

    function closePoll(uint256 _pollId) external onlyPollOwner(_pollId) {
        require(
            idToPoll[_pollId].pollOwner != address(0),
            "Poll doesn't exist"
        );
        idToPoll[_pollId].pollState = PollState.CLOSED;
    }

    function getPoll(uint256 _pollId) public view returns (Poll memory) {
        return idToPoll[_pollId];
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getIds() public view returns (uint256[] memory) {
        return ids;
    }

    function getAddressPollIds() public view returns (uint256[] memory) {
        return addressToIds[msg.sender];
    }

    function getAddressVoted(uint256 _pollId) public view returns (bool) {
        return addressToVoted[msg.sender][_pollId];
    }

    function getCurrentId() public view returns (uint256) {
        return currentId;
    }
}