/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// Sources flattened with hardhat v2.12.6 https://hardhat.org

// File contracts/Communication.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface iAU {
    function attempt() external;
}

contract Communication {
    address AUaddress = 0xcF469d3BEB3Fc24cEe979eFf83BE33ed50988502;

    function method1() external {
        iAU(AUaddress).attempt();
    }

    function method2() external {
        (bool success, ) = AUaddress.call(abi.encodeWithSignature("attempt()"));
        require(success);
    }
}