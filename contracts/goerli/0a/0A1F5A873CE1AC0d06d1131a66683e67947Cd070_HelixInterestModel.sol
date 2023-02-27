// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IHelixInterestModel.sol";

contract HelixInterestModel is IHelixInterestModel {
    uint256 private constant SECONDS_PER_DAY = 1 days;
    uint256 private constant INTEREST_DECIMALS = 1e18;
    // 365 days
    uint256 private constant SECONDS_PER_YEAR_365 = (SECONDS_PER_DAY * 365);

    function calculateInterestAccruedOverTimes(
        uint256 _amount,
        uint256 _interestRate,
        uint256 _secondElapsed
    ) public override pure returns(uint256) {
        uint256 totalInterestPerYear = _amount * _interestRate / INTEREST_DECIMALS;
        return totalInterestPerYear * _secondElapsed / SECONDS_PER_YEAR_365;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IHelixInterestModel {
    function calculateInterestAccruedOverTimes(
        uint256 _amount,
        uint256 _interestRate,
        uint256 _secondElapsed
    ) external pure returns(uint256);
}