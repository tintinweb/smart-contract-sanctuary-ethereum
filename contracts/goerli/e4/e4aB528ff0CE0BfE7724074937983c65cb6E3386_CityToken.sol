// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title InfinityTower
 * @dev Implements floors creation
 */
contract CityToken {

    struct Position {
        uint x;
        uint y;
        uint z;
    }

    struct Building {
        string ownerName;
        string message;
        Position position;
        uint height;
        uint color;
    }
    
    
    event NewBuilding(uint building, string ownerName, string message, Position position, uint height, uint color);

    Building[] public buildings;
    uint public nbBuildings;
 
    function createBuilding(string memory _ownerName, string memory _message, Position memory _position, uint _height, uint _color) public {
        buildings.push(Building(_ownerName, _message, _position, _height, _color));
        emit NewBuilding(nbBuildings, _ownerName, _message, _position, _height, _color);
        nbBuildings++;
    }
}