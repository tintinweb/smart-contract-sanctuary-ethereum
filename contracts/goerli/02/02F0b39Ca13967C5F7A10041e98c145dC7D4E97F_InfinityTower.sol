// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title InfinityTower
 * @dev Implements floors creation
 */
contract InfinityTower {

    struct Floor {
        string ownerName;
        string message;
        string link;
        uint color;
        uint windowsTint;
    }
    
    
    event NewFloor(uint floor, string ownerName, string message, string link, uint color, uint windowsTint);

    Floor[] public floors;
    uint public nbFloors;
 
    function createFloor(string memory _ownerName, string memory _message, string memory _link, uint _color, uint _windowTint) public {
        floors.push(Floor(_ownerName, _message, _link, _color, _windowTint));
        emit NewFloor(nbFloors, _ownerName, _message, _link, _color, _windowTint);
        nbFloors++;
    }
}