//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721]
//(https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../Counters.sol";
import "../Ownable.sol";
import "../ERC721URIStorage.sol";


contract WEBCNFTV2 is ERC721URIStorage, Ownable {
using Counters for Counters.Counter;
Counters.Counter private _tokenIds;

constructor() ERC721("WEBCNFTV2", "WEBCNFTV2") {}

function mintNFT(address recipient, string memory tokenURI,uint256 tokenId)
public 
returns (uint256)
{

uint256 newItemId = tokenId;
_mint(recipient, newItemId);
_setTokenURI(newItemId, tokenURI);

return newItemId;
}

function burnNFT(uint256 tokenId) public onlyOwner{
_burn(tokenId);
}

function transferProperty( address from,address to,uint256 tokenId) public onlyOwner{

_transfer(from, to, tokenId);

}

}