/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

pragma solidity ^0.4.11;

contract RoleBasedAcl {
  address creator;
  
  //mapping(address => mapping(string => mapping(string => bool))) roles;
  mapping(address => mapping(string => bool)) roles;
  mapping(address => mapping(string => bool)) roles2;

  function RoleBasedAcl () {
    creator = msg.sender;
  }
  
  function adminRole (address entity, string role) hasRole('superadmin') {
    roles2[entity][role] = true;
  }
  
  function assignRole (address entity, string topic) hasRole('superadmin') {
    roles[entity][topic] = true;
  }

  
  function unassignRole (address entity, string topic) hasRole('superadmin') {
    roles[entity][topic] = false;
  }

  
  function isAssignedRole (address entity, string topic) returns (bool) {
    return roles[entity][topic];
  }

  
  modifier hasRole (string role) {
    if (!roles2[msg.sender][role] && msg.sender != creator) {
      throw;
    }
    _;
  }
}