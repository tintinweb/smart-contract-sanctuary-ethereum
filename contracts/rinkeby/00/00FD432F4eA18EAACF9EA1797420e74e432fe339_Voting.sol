// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Voting {
    address owner;
    uint priceForVote = 10000000000000000 wei;
    uint totalComission;
    string[] allBallots; 
    event newBallot(string name, uint time);
    mapping(string => Ballot) public ballots;
    
    struct Ballot {
        address[] candidates;
        address winner;
        uint pool;
        uint timeOfBeginning;
        mapping(address=>uint) firstVote;
        mapping(address=>uint) counterOfVotes;
        mapping(address=>bool) voted;
        mapping(address=>bool) isCandidate;
        bool exist;
    }


    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender==owner, "You are not an owner!");
        _;
    }

    function addVoting(address[] memory candidates, string memory name) external onlyOwner {
        require(ballots[name].exist != true, "such a vote already exists");
        for(uint i; i < candidates.length; i++) {
            if(candidates[i] == address(0)) {
                revert("Candidate cannot be zero address");
            }
        }
        ballots[name].timeOfBeginning = block.timestamp;
        ballots[name].candidates = candidates;
        ballots[name].exist = true;
        for(uint i; i < candidates.length; i++) {
            ballots[name].isCandidate[candidates[i]] = true;
        }
        allBallots.push(name);
        emit newBallot(name, block.timestamp);
    }

    function vote(string memory name, address candidate) external payable {
        require(block.timestamp - ballots[name].timeOfBeginning <= 3 days, "The voting is over");
        require(msg.sender!=address(0), "Incorrect address!");
        require(ballots[name].isCandidate[candidate] == true, "This address isn't candidate!");
        require(msg.value >= priceForVote, "Please send money no less");
        require(ballots[name].voted[msg.sender] == false, "You already used your vote");
        if(ballots[name].counterOfVotes[candidate]==0) {
            ballots[name].firstVote[candidate] = block.timestamp;
        }
        ballots[name].voted[msg.sender] = true;
        ballots[name].counterOfVotes[candidate]++;
        ballots[name].pool += msg.value;
        
    }

    receive() external payable {
        totalComission += msg.value;
    }

    function finish(string memory name) public {
        require(block.timestamp - ballots[name].timeOfBeginning >= 3 days, "The voting isn't over");
        uint i;

        if(ballots[name].pool != 0) {
            for(uint j; j<ballots[name].candidates.length; j++) {
                if(ballots[name].counterOfVotes[ballots[name].candidates[i]] < ballots[name].counterOfVotes[ballots[name].candidates[j]]) {
                    i = j;
                }
                if(ballots[name].counterOfVotes[ballots[name].candidates[i]] == ballots[name].counterOfVotes[ballots[name].candidates[j]] && ballots[name].firstVote[ballots[name].candidates[i]] > ballots[name].firstVote[ballots[name].candidates[j]]) {
                    i = j;
                }
            }

            ballots[name].winner = ballots[name].candidates[i];
            (bool _success, ) = ballots[name].candidates[i].call{value: ballots[name].pool*9/10}("");
            require(_success, "Transfer failed");
            totalComission += ballots[name].pool;
        }
    }

    function withdrawComission() external payable onlyOwner {
        require(totalComission > 0, "There is not a comission");
        (bool _success, ) = owner.call{value: totalComission}("");
        require(_success == true, "Transfer failed");
        totalComission = 0;
    }

    function showBallots() external view returns(string[] memory) {
        return allBallots;
    }

    function showCandidates(string memory name) external view returns(address[] memory) {
        return ballots[name].candidates;
    }
    
    function candidateVoices(string memory name, address candidate) external view returns(uint) {
        return ballots[name].counterOfVotes[candidate];
    }

    function showWinner(string memory name) external view returns(address) {
        require(block.timestamp - ballots[name].timeOfBeginning >= 3 days, "The voting isn't over");
        return ballots[name].winner;
    }
    function showOwner() public view returns(address) {
        return owner;
    }
    function showBegin(string memory name) external view returns(uint) {
        return ballots[name].timeOfBeginning;
    }
}