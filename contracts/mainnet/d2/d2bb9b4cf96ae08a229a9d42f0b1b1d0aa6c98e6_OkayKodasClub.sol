// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract OkayKodasClub is ERC721A, Ownable {
    using Strings for uint256;

    string private baseURI;

    uint256 public price = 0.002 ether;

    uint256 public maxPerTx = 10;

    uint256 public maxSupply = 5000;

    bool public mintEnabled = true;

    uint256 public maxFreePerWallet = 60;

    uint256 public totalFree = 1000;

    mapping(address => uint256) private _mintedFreeAmount;

    constructor() ERC721A("Okay Kodas Club", "OKC") {}

    function mint(uint256 count) external payable {
        uint256 cost = price;
        bool isFree = ((totalSupply() + count < totalFree + 1) &&
            (_mintedFreeAmount[msg.sender] + count <= maxFreePerWallet));
        if (isFree) {
            cost = 0;
        }
        require(msg.value >= count * cost, "Please send the exact amount.");
        require(totalSupply() + count < maxSuply + 1, "No more bears");
        require(mintEnabled, "Minting is not live yet, hold on bear.");
        require(count < maxPerTx + 1, "Max per TX reached.");
        if (isFree) {
            _mintedFreeAmount[msg.sender] += count;
        }
        _safeMint(msg.sender, count);
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