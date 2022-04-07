/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
contract BoxV3 {
    uint256 private value;

    struct Hero{
        uint8 gender;
        uint8 role;
        bytes32 name;
        uint32 level; //  add v2 new line
        uint64 birthday; // add v2 new line
        string url; // add v3 new line
    }

    mapping(uint256=>Hero) private _users;
 
    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);
 
    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }
 
    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }

    // Increments the stored value by 1
    function increment() public {
        value = value + 1;
        emit ValueChanged(value);
    }

    function add(uint256 id,uint8 gender,uint8 role,bytes32 name,uint32 level,uint64 birthday,string memory url) public {
        Hero memory hero;
        hero.gender = gender;
        hero.role = role;
        hero.name = name;
        hero.level = level;
        hero.birthday = birthday;
        hero.url = string(abi.encodePacked("ipfs://url",url));
        _users[id] = hero;
    }


    function get(uint256 id) public view returns (Hero memory hero) {
        return _users[id];
    }

}