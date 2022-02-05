// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract ParseStrings{
    function stringToBytes32(string memory _text) external pure returns (bytes32){
        return bytes32(bytes(_text));
    }

    function bytes32ToString(bytes32 _data) external pure returns (string memory){
        return string(abi.encodePacked(_data));
    }

    // 0x4e69636f6c617300000000000000000000000000000000000000000000000000
    // 0x53616e746961676f000000000000000000000000000000000000000000000000
    // 0x4b6172656e000000000000000000000000000000000000000000000000000000
    // 0x506564726f000000000000000000000000000000000000000000000000000000

}


contract CEOVote {
   
    struct Voter {
        uint256 weight;
        bool voted;
        address delegate;
        uint256 candidateIndex;
    }

    struct Candidate {
        bytes32 name;
        uint256 voteCount; 
    }

    address public admin;
    bool public isActive = true;
    uint256 public START_DATE = block.number;

    mapping(address => Voter) public voters;

    Candidate[2] public candidates;
    
    constructor(bytes32 _candidateOneName, bytes32 _candidateTwoName) {
        admin = msg.sender;
        voters[admin].weight = 1;
        candidates[0] = Candidate({
            name: _candidateOneName,
            voteCount: 0
        });

        candidates[1] = Candidate({
            name: _candidateTwoName,
            voteCount: 0
        });
    }
    
    
    function giveRightToVote(address voter) public {
        require(msg.sender == admin, "Only admin can give right to vote.");
        require(!voters[voter].voted,"The voter already voted.");
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    function vote(uint256 _candidate) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.candidateIndex = _candidate;

        candidates[_candidate].voteCount += sender.weight;
        if(candidates[_candidate].voteCount > 3 || block.number > START_DATE + 11520){
            finishVoting();
        }
    }

    function winningCandidate() public view returns (uint256 winningProposal_){
        if (candidates[0].voteCount > candidates[1].voteCount) {
            winningProposal_ = 0;
        }else{
            winningProposal_ = 1;
        }
    }

    function finishVoting() internal{
        isActive = false;
    }

    function winnerName() public view returns (bytes32 winnerName_){
        if(!isActive){
            winnerName_ = candidates[winningCandidate()].name;
        } 
    }
}


interface ICEOVote{
    function winnerName() external view returns (bytes32 winnerName_);
    function isActive() external view returns (bool);
}

contract CEOBet{

    uint256 constant public DID_BET = 1;
    uint256 constant public DID_NOT_BET = 0;

    struct Gambler{
       bytes32 userBet;
       uint256 alreadyBet;  
    }

    mapping(address => Gambler) public gamblers;
    mapping(address => bool) public isWhitelisted;
    ICEOVote public betTarget;

    constructor(address _userOne, address _userTwo, ICEOVote _CeoVotingAddress){
        betTarget = _CeoVotingAddress;
        isWhitelisted[_userOne] = true;
        isWhitelisted[_userTwo] = true;
    }

    function bet(bytes32 _candidate) public payable {
        bool isActive = ICEOVote(betTarget).isActive();
        require(isActive == true, "Already finished");
        require(isWhitelisted[msg.sender], "You cannot participate");
        require(msg.value == 1 ether, "Must bet one ether");
        require(gamblers[msg.sender].alreadyBet == DID_NOT_BET, "Already bet");
        Gambler storage gambler = gamblers[msg.sender];
        gambler.alreadyBet = DID_BET;
        gambler.userBet = _candidate;
    }

    function withdrawPrice() public {
        bool isActive = ICEOVote(betTarget).isActive();
        require(isActive != true, "Wait until voting is done");
        require(isWhitelisted[msg.sender], "You did not participate");
        require(gamblers[msg.sender].userBet == ICEOVote(betTarget).winnerName());
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transaction failed");
    }
}