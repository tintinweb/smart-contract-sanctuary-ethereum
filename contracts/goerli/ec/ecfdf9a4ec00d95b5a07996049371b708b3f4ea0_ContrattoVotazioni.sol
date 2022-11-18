/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract ContrattoVotazioni {
    bytes32[] private candidati;

    function getCandidates() public view returns (bytes32[] memory) {
        return candidati;
    }

    function addCandidate(bytes32 nomeCognome) public {
       candidati.push(nomeCognome);
    }
    
}