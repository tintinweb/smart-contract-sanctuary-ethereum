// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {
    string public myString;

    /**
     * @dev Stores a string in the contract state
     * @param inputString The string to store
     */
    function store_hex(string memory inputString) public {
        myString = inputString;
    }
    /**
     * @dev Returns the stored string from the contract state
     * @return The stored string
     */
    function get_hex() public view returns (string memory) {
        return myString;
    }
}