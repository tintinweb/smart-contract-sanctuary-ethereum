// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/Ieesee.sol";

contract eesee is Ieesee, VRFConsumerBaseV2, ERC721Holder, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    ///@dev An array of all existing listings.
    Listing[] public listings;
    ///@dev An array of all existing drops listings.
    Drop[] public drops;
    ///@dev Maps chainlink request ID to listing ID.
    mapping(uint256 => uint256) private chainlinkRequestIDs;

    ///@dev ESE token this contract uses.
    IERC20 public immutable ESE;
    ///@dev Contract that mints NFTs
    IeeseeMinter public immutable minter;

    ///@dev Min and max durations for a listing.
    uint256 public minDuration = 1 days;
    uint256 public maxDuration = 30 days;
    ///@dev Max tickets bought by a single address in a single listing. [1 ether == 100%]
    //Note: Users can still buy 1 ticket even if this check fails. e.g. there is a listing with only 2 tickets and this is set to 20%.
    uint256 public maxTicketsBoughtByAddress = 0.20 ether;
    ///@dev Fee that is collected to {feeCollector} from each fulfilled listing. [1 ether == 100%]
    uint256 public fee = 0.10 ether;
    ///@dev Address {fee}s are sent to.
    address public feeCollector;
    ///@dev Denominator for fee & maxTicketsBoughtByAddress variables.
    uint256 private constant denominator = 1 ether;

    ///@dev Chainlink token.
    LinkTokenInterface immutable public LINK;
    ///@dev Chainlink VRF V2 coordinator.
    VRFCoordinatorV2Interface immutable public vrfCoordinator;
    ///@dev Chainlink VRF V2 subscription ID.
    uint64 immutable public subscriptionID;
    ///@dev Chainlink VRF V2 key hash to call requestRandomWords() with.
    bytes32 immutable public keyHash;
    ///@dev Chainlink VRF V2 request confirmations.
    uint16 immutable public minimumRequestConfirmations;
    ///@dev Chainlink VRF V2 gas limit to call fulfillRandomWords().
    uint32 immutable private callbackGasLimit;

    ///@dev The Royalty Engine is a contract that provides an easy way for any marketplace to look up royalties for any given token contract.
    IRoyaltyEngineV1 immutable public royaltyEngine;
    ///@dev 1inch router used for token swaps.
    address immutable public OneInchRouter;

    receive() external payable {
        //Reject deposits from EOA
        if (msg.sender == tx.origin) revert EthDepositRejected();
    }

    constructor(
        IERC20 _ESE,
        IeeseeMinter _minter,
        address _feeCollector,
        IRoyaltyEngineV1 _royaltyEngine,
        address _vrfCoordinator, 
        LinkTokenInterface _LINK,
        bytes32 _keyHash,
        uint16 _minimumRequestConfirmations,
        uint32 _callbackGasLimit,
        address _OneInchRouter
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        ESE = _ESE;
        minter = _minter;
        feeCollector = _feeCollector;
        royaltyEngine = _royaltyEngine;

        // ChainLink stuff. Create subscription for VRF V2.
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionID = vrfCoordinator.createSubscription();
        vrfCoordinator.addConsumer(subscriptionID, address(this));
        LINK = _LINK;
        keyHash = _keyHash;
        minimumRequestConfirmations = _minimumRequestConfirmations;
        callbackGasLimit = _callbackGasLimit;

        OneInchRouter = _OneInchRouter;

        //Create dummy listings at index 0
        listings.push();
        drops.push();
    }

    // ============ External Methods ============

    /**
     * @dev Lists NFT from sender's balance. Emits {ListItem} event.
     * @param nft - NFT to list. Note: The sender must have it approved for this contract.
     * @param maxTickets - Max amount of tickets that can be bought by participants.
     * @param ticketPrice - Price for a single ticket.
     * @param duration - Duration of listings. Can be in range [minDuration, maxDuration].
     
     * @return ID - ID of listing created.
     */
    function listItem(NFT memory nft, uint256 maxTickets, uint256 ticketPrice, uint256 duration) external returns(uint256 ID){
        nft.collection.safeTransferFrom(msg.sender, address(this), nft.tokenID);
        ID = _listItem(nft, maxTickets, ticketPrice, duration);
    }

    /**
     * @dev Lists NFTs from sender's balance. Emits {ListItem} events for each NFT listed.
     * @param nfts - NFTs to list. Note: The sender must have them approved for this contract.
     * @param maxTickets - Max amount of tickets that can be bought by participants.
     * @param ticketPrices - Prices for a single ticket.
     * @param durations - Durations of listings. Can be in range [minDuration, maxDuration].
     
     * @return IDs - IDs of listings created.
     */
    function listItems(
        NFT[] memory nfts, 
        uint256[] memory maxTickets, 
        uint256[] memory ticketPrices, 
        uint256[] memory durations
    ) external returns(uint256[] memory IDs){
        if(nfts.length != maxTickets.length || maxTickets.length != ticketPrices.length || ticketPrices.length != durations.length)
            revert InvalidArrayLengths();
        IDs = new uint256[](nfts.length);
        for(uint256 i = 0; i < nfts.length; i++) {
            nfts[i].collection.safeTransferFrom(msg.sender, address(this), nfts[i].tokenID);
            IDs[i] = _listItem(nfts[i], maxTickets[i], ticketPrices[i], durations[i]);
        }
    }

    /**
     * @dev Mints NFT to a public collection and lists it. Emits {ListItem} event.
     * @param tokenURI - Token metadata URI.
     * @param maxTickets - Max amounts of tickets that can be bought by participants.
     * @param ticketPrice - Price for a single ticket.
     * @param duration - Duration of listing. Can be in range [minDuration, maxDuration].
     * @param royaltyReceiver - Receiver of royalties from each NFT sale.
     * @param royaltyFeeNumerator - Amount of royalties to collect from each NFT sale. [10000 = 100%].

     * @return ID - ID of listing created.
     * @return token - NFT minted.
     * Note This function costs less than mintAndListItemWithDeploy() but does not deploy additional NFT collection contract
     */
    function mintAndListItem(
        string memory tokenURI, 
        uint256 maxTickets, 
        uint256 ticketPrice, 
        uint256 duration,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator
    ) external returns(uint256 ID, NFT memory token){
        string[] memory tokenURIs = new string[](1);
        tokenURIs[0] = tokenURI;
        
        (IERC721 collection, uint256[] memory tokenIDs) = minter.mintToPublicCollection(1, tokenURIs, royaltyReceiver, royaltyFeeNumerator);
        token = NFT(collection, tokenIDs[0]);
        ID = _listItem(token, maxTickets, ticketPrice, duration);
    }

    /**
     * @dev Mints NFTs to a public collection and lists them. Emits {ListItem} event for each NFT listed.
     * @param tokenURIs - Token metadata URIs.
     * @param maxTickets - Max amounts of tickets that can be bought by participants.
     * @param ticketPrices - Prices for a single ticket.
     * @param durations - Durations of listings. Can be in range [minDuration, maxDuration].
     * @param royaltyReceiver - Receiver of royalties from each NFT sale.
     * @param royaltyFeeNumerator - Amount of royalties to collect from each NFT sale. [10000 = 100%].
     
     * @return IDs - IDs of listings created.
     * @return collection - Address of NFT collection contract.
     * @return tokenIDs - IDs of tokens that were minted.
     * Note This function costs less than mintAndListItemsWithDeploy() but does not deploy additional NFT collection contract
     */
    function mintAndListItems(
        string[] memory tokenURIs, 
        uint256[] memory maxTickets, 
        uint256[] memory ticketPrices, 
        uint256[] memory durations,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator
    ) external returns(uint256[] memory IDs, IERC721 collection, uint256[] memory tokenIDs){
        if(maxTickets.length != ticketPrices.length || maxTickets.length != durations.length) revert InvalidArrayLengths();
        (collection, tokenIDs) = minter.mintToPublicCollection(maxTickets.length, tokenURIs, royaltyReceiver, royaltyFeeNumerator);

        IDs = new uint256[](maxTickets.length);
        for(uint256 i; i < maxTickets.length; i++){
            IDs[i] = _listItem(NFT(collection, tokenIDs[i]), maxTickets[i], ticketPrices[i], durations[i]);
        }
    }

    /**
     * @dev Deploys new NFT collection contract, mints NFT to it and lists it. Emits {ListItem} event.
     * @param name - Name for a collection.
     * @param symbol - Collection symbol.
     * @param baseURI - URI to store NFT metadata in.
     * @param maxTickets - Max amounts of tickets that can be bought by participants.
     * @param ticketPrice - Price for a single ticket.
     * @param duration - Duration of listing. Can be in range [minDuration, maxDuration].
     * @param royaltyReceiver - Receiver of royalties from each NFT sale.
     * @param royaltyFeeNumerator - Amount of royalties to collect from each NFT sale. [10000 = 100%].
     
     * @return ID - ID of listings created.
     * @return token - NFT minted.
     * Note: This is more expensive than mintAndListItem() function but it deploys additional NFT contract.
     */
    function mintAndListItemWithDeploy(
        string memory name, 
        string memory symbol, 
        string memory baseURI, 
        string memory contractURI,
        uint256 maxTickets, 
        uint256 ticketPrice,
        uint256 duration,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator
    ) external returns(uint256 ID, NFT memory token){
        (IERC721 collection, uint256[] memory tokenIDs) = minter.mintToPrivateCollection(1, name, symbol, baseURI, contractURI, royaltyReceiver, royaltyFeeNumerator);
        token = NFT(collection, tokenIDs[0]);
        ID = _listItem(token, maxTickets, ticketPrice, duration);
    }

    /**
     * @dev Deploys new NFT collection contract, mints NFTs to it and lists them. Emits {ListItem} event for each NFT listed.
     * @param name - Name for a collection.
     * @param symbol - Collection symbol.
     * @param baseURI - URI to store NFT metadata in.
     * @param maxTickets - Max amounts of tickets that can be bought by participants.
     * @param ticketPrices - Prices for a single ticket.
     * @param durations - Durations of listings. Can be in range [minDuration, maxDuration].
     * @param royaltyReceiver - Receiver of royalties from each NFT sale.
     * @param royaltyFeeNumerator - Amount of royalties to collect from each NFT sale. [10000 = 100%].
     
     * @return IDs - IDs of listings created.
     * @return collection - Address of NFT collection contract.
     * @return tokenIDs - IDs of tokens that were minted.
     * Note: This is more expensive than mintAndListItems() function but it deploys additional NFT contract.
     */
    function mintAndListItemsWithDeploy(
        string memory name, 
        string memory symbol, 
        string memory baseURI, 
        string memory contractURI,
        uint256[] memory maxTickets, 
        uint256[] memory ticketPrices,
        uint256[] memory durations,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator
    ) external returns(uint256[] memory IDs, IERC721 collection, uint256[] memory tokenIDs){
        if(maxTickets.length != ticketPrices.length || maxTickets.length != durations.length) revert InvalidArrayLengths();
        (collection, tokenIDs) = minter.mintToPrivateCollection(maxTickets.length, name, symbol, baseURI, contractURI, royaltyReceiver, royaltyFeeNumerator);
        
        IDs = new uint256[](maxTickets.length);
        for(uint256 i; i < maxTickets.length; i++){
            IDs[i] = _listItem(NFT(collection, tokenIDs[i]), maxTickets[i], ticketPrices[i], durations[i]);
        }
    }

    /**
     * @dev Buys tickets to participate in a draw. Requests Chainlink to generate random words if all tickets have been bought. Emits {BuyTicket} event for each ticket bought.
     * @param ID - ID of a listing to buy tickets for.
     * @param amount - Amount of tickets to buy. A single address can't buy more than {maxTicketsBoughtByAddress} of all tickets. 
     
     * @return tokensSpent - ESE tokens spent.
     */
    function buyTickets(uint256 ID, uint256 amount) external returns(uint256 tokensSpent){
        tokensSpent = _buyTickets(ID, amount);
        ESE.safeTransferFrom(msg.sender, address(this), tokensSpent);
    }

    /**
     * @dev Buys tickets with any token using 1inch'es router and swapping it for ESE. Requests Chainlink to generate random words if all tickets have been bought. Emits {BuyTicket} event for each ticket bought.
     * @param ID - ID of a listing to buy tickets for.
     * @param swapData - Data for 1inch swap. 
     
     * @return tokensSpent - Tokens spent.
     * @return ticketsBought - Tickets bought.
     */
    function buyTicketsWithSwap(uint256 ID, bytes calldata swapData) external nonReentrant payable returns(uint256 tokensSpent, uint256 ticketsBought){
        (address executor,IAggregationRouterV5.SwapDescription memory desc, bytes memory permit, bytes memory data) = abi.decode(swapData[4:], (address, IAggregationRouterV5.SwapDescription, bytes, bytes));
        if(
            bytes4(swapData[:4]) != IAggregationRouterV5.swap.selector || 
            desc.srcToken == ESE || 
            desc.dstToken != ESE || 
            desc.dstReceiver != address(this)
        ) revert InvalidSwapDescription();

        bool isETH = (address(desc.srcToken) == address(0) || address(desc.srcToken) == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE));
        if(isETH){
            if(msg.value != desc.amount) revert InvalidMsgValue();
        }else{
            if(msg.value != 0) revert InvalidMsgValue();
            desc.srcToken.transferFrom(msg.sender, address(this), desc.amount);
            desc.srcToken.approve(OneInchRouter, desc.amount);
        }
        uint256 returnAmount;
        (returnAmount, tokensSpent) = IAggregationRouterV5(OneInchRouter).swap{value: msg.value}(executor, desc, permit, data);

        Listing storage listing = listings[ID];
        ticketsBought = returnAmount / listing.ticketPrice;
        _buyTickets(ID, ticketsBought);

        // Refund dust
        uint256 ESEPaid = ticketsBought * listing.ticketPrice;
        if(returnAmount > ESEPaid){
            ESE.transfer(address(msg.sender), returnAmount - ESEPaid); 
        }
        if(desc.amount > tokensSpent){
            if(isETH){
                (bool success, ) = msg.sender.call{value: desc.amount - tokensSpent, gas: 5000}("");
                if(!success) revert TransferNotSuccessful();
            }else{
                desc.srcToken.transfer(address(msg.sender), desc.amount - tokensSpent);
            }   
        }
    }

    /**
     * @dev Deploys new NFT collection and lists it to users for minting. Emits {ListDrop} event.
     * @param name - Name for a collection.
     * @param symbol - Collection symbol.
     * @param URI - URI to store NFT metadata in.
     * @param contractURI - URI to store collection metadata in.
     * @param royaltyReceiver - Receiver of royalties from each NFT sale.
     * @param royaltyFeeNumerator - Amount of royalties to collect from each NFT sale. [10000 = 100%].
     * @param mintLimit - Max amount of NFTs that can be minted.
     * @param earningsCollector - Address to send NFT sale earnings to.
     * @param mintStartTimestamp - Timestamp when minting starts.
     * @param publicStageOptions - Option for public stage.
     * @param presalesOptions - Options for presales stages.

     * @return ID - ID of a drop created.
     * @return collection - Address of NFT collection contract.
     */
    function listDrop(
        string memory name,
        string memory symbol,
        string memory URI,
        string memory contractURI,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator,
        uint256 mintLimit,
        address earningsCollector,
        uint256 mintStartTimestamp, 
        IeeseeNFTDrop.StageOptions memory publicStageOptions,
        IeeseeNFTDrop.StageOptions[] memory presalesOptions
    ) external returns (uint256 ID, IERC721 collection){
        if(earningsCollector == address(0)) revert InvalidEarningsCollector();
        collection = minter.deployDropCollection(
            name,
            symbol,
            URI,
            contractURI,
            royaltyReceiver,
            royaltyFeeNumerator,
            mintLimit,
            mintStartTimestamp,
            publicStageOptions,
            presalesOptions
        );

        ID = drops.length;
        Drop storage drop = drops.push();
        drop.ID = ID;
        drop.collection = collection;
        drop.earningsCollector = earningsCollector;
        drop.fee = fee;

        emit ListDrop(ID, collection, earningsCollector);
    }

    /**
     * @dev Mints NFTs from a drop. Emits {MintDrop} event.
     * @param ID - ID of a drop to mint NFTs from.
     * @param quantity - Amount of NFTs to mint.
     * @param merkleProof - Merkle proof for a user to mint NFTs.

     * @return mintPrice - Amount of ESE tokens spent on minting.
     */
    function mintDrop(uint256 ID, uint256 quantity, bytes32[] memory merkleProof) external returns(uint256 mintPrice){
        if(quantity == 0) revert InvalidQuantity();
        Drop storage drop = drops[ID];

        IeeseeNFTDrop _drop = IeeseeNFTDrop(address(drop.collection));
        uint256 nextTokenId = _drop.nextTokenId();
        _drop.mint(msg.sender, quantity, merkleProof);

        (,,IeeseeNFTDrop.StageOptions memory stageOptions) = _drop.stages(_drop.getSaleStage()); 
        uint256 mintFee = stageOptions.mintFee;
        if (mintFee != 0) {
            mintPrice = mintFee * quantity;
            ESE.safeTransferFrom(msg.sender, address(this), mintPrice);
            uint256 fees = _collectFee(mintPrice, drop.fee);
            ESE.safeTransfer(drop.earningsCollector, mintPrice - fees);
        }

        for(uint256 i; i < quantity; i++){
            emit MintDrop(ID, NFT(drop.collection, nextTokenId + i), msg.sender, mintFee);
        }
    }

    /**
     * @dev Receive NFTs the sender won from listings. Emits {ReceiveItem} event for each of the NFT received.
     * @param IDs - IDs of listings to claim NFTs in.
     * @param recipient - Address to send NFTs to. 
     
     * @return collections - Addresses of tokens received.
     * @return tokenIDs - IDs of tokens received.
     * Note: Returning an array of NFT structs gives me "Stack too deep" error for some reason, so I have to return it this way
     */
    function batchReceiveItems(uint256[] memory IDs, address recipient) external returns(IERC721[] memory collections, uint256[] memory tokenIDs){
        if(recipient == address(0)) revert InvalidRecipient();
        collections = new IERC721[](IDs.length);
        tokenIDs = new uint256[](IDs.length);

        for(uint256 i; i < IDs.length; i++){
            uint256 ID = IDs[i];
            Listing storage listing = listings[ID];

            if(msg.sender != listing.winner) revert CallerNotWinner(ID);
            if(listing.itemClaimed) revert ItemAlreadyClaimed(ID);

            collections[i] = listing.nft.collection;
            tokenIDs[i] = listing.nft.tokenID;
            listing.itemClaimed = true;
            listing.nft.collection.safeTransferFrom(address(this), recipient, listing.nft.tokenID);

            emit ReceiveItem(ID, listing.nft, recipient);

            if(listing.tokensClaimed) delete listings[ID];
        }
    }

    /**
     * @dev Receive ESE the sender has earned from listings. Emits {ReceiveTokens} event for each of the claimed listing.
     * @param IDs - IDs of listings to claim tokens in.
     * @param recipient - Address to send tokens to.
     
     * @return amount - ESE received.
     */
    function batchReceiveTokens(uint256[] memory IDs, address recipient) external returns(uint256 amount){
        if(recipient == address(0)) revert InvalidRecipient();
        for(uint256 i; i < IDs.length; i++){
            uint256 ID = IDs[i];
            Listing storage listing = listings[ID];

            if(listing.winner == address(0)) revert ListingNotFulfilled(ID);
            if(msg.sender != listing.owner) revert CallerNotOwner(ID);
            if(listing.tokensClaimed) revert TokensAlreadyClaimed(ID);

            listing.tokensClaimed = true;
            uint256 _amount = listing.ticketPrice * listing.maxTickets;
            _amount -= _collectRoyalties(_amount, listing.nft, listing.owner);
            _amount -= _collectFee(_amount, listing.fee);
            amount += _amount;

            emit ReceiveTokens(ID, recipient, _amount);

            if(listing.itemClaimed) delete listings[ID];
        }
        // Transfer later to save gas
        ESE.safeTransfer(recipient, amount);
    }

    /**
     * @dev Reclaim NFTs from expired listings. Emits {ReclaimItem} event for each listing ID.
     * @param IDs - IDs of listings to reclaim NFTs in.
     * @param recipient - Address to send NFTs to.
     
     * @return collections - Addresses of tokens reclaimed.
     * @return tokenIDs - IDs of tokens reclaimed.
     * Note: returning an array of NFT structs gives me "Stack too deep" error for some reason, so I have to return it this way
     */
    function batchReclaimItems(uint256[] memory IDs, address recipient) external returns(IERC721[] memory collections, uint256[] memory tokenIDs){
        if(recipient == address(0)) revert InvalidRecipient();
        collections = new IERC721[](IDs.length);
        tokenIDs = new uint256[](IDs.length);

        for(uint256 i; i < IDs.length; i++){
            uint256 ID = IDs[i];
            Listing storage listing = listings[ID];

            if(msg.sender != listing.owner) revert CallerNotOwner(ID);
            if(block.timestamp <= listing.creationTime + listing.duration) revert ListingNotExpired(ID);
            if(listing.itemClaimed) revert ItemAlreadyClaimed(ID);
            if(listing.winner != address(0)) revert ListingAlreadyFulfilled(ID);

            collections[i] = listing.nft.collection;
            tokenIDs[i] = listing.nft.tokenID;
            listing.itemClaimed = true;
            listing.nft.collection.safeTransferFrom(address(this), recipient, listing.nft.tokenID);

            emit ReclaimItem(ID, listing.nft, recipient);

            if(listing.ticketsBought == 0) delete listings[ID];
        }
    }

    /**
     * @dev Reclaim ESE from expired listings. Emits {ReclaimTokens} event for each listing ID.
     * @param IDs - IDs of listings to reclaim tokens in.
     * @param recipient - Address to send tokens to.
     
     * @return amount - ESE received.
     */
    function batchReclaimTokens(uint256[] memory IDs, address recipient) external returns(uint256 amount){
        if(recipient == address(0)){
            revert InvalidRecipient();
        }
        for(uint256 i; i < IDs.length; i++){
            uint256 ID = IDs[i];
            Listing storage listing = listings[ID];
            uint256 ticketsBoughtByAddress = listing.ticketsBoughtByAddress[msg.sender];

            if(ticketsBoughtByAddress == 0) revert NoTicketsBought(ID);
            if(block.timestamp <= listing.creationTime + listing.duration) revert ListingNotExpired(ID);
            if(listing.winner != address(0)) revert ListingAlreadyFulfilled(ID);

            listing.ticketsBought -= ticketsBoughtByAddress;
            listing.ticketsBoughtByAddress[msg.sender] = 0;

            uint256 _amount = ticketsBoughtByAddress * listing.ticketPrice;
            amount += _amount;

            emit ReclaimTokens(ID, msg.sender, recipient, ticketsBoughtByAddress, _amount);

            if(listing.ticketsBought == 0 && listing.itemClaimed) delete listings[ID];
        }
        // Transfer later to save some gas
        ESE.safeTransfer(recipient, amount);
    }

    // ============ Getters ============

    /**
     * @dev Get length of the listings array.
     * @return length - Length of the listings array.
     */
    function getListingsLength() external view returns(uint256 length) {
        length = listings.length;
    }

    /**
     * @dev Get length of the drops array.
     * @return length - Length of the drops array.
     */
    function getDropsLength() external view returns(uint256 length) {
        length = drops.length;
    }

    /**
     * @dev Get the buyer of the specified ticket in listing.
     * @param ID - ID of the listing.
     * @param ticket - Ticket index.
     
     * @return address - Ticket buyer.
     */
    function getListingTicketIDBuyer(uint256 ID, uint256 ticket) external view returns(address) {
        return listings[ID].ticketIDBuyer[ticket];
    }
    
    /**
     * @dev Get the amount of tickets bought by address in listing.
     * @param ID - ID of the listing.
     * @param _address - Buyer address.
     
     * @return uint256 - Tickets bought by {_address}.
     */
    function getListingTicketsBoughtByAddress(uint256 ID, address _address) external view returns(uint256) {
        return listings[ID].ticketsBoughtByAddress[_address];
    }

    // ============ Internal Methods ============

    // Note: Must be called after nft was minted/transfered
    function _listItem(NFT memory nft, uint256 maxTickets, uint256 ticketPrice, uint256 duration) internal returns(uint256 ID){
        if(duration < minDuration) revert DurationTooLow(minDuration);
        if(duration > maxDuration) revert DurationTooHigh(maxDuration);
        if(maxTickets < 2) revert MaxTicketsTooLow();
        if(ticketPrice == 0) revert TicketPriceTooLow();

        ID = listings.length;

        Listing storage listing = listings.push();
        listing.ID = ID;
        listing.nft = nft;
        listing.owner = msg.sender;
        listing.maxTickets = maxTickets;
        listing.ticketPrice = ticketPrice;
        listing.fee = fee; // We save fees at the time of listing's creation to not have any control over existing listings' fees
        listing.creationTime = block.timestamp;
        listing.duration = duration;

        emit ListItem(ID, nft, listing.owner, maxTickets, ticketPrice, duration);
    }

    function _buyTickets(uint256 ID, uint256 amount) internal returns(uint256 tokensSpent){
        if(amount == 0) revert BuyAmountTooLow();
        Listing storage listing = listings[ID];
        if(listing.owner == address(0)) revert ListingNotExists(ID);
        if(block.timestamp > listing.creationTime + listing.duration) revert ListingExpired(ID);

        tokensSpent = listing.ticketPrice * amount;

        for(uint256 i; i < amount; i++){
            emit BuyTicket(ID, msg.sender, listing.ticketsBought, listing.ticketPrice);
            listing.ticketIDBuyer[listing.ticketsBought] = msg.sender;
            listing.ticketsBought += 1;
        }
        listing.ticketsBoughtByAddress[msg.sender] += amount;

        //Allow buy single tickets even if bought amount is more than maxTicketsBoughtByAddress
        if(listing.ticketsBoughtByAddress[msg.sender] > 1){
            if(listing.ticketsBoughtByAddress[msg.sender] * denominator / listing.maxTickets > maxTicketsBoughtByAddress) revert MaxTicketsBoughtByAddress(msg.sender);
        }
        if(listing.ticketsBought > listing.maxTickets) revert AllTicketsBought();

        if(listing.ticketsBought == listing.maxTickets){
            uint256 requestID = vrfCoordinator.requestRandomWords(keyHash, subscriptionID, minimumRequestConfirmations, callbackGasLimit, 1);
            chainlinkRequestIDs[requestID] = ID;
            emit RequestWords(ID, requestID);
        }
    }

    function _collectRoyalties(uint256 value, NFT memory nft, address listingOwner) internal returns(uint256 royaltyAmount) {
        (address payable[] memory recipients, uint256[] memory amounts) = royaltyEngine.getRoyalty(address(nft.collection), nft.tokenID, value);
        for(uint256 i = 0; i < recipients.length; i++){
            //There is no reason to collect royalty from owner if it goes to owner
            if (recipients[i] != address(0) && recipients[i] != listingOwner && amounts[i] != 0){
                ESE.safeTransfer(recipients[i], amounts[i]);
                royaltyAmount += amounts[i];
                emit CollectRoyalty(recipients[i], amounts[i]);
            }
        }
    }

    function _collectFee(uint256 amount, uint256 _fee) internal returns(uint256 feeAmount){
        if(feeCollector == address(0)) return 0;
        feeAmount = amount * _fee / denominator;
        if(feeAmount > 0){
            ESE.safeTransfer(feeCollector, feeAmount);
            emit CollectFee(feeCollector, feeAmount);
        }
    }

    /**
     * @dev This function is called by Chainlink. Chooses listing winner and emits {FulfillListing} event.
     * @param requestID - Chainlink request ID.
     * @param randomWords - Random values sent by Chainlink.
     */
    function fulfillRandomWords(uint256 requestID, uint256[] memory randomWords) internal override {
        uint256 ID = chainlinkRequestIDs[requestID];
        Listing storage listing = listings[ID];

        if(block.timestamp > listing.creationTime + listing.duration) revert ListingExpired(ID);

        uint256 chosenTicket = randomWords[0] % listing.maxTickets;
        listing.winner = listing.ticketIDBuyer[chosenTicket];

        delete chainlinkRequestIDs[requestID];
        emit FulfillListing(ID, listing.nft, listing.winner);
    }

    // ============ Admin Methods ============

    /**
     * @dev Changes minDuration. Emits {ChangeMinDuration} event.
     * @param _minDuration - New minDuration.
     * Note: This function can only be called by owner.
     */
    function changeMinDuration(uint256 _minDuration) external onlyOwner {
        emit ChangeMinDuration(minDuration, _minDuration);
        minDuration = _minDuration;
    }

    /**
     * @dev Changes maxDuration. Emits {ChangeMaxDuration} event.
     * @param _maxDuration - New maxDuration.
     * Note: This function can only be called by owner.
     */
    function changeMaxDuration(uint256 _maxDuration) external onlyOwner {
        emit ChangeMaxDuration(maxDuration, _maxDuration);
        maxDuration = _maxDuration;
    }

    /**
     * @dev Changes maxTicketsBoughtByAddress. Emits {ChangeMaxTicketsBoughtByAddress} event.
     * @param _maxTicketsBoughtByAddress - New maxTicketsBoughtByAddress.
     * Note: This function can only be called by owner.
     */
    function changeMaxTicketsBoughtByAddress(uint256 _maxTicketsBoughtByAddress) external onlyOwner {
        if(_maxTicketsBoughtByAddress > denominator) revert MaxTicketsBoughtByAddressTooHigh();

        emit ChangeMaxTicketsBoughtByAddress(maxTicketsBoughtByAddress, _maxTicketsBoughtByAddress);
        maxTicketsBoughtByAddress = _maxTicketsBoughtByAddress;
    }

    /**
     * @dev Changes fee. Emits {ChangeFee} event.
     * @param _fee - New fee.
     * Note: This function can only be called by owner.
     */
    function changeFee(uint256 _fee) external onlyOwner {
        if(_fee > denominator / 2) revert FeeTooHigh();

        emit ChangeFee(fee, _fee);
        fee = _fee;
    }

    /**
     * @dev Changes feeCollector. Emits {ChangeFeeCollector} event.
     * @param _feeCollector - New feeCollector.
     * Note: This function can only be called by owner.
     */
    function changeFeeCollector(address _feeCollector) external onlyOwner{
        emit ChangeFeeCollector(feeCollector, _feeCollector);
        feeCollector = _feeCollector;
    }

    /**
     * @dev Fund function for Chainlink's VRF V2 subscription.
     * @param amount - Amount of LINK to fund subscription with.
     */
    function fund(uint96 amount) external {
        IERC20(address(LINK)).safeTransferFrom(msg.sender, address(this), amount);
        LINK.transferAndCall(
            address(vrfCoordinator),
            amount,
            abi.encode(subscriptionID)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

    constructor() {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
interface IERC20Permit {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IAggregationRouterV5 {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    function swap(
        address executor,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 spentAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "./IeeseeMinter.sol";
import "./IRoyaltyEngineV1.sol";
import "./IAggregationRouterV5.sol";

interface Ieesee {
    /**
     * @dev NFT:
     * {token} - IERC721 contract address.
     * {tokenID} - Token ID of NFT. 
     */
    struct NFT {
        IERC721 collection;
        uint256 tokenID;
    }

    /**
     * @dev Listing:
     * {ID} - Id of the Listing, starting from 1.
     * {nft} - NFT sold in this listing. 
     * {owner} - Listing creator.
     * {maxTickets} - Amount of tickets sold in this listing. 
     * {ticketIDBuyer} - The buyer of the specified ticket.
     * {ticketsBoughtByAddress} - Amount of tickets bought by address.
     * {ticketPrice} - Price of a single ticket.
     * {ticketsBought} - Amount of tickets bought.
     * {fee} - Fee sent to {feeCollector}.
     * {creationTime} - Listing creation time.
     * {duration} - Listing duration.
     * {winner} - Selected winner.
     * {itemClaimed} - Is NFT claimed/reclaimed.
     * {tokensClaimed} - Are tokens claimed.
     */
    struct Listing {
        uint256 ID;
        NFT nft;
        address owner;
        uint256 maxTickets;
        mapping(uint256 => address) ticketIDBuyer;
        mapping(address => uint256) ticketsBoughtByAddress;
        uint256 ticketPrice;
        uint256 ticketsBought;
        uint256 fee;
        uint256 creationTime;
        uint256 duration;
        address winner;
        bool itemClaimed;
        bool tokensClaimed;
    }

    /**
     * @dev Drop:
     * {ID} - Id of the Drop, starting from 1.
     * {collection} - IERC721 contract address.
     * {earningsCollector} - Address that collects earnings from this drop.
     * {fee} - Fee sent to {feeCollector}.
     */
    struct Drop {
        uint256 ID;
        IERC721 collection;
        address earningsCollector;
        uint256 fee;
    }

    event ListItem(
        uint256 indexed ID,
        NFT indexed nft,
        address indexed owner,
        uint256 maxTickets, 
        uint256 ticketPrice,
        uint256 duration
    );

    event BuyTicket(
        uint256 indexed ID,
        address indexed buyer,
        uint256 indexed ticketID,
        uint256 ticketPrice
    );


    event RequestWords(
        uint256 indexed ID,
        uint256 requestID
    );

    event FulfillListing(
        uint256 indexed ID,
        NFT indexed nft,
        address indexed winner
    );


    event ReceiveItem(
        uint256 indexed ID,
        NFT indexed nft,
        address indexed recipient
    );

    event ReceiveTokens(
        uint256 indexed ID,
        address indexed recipient,
        uint256 amount
    );


    event ReclaimItem(
        uint256 indexed ID,
        NFT indexed nft,
        address indexed recipient
    );

    event ReclaimTokens(
        uint256 indexed ID,
        address indexed sender,
        address indexed recipient,
        uint256 tickets,
        uint256 amount
    );


    event CollectRoyalty(
        address indexed recipient,
        uint256 amount
    );

    event CollectFee(
        address indexed to,
        uint256 amount
    );


    event ChangeMinDuration(
        uint256 indexed previousMinDuration,
        uint256 indexed newMinDuration
    );

    event ChangeMaxDuration(
        uint256 indexed previousMaxDuration,
        uint256 indexed newMaxDuration
    );

    event ChangeMaxTicketsBoughtByAddress(
        uint256 indexed previousMaxTicketsBoughtByAddress,
        uint256 indexed newMaxTicketsBoughtByAddress
    );

    event ChangeFee(
        uint256 indexed previousFee, 
        uint256 indexed newFee
    );

    event ChangeFeeCollector(
        address indexed previousFeeColector, 
        address indexed newFeeCollector
    );

    event ListDrop(
        uint256 indexed ID, 
        IERC721 indexed collection, 
        address indexed earningsCollector
    );
    event MintDrop(
        uint256 indexed ID, 
        NFT indexed nft,
        address indexed sender,
        uint256 mintFee
    );

    error CallerNotOwner(uint256 ID);
    error CallerNotWinner(uint256 ID);

    error ItemAlreadyClaimed(uint256 ID);
    error TokensAlreadyClaimed(uint256 ID);

    error ListingAlreadyFulfilled(uint256 ID);
    error ListingNotFulfilled(uint256 ID);
    error ListingExpired(uint256 ID);
    error ListingNotExpired(uint256 ID);
    error ListingNotExists(uint256 ID);

    error DurationTooLow(uint256 minDuration);
    error DurationTooHigh(uint256 maxDuration);
    error MaxTicketsTooLow();
    error TicketPriceTooLow();
    error BuyAmountTooLow();
    error FeeTooHigh();
    error MaxTicketsBoughtByAddressTooHigh();

    error AllTicketsBought();
    error NoTicketsBought(uint256 ID);
    error MaxTicketsBoughtByAddress(address _address);

    error InvalidArrayLengths();
    error InvalidSwapDescription();
    error InvalidMsgValue();
    error InvalidEarningsCollector();
    error InvalidQuantity();
    error InvalidRecipient();

    error SwapNotSuccessful();
    error TransferNotSuccessful();
    error EthDepositRejected();

    function listings(uint256) external view returns(
        uint256 ID,
        NFT memory nft,
        address owner,
        uint256 maxTickets,
        uint256 ticketPrice,
        uint256 ticketsBought,
        uint256 fee,
        uint256 creationTime,
        uint256 duration,
        address winner,
        bool itemClaimed,
        bool tokensClaimed
    );

    function drops(uint256) external view returns(
        uint256 ID,
        IERC721 collection,
        address earningsCollector,
        uint256 fee
    );

    function ESE() external view returns(IERC20);
    function minter() external view returns(IeeseeMinter);

    function minDuration() external view returns(uint256);
    function maxDuration() external view returns(uint256);
    function maxTicketsBoughtByAddress() external view returns(uint256);
    function fee() external view returns(uint256);
    function feeCollector() external view returns(address);

    function LINK() external view returns(LinkTokenInterface);
    function vrfCoordinator() external view returns(VRFCoordinatorV2Interface);
    function subscriptionID() external view returns(uint64);
    function keyHash() external view returns(bytes32);
    function minimumRequestConfirmations() external view returns(uint16);

    function royaltyEngine() external view returns(IRoyaltyEngineV1);
    function OneInchRouter() external view returns(address);

    function listItem(
        NFT memory nft, 
        uint256 maxTickets, 
        uint256 ticketPrice, 
        uint256 duration
    ) external returns(uint256 ID);
    function listItems(
        NFT[] memory nfts, 
        uint256[] memory maxTickets, 
        uint256[] memory ticketPrices, 
        uint256[] memory durations
    ) external returns(uint256[] memory IDs);

    function mintAndListItem(
        string memory tokenURI, 
        uint256 maxTickets, 
        uint256 ticketPrice, 
        uint256 duration,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator
    ) external returns(uint256 ID, NFT memory token);
    function mintAndListItems(
        string[] memory tokenURIs, 
        uint256[] memory maxTickets, 
        uint256[] memory ticketPrices, 
        uint256[] memory durations,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator
    ) external returns(uint256[] memory IDs, IERC721 collection, uint256[] memory tokenIDs);

    function mintAndListItemWithDeploy(
        string memory name, 
        string memory symbol, 
        string memory baseURI, 
        string memory contractURI,
        uint256 maxTickets, 
        uint256 ticketPrice,
        uint256 duration,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator
    ) external returns(uint256 ID, NFT memory token);
    function mintAndListItemsWithDeploy(
        string memory name, 
        string memory symbol, 
        string memory baseURI, 
        string memory contractURI,
        uint256[] memory maxTickets, 
        uint256[] memory ticketPrices,
        uint256[] memory durations,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator
    ) external returns(uint256[] memory IDs, IERC721 collection, uint256[] memory tokenIDs);

    function buyTickets(uint256 ID, uint256 amount) external returns(uint256 tokensSpent);
    function buyTicketsWithSwap(uint256 ID, bytes calldata swapData) external payable returns(uint256 tokensSpent, uint256 ticketsBought);

    function listDrop(
        string memory name,
        string memory symbol,
        string memory URI,
        string memory contractURI,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator,
        uint256 mintLimit,
        address earningsCollector,
        uint256 mintStartTimestamp, 
        IeeseeNFTDrop.StageOptions memory publicStageOptions,
        IeeseeNFTDrop.StageOptions[] memory presalesOptions
    ) external returns (uint256 ID, IERC721 collection);
    function mintDrop(uint256 ID, uint256 quantity, bytes32[] memory merkleProof) external returns(uint256 mintPrice);

    function batchReceiveItems(uint256[] memory IDs, address recipient) external returns(IERC721[] memory collections, uint256[] memory tokenIDs);
    function batchReceiveTokens(uint256[] memory IDs, address recipient) external returns(uint256 amount);

    function batchReclaimItems(uint256[] memory IDs, address recipient) external returns(IERC721[] memory collections, uint256[] memory tokenIDs);
    function batchReclaimTokens(uint256[] memory IDs, address recipient) external returns(uint256 amount);

    function getListingsLength() external view returns(uint256 length);
    function getListingTicketIDBuyer(uint256 ID, uint256 ticket) external view returns(address);
    function getListingTicketsBoughtByAddress(uint256 ID, address _address) external view returns(uint256);

    function changeMinDuration(uint256 _minDuration) external;
    function changeMaxDuration(uint256 _maxDuration) external;
    function changeMaxTicketsBoughtByAddress(uint256 _maxTicketsBoughtByAddress) external;
    function changeFee(uint256 _fee) external;
    function changeFeeCollector(address _feeCollector) external;

    function fund(uint96 amount) external;
}

// Because of the contract size limit we need a sepparate contract to mint NFTs.
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/IeeseeNFTDrop.sol";
import "../interfaces/IeeseeNFT.sol";

interface IeeseeMinter {
    error IncorrectTokenURILength();

    function publicCollection() external view returns(IeeseeNFT);
    function mintToPublicCollection(uint256 amount, string[] memory tokenURIs, address royaltyReceiver, uint96 royaltyFeeNumerator) external returns(IERC721 collection, uint256[] memory tokenIDs);
    function mintToPrivateCollection(
        uint256 amount,
        string memory name, 
        string memory symbol, 
        string memory baseURI, 
        string memory contractURI,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator
    ) external returns(IERC721 collection, uint256[] memory tokenIDs);
    function deployDropCollection(
        string memory name, 
        string memory symbol, 
        string memory URI,
        string memory contractURI,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator,
        uint256 mintLimit,
        uint256 mintStartTimestamp, 
        IeeseeNFTDrop.StageOptions memory publicStageOptions,
        IeeseeNFTDrop.StageOptions[] memory presalesOptions
    ) external returns(IERC721 collection);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IeeseeNFT {
    error SetURIForNonexistentToken();
    error SetRoyaltyForNonexistentToken();

    function URI() external view returns (string memory);
    function contractURI() external view returns (string memory);
    function nextTokenId() external view returns (uint256);
    function mint(address recipient, uint256 quantity) external;
    function setURIForTokenId(uint256 tokenId, string memory _tokenURI) external;
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;
    function setRoyaltyForTokenId(uint256 tokenId, address receiver, uint96 feeNumerator) external;
}

// Because of the contract size limit we need a sepparate contract to mint NFTs.
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IeeseeNFTDrop {
    /**
     * @dev SaleStage:
     * {startTimestamp} - Timestamp when this stage starts.
     * {endTimestamp} - Timestamp when this stage ends.
     * {addressMintedAmount} - Amount of nfts minted by address.
     * {stageOptions} - Additional options for this stage.
     */
    struct SaleStage {
        uint256 startTimestamp;
        uint256 endTimestamp;
        mapping(address => uint256) addressMintedAmount;
        StageOptions stageOptions;
    }	 
    /**
     * @dev StageOptions:
     * {name} - Name of a mint stage.
     * {mintFee} - Price to mint 1 nft.
     * {duration} - Duration of mint stage.
     * {perAddressMintLimit} - Mint limit for one address.
     * {allowListMerkleRoot} - Root of merkle tree for allowlist.
     */
    struct StageOptions {     
        string name;
        uint256 mintFee;
        uint256 duration;
        uint256 perAddressMintLimit;
        bytes32 allowListMerkleRoot;
    }

    error MintTimestampNotInFuture();
    error PresaleStageLimitExceeded();
    error ZeroSaleStageDuration();
    error MintLimitExceeded();
    error MintingNotStarted();
    error MintingEnded();
    error NotInAllowlist();

    function URI() external view returns (string memory);
    function contractURI() external view returns (string memory);
    function mintLimit() external view returns (uint256);
    function mintedAmount() external view returns (uint256);

    function getSaleStage() external view returns (uint8 index);
    function stages(uint256) external view returns (uint256 startTimestamp, uint256 endTimestamp, StageOptions memory stageOptions);
    
    function nextTokenId() external view returns (uint256);
    function verifyCanMint(uint8 saleStageIndex, address claimer, bytes32[] memory merkleProof) external view returns (bool);

    function mint(address recipient, uint256 quantity, bytes32[] memory merkleProof) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Lookup engine interface
 */
interface IRoyaltyEngineV1 is IERC165 {
    /**
     * Get the royalty for a given token (address, id) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value)
        external
        returns (address payable[] memory recipients, uint256[] memory amounts);

    /**
     * View only version of getRoyalty
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyaltyView(address tokenAddress, uint256 tokenId, uint256 value)
        external
        view
        returns (address payable[] memory recipients, uint256[] memory amounts);
}