// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract AIApeClub is ERC721A, Ownable {
    using Strings for uint256;

    string public baseURI = "https://ipfs.io/ipfs/Qmcy4dT12UXqd2ukW3dPzcNZLcTEsw45PW9sDTGnopLzVV/";
    uint256 public price = 0.004 ether;
    uint256 public maxPerTx = 10;
    uint256 public totalFree = 1500;
    uint256 public maxSupply = 4000;
    uint256 public maxPerWallet = 80;
    uint256 public maxFreePerWallet = 20;
    bool public mintEnabled = true;
    mapping(address => uint256) private _mintedFreeAmount;

    constructor() ERC721A("AI Ape Club", "AAC") {
        _safeMint(msg.sender, 5);
    }

    function mint(uint256 amt) external payable {
        uint256 cost = price;
        bool isFree = (totalSupply() + amt < totalFree + 1) &&
            (_mintedFreeAmount[msg.sender] + amt <= maxFreePerWallet);
        if (isFree) {
            cost = 0;
        }

        require(msg.value >= amt * cost, "Please send the exact amount.");
        require(totalSupply() + amt < maxSuply + 1, "No more");
        require(mintEnabled, "Minting is not live yet");
        require(amt < maxPerTx + 1, "Max per TX reached.");
        require(
            _numberMinted(msg.sender) + amt <= maxPerWallet,
            "Too many per wallet!"
        );

        if (isFree) {
            _mintedFreeAmount[msg.sender] += amt;
        }

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
            string(
                abi.encodePacked(
                    baseURI,
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        totalFree = amount;
    }

    function setMaxFreePerWallet(uint256 _num) external onlyOwner {
        maxFreePerWallet = _num;
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