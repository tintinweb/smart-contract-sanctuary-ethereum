/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract ZombieFactory {
  event NewZombie(uint zombieId, string zombieName, uint zombieDna);

  uint dnaDigits  = 16;
  uint dnaModulus = 10 ** dnaDigits;

  struct Zombie {
    string name;
    uint dna;
  }

  Zombie[] public zombies;

  mapping (uint => address) public zombieToOwner;
  mapping (address => uint) internal ownerZombieCount;

  function _generateRandomDna(string memory _str) private view returns (uint) {
    uint rand = uint(keccak256(abi.encodePacked(_str)));
    return rand % dnaModulus;
  }

  function _createZombie(string memory _name, uint _dna) internal {
    zombies.push(Zombie(_name, _dna));
    uint id = zombies.length - 1;
    zombieToOwner[id] = msg.sender;
    ownerZombieCount[msg.sender]++;
    emit NewZombie(id, _name, _dna);
  }

  function createRandomZombie(string memory _name) public {
    require(ownerZombieCount[msg.sender] == 0, "you cannot have more than one zombie");
    uint randDna = _generateRandomDna(_name);
    _createZombie(_name, randDna);
  }
}