// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ICLSynchronicityPriceAdapter {
  /**
   * @notice Calculates the current answer based on the aggregators.
   */
  function latestAnswer() external view returns (int256);

  error DecimalsAboveLimit();
  error DecimalsNotEqual();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {ICLSynchronicityPriceAdapter} from "../dependencies/chainlink/ICLSynchronicityPriceAdapter.sol";

contract CLBaseCurrencySynchronicityPriceAdapter is
    ICLSynchronicityPriceAdapter
{
    address public immutable BASE_CURRENCY;
    uint256 public immutable BASE_CURRENCY_UNIT;

    constructor(address baseCurrency, uint256 baseCurrencyUnit) {
        BASE_CURRENCY = baseCurrency;
        BASE_CURRENCY_UNIT = baseCurrencyUnit;
    }

    function latestAnswer() external view override returns (int256) {
        return int256(BASE_CURRENCY_UNIT);
    }
}