/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

pragma solidity ^0.4.0;
contract TestContract {

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

/*    function voteAddresses(uint proposal) {
        return proposals[proposal] + address[owner];
    }
*/
}