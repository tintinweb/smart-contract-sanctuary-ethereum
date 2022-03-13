// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC165.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract HexagonMarketplace is Ownable, ReentrancyGuard {
    
    using SafeERC20 for IERC20;

    /**
    * @dev Interface ids to check which interface a nft contract supports, used to classify between an ERC721 and ERC1155 nft contracts
    */
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /**
    * @dev The divisor when calculating percent fees
    */
    uint constant BASIS_POINTS = 10000;

    /**
    * @dev This is the max percent fee that can be charged for using a token (10% max)
    */
    uint constant MAX_FEE = 1000;


    /**
    * @dev Struct containing contract address and fees for a payment token
    */
    struct PaymentToken {

        address contractAddress;
        uint fee;
    }

    /**
    * @dev Addresses of the payment tokens this marketplace accepts
    */
    PaymentToken[] paymentTokens;


    /**
    * @dev amount of fees that can be pulled from the contract and sent into the other wallets in the protocal
    */
    mapping(uint => uint) claimableAmount;

    struct FeeAllocation {
        address wallet;
        uint percent;
    }

    FeeAllocation[] feeAllocations;

    /**
    * @dev A Struct containing all the payment info for a whitelisted collection.
    */
    struct Collection {
        address royaltyRecipient;
        uint royaltyFee;
        uint royaltiesEarned;
        uint currencyType;
    }

    /**
    * @dev A Struct containing all the info for a nft listing or bid, this data is also used to generate a signature that checked to see if the owner of the nft signed it,
    * authorizing the sale of the nft with these parameters if a buyer accepts.
    */
    struct Signature {
        address contractAddress;
        address userAddress;
        uint256 tokenId;
        uint256 quantity;
        uint256 pricePerItem;
        uint256 expiry;
        uint256 nonce;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    /**
    * @dev Struct containing data about the highest bid for a particular nft
    */ 
    struct AuctionData {
        uint tokenId;
        uint highestBid;
        uint expiry;
        uint minBid;
        uint percentIncrement;
        uint quantity;
        address highestBidder;
        address collectionAddress;

    }

    /**
    * @dev mapping from collection id -> tokenId -> owner -> auctionData
    * ///@notice owner is used as a mapping because multiple owners can put of for auction the same erc1155 item
    */
    mapping(address => mapping(uint => mapping(address => AuctionData))) public AuctionMapping;

    /**
    * @dev A mapping of nft collection addresses of whitelisted collection, and the data corrisponding to it (royalty fee, wallet address)
    */
    mapping(address => Collection) whitelistedCollections;

    /**
    * @dev A mapping of signatures and their validity. Signatures are signed messages from people offering bids on nfts they want to buy,
    * or setting a listing price on an nft they wish to sell. After a trade goes through, or a listing/bid is canceled, the signature is mapped here to be invalid. 
    */
    mapping(bytes32 => bool) invalidSignatures;

    /**
    * @dev Event emitted when the percent fee the marketplace takes changes
    */
    event UpdateFee(uint fee);

    /**
    * @dev Event emitted when the wallet address that marketplace fees get sent to changes
    */
    event UpdateFeeRecipient(address feeRecipient);

    /**
    * @dev Event emitted when a collection gets get added to the marketplace, allowing this contracts nfts to be traded on this marketplace
    */
    event CollectionWhitelisted(address nftAddress, address royaltyRecipient, uint royaltyFee);

    /**
    * @dev Event emitted when a collection gets removed from the marketplace, meaning the contracts nfts can no longer trade on this marketplace
    */
    event CollectionRemoved(address nftAddress);

    /**
    * @dev Event emitted when a collection gets updated, either its royalty fees, or its wallet address
    */
    event CollectionUpdated(address nftAddress, address royaltyRecipient, uint royaltyFee);

    /**
    * @dev Event emitted when a bid is accepted by the owner of the nft, and a trade takes place
    */
    event BidAccepted(
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        address indexed owner,
        address buyer,
        uint256 marketplaceFee,
        uint256 creatorFee,
        uint256 ownerRevenue,
        uint256 value,
        uint256 nonce
    );

    /**
    * @dev Event emitted when a bid is canceled
    */
    event BidCanceled(
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 nonce
    );

    /**
    * @dev Event emitted when a listing is accepted by the buyer and a trade takes place
    */
    event ListingAccepted(
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        address indexed owner,
        address buyer,
        uint256 marketplaceFee,
        uint256 creatorFee,
        uint256 ownerRevenue,
        uint256 value,
        uint256 nonce
    );

    /**
    * @dev Event emitted when a listing is canceled
    */
    event ListingCanceled(
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        address indexed owner,
        uint256 nonce
    );

    /**
    * @dev Event emitted when an auction is placed for an nft
    */
    event AuctionBid(address indexed collectionAddress, uint indexed tokenId, address indexed bidder, uint bid, address owner);

    /**
    * @dev Event emitted when an auction is placed for an nft
    */
    event AuctionPlaced(address indexed collectionAddress, uint indexed tokenId, address indexed owner);

    /**
    * @dev Event emitted when an auction is concluded
    */
    event AuctionConcluded(address indexed collectionAddress, uint indexed tokenId, address indexed bidder, uint bid, address owner);

     /**
    * @dev This is the domain used in EIP-712 signatures.
    * It is not a constant so that the chainId can be determined dynamically.
    * If multiple classes use EIP-712 signatures in the future this can move to a shared file.
    */
    bytes32 private DOMAIN_SEPARATOR;

    /**
    * @dev This name is used in the EIP-712 domain.
    * If multiple classes use EIP-712 signatures in the future this can move to the shared constants file.
    */
    string private constant NAME = "HEXAGONMarketplace";

    /**
    * @dev This is a hash of the method signature used in the EIP-712 signature for bids.
    */
    bytes32 private constant ACCEPT_BID_TYPEHASH =
        keccak256("AcceptBid(address contractAddress,uint256 tokenId,address userAddress,uint256 pricePerItem,uint256 quantity,uint256 expiry,uint256 nonce)");

     /**
    * @dev This is a hash of the method signature used in the EIP-712 signature for listings.
    */
    bytes32 private constant ACCEPT_LISTING_TYPEHASH =
        keccak256("AcceptListing(address contractAddress,uint256 tokenId,address userAddress,uint256 pricePerItem,uint256 quantity,uint256 expiry,uint256 nonce)");

    /**
    * @dev This function must be called at least once before signatures will work as expected.
    * It's okay to call this function many times. Subsequent calls will have no impact.
    */
    function _initializeSignatures() internal {
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
        chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(NAME)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function getChainId() public view returns(uint256) {
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
        chainId := chainid()
        }

        return chainId;
    }

    /**
    * @dev Modifier ensuring the provided contract address has been whitelisted
    */
    modifier onlyWhitelisted(address nft) {
        require(whitelistedCollections[nft].royaltyFee > 0, "nft not whitelisted");
        _;
    }

    /**
    * @dev Constructor initializing the fees, recipient of market fees, and the contract address of the payment token used in this marketplace
    */
    constructor() {
        _initializeSignatures();
    }

    /**
    * @notice Allow a buyer to purchase the nfts at the price previously set.
    * @dev The seller signs a message approving the price, and then the buyer calls this function
    * and transfers the agreed upon tokens
    */
    function AcceptListing(Signature calldata listing) public nonReentrant onlyWhitelisted(listing.contractAddress) {

        bytes32 signature = getSignature(ACCEPT_LISTING_TYPEHASH, listing);

        // Revert if the signature is invalid, the terms are not as expected, or if the seller transferred the NFT.
        require(ecrecover(signature, listing.v, listing.r, listing.s) == listing.userAddress && invalidSignatures[signature] == false, "AcceptListing: Invalid Signature");

        //Invalidate signature so it cannot be used again
        invalidSignatures[signature] = true;
        
        // The signed message from the seller is only valid for a limited time.
        require(listing.expiry > block.timestamp, "AcceptListing: EXPIRED");

        // Transfer the nft(s) from the owner to the bidder
        // Will revert if the seller doesn't have the nfts
        if (IERC165(listing.contractAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721(listing.contractAddress).safeTransferFrom(listing.userAddress, msg.sender, listing.tokenId);
        } else {
            IERC1155(listing.contractAddress).safeTransferFrom(listing.userAddress, msg.sender, listing.tokenId, listing.quantity, bytes(""));
        }

        uint256 value = listing.pricePerItem * listing.quantity;

        // Pay the creator the marketplace, and seller
        // Will revert if the buyer doesn't have the funds
        (uint256 marketplaceFee, uint256 creatorFee, uint256 ownerRevenue) = _distributeFunds(
            value,
            listing.userAddress,
            msg.sender,
            listing.contractAddress
        );

        emit ListingAccepted(
            listing.contractAddress,
            listing.tokenId,
            listing.userAddress,
            msg.sender,
            marketplaceFee,
            creatorFee,
            ownerRevenue,
            value,
            listing.nonce
        );
    }

    /**
    * @dev The seller cancels the listing they previously approved by providing the listing data they wish to cancel
    */
    function CancelListing(Signature calldata listing) public {

        bytes32 signature = getSignature(ACCEPT_LISTING_TYPEHASH, listing);

        // Revert if the signature has not been signed by the sender
        require(ecrecover(signature, listing.v, listing.r, listing.s) == msg.sender, "CancelListing: INVALID_SIGNATURE");

        //Set the signature to be invalid, preventing anyone from using this signature to purchase this item
        invalidSignatures[signature] = true;

        emit ListingCanceled(
            listing.contractAddress,
            listing.tokenId,
            msg.sender,
            listing.nonce
        );

    }

    /**
    * @notice Allow a bid for a NFT to be accepted by the owner.
    * @dev The buyer signs a message approving the purchase, and then the seller calls this function
    * with the msg.value equal to the agreed upon price.
    */
    function AcceptBid (Signature calldata bid) public nonReentrant onlyWhitelisted(bid.contractAddress) {

        bytes32 signature = getSignature(ACCEPT_BID_TYPEHASH, bid);

        // Revert if the signature is invalid, the terms are not as expected, or if the seller transferred the NFT.
        require(ecrecover(signature, bid.v, bid.r, bid.s) == bid.userAddress && invalidSignatures[signature] == false, "AcceptBid: Invalid Signature");

        //Invalidate signature so it cannot be used again
        invalidSignatures[signature] = true;
        
        // The signed message from the seller is only valid for a limited time.
        require(bid.expiry > block.timestamp, "AcceptBid: EXPIRED");


        //Transfer the nft from the owner to the bidder
        if (IERC165(bid.contractAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721(bid.contractAddress).safeTransferFrom(msg.sender, bid.userAddress, bid.tokenId);
        } else {
            IERC1155(bid.contractAddress).safeTransferFrom(msg.sender, bid.userAddress, bid.tokenId, bid.quantity, bytes(""));
        }

        uint256 value = bid.pricePerItem * bid.quantity;

        // Pay the creator the marketplace, and seller
        // Will revert of the bidder doesn't have the funds
        (uint256 marketplaceFee, uint256 creatorFee, uint256 ownerRevenue) = _distributeFunds(
            value,
            msg.sender,
            bid.userAddress,
            bid.contractAddress
        );

        emit BidAccepted(
            bid.contractAddress,
            bid.tokenId,
            msg.sender,
            bid.userAddress,
            marketplaceFee,
            creatorFee,
            ownerRevenue,
            value,
            bid.nonce
        );
    }

    /**
    * @dev The buyer cancels the bid they previously approved by providing the bid data they wish to cancel
    */
    function CancelBid(Signature calldata bid) public {

        bytes32 signature = getSignature(ACCEPT_BID_TYPEHASH, bid);

        // Revert if the signature has not been signed by the sender
        require(ecrecover(signature, bid.v, bid.r, bid.s) == msg.sender, "CancelBid: INVALID_SIGNATURE");

        //Invalidate signature so it can no longer be used
        invalidSignatures[signature] = true;

        emit BidCanceled(
            bid.contractAddress,
            bid.tokenId,
            msg.sender,
            bid.nonce
        );
    }

    /**
    * @dev Destributes the funds from the buyer to the seller/owner, with a percentage of the sale price distributed to the marketplace,
    * and potentially the creator of the collection
    */
    function _distributeFunds(
        uint256 _value,
        address _owner,
        address _sender,
        address _nftAddress
       
    ) internal returns(uint256 marketplaceFee, uint256 creatorFee, uint256 ownerRevenue){

        if(_value > 0) {

            Collection memory collection = whitelistedCollections[_nftAddress];

            PaymentToken memory paymentToken = paymentTokens[collection.currencyType];

            IERC20 token = IERC20(paymentToken.contractAddress);

            //calculate fee for the marketplace
            marketplaceFee = _value * paymentToken.fee / BASIS_POINTS;

            //calculate the creator fee
            creatorFee = _value * collection.royaltyFee / BASIS_POINTS;


            if(marketplaceFee > 0) {

                ///@notice buyer can be 
                if(_sender != address(this)) {

                    //send tokens to the marketplace wallet
                    token.safeTransferFrom(_sender, address(this), marketplaceFee);

                }

                claimableAmount[collection.currencyType] += marketplaceFee;

            }

            if(creatorFee > 0) {

                whitelistedCollections[_nftAddress].royaltiesEarned += creatorFee;
                
                //send tokens to the creator wallet
                token.safeTransferFrom(_sender, collection.royaltyRecipient, creatorFee);

            }

            ownerRevenue = (_value - marketplaceFee) - creatorFee;

            //send remaining tokens to the seller/owner
            token.safeTransferFrom(_sender, _owner, ownerRevenue);

        }
    }
    

    /**
    * @dev Place a bid an nft up for auction
    * requires the auction to have started and not be over
    * and the value of the bid to be at least the minimum bid amount, greator than the current highest bid, and increased from the min bid
    * by at least the minimum increment
    * @notice Payment tokens are sent to the contract on successful bid, and if a bid is beaten the tokens they sent will be sent back to the beaten bids address
    */
    function placeAuctionBid(address _collectionAddress, uint _tokenId, address _owner, uint _amount) public nonReentrant
    {
        
        AuctionData memory auctionData = AuctionMapping[_collectionAddress][_tokenId][_owner];

        require(auctionData.quantity > 0, "Auction doesn't exist");

        require(auctionData.expiry > block.timestamp, "Auction is over");

        require(msg.sender != _owner, "Can't bid on your own item");

        uint highestBid = auctionData.highestBid;
        address highestBidder = auctionData.highestBidder;

        ///@notice set the values here to help prevent reentancy attack
        auctionData.highestBidder = msg.sender;
        auctionData.highestBid = _amount;

        AuctionMapping[_collectionAddress][_tokenId][_owner] = auctionData;

        Collection memory collection = whitelistedCollections[_collectionAddress];

        PaymentToken memory paymentToken = paymentTokens[collection.currencyType];

        IERC20 token = IERC20(paymentToken.contractAddress);

        if(highestBid > 0) {

            uint minIncrement = (highestBid * auctionData.percentIncrement) / 1000;

            ///@notice there is already a bid on this auction, so it needs to be higher
            require(_amount >= highestBid + minIncrement, "Amount needs to be more than last bid, plus increment");

            ///@notice the _amount is more, so lets send the other funds back
            token.safeTransfer(highestBidder, highestBid);


        } else {

            ///@notice there is already a bid on this auction, so it needs to be higher
            require(_amount >= auctionData.minBid, "Amount needs to be more than the min bid");

        }

        ///@notice send the tokens to the contract to be locked until either outbid, or the auction is over
        token.safeTransferFrom(msg.sender, address(this), _amount);




        emit AuctionBid(_collectionAddress, _tokenId, msg.sender, _amount, _owner);


    }

    /**
    * @dev Place an auction, setting the auctions parameters and locking the nft in the contract until the auction is concluded
    * Requires an auction to not already exist, and the proper permissions to be set
    */
    function placeAuction(AuctionData memory _auctionData) public onlyWhitelisted(_auctionData.collectionAddress) nonReentrant {

        require(_auctionData.expiry > block.timestamp, "Auction needs to have a duration");

        require(AuctionMapping[_auctionData.collectionAddress][_auctionData.tokenId][msg.sender].quantity == 0, "Auction already exists");

        require(_auctionData.percentIncrement >= 50, "need to set a minimum percent of at least 5");

        require(_auctionData.minBid > 0, "have to set a minimum bid");

        AuctionMapping[_auctionData.collectionAddress][_auctionData.tokenId][msg.sender] = _auctionData;

        //Hold the nft in escrow
        ///@notice assumption is made that these contracts will be either erc721 or erc1155, because those are the only contracts thats will be whitelisted
        /// this will also revert if permissions havent been set, or the sender doesnt own the nft
        if (IERC165(_auctionData.collectionAddress).supportsInterface(INTERFACE_ID_ERC721)) {

            IERC721(_auctionData.collectionAddress).transferFrom(msg.sender, address(this), _auctionData.tokenId);
            require(_auctionData.quantity == 1, "Can't have more than 1 nft of this type");

            
        } else {
            
            IERC1155(_auctionData.collectionAddress).safeTransferFrom(msg.sender, address(this), _auctionData.tokenId, _auctionData.quantity, bytes(""));

            require(_auctionData.quantity > 0, "Quantity can't be zero");
        }

        
        emit AuctionPlaced(_auctionData.collectionAddress, _auctionData.tokenId, msg.sender);

    }

    /**
    * @dev Completes an auction, sending funds and the nft to the proper owners
    * Requires the auction to be over, can be called by anyone
    */
    function concludeAuction(address _collectionAddress, uint _tokenId, address _owner) public nonReentrant {

        AuctionData memory auctionData = AuctionMapping[_collectionAddress][_tokenId][_owner];

        require(auctionData.quantity > 0, "Auction doesn't exist");

        require(auctionData.expiry >= block.timestamp, "Auction isn't over");

        address nftReciever;

        if(auctionData.highestBid > 0) {

            ///@notice there was a bid, so we can send the funds from this contract to the appropriate people, and send the nft to the bidder
            nftReciever = auctionData.highestBidder;

            //send funds from this address
            _distributeFunds(auctionData.highestBid, _owner, address(this), auctionData.collectionAddress);

        } else {

            ///@notice there wasnt a bid, so the nft can be sent back to the owner
            nftReciever = _owner;

        }

        //Send the nft from this contract to the proper person
        ///@notice assumption is made that these contracts will be either erc721 or erc1155, because those are the only contracts thats will be whitelisted
        /// this will also revert if permissions havent been set, or the sender doesnt own the nft
        if (IERC165(auctionData.collectionAddress).supportsInterface(INTERFACE_ID_ERC721)) {

            IERC721(auctionData.collectionAddress).safeTransferFrom(address(this), nftReciever, auctionData.tokenId);

            
        } else {
            
            IERC1155(auctionData.collectionAddress).safeTransferFrom(address(this), nftReciever, auctionData.tokenId, auctionData.quantity, bytes(""));

        }

        ///@notice delete the auction so a new one can be made
        delete AuctionMapping[_collectionAddress][_tokenId][_owner];

        emit AuctionConcluded(_collectionAddress, _tokenId, nftReciever, auctionData.highestBid, _owner);


    }

   

    //View functions

    function getTimestamp() public view returns(uint) {
        return block.timestamp;
    }

    function getSignature(bytes32 _TYPEHASH, Signature memory signature) internal view returns(bytes32) {

        return keccak256(
        abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(_TYPEHASH, signature.contractAddress, signature.tokenId, signature.userAddress, signature.pricePerItem, signature.quantity, signature.expiry, signature.nonce))
            )
        );

    }

    function getCollectionInfo(address _collectionAddress) public view returns (Collection memory) {
        return whitelistedCollections[_collectionAddress];
    }

    /**
    * @dev Retrieves the total royalties this collection has generated
    */
    function getRoyaltiesGenerated(address _collectionAddress) public view returns (uint) {

        return whitelistedCollections[_collectionAddress].royaltiesEarned;

    }

    //Owner functions

    /**
    * @dev Claims the fees generated by the marketplace, if any, and sends to the proper wallets in the set amounts
    */
    function claimFees() external onlyOwner {

        FeeAllocation[] memory _feeAllocations = feeAllocations;

        require(_feeAllocations.length > 0, "Fee allocations not set");

        PaymentToken[] memory tokens = paymentTokens;

        require(tokens.length > 0, "No tokens set");

        for(uint i = 0; i < tokens.length; i++) {

            IERC20 token = IERC20(tokens[i].contractAddress);

            uint _claimableAmount = claimableAmount[i];

            if(_claimableAmount == 0) {
                continue;
            }

            for(uint j = 0; j < _feeAllocations.length; j++) {

                uint toClaim = (_claimableAmount * _feeAllocations[i].percent) / BASIS_POINTS;

                if(toClaim > 0) {

                    token.safeTransfer(_feeAllocations[i].wallet, toClaim);

                }

            }

            claimableAmount[i] = 0;

        }

    }

    function setPaymentToken(address _paymentAddress, uint256 _fee, uint256 _index) external onlyOwner {

        require(_index <= paymentTokens.length, "index out of range");
        require(_fee <= MAX_FEE, "Attempting to set too high of a fee");

        //approve this contract to use transfer from to move funds
        IERC20(_paymentAddress).approve(address(this), 2**256 - 1);

        if(_index == paymentTokens.length) {

            //Adding a new payment token
            paymentTokens.push(PaymentToken(_paymentAddress, _fee));

        } else {

            //Updating a previous payment token
            paymentTokens[_index] = PaymentToken(_paymentAddress, _fee);

        }

    }

    /**
    * @dev Sets how the fees will be allocated when withdrawn
    */
    function setFeeAllocations(FeeAllocation[] memory _feeAllocations) public onlyOwner {

        uint totalPercent;

        uint allocationsLength = feeAllocations.length;

        for(uint i = 0; i < _feeAllocations.length; i++) {

            totalPercent += _feeAllocations[i].percent;

            if(i >= allocationsLength) {
                feeAllocations.push(_feeAllocations[i]);
            }else {
                feeAllocations[i] = _feeAllocations[i];
            }
           

        }

        require(totalPercent == BASIS_POINTS, "Total percent does not add to 100%");

    }


    /**
    * @dev Adds a nft collection to the whitelist, allowing it to be traded on this marketplace, and setting the royalty fee and fee recipient
    */
    function addToWhitelist(address _nft, address _royaltyRecipient, uint _royaltyFee, uint _currencyType) external onlyOwner {
        require(whitelistedCollections[_nft].royaltyFee == 0, "nft already whitelisted");
        require(_currencyType < paymentTokens.length, "payment token doesn't exist");
        whitelistedCollections[_nft] = Collection(_royaltyRecipient, _royaltyFee, 0, _currencyType);
        emit CollectionWhitelisted(_nft, _royaltyRecipient, _royaltyFee);
    }

    /**
    * @dev removes a nft collection to the whitelist, preventing from being traded on this marketplace
    */
    function removeFromWhitelist(address _nft) external onlyOwner onlyWhitelisted(_nft) {
        delete whitelistedCollections[_nft];
        emit CollectionRemoved(_nft);
    }

    /**
    * @dev updates a nft collections royalty fee and recepient address
    */
    function updateWhitelist(address _nftAddress, address _royaltyRecipient, uint _royaltyFee) external onlyOwner onlyWhitelisted(_nftAddress) {

        Collection storage _collection = whitelistedCollections[_nftAddress];

        _collection.royaltyFee = _royaltyFee;
        _collection.royaltyRecipient = _royaltyRecipient;

        emit CollectionUpdated(_nftAddress, _royaltyRecipient, _royaltyFee);

    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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