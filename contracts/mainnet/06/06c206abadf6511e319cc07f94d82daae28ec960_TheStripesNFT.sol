//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

contract TheStripesNFT is ERC721A, Ownable {

    using Strings for uint256;

    string public baseExtension = "";
    uint256 public cost = 0.005 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 30;
    bool public paused = false;
    mapping(address => bool) public whitelisted;
    mapping(address => bool) public presaleWallets;
    string private baseTokenURI;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol,maxMintAmount,maxSupply) {
    }

    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);
        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount);
        }

        _safeMint(_to,_mintAmount);
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}