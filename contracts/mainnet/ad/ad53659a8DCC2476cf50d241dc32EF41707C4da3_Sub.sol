//SPDX-License-Identifier: NONE
pragma experimental ABIEncoderV2;
pragma solidity ^0.8.0;
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
interface IERC1155Received {
    function onERC1155Received(address operator, address from, uint256 id, uint256 value,bytes calldata data) external returns (bytes4);
}
interface IERC721 {
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}
interface IERC1155BatchReceived{
function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
    }
interface IERC1155 {
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata data) external;
}
contract Sub is IERC721Receiver,IERC1155Received,IERC1155BatchReceived{
    uint256[] public tokenIds;
    uint256[] public tokenIdsERC1155;
    uint256[] public valuesERC1155;
    receive() external payable {}
    fallback() external payable {}
     function mint(
        address targets,
        bytes calldata datas,
        address contractAddress,
        address receiver
    ) external payable {
        (bool success,) = targets.delegatecall{gas: (350000)}(datas);
         require(success);
        uint256 lengths = tokenIds.length;
        IERC721 collection = IERC721(contractAddress);
        for (uint16 j = 0; j < lengths; ) {
            collection.safeTransferFrom(address(this), receiver, tokenIds[j]);
            unchecked {
                ++j;
            }
        }
        delete tokenIds;
    }
     function mint1(
        address targets,
        bytes calldata datas,
        address contractAddress,
        address receiver
    ) public payable {
        (bool success,) = targets.delegatecall{gas: (350000)}(datas);
        require(success);
        IERC1155(contractAddress).safeBatchTransferFrom(address(this),receiver,tokenIdsERC1155,valuesERC1155,"0x");
        delete tokenIdsERC1155;
        delete valuesERC1155;
    }
    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) public virtual override returns (bytes4) {
        tokenIds.push(_tokenId);
        return this.onERC721Received.selector;
    }
     function onERC1155Received(address, address, uint256 id, uint256 value,bytes memory) 
     public virtual override returns (bytes4){
         tokenIdsERC1155.push(id);
         valuesERC1155.push(value);
         return this.onERC1155Received.selector;
     }
     function onERC1155BatchReceived(address, address, uint256[] memory ids, uint256[] memory values, bytes memory) public virtual override returns (bytes4) {
        tokenIdsERC1155 = ids;
        valuesERC1155 = values;
        return this.onERC1155BatchReceived.selector;
    }
    function transferBack(address payable to) public {
        to.transfer(address(this).balance);
    }
    function bulkTransfer(address _to,address _collection,uint256[] calldata _tokenIds) public  {
        IERC721 collection = IERC721(_collection);
        for (uint16 i = 0; i < _tokenIds.length;) {
            collection.safeTransferFrom(address(this), _to, _tokenIds[i]);
            unchecked{
                ++i;
            }
        }
    }
    function bulkTransfer2(address _to,  address _collection,uint256[] calldata _tokenIds,uint256[] calldata _values) public  {
        IERC1155 collection = IERC1155(_collection);
            collection.safeBatchTransferFrom(address(this), _to, _tokenIds,_values,"0x");
    }
}