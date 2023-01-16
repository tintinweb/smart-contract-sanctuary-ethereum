/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Handbag Design
 * @dev Implements Handbag creation
 */
contract Handbagdesign {

    struct Handbag {
        string ownerName;
        string message;
        string link;
        uint color;
        uint tint;
    }

   event NewHandbag(uint floor, string ownerName, string message, string link, uint color, uint tint);
    
   Handbag[] public handbags;
   uint public nbHandbags;

   function createHandbag(string memory _ownerName, string memory _message, string memory _link, uint _color, uint _tint ) public {
       // push into the handbags arr a new one
       handbags.push(Handbag(_ownerName, _message, _link, _color, _tint));
       emit NewHandbag(nbHandbags,_ownerName, _message, _link, _color, _tint );
       nbHandbags++;
   }
}