// SPDX-License-Identifier: MIT
pragma solidity 0.8.8; //0.8.12s

contract SimpleStorage {
    // This get initialized to zero
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

    // we only spend gas if we cange the blockchain
    // wen using view it does not spend gas as we are only reading from thhe blockchain
    function retrive() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata, memory, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}