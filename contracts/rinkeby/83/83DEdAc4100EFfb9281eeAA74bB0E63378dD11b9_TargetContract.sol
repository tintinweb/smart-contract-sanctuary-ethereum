/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;

contract TargetContract {
    struct TupleParams {
        address tokenIn;
        address recipient;
        uint24 fee;
    }

    function method1(uint24 param1) external returns (uint256 i) {
        return 0;
    }

    function method2(TupleParams calldata params) external returns (uint256 i) {
        return 0;
    }

    function method3() external returns (uint256 i) {
        return 0;
    }

    function method4() external returns (uint256 i) {
        return 0;
    }
}