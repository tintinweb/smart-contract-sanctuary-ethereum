// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract InsuranceProviderDeployer {

    event ContractDeployed(address indexed newContract);

    function deploy(bytes memory contractData) public {
        address newContract;
        assembly {
            newContract := create(0, add(contractData, 0x20), mload(contractData))
            if iszero(newContract) {
                revert(0, 0)
            }
        }
        emit ContractDeployed(newContract);
    }
    
}