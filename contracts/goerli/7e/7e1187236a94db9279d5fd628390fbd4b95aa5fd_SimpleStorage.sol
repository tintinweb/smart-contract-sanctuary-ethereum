//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    uint256 public favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    /* Function to Store new number */
    function store(uint256 numberFavorite) public virtual {
        favoriteNumber = numberFavorite;
    }

    /* Function to retrieve stored Number */
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
    /* Function to add FavoriteNumber and name to hashMap and array */
    function add(string memory name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, name));
        nameToFavoriteNumber[name] = _favoriteNumber;
    }
}