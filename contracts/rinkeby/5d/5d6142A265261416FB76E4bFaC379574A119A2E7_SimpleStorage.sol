/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract SimpleStorage {
    //THis get initialised to zero!
    // <- This means that this section is a comment!
    uint256 favouriteNumber;
    //People public person = People({favouriteNumber: 2, name: "Niroo"});

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    mapping(string => uint256) public nameToFavouirteNumber;

    //uint256[] public favouriteNumber;
    People[] public people;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouirteNumber[_name] = _favouriteNumber;
    }
}

//0xd9145CCE52D386f254917e481eB44e9943F39138