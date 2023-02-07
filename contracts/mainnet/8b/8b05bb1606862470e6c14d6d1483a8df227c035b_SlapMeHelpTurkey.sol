// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
                                                                    


contract SlapMeHelpTurkey is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    
    string private baseURI;    
    uint256 public maxSupply = 5000;
    uint256 public constant cost = 0.075 ether;

    constructor(string memory _initBaseURI) ERC721A("Slap Me Help Turkey", "SMHT"){
        baseURI = _initBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getTotalSupply() public view returns(uint256) {
        return totalSupply();
    }


    //PUBLIC FUNCTIONS
    //Mint - To help turkey
    function mint(uint256 _mintAmount) external payable {
        require(totalSupply() + _mintAmount <= maxSupply, "Total Supply Exceeded");
        require(msg.value == cost * _mintAmount, "Insufficient fund in your wallet");
        _safeMint(msg.sender, _mintAmount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }


    //SET FUNCTIONS 
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        maxSupply = _newMaxSupply;
    }

    //TOGGLE FUNCTION

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }



}