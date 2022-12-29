/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 public favouriteNumber;

    struct people {
        uint256 favouriteNumber;
        string name;
    }

    people[] public persons;

    people public person = people({favouriteNumber: 2, name: "Rock"});
    people public person2 = people({favouriteNumber: 4, name: "Lika"});

    function store(uint256 receivedNo) public virtual {
        favouriteNumber = receivedNo;
        retrieve();
    }

    mapping(string => uint256) public nameToFavoriteNo;

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    function addPerson(string memory _name, uint256 _favNo) public {
        people memory newPerson = people({
            name: _name,
            favouriteNumber: _favNo
        });
        nameToFavoriteNo[_name] = _favNo;
        persons.push(newPerson);
    }
}