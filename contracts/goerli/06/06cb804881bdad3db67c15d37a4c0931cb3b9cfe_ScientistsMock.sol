// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract ScientistsMock {
    address[] public owners;

    constructor() {}

    function addOwner(address owner) external {
        owners.push(owner);
    }

    function getRandomPaidScientistOwner(uint256 randomness) external view returns (address) {
        return owners[randomness % owners.length];
    }

    function increasePool(uint256) external {}
}