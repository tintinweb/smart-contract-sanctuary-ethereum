/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;



// File: Item.sol

// The Item contract represents a raw material in the simulation.
contract Item {
    string public name;
    uint256 public quantity;

    constructor(string memory _name, uint256 _quantity) public {
        name = _name;
        quantity = _quantity;
    }

    // The add function allows more of the item to be
    // added to the supply.
    function add(uint256 amount) public {
        quantity += amount;
    }

    // The remove function allows some of the item to
    // be removed from the supply, given that there is enough.
    function remove(uint256 amount) public {
        require(quantity >= amount, "Not enough items");
        quantity -= amount;
    }
}