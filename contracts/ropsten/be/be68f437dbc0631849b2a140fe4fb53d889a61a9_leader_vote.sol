/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

contract leader_vote {

    struct Voter {
        bool canVote;
        uint giveVote;
    }
    mapping(address => Voter) voters;

    struct Candidate {
        string name;
        string politics;
        uint voteCount;
    }
    Candidate[] candidates;

    enum State {Nomination, Vote, Announcement}

    string voteName;
    address chairman;
    uint voteLimit; 
    State state;

    constructor(string memory _voteName, uint _number) public {
        chairman = msg.sender;
        voteName = _voteName;
        voters[chairman].canVote = true;
        voteLimit = _number;
        state = State.Nomination;
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

    modifier isAuthorized (address _sender){
        require(
            voters[_sender].canVote,
            "抱歉！您不具有投票權！"
        );
        _;
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

    function setVoteLimit(uint _number) public isChair(msg.sender) checkState(State.Nomination){
        require(
            _number>0,
            "可投票數須大於0！"
        );
        require(
            _number != voteLimit,
            "您沒有更改可投票數！"
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

    function getState() public view returns(State){
        return state;
    }
    
    function getVoteLimit() public view returns(uint){
        return voteLimit;
    }

    function getMyRemainingVote() public view isAuthorized(msg.sender) returns(uint){
        return voteLimit-voters[msg.sender].giveVote;
    }

    function vote(uint [] memory toWhom) public checkState(State.Vote) isAuthorized(msg.sender){
        Voter storage sender = voters[msg.sender];
        require(
            sender.giveVote <= voteLimit, 
            "抱歉！您已經用罄可投票數！"
        );
        require(
            toWhom.length <= voteLimit-sender.giveVote,
            "抱歉！您投了太多票！"
        );
        require(
            toWhom.length>0,
            "抱歉！您沒有投票吧？"
        );
        sender.giveVote += toWhom.length;
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
            else if(candidates[i].voteCount == winAmount){
                winner=string(abi.encodePacked(winner,";",candidates[i].name));
            }
        }
        return(winner, winAmount);
    }
}