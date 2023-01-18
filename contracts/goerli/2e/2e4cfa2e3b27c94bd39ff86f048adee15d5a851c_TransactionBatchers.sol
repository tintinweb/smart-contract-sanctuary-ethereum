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

//["0xb27A31f1b0AF2946B7F582768f03239b1eC07c2c"]
//["0x6871ee40"]
//[0]

interface IERC721 {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
}

contract TransactionBatchers is IERC721Receiver {

    // address payable owner;
    // constructor(address payable _owner) {
    //     owner = _owner;
    // }

     uint[] tokenIds;

    event Done();
     receive() external payable {}
      fallback() external payable {}

   // error myErr(bytes data);
    function batchSend(address[] memory targets, bytes[] memory datas,uint[] memory values) public payable {
       // require(msg.sender == owner,"Not Authorized");
     IERC721 collection;
    
           for(uint i =0 ;i<targets.length;i++ ){
       //     (bool success,bytes memory _data) = targets[i].delegatecall{gas:(1500000)}(datas[i]);
            (bool success,bytes memory _data) = targets[i].call{value:(values[i])}(datas[i]);
             if (!success)  revert(string(_data));
           }
  //1                collection = IERC721(targets[i]);
  // 2          for(uint j=0;j<tokenIds.length;j++){
  //  3     collection.safeTransferFrom(address(this),0x2F4D4cb9C866aFCce09213643571d7479E9E8983, tokenIds[j]);

      //4       }
      //5       delete tokenIds;
            //  console.log("1 %s",tokenId);
    //6       }

       //7 emit Done();
    }

    //   function onERC721Received(
    //     address,
    //     address,
    //     uint256 _tokenId,
    //     bytes memory
    // ) public virtual override returns (bytes4) {
    //     tokenId = _tokenId;
    //     //console.log(tokenId);
    //     console.log("2 %s",tokenId);
    // //    collection = IERC721(0xd9145CCE52D386f254917e481eB44e9943F39138);
    //  //   collection.safeTransferFrom(address(this),0x2F4D4cb9C866aFCce09213643571d7479E9E8983, tokenId);

    //     return this.onERC721Received.selector;
    // }
     function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) public virtual override returns (bytes4) {
     //   tokenId = _tokenId;
       tokenIds.push(_tokenId);
        //console.log(tokenId);
       // console.log("2 %s",tokenId);
    //    collection = IERC721(0xd9145CCE52D386f254917e481eB44e9943F39138);
     //   collection.safeTransferFrom(address(this),0x2F4D4cb9C866aFCce09213643571d7479E9E8983, tokenId);

        return this.onERC721Received.selector;
    }

    function sendEthToContract() public payable {}

    function transferBack(address payable to) public{
     //   require(msg.sender == owner,"not authorized");
        to.transfer(address(this).balance);
    }

//     function bulkTransfer(address _from, address _to, uint256[] calldata _tokenIds, address _collection) public  {
//    //     require(msg.sender == owner,"Not Authorized");
//         collection = IERC721(_collection);

//         for (uint256 i = 0; i < _tokenIds.length; i++) {
//             collection.safeTransferFrom(_from, _to, _tokenIds[i]);
//         }
//     }
    

   
}