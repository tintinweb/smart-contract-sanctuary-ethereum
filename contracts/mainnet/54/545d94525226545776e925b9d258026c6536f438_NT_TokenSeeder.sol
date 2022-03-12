/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface INeoTokyoContract {
    function setTokenSeed(uint256 tokenId) external;  
}

contract NT_TokenSeeder {
    address public owner;

    constructor() {
        owner = msg.sender;
    }
  
    function destroySmartContract(address payable _to) public {
        require(msg.sender == owner, "You are not the owner");
        selfdestruct(_to);
    }

    //Use this after minting boughtIdentities, land, and eventually items, outer_ids, outer_lands, outer_items.
    function setTokenSeed(address target, uint256 tokenId) public {
      return INeoTokyoContract(target).setTokenSeed(tokenId);
    }
}