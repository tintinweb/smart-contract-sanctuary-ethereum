/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Sorular
// 1-Memory koyunca ne oluyor.

contract SimpleStorage {
    uint256 favNumb;
    uint256 testVal;

    mapping(string => uint256) public nameToFavNum;

    struct People {
        uint256 favNumb;
        string name;
    }

    // uint256[] public favNumList;
    People[] public people;

    function store(uint256 _favNumb) public virtual {
        favNumb = _favNumb;
        testVal = 5;
        retrieve();
    }

    function something() public {
        testVal = 6;
    }

    function retrieve() public view returns (uint256) {
        return favNumb;
    }

    function addPerson(string memory _name, uint256 _favNumb) public {
        People memory newPerson = People(_favNumb, _name); //People({favNumb: _favNumb, name: _name});
        //people.push(People(_favNumb,_name));
        people.push(newPerson);
        nameToFavNum[_name] = _favNumb;
    }
}