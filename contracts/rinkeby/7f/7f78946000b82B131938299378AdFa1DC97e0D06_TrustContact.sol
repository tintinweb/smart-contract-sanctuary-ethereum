/* SPDX-License-Identifier: MIT */

pragma solidity >= 0.5.12;


contract TrustContact {

  mapping( string => string )  urlNames; 

  
  function insertName(string memory did, string memory name) public {
      urlNames[did]=name;
  }

  function FindNameByDID(string memory DID) public view returns(string memory) {
      bytes memory result = bytes(urlNames[DID]);
      if (result.length == 0 ) {
        return "notFound";
      }
      return urlNames[DID];
    }
  }