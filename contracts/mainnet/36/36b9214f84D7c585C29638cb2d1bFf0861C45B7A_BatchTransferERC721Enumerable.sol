/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;


interface ERC721EnumerablePartial {
    function transferFrom(address from, address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract BatchTransferERC721Enumerable {

    function batchTransfer(ERC721EnumerablePartial tokenContract, address recipient, uint256 num) external {
        uint256 amount = tokenContract.balanceOf(msg.sender);
        require(amount >= num, "Not enough tokens");

        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenContract.tokenOfOwnerByIndex(msg.sender, 0);
            tokenContract.transferFrom(msg.sender, recipient, tokenId);
        }
    }
}