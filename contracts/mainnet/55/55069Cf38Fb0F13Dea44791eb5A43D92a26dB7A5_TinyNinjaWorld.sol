// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// ▀▄▀▄▀▄ 小さな忍者の世界 ▄▀▄▀▄▀

// ██████████████████████████████████████████████████████████████████████████████████████████████
// █─▄─▄─█▄─▄█▄─▀█▄─▄█▄─█─▄███▄─▀█▄─▄█▄─▄█▄─▀█▄─▄███▄─▄██▀▄─████▄─█▀▀▀█─▄█─▄▄─█▄─▄▄▀█▄─▄███▄─▄▄▀█
// ███─████─███─█▄▀─███▄─▄█████─█▄▀─███─███─█▄▀─██─▄█─███─▀─█████─█─█─█─██─██─██─▄─▄██─██▀██─██─█
// ▀▀▄▄▄▀▀▄▄▄▀▄▄▄▀▀▄▄▀▀▄▄▄▀▀▀▀▄▄▄▀▀▄▄▀▄▄▄▀▄▄▄▀▀▄▄▀▄▄▄▀▀▀▄▄▀▄▄▀▀▀▀▄▄▄▀▄▄▄▀▀▄▄▄▄▀▄▄▀▄▄▀▄▄▄▄▄▀▄▄▄▄▀▀

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract TinyNinjaWorld is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 555;
    uint256 public mintPrice = .004 ether;
    uint256 public maxPerWallet = 5;
    bool public paused = true;
    string public baseURI;

    constructor(string memory initBaseURI) ERC721A("Tiny Ninja World", "TNW") {
        baseURI = initBaseURI;
    }

    function mint(uint256 amount) external payable {
        require(!paused, "Mint paused");
        require((totalSupply() + amount) <= maxSupply, "Max supply exceeded");
        require(amount <= maxPerWallet, "Max mint per transaction exceeded");
        require(msg.value >= (mintPrice * amount), "Wrong mint price");

        _safeMint(msg.sender, amount);
    }

    function teamMint(uint256 amount) external onlyOwner {
        _safeMint(msg.sender, amount);
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

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function startSale() external onlyOwner {
        paused = !paused;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function setSupply(uint256 newSupply) external onlyOwner {
        maxSupply = newSupply;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transaction failed");
    }
}