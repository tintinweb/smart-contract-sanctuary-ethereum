/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

pragma solidity ^0.4.2;

contract Election {
    string public candidateName;

    function Election () public {
        candidateName = "Candidate 1";
    }

    function setCandidate (string _name) public {
        candidateName = _name;
    }
}