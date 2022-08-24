/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

pragma solidity ^0.4.0;
contract TestContract {
//Nevil
    struct Proposal {
        uint voteCount;
        string description;
    }

    address public owner;
    Proposal[] public proposals;

    function TestContract() {
        owner = msg.sender;
    }

    function createProposal(string description) {
        Proposal memory p;
        p.description = description;
        proposals.push(p);
    }

    function vote(uint proposal) {
        proposals[proposal].voteCount += 1;
    }
}