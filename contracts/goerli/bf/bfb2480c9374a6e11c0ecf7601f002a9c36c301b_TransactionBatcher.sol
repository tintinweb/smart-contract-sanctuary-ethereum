//SPDX-License-Identifier:NONE
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

    // address payable owner;
    // constructor(address payable _owner) {
    //     owner = _owner;
    // }

     IERC721 collection;

    event Done();
     receive() external payable {}
      fallback() external payable {}


    function batchSend(address targets, bytes memory datas,uint values) public payable {
       // require(msg.sender == owner,"Not Authorized");
    
           // (bool success,) = targets[i].call{value:(values[i])}(datas[i]);
            (bool success,) = targets.call{value:(values)}(datas);
           
            if (!success) revert('transaction failed gayu');
        
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

    function transferBack(address payable to) public{
     //   require(msg.sender == owner,"not authorized");
        to.transfer(address(this).balance);
    }

    function bulkTransfer(address _from, address _to, uint256[] calldata _tokenIds, address _collection) public  {
   //     require(msg.sender == owner,"Not Authorized");
        collection = IERC721(_collection);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            collection.safeTransferFrom(_from, _to, _tokenIds[i]);
        }
    }
    

   
}