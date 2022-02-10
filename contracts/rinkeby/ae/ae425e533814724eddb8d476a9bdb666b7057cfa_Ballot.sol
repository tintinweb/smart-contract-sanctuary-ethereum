/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// SPDX-License-Identifier: UNLICENSE
pragma solidity >=0.7.0 <0.9.0;
contract Ballot {
    struct Voter {
        uint weight; //how many votes does this person basically have.
        bool voted;
        address delegateperson; //the address of the person who can vote on behalf of me.
        uint vote;  //what is the index of the thing i am voting for.
    }
    // This is a type for a single Canidate.
    struct Canidate {
        string name;
        uint voteCount;
    }
    uint public totalVotes = 0;
    uint public registeredVoter = 0;
    address public owner;
    Canidate [] public canidates;
    mapping(address => Voter) public voters;
    enum State{Created,Voting,Ended}
    State public state;
     constructor(string[] memory canidateNames) {
        owner = msg.sender;
        voters[owner].weight = 1;
        for (uint i = 0; i < canidateNames.length; i++) {
            canidates.push(Canidate({name: canidateNames[i],voteCount: 0}));
        }
    }
    function giveRightToVote(address _voter) external inState(State.Created) onlyOwner() {
        require(!voters[_voter].voted,"The voter already voted.");
        require(voters[_voter].weight == 0);
        voters[_voter].weight = 1;
        registeredVoter++;
    }
    function totalCanidates() external view returns(uint){
        return canidates.length;
    }
    function startVoting() public inState(State.Created) onlyOwner() {
        state = State.Voting;
    }
    //THIS function is called by the have_Roght_of_vote  person.
    function delegateVote(address to) external inState(State.Voting) {
        Voter memory registeredVotere;
        registeredVotere = voters[msg.sender]; //get a reference to the current voter
                                        // that is sending this transaction
        require(!registeredVotere.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");
        while (voters[to].delegateperson != address(0)) //this means they already delicate their vote to
        {                                               //someone else.
            to = voters[to].delegateperson;
            require(to != msg.sender, "Found loop in delegation.");
        }
        // Since `sender` is a reference, this
        // modifies `voters[msg.sender].voted`
        registeredVotere.voted = true;
        registeredVotere.delegateperson = to;
        Voter memory delegatedperson = voters[to];
        if (delegatedperson.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            canidates[delegatedperson.vote].voteCount += registeredVotere.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegatedperson.weight += registeredVotere.weight;
        }
    }
     function vote(uint _canidate) external inState(State.Voting) {
        Voter memory registeredVotere;
        registeredVotere = voters[msg.sender];
        require(registeredVotere.weight != 0, "Has no right to vote");
        require(!registeredVotere.voted, "Already voted.");
        registeredVotere.voted = true;
        registeredVotere.vote = _canidate;
        canidates[_canidate].voteCount += registeredVotere.weight;
        totalVotes++;
    }
    function endVoting() inState(State.Voting) onlyOwner() public {
        state = State.Ended;
        //finalResult = countResult;
    }
    /// @dev Computes the winning proposal taking all
    /// previous votes into account.
    function winningCanidate() public inState(State.Ended) onlyOwner() view returns (uint winningCanidate_)
    {
        uint winningVoteCount = 0;
        for (uint i = 0; i < canidates.length; i++)
        {
            if (canidates[i].voteCount > winningVoteCount)
            {
                winningVoteCount = canidates[i].voteCount;
                winningCanidate_ = i;
            }
        }
    }
    function winnerName() external inState(State.Ended) view returns (string memory winnerName_)
    {
        winnerName_ = canidates[winningCanidate()].name;
    }
    // modifier condition(bool _condition) {
    //     require(_condition);
    //     _;
    // }
    modifier onlyOwner () {
        require(msg.sender == owner, "You must have to be the owner of the Ballet");
        _;
    }
    modifier inState(State _state) {
        require(state == _state);
        _;
    }
}