//SPDX-License-Identifier: MIT

//pragma solidity ^0.8.0;

pragma solidity ^0.8.0;

import "./TimeLine.sol";

contract DAO{
    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    TimeLine public timeLine;


    constructor(TimeLine _timeLine){
        owner = msg.sender;
        timeLine = _timeLine;
        nextProposal = 1;
    }

    struct proposal{
        uint256 id;
        bool exists;
        string description;
        uint deadline;
        uint256 votesUp;
        uint256 votesDown;
        address[] canVote;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    mapping(uint256 => proposal) public Proposals;

    event proposalCreated(uint256 id, string description, uint256 maxVotes, address proposer);

    event newVote(uint256 votesUp, uint256 votesDown, address voter, uint256 proposal, bool votedFor);

    event proposalCount(
        uint256 id,
        bool passed
    );

    function checkProposalEligibility(address _proposalist) private view returns(bool){
        if(timeLine.balanceOf(_proposalist) > 0){
            return true;
        }
        return false;
    }

    function checkVoteEligibility(address _voter) private view returns(bool){
        //address[] storage _investorStorage = timeLine.investors();
        //storage _investorStorage = timeLine.investors();
        uint256 _investorsIndex = timeLine.investorsIndex();
        for(uint i=0; i<_investorsIndex; i++){
            address _investor = timeLine.investors(i);
            if(_investor == _voter){
                return true;
            }
        }
        return false;
    }

    function createProposal(string memory _description) public{
        require(checkProposalEligibility(msg.sender), "Only TimeLine Token holders can put forth Proposals");
         uint256 _investorsIndex = timeLine.investorsIndex();

        address[] memory _canVote = new address[](_investorsIndex);

        for(uint i=1; i<_investorsIndex; i++){
            //_canVote.push(timeLine.investors(i));
            _canVote[i] = timeLine.investors(i);
        }

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.timestamp + 60 minutes;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _investorsIndex;

        emit proposalCreated(nextProposal, _description, _investorsIndex, msg.sender);
        nextProposal++;
    }


    function voteOnProposal(uint256 _id, bool _vote) public{
        require(Proposals[_id].exists,"This Proposal does not exist");
        require(checkVoteEligibility(msg.sender),"You can not vote on this Proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
        require(block.number <= Proposals[_id].deadline, "This deadline has passed for this Proposal");

        proposal storage p = Proposals[_id];
        if(_vote){
            p.votesUp++;
        }else{
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }


    function countVotes(uint256 _id) public{
        require(msg.sender == owner, "Only the owner can count votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(block.timestamp >= Proposals[_id].deadline, "This deadline has not passed for this Proposal");
        require(!Proposals[_id].countConducted, "Voting has already been conducted");

        proposal storage p = Proposals[_id];

        if(Proposals[_id].votesDown < Proposals[_id].votesUp){
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    //Check to See if Proposal Deadline Has been met with
     function isDeadLineMet(uint _id) public view returns(bool){
         require(msg.sender == owner, "Only Owner Can View Deadline");
         proposal storage p = Proposals[_id];
         
         if(p.deadline > block.timestamp){
             return true;
         }
         return false;
     }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract TimeLine {
    string  public name = "TimeLine coin";
    string  public symbol = "TL";
    uint256 public totalSupply = 3000000000000000000000000; // 3 million TimeLine tokens
    uint8   public decimals = 18;



    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    //address[] public investors;
    mapping(uint256 => address) public investors;
    uint256 public investorsIndex = 1;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        investors[investorsIndex] = msg.sender;
        investorsIndex++;
    }

     function returnInvestorsArray() public view returns(address[] memory){
        address[] memory _investors = new address[](investorsIndex);
        for(uint i=0; i<investorsIndex; i++){
            _investors[i] = investors[i];
        }
        return _investors;
     }

     function addToInvestorArray(address _investor) private{
         require(balanceOf[_investor] >= 0);
         for(uint i = 1; i<investorsIndex; i++){
            if(investors[i] == _investor){
                return;
            }
         }
         investors[investorsIndex] = _investor;
         investorsIndex++;
     }
   /* 
     function removeInvestorArray(address _investor) private{
         if(balanceOf[_investor] <= 0){
             for(uint i=0; i<investors.length; i++){
                 if(investors[i] == _investor){
                    _burn(i);
                 }
             }
         }
         } */

      function removeInvestorArray(address _investor)private{
        if(balanceOf[_investor] <= 0){
            for(uint i=1; i<investorsIndex; i++){
                if(investors[i] == _investor){
                    delete investors[i];
                    investorsIndex--;
                    return;
                }
            }
        }
      }

    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        //add to investors array to use For DAO propagation

        addToInvestorArray(_to);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        removeInvestorArray(_from);
        addToInvestorArray(_to);
        return true;
    }
}