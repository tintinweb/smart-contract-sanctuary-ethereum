// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Voting {
    uint16 public numVotings;
    uint16 public numCandidates;
    address public owner;
    uint256 feeFund; // Fees fund of the owner

    // stores voting data
    struct VotingData {
        bool finished; // if true, that voting already finished
        mapping(address => bool) voted; // tracks who's already voted
        uint16[] results; // stores user's votes
        uint32 endTime; // timestamp - end of voting
        string votingName;
    }
    mapping(uint16 => VotingData) votings;

    // stores candidates
    struct Candidate {
        string name; // candidate's name
        address payable candidateAddr; //candidate's address
    }
    mapping(uint16 => Candidate) public candidates;

    constructor() {
        owner = msg.sender;
        //candidates[0] = Candidate("owner", payable(owner));
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    // Add a new candidate
    function addCandidate(string memory _name, address _candidateAddr)
        public
        onlyOwner
    {
        candidates[++numCandidates] = Candidate(_name, payable(_candidateAddr));
    }

    // Add a new voting
    function addVoting(string memory _name) public onlyOwner {
        numVotings++;
        votings[numVotings].votingName = _name;
        //The voting period will last 3 days
        votings[numVotings].endTime = uint32(block.timestamp + 3 days);
    }

    // Choose voting(_votingId) and give your vote to candidate(_candidateId)
    function vote(uint16 _votingId, uint16 _candidateId) public payable {
        require(msg.value == 0.01 ether, "0.01 Eth"); //Vote costs 0.01 eth
        require(_votingId <= numVotings, "Invalid id");
        require(_candidateId <= numCandidates, "Invalid candidate id");
        VotingData storage v = votings[_votingId];
        require(block.timestamp <= v.endTime, "Time is over");
        require(!v.voted[msg.sender], "You've already voted");
        v.voted[msg.sender] = true; // mark a user as voted
        v.results.push(_candidateId); // push chosen candidate id to the array
    }

    // Finish voting
    // The function will transfer 90% of the fund to a winner and count 10% to the owner
    function finishVoting(uint16 _votingId) public {
        require(_votingId <= numVotings, "Invalid id");
        VotingData storage v = votings[_votingId];
        require(block.timestamp > v.endTime, "Await");
        require(!v.finished, "Finished");
        v.finished = true; // mark the voting as finished
        uint256 _fund = v.results.length * 10**15; // calculates 1/10 of the fund
        candidates[getWinner(v.results)].candidateAddr.transfer(_fund * 9); // 90%
        feeFund += _fund; // 10%
    }

    // Get information about any voting
    function getVoting(uint16 _votingId)
        public
        view
        returns (
            uint16,
            string memory,
            uint256,
            uint16,
            uint32,
            bool
        )
    {
        VotingData storage v = votings[_votingId];
        return (
            _votingId, // voting id
            v.votingName, // voting name
            v.results.length, // number of participants
            getWinner(v.results), // winner (candidate id)
            v.endTime, // end timestamp
            v.finished // retunrs state( if true - finished )
        );
    }

    // Withdraw fee fund at any time
    // Only owner able to call this function
    function withdrawFee() public onlyOwner {
        payable(msg.sender).transfer(feeFund);
        feeFund = 0;
    }

    // Calculates a winner from passed array
    function getWinner(uint16[] memory _results) private view returns (uint16) {
        uint16[] memory count;
        count = new uint16[](numCandidates + 1);
        uint16 number;
        uint16 maxIndex;
        for (uint256 i = 0; i < _results.length; ++i) {
            number = _results[i];
            count[number] += 1;
            if (count[number] > count[maxIndex]) {
                maxIndex = number;
            }
        }
        return maxIndex; // returns the most frequent number(candidate id)
    }
}