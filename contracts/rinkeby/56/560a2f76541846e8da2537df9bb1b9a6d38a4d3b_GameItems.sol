/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// contracts/GameItems.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.9.0;
pragma experimental ABIEncoderV2;
contract GameItems {
  struct People{
    uint id;
    string name;
  }
  mapping (uint => People) public peoples;
  event votedEvent(uint indexed _candidateId);
  uint public candidateConut;

  constructor() public {
    candidateConut = 0;
  }
  function addCandidate(string memory _name) public {
    peoples[candidateConut] = People(candidateConut,_name);
    candidateConut++;
  }
  //return Single structure
  function get(uint _candidateId) public view returns(People memory) {
    return peoples[_candidateId];
  }
  //return Array of structure Value
  function getPeople() public view returns (uint[] memory, string[] memory){
      uint[]    memory id = new uint[](candidateConut);
      string[]  memory name = new string[](candidateConut);
      for (uint i = 0; i < candidateConut; i++) {
          People storage people = peoples[i];
          id[i] = people.id;
          name[i] = people.name;
      }

      return (id, name);

  }
  //return Array of structure
  function getPeoples() public view returns (People[] memory){
      People[]    memory id = new People[](candidateConut);
      for (uint i = 0; i < candidateConut; i++) {
          People storage people = peoples[i];
          id[i] = people;
      }
      return id;
  }
}