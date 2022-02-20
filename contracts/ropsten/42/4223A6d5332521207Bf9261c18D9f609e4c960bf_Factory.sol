/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.7;

/// @title Deploy a contract to a specific address
/// @author kyrers
/// @notice You can use this contract to deploy a contract at a specific address by passing it the correct salt
/// @dev These could be modified to be contract independent
contract Factory {
    event Deployed(address addr, uint256 salt);
    
    /// @notice Deploy a contract using CREATE2
    /// @param contractBytecode The bytecode of the contract to be deployed
    /// @param salt The value needed to deploy the contract with the specified bytecode to the address you want
    function deploy(bytes memory contractBytecode, uint256 salt) public  {
        address addr;

        assembly {
            addr := create2(0, add(contractBytecode, 0x20), mload(contractBytecode), salt)

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(addr, salt);
    }
}