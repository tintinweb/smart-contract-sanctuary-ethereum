// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract ABCDEF is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public maxSupply = 1000;
    uint256 public maxPerTx = 1;
    uint256 public freeMints = 3;
    uint256 public price = 0.0025 ether;
    bool public publicSaleStarted = false;

    string public _baseTokenURI;
    string public hiddenMetadataUri;

    bool public paused;
    bool public revealed;

    constructor() ERC721A("ABCDEF", "ACF") {
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function setBaseURI(string calldata baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice * (1 ether);
    }

    function setmaxSupply(uint256 _newMaxSupply) public onlyOwner {
	    maxSupply = _newMaxSupply;
	}

    function setMaxPerTx(uint256 _newMaxPerTx) public onlyOwner {
	    maxPerTx = _newMaxPerTx;
	}

    function setFreeMints(uint256 _newFreeMints) public onlyOwner {
	    freeMints = _newFreeMints;
	}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI does not exist!");
    
        if (revealed) {
            return string(abi.encodePacked(_baseURI(), _tokenId.toString()));
        } else {
            return hiddenMetadataUri;
        }
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function mint(uint256 tokens) external payable {
        require(publicSaleStarted, "Public sale has not started");
        require(totalSupply() + tokens <= maxSupply, "Minting would exceed max supply");
        require(tokens <= maxPerTx, "Must mint less than maxPerTx");
        require(tokens > 0, "Must mint at least one token");
        if (totalSupply() > freeMints) {
            require(price * tokens <= msg.value, "ETH amount is incorrect");
        }

        _safeMint(_msgSender(), tokens);
    }

    function devMint(uint256 tokens) public payable onlyOwner {
        require(totalSupply() + tokens <= maxSupply, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");
        _safeMint(_msgSender(), tokens);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(_msgSender(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }
}