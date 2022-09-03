// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct MintParams {
    address to;
    uint256 price;
    uint256 tokenExpiration; 
    uint256 mintExpiration;
    string[] values;
    bool canMint;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

contract GoerliTestNFT {
  function mint(MintParams memory params) external view returns(address){  
    return ecrecover(keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash(params))
    ), params.v, params.r, params.s);
  }

  function chainId() public view returns (uint256) {
    return block.chainid;
  }

  function hash(MintParams memory params) public view returns (bytes32) {
    return keccak256(abi.encode(block.chainid, params.to, params.price, params.tokenExpiration, params.mintExpiration, params.values, params.canMint));
  }
}