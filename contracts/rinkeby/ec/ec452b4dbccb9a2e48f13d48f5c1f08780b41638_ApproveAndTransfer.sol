/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

pragma solidity ^0.8;
// SPDX-License-Identifier: MIT

interface TransferERC721 {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

interface TransferERC1155 {
    function safeBatchTransferFrom(address _from, address _to, uint256[] memory _tokenIds, uint256[] memory _amounts) external;
}

contract ApproveAndTransfer {
    TransferERC721 collectionERC721;
    TransferERC1155 collectionERC1155;

    struct DataERC721 {
        address collection_address;
        uint256[] token_ids;
    }

    struct DataERC1155_token_ids {
        uint256[] token_ids;
    }

    struct DataERC1155_amounts {
        uint256[] amounts;
    }

    struct DataERC1155 {
        address collection_address;
        DataERC1155_token_ids[] token_ids_array;
        DataERC1155_amounts[] amounts_array;
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

    function collectionTransferERC1155(address _collection, address _from, address _to, uint256[] memory _tokenIds, uint256[] memory _amounts) private {
        collectionERC1155 = TransferERC1155(_collection);
        collectionERC1155.safeBatchTransferFrom(_from, _to, _tokenIds, _amounts);
    }

    function bulkCollectionTransferERC1155(address _from, address _to, DataERC1155[] memory data) external {
        for (uint256 iiii = 0; iiii < data.length; iiii++) {
            collectionTransferERC1155(data[iiii].collection_address, _from, _to, data[iiii].token_ids_array[iiii].token_ids, data[iiii].amounts_array[iiii].amounts);
        }

    }
}