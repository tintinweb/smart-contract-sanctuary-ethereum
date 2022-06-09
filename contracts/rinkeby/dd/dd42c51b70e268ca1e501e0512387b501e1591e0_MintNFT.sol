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
    uint tokenIdTmp = 0;

  function mint(uint256 amount, address project) external
  { 
    // projectAddr = project;

    minting(amount, project);
    

    transferBackToUser(project);

  }

  function minting(uint256 amount, address project) internal 
  {
      IERC721(project).mint(amount);
  }

  function transferBackToUser(address project) internal 
  {
    uint bal = IERC721(project).balanceOf(address(this));
    if (bal > 0) {
    //     for (uint i=0; i<bal; i++) {
            // uint tokenid = IERC721(project).tokenOfOwnerByIndex(address(this), i);
            IERC721(project).transferFrom(address(this), msg.sender, tokenIdTmp);
            tokenIdTmp = 0;
    //     }
    }
  }

   function onERC721Received( address operator, address from, uint256 tokenId, bytes calldata data ) public returns (bytes4) 
  {
    tokenIdTmp = tokenId;
    return this.onERC721Received.selector;
  }

//   function withdraw() external {
//     (bool success, ) = msg.sender.call{value: address(this).balance}("");
//     require(success, "Transfer failed.");
//   }


}