// SPDX-License-Identifier: MIT
// https://metastaq.mypinata.cloud/ipfs/QmYgsYugp5makRBagkxQ9RG96Q2qGN8jLn29wryrtoey4f/
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract Metastaq is Ownable, ERC721A, ReentrancyGuard {
    uint256 public immutable maxPerAddressDuringMint;
    uint256 public immutable amountForDevs;
    //uint256 public immutable amountForAuctionAndDev;

    struct SaleConfig {
        uint publicSaleStartTime;
        uint64 mintlistPrice;
        uint64 publicPrice;
    }

    SaleConfig public saleConfig;

    mapping(address => uint256) public allowlist;

    // // metadata URI
    string private _baseTokenURI;

    constructor(
        //string memory tokenName,
        //string memory tokenSymbol,
        //uint256 maxBatchSize_,
        //uint256 collectionSize_,
        //uint256 amountForAuctionAndDev_,
        //uint256 amountForDevs_
    ) ERC721A("another fake collection", "AFO", 5, 100) {
        maxPerAddressDuringMint = 5;
        //amountForAuctionAndDev = amountForAuctionAndDev_;
        amountForDevs = 10;
        _baseTokenURI = "https://metastaq.mypinata.cloud/ipfs/QmdgTc5SZFYsHchGxUzhi3shnbp1QKHAirm2CfvywyoBkv/";
        saleConfig.publicSaleStartTime = block.timestamp;
        saleConfig.publicPrice = 10000000000000000;
        // require(
        //     amountForAuctionAndDev_ <= collectionSize_,
        //     "larger collection size needed"
        // );
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function SetupSaleInfo(
        uint64 mintlistPriceWei,
        uint64 publicPriceWei,
        uint32 publicSaleStartTime
    ) external onlyOwner {
        saleConfig = SaleConfig(
            publicSaleStartTime,
            mintlistPriceWei,
            publicPriceWei
        );
    }

    function allowlistMint() external payable callerIsUser {
        uint256 price = uint256(saleConfig.mintlistPrice);
        require(price != 0, "allowlist sale has not begun yet");
        require(allowlist[msg.sender] > 0, "not eligible for allowlist mint");
        require(totalSupply() + 1 <= collectionSize, "reached max supply");
        allowlist[msg.sender]--;
        _safeMint(msg.sender, 1);
        refundIfOver(price);
    }

    function publicSaleMint(uint256 quantity, address to)
        external
        payable
        callerIsUser
    {
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
            numberMinted(to) + quantity <= maxPerAddressDuringMint,
            "can not mint this many"
        );
        _safeMint(to, quantity);
        refundIfOver(publicPrice * quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function isPublicSaleOn(
        uint256 publicPriceWei,
        uint256 publicSaleStartTime
    ) public view returns (bool) {
        return
            publicPriceWei != 0 &&
            block.timestamp >= publicSaleStartTime;
    }

    function seedAllowlist(
        address[] memory addresses,
        uint256[] memory numSlots
    ) external onlyOwner {
        require(
            addresses.length == numSlots.length,
            "addresses does not match numSlots length"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = numSlots[i];
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