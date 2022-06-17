// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


contract ContractFactory {
    event ContractCreation(address newContract);

    function performCreate2(
        uint256 value,
        bytes memory deploymentData,
        bytes32 salt
    ) public returns (address newContract) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newContract := create2(
                value,
                add(0x20, deploymentData),
                mload(deploymentData),
                salt
            )
        }
        require(newContract != address(0), "Could not deploy contract");
        emit ContractCreation(newContract);
    }

    function performCreate(uint256 value, bytes memory deploymentData)
        public
        returns (address newContract)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newContract := create(
                value,
                add(deploymentData, 0x20),
                mload(deploymentData)
            )
        }
        require(newContract != address(0), "Could not deploy contract");
        emit ContractCreation(newContract);
    }
}