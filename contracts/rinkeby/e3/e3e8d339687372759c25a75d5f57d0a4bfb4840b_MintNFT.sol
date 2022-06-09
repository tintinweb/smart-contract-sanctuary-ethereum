/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721 {

    function mint(uint256 amount) external;

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract MintNFT  {

  function onERC721Received( address operator, address from, uint256 tokenId, bytes calldata data ) public returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function mint(uint256 amount, address project) external
  { 
    IERC721(project).mint(amount);

  }

  function claim(address project) external 
  {
    uint tokeid = IERC721(project).tokenOfOwnerByIndex(address(this), 0);

    IERC721(project).transferFrom(address(this), msg.sender, tokeid);
  }

  function withdraw() external {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }


}