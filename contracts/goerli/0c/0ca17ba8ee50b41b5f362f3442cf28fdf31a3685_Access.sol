/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

pragma solidity ^0.6.1;

contract Access {
  address creator;
  
  // Storing the address associated with the image CID and hash

  mapping(address => mapping(string => mapping(string => bool))) roles;
  mapping(address => mapping(string => bool)) roles2;

   constructor() public{
    creator = msg.sender;
  }
  
  function adminRole (address adminstrator, string memory role) public hasRole('superadmin') {
    roles2[adminstrator][role] = true;
  }
  
  // function to assign cid and hash to address

   function assignAccess (address entity, string memory cid, string memory hash) public {
    roles[entity][cid][hash]= true;
  }

  // function to unassign cid and hash from address

  function unassignAccess (address entity, string memory cid, string memory hash) public {
    roles[entity][cid][hash] = false;
  }

  // function to show who check assigned access 

  function isAssignedAcccess (address entity, string memory cid, string memory hash) public view returns (bool) {
    return roles[entity][cid][hash];
  }

  
  modifier hasRole (string memory role) {
    require(!roles2[msg.sender][role] && msg.sender != creator);
    _;
  }
}