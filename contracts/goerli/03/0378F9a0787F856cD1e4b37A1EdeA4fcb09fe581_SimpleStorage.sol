/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    // by default it get initialized to zero
    // uint256  favouriteNumber;

    uint256 public favouriteNumber;

    function storeFavouriteNumber(uint256 _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
        favouriteNumber = favouriteNumber + 5;
    }

    // view functions doesn't require any gas fees
    function getFavouriteNumber() public view returns(uint256) {
        return favouriteNumber;
    }


    // pure function doesn't require any gas fee until we don't call it any inside any state update function
    function calculateTwoNumbers(uint256) public pure returns(uint256) {
        return (1 + 1);
    }
}