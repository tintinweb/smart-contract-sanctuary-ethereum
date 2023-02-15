pragma solidity ^0.8.12;
// SPDX-License-Identifier: MIT

contract SimpleStorage {

    uint256 private favoriteNumber;

    function setFavoriteNumber(uint256 _favNumber) public {
        favoriteNumber = _favNumber;
    }

    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

}

pragma solidity ^0.8.12;
// SPDX-License-Identifier: MIT

import "./SimpleStorage.sol";

contract StorageFactory {

    SimpleStorage[] public ssStorage;

    function createStorage() public {
        SimpleStorage ss = new SimpleStorage();
        ssStorage.push(ss);
    }

    function setFavoriteNumber(uint256 index, uint256 _favNumber) public {
        ssStorage[index].setFavoriteNumber(_favNumber);
    }

    function getNumber(uint256 index) public view returns(uint256) {
        return ssStorage[index].retrieve();
    }

}