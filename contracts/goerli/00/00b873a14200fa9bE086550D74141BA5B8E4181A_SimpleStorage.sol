/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct Human {
        uint256 favoriteNumber;
        string name;
    }

    Human[] public humans;

    mapping(string => uint256) public humanToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addHuman(string memory _name, uint256 _favoriteNumber) public {
        humans.push(Human(_favoriteNumber, _name));
        humanToFavoriteNumber[_name] = _favoriteNumber;
    }
}