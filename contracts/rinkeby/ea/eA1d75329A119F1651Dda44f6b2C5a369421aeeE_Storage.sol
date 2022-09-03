/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {
     uint private numVot;
     mapping (uint => Alegator) private Alegatori;
     struct Alegator {
        uint id;
        bool status;
        string name;
        string vote;
    }
    event VotAdded (uint voteId, string name, string vote);

    
     constructor() {
       addPreDefinedVotes();
    }

    function addPreDefinedVotes() private {
        insertVot("WEVERTON", "Trump");
        insertVot("FELIPE MELO", "Obam1");
        insertVot("GUSTAVO GOMEZ","obama");
    }

      function addVot(string memory name, string memory vote) public returns (uint) {
        require(bytes(name).length > 0, "The argument 'name' cannot be empty");

        uint id = insertVot(name,vote);

        emit VotAdded(id, name, vote);
        return id;
    }
      function insertVot(string memory name, string memory vote) private returns (uint) {
        uint id = ++numVot;
        Alegatori[id] = Alegator(id, true, name, vote);
        return id;
    }
     function getVote(uint id) public view returns (uint, string memory, string memory) {
        require(Alegatori[id].status, "Player with the informed id doesn't exist");
        Alegator storage alegator = Alegatori[id];
        return (alegator.id, alegator.name, alegator.vote);
    }

}