/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract Test {
    struct Data {
        address a;
        address r;
        uint256[] values;
    }

    function foo(Data[] calldata data) external returns (uint256[] memory) {
        uint256 length = data.length;
        uint256[] memory sums = new uint256[](length);
        
        for (uint256 i = 0; i < length; i++) {
            uint256 sum = 0;
            uint256[] memory values = data[i].values;
            for (uint256 j = 0; j < values.length; j++) {
                sum += values[j];
            }

            sums[i] = sum;
        }   

        return sums;
    }
}