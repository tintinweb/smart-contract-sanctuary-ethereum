/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

pragma solidity 0.8.4;

contract NFTBurner {
  function burn(address _nft, address _to, uint[] memory _tokenIds) public {
    uint len = _tokenIds.length;
    for(uint i; i<len;) {
      _nft.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",msg.sender,_to,_tokenIds[i]));
      unchecked {++i;}
    }
  }
}