/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract TestMarketplace {

    address public NFT_CONTRACT_ADDRESS;

    mapping(uint256 => address) public originalOwner;


    function transferToContract(uint256 _tokenId) public {
        IERC721(NFT_CONTRACT_ADDRESS).transferFrom(msg.sender, address(this), _tokenId);
        originalOwner[_tokenId] = msg.sender;
    }
  

    function withdrawNFTFromContract(uint256 _tokenId) public {
        require(originalOwner[_tokenId] == msg.sender, "Not Original Owner");
        IERC721(NFT_CONTRACT_ADDRESS).transferFrom(address(this), msg.sender, _tokenId);
    }

}