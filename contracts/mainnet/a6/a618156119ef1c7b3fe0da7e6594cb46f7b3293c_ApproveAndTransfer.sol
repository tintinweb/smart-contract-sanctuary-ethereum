/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

pragma solidity ^0.8;
// SPDX-License-Identifier: MIT

interface TransferERC721 {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

interface TransferERC1155 {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, uint256 _amount, bytes memory _bytes) external;
}

contract ApproveAndTransfer {
    TransferERC721 collectionERC721;
    TransferERC1155 collectionERC1155;

    struct DataERC721 {
        address collection_address;
        uint256[] token_ids;
    }

    struct DataERC1155 {
        address collection_address;
        uint256[] token_ids;
        uint256[] amounts;
    }

    function collectionTransferERC721(address _collection, address _from, address _to, uint256[] memory _tokenIds) private {
        collectionERC721 = TransferERC721(_collection);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            collectionERC721.safeTransferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function bulkCollectionTransferERC721(address _from, address _to, DataERC721[] memory data) external {
        for (uint256 ii = 0; ii < data.length; ii++) {
            collectionTransferERC721(data[ii].collection_address, _from, _to, data[ii].token_ids);
        }

    }

    function collectionTransferERC1155(address _collection, address _from, address _to, uint256[] memory _tokenIds, uint256[] memory _amounts, bytes memory _bytes) private {
        collectionERC1155 = TransferERC1155(_collection);
        for (uint256 iii = 0; iii < _tokenIds.length; iii++) {
            collectionERC1155.safeTransferFrom(_from, _to, _tokenIds[iii], _amounts[iii], _bytes);
        }
    }

    function bulkCollectionTransferERC1155(address _from, address _to, bytes memory _bytes, DataERC1155[] memory data) external {
        for (uint256 iiii = 0; iiii < data.length; iiii++) {
            collectionTransferERC1155(data[iiii].collection_address, _from, _to, data[iiii].token_ids, data[iiii].amounts, _bytes);
        }

    }

}