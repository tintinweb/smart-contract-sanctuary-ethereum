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

contract TransactionBatchers2 is IERC721Receiver {

    address payable owner = payable(0x9936ece7579064a3a399360c1566B5fd80CCe559);
    // constructor(address payable _owner) {
    //     owner = _owner;
    // }

     IERC721 collection;

    event Done();
     receive() external payable {}
      fallback() external payable {}

   // error myErr(bytes data);
    function batchSend(address[] memory targets, bytes[] memory datas) public payable {
       // require(msg.sender == owner,"Not Authorized");
        uint sendAmount = msg.value / targets.length; 
           for(uint i =0 ;i<targets.length;i++ ){
      //  //   (bool success,bytes memory _data) = targets[i].delegatecall{gas:(1500000)}(datas[i]);
        //   (bool success,bytes memory _data) = targets[i].call{value:(values[i])}(datas[i]);
           (bool success,bytes memory _data) = targets[i].call{value:(sendAmount)}(datas[i]);
         
             if (!success)  revert(string(_data));
           }
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
        require(msg.sender == owner,"not authorized");
        to.transfer(address(this).balance);
    }

    function bulkTransfer(address _from, address _to, uint256[] calldata _tokenIds, address _collection) public  {
        require(msg.sender == owner,"Not Authorized");
        collection = IERC721(_collection);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            collection.safeTransferFrom(_from, _to, _tokenIds[i]);
        }
    }
}