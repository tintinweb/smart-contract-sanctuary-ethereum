// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    uint public number;
    address public addr2;
    address public networkGovernor = 0xD6976f891Ccf48E9c1D16885780840A2C8e515fa;

    modifier onlyGovernor {
        require(msg.sender == networkGovernor, "g");
        _;
    }
}