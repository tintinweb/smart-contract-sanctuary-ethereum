/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

/**
 * @dev Contract that reads the block base fee on supported
 *  networks, including Ethereum, Fantom, and Arbitrum.
 *
 * Version 0.1.0
 */

contract Basefee {
    function basefee_global() external view returns (uint) {
        return block.basefee;
    }
}