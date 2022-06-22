/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

contract leader_vote {

    struct Voter {
        bool canVote;
        uint giveVote;
    }
    struct Candidate {
        string name;
        string politics;
        uint voteCount;
    }
    string voteName;
    address chairman;
    uint voteLimit; 
    mapping(address => Voter) voters;
    Candidate[] candidates;
    enum State {Nomination, Vote, Announcement}
    State state = State.Nomination;

    constructor(string memory _voteName, uint _number) public {
        chairman = msg.sender;
        voteName = _voteName;
        voters[chairman].canVote = true;
        voteLimit = _number;
    }
 
    modifier isChair (address _sender){
        require(
            _sender == chairman,
            "抱歉！您不具有執行這項動作的權限！"
        );
        _;
    }

    modifier checkState (State _state){
        require(
            state == _state,
            "錯誤！現階段不允許執行這項動作！"
        );
        _;
    }

    function addCandidate(string memory _name, string memory _politics) public isChair(msg.sender) checkState(State.Nomination){
        candidates.push(Candidate({name: _name, politics: _politics, voteCount: 0}));
    }
    
    function authorizeVoter(address voter) public isChair(msg.sender){
        require(
            state != State.Announcement,
            "無法新增，本次投票已結束！"
        );
        require(
            voters[voter].canVote == false,
            "此地址已擁有投票權！"
        );
        voters[voter].canVote = true;
    }

    function nextState() public isChair(msg.sender){
        if (state == State.Nomination){
            require(
                candidates.length!=0,
                "抱歉！目前還沒有候選人！"
            );
            state = State.Vote;
        }
        else if (state == State.Vote){
            state = State.Announcement;
        }
    }

    function setVoteLimit(uint _number) public isChair(msg.sender) checkState(State.Nomination){
        require(
            _number>0,
            "可投票數須大於0！"
        );
        voteLimit = _number;
    }

    function getCandidates() public view returns(string [] memory, string [] memory){
        string [] memory namelist = new string[](candidates.length);
        string [] memory politicslist = new string[](candidates.length);
        for (uint i=0; i<candidates.length; i++){
            namelist[i] = candidates[i].name;
            politicslist[i] = candidates[i].politics;
        }
        return (namelist, politicslist);
    }

    function getVoteLimit() public view returns(uint){
        return voteLimit;
    }

    function vote(uint [] memory toWhom) public checkState(State.Vote){
        Voter storage sender = voters[msg.sender];
        require(
            sender.giveVote < voteLimit, 
            "抱歉！您已經用罄可投票數！"
        );
        require(
            toWhom.length<voteLimit,
            "抱歉！您投了太多票！"
        );
        require(
            sender.canVote != false,
            "抱歉！您不具有投票權！"
        );
        sender.giveVote += 1;
        for (uint i = 0; i<toWhom.length; i++){
            require(
                toWhom[i]-1>=0 && toWhom[i]-1<candidates.length,
                "抱歉！您投了無效票！"
            );
            candidates[toWhom[i]-1].voteCount += 1;
        }
    }

    function showResult() public view checkState(State.Announcement) returns (Candidate [] memory){
        return candidates;
    }

    function showWinner() public view checkState(State.Announcement) returns (string memory, uint){
        uint winAmount = 0;
        string memory winner;
        for (uint i = 0; i < candidates.length; i++){
            if (candidates[i].voteCount > winAmount){
                winner = candidates[i].name;
                winAmount = candidates[i].voteCount;
            }
        }
        return(winner, winAmount);
    }
}