//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/Contracts/IERC20.sol";
import "../interfaces/Contracts/IStaking.sol";

contract DAOVoting {
    address public _chairPerson; // address of user, who has a possibility to create new proposals
    IStaking public _stakingContract; // staking contract

    uint256 public minimumQuorum; // minimum number of votes for voting
    uint256 public debatingPeriodDuration; // time for which users should vote

    uint256 private proposalId; // variable for creating new proposal ID
    
    struct User {
        mapping(uint256 => uint256) delegatedVotes; // proposalId => amount
        
        uint256 [] userProposals; // I used array, because with mapping we can't understand in which votings user participated
    }

    struct Proposal {
        bool proposalType; // 0 - simple, 1 - one of two
        bytes callData; // calldata of this proposal
        address recipient; // contract, which will be called after finishing voting
        string description; // description of this proposal
        uint256 creationTime; // creation time of this proposal

        mapping(address => bool) voted; // voted users

        uint256 positive; // number of votes for this proposal
        uint256 negative; // number of votes against this proposal
        bool ended; // is voting for this proposal ended or not

        uint256 connectedProposal; // param for "one of two" proposals
        bool choice; // param for "one of two" proposals (choice of user for choose this proposal)
    }

    mapping(address => User) private users;
    mapping(uint256 => Proposal) private proposals;

    event ProposalAdded(
        uint256 proposalId, 
        string description,
        bytes callData);
    
    event ProposalFinished(
        uint256 proposalId,
        bool votingResult,
        bool callingResult
    );

    constructor(address chairPerson_, address stakingContract_, uint256 minimumQuorum_, uint256 debatingPeriodDuration_) {
        _chairPerson = chairPerson_;
        _stakingContract = IStaking(stakingContract_);
        minimumQuorum = minimumQuorum_;
        debatingPeriodDuration = debatingPeriodDuration_;
    }

    modifier requireChairPerson {
        require(msg.sender == _chairPerson, "Not a chairperson");
        _;
    }

    modifier requireDAOVoting {
        require(msg.sender == address(this), "Function can't be called by user");
        _;
    }

    modifier requireStaking {
        require(msg.sender == address(_stakingContract), "Not staking contract");
        _;
    }

    // delegate your vote to another user
    function delegateVote(address user_, uint256 proposalId_) external {
        require(!proposals[proposalId_].voted[user_], "This user have already voted");
        require(msg.sender != user_, "You can't delegate tokens to yourself");
        require(!proposals[proposalId_].voted[msg.sender], "You have already voted");
        require(_stakingContract.balanceOf(msg.sender) > 0, "You haven't got staked tokens");

        users[msg.sender].userProposals.push(proposalId_);

        proposals[proposalId_].voted[msg.sender] = true;
        users[user_].delegatedVotes[proposalId_] += _stakingContract.balanceOf(msg.sender);
    }

    // adds new proposal (can be called only by chairperson)
    function addProposal(address recipient_, bytes memory callData_, string memory description_, bool proposalType_) public requireChairPerson {
        // Struct containing a mapping cannot be constructed, so I set values one by one
        proposals[proposalId].callData = callData_;
        proposals[proposalId].recipient = recipient_;
        proposals[proposalId].description = description_;
        proposals[proposalId].creationTime = block.timestamp;
        proposals[proposalId].proposalType = proposalType_;

        emit ProposalAdded(proposalId, description_, callData_);
        proposalId++;
    }

    // adds new proposal with choice between two functions
    function addOneOfTwoProposal
    (
        address recipient1_, bytes memory callData1_, 
        address recipient2_, bytes memory callData2_, 
        string memory description_
    ) external 
    {
        addProposal(recipient1_, callData1_, description_, true);
        proposals[proposalId-1].choice = true;
        proposals[proposalId-1].connectedProposal = proposalId;
        addProposal(recipient2_, callData2_, description_, true);
        proposals[proposalId-1].connectedProposal = proposalId - 2;
    }

    // function for voting for or against a proposal
    function vote(uint256 proposalId_, bool choice_) external {
        require(proposals[proposalId_].creationTime != 0, "Proposal doesn't exist");
        require(block.timestamp - proposals[proposalId_].creationTime < debatingPeriodDuration, "Too late");
        require(_stakingContract.balanceOf(msg.sender) > 0 || users[msg.sender].delegatedVotes[proposalId_] > 0, "You haven't got staked tokens");
        require(!proposals[proposalId_].voted[msg.sender], "You have already voted");
        
        if(proposals[proposalId_].proposalType){
            uint256 connectedId = proposals[proposalId_].connectedProposal;

            if(choice_ == proposals[proposalId_].choice){
                proposals[proposalId_].positive += users[msg.sender].delegatedVotes[proposalId_] += _stakingContract.balanceOf(msg.sender);
                proposals[connectedId].negative += users[msg.sender].delegatedVotes[connectedId] += _stakingContract.balanceOf(msg.sender);
            }
            else {
                proposals[proposalId_].negative += users[msg.sender].delegatedVotes[proposalId_] += _stakingContract.balanceOf(msg.sender);
                proposals[connectedId].positive += users[msg.sender].delegatedVotes[connectedId] += _stakingContract.balanceOf(msg.sender);
            }

            proposals[proposalId_].voted[msg.sender] = true;
            proposals[connectedId].voted[msg.sender] = true;
            
            users[msg.sender].userProposals.push(proposalId_);
            users[msg.sender].userProposals.push(connectedId);
        }
        else {
            if(choice_){
                proposals[proposalId_].positive += users[msg.sender].delegatedVotes[proposalId_] += _stakingContract.balanceOf(msg.sender);
            }
            else {
                proposals[proposalId_].negative += users[msg.sender].delegatedVotes[proposalId_] += _stakingContract.balanceOf(msg.sender);
            }

            proposals[proposalId_].voted[msg.sender] = true;
            users[msg.sender].userProposals.push(proposalId_);
        }
    }

    // finishes voting 
    function finishProposal(uint proposalId_) external {
        require(block.timestamp - proposals[proposalId_].creationTime > debatingPeriodDuration, "Too early");
        require(proposals[proposalId_].creationTime != 0, "Proposal doesn't exist");

        proposals[proposalId_].ended = true;

        if(proposals[proposalId_].positive > proposals[proposalId_].negative && proposals[proposalId_].positive > minimumQuorum) {
            (bool success, ) =  proposals[proposalId_].recipient.call(proposals[proposalId_].callData);
            emit ProposalFinished(proposalId_, true, success);
        }
        else {
            if(proposals[proposalId_].proposalType){
                
                uint256 connectedId = proposals[proposalId_].connectedProposal;
                proposals[connectedId].ended = true;
                
                if(proposals[connectedId].positive > proposals[connectedId].negative && proposals[connectedId].positive > minimumQuorum) {
                    (bool success, ) =  proposals[connectedId].recipient.call(proposals[connectedId].callData);
                    emit ProposalFinished(proposalId_, true, success);
                }
                else {
                    emit ProposalFinished(proposalId_, false, false);
                }
            } 
        }
    }

    // ends withdrawing
    function endWithdrawing(address user_) external requireStaking {
        delete users[user_].userProposals;
    }

    // function for unstaking in staking contract
    function activeVotingsExists(address user_) external view returns (bool) {
        for(uint i=0; i < users[user_].userProposals.length; ++i) {
            if(!proposals[users[user_].userProposals[i]].ended) {
                return true;
            }
        }
        return false;
    }

    // changes settings of voting contract (can be called only after voting)
    function changeSettings(uint256 minimumQuorum_, uint256 debatingPeriodDuration_) external requireDAOVoting {
        minimumQuorum = minimumQuorum_;
        debatingPeriodDuration = debatingPeriodDuration_;
    }

    // returns information about specific voting
    function votingInfo(uint256 proposalId_) external view returns (bool, string memory, uint256, uint256, bool) {
        return (proposals[proposalId_].proposalType,
                proposals[proposalId_].description, 
                proposals[proposalId_].positive,
                proposals[proposalId_].negative,
                proposals[proposalId_].ended);
    }

    // returns contract settings
    function settingsInfo() external view returns (uint256, uint256) {
        return (minimumQuorum, debatingPeriodDuration);
    }

    function lastProposal() external view returns (uint256) {
        return proposalId;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function allowance(address _owner, address _spender) external view returns (uint256);

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IStaking {
   
   function balanceOf (address user_) external view returns (uint);

}