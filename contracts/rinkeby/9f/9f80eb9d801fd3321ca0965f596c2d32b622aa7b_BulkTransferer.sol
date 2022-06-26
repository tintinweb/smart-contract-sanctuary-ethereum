/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface IERC721 {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

contract BulkTransferer {
    constructor () { }

    function bulkTransfer(address _from, address _to, address[] memory _collections, uint256[] memory _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IERC721 collection = IERC721(_collections[i]);
            collection.safeTransferFrom(_from, _to, _tokenIds[i]);
        }
    }
}