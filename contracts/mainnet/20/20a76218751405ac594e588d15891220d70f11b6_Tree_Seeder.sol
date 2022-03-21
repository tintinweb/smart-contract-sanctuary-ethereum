/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface INeoTokyoContract {
    function setTokenSeed(uint256 tokenId) external;  
}

contract Tree_Seeder {
    address public owner;

    constructor(address _creator) {
        owner = _creator;
    }

    function thisAddress() public view returns (address) {
        return address(this);
    }
  
    function destroySeeder(address payable _to) public {
        require(msg.sender == owner, "Must be owner");
        selfdestruct(_to);
    }

     //Use this after minting boughtIdentities, land, and eventually items, outer_ids, outer_lands, outer_items.
    function setSeed(address target, uint256 tokenId) public {
      return INeoTokyoContract(target).setTokenSeed(tokenId);
    }
}