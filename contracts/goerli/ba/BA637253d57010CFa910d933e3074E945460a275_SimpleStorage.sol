// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract SimpleStorage {

    struct Zombie {
        uint id;
        string name;
    }

    function totalZombies() public view returns (uint) {
        return zombie_list.length;
    }


    Zombie[] public zombie_list;

    function addZombie(uint _id, string memory _name) public {
        zombie_list.push(Zombie(_id, _name));
    }
}