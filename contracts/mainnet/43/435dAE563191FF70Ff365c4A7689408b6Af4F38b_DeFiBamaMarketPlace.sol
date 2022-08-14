// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721URIStorage.sol";
import "Counters.sol";
import "ERC721.sol";
import "ReentrancyGuard.sol";
import "NFTCollection.sol";

contract DeFiBamaMarketPlace is ReentrancyGuard, IERC721Receiver {
    using Counters for Counters.Counter;
    Counters.Counter private _buyNowtokenIds;
    Counters.Counter private _auctiontokenIds;
    Counters.Counter private _numberOfSalesMade;
    Counters.Counter private _numberOfBidsMade;
    Counters.Counter private _numberOfItemsListed;

    uint256 private totalIncome;
    address payable private owner;
    uint256 private listingPrice;
    uint256 private salesPercentage;
    uint256 private minimumBidIncreasePercentage;
    bool private initialized;

    error NotApprovedForMarketplace();

    enum Category {
        Art, Music, Video, Sports, Collectible, Specialised, Photography, Other
    }

    mapping(uint256 => Market) private buyNowNFTs;
    mapping(address => mapping(uint256 => MarketItem)) private buyNowListing;
    mapping(address => mapping(uint256 => AuctionItem)) private auctionListing;
    mapping(uint256 => Auction) private auctionNFTs;

    struct Market {
        MarketItem _marketItem;
        bool _isDeleted;
    }
    struct Auction {
        AuctionItem _auctionItem;
        bool _isDeleted;
    }
    struct NFT {
        address adr;
        uint256 id;
    }

    struct MarketItem {
        uint256 tokenId;
        address payable owner;
        address payable creator;
        uint256 price;
        uint8 category;
        NFT nft;
        uint256 profession;
    }

    struct AuctionItem {
        uint256 tokenId;
        address payable owner;
        address payable creator;
        uint256 basePrice;
        uint8 category;
        uint256 currentBidPrice;
        address highestBiderAddress;
        uint256 startTime;
        uint256 auctionDurationBasedOnHours;
        NFT nft;
        uint256 profession;
    }

    event buyNowItemSold(
        address buyerAddress, uint256 price, address oldOwner
    );

    event buyNowMarketItemCreated (
        uint256 indexed tokenId,
        address owner,
        address creator,
        uint256 price,
        uint8 category
    );

    event AuctionMarketItemCreated (
        uint256 indexed tokenId,
        address owner,
        address creator,
        uint8 category,
        uint256 currentBidPrice,
        address highestBiderAddress,
        uint256 startTime,
        uint256 auctionDurationBasedOnHours
    );

    event ItemRemovedFromSales(
        uint256 id, address nftAddress, uint256 tokenId
    );

    event BidMade(
        address addressOfBidder, uint256 oldPrice, uint256 newPrice
    );

    event LastTimeAuctionChecked(uint256 time);

    modifier isOwner(address addressOfNFT, uint256 tokenId) {
        IERC721 nft = IERC721(addressOfNFT);
        require(msg.sender == nft.ownerOf(tokenId));
        _;
    }

    function initialize() public {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        owner = payable(msg.sender);
        salesPercentage = 4;
        totalIncome = 0;
        listingPrice = 0;
        minimumBidIncreasePercentage = 5;
    }

    function removeFromMarketSale(uint256 id) nonReentrant public {
        Market storage m = buyNowNFTs[id];
        require(m._marketItem.owner == msg.sender, "Only owner of the NFT can remove the item from marketplace.");

        // Transfer back the NFT from Marketplace to user
        IERC721 nft = IERC721(m._marketItem.nft.adr);
        nft.safeTransferFrom(nft.ownerOf(m._marketItem.nft.id), payable(msg.sender), m._marketItem.nft.id);

        // Remove the nft from market
        delete (buyNowListing[m._marketItem.nft.adr][m._marketItem.nft.id]);
        m._isDeleted = true;
        emit ItemRemovedFromSales(id, m._marketItem.nft.adr, m._marketItem.nft.id);
    }

    function removeFromAuctionSale(uint256 id) nonReentrant public {
        Auction storage a = auctionNFTs[id];
        require(a._auctionItem.owner == msg.sender, "Only owner of the NFT can remove the item from marketplace.");
        // Only remove if there is no bid for item
        require(a._auctionItem.currentBidPrice == 0, "There is a bid for your item, so cannot be removed from marketplace.");

        // Transfer back the NFT from Marketplace to user
        IERC721 nft = IERC721(a._auctionItem.nft.adr);
        nft.safeTransferFrom(nft.ownerOf(a._auctionItem.nft.id), payable(msg.sender), a._auctionItem.nft.id);

        // Remove the nft from market
        delete (auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id]);
        a._isDeleted = true;
        emit ItemRemovedFromSales(id, a._auctionItem.nft.adr, a._auctionItem.nft.id);
    }

    function makeABid(uint256 id) nonReentrant payable public {
        // Get the NFT based on id
        Auction storage a = auctionNFTs[id];
        require(msg.value >= a._auctionItem.basePrice, "The offer must be greater than base price");

        // Check if the auction is finished or not
        uint256 numberOfHours = auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].auctionDurationBasedOnHours * 1 hours;
        uint256 endDate = auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].startTime + numberOfHours;
        require(block.timestamp <= endDate, "The auction is closed now.");

        // Check the bid value and make sure it is valid
        uint256 minimumBidAllowed;
        if (auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].currentBidPrice > 1) {
            minimumBidAllowed = (auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].currentBidPrice) + ((auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].currentBidPrice * minimumBidIncreasePercentage) / 100);
        } else {
            minimumBidAllowed = (auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].basePrice) + ((auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].basePrice * minimumBidIncreasePercentage) / 100);
        }
        require(msg.value >= minimumBidAllowed, "The bid must be at least 5% greater than previous bid.");

        // Check if this is the first bid or not, if not give the money of last bidder back
        if (auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].highestBiderAddress != address(0)) {
            payable(auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].highestBiderAddress).transfer(auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].currentBidPrice);
        }
        emit BidMade(msg.sender, auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].currentBidPrice, msg.value);
        auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].highestBiderAddress = msg.sender;
        auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].currentBidPrice = msg.value;
        auctionNFTs[id]._auctionItem = auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id];
    }

    // Check auction and wrap up finished auctions
    function checkAuctions() nonReentrant external payable {
        emit LastTimeAuctionChecked(block.timestamp);
        uint256 currentId = _auctiontokenIds.current();
        Auction[] memory items = new Auction[](currentId);

        // Loop through all items
        for (uint256 i = 0; i < currentId; i++) {
            Auction storage m = auctionNFTs[i];

            // Make sure is not deleted already
            if (m._isDeleted == false) {
                uint256 numberOfHours =  m._auctionItem.auctionDurationBasedOnHours * 1 hours;
                uint256 endDate =  m._auctionItem.startTime + numberOfHours;
                // if time of block is greater than endDate then auction is finished wrap it up!
                if (block.timestamp > endDate) {

                    // check if there is any bid and if there isn't just delete the auction item
                    AuctionItem storage item =  m._auctionItem;
                    if (item.highestBiderAddress != address(0)) {
                        address payable ownerOfNFT = payable(NFTCollection(m._auctionItem.nft.adr).ownerOf(m._auctionItem.nft.id));

                        // Transfer nft to highest bidder
                        IERC721 nft = IERC721(m._auctionItem.nft.adr);
                        nft.safeTransferFrom(nft.ownerOf(m._auctionItem.nft.id), payable(msg.sender), m._auctionItem.nft.id);

                        // Tranfser the money and commission
                        uint256 amountsTobePaidToOwner = (m._auctionItem.currentBidPrice * (100 - salesPercentage)) / 100;
                        uint256 commision = (m._auctionItem.currentBidPrice * salesPercentage) / 100 ;
                        totalIncome += commision;
                        payable(m._auctionItem.owner).transfer(amountsTobePaidToOwner);
                        owner.transfer(commision);
                        m._auctionItem.owner = payable(m._auctionItem.highestBiderAddress);
                    }
                    delete (auctionListing[m._auctionItem.nft.adr][m._auctionItem.nft.id]);
                    m._isDeleted = true;
                    auctionNFTs[i] = m;
                }
            }
        }
    }
    function buyMarketPlaceItem(uint256 id) nonReentrant public payable {
        Market storage m = buyNowNFTs[id];
        require(msg.value >= m._marketItem.price, "Price must be greater than the price set by the owner.");

        // Transfer the NFT
        IERC721 nft = IERC721(m._marketItem.nft.adr);
        nft.safeTransferFrom(nft.ownerOf(m._marketItem.nft.id), payable(msg.sender), m._marketItem.nft.id);

        // Transfer the price and commission
        uint256 adminFees = (msg.value * salesPercentage) / 100;
        owner.transfer(adminFees);
        totalIncome += adminFees;
        uint256 netPrice = (msg.value * (100 - salesPercentage)) / 100;
        payable(m._marketItem.owner).transfer(netPrice);

        // edit the market item
        m._marketItem.owner = payable(msg.sender);
        m._isDeleted = true;

        // remove the nft from market sale
        delete (buyNowListing[m._marketItem.nft.adr][m._marketItem.nft.id]);
        // increase stats
        _numberOfSalesMade.increment();

        emit buyNowItemSold(msg.sender, msg.value, m._marketItem.owner);
    }

    function listNFTForSaleOnMarket(uint256 price, address addressOfNFT, uint256 tokenId,
     uint8 category, uint256 prefession) isOwner(addressOfNFT, tokenId) nonReentrant public payable {
        require(category <= 10, "Invalid Category");
        require(msg.value >= listingPrice, "Not enough money for listing");
        require(price > 0, "Price must be greater than zero!");

        // Transfer the nft to marketplace
        IERC721 nftContract = IERC721(addressOfNFT);
        if (nftContract.getApproved(tokenId) != address(this)) {
            revert NotApprovedForMarketplace();
        }
        nftContract.safeTransferFrom(nftContract.ownerOf(tokenId), payable(address(this)), tokenId);

        // Create Market Item for the nft
        MarketItem memory m = MarketItem(tokenId, payable(msg.sender), payable(NFTCollection(addressOfNFT).creator()), price, category, NFT(addressOfNFT, tokenId), prefession);
        buyNowListing[addressOfNFT][tokenId] = m;
        buyNowNFTs[_buyNowtokenIds.current()] = Market(m, false);
        _buyNowtokenIds.increment();
        //emit buyNowMarketItemCreated(tokenId, payable(msg.sender), payable(msg.sender), price, category);
    }

    function listNFTForSaleOnAuction(uint256 price, address addressOfNFT, uint256 tokenId,
     uint8 category, uint auctionDurationInHours, uint256 profession) nonReentrant isOwner(addressOfNFT, tokenId) public payable {
        require(category <= 7, "Invalid Category");
        require(msg.value >= listingPrice, "Invalid Market Type");
        require(price > 0, "Price must be greater than zero!");

        // Transfer the nft to marketplace
        IERC721 nftContract = IERC721(addressOfNFT);
        if (nftContract.getApproved(tokenId) != address(this)) {
            revert NotApprovedForMarketplace();
        }
        nftContract.safeTransferFrom(nftContract.ownerOf(tokenId), payable(address(this)), tokenId);
        // Create the nft and execute listing
        NFT memory nft = NFT(addressOfNFT, tokenId);
        listForAuction(price, category, auctionDurationInHours, nft, profession);
    }

    function listForAuction(uint256 price, uint8 category, uint auctionDurationInHours, NFT memory nft, uint256 prefession) private {
        // Create Auction Item
        AuctionItem memory a = AuctionItem(nft.id, payable(msg.sender), payable(msg.sender), price, category, 0, address(0), block.timestamp, auctionDurationInHours, nft, prefession);
        auctionListing[nft.adr][nft.id] = a;
        auctionNFTs[_auctiontokenIds.current()] = Auction(a, false);
        emit AuctionMarketItemCreated(nft.id, payable(msg.sender), payable(msg.sender), category, price, payable(msg.sender), block.timestamp, auctionDurationInHours);
        _auctiontokenIds.increment();
    }

    // Admin functions
    function deleteAuctionItem(uint256 id) public nonReentrant {
        require(owner == msg.sender, "Only marketplace owner can update listing price.");
        Auction storage a = auctionNFTs[id];

        // Transfer back the NFT from Marketplace to user
        // IERC721 nft = IERC721(a._auctionItem.nft.adr);
        // nft.safeTransferFrom(nft.ownerOf(a._auctionItem.nft.id), payable(msg.sender), a._auctionItem.nft.id);

        // Remove the nft from market
        delete (auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id]);
        a._isDeleted = true;
        emit ItemRemovedFromSales(id, a._auctionItem.nft.adr, a._auctionItem.nft.id);
    }

    /* delete an auction and return money to bidder if there is any violations */
    function deleteByNowItem(uint256 id) public nonReentrant {
        require(owner == msg.sender, "Only marketplace owner can update listing price.");
        Market storage m = buyNowNFTs[id];

        // Transfer back the NFT from Marketplace to user
        // IERC721 nft = IERC721(m._marketItem.nft.adr);
        // nft.safeTransferFrom(nft.ownerOf(m._marketItem.nft.id), payable(owner), m._marketItem.nft.id);

        // Remove the nft from market
        delete (buyNowListing[m._marketItem.nft.adr][m._marketItem.nft.id]);
        m._isDeleted = true;
    }

    /* Updates the listing Percentage of the contract */
    function updateListingPrice(uint256 _price) public nonReentrant {
        require(owner == msg.sender, "Only marketplace owner can update listing price.");
        listingPrice = _price;
    }

    /* Returns the listing Percentage of the contract */
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    /* Updates the sales Percentage of the contract */
    function updateSalesPercentage(uint256 _percentage) nonReentrant public {
        require(owner == msg.sender, "Only marketplace owner can update listing price.");
        salesPercentage = _percentage;
    }

    /* Returns the number of sales on the contract */
    function getNumberOfSalesMade() public view returns(uint256) {
        require(owner == msg.sender, "Only marketplace owner can run this.");
        return _numberOfSalesMade.current();
    }

    /* Returns the number of bides made on the contract */
    function getNumberOfBidsMade() public view returns(uint256) {
        require(owner == msg.sender, "Only marketplace owner can run this.");
        return _numberOfBidsMade.current();
    }

    /* Returns the number of items listed on the contract */
    function getNumberOfItemsListed() public view returns(uint256) {
        require(owner == msg.sender, "Only marketplace owner can run this.");
        return _numberOfItemsListed.current();
    }

    /* Returns the money made on the contract */
    function getMoneyMade() public view returns(uint256) {
        require(owner == msg.sender, "Only marketplace owner can run this.");
        return totalIncome;
    }

    /* Returns the sales Percentage of the contract */
    function getSalesPercentage() public view returns (uint256) {
        return salesPercentage;
    }

    /* Returns the current id of Buy Now the contract */
    function getCurrentIdOfBuyNowListing() public view returns (uint256) {
        return _buyNowtokenIds.current();
    }

    /* Returns the current id of Auction the contract */
    function getCurrentIdOfAuctionListing() public view returns (uint256) {
        return _auctiontokenIds.current();
    }
    
    /* Updates the bid Percentage of the contract */
    function updateMinimumBidIncreasePercentage(uint256 _percentage) nonReentrant public {
        require(owner == msg.sender, "Only marketplace owner can update listing price.");
        minimumBidIncreasePercentage = _percentage;
    }

    /* Returns the minimum bid increase percentage the contract */
    function getMinimumBidIncreasePercentage() public view returns(uint256) {
        return minimumBidIncreasePercentage;
    }

    // It must be implemenetd so marketplace place can hold nfts
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /* Withdraw the remaining money on contract */
    function withdrawBalance() nonReentrant public payable {
        require(msg.sender == owner, "Only Market Place Owner can run this command.");
        owner.transfer(address(this).balance);
    }

    // API Functions
    function getListedItemsOnMarket() public view returns(MarketItem[] memory) {
        uint256 currentId = _buyNowtokenIds.current();
        MarketItem[] memory items = new MarketItem[](currentId);
        for (uint256 i = 0; i < _buyNowtokenIds.current(); i++) {
            Market storage m = buyNowNFTs[i];
            if (m._isDeleted == false) {
                items[i] = m._marketItem;
            }
        }
        return items;
    }

    // API Functions
    function getIdsOfListedItemsOnMarket() public view returns(uint256[] memory) {
        uint256 currentId = _buyNowtokenIds.current();
        uint256[] memory items = new uint256[](currentId);
        for (uint256 i = 0; i < _buyNowtokenIds.current(); i++) {
            Market storage m = buyNowNFTs[i];
            if (m._isDeleted == false) {
                items[i] = i;
            }
        }
        return items;
    }

    function getListedItemsOnAuctions() public view returns(AuctionItem[] memory) {
        uint256 currentId = _auctiontokenIds.current();
        AuctionItem[] memory items = new AuctionItem[](currentId);
        for (uint256 i = 0; i < _auctiontokenIds.current(); i++) {
            Auction storage m = auctionNFTs[i];
            if (m._isDeleted == false) {
                items[i] = m._auctionItem;
            }
        }
        return items;
    }

    function getIdsOfListedItemsOnAuctions() public view returns(uint256[] memory) {
        uint256 currentId = _auctiontokenIds.current();
        uint256[] memory items = new uint256[](currentId);
        for (uint256 i = 0; i < _auctiontokenIds.current(); i++) {
            Auction storage m = auctionNFTs[i];
            if (m._isDeleted == false) {
                items[i] = i;
            }
        }
        return items;
    }

    function getBuyNowId() public view returns(uint256) {
        return _buyNowtokenIds.current();
    }

    function getAuctionId() public view returns(uint256) {
        return _auctiontokenIds.current();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC721Metadata.sol";
import "Address.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721.sol";
import "ERC721URIStorage.sol";
import "Counters.sol";

contract NFTCollection is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public creator;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        creator = msg.sender;
    }

    event tokenMinted(string tokenURI, address owner);

    function mintTo(string memory tokenURI)
        external
        returns (uint256)
    {
        //require(creator == msg.sender, "Only owner can mint nft on this address.");
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        _tokenIds.increment();
        emit tokenMinted(tokenURI, msg.sender);
        return newItemId;
    }

    function getCurrentId() public view returns(uint256) {
        return _tokenIds.current();
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        _burn(tokenId);
    }
}