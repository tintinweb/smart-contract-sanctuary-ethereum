//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ZombieFactoryByElorri {

    uint id = 0;

    struct zombie {
        string name;
        string color;
    }

    zombie[] zombieList;
    mapping(uint => zombie) idToZombie;
    mapping(uint => address) idToOwner;
    mapping(address => uint) ownerToZombieCount;

    function createZombie(string memory _name, string memory _color) public {
        zombieList.push(zombie(_name, _color));
        id++;
        idToZombie[id] = zombieList[id -1];
        idToOwner[id] = msg.sender;
        ownerToZombieCount[msg.sender] = id;
    }

    function whoIsTheOwner(uint _id) public view returns (address){
        return idToOwner[_id];
    }

    function totalZombies() public view returns (uint) {
        return zombieList.length;
    }

    function howManyZombiesHeHave(address _who) public view returns (uint) {
        return ownerToZombieCount[_who];
    }

}