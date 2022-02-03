/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract IVault {
    mapping (address => uint256) public cash;

    uint256 public managed;
    uint256 public lastChangeBlock;
    address public assetManager;

    function setPoolTokenInfo(
        address token_,
        uint256 cash_
    ) public {
        cash[token_] = cash_;
    }

    function getPoolTokenInfo(bytes32 poolId, address token)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address
        ) {
        return (
            cash[token],
            managed,
            lastChangeBlock,
            assetManager                
        );
    }
}