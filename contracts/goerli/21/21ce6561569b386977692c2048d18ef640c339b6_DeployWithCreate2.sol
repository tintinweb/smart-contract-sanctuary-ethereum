/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
//Use Create2 to know contract address before it is deployed.
contract DeployWithCreate2 {
    address public owner;
    constructor(address _owner) {
        owner = _owner;
    }
}