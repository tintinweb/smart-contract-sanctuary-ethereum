// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../../interfaces/aaveV2/IAaveLendingPoolAddressesProviderV2.sol";

contract MockAaveLendingPoolAddressesProviderV2 is IAaveLendingPoolAddressesProviderV2 {
    address lendingPool;

    constructor(address _lendingPool) {
        lendingPool = _lendingPool;
    }

    function getLendingPool() external view override returns (address) {
        return lendingPool;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface IAaveLendingPoolAddressesProviderV2 {
    function getLendingPool() external view returns (address);
}