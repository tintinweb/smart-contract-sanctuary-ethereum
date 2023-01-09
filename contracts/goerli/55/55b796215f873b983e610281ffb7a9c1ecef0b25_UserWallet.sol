/**
 *Submitted for verification at Etherscan.io on 2023-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract UserWallet {
    address public receiver;

    function transferERC721(address token, uint256 tokenId) external {
      IERC721(token).safeTransferFrom(address(this), receiver, tokenId);
    }

    function onERC721Received(
      address, 
      address, 
      uint256, 
      bytes calldata
    ) external pure returns (bytes4) {
      return 0x80ac58cd;
    }
}