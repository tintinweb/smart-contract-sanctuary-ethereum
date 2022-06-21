// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

interface IOwnable {
    function transferOwnership(address) external;
}

contract Deployer {
    event ContractCreation(address newContract);

    function performCreate2(
        uint256 value,
        bytes memory deploymentData,
        bytes32 salt,
        address owner
    ) public returns (address newContract) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newContract := create2(value, add(0x20, deploymentData), mload(deploymentData), salt)
        }
        require(newContract != address(0), "Could not deploy contract");

        if (owner != address(0)) IOwnable(newContract).transferOwnership(owner);

        emit ContractCreation(newContract);
    }

    function performCreate(uint256 value, bytes memory deploymentData, address owner) public returns (address newContract) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newContract := create(value, add(deploymentData, 0x20), mload(deploymentData))
        }
        require(newContract != address(0), "Could not deploy contract");
        emit ContractCreation(newContract);

        if (owner != address(0)) IOwnable(newContract).transferOwnership(owner);
    }
}