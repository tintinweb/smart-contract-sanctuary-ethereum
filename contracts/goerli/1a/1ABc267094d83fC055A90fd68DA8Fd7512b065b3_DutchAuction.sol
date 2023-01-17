//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./components/WhitelistedAddresses.sol";
import "./components/IsPausable.sol";
import "./components/PriceGetter.sol";
import "./components/PriceDecrease.sol";
import "./interfaces/IOuterRingNFT.sol";

/// @title Dutch Auction Smart Contract
/// @author eludius18lab
/// @notice Dutch Auction --> MarketPlace
/// @dev This Contract will be used to create and Bid NFTs Dutch Auction

//============== DUTCH AUCTION ==============

contract DutchAuction is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    WhitelistedAddresses,
    IsPausable,
    PriceGetter,
    PriceDecrease,
    IERC721ReceiverUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    //============== STRUCTS ==============

    struct Auction {
        uint256 endTime;
        uint256 auctionStart; 
        uint256 startPrice;
        uint256 minPrice;
        address nftSeller;
        address nftContractAddress;
        uint256 tokenId;
        AuctionState aucState;
        address ERC20Token;
        address feeRecipients;
        uint32 feePercentages;
        address bidder;
        uint256 payedPrice;
    }

    struct AuctionTime {
        bool active;
        uint256 price;
    }

    struct AuctionTimming {
        address nftContractAddress;
        uint256 tokenId;
        uint256 deadlineTime;
        uint256 decreasePeriod;
    }

    //============== MAPPINGS ==============

    enum AuctionState { 
        OPEN,
        ENDED
    }
    
    mapping(address => mapping(uint256 => Auction)) public nftContractAuctions;
    mapping(address => mapping(uint256 => AuctionTimming)) public nftContractAuctionTimming;
    mapping(uint256 => mapping(uint256 => AuctionTime)) public mapAuctionTime;

    //============== VARIABLES ==============

    uint32 public defaultFeePercentages;
    address public defaultFeeRecipient;
    uint32 public firstOwnerFeePercentage;
    uint32 public defaultminPricePercentatge;
    bool public initialized;
    
    //============== ERRORS ==============

    error NotNFTOwner();
    
    //============== EVENTS ==============

    event NftAuctionCreated(
        uint256 endTime,
        uint256 auctionStart,
        uint256 startPrice,
        uint256 minPrice,
        address nftSeller,
        address nftContractAddress,
        uint256 tokenId,
        address ERC20Token
    );

    event BidMade(
        address nftContractAddress,
        uint256 tokenId,
        address bidder,
        address erc20Token,
        uint256 payedPrice
    );

    event NFTTransferredAndSellerPaid(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        uint256 payedPrice,
        address bidder
    );

    event ChangedDefaultFeePercentages(uint32 newFee);
    event ChangedDefaultFeeRecipient(address newFee);
    event ChangedFirstOwnerFeePercentage(uint32 newFee);
    event ChangeddefaultminPricePercentatge(uint32 newminPricePercentatge);

    //============== MODIFIERS ==============

    modifier isPercentageInBounds(uint256 percentage) {
        require(
            percentage >= 0 && percentage <= 10000,
            "Error: incorrect percentage"
        );
        _;
    }

    modifier auctionOngoing(address nftContractAddress, uint256 tokenId) {
        require(
            _getAuctionState(nftContractAddress, tokenId) == AuctionState.OPEN,
            "Auction it's not available"
        );
        _;
    }

    modifier auctionEnded(address nftContractAddress, uint256 tokenId) {
        require (
            _getAuctionState(nftContractAddress, tokenId) == AuctionState.ENDED, 
            "Auction has not ended"
        );
        _;
    }

    modifier notNftSeller(address nftContractAddress, uint256 tokenId) {
        require(
            msg.sender !=
                nftContractAuctions[nftContractAddress][tokenId].nftSeller,
            "Owner cannot bid on own NFT"
        );
        _;
    }

    modifier isInitialized() {
        require(initialized, "Error: contract not initialized");
        _;
    }

    modifier isNftSeller(address nftContractAddress, uint256 tokenId) {
        require(
            msg.sender == 
                nftContractAuctions[nftContractAddress][tokenId].nftSeller,
            "Only NFT Seller if there are no Bids"
        );
        _;
    }

    modifier doesBidMeetBidRequirements(
        address nftContractAddress,
        uint256 tokenId,
        uint256 payedPrice
    ) {
        require(payedPrice >= getCurrentPrice(nftContractAddress, tokenId),"Set the current Price");
        _;
    }

    modifier isNFTOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        if (spender != IERC721Upgradeable(nftAddress).ownerOf(tokenId)) {
            revert NotNFTOwner();
        }
        _;
    }

    modifier miniumPriceMeetRequirements(
        uint256 startPrice,
        uint256 minPrice
    ) {
        require(
            minPrice <= _getPortion(startPrice, defaultminPricePercentatge) &&
            minPrice > 0 &&
            startPrice > minPrice,
            "Error: incorrect Price difference"
        );
        _;
    }

    modifier outerRingNFTHasFirstOwner(address nftAddress, uint256 tokenId) {
        if (outerRingNFTs[nftAddress]) {
            require(
                IOuterRingNFT(nftAddress).getFirstOwner(tokenId) != address(0),
                "first owner must be != 0"
            );
        }
        _;
    } 

    //============== CONSTRUCTOR ==============

    constructor() {
        _disableInitializers();
    }

    //============== INITIALIZE ==============
    function initialize(
        uint32 defaultFeePercentages_,
        address defaultFeeRecipient_,
        uint32 firstOwnerFeePercentage_,
        uint32 defaultminPricePercentatge_,
        address aggregatorAddress

    ) 
        external 
        initializer
        isPercentageInBounds(defaultFeePercentages_)
        isPercentageInBounds(firstOwnerFeePercentage_)
    {
        __Ownable_init();
        ///TODO Change to mainnet before deploy
        __PriceGetter_init(aggregatorAddress);
        __WhitelistedAddresses_init();
        __IsPausable_init();
        require(
            defaultFeeRecipient_ != address(0),
            "Error: invalid fee recipient"
        );
        require(aggregatorAddress != address(0), "Error: invalid aggregator");
        require(
            defaultFeePercentages_ + firstOwnerFeePercentage_ <= 10000,
            "Error: incorrect amount"
        );
        defaultFeePercentages = defaultFeePercentages_;
        defaultFeeRecipient = defaultFeeRecipient_;
        firstOwnerFeePercentage = firstOwnerFeePercentage_;
        defaultminPricePercentatge = defaultminPricePercentatge_;
        initialized = true;
    }

    receive() external payable {}

    //============== EXTERNAL FUNCTIONS ==============

    /// Creates a new auction
    /// @param nftContractAddress Contract address that will be put on auction
    /// @param tokenId Identifier of the NFT
    /// @param endTime Time to end the Auction
    /// @param startPrice The start price for the auction
    /// @param minPrice The minimum price to reach
    /// @param decreasePeriod The Period to decrease
    /// @param erc20Token Token used to pay
    function createNewNftAuction(
    address nftContractAddress,
    uint256 tokenId,
    uint256 endTime, 
    uint256 startPrice,
    uint256 minPrice,
    uint256 decreasePeriod,
    address erc20Token
    )
    external
    payable
        whenNotPaused
        isInitialized
        isNFTOwner(nftContractAddress, tokenId, msg.sender)
    {
        _checkAuctionParameters(
            nftContractAddress,
            tokenId,
            startPrice,
            minPrice,
            erc20Token,
            endTime,
            decreasePeriod
        );
        _setupAuction(
            nftContractAddress,
            tokenId,
            endTime, 
            startPrice,
            minPrice,
            decreasePeriod,
            erc20Token
        );
        emit NftAuctionCreated(
            endTime,
            block.timestamp + endTime,
            startPrice,
            minPrice,
            msg.sender,
            nftContractAddress,
            tokenId,
            erc20Token
        );
    }

    /// Makes a new bid with ERC20 token
    /// @param nftContractAddress Contract address on auction
    /// @param tokenId Identifier of the NFT
    /// @param payedPrice The amount of tokens to bid
    function makeBid(
        address nftContractAddress,
        uint256 tokenId,
        uint256 payedPrice
    ) external payable
        whenNotPaused
        nonReentrant
        auctionOngoing(nftContractAddress, tokenId)
        notNftSeller(nftContractAddress, tokenId)
        doesBidMeetBidRequirements(nftContractAddress, tokenId, payedPrice)
    {
        Auction memory nftContractAuction = nftContractAuctions[
            nftContractAddress
        ][tokenId];
        require(nftContractAuction.ERC20Token != address(0), "Only ERC20 Payment");
        _transferNftAndPaySeller(nftContractAddress, tokenId, payedPrice);
        emit BidMade(
            nftContractAddress,
            tokenId,
            msg.sender,
            nftContractAuction.ERC20Token,
            payedPrice
        );
    }

    /// Makes a new bid with BNB
    /// @param nftContractAddress Contract address on auction
    /// @param tokenId Identifier of the NFT
    function makeBNBBid(address nftContractAddress,uint256 tokenId) 
        external payable
        whenNotPaused
        nonReentrant
        auctionOngoing(nftContractAddress, tokenId)
        notNftSeller(nftContractAddress, tokenId)
        doesBidMeetBidRequirements(nftContractAddress, tokenId, msg.value)
    {
        Auction memory nftContractAuction = nftContractAuctions[
            nftContractAddress
        ][tokenId];
        require(nftContractAuction.ERC20Token == address(0), "Only BNB Payment");
        _transferNftAndPaySeller(nftContractAddress, tokenId, msg.value);
        emit BidMade(
            nftContractAddress,
            tokenId,
            msg.sender,
            nftContractAuction.ERC20Token,
            msg.value
        );
    }

    /// Settles the auction
    /// @param nftContractAddress Contract address on auction
    /// @param tokenId Identifier of the NFT
    function settleAuction(address nftContractAddress, uint256 tokenId)
    external
        whenNotPaused
        auctionEnded(nftContractAddress, tokenId)
        isNftSeller(nftContractAddress, tokenId)
    {
        Auction memory nftContractAuction = nftContractAuctions[
            nftContractAddress
        ][tokenId];
        _resetAuction(nftContractAddress, tokenId);
        IERC721Upgradeable(nftContractAddress).safeTransferFrom(
            address(this),
            nftContractAuction.nftSeller,
            tokenId
        );
    }

    /// Change the default fee percentage
    /// @param newDefaultFeePercentages New fee percentage
    function changeDefaultFeePercentages(uint32 newDefaultFeePercentages)
    external
        onlyOwner
        isPercentageInBounds(newDefaultFeePercentages)
    {
        defaultFeePercentages = newDefaultFeePercentages;
        emit ChangedDefaultFeePercentages(defaultFeePercentages);
    }

    /// Change the default fee recipient
    /// @param newDefaultFeeRecipient New address for recipient
    function changeDefaultFeeRecipient(address newDefaultFeeRecipient)
    external
        onlyOwner
    {
        require(
            newDefaultFeeRecipient != address(0),
            "fee recipient must be != address(0)"
        );
        defaultFeeRecipient = newDefaultFeeRecipient;
        emit ChangedDefaultFeeRecipient(defaultFeeRecipient);
    }

    /// Change the first owner fee
    /// @param newFirstOwnerFeePercentage New fee percentage for first owner
    function changeFirstOwnerFeePercentage(uint32 newFirstOwnerFeePercentage)
    external
        onlyOwner
        isPercentageInBounds(newFirstOwnerFeePercentage)
    {
        firstOwnerFeePercentage = newFirstOwnerFeePercentage;
        emit ChangedFirstOwnerFeePercentage(firstOwnerFeePercentage);
    }

    /// Change default minium price percentatge
    /// @param newdefaultminPricePercentatge New default minium price percentatge
    function changeDefaultminPricePercentatge(uint32 newdefaultminPricePercentatge)
    external
        onlyOwner
        isPercentageInBounds(newdefaultminPricePercentatge)
    {
        defaultminPricePercentatge = newdefaultminPricePercentatge;
        emit ChangeddefaultminPricePercentatge(defaultminPricePercentatge);
    }

    
    /// Change or add the data time and price for auction
    /// @param endTime Time to end the Auction
    /// @param active Status of the auction
    /// @param price Fee price for aditional period
    function changeAuctionTimeMap(
        uint256 endTime,
        uint256 decreasePeriod,
        bool active,
        uint256 price
    ) external onlyOwner {
        AuctionTime storage auctionTime = mapAuctionTime[endTime][decreasePeriod];
        auctionTime.active = active;
        auctionTime.price = price;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    //============== INTERNAL FUNCTIONS ==============

    /// Get funtion to get Auction State
    /// @param nftContractAddress Contract address that will be put on auction
    /// @param tokenId Identifier of the NFT
    function _getAuctionState(
        address nftContractAddress,
        uint256 tokenId
    ) public view returns(AuctionState) {
        
        if(block.timestamp >= nftContractAuctionTimming[nftContractAddress][tokenId].deadlineTime) {
            return AuctionState.ENDED;
        }else{
            return AuctionState.OPEN;
        } 
    }

    /// Get funtion to get End Auction Time
    /// @param nftContractAddress Contract address that will be put on auction
    /// @param tokenId Identifier of the NFT
    function getendTime(address nftContractAddress, uint256 tokenId) external view returns(uint){
        return nftContractAuctionTimming[nftContractAddress][tokenId].deadlineTime;
    }

    /// Get funtion to get Start Price
    /// @param nftContractAddress Contract address that will be put on auction
    /// @param tokenId Identifier of the NFT
    function getStartPrice(address nftContractAddress, uint256 tokenId) external view returns(uint256){
        return nftContractAuctions[nftContractAddress][tokenId].startPrice;
    }

    /// Get funtion to get min Bid Price decreased
    /// @param nftContractAddress Contract address that will be put on auction
    /// @param tokenId Identifier of the NFT
    function getminPrice(address nftContractAddress, uint256 tokenId) external view returns(uint256){
        return nftContractAuctions[nftContractAddress][tokenId].minPrice;
    }

    /// Get function to get due time in auction
    /// @param nftContractAddress Contract address that will be put on auction
    /// @param tokenId Identifier of the NFT
    function getDueAuctionTime(address nftContractAddress, uint256 tokenId) external view returns(uint256){
        AuctionTimming memory nftContractAuctionTimmings = nftContractAuctionTimming
        [nftContractAddress][tokenId];
        return nftContractAuctionTimmings.deadlineTime - block.timestamp;
    }
    /// Get function to get Current Price
    /// @param nftContractAddress Contract address that will be put on auction
    /// @param tokenId Identifier of the NFT
    function getCurrentPrice(address nftContractAddress, uint256 tokenId) public view returns(uint256){
        Auction memory nftContractAuction = nftContractAuctions
        [nftContractAddress][tokenId];
        AuctionTimming memory nftContractAuctionTimmings = nftContractAuctionTimming
        [nftContractAddress][tokenId];
        if (_getAuctionState(nftContractAddress, tokenId) == AuctionState.OPEN){
            if ((block.timestamp - nftContractAuction.auctionStart) > nftContractAuctionTimmings.decreasePeriod){
                uint256 amountToDecrease = 
                getDecreasePrice(nftContractAuction.startPrice, 
                                nftContractAuction.minPrice, 
                                nftContractAuctionTimmings.deadlineTime, 
                                nftContractAuction.auctionStart, 
                                nftContractAuctionTimmings.decreasePeriod
                );
                if ((nftContractAuctionTimmings.deadlineTime - nftContractAuctionTimmings.decreasePeriod) >= block.timestamp){
                    return nftContractAuction.startPrice - amountToDecrease;
                }else{
                    return nftContractAuction.minPrice;
                }
            }
            return nftContractAuction.startPrice;
        }
        return 0;
    }

    /// Auxiliar function to get portion
    /// @param totalBid The last bid
    /// @param percentage Quantity to extract from totalBid
    function _getPortion(uint256 totalBid, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        return (totalBid * (percentage)) / 10000;
    }

    /// Internal function to set up the auction data
    /// @param nftContractAddress Contract address that will be put on auction
    /// @param tokenId Identifier of the NFT
    /// @param endTime Time to end the Auction
    /// @param startPrice The start price for the auction
    /// @param minPrice The minimum price to reach
    /// @param decreasePeriod The Period to decrease
    /// @param erc20Token Token used to pay
    function _setupAuction(
        address nftContractAddress,
        uint256 tokenId,
        uint256 endTime, 
        uint256 startPrice,
        uint256 minPrice,
        uint256 decreasePeriod,
        address erc20Token

    )   internal{
        Auction storage nftContractAuction = nftContractAuctions[
            nftContractAddress
        ][tokenId];
        AuctionTimming storage nftAuctionTimming = nftContractAuctionTimming[
            nftContractAddress][tokenId];
        nftContractAuction.nftContractAddress = nftContractAddress;
        nftContractAuction.tokenId = tokenId;
        nftContractAuction.endTime = (endTime);
        nftContractAuction.auctionStart =  block.timestamp;
        nftContractAuction.startPrice = startPrice;
        nftContractAuction.minPrice = minPrice;
        nftContractAuction.ERC20Token = erc20Token;
        nftContractAuction.nftSeller = msg.sender;
        nftContractAuction.feeRecipients = defaultFeeRecipient;
        nftContractAuction.feePercentages = defaultFeePercentages;
        nftContractAuctions[nftContractAddress][tokenId].aucState == AuctionState.OPEN;
        nftAuctionTimming.nftContractAddress = nftContractAddress;
        nftAuctionTimming.tokenId = tokenId;
        nftAuctionTimming.deadlineTime = (block.timestamp + endTime);
        nftAuctionTimming.decreasePeriod = decreasePeriod;
        IERC721Upgradeable(nftContractAddress).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );
    }

    /// Internal function to check internal Parameters
    /// @param nftContractAddress Contract address that will be put on auction
    /// @param tokenId Identifier of the NFT
    /// @param erc20Token Token used to pay
    /// @param endTime Time to end the Auction
    /// @param decreasePeriod The Period to decrease
    function _checkAuctionParameters(
        address nftContractAddress,
        uint256 tokenId,
        uint256 startPrice,
        uint256 minPrice,
        address erc20Token,
        uint256 endTime,
        uint256 decreasePeriod
    )   internal
        isWhitelistedToken(erc20Token)
        isWhitelistedNFT(nftContractAddress)
        outerRingNFTHasFirstOwner(nftContractAddress, tokenId)
        miniumPriceMeetRequirements(startPrice, minPrice)
    {
        AuctionTime memory auctionTime = mapAuctionTime[endTime][decreasePeriod];
        require(auctionTime.active, "Not a valid bid period");
        _auctionTimePayment(auctionTime.price);
    }

    /// Internal function for payment the comission depending on auction period
    /// @param price The price that user has to pay
    function _auctionTimePayment(uint256 price) internal {
        if (price > 0) {
            uint256 comission = convertBNBToBUSD(price);
            require(msg.value == comission, "Not enough BNB");
            (bool success, ) = payable(defaultFeeRecipient).call{
                value: comission
            }("");
            require(success, "error sending");
        }
    }

    /// Internal function to reset the auction data
    /// @param nftContractAddress Contract address auctioned
    /// @param tokenId Identifier of the NFT
    function _resetAuction(address nftContractAddress, uint256 tokenId)
        internal
    {
        Auction storage nftContractAuction = nftContractAuctions[
            nftContractAddress
        ][tokenId];
        AuctionTimming storage nftAuctionTimming = nftContractAuctionTimming[
            nftContractAddress
        ][tokenId];
        nftContractAuction.nftContractAddress = address(0);
        nftContractAuction.tokenId = 0;
        nftContractAuction.startPrice = 0;
        nftContractAuction.minPrice = 0;
        nftContractAuction.endTime = 0;
        nftContractAuction.auctionStart = 0;
        nftContractAuction.nftSeller = address(0);
        nftContractAuction.aucState = AuctionState.ENDED;
        nftContractAuction.ERC20Token = address(0);
        nftContractAuction.feePercentages = 0;
        nftContractAuction.feeRecipients = address(0);
        nftAuctionTimming.nftContractAddress = nftContractAddress;
        nftAuctionTimming.tokenId = tokenId;
        nftAuctionTimming.deadlineTime = 0;
        nftAuctionTimming.decreasePeriod = 0;
    }

    /// Internal function to pay the fees and transfer the NFT to the bidder
    /// @param nftContractAddress Contract address auctioned
    /// @param tokenId Identifier of the NFT
    /// @param payedPrice The Price amount payed
    function _transferNftAndPaySeller(
        address nftContractAddress,
        uint256 tokenId,
        uint256 payedPrice
    ) internal {
        Auction memory nftContractAuction = nftContractAuctions[nftContractAddress][
            tokenId
        ];
        _resetAuction(nftContractAddress, tokenId);
        if (nftContractAuction.ERC20Token != address(0)) {
            IERC20Upgradeable(nftContractAuction.ERC20Token).safeTransferFrom(
                msg.sender,
                address(this),
                payedPrice
            );
        } else {
            (bool success, ) = payable(address(this)).call{value: payedPrice}(
                ""
            );
            require(success, "error sending");
        }
        _payFeesAndSeller(
            nftContractAddress,
            tokenId,
            nftContractAuction.nftSeller,
            nftContractAuction.payedPrice,
            nftContractAuction.ERC20Token
        );
        IERC721Upgradeable(nftContractAddress).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
        emit NFTTransferredAndSellerPaid(
            nftContractAddress,
            tokenId,
            nftContractAuction.nftSeller,
            nftContractAuction.payedPrice,
            msg.sender
        );
    }

    /// Makes payment of the NFT fees
    /// @param nftContractAddress Contract address of the NFT on sale
    /// @param tokenId Identifier of the NFT
    /// @param nftSeller Seller of the NFT who receives the fee
    /// @param payedPrice The Price amount payed
    /// @param erc20Token Token used to pay
    function _payFeesAndSeller(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        uint256 payedPrice,
        address erc20Token
    ) internal {
        uint256 fee = _getPortion(
            payedPrice,
            defaultFeePercentages
        );
        uint256 firstOwnerFee;
        if (outerRingNFTs[nftContractAddress]) {
            firstOwnerFee = _getPortion(
                payedPrice,
                firstOwnerFeePercentage
            );
            _payout(
                IOuterRingNFT(nftContractAddress).getFirstOwner(tokenId),
                firstOwnerFee,
                erc20Token
            );
        }
        _payout(defaultFeeRecipient, fee,erc20Token);
        _payout(
            nftSeller,
            (payedPrice - fee - firstOwnerFee),
            erc20Token
        );
    }

    /// Makes the transfer of the tokens ERC20 or BNB
    /// @param recipient Address that receives tokens
    /// @param amountPaid Amount to transfer
    /// @param auctionERC20Token Token used to pay
    function _payout(
        address recipient,
        uint256 amountPaid,
        address auctionERC20Token
    ) internal {
        if (auctionERC20Token != address(0)) {
            IERC20Upgradeable(auctionERC20Token).safeTransfer(
                recipient,
                amountPaid
            );
        } else {
            (bool success, ) = payable(recipient).call{value: amountPaid}("");
            require(success, "error sending");
        }
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
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

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./IsPausable.sol";

contract WhitelistedAddresses is Initializable, OwnableUpgradeable {
    //============== INITIALIZE ==============

    function __WhitelistedAddresses_init() internal onlyInitializing {
        __WhitelistedAddresses_init_unchained();
    }

    function __WhitelistedAddresses_init_unchained()
        internal
        onlyInitializing
    {}

    //============== EVENTS ==============

    event WhitelistedToken(address indexed tokenaddressToWhitelist);
    event UnWhitelistedToken(address indexed tokenaddressToWhitelist);
    event WhitelistedNFT(address indexed nftToWhitelist);
    event UnWhitelistedNFT(address indexed nftToWhitelist);
    event WhitelistedOuterRingNFT(address indexed nftToWhitelist);
    event UnWhitelistedOuterRingNFT(address indexed nftToWhitelist);

    //============== MAPPINGS ==============

    mapping(address => bool) public whitelistedTokens;
    mapping(address => bool) public whitelistedNFTs;
    mapping(address => bool) public outerRingNFTs;

    //============== MODIFIERS ==============

    modifier isWhitelistedToken(address erc20Token) {
        require(whitelistedTokens[erc20Token], "ERC20 not Whitelisted");
        _;
    }

    modifier isWhitelistedNFT(address nftContractAddress) {
        require(whitelistedNFTs[nftContractAddress], "NFT not Whitelisted");
        _;
    }

    //============== SET FUNCTIONS ==============

    function addTokenToWhitelist(address _tokenAddressToWhitelist)
        external
        onlyOwner
    {
        whitelistedTokens[_tokenAddressToWhitelist] = true;
        emit WhitelistedToken(_tokenAddressToWhitelist);
    }

    function deleteTokenFromWhitelist(address _tokenAddressToWhitelist)
        external
        onlyOwner
    {
        whitelistedTokens[_tokenAddressToWhitelist] = false;
        emit UnWhitelistedToken(_tokenAddressToWhitelist);
    }

    function addNFTToWhitelist(address _nftToWhitelist) external onlyOwner {
        whitelistedNFTs[_nftToWhitelist] = true;
        emit WhitelistedNFT(_nftToWhitelist);
    }

    function deleteNFTFromWhitelist(address _nftToWhitelist)
        external
        onlyOwner
    {
        whitelistedNFTs[_nftToWhitelist] = false;
        emit UnWhitelistedNFT(_nftToWhitelist);
    }

    function addOuterRingNFTToWhitelist(address _nftToWhitelist) external onlyOwner {
        outerRingNFTs[_nftToWhitelist] = true;
        emit WhitelistedOuterRingNFT(_nftToWhitelist);
    }

    function deleteOuterRingNFTFromWhitelist(address _nftToWhitelist)
        external
        onlyOwner
    {
        outerRingNFTs[_nftToWhitelist] = false;
        emit UnWhitelistedOuterRingNFT(_nftToWhitelist);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract IsPausable is Initializable, OwnableUpgradeable {

    //============== INITIALIZE ==============
    function __IsPausable_init() internal onlyInitializing {
        __IsPausable_init_unchained();
    }
  
    function __IsPausable_init_unchained()
      internal
      onlyInitializing
    {
      __Ownable_init();
    }

    //============== EVENTS ==============

    event Paused(address account);
    event Unpaused(address account);

    //============== VARIABLES ==============

    bool private _paused;

    //============== CONSTRUCTOR ==============

    constructor() {
        _paused = false;
    }

    //============== MODIFIERS ==============

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    //============== VIEW FUNCTIONS ==============

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    //============== INTERNAL FUNCTIONS ==============

    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    //============== EXTERNAL FUNCTIONS ==============

    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }


    function unpause() external onlyOwner {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceGetter is Initializable, OwnableUpgradeable {
    event AggregatorChanged(address aggregatorAddress);

    //============== INITIALIZE ==============

    function __PriceGetter_init(address aggregatorAddress)
        internal
        onlyInitializing
    {
        __PriceGetter_init_unchained(aggregatorAddress);
    }

    function __PriceGetter_init_unchained(address aggregatorAddress)
        internal
        onlyInitializing
    {
        bnbBusdPriceFeed = AggregatorV3Interface(aggregatorAddress);
    }

    //============== VARIABLES ==============

    AggregatorV3Interface internal bnbBusdPriceFeed;

    function changeAggregatorInterface(address aggregatorAddress)
        external
        onlyOwner
    {
        bnbBusdPriceFeed = AggregatorV3Interface(aggregatorAddress);
        emit AggregatorChanged(aggregatorAddress);
    }

    //============== GET FUNCTIONS ==============

    function getBnbBusd() public view returns (uint256) {
        (, int price, , , ) = bnbBusdPriceFeed.latestRoundData();
        return uint256(price);
    }

    //============== CONVERT FUNCTIONS ==============

    function convertBNBToBUSD(uint256 amountInBNB) public view returns (uint256) {
        return (amountInBNB * 1e18) / getBnbBusd();
    }

    function convertBUSDToBNB(uint256 amountInBUSD)
        public
        view
        returns (uint256)
    {
        return (getBnbBusd() * amountInBUSD) / 1e18;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract PriceDecrease is Initializable, OwnableUpgradeable {

    //============== INITIALIZE ==============
    function __PriceDecrease_init() internal onlyInitializing {
        __PriceDecrease_init_unchained();
    }
  
    function __PriceDecrease_init_unchained()
      internal
      onlyInitializing
    {
      __Ownable_init();
    }

    //============== VIEW FUNCTIONS ==============

    function getDecreasePrice(
      uint256 startPrice, 
      uint256 minPrice, 
      uint256 deadlineTime, 
      uint256 auctionStart, 
      uint256 decreasePeriod
    ) 
    public view returns(uint256){
        uint256 decreasesteps = (deadlineTime - auctionStart)/decreasePeriod; //172800/600 = 288
        uint256 stepsToDecrease = (startPrice - minPrice) / (decreasesteps - 1); //10000/287 = 34,84
        uint256 timer = (block.timestamp - auctionStart)/ decreasePeriod; // 172800/600 = 288
        return (timer * stepsToDecrease); // 287*34,84 = 10000
    }

    //============== INTERNAL FUNCTIONS ==============

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IOuterRingNFT is IERC721Upgradeable {
    function getFirstOwner(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}