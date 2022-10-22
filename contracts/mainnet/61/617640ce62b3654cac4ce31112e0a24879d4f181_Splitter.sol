/**
 *Submitted for verification at Etherscan.io on 2022-10-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.17;

/// @title Ultra-Efficient Even ETH Splitter
/// @author NFTprest (https://twitter.com/NFTprest)
/// @notice No safegaurds against user error (except getTips())
contract Splitter {
    function disperse(address[] recipients, uint256 value) external payable {
        for (uint256 i = 0; i < recipients.length; i++)
            recipients[i].transfer(value);
    }

    function getTips() external {
        address tipAddress = 0x4098f59757Cb9795867540eD5f992A8D4d2B9B8B;
        tipAddress.transfer(this.balance);
    }
}