/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //version

contract SimpleStorage {
    //bolean, uint +number, int -number, address, bytes are our data types
    //this will be initialized to zero!
    uint256 favNumber; //jestliže nastavíme proměnou na public tak se automaticky vytvoří getter fucntion
    uint256 testVar = 5;

    mapping(string => uint256) public nameToFavNumber;

    struct People {
        uint256 favNumber;
        string name;
    }

    People[] public people; //uint256[] public favNumbers;

    function store(uint256 _favNumber) public virtual {
        favNumber = _favNumber;
    }

    function retrieve() public view returns (uint256) {
        return favNumber;
    }

    function addPerson(string memory _name, uint256 _favNumber) public {
        //People memory newPerson = People(_favNumber,_name);
        people.push(People(_favNumber, _name));
        nameToFavNumber[_name] = _favNumber;
    }
}
//0xd9145CCE52D386f254917e481eB44e9943F39138