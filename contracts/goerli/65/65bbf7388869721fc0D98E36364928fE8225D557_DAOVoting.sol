//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./SafeERC20.sol";

contract DAOVoting {
    using Counters for Counters.Counter;
    Counters.Counter private votingID;
    address private owner;
    IERC20 public token;
    uint256 public minimumQuorum;
    uint256 public debatingPeriodDuration;
    mapping(address => bool) public isChairMan;
    mapping(address => bool) public isDAO;

    mapping(address => uint256) private balanceTotal;
    mapping(address => uint256) private lastVoting;
    
    struct Voting {
        string description;

        mapping(address => uint256) participants;
        uint256 totalVotes;
        uint256 positiveVotes;
        uint256 courseVote;

        address recipient;
        bytes callData;

        uint256 startAt;
        uint256 endAt;
        bool ended;
    }

    mapping(uint256 => Voting) public votings;

    event VotingCreated(uint256 id, string description);
    event VotingEnded(uint256 id, bool result);

    modifier OnlyOwner() {
        require(msg.sender == owner, "not an owner");
        _;
    }

    modifier OnlyChairMan() {
        require(isChairMan[msg.sender], "not a chairman");
        _;
    }

    modifier OnlyDAO() {
        require(isDAO[msg.sender], "not a DAO");
        _;
    }

    constructor(address chairMan, IERC20 _token, uint256 _minimumQuorum, uint256 _debatingPeriodDuration) {
        owner = msg.sender;
        addChairMan(chairMan);
        addChairMan(owner);
        addDAO(address(this));
        token = _token;
        minimumQuorum = _minimumQuorum;
        debatingPeriodDuration = _debatingPeriodDuration;
    }

    function getBalance() external view returns(uint256) {
        return balanceTotal[msg.sender];
    }

    function getFrozenBalance() external view returns(uint256) {
        if (votings[lastVoting[msg.sender]].ended) {
            return 0;
        }
        return votings[lastVoting[msg.sender]].participants[msg.sender];
    }

    function addChairMan(address account) public OnlyOwner {
        isChairMan[account] = true;
    }

    function addDAO(address account) public OnlyOwner {
        isDAO[account] = true;
    }

    function setMinimumQuorum(uint256 newMinimumQuorum) external OnlyDAO {
        minimumQuorum = newMinimumQuorum;
    }

    function setDebatingPeriodDuration(uint256 newDebatingPeriodDuration) external OnlyDAO {
        debatingPeriodDuration = newDebatingPeriodDuration;
    }

    function deposit(uint256 funds) external {
        require(token.balanceOf(msg.sender) >= funds, "not enough funds");
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), funds);
        balanceTotal[msg.sender] += funds;
    }

    function addProposal(bytes memory callData, address recipient, string memory description) external OnlyChairMan {
        Voting storage newVoting = votings[votingID.current()];
        newVoting.callData = callData;
        newVoting.recipient = recipient;
        newVoting.description = description;
        newVoting.courseVote = 1;
        newVoting.startAt = block.timestamp;
        newVoting.endAt = block.timestamp + debatingPeriodDuration;
        emit VotingCreated(votingID.current(), description);
        votingID.increment();
    }

    function vote(uint256 votingId, bool voteValue) external {
        require(votingID.current() >= votingId, "such voting does not exist");
        require(votings[votingId].courseVote != 0, "course vote equal to 0");
        require((balanceTotal[msg.sender] / votings[votingId].courseVote) != 0, "you don't froze enough tokens");
        require(block.timestamp < votings[votingId].endAt, "already ended");
        require(votings[votingId].participants[msg.sender] == 0, "you already voted");

        lastVoting[msg.sender] = votingId;
        votings[votingId].participants[msg.sender] = balanceTotal[msg.sender] / votings[votingId].courseVote;
        votings[votingId].totalVotes += balanceTotal[msg.sender] / votings[votingId].courseVote;
        if (voteValue) {
            votings[votingId].positiveVotes += balanceTotal[msg.sender] / votings[votingId].courseVote;
        }
    }

    function finishProposal(uint256 votingId) external {
        require(votingID.current() >= votingId, "such voting does not exist");
        require(block.timestamp >= votings[votingId].endAt, "proposal is runnning right now");
        require(!votings[votingId].ended, "already ended");
        bool called = false;
        if (votings[votingId].totalVotes >= minimumQuorum && votings[votingId].positiveVotes > votings[votingId].totalVotes - votings[votingId].positiveVotes) {
            callFunction(votings[votingId].recipient, votings[votingId].callData);
            called = true;
        }

        votings[votingId].ended = true;
        emit VotingEnded(votingId, votings[votingId].ended);
    }

    function callFunction(address recipient, bytes memory signature) internal {
        (bool success, ) = recipient.call(signature);
        require(success, "ERROR call function");
    }

    function withdraw() external {
        if (votings[lastVoting[msg.sender]].ended) {
            lastVoting[msg.sender] = votingID.current() + 5;
        }
        token.transfer(msg.sender, balanceTotal[msg.sender] - votings[lastVoting[msg.sender]].participants[msg.sender] * votings[lastVoting[msg.sender]].courseVote);
    }
}