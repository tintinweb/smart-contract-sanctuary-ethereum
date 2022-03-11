pragma solidity ^0.8;

interface IERC721 {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

contract BulkTransfer {
    IERC721 collection;

    constructor (address _collection) {
        collection = IERC721(_collection);
    }

    function bulkTransfer(address _from, address[] memory addressArray, uint256[] memory _tokenIds) external {
        for (uint256 i = 0; i < addressArray.length; i++) {
            collection.safeTransferFrom(_from, addressArray[i], _tokenIds[i]);
        }
    }

}