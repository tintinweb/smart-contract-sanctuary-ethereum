/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract NT_Seeder {
    
    //Use this after minting boughtIdentities, Land, and eventually items, S2 ids, S2 lands, S2 items.
    function setSeed(address target, uint256 tokenId) public returns (uint) {
        (bool success, bytes memory data) = target.call(abi.encodeWithSelector(0x51df8ed6, tokenId));
        
        if (success == false) { return 0; }
        return abi.decode(data, (uint));
    }
}