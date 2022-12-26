/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// File: contracts/Eyesil.sol



pragma solidity >=0.7.0 <0.9.0;

contract Eyesil_Work {

    address owner;

    constructor(){
        owner=msg.sender;
    }

    struct Person
    {
        string ID;
        string PhotoHash;

    }

    Person[] public persons;

    function addPerson(string memory pID, string memory pPhotoHash) public
    {
        persons.push(Person(pID,pPhotoHash));
        
    }

    function getPhotoHash(string memory pID) public view returns(string memory)
    {
          for(uint i=0; i<persons.length; i++)
          {
              
              if(keccak256(abi.encodePacked(persons[i].ID)) == keccak256(abi.encodePacked(pID)))
              {
                  return persons[i].PhotoHash;
              }
          }
          return "nothing";
    }

}