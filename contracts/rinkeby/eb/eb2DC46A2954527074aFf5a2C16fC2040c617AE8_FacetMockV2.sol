/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

contract FacetMock {
    function getABC() external pure returns (uint256) {
        return 69;
    }
}

contract FacetMockV2 {
    function getABC() external pure returns (uint256) {
        return 420;
    }
}