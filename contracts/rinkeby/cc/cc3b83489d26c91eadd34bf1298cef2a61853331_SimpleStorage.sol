/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7; // fix the solidity version (any minor version above 8)

contract SimpleStorage {
    // initially 0
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

    // view, pure (does not cost gas because we just read from the blockchain)
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // TODO: Question: Why did you choose memory here for the _name argument? It's not being modified... I chose calldata.
    function addPerson(string calldata _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson);

        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}