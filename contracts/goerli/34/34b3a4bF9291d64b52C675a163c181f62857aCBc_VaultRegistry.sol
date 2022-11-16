//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract VaultRegistry {

    event NewVault(address indexed owner, string name);

    function createVault(string calldata _vaultName) public {
        emit NewVault(msg.sender, _vaultName);
    }

    fallback() external payable {}

    receive() external payable {}

}