//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";

contract Voting is Ownable {
    struct Candidate {
        address payable account;
        uint256 votes;
    }

    enum VotingStatus { NotStarted, Started, Finished }

    event CandidateAdded(uint256 indexed id, address indexed account);
    event Vote(uint256 indexed id, address indexed voter);
    event VotingStarted(uint256 indexed endTime);
    event VotingEnded(uint256 indexed id, address account, uint256 indexed votes);
    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => bool) internal _voters;
    /**
     * We do not provide an option to remove a candidate, so we can use array
     * and an array index as a candidate id
     * instead of mapping(uint => Candidate), where uint is an id.
     */
    Candidate[] public candidates;
    VotingStatus public status;
    uint256 public endTime;
    uint256 public constant votingRate = 0.01 ether;
    uint256 public constant ownerPercent = 10;

    constructor() Ownable() {
        status = VotingStatus.NotStarted;
    }

    function addCandidates(address payable[] memory accounts) external onlyOwner {
        require(accounts.length > 0, "No candidates provided");
        uint256 startIndex =  candidates.length;
        for (uint i=0; i < accounts.length; i++) {
            candidates.push(Candidate(accounts[i], 0));
            emit CandidateAdded(i + startIndex, accounts[i]);
        }
    }

    function vote(uint256 candidateId) external payable{
        require(candidateId < candidates.length, "Invalid candidate id");
        require(status == VotingStatus.Started, "Voting is not running");
        require(block.timestamp < endTime, "Voting is over");
        require(!_voters[msg.sender], "You have voted already");
        require(msg.value == votingRate, "You should send voting rate to vote");
        candidates[candidateId].votes++;
        _voters[msg.sender] = true;
        emit Vote(candidateId, msg.sender);
    }

    function startVoting(uint256 votingTime) external onlyOwner {
        require(status == VotingStatus.NotStarted, "Voting can't be started");
        require(votingTime > 0 , "Invalid voting time");
        status = VotingStatus.Started;
        endTime = block.timestamp + votingTime;
        emit VotingStarted(endTime);
    }

    function finishVoting() external {
        require(status == VotingStatus.Started, "Voting is not running to be finished");
        require(block.timestamp > endTime, "Time is not finished yet");
        status = VotingStatus.Finished;
        delete endTime;

        (uint256 id, address payable account, uint256 votes) = _chooseWinner();
        emit VotingEnded(id, account, votes);

        // Transfer all tokens from the balance minus 10% to the winner
        uint256 amount = address(this).balance - (address(this).balance * ownerPercent / 100);
        (bool sent, ) = account.call{value: amount, gas: 700}("");
        require(sent, "Failed to send Ether");
        emit Transfer(address(this), account, amount);
    }

    function withdraw() external onlyOwner {
        // Possibility for owner to withdraw 10% after voting is finished
        require(status == VotingStatus.Finished, "You can't make withdrawal until voting is finished");
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing to withdraw");
        (bool sent, ) = _owner.call{value: amount, gas: 700}("");
        require(sent, "Failed to withdraw Ether");
        emit Transfer(address(this), _owner, amount);
    }
    function getCandidates() public view returns (Candidate[] memory){
        return candidates;
    }

    function _chooseWinner() internal view returns(uint256 id, address payable winner, uint256 winningVotes) {
        winningVotes = 0;
        // For simplicity, if several candidates have the same amount of votes, the winner will be the first candidate.
        for (uint256 i=0; i<candidates.length; i++) {
            if (candidates[i].votes > winningVotes) {
                winningVotes = candidates[i].votes;
                winner = candidates[i].account;
                id = i;
            }
        }
    }
}