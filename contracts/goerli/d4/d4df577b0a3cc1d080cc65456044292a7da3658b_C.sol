/**
 *Submitted for verification at Etherscan.io on 2022-09-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;



contract C {

    
    
    


    struct Proposal {
        uint number;
        bytes32 callbytes;
    }

    Proposal[] public proposals;

    function createProposal(Proposal memory _proposal) external returns(Proposal memory){
        proposals.push(_proposal);
        return _proposal;

    }

    function proposal_index(uint index) public view returns(Proposal memory){
        return proposals[index];
    }
    
}