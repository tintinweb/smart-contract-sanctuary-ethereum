// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Base64.sol";

contract ThisWeb3_ERC721_NFT_On_Polygon_Mumbai is ERC721URIStorage  {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    mapping(uint256 => uint256) public tokenIdToLevels;

    constructor() ERC721 ("ThisWeb3.eth NFT On Polygon Mumbai", "ThisWeb3"){
    }

    function getMainString(uint256 _tokenId) public view returns(string memory){

    bytes memory svg = abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
        '<style>.base { fill: white; font-family: serif; font-size: 14px; }</style>',
        '<rect width="100%" height="100%" fill="black" />',
        '<text x="50%" y="40%" class="base" dominant-baseline="middle" text-anchor="middle">',"ThisWeb3",'</text>',
        '<text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">', "Levels: ",getLevels(_tokenId),'</text>',
        '</svg>'
    );
    return string(
        abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(svg)
        )    
    );
  }
function getLevels(uint256 _tokenId) public view returns (string memory) {
    uint256 levels = tokenIdToLevels[_tokenId];
    return levels.toString();
}
 function getTokenURI(uint256 _tokenId) public view returns (string memory){
    bytes memory dataURI = abi.encodePacked(
        '{',
            '"name": "ThisWeb3.eth NFT On Polygon Mumbai #', _tokenId.toString(), '",',
            '"description": "This Nft Contract is created by ThisWeb3.eth",',
            '"image": "', getMainString(_tokenId), '"',
        '}'
    );
    return string(
        abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(dataURI)
        )
    );
}
function mint() public {
    tokenIds.increment();
    uint256 newItemId = tokenIds.current();
    _safeMint(msg.sender, newItemId);
    tokenIdToLevels[newItemId] = 0;
    _setTokenURI(newItemId, getTokenURI(newItemId));
}

function train(uint256 _tokenId) public{
  require(_exists(_tokenId),"The tokenId does not exist");
  require(_isApprovedOrOwner(msg.sender, _tokenId),"You are not the owner of the NFT"); 
  tokenIdToLevels[_tokenId] += 1;
  _setTokenURI(_tokenId, getTokenURI(_tokenId));
}
}