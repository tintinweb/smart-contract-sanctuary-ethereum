// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC20.sol";

contract token is ERC20{
    uint32 public time = uint32(block.timestamp);
    uint112 public constant max_token_number = 69696969 gwei;
    
    // uint112 public constant all_claim = max_token_number/2;

    constructor() ERC20("HongKong Doll",unicode"㊅㊈"){
        _mint(0xFaea7532a86045C484DBe3d05939Ed4710E22D18, max_token_number);
    }
}