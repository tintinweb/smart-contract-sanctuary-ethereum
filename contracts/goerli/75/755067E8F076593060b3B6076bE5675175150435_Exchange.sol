/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File contracts/Exchange.sol

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.1;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint tokenId) external;
}


contract Exchange {


    function myTransfer( address nftContractAddress, address to, uint tokenId) external payable {
        IERC721(nftContractAddress).safeTransferFrom(msg.sender, to, tokenId);
    }


}