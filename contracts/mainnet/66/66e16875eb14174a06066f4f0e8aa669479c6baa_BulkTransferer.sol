/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

pragma solidity ^0.8;

interface IERC721 {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

contract BulkTransferer {
    IERC721 collection;

    constructor (address _collection) {
        collection = IERC721(_collection);
    }

    function bulkTransfer(address _from, address _to, uint256[] memory _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            collection.safeTransferFrom(_from, _to, _tokenIds[i]);
        }
    }
}