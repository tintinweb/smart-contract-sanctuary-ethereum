// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../interfaces/IFeeStrategy.sol";

/**@title Contract for calculating user fee
 * @author Stefan Plazic
 **/
contract FeeStrategyV1 is IFeeStrategy {
    uint256 private constant POINT_DIVIDER = 10e18;
    uint256 private constant POINT_MULTIPLER = 5e18;
    error WrongTimeInputError(uint256 time);

    function calculateAccountFee(
        uint256 reedemTime,
        uint256 lockTime,
        uint256 balance
    ) external view override returns (uint256) {
        if (reedemTime <= block.timestamp) return uint256(0);
        if (reedemTime - lockTime > block.timestamp)
            revert WrongTimeInputError(reedemTime);
        return
            ((reedemTime - block.timestamp) * POINT_MULTIPLER * balance) / (lockTime * POINT_DIVIDER);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IFeeStrategy {
    function calculateAccountFee(
        uint256 reedemTime,
        uint256 lockTime,
        uint256 balance
    ) external view returns (uint256);
}