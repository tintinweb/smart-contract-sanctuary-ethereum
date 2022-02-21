/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IERC20 { 

    function safeMint(address to) external; 

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external; 
}



pragma solidity ^0.8.0;

interface IERC721Receiver {        
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


abstract contract ERC721Receiver{

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4){
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}



contract MyContract is ERC721Receiver{    

    IERC20 dcoffer = IERC20(address(0x9149A8Cb21f2702fCb1076f0964A17d45B5EFa85));

    function staking(address from,address to,uint256 tokenId) external {       
        dcoffer.safeTransferFrom(from,to,tokenId);
    }

    function mint()external{
        dcoffer.safeMint(msg.sender);
    }

    
}