// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Burnable.sol";
import "./SafeMath.sol";
import "./IERC721.sol";

/**
 * @title JPEGERSᵍᵐ Contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract NFT is ERC721Burnable {
    using SafeMath for uint256;
    uint16 private mintedCount;

    string public baseTokenURI;
    uint16 public MAX_SUPPLY;

    uint16 public maxByMint;
    uint256 public mintPrice;

    mapping(address => bool) public freeMintedFromAddress;

    constructor() ERC721("Son of Bitches", "Son of Bitches") {
        MAX_SUPPLY = 10000;
        mintPrice = 0.02 ether;
        maxByMint = 5;
    }

    function mintFree() external {
        require(tx.origin == msg.sender, "Only EOA");
        require(
            !freeMintedFromAddress[msg.sender],
            "Already minted from this address"
        );
        require(totalSupply() < MAX_SUPPLY, "Max Limit To Presale");

        uint16 tokenId = uint16(totalSupply());
        _safeMint(msg.sender, tokenId);
        mintedCount = mintedCount + 1;
        freeMintedFromAddress[msg.sender] = true;
    }

    function mint5NFT() external payable {
        require(tx.origin == msg.sender, "Only EOA");
        require(
            totalSupply() + maxByMint <= MAX_SUPPLY,
            "Max Limit To Presale"
        );

        require(mintPrice <= msg.value, "Low Price To Mint");

        for (uint8 i = 0; i < maxByMint; i += 1) {
            uint16 tokenId = uint16(totalSupply() + i);
            _safeMint(msg.sender, tokenId);
        }
        mintedCount = mintedCount + maxByMint;
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

    function withdraw() public payable onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }
}