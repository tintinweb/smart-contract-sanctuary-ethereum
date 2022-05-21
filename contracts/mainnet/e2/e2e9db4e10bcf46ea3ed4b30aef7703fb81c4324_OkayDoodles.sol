// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract OkayDoodles is ERC721A, Ownable {
    using Strings for uint256;

    string public baseURI;
    uint256 public price = 0.005 ether;
    uint256 public maxPerTx = 20;
    uint256 public totalFree = 1000;
    uint256 public maxSupply = 10000;
    uint256 public maxPerWallet = 90;
    uint256 public nextOwnerToExplicitlySet;
    bool public mintEnabled;
    bool public revealed;

    constructor() ERC721A("Okay Doodles", "OKD") {
        _safeMint(msg.sender, 5);
    }

    function mint(uint256 amt) external payable {
        uint256 cost = price;
        if (totalSupply() + amt < totalFree + 1) {
            cost = 0;
        }

        require(msg.value >= amt * cost, "Please send the exact amount.");
        require(totalSupply() + amt < maxSupply + 1, "No more okay Doodles");
        require(mintEnabled, "Minting is not live yet, hold on okay Doodles.");
        require(amt < maxPerTx + 1, "Max per TX reached.");
        require(
            _numberMinted(msg.sender) + amt <= maxPerWallet,
            "Too many per wallet!"
        );

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
        return
            revealed
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "https://ipfs.io/ipfs/QmeVExjsT2y7sqN1UZohCDyE89G2vLipjBcXBxiRJHHEqZ";
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

    function flipReveal() external onlyOwner {
        revealed = !revealed;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}