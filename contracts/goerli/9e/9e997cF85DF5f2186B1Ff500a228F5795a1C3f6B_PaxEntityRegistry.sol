// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract PaxEntityRegistry {
    struct PaxEntity {
        address pk;
        string name;
        string dataURI;
    }

    PaxEntity[] entities;

    event NewEntity(uint _id);
 
    function addEntity(string memory name, string memory dataURI) public {
        emit NewEntity(entities.length);
        entities.push();
        uint _id = entities.length-1;
        entities[_id].pk = msg.sender;
        entities[_id].name = name;
        entities[_id].dataURI = dataURI;
    }
}