/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}
contract BulkTransfer {
    address public admin;

    constructor()  {
        admin = msg.sender;
    }

    function bulkTransfer(address[] calldata collections, uint256[] calldata tokenIds, address receiver) external {
        require(msg.sender == admin, "not amdin");
        require(collections.length == tokenIds.length, "length mismatch");
        for (uint256 i = 0; i < collections.length; i++){
            IERC721(collections[i]).transferFrom(msg.sender, receiver, tokenIds[i]);
        }
    }

}