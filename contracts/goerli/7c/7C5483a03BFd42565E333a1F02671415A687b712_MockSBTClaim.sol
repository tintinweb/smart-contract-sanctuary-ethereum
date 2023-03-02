// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @dev: this is minimum mock contract for claim demo
contract MockSBTClaim {
    event Transfer(address from, address to, uint256 tokenId);

    function claim() public {
      // @dev: almost random token id for demo
      uint256 tokenId = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender)));
      emit Transfer(address(0x0), msg.sender, tokenId);
    }
}