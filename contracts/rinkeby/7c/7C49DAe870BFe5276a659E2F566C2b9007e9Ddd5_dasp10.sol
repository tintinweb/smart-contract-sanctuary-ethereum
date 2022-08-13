/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract dasp10 {
    string private name = "taylor.schmidt";

    function updateName(string memory _newName) public {
        name = _newName;
    }

}