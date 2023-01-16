// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../ERC721A.sol";
import "../Ownable.sol";

    contract CursedMushroomSculptures is ERC721A, Ownable {
    uint256 public price;   
    uint256 public maxSupply;
    address private withdrawWallet;
    string baseURI;
    string public baseExtension;    

    constructor() ERC721A("Cursed Mushroom Sculptures", "CMS") {
        price = 0.025 ether;
        maxSupply = 343;
        baseExtension = ".json";
        baseURI = "";
        withdrawWallet = address(msg.sender);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }


    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWithdrawWallet(address wallet) public onlyOwner {
        withdrawWallet = wallet;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(withdrawWallet).call{value: address(this).balance}("");
        require(os);
    }
    
    

    function mint( uint256 _mintAmount) public payable onlyOwner {
         require(totalSupply() + _mintAmount <= maxSupply);
        _mint(msg.sender, _mintAmount);
    }


    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }


    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(_baseURI(), _toString(tokenId), baseExtension)) : '';
    }
}