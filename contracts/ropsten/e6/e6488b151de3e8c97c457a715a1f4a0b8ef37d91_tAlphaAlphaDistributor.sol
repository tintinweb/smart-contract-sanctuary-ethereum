// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AlphaDistributor.sol";

contract tAlphaAlphaDistributor is AlphaDistributor {
    constructor (IERC20 _alpha) AlphaDistributor(_alpha) {}
}