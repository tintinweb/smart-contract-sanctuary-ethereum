/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

/**
 * SPDX-License-Identifier: UNLICENSED
**/
pragma solidity ^0.8.7;

contract BaseFeeContract {

    function block_basefee() external view returns (uint256) {
        return block.basefee;
    }

    function block_chainid() external view returns (uint256) {
        return block.chainid;
    }
}