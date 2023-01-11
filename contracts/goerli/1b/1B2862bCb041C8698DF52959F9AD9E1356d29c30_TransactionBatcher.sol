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
interface IERC721 {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
}



contract TransactionBatcher is IERC721Receiver {

    

     IERC721 collection;

    event Done();
     receive() external payable {}
      fallback() external payable {}


    function batchSend(address payable targets, bytes memory datas) public payable {
    
        
            (bool success,) = targets.delegatecall(datas);
            require(success,"Transaction failed in contract");

        emit Done();
    }

      function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        
        return this.onERC721Received.selector;
    }

    function sendEthToContract() public payable {}

    function bulkTransfer(address _from, address _to, uint256[] calldata _tokenIds, address _collection) public  {
        
        collection = IERC721(_collection);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            collection.safeTransferFrom(_from, _to, _tokenIds[i]);
        }
    }
    

   
}