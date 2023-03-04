// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./Ownable.sol";

contract TheCats is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public maxSupply = 5555;
    uint256 public maxFreeAmount = 555;
    uint256 public maxFreePerWallet = 2;
    uint256 public price = 0.002 ether;
    uint256 public maxPerTx = 10;
    uint256 public maxPerWallet = 100;
    uint256 public teamReserved = 2;
    bool public mintEnabled = false;
    bool revealed = false;
    string public baseURI;
    string unRevealedURI;
    

    constructor() ERC721A("The Cats", "Cat") {
        _safeMint(msg.sender, teamReserved);
    }

    function mint(uint256 quantity) external payable {
        require(mintEnabled, "Not live");
        require(totalSupply() + quantity < maxSupply + 1, "No more");
        uint256 cost = price;
        uint256 _maxPerWallet = maxPerWallet;

        if (_numberMinted(msg.sender) < maxFreePerWallet && quantity <= maxFreePerWallet&& totalSupply() < maxFreeAmount) {
            _maxPerWallet = maxFreePerWallet;
            cost = 0;
        }

        require(
            _numberMinted(msg.sender) + quantity <= _maxPerWallet,
            "Max per wallet"
        );
        require(msg.value >= quantity * cost, "Please send the exact amount.");
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
        return  revealed ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : unRevealedURI;
    }

    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setUnRevealedURI(string memory uri) public onlyOwner {
        unRevealedURI = uri;
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