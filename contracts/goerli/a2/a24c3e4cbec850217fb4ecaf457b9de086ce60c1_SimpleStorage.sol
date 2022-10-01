/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract SimpleStorage {
    uint256 favoriteNumber;
    mapping(string => uint256) public nameToFavorite;
    
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function addPerson(string calldata _name, uint256 _favNum) public {
        People memory person = People({favoriteNumber: _favNum, name: _name});
        people.push(person);
        nameToFavorite[_name] = _favNum;
    }

    function store(uint256 _favNum) public {
        favoriteNumber = _favNum;
        favoriteNumber = favoriteNumber + 1;
    }

    function retireve() public view returns(uint256) {
        return favoriteNumber + retirevePure();
    }

    function retirevePure() public pure returns(uint256) {
        return 1 + 22;
    }

}

// 0xd9145CCE52D386f254917e481eB44e9943F39138