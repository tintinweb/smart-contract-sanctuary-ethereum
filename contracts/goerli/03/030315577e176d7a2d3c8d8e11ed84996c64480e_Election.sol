/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// File: Election_flat.sol


// File: Election.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;
 contract Election{
     struct Party{
         string name;
         uint id;
         uint voteCount;
     }
     mapping(uint=> Party) public parties;
     mapping(address=> bool) public voters;
     
     uint public partycount;
    constructor()  {
            addParty('NDA');
            addParty('UPA');
            addParty('other');
     }
    function addParty(string memory _name) private{
        partycount++;
        parties[partycount]=Party(_name,partycount,0);
    }
    
    function vote(uint id,address add) public{
          require(!voters[add]);

        voters[add]=true;
            parties[id].voteCount++;
            voters[add]==true;
        
        
    }
 }