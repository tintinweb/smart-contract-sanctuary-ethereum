// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract BoxV2 {
    uint256 public val;

    function inc() external {
        val += 1;
    }

    function _msgSender() external view returns(address){
        return msg.sender;
    }
}