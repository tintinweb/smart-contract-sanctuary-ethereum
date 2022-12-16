/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// EVM
// AValance, polygon, fantom are evm compitable network
contract SimpleStorage {
    // boolean, unint, int, address, bytes

    // Initial assigns to zero
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure means only read function so doesn not consume gas as it could not update anything
    function retrive() public view returns (uint256) {
        return favoriteNumber;
    }

    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory person = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(person);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
} // 0xd9145CCE52D386f254917e481eB44e9943F39138