//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Worlds {
    struct Position {
        int256 x;
        int256 y;
    }

    struct Entity {
        string name;
        Position pos;
    }

    struct World {
        address owner;
        string name;
        Entity[] entities;
    }

    address owner;

    bool initialized;

    event WorldSaved(World world);

    mapping(address => World[]) public worlds;

    function initialize(address _owner) external {
        require(!initialized, "Already initialized");

        owner = _owner;

        initialized = true;
    }

    function saveWorld(World calldata world) public {
        require(msg.sender == owner, "Only the owner may create worlds");

        worlds[world.owner].push(world);
    }

    function getWorlds(address worldOwner, uint256 worldIndex) public view returns (World memory) {
        return worlds[worldOwner][worldIndex];
    }

    function getWorldCount(address worldOwner) public view returns (uint256) {
        return worlds[worldOwner].length;
    }
}