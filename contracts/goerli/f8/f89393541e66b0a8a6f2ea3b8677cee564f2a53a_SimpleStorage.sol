/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favouriteNumber;

    struct People {
        string name;
        uint256 favouriteNumber;
    }

    People[] public people;
    mapping(string => uint256) public nameToFavouriteNumber;

    function store(uint256 _favNumber) public {
        favouriteNumber = _favNumber;
    }

    function retrive() public view returns (uint256) {
        uint256 tmp = 9;
        tmp = favouriteNumber;
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favNum) public {
        people.push(People(_name, _favNum));
        nameToFavouriteNumber[_name] = _favNum;
    }
}

// yarn solcjs --bin --abi --include-path node_modules/ --base-path . -o . .\SimpleStorage.sol