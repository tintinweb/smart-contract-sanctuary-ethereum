//SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import { IOracleUsd } from "../../interfaces/IOracleUsd.sol";

// Working implementation:
// https://github.com/GTON-capital/gcd-oracles/blob/main/contracts/impl/UniswapV3Oracle.sol

contract TwapOracleMock is IOracleUsd {

    // UniV3 price when UI says: 1 gtonUSDC = 1.001 tGTON
    // 1 GTON swap's expected output: 0.999299 gtonUSDC
    // when 1 USDC is pegged to 1 USD precisely
    uint value = 5204784332479603888977112172891870330880000000000000;

    // returns Q112-encoded value
    // returned value 10**18 * 2**112 is $1
    function assetToUsd(address baseAsset, uint amount) external view override returns(uint) {
        return value;
    }

    function setValue(uint value_) external {
        value = value_;
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity >=0.8.0;

interface IOracleUsd {

    // returns Q112-encoded value
    // returned value 10**18 * 2**112 is $1
    function assetToUsd(address asset, uint amount) external view returns (uint);
}