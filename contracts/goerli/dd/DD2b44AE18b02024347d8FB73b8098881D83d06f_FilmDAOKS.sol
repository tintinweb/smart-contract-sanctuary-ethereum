/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 < 0.9.0;


contract FilmDAOKS {

  enum ProposalState {
      Review,
      Cancelled,
      Voting,
      Defeated,
      Succeeded,
      Accepted,
      Rejected
  }


  enum VoteType {
      Against,
      For,
      Abstain
  }


  struct Project {
      uint256 stakedAmount;
      uint256 stakersCount;
      uint256 proposalThresholdAmt;
      uint256 votingThresholdAmt;
      uint256 minStakingAmt;
      uint256[] ProjectProposals;
  }

  struct Proposal {
      uint256 ForWeight;
      uint256 AgainstWeight;
      uint256 AbstainWeight;
      uint TimeEnd;
      ProposalState State;
      address[] ForVoters;
      address[] AgainstVoters;
      address[] AbstainVoters;
      mapping(address => bool) ProposalVoters;
  }


  mapping(address => uint256) internal OrgAdmins;
  mapping(uint256 => mapping(address => uint256)) public StakedAmounts;
  mapping(uint256 => Project) public Projects;
  mapping(uint256 => Proposal) public Proposals;


  uint256 public ProposalsCount;
  uint256 public ProjectsCount;
  address public Owner;


  constructor() {
    OrgAdmins[msg.sender] = 1;
    Owner = msg.sender;
  }

 
  function OrgAdmin_Check(address _add) public view returns (bool) {
    return OrgAdmins[_add] > 0 ? true : false;
  }

  function OrgAdmin_Add(address _orgAdmin) public {
    require(OrgAdmin_Check(msg.sender) == true, 'Only admins can call this function.');
     OrgAdmins[_orgAdmin] = 1;
  }

  function OrgAdmin_Remove(address _orgAdmin) public {
    require(OrgAdmin_Check(msg.sender) == true, 'Only admins can call this function.');
    require(Owner != _orgAdmin, 'Owner cannot be removed');
     OrgAdmins[_orgAdmin] = 0;
  }


  function Project_Add(uint256 _proposalThresholdAmt, uint256 _votingThresholdAmt, uint256 _minStakingAmt) public returns(uint256) {
    require(OrgAdmin_Check(msg.sender) == true, 'Only admins can create projects.');
    require(_minStakingAmt > 0, 'Minimum staking amount should be greater than zero');
    require(_proposalThresholdAmt >= _minStakingAmt, 'Minimum proposal amount should be greater min staking amount');
    require(_votingThresholdAmt >= _minStakingAmt, 'Minimum voting amount should be greater min staking amount');
    unchecked {
      ProjectsCount++;
      Projects[ProjectsCount].stakedAmount = 0;
      Projects[ProjectsCount].proposalThresholdAmt = _proposalThresholdAmt;
      Projects[ProjectsCount].votingThresholdAmt = _votingThresholdAmt;
      Projects[ProjectsCount].minStakingAmt = _minStakingAmt;
    }
    return ProjectsCount;
  }

  function Project_GetVotingThrashold(uint256 _projectID) public view returns (uint256) {
    return Projects[_projectID].votingThresholdAmt;
  }

  function Project_GetProposalThrashold(uint256 _projectID) public view returns (uint256) {
    return Projects[_projectID].proposalThresholdAmt;
  }

  function Project_SetVotingThrashold(uint256 _projectID, uint256 _votingThresholdAmt) public {
    require(OrgAdmin_Check(msg.sender) == true, 'Only admins can set values.');
    Projects[_projectID].votingThresholdAmt = _votingThresholdAmt;
  }

  function Project_SetProposalThrashold(uint256 _projectID, uint256 _proposalThresholdAmt) public {
    require(OrgAdmin_Check(msg.sender) == true, 'Only admins can set values.');
    Projects[_projectID].proposalThresholdAmt = _proposalThresholdAmt;
  }

  function Project_GetStakedInfo(uint256 _projectID) public view returns (uint256 StakersCount, uint256 StakedAmount) {
    return (Projects[_projectID].stakersCount, Projects[_projectID].stakedAmount);
  }

  function Project_GetAllProposals(uint256 _projectID) public view returns (uint256[] memory) {
    return Projects[_projectID].ProjectProposals;
  }


  function Project_StakeMoney(uint256 _amount, uint256 _projectID) public  {
    require(_amount > 0, 'Invalid Amount.');
    require((_projectID <= ProjectsCount) && (_projectID > 0), 'Invalid Project ID' );
    require(StakedAmounts[_projectID][msg.sender] + _amount >= Projects[ProjectsCount].minStakingAmt, 'Low staking amount');

    unchecked {
      Projects[_projectID].stakedAmount += _amount;
      if (StakedAmounts[_projectID][msg.sender] == 0) {
        Projects[_projectID].stakersCount += 1;
      }     
      StakedAmounts[_projectID][msg.sender] += _amount;
    }
  }


  function Proposal_Add(uint256 _projectID) public returns(uint256) {
    require((_projectID <= ProjectsCount) && (_projectID > 0), 'Invalid Project ID' );
    require(StakedAmounts[_projectID][msg.sender] >= Projects[_projectID].proposalThresholdAmt, 'Low staked amount');

  
    ProposalsCount++;
    Projects[_projectID].ProjectProposals.push(ProposalsCount);

    Proposals[ProposalsCount].State = ProposalState.Review;
      return ProposalsCount;
  }

  function Proposal_GetVoterCounts(uint256 _proposalID) public view returns(uint256 ForVotes, uint256 AgainstVotes, uint256 AbstainVotes)  { 

    return (Proposals[_proposalID].ForVoters.length, 
        Proposals[_proposalID].AgainstVoters.length, 
        Proposals[_proposalID].AbstainVoters.length);
  }


  function Proposal_GetVotingWeights(uint256 _proposalID) public view returns(uint256 VoteForWeight, uint256 VoteAgainstWeight, uint256 VoteAbstainWeight)  {    
    return (Proposals[_proposalID].ForWeight, 
            Proposals[_proposalID].AgainstWeight,
            Proposals[_proposalID].AbstainWeight);
  }

  function Proposal_GetForVoters(uint256 _proposalID) public view returns(address[] memory)  {    
    return Proposals[_proposalID].ForVoters;
  }

  function Proposal_GetAgainstVoters(uint256 _proposalID) public view returns(address[] memory)  {    
    return Proposals[_proposalID].AgainstVoters;
  }
  
  function Proposal_GetAbstainVoters(uint256 _proposalID) public view returns(address[] memory)  {    
    return Proposals[_proposalID].AbstainVoters;
  }


  function Proposal_GetState(uint256 _proposalID) public view returns (ProposalState) {
    return Proposals[_proposalID].State;
  }


  function Proposal_SetState(uint256 _proposalID, ProposalState _state) public  {
    require(OrgAdmin_Check(msg.sender) == true, 'Only admins can change state.');
    require((_proposalID <= ProposalsCount) && (_proposalID > 0), 'Invalid Proposal ID' );
    Proposals[_proposalID].State = _state;
  }

  function Proposal_SetState_OpenVoting(uint256 _proposalID, uint _openForHours) public  {
    require(OrgAdmin_Check(msg.sender) == true, 'Only admins can change state.');
    require((_proposalID <= ProposalsCount) && (_proposalID > 0), 'Invalid Proposal ID' );
    require(_openForHours > 0, 'Invalid voting time');

    Proposals[_proposalID].TimeEnd = block.timestamp + (_openForHours * 1 hours);
    Proposals[_proposalID].State = ProposalState.Voting;
  }


  function Proposal_SetState_CloseVoting(uint256 _projectID, uint256 _proposalID) public returns(uint256 VoteForWeight, uint256 VoteAgainstWeight) {
    require(OrgAdmin_Check(msg.sender) == true, 'Only admins can change state.');
    require((_projectID <= ProjectsCount) && (_projectID > 0), 'Invalid Project ID' );
    require((_proposalID <= ProposalsCount) && (_proposalID > 0), 'Invalid Proposal ID' );

    if(Proposals[_proposalID].State > ProposalState.Voting) {
        return (Proposals[_proposalID].ForWeight, Proposals[_proposalID].AgainstWeight);
    }

    uint256 nForWeight;
    uint256 nAgainstWeight;

    // nAgainstWeight = AgainstWeight[_proposalID];
    // nForWeight = ForWeight[_proposalID];
    (nForWeight, nAgainstWeight) = Proposal_EvaluateVotes(_projectID, _proposalID);

    if (nForWeight >= nAgainstWeight) {
      Proposals[_proposalID].State = ProposalState.Succeeded;
    } else {
      Proposals[_proposalID].State = ProposalState.Defeated;
    }
    return (nForWeight, nAgainstWeight);
  }

  function Proposal_EvaluateVotes(uint256 _projectID, uint256 _proposalID) public returns (uint256 VoteForWeight, uint256 VoteAgainstWeight) {
    require(OrgAdmin_Check(msg.sender) == true, 'Only admins can change state.');
    require((_projectID <= ProjectsCount) && (_projectID > 0), 'Invalid Project ID' );
    require((_proposalID <= ProposalsCount) && (_proposalID > 0), 'Invalid Proposal ID' );

    uint256 nCount;
    uint256 nForWeight;
    uint256 nAgainstWeight;

    for (nCount = 0; nCount < Proposals[_proposalID].ForVoters.length; nCount++) 
    {
      nForWeight += StakedAmounts[_projectID][msg.sender];
    }

    for (nCount = 0; nCount < Proposals[_proposalID].AgainstVoters.length; nCount++) 
    {
      nAgainstWeight += StakedAmounts[_projectID][msg.sender];
    }

    Proposals[_proposalID].ForWeight = nForWeight;
    Proposals[_proposalID].AgainstWeight = nAgainstWeight;
    return(nForWeight, nAgainstWeight);
  }



   function Proposal_CastVote(uint8 _voteType, uint256 _projectID, uint256 _proposalID) public  {
      require((_projectID <= ProjectsCount) && (_projectID > 0), 'Invalid Project ID' );
      require((_proposalID <= ProposalsCount) && (_proposalID > 0), 'Invalid Proposal ID' );
      require(StakedAmounts[_projectID][msg.sender] >= Projects[_projectID].votingThresholdAmt, 'Low staked amount');
      require(Proposals[_proposalID].ProposalVoters[msg.sender] == false, 'Already Voted');
      require(Proposals[_proposalID].State == ProposalState.Voting, 'Proposal not open for Voting');
      require(block.timestamp < Proposals[_proposalID].TimeEnd, 'Voting time elapsed');

      

      Proposals[_proposalID].ProposalVoters[msg.sender] = true;

      if (_voteType == uint8(VoteType.Against)) {
        Proposals[_proposalID].AgainstVoters.push(msg.sender);
        Proposals[_proposalID].AgainstWeight += StakedAmounts[_projectID][msg.sender];

      } else if (_voteType == uint8(VoteType.For)) {
        Proposals[_proposalID].ForVoters.push(msg.sender);
        Proposals[_proposalID].ForWeight += StakedAmounts[_projectID][msg.sender];
      } else if (_voteType == uint8(VoteType.Abstain)) {
        Proposals[_proposalID].AbstainVoters.push(msg.sender);
        Proposals[_proposalID].AbstainWeight += StakedAmounts[_projectID][msg.sender];
      } else {
          revert("invalid value for VoteType");
      }

    }

 
  fallback() external  {
  }

  
}