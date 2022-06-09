/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721 {

    function mint(uint256 amount) external;

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256 balance);
}

contract MintNFT  {

    address public projectAddr = address(0);

  function mint(uint256 amount, address project) external
  { 
    projectAddr = project;
    IERC721(project).mint(amount);

    // transferBackToUser(project);

  }

  function onERC721Received( address operator, address from, uint256 tokenId, bytes calldata data ) public returns (bytes4) 
  {
    if (projectAddr != address(0)){
      // transferBackToUser(projectAddr);
      IERC721(projectAddr).transferFrom(address(this), msg.sender, tokenId);
      projectAddr = address(0);
    }

    return this.onERC721Received.selector;
  }

  function transferBackToUser(address project) internal 
  {
    uint bal = IERC721(project).balanceOf(address(this));
    if (bal > 0) {
        for (uint i=0; i<bal; i++) {
            uint tokenid = IERC721(project).tokenOfOwnerByIndex(address(this), i);
            IERC721(project).transferFrom(address(this), msg.sender, tokenid);
        }
    }
  }

//   function withdraw() external {
//     (bool success, ) = msg.sender.call{value: address(this).balance}("");
//     require(success, "Transfer failed.");
//   }


}