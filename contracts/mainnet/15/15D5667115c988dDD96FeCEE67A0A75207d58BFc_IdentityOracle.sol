// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.15;

import "@yield-protocol/vault-v2/contracts/interfaces/IOracle.sol";

contract IdentityOracle is IOracle {
    function peek(
        bytes32,
        bytes32,
        uint256 amountBase
    ) external view virtual override returns (uint256, uint256) {
        return (amountBase, block.timestamp);
    }

    function get(
        bytes32,
        bytes32,
        uint256 amountBase
    ) external virtual override returns (uint256, uint256) {
        return (amountBase, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @notice Doesn't refresh the price, but returns the latest value available without doing any transactional operations
     * @param base The asset in which the `amount` to be converted is represented
     * @param quote The asset in which the converted `value` will be represented
     * @param amount The amount to be converted from `base` to `quote`
     * @return value The converted value of `amount` from `base` to `quote`
     * @return updateTime The timestamp when the conversion price was taken
     */
    function peek(
        bytes32 base,
        bytes32 quote,
        uint256 amount
    ) external view returns (uint256 value, uint256 updateTime);

    /**
     * @notice Does whatever work or queries will yield the most up-to-date price, and returns it.
     * @param base The asset in which the `amount` to be converted is represented
     * @param quote The asset in which the converted `value` will be represented
     * @param amount The amount to be converted from `base` to `quote`
     * @return value The converted value of `amount` from `base` to `quote`
     * @return updateTime The timestamp when the conversion price was taken
     */
    function get(
        bytes32 base,
        bytes32 quote,
        uint256 amount
    ) external returns (uint256 value, uint256 updateTime);
}