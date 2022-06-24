// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

interface IVester {
    function rely(address _usr) external;
    function deny(address _usr) external;
}

contract VesterDeployer {
    address constant admo = 0x6ABfd6139c7C3CC270ee2Ce132E309F59cAaF6a2;

    event ContractCreation(address newContract);

    function performCreate2(
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

        IVester(newContract).rely(admo);
        IVester(newContract).deny(address(this));
    }
}