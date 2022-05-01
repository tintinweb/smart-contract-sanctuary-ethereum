// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MA {
    string public name = "MA";
    string public symbol = "MA";
    string public avatar = "<svg />";

    /**
     * Contract initialization.
     *
     * The `constructor` is executed only once when the contract is created.
     */
    constructor() {

    }

    /**
     * Read only function to retrieve the token balance of a given account.
     *
     * The `view` modifier indicates that it doesn't modify the contract's
     * state, which allows us to call it without executing a transaction.
     */
    function test(string calldata avatarName) external view returns (string memory) {
        return (avatarName);
    }
}