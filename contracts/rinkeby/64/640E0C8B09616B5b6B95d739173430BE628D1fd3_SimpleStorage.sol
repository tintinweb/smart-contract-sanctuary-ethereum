// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9; // compiler version

// can use ^0.8.7 or >= ver <

contract SimpleStorage {
    // simple first test contract!

    uint256 favNumber = 100;

    function setFavNumber(uint256 num) public virtual {
        favNumber = num;
    }

    function retrieve() public view returns (uint256) {
        return favNumber;
    }
}