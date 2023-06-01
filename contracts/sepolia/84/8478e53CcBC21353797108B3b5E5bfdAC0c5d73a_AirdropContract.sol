// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract AirdropContract {
    event AirdropERC20Completed(address indexed sender, address indexed tokenAddress, address[] recipients, uint256 amount);
    event AirdropERC721Completed(address indexed sender, address indexed tokenAddress, address[] recipients, uint256[] tokenIds);
    
    function airdropERC20(address[] calldata recipients, address tokenAddress, uint256 amount) external {
        IERC20 token = IERC20(tokenAddress);
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(token.transferFrom(msg.sender, recipients[i], amount), "ERC20 transfer failed");
        }
        
        emit AirdropERC20Completed(msg.sender, tokenAddress, recipients, amount);
    }
    
    function airdropERC721(address[] calldata recipients, address tokenAddress, uint256[] calldata tokenIds) external {
        IERC721 token = IERC721(tokenAddress);
        
        require(recipients.length == tokenIds.length, "Array length mismatch");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            token.transferFrom(msg.sender, recipients[i], tokenIds[i]);
        }
        
        emit AirdropERC721Completed(msg.sender, tokenAddress, recipients, tokenIds);
    }
}