/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library OrderTypes {
  struct OrderOS {
    address[14] addrs;
    uint[18] uints;
    uint8[8] feeMethodsSidesKindsHowToCalls;
    bytes calldataBuy;
    bytes calldataSell;
    bytes replacementPatternBuy;
    bytes replacementPatternSell;
    bytes staticExtradataBuy;
    bytes staticExtradataSell;
    uint8[2] vs;
    bytes32[5] rssMetadata;
  }
}


interface IOpenSea {  
    function atomicMatch_(OrderTypes.OrderOS calldata orderOS) external payable;
}


interface IERC721 {
  function setApprovalForAll(address operator, bool approved) external;
  function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}



contract OsBuy is IERC721Receiver {

  address internal immutable OWNER;

  IOpenSea internal immutable OPENSEA;

  constructor(
    address _OPENSEA 
  ) {

    OWNER = msg.sender;

    OPENSEA = IOpenSea(_OPENSEA);
  }


  receive() external payable{}
    
  function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
  ) public override returns (bytes4) {
        return this.onERC721Received.selector;
  }
    
  function isValidSignature(bytes32 _hash, bytes memory _signature) public view returns (bytes4) {
    if (tx.origin == OWNER) {
      return 0x1626ba7e; // EIP-1271 
    } else {
      return 0xffffffff;
    }
  }
  
  function buyNFT(OrderTypes.OrderOS calldata orderOS) external {
    require(msg.sender == OWNER);
    OPENSEA.atomicMatch_{value: orderOS.uints[4]}(orderOS);
  }
  
  error WithdrawTransfer();
  function withdraw(address payable payee) external {
        require(msg.sender == OWNER);
        uint256 balance = address(this).balance;
        (bool transferTx, ) = payee.call{value: balance}("");
        if (!transferTx) {
            revert WithdrawTransfer();
        }
  }
  
  
}