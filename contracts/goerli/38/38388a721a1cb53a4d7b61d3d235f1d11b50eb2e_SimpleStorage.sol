/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    // bool, uint256, int256, string, address, bytes32
    uint256 public favoriteNumber = 5; // public variable implicitly got a getter function

    People public person = People({favoriteNumber: 2, name: "Peter"});
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    // virtual means overridable
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // view doesn't incur transaction cost
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function add() public pure returns (uint256) {
        return 1 + 1;
    }

    // memory only exists temporarily, calldata is memory with no modification
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name)); // or can use {} format
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

// contract address: 0xd9145CCE52D386f254917e481eB44e9943F39138