// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./Ownable.sol";

contract OpepenPFP is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public maxSupply = 5555;
    uint256 public maxFreeAmount = 2000;
    uint256 public price = 0.001 ether;
    uint256 public maxPerTx = 10;
    uint256 public maxPerWallet = 50;
    uint256 public maxFreePerWallet = 5;
    bool public mintEnabled = true;
    string public baseURI;

    constructor() ERC721A("Opepen PFP", "PEPE") {}

    function publicMint(uint256 quantity) external payable {
        require(mintEnabled, "Minting is not live yet.");
        require(totalSupply() + quantity < maxSuply + 1, "No more");
        uint256 cost = getPrice();
        uint256 _maxPerWallet = maxPerWallet;
        if (cost == 0) {
            _maxPerWallet = maxFreePerWallet;
        }
        require(
            _numberMinted(msg.sender) + quantity <= _maxPerWallet,
            "Max per wallet"
        );
        require(msg.value >= quantity * cost, "Please send the exact amount.");
        _safeMint(msg.sender, quantity);
    }

    function getPrice() public view returns (uint256) {
        uint256 minted = totalSupply();
        uint256 cost = 0;
        if (minted < maxFreeAmount) {
            cost = 0;
        } else {
            cost = 0.002 ether;
        }
        return cost;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
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

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
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