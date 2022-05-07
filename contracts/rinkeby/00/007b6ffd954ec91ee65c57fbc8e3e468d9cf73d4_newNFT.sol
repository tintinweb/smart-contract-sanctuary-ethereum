// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
 
import 
"./nf-token-metadata.sol";
import 
"./ownable.sol";
 
contract newNFT is NFTokenMetadata, Ownable {
 
  constructor() {
    nftName = "WUP NFT";
    nftSymbol = "WFT";
  }
 
  /*function mint(address _to, uint256 _tokenId, string calldata _uri) 
external {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }*/

  function mint(uint256 num) public payable {
    uint256 supply = _totalSupply;
    require( num < 11, "You can mint a maximum of 10" );
    require( supply + num < 4000, "Exceeds maximum supply" );
    require( msg.value >= 0.05 ether * num, "Not enough ETH sent, check price" );
    for(uint256 i; i < num; i++){
        super._mint( msg.sender, supply + i);
        super._setTokenUri(supply + i, "https://tbcdevbd46.blob.core.windows.net/dev-test/testnet-sample-metadata.json");
    }
 }

 
}