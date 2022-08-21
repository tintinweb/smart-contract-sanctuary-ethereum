/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

pragma solidity ^0.8;
// SPDX-License-Identifier: MIT

interface IERC721 {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

contract BulkTransferer {
    IERC721 collection;

    function bulkTransfer(address _collection, address _from, address _to, uint256[] memory _tokenIds) external {
        collection = IERC721(_collection);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            collection.safeTransferFrom(_from, _to, _tokenIds[i]);
        }
    }
}