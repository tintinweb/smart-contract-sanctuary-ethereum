/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

pragma solidity ^0.4.25;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract Disperse {
    function disperseNft(IERC721 token, address[] recipients, uint256[] values) external {
        for (uint256 i = 0; i < recipients.length; i++)
            token.safeTransferFrom(msg.sender, recipients[i], values[i]);
    }
}