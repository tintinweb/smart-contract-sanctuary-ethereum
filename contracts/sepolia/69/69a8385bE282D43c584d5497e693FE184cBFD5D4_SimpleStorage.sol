// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.10;

contract SimpleStorage {
    address private immutable owner;

    constructor() {
        owner = msg.sender;
    }

    uint256 favorite;

    function addFavorite(uint256 fav) public {
        favorite = fav;
    }

    function getFavorite() public view returns (uint256) {
        return favorite;
    }
}