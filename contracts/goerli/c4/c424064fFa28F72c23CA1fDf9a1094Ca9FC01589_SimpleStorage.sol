// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// pragma solidity ^0.8.7; --> any version equal or above this (upto 0.8.x)
// pragma solidity >=0.8.7 <0.9.0; --> version greater or equal to 0.8.7 but strictly less than 0.9.0

contract SimpleStorage {
    // bool, uint(8 to 256), int(8 to 256), address, bytes(1 to 32), string

    // if no scope mentioned, it is internal..
    uint256 faviouriteNumber; // gets initialized as 0 in solidity

    People public people = People({name: "Vijit", faviouriteNumber: 23});

    struct People {
        uint256 faviouriteNumber;
        string name;
    }

    People[] public peeps;

    mapping(string => uint256) public nameToFavNum; // everything initialized to 0 initially..

    // uint256 public faviouriteNumber;

    // scopes are private, public, external, internal

    // more things you do in a funciton, more gas spent..
    function store(uint256 _favouriteNUmber) public virtual {
        faviouriteNumber = _favouriteNUmber; // gas spent -> 24K
        faviouriteNumber = faviouriteNumber + 1; // gas spent -> 43K
    }

    //  view --> just reading, pure -> not even read on blockchain (eg., util functions)
    function retrieve() public view returns (uint256) {
        return faviouriteNumber;
    }

    // function add() public pure returns(uint256) {
    //     return (1+1);
    // }

    // different types of storages in solidity --> calldata, memory, storage
    function addPeep(string memory _name, uint256 favNum) public {
        peeps.push(People(favNum, _name));
        nameToFavNum[_name] = favNum;
    }
}