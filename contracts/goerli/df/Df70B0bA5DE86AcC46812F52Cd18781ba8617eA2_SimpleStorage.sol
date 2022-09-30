/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleStorage {
    // This gets initialized to zero!
    uint256 favouriteNumber;

    mapping(string => uint256) public nameToFavouriteNumber;

    // Instantiaing the object
    // People public person = People({favouriteNumber: 5, name: "Nischal"});

    // struct
    struct People {
        uint256 favouriteNumber;
        string name;
    }

    // Arrays
    People[] public people;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    // view
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    // public function
    // function add() public pure returns(uint256) {
    //     return 1+1;
    // }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138