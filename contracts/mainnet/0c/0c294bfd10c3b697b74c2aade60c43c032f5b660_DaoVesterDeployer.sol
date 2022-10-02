// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.16;

interface IVester {
    function rely(address _usr) external;
    function deny(address _usr) external;
}

contract DaoVesterDeployer {
    event ContractCreation(address newContract);

    address public constant MORPHO_DAO = 0xcBa28b38103307Ec8dA98377ffF9816C164f9AFa;

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

        IVester(newContract).rely(MORPHO_DAO);
        IVester(newContract).deny(address(this));
    }
}