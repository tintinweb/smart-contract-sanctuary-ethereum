pragma solidity >=0.5.0 <0.6.0;

import "./zombiefactory.sol";


contract ZombieFeeding is ZombieFactory {

  function zombieFood(uint _blockNumber) public view returns (uint256) {
    uint256 randomN = uint256(blockhash(_blockNumber));
    return randomN;
  }


  function feedAndMultiply(uint _zombieId, uint _targetDna, string memory _species) public {
    require(msg.sender == zombieToOwner[_zombieId]);
    Zombie storage myZombie = zombies[_zombieId];
    _targetDna = _targetDna % dnaModulus;
    uint newDna = (myZombie.dna + _targetDna) / 2;
    if (keccak256(abi.encodePacked(_species)) == keccak256(abi.encodePacked("blockmeat"))) {
      newDna = newDna - newDna % 100 + 99;
    }
    _createZombie("NoName", newDna);
  }

  function feedOnFood(uint _zombieId, uint _BlockNumber) public {
    uint256 Food = zombieFood(_BlockNumber);
    feedAndMultiply(_zombieId, Food, "blockmeat");
  }

}