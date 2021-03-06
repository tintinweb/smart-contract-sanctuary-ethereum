pragma solidity ^0.4.17;

/**
    This contract represents a sort of time-limited challenge,
    where users can vote for some candidates.
    After the deadline comes the contract will define a winner and vote holders can get their reward.
**/
contract VotingChallenge {
    uint public challengeDuration;
    uint public challengePrize;
    uint public creatorPrize;
    uint public challengeStarted;
    uint public candidatesNumber;
    address public creator;
    uint8 public creatorFee;    // measured in percent
    uint public winner;
    bool public isVotingPeriod;
    bool public beforeVoting;
    uint[] public votes;
    mapping( address => mapping (uint => uint)) public userVotesDistribution;

    // Modifiers
    modifier inVotingPeriod() {
        require(isVotingPeriod);
        _;
    }

    modifier afterVotingPeriod() {
        require(!isVotingPeriod);
        _;
    }
    
    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }

    // Events
    event ChallengeBegan(address _creator, uint8 _creatorFee, uint _candidatesNumber, uint _challengeDuration);
    event NewVotesFor(uint _candidate, uint _votes);
    event TransferVotes(address _from, address _to, uint _candidateIndex, uint _votes);
    event EndOfChallenge(uint _winner, uint _winnerVotes, uint _challengePrize);
    event RewardWasPaid(address _participant, uint _amount);
    event CreatorRewardWasPaid(address _creator, uint _amount);

    // Constructor
    function VotingChallenge() public {
        challengeDuration = 100;
        candidatesNumber = 3;
        votes.length = candidatesNumber + 1; // we will never use the first elements of array (with zero index)
        creator = msg.sender;
        creatorFee = 10;
        if(creatorFee > 100) creatorFee = 100;
        beforeVoting = true;
        ChallengeBegan(creator, creatorFee, candidatesNumber, challengeDuration);
    }
    
    // Last block timestamp getter
    function getTime() public view returns (uint) {
        return now;
    }

    function getAllVotes() public view returns (uint[]) {
        return votes;
    }

    // Return a winner ID
    function getWinner() public view afterVotingPeriod returns (uint) {
        return winner;
    }
    
    // Start challenge
    function startChallenge() public onlyCreator {
        require(beforeVoting);
        isVotingPeriod = true;
        beforeVoting = false;
        challengeStarted = now;
    }
    
    // Change creator adress
    function changeCreator(address newCreator) public onlyCreator {
        require(msg.sender == creator);
        creator = newCreator;
    }

    // Vote for candidate
    function voteForCandidate(uint candidate) public payable inVotingPeriod {
        require(candidate <= candidatesNumber);
        require(candidate > 0);
        require(msg.value > 0);
        // if(checkEndOfChallenge()) {
        //     msg.sender.transfer(msg.value);
        //     return;
        // }
        
        // Add new votes for community
        votes[candidate] += msg.value;

        // Change the votes distribution
        userVotesDistribution[msg.sender][candidate] += msg.value;

        // Fire the event
        NewVotesFor(candidate, msg.value);
    }

    // Transfer votes to anybody
    function transferVotes (address to, uint candidate) public inVotingPeriod {
        require(userVotesDistribution[msg.sender][candidate] > 0);
        uint votesToTransfer = userVotesDistribution[msg.sender][candidate];
        userVotesDistribution[msg.sender][candidate] = 0;
        userVotesDistribution[to][candidate] += votesToTransfer;
        
        // Fire the event
        TransferVotes(msg.sender, to, candidate, votesToTransfer);
    }

    // Check the deadline
    // If success then define a winner and close the challenge
    function checkEndOfChallenge() public inVotingPeriod returns (bool) {
        if (challengeStarted + challengeDuration > now)
            return false;
        uint theWinner;
        uint winnerVotes;
        for (uint i = 1; i <= candidatesNumber; i++) {
            if (votes[i] > winnerVotes) {
                winnerVotes = votes[i];
                theWinner = i;
            }
        }
        winner = theWinner;
        creatorPrize = address(this).balance * creatorFee / 100;
        challengePrize = address(this).balance - creatorPrize;
        isVotingPeriod = false;

        // Fire the event
        EndOfChallenge(winner, winnerVotes, challengePrize);
        return true;
    }

    // Send a reward if user voted for a winner
    function getReward() public afterVotingPeriod {
        require(userVotesDistribution[msg.sender][winner] > 0);
        
        // Compute a vote ratio and send the reward
        uint userVotesForWinner = userVotesDistribution[msg.sender][winner];
        userVotesDistribution[msg.sender][winner] = 0;
        uint reward = (challengePrize * userVotesForWinner) / votes[winner];
        msg.sender.transfer(reward);

        // Fire the event
        RewardWasPaid(msg.sender, reward);
    }

    // Send a reward to challenge creator
    function getCreatorReward() public afterVotingPeriod onlyCreator {
        require(creatorPrize > 0);
        uint creatorReward = creatorPrize;
        creatorPrize = 0;
        msg.sender.transfer(creatorReward);

        // Fire the event
        CreatorRewardWasPaid(msg.sender, creatorReward);
    }
}