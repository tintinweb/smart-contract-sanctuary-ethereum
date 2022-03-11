// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract BaseNFT is ERC721Enumerable, Ownable {

    event NftBought(address _seller, address _buyer, uint256 _price);

    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIdCounter;

    // NFT MAX SUPPLY
    uint public constant MAX_SUPPLY = 10000;

    // Minting price for 1 NFT
    uint public constant PRICE = 0.1 ether;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping from token ID to token uri
    mapping(uint256 => string) private _tokenURIs;
    
    constructor(string memory name, string memory symbol) ERC721(name, symbol){}

    function mint(string memory _tokenURI) public payable returns (uint256)  {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        require( tokenId < MAX_SUPPLY, "Exceeds maximum supply");
        require( msg.value >= PRICE, "Not enough MEHHC sent, check price");
        _owners[tokenId] = msg.sender;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);

        return tokenId;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        return _tokenURI;
    }

    function tokensOfOwner(address _owner) external view returns (uint[] memory) {

        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No mehhc left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function buy(uint256 _tokenId, uint256 price) external payable {
        require(price > PRICE, "This token is not for sale");
        require(msg.value == price, "Your balance is not enough");
        
        address seller = _owners[_tokenId];
        _transfer(seller, msg.sender, _tokenId);
        payable(seller).transfer(msg.value); // send the MEHHC to the seller

        emit NftBought(seller, msg.sender, msg.value);
    }

    function burn(uint256 tokenId) external onlyOwner {
        require(_owners[tokenId] == msg.sender, "Only owner can mint the token");
        _burn(tokenId);
    }
}