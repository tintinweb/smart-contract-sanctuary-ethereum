/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// EVM Compatible Blockchains: Avalance, Fantom, Polygon (Solidity can be deployed here)

contract SimpleStorage {
    // bool, string, bytes
    uint256 favouriteNumnber;

    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favouriteNumnber;
        string name;
    }

    //uint256[] public favouriteNumnberList;
    People[] public people;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumnber = _favouriteNumber;
    }

    // view reass state, dont use gas
    function retrieve() public view returns (uint256) {
        return favouriteNumnber;
    }

    // pure cant read state, and doesnt use gas
    function add() public pure returns (int) {
        return (1 + 1);
    }

    // calldata = temp var that cannot be modified
    // memory   = temp var that can be modified
    // storage  = permanent var that can be modified
    // structs, mappings and arrays need to specify the location when passing to functions.But an int does not
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}