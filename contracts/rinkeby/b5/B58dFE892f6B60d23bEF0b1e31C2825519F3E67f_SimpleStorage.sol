/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //hello solidity this is okhamena azeez

contract SimpleStorage {
    uint256 favoriteNumber;

    mapping(string => uint256) public favoritePie;

    //   this is how to write a struct
    // People public person=People({number:2,name:"kenny"});

    struct People {
        uint256 number;
        string name;
    }

    struct Kenny {
        uint256 len;
        string azeez;
    }

    Kenny[] public Lenny;

    People[] public person;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        person.push(People(_favoriteNumber, _name));
        favoritePie[_name] = _favoriteNumber;
    }

    function addKenny(string memory _name, uint256 _number) public {
        Lenny.push(Kenny(_number, _name));
    }
}

//0xd9145CCE52D386f254917e481eB44e9943F39138