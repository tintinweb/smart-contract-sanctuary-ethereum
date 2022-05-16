// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract OkayBabybears is ERC721A, Ownable {
    using Strings for uint256;

    string private baseURI;
    uint256 public price = 0.01 ether;
    uint256 public maxPerTx = 20;
    uint256 public maxPerWallet = 60;
    uint256 public totalFree = 1000;
    uint256 public maxSupply = 3000;
    bool public mintEnabled = true;

    constructor() ERC721A("Okay Babybears", "OBB") {
        _safeMint(msg.sender, 5);
    }

    function mint(uint256 amt) external payable {
        uint256 cost = price;
        if (totalSupply() + amt < totalFree + 1) {
            cost = 0;
        }
        require(msg.value >= amt * cost, "Please send the exact amount.");
        require(totalSupply() + amt < maxSupply + 1, "No more bears");
        require(mintEnabled, "Minting is not live yet, hold on bear.");
        require(
            _numberMinted(msg.sender) + amt <= maxPerWallet,
            "Too many per wallet!"
        );
        require(amt < maxPerTx + 1, "Max per TX reached.");
        _safeMint(msg.sender, amt);
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

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        totalFree = amount;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}