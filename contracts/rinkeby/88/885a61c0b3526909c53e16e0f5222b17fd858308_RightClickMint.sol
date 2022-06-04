/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Strings.sol";
import "./Shareholders.sol";
import "./ERC721A.sol";


contract RightClickMint is ERC721A, Shareholders {
    mapping(uint256 => string) public URIofToken;
    uint public cost = 0.01 ether;

    constructor(
      ) ERC721A("Right Click Mint", "RCM")payable{}


    function mint(string memory _uri) external payable
    {
        require(msg.value + 1 > cost, "Amount of Ether sent too small");
        require(tx.origin == msg.sender, "No contracts!");
        URIofToken[_totalMinted()] = _uri;
        _mint(msg.sender, 1,"",true);
        
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        string memory TokenURI = URIofToken[_tokenId];
        return bytes(TokenURI).length > 0 ? string(abi.encodePacked(TokenURI)) : "";
    }

    function updateTokenURI(uint _tokenId, string memory _uri) external {
        address tokenOwner = ownerOf(_tokenId);
        require(msg.sender == tokenOwner, "You must own this token to update the URI.");
        URIofToken[_tokenId] = _uri;
    }

    function changeCost(uint _newCost) external onlyOwner {
        cost = _newCost;
    }

}