// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./Ownable.sol";

contract MegaMcpepes is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public maxSupply = 3333;
    uint256 public maxFreeAmount = 3333;
    uint256 public maxFreePerWallet = 1;
    uint256 public price = 0.002 ether;
    uint256 public maxPerTx = 10;
    uint256 public maxPerWallet = 50;
    uint256 public teamReserved = 2;
    bool public mintEnabled = false;
    string public baseURI;

    constructor() ERC721A("Mega Mcpepes", "MM") {
        _safeMint(msg.sender, teamReserved);
    }

    function publicMint(uint256 quantity) external payable {
        require(mintEnabled, "Minting is not live yet.");
        require(totalSupply() + quantity < maxSupply + 1, "No more");
        uint256 cost = price;
        uint256 _maxPerWallet = maxPerWallet;

        if (
            totalSupply() < maxFreeAmount &&
            _numberMinted(msg.sender) == 0 &&
            quantity <= maxFreePerWallet
        ) {
            cost = 0;
            _maxPerWallet = maxFreePerWallet;
        }

        require(
            _numberMinted(msg.sender) + quantity <= _maxPerWallet,
            "Max per wallet"
        );

        uint256 needPayCount = quantity;
        if (_numberMinted(msg.sender) == 0) {
            needPayCount = quantity - 1;
        }
        require(
            msg.value >= needPayCount * cost,
            "Please send the exact amount."
        );
        _safeMint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setMaxFreeAmount(uint256 _amount) external onlyOwner {
        maxFreeAmount = _amount;
    }

    function setMaxFreePerWallet(uint256 _amount) external onlyOwner {
        maxFreePerWallet = _amount;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}