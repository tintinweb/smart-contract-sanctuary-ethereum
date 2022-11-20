/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;

    People[] public people;
    mapping(string => uint256) public namesToFavoriteNumber;
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata, memory, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        namesToFavoriteNumber[_name] = _favoriteNumber;
    }
}