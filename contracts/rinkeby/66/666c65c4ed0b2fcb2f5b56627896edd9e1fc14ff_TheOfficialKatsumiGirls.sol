// SPDX-License-Identifier: MIT
// The Official Katsumi Girls
/* 


*/

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721A.sol";

contract TheOfficialKatsumiGirls is ERC721A, Ownable {
    uint256 public constant maxSupply = 5555;
    uint256 public price = 0.003 ether;
    string public baseURI = "ipfs://QmbFXEiqe1dmbRsNRyVeHX7DvikfasNSoBz31DA9rvYvJa/";
    uint256 public maxpertx = 10;
    uint256 public freesupply = 750;
    bool public paused = false;


    constructor() ERC721A("TheOfficialKatsumiGirls", "KG") {}


    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function startMint() external onlyOwner {
        paused = false;
    }

    function pauseMint() external onlyOwner {
        paused = true;
    }
    

    function setBaseURI(string memory _updatedURI) public onlyOwner {
        baseURI = _updatedURI;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        price = _newCost;
    }


    modifier checks(uint256 _mintAmount) {
        require(!paused, "Mint is paused!");
        require(_mintAmount > 0);
        require(totalSupply() + _mintAmount <= maxSupply, "Exceed max supply!");
        require(_mintAmount <= maxpertx, "Exceed max per tx!");
        if(totalSupply() >= freesupply){
            require(msg.value >= _mintAmount * price, "You need to send more ETH!");
        }
        _;
    }


    function mint(uint256 _mintAmount) public payable checks(_mintAmount) {
        _safeMint(msg.sender, _mintAmount);
    }


    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

}