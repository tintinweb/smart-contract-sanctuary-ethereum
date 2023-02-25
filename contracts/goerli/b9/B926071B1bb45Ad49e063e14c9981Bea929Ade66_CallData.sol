/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract CallData {

    function staticParameters(
        uint256 param1,
        address param2,
        bool param3
    ) external view returns (bool result) {
        result = param1 == 15 && param2 == address(this) && param3 == true;
    }

    function dynamicParameters(uint256[] memory param1, bytes memory param2, bytes[] memory param3)
        external
        pure
        returns (bool result)
    {
        uint256 sum;

        for (uint256 i = 0; i < param1.length; ) {
            sum += param1[i];
            unchecked {
                ++i;
            }
        }

        result = sum == 10;
    }
}