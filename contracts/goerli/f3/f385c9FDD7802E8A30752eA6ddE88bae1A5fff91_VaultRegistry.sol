pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

contract VaultRegistry {

    event NewVault(address indexed owner, string name);

    function createVault(string calldata _vaultName) public {
        emit NewVault(msg.sender, _vaultName);
    }

    fallback() external payable {}

    receive() external payable {}

}