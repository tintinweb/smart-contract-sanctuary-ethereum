// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract DontBuyGoblins is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public price = 0.002 ether;

    uint256 public maxSupply = 4000;

    uint256 public maxPerTx = 10;

    uint256 public maxPerWallet = 80;

    uint256 public maxFreeAmount = 2222;

    uint256 public maxFreePerWallet = 20;

    bool public mintEnabled;

    bool public revealed;

    string public baseURI;

    string public unrevealedURI;

    mapping(address => uint256) private _mintedFreeAmount;

    constructor() ERC721A("Dont buy Goblin or ill doit", "DBGorilldoit") {
        _safeMint(msg.sender, 10);
    }

    function mint(uint256 amount) external payable {
        uint256 cost = price;
        bool free = ((totalSupply() + amount < maxFreeAmount + 1) &&
            (_mintedFreeAmount[msg.sender] + amount <= maxFreePerWallet));
        if (free) {
            cost = 0;
        }

        require(msg.value >= amount * cost, "Please send the exact amount.");
        require(totalSupply() + amount < maxSuply + 1, "No more");
        require(mintEnabled, "Minting is not live yet.");
        require(amount < maxPerTx + 1, "Max per TX reached.");
        require(
            _numberMinted(msg.sender) + amount <= maxPerWallet,
            "Too many per wallet!"
        );

        if (free) {
            _mintedFreeAmount[msg.sender] += amount;
        }

        _safeMint(msg.sender, amount);
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
                : unrevealedURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setUnrevealedURI(string memory uri) public onlyOwner {
        unrevealedURI = uri;
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