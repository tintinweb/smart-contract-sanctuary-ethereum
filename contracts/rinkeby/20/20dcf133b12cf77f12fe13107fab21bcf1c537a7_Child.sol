/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    Child public child;

    constructor(uint i) {
        child = new Child(i);
    }
}

contract Child {

    uint public a;

    constructor(uint _a) {
        a = _a;
    }
}