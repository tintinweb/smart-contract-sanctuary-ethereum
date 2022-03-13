/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract Storage {
  mapping(uint=>string) private apeTraits;
  mapping(string=>bool) private apeExist;

   function checkApeExist(string memory traits) public view returns (bool exist){
        return apeExist[traits];
    }

     function currentTraits(uint tokenId) public view returns (string memory traits){
        return apeTraits[tokenId];
    }

      function setTraits(uint tokenId,string memory traits) public  returns (bool exist) {
       string memory temp=apeTraits[tokenId];
        if(!apeExist[traits]){
          apeTraits[tokenId]=traits;
          apeExist[traits]=true;
          apeExist[temp]=false;
          return true;
        }
    }

    constructor(){
   
    }

    function pupulate(uint start,string[] memory traits) public {
            for (uint256 i; i < traits.length; i++) {
              apeTraits[i+start]=traits[i];
              apeExist[traits[i]]=true;
        }
    }
}