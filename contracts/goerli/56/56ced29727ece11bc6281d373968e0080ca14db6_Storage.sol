// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {
    bytes32 public variable;

    constructor() {}

    function set(uint256 input) public {
        // variableA = sha256(abi.encodePacked(input));
        // sha256(abi.encodePacked(input));
        // assembly {
        //     let res := call(gas(), 0x02, 0, 0, 32, 0, 32)
        // }
        // uint256 b = 123;
        // variable = bytes32(abi.encodePacked(b));
        variable = bytes32(input);
    }
}