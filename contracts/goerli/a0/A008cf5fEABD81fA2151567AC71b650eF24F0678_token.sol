/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;

contract token{
    uint32 public time  = uint32(block.timestamp);
    uint112 constant public max_token_number=37800000000000 ether;
    uint112 constant public all_claim =max_token_number/2;
}