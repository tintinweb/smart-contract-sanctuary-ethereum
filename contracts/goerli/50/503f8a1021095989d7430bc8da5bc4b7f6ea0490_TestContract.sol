/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

pragma solidity ^0.4.0;
contract TestContract{
    //Deij Pokotea 21302141
    struct Proposal {
        uint voteCount;
        string description;
    }

    address public owner;
    Proposal[] public proposals;

    function TestContract(){
        owner = msg.sender;
    }

    function createProposal(string description){
        Proposal memory p;
        p.description = description;
        proposals.push(p);
    }

    function vote(uint proposal){
        proposals[proposal].voteCount += 1;
    }
}