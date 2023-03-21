/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.16;

contract Timestamper  {
    function timestamp() external view returns (uint256) {
        return block.timestamp;
    }
}