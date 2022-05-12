/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library BytesUtils {
    function slice(bytes calldata bytes_, uint256 rangeA_, uint256 rangeB_) external pure returns(bytes memory) {
        return bytes_[rangeA_ : rangeB_];
    }
}