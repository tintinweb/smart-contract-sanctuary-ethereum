// SPDX-License-Identifier:MIT
// Maybe we're in a holographic universe, and all humans are mining machines，we use our mind to generate currency!!!
// Thought is the ruler of the universe forever.  ——Plato


pragma solidity ^0.8.16;
import "./ERC20.sol";


contract token is ERC20{
    uint32  time = uint32(block.timestamp);
    uint112 constant max_token = 1900000000 ether; 
    
    constructor() ERC20("Mind Token","MITO"){
        _mint(0xd088921D2E112941f98E3eCe9769159D2432c183,max_token);
    }
}