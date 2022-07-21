/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.22;

contract nameVoter {
    mapping (address => bool) postulationState;
    mapping (address => bool) votingState;
    uint proposal_count_i;
    uint proposal_count_im1;
    mapping(string => bool) nameState;
    mapping(string => bool) ownerNameState;

    struct proposal{
        string proposal_name;
        string owner_name;
        uint voteCount;
        address owner;
    }
    
    proposal[] public proposals;
    

    function postulate(string _newProposal, string _owner_name) public {
        require(!postulationState[msg.sender],"Only one proposal per address");
        require(!nameState[_newProposal],"Name already proposed");
        require(!ownerNameState[_owner_name],"Owner name already proposed");
        proposals.push(proposal(_newProposal,_owner_name,0,msg.sender));
        postulationState[msg.sender]=true;
        nameState[_newProposal]=true;
        ownerNameState[_newProposal]=true;
    }
    function vote(uint _proposal) public {
        require(!votingState[msg.sender],"");
        require(proposals.length>=_proposal,"ID for proposal not created");
        require(msg.sender!=proposals[_proposal].owner,"Cant vote for your proposal");
        proposals[_proposal].voteCount++;
        votingState[msg.sender]=true;
    }


        function winningProposal() public view
            returns (uint winningProposal_, string proposalName)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
        proposalName=proposals[winningProposal_].proposal_name;
    }

}