/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Voting {

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    mapping(uint => Candidate) public candidates;
    address[] private voters;

    uint public candidatesCount;

    function addCandidate (string memory _name) public {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function voteCandidate (uint id) public{
        bool ok = true;
        for (uint i=0; i<voters.length; i++) {
            if (msg.sender == voters[i]){
                ok = false;
            }
        }
        require(ok, "You have already voted");
        candidates[id].voteCount += 1;
        voters.push(msg.sender);
    }

}