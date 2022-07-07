/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Assembly {
    function countSolidity(uint256[] memory array, uint256 k) external returns(uint256 res) {
        for(uint i; i < array.length; i ++)
            if(array[i] == k) res++;
    }

    function countAssembly(uint256[] memory array, uint256 k) external returns(uint256 res) {
        assembly {
           let len := mload(array)
           let data := add(array, 0x20)
           for
               { let end := add(data, mul(len, 0x20)) }
               lt(data, end)
               { data := add(data, 0x20) }
           {
               if eq(mload(data), mload(k)) {
                   res := add(res, 1)
               }
           }
        }
    }
}