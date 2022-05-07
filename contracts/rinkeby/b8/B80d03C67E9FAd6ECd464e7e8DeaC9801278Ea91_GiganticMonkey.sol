// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract GiganticMonkey is Ownable, ERC721A, ReentrancyGuard {
    string public constant uriSuffix = ".json";
    uint256 public collectionSize = 8888;
    uint256 public maxPerAddressDuringMint = 4;

    // used for giveaways

    uint256 public amountForDevs = 444;


    struct SaleConfig {

        uint32 allowListSaleStartTime;

        uint32 publicSaleStartTime;

        uint64 allowListPrice;

        uint64 publicPrice;
    }

    SaleConfig public saleConfig;


    mapping(address => uint256) public allowlist;


    // Name, Symbol, Max batch size, collection size.
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC721A(_tokenName, _tokenSymbol) {

        require(
            amountForDevs % maxPerAddressDuringMint == 0,
            "dev mints must be multiple of maxPerAddressDuringMint"
        );

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function publicSaleMint(uint256 quantity) external payable callerIsUser {
        uint256 publicPrice = uint256(saleConfig.publicPrice);
        uint256 publicSaleStartTime = uint256(saleConfig.publicSaleStartTime);

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
        refundIfOver(publicPrice * quantity);
        _safeMint(msg.sender, quantity);
    }


    function allowlistMint() external payable callerIsUser {
        require(
            isAllowListSaleOn(),
            "white list sale has not begun yet or has ended"
        );
        uint256 price = uint256(saleConfig.allowListPrice);
        require(price != 0, "white list sale has not begun yet or has ended");
        require(allowlist[msg.sender] > 0, "not eligible for white list mint");
        require(totalSupply() + 1 <= collectionSize, "reached max supply");
        if (allowlist[msg.sender] == 1) {
            delete allowlist[msg.sender];
        } else {
            allowlist[msg.sender]--;
        }
        refundIfOver(price);
        _safeMint(msg.sender, 1);
    }


    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function isPublicSaleOn(uint256 publicPriceWei, uint256 publicSaleStartTime)
        public
        view
        returns (bool)
    {
        return publicPriceWei != 0 && block.timestamp >= publicSaleStartTime;
    }


    function isAllowListSaleOn() public view returns (bool) {
        uint256 _allowListStartTime = uint256(
            saleConfig.allowListSaleStartTime
        );
        return
            _allowListStartTime != 0 && block.timestamp >= _allowListStartTime;
    }


    // Mint for marketing and giveaways

    function devMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= amountForDevs,
            "too many already minted before dev mint"
        );
        require(
            quantity % maxPerAddressDuringMint == 0,
            "can only mint a multiple of the maxPerAddressDuringMint"
        );
        uint256 numChunks = quantity / maxPerAddressDuringMint;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxPerAddressDuringMint);
        }
    }


    function endAuctionAndSetupNonAuctionSaleInfo(
        uint64 allowListPriceWei,
        uint64 publicPriceWei,
        uint32 publicSaleStartTime
    ) external onlyOwner {
        saleConfig = SaleConfig(
            0, //allow list sale start time
            publicSaleStartTime,
            allowListPriceWei,
            publicPriceWei
        );
    }


    function setAllowListPrice(uint64 allowListPriceWei) external onlyOwner {
        saleConfig.allowListPrice = allowListPriceWei;
    }

    function setAllowListSaleStartTime(uint32 timestamp) external onlyOwner {
        saleConfig.allowListSaleStartTime = timestamp;
    }


    function setPublicPrice(uint64 publicPriceWei) external onlyOwner {
        saleConfig.publicPrice = publicPriceWei;
    }

    function setPublicSaleStartTime(uint32 timestamp) external onlyOwner {
        saleConfig.publicSaleStartTime = timestamp;
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


    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721AMetadata: URI query for nonexistant token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        uriSuffix
                    )
                )
                : "";
    }

    // metadata URI
    string private _baseTokenURI = "ipfs://__CID__/hidden.json";

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney(uint256 amount_) external onlyOwner {
        require(
            address(this).balance >= amount_,
            "Address: insufficient balance"
        );
        (bool toCreatorLab, ) = payable(
              0x3A4B8b78bd9CBdb0Bd6a089eaD6E6e6b59600F91
        ).call{value: (amount_ * 7 ) / 100}("");
        require(toCreatorLab);
        (bool success, ) = msg.sender.call{value: (amount_ * (100 - 7)) / 100}("");
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