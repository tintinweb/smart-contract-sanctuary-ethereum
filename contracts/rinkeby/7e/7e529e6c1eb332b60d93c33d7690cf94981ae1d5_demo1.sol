/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

contract demo1 {
    uint256 public count;

    function inc() external {
        count += 1;
    }

    function dec() external {
        count -= 1;
    }
}

// contract TestCounter is demo1 {
//     function echidna_test_pass() public view returns (bool) {
//         return true;
//     }

//     function echidna_test_fails() public view returns (bool) {
//         return false;
//     }
// }