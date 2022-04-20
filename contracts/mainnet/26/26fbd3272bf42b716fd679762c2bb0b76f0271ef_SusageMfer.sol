// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract SusageMfer is Ownable, ERC721A, ReentrancyGuard {
    uint256 public immutable collectionSize;

    uint256 public mintPrice;

    mapping(address => uint256) public presaleList;

    constructor(uint256 collectionSize_) ERC721A("Susage Mfers", "SUSMFERS") {
        collectionSize = collectionSize_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function mint(uint256 quantity) external payable callerIsUser {
        require(
            totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );

        _safeMint(msg.sender, quantity);
        refundIfOver(mintPrice * quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function setMintPrice(uint64 mintPriceWei) external onlyOwner {
        mintPrice = mintPriceWei;
    }

    // For marketing etc.
    function devMint(uint256 quantity) external onlyOwner {
        _safeMint(msg.sender, quantity);
    }

    // // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }
}