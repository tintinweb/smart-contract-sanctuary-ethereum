// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

interface IOwnable {
    function transferOwnership(address) external;
}

/// @title Create Call - Allows to use the different create opcodes to deploy a contract
/// @author Richard Meissner - <[email protected]>
contract CreateCallModified {
    event ContractCreation(address newContract);

    function performCreate2OnProxyAdmin(
        uint256 value,
        bytes memory deploymentData,
        bytes32 salt
    ) public returns (address newContract) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newContract := create2(value, add(0x20, deploymentData), mload(deploymentData), salt)
        }
        require(newContract != address(0), "Could not deploy contract");
        emit ContractCreation(newContract);

        IOwnable(newContract).transferOwnership(0x936D96e782A3F8001c6e63557318aff1f6a9035D);
    }

    function performCreate(uint256 value, bytes memory deploymentData) public returns (address newContract) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newContract := create(value, add(deploymentData, 0x20), mload(deploymentData))
        }
        require(newContract != address(0), "Could not deploy contract");
        emit ContractCreation(newContract);
    }
}