// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract HazeMonkey is Ownable, ERC721A, ReentrancyGuard {
    uint256 public immutable maxPerAddressDuringMint;
    uint256 public immutable amountForDevs;

    struct SaleConfig {
        uint32 publicSaleStartTime;
        uint64 presalePrice;
        uint64 publicPrice;
    }

    SaleConfig public saleConfig;

    mapping(address => uint256) public presaleList;

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        uint256 amountForDevs_
    ) ERC721A("Haze Monkey Society", "HAZE", maxBatchSize_, collectionSize_) {
        maxPerAddressDuringMint = maxBatchSize_;
        amountForDevs = amountForDevs_;
        require(
            amountForDevs_ <= collectionSize_,
            "larger collection size needed"
        );
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function presaleMint(uint256 quantity) external payable callerIsUser {
        uint256 price = uint256(saleConfig.presalePrice * quantity) ;
        require(price != 0, "presaleList sale has not begun yet");
        require(presaleList[msg.sender] > 0, "not eligible for presaleList mint");
        require(quantity <= presaleList[msg.sender], "Max amount already minted");
        require(totalSupply() + quantity <= collectionSize, "reached max supply");

        presaleList[msg.sender] = presaleList[msg.sender] - quantity;
        _safeMint(msg.sender, quantity);
        refundIfOver(price);
    }

    function publicSaleMint(uint256 quantity) external payable callerIsUser {
        SaleConfig memory config = saleConfig;
        uint256 publicPrice = uint256(config.publicPrice);
        uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);

        require(
            isPublicSaleOn(publicPrice, publicSaleStartTime),
            "public sale has not begun yet"
        );
        require(
            totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );
        require(
            numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
            "can not mint this many"
        );
        _safeMint(msg.sender, quantity);
        refundIfOver(publicPrice * quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function setSaleConfig(
        uint64 presaleListPriceWei,
        uint64 publicPriceWei,
        uint32 publicSaleStartTime
    ) external onlyOwner {
        saleConfig = SaleConfig(
            publicSaleStartTime,
            presaleListPriceWei,
            publicPriceWei
        );
    }

    function isPublicSaleOn(uint256 publicPriceWei, uint256 publicSaleStartTime)
        public
        view
        returns (bool)
    {
        return publicPriceWei != 0 && block.timestamp >= publicSaleStartTime;
    }

    function seedPresalelist(
        address[] memory addresses,
        uint256 numSlots
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            presaleList[addresses[i]] = numSlots;
        }
    }

    // For marketing etc.
    function devMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= amountForDevs,
            "too many already minted before dev mint"
        );
        require(
            quantity % maxBatchSize == 0,
            "can only mint a multiple of the maxBatchSize"
        );
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
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

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}