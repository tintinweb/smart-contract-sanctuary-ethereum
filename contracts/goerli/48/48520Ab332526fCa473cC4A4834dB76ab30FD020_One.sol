// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./MyContract.sol";

contract One is MyContract {

    uint256 public sOne;

    constructor(uint256 _one) {
        sOne = _one;
    }

    function getMul(uint256 _num1, uint256 _num2)
        external
        pure
        returns (uint256)
    {
        return _num1 * _num2;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

contract MyContract {
    function getSum(uint256 _num1, uint256 _num2)
        external
        pure
        returns (uint256)
    {
        return _num1 + _num2;
    }
}