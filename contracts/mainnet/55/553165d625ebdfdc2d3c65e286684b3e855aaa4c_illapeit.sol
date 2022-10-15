// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract illapeit is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 10000;

    uint256 public price = 0.005 ether;

    uint256 public maxPerTx = 20;

    uint256 public maxFreeAmount = 3000;

    uint256 public maxFreePerWallet = 10;

    uint256 public maxFreePerTx = 5;

    bool public mintEnabled = true;

    bool public revealed = false;

    string public baseURI;

    string public unrevealedURI="ipfs://QmUZ2ZX4mQPmmTTF8MrxzUe5ZxfxPbtbqNcYysPGrHxkaM";

    mapping(address => uint256) private _mintedFreeAmount;

    constructor() ERC721A("ill ape it", "iai") {
        _safeMint(msg.sender, 10);
    }

    function mint(uint256 amount) external payable {
        uint256 cost = price;
        uint256 num = amount > 0 ? amount : 1;
        bool free = ((totalSupply() + num < maxFreeAmount + 1) &&
            (_mintedFreeAmount[msg.sender] + num <= maxFreePerWallet));
        if (free) {
            cost = 0;
            _mintedFreeAmount[msg.sender] += num;
            require(num < maxFreePerTx + 1, "Max per TX reached.");
        } else {
            require(num < maxPerTx + 1, "Max per TX reached.");
        }

        require(mintEnabled, "Minting is not live yet.");
        require(msg.value >= num * cost, "Please send the exact amount.");
        require(totalSupply() + num < maxSupply + 1, "No more");

        _safeMint(msg.sender, num);
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