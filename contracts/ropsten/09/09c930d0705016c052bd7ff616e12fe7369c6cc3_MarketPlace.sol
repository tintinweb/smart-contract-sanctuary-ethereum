/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract MarketPlace {
    struct Character {
        string name;
        string desc;
    }
    Character[] public characters;

    function setAthings(string memory _name, string memory _desc) public {
        characters.push(Character(_name, _desc));
        characters.push(Character({name: _name, desc: _desc}));

        Character memory character;
        character.desc = _desc;
        character.name = _name;
        characters.push(character);
    }

    function getAthings(uint256 _index)
        public
        view
        returns (string memory name, string memory desc)
    {
        Character storage character = characters[_index];
        return (character.name, character.desc);
    }
}