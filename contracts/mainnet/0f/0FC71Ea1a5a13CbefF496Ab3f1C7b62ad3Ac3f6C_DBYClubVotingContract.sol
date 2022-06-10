//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/* DBYClub DAO LLC. Initial voting contract 06/2022. 
      Any updates to our contracts are reflected in our Articles of Operation within 30 days. */

contract Ownable {
    address public owner;

    // Sets the deployer address as the `owner`.
    constructor(){
        owner = msg.sender;
    }

    // Throws an exception if called by any account other than the `owner`.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract DBYClubVotingContract is Ownable{
    struct Poll {
        uint256 pollId;
        string pollTitle;
        string pollDesc;
        address whoProposed;
        bool openForPolling;
        uint256 numberOfVotes;
    }
    struct votesForPoll {
        address[] voters;
        uint256 polledId;
    }
    
    mapping(uint=>votesForPoll) private votersVoted;
    mapping (uint => Poll) public polls;
    uint public pollCount;
    address[] public votersAndProposers;

    //storing Poll details
    function proposePoll(string memory _pollTitle, string memory _pollDesc) public{
        require(checkIsValid(msg.sender), "Not a valid Poposer");
        pollCount++;
        polls[pollCount] = Poll(pollCount, _pollTitle, _pollDesc, msg.sender, true, 0);
    }

    //set addresses who can vote
    function setVotersAndProposers(address _voterAddr) external onlyOwner{
        require(!checkIsValid(_voterAddr), "Already added to Voter List");
        votersAndProposers.push(_voterAddr);
    }

    //Checking if address is Valid
    function checkIsValid(address _addrGiven) public view returns(bool){
        for(uint i= 0; i< votersAndProposers.length; i++){
            if(votersAndProposers[i]==_addrGiven){
                return true;
            }
        }
        return false;
    }

    //allow Voters to vote
    function voteForPoll(uint256 _pollId) public{
        require(checkIsValid(msg.sender), "Not a valid voter");
        require(polls[_pollId].openForPolling, "Polling Closed");
        polls[_pollId].numberOfVotes++;
        votersVoted[_pollId].voters.push(msg.sender);
    }

}