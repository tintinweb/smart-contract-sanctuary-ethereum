/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

// Contract Factory is needed to deploy other contracts using create2 opcode
contract ContractFactory {
    event ContractDeployed(address addr, uint256 salt);

    function deploy(bytes memory code, uint256 salt) public {
        address addr;
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit ContractDeployed(addr, salt);
    }
}