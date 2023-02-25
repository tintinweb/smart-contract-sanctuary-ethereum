/**
                 ▄▀▄██▄
                ▐█▐██▀▀▄▄▄▄▄▄▄▄▄▄▄,    ▄▄▄▄
                █████████████████████▄▀████
              ,▓████████████████████████▄▀
             ▄▓███████████████████████████▄
            █▓█████████████████████████████▄
           ▐█▓██████████████████████████████r
           ███████████████▌;▄▀█████QA▄▄██████
          ▐██▓███████████████████▀   /██▀████
          ▓██████████████████████████████▌███▌
          ████▓███████████████████████████▐██▌
          █████▓██████████████████████████████
          ██████▓█████████████████████████████
         ▐███████▓████████████████▓▓██████████L
         ██████████▓▓██████████████████████████
        ██████████████▓▓███████████████████████
       ▄███████████████████▓▓▓██████████████████
      ▐█████████████▀██████▓▀▀▄████▓▓███████████▌
     ╒███████████▀╙██▓████████▄▀██████▓████▐█████▄
     █████▌████████▄▀████▓▓▓▓▓▓█▓▓█▓██▓▓██)███████
    ▐██████▐██████████▓█████████████▓▀▀▀▄██████████
    ███████▌███████████▌▀███████████████▓██████████⌐
   ▐████████▌▀███████████▄▀████████████▓███████▀███▌
   ███████████▄▀████████████▀▀██████████████▀▓▓█████
  ]███████████████████▓██▄▄▄████▄▄█████▓▓▓██▓███████
  ▐██████████████████████████████████████▓██████████═
  ▐███████████████████████████████████▓█████████████
  ▐████████████████████████████████▓████████████████
   ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█████████████████▀
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./Ownable.sol";

contract MoonConnors is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public maxSupply = 3333;
    uint256 public maxFreeAmount = 333;
    uint256 public price = 0.0015 ether;
    uint256 public maxPerTx = 10;
    uint256 public maxPerWallet = 50;
    uint256 public maxFreePerWallet = 2;
    uint256 public teamReserved = 5;
    bool public mintEnabled = false;
    string public baseURI;
    bool public revealed = false;
    string public unRevealedUri;

    constructor() ERC721A("MoonConnors", "MC") {
        _safeMint(msg.sender, teamReserved);
    }

    function mint(uint256 quantity) external payable {
        require(mintEnabled, "Minting is not live yet.");
        require(totalSupply() + quantity < maxSupply + 1, "No more");
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
            cost = price;
        }
        return cost;
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

        return
            revealed
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : unRevealedUri;
    }

    function flipReveal() external onlyOwner {
        revealed = !revealed;
    }

    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function setUnRevealUri(string memory uri) public onlyOwner {
        unRevealedUri = uri;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
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