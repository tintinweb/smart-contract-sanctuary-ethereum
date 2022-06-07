// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------------------
// |  .d8888b. 888b    888 d888  8888888888                                  d88888888888 |
// | d88P  Y88b8888b   888d8888  888                                        d88888  888   |
// | 888    88888888b  888  888  888                                       d88P888  888   |
// | 888    888888Y88b 888  888  8888888 .d88b. 888d888 .d8888b .d88b.    d88P 888  888   |
// | 888    888888 Y88b888  888  888    d88""88b888P"  d88P"   d8P  Y8b  d88P  888  888   |
// | 888    888888  Y88888  888  888    888  888888    888     88888888 d88P   888  888   |
// | Y88b  d88P888   Y8888  888  888    Y88..88P888    Y88b.   Y8b.    d8888888888  888   |
// |  "Y8888P" 888    Y8888888888888     "Y88P" 888     "Y8888P "Y8888d88P     8888888888 |
// ----------------------------------------------------------------------------------------                                                                                                

pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract OniForceAI is ERC721A, Ownable {

  using Strings for uint256;
  string public           baseURI;
  uint256 public constant maxSupply         = 10000;
  uint256 public constant freeSupply        = 2500;
  uint256 public          price             = 0.001 ether;
  uint256 public          maxFreePerWallet  = 2;
  uint256 public          maxPerWallet      = 10;
  bool public             mintEnabled       = false;

  mapping(address => uint256) private _walletFreeMints;
  mapping(address => uint256) private _walletMints;

  constructor() ERC721A("0N1ForceAI", "0N1"){
      _safeMint(msg.sender, 1);
  }

  function mint(uint256 amt) external payable {
    require(mintEnabled, "Minting is not live yet.");
    require(msg.sender == tx.origin,"No bots, only true 0N1!");
    require(totalSupply() + amt < maxSupply + 1, "Not enough 0N1 left.");
    require(_walletMints[_msgSender()] + amt < maxPerWallet + 1, "That's enough 0N1 for you!");
    require(msg.value >= amt * price,"Please send the exact amount.");

    _walletMints[_msgSender()] += amt;
    _safeMint(msg.sender, amt);
  }

    function freeMint(uint256 amt) external {
        require(mintEnabled, "Minting is not live yet.");
        require(msg.sender == tx.origin,"No bots, only true 0N1!");
        require(totalSupply() + amt < freeSupply + 1, "Not enough Free 0N1 left.");
        require(_walletFreeMints[_msgSender()] + amt < maxFreePerWallet + 1, "That's enough Free 0N1 for you!");

        _walletFreeMints[_msgSender()] += amt;
        _safeMint(msg.sender, amt);
   }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

	  string memory currentBaseURI = _baseURI();
	  return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : ".json";
  }

  function toggleMinting() external onlyOwner {
      mintEnabled = !mintEnabled;
  }

  function numberMinted(address owner) public view returns (uint256) {
      return _numberMinted(owner);
  }

  function setBaseURI(string calldata baseURI_) external onlyOwner {
      baseURI = baseURI_;
  }

  function setMaxFreePerWallet(uint256 maxFreePerWallet_) external onlyOwner {
      maxFreePerWallet = maxFreePerWallet_;
  }

  function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
    maxPerWallet = maxPerWallet_;
  }

  function setPrice(uint256 price_) external onlyOwner {
      price = price_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }
  
  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
    }
}