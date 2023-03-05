// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

/**
 * @title ICondition
 * @dev Interface for the Condition contract.
 */
interface ICondition {
    /**
     * @notice Checks if the condition is met.
     * @param _data The data needed to perform a check.
     * @return True if the condition is met, false otherwise.
     */
    function check(bytes memory _data) external view returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import "../interfaces/ICondition.sol";

/**
 * @title ConditionETH
 * @author h0tw4t3r.eth
 * @notice Checks if the target address has a specific amount of ETH.
 */
contract ConditionETH is ICondition {
    uint256 public immutable quantity;

    constructor(uint256 _quantity) {
        quantity = _quantity;
    }

    /// @inheritdoc ICondition
    function check(bytes memory _data) external view override returns (bool) {
        address target = abi.decode(_data, (address));
        return target.balance >= quantity;
    }
}