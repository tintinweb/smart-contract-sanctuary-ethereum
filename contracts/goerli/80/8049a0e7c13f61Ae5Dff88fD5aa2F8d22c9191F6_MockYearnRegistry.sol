// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/RegistryApi.sol";

contract MockYearnRegistry is RegistryAPI {

    address override public governance;
    mapping(address => uint256) override public numVaults;
    mapping(address => mapping(uint256 => address)) override public vaults;

    constructor() {
        governance = msg.sender;
    }

    function latestVault(address token) override external view returns (address) {
        return vaults[token][numVaults[token] - 1];
    }

    function newVault(address token, address vault) external {
        vaults[token][numVaults[token]] = vault;
        numVaults[token] += 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface RegistryAPI {
    function governance() external view returns (address);

    function latestVault(address token) external view returns (address);

    function numVaults(address token) external view returns (uint256);

    function vaults(address token, uint256 deploymentId)
        external
        view
        returns (address);
}