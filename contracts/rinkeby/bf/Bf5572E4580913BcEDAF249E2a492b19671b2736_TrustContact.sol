/* SPDX-License-Identifier: MIT */

pragma solidity >= 0.5.12;


contract TrustContact {

  mapping( string => string )  urlNames; 
  address owner;

  constructor() public{
      owner = 0x5e0EEC22d8015f94e62eAf6B7078be3e1281681C;
  }

  modifier _ownerOnly(){
      require(msg.sender == owner, "bad_actor");
      _;
  }
  
  function insertName(string memory did, string memory name) public _ownerOnly {
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