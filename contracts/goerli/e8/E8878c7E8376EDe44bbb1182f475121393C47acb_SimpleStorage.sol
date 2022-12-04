/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favouriteNumber;

    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    // uint256[] public favouriteNumbersList;
    People[] public people;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    // view, pure (no gas needed as only reading)
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    // Structs, Mappings & Arrays need to be given memory/calldata keyword

    // calldata -> temp variables that CANT be modified
    // memory -> temp variables that CAN be modified
    // storage -> perm variables that CAN be modified

    // calldata, memory, storage
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}