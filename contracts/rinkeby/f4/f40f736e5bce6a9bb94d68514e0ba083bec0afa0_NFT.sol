// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Burnable.sol";
import "./SafeMath.sol";
import "./IERC721.sol";

/**
 * @title NFT Contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract NFT is ERC721Burnable {
    using SafeMath for uint256;
    uint16 private mintedCount;

    string public baseTokenURI;
    uint16 public MAX_SUPPLY;
    uint16 private reserved = 1000;

    uint8 public minByMint;
    uint256 public mintPrice;

    address private fund1;
    address private fund2 = 0x7DEb1573a405f1DB2a7de1F630e07634B9983776;

    mapping(address => bool) public freeMintedFromAddress;
    mapping(address => bool) public whitelistAddress;

    constructor() ERC721("Son of Gun", "Son of Gun") {
        MAX_SUPPLY = 10000;
        mintPrice = 0.02 ether;
        minByMint = 6;
        fund1 = owner();
    }

    function mintFree() external {
        require(tx.origin == msg.sender, "Only EOA");
        require(
            !freeMintedFromAddress[msg.sender],
            "Already minted from this address"
        );
        require(totalSupply() < MAX_SUPPLY - reserved, "Max Limit To Presale");

        uint256 supply = totalSupply();
        for (uint8 i = 0; i < 2; i += 1) {
            _safeMint(msg.sender, supply + i);
        }
        mintedCount = mintedCount + 2;
        freeMintedFromAddress[msg.sender] = true;
    }

    function mintNFTPayable() external payable {
        require(tx.origin == msg.sender, "Only EOA");
        require(mintPrice <= msg.value, "Low Price To Mint");
        uint8 mintNumber = uint8((msg.value / mintPrice) * minByMint);
        require(
            totalSupply() + mintNumber <= MAX_SUPPLY - reserved,
            "Max Limit To Presale"
        );

        uint256 supply = totalSupply();
        for (uint8 i = 0; i < mintNumber; i += 1) {
            _safeMint(msg.sender, supply + i);
        }
        mintedCount = mintedCount + mintNumber;
    }

    function mintFreeFromWL(uint8 _amount) external {
        require(tx.origin == msg.sender, "Only EOA");
        require(whitelistAddress[msg.sender], "Not Whitelist");
        require(_amount <= 25, "Limit To Presale");
        require(
            totalSupply() + _amount < MAX_SUPPLY - reserved,
            "Max Limit To Presale"
        );

        require(_amount <= reserved, "Exceeds reserved Cat supply");

        uint256 supply = totalSupply();
        for (uint256 i; i < _amount; i++) {
            _safeMint(msg.sender, supply + i);
        }

        mintedCount = mintedCount + _amount;
        freeMintedFromAddress[msg.sender] = false;
    }

    function giveAway(address _to, uint16 _amount) external onlyOwner {
        require(_amount <= reserved, "Exceeds reserved Cat supply");

        uint256 supply = totalSupply();
        for (uint256 i; i < _amount; i++) {
            _safeMint(_to, supply + i);
        }

        mintedCount = mintedCount + _amount;
        reserved -= _amount;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function totalSupply() public view virtual returns (uint16) {
        return mintedCount;
    }

    function setWhitelist(address[] memory addresses) external onlyOwner {
        require(addresses.length > 0, "No Empty");
        for (uint256 i; i < addresses.length; i++) {
            whitelistAddress[addresses[i]] = true;
        }
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        uint256 amount1 = (amount * 8) / 10;
        payable(msg.sender).transfer(amount1);
        payable(msg.sender).transfer(amount - amount1);
    }
}