/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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




abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}




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



contract CustomAuction is Ownable,ReentrancyGuard{

// Name of the marketplace
    string public name;
    // Index of auctions
    uint256 public index = 0;
    // Index of Bidder
    uint256 public Bidderindex = 0;
    //Index of Fix PriceSale 
    uint256 public FixPriceSaleindex = 0;
    //Index of Lottery 
    uint256 public Lotteryindex = 0;
    //Fix Price sale status
    enum FixSaleStatus { STARTED, ENDED }

    //Fixed Price Sale Details
    struct FixedPriceSell {
        uint256 index;
        uint256 TokenId;
        address CollectionAddress;
        address CollectionOwnerAddress;
        address NFTOwnerAddress;
        uint RoyaltyP;
        uint256 Price; //price in gwei
        FixSaleStatus Status;
    }

//bidder details
 struct Bidder {
        uint256 index;
        uint256 auctionIndex;
        address bidderAddress;
        uint256 bidAmount;
    }

    // Structure to define auction properties
    struct Auction {
        uint256 index; // Auction Index
        address addressNFTCollection; // Address of the ERC721 NFT Collection contract
        address addressPaymentToken; // Address of the ERC20 Payment Token contract
        uint256 nftId; // NFT Id
        address creator; // Creator of the Auction
        uint RoyaltyP;
        address CollectionOwnerAddress;
        address payable currentBidOwner; // Address of the highest bidder
        uint256 currentBidPrice; // Current highest bid for the auction
        uint256 endAuction; // Timestamp for the end day&time of the auction
        uint256 bidCount; // Number of bid placed on the auction
        //Bidder[] bidders; // 
    }
    //Array for all bidders
    Bidder[] private Allbidders;

    //Array for Fixed Price
    FixedPriceSell[] private AllFixedPriceSell;
   
    // Array will all auctions
    Auction[] private allAuctions;

    // Public event to notify that a new auction has been created
    event NewAuction(
        uint256 index,
        address addressNFTCollection,
        address addressPaymentToken,
        uint256 nftId,
        address mintedBy,
        address currentBidOwner,
        uint256 currentBidPrice,
        uint256 endAuction,
        uint256 bidCount
    );


    event FixPriceEvent(
        uint256 index,
        uint256 TokenId,
        address CollectionAddress,
        uint256 Price,
        bool IsOnSale
    );

    // Public event to notify that a new bid has been placed
    event NewBidOnAuction(uint256 auctionIndex, uint256 newBid);

    // constructor of the contract
    constructor(string memory _name) {
        name = _name;
    }

    /**
     * Check if a specific address is
     * a contract address
     * @param _addr: address to verify
     */
    function isContract(address _addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }


    /**
     * Create a new Fix Price Sale of a specific NFT
     * Price in gwei 
     */

 function CreateFixPriceSale(address _addressNFTCollection, uint256 _nftId, uint256 _price , address _collectionOwner ,uint256 Royalty) external returns(uint256) {
    //Check is addresses are valid
        require(
            isContract(_addressNFTCollection),
            "Invalid NFT Collection contract address"
        );
        // Get NFT collection contract
        IERC721 nftCollection = IERC721(_addressNFTCollection);
        
        // Make sure the sender that wants to create a new auction
        // for a specific NFT is the owner of this NFT
        require(
            nftCollection.ownerOf(_nftId) == msg.sender,
            "Caller is not the owner of the NFT"
        );

        require(Royalty <= 10 , "Max 10% royalty allowed.");

        // Make sure the owner of the NFT approved that the MarketPlace contract
        // is allowed to change ownership of the NFT
        require(
            nftCollection.getApproved(_nftId) == address(this),
            "Require NFT ownership transfer approval"
        );
        // Create new Fix Price Sale object
        FixedPriceSell memory fixPrice = FixedPriceSell({
            index: FixPriceSaleindex,
            TokenId: _nftId,
            CollectionAddress : _addressNFTCollection,
            CollectionOwnerAddress : _collectionOwner,
            NFTOwnerAddress : msg.sender,
            RoyaltyP : Royalty,
            Price : _price,
            Status : FixSaleStatus.STARTED
        });
        //update list
        AllFixedPriceSell.push(fixPrice);
        //increment auction sequence
        FixPriceSaleindex++;

        return FixPriceSaleindex;
    }

 //Claim NFT for FIx Price
    function ClaimFixPriceNFT(uint256 _priceIndex) external payable{

     require(_priceIndex < AllFixedPriceSell.length, "Invalid FixPrice index");
        FixedPriceSell storage FixedSell = AllFixedPriceSell[_priceIndex];
        require(msg.value > 0, "Price must be greater than zero");
        require(FixedSell.Status == FixSaleStatus.STARTED , "Not For Sale Currently");
        
        //now distribute price with royalty
        uint256 amountReceived = (msg.value * 1000000000);
        //get NFT Price  //Price in gwei
        require(amountReceived == FixedSell.Price , "Invalid Price");
        //Predefined Platform percentage
        uint256 Platformpercentage = 5;
        //Give royalties to original contract owner
        uint256 ownerCut = (msg.value * Platformpercentage) / 100;
        //owner of this contract
        address owner = owner();
        payable(owner).transfer(ownerCut);
        //Give royalties to NPort (10%)
        uint256 nportCut = (msg.value * 10) / 100;
        //Transfer to first owner
        payable(FixedSell.CollectionOwnerAddress).transfer(nportCut);
        //Give current owner the rest
        payable(FixedSell.NFTOwnerAddress).transfer(msg.value - ownerCut - nportCut);
        
        // Get NFT collection contract
        IERC721 NftCollection = IERC721(FixedSell.CollectionAddress);
    
         NftCollection.transferFrom(
                address(this),
                msg.sender,
                FixedSell.TokenId
            );
    
        //nftCollection.safeTransferFrom(FixedSell.NFTOwnerAddress, msg.sender, FixedSell.TokenId);
        //FixedSell.Price = 0;
        FixedSell.Status = FixSaleStatus.ENDED;
       
    }


    /**
     * Create a new auction of a specific NFT
     * @param _addressNFTCollection address of the ERC721 NFT collection contract
     * @param _addressPaymentToken address of the ERC20 payment token contract
     * @param _nftId Id of the NFT for sale
     * @param _initialBid Inital bid decided by the creator of the auction
     * @param _endAuction Timestamp with the end date and time of the auction
     */
    function createAuction(
        address _addressNFTCollection,
        address _addressPaymentToken,
        uint256 _nftId,
        uint256 _initialBid,
        uint256 _endAuction,
        address collectionOwner,
        uint256 Royalty
    ) external returns (uint256) {
        //Check is addresses are valid
        require(
            isContract(_addressNFTCollection),
            "Invalid NFT Collection contract address"
        );
        require(
            isContract(_addressPaymentToken),
            "Invalid Payment Token contract address"
        );
        
         require(Royalty <= 10 , "Max 10% royalty allowed.");
        // Check if the endAuction time is valid
        require(_endAuction > block.timestamp, "Invalid end date for auction");

        // Check if the initial bid price is > 0
        require(_initialBid > 0, "Invalid initial bid price");

        // Get NFT collection contract
        IERC721 nftCollection = IERC721(_addressNFTCollection);

        // Make sure the sender that wants to create a new auction
        // for a specific NFT is the owner of this NFT
        require(
            nftCollection.ownerOf(_nftId) == msg.sender,
            "Caller is not the owner of the NFT"
        );

        // Make sure the owner of the NFT approved that the MarketPlace contract
        // is allowed to change ownership of the NFT
        require(
            nftCollection.getApproved(_nftId) == address(this),
            "Require NFT ownership transfer approval"
        );

        // Lock NFT in Marketplace contract
        //require(nftCollection.transferNFTFrom(msg.sender, address(this), 0));

        //Casting from address to address payable
        address payable currentBidOwner = payable(address(0));
        
        // Create new Auction object
        Auction memory newAuction = Auction({
            index: index,
            addressNFTCollection: _addressNFTCollection,
            addressPaymentToken: _addressPaymentToken,
            nftId: _nftId,
            creator: msg.sender,
            currentBidOwner: currentBidOwner,
            currentBidPrice: _initialBid,
            endAuction: _endAuction,
            RoyaltyP : Royalty,
            CollectionOwnerAddress : collectionOwner,
            bidCount: 0
        });

        //update list
        allAuctions.push(newAuction);

        // increment auction sequence
        index++;

        // Trigger event and return index of new auction
        emit NewAuction(
            index,
            _addressNFTCollection,
            _addressPaymentToken,
            _nftId,
            msg.sender,
            currentBidOwner,
            _initialBid,
            _endAuction,
            0
        );
        return index;
    }

    /**
     * Check if an auction is open
     * @param _auctionIndex Index of the auction
     */
    function isOpen(uint256 _auctionIndex) public view returns (bool) {
        Auction storage auction = allAuctions[_auctionIndex];
        if (block.timestamp >= auction.endAuction) return false;
        return true;
    }

    /**
     * Return the address of the current highest bider
     * for a specific auction
     * @param _auctionIndex Index of the auction
     */
    function getCurrentBidOwner(uint256 _auctionIndex)
        public
        view
        returns (address)
    {
        require(_auctionIndex < allAuctions.length, "Invalid auction index");
        return allAuctions[_auctionIndex].currentBidOwner;
    }

    /**
     * Return the current highest bid price
     * for a specific auction
     * @param _auctionIndex Index of the auction
     */
    function getCurrentBid(uint256 _auctionIndex)
        public
        view
        returns (uint256)
    {
        require(_auctionIndex < allAuctions.length, "Invalid auction index");
        return allAuctions[_auctionIndex].currentBidPrice;
    }

    /**
     * Place new bid on a specific auction
     * @param _auctionIndex Index of auction
     * @param _newBid New bid price
     */
    function bid(uint256 _auctionIndex, uint256 _newBid)
        external
        returns (bool)
    {
        require(_auctionIndex < allAuctions.length, "Invalid auction index");
        Auction storage auction = allAuctions[_auctionIndex];

        // check if auction is still open
        require(isOpen(_auctionIndex), "Auction is not open");

        // check if new bid price is higher than the current one
        require(
            _newBid > auction.currentBidPrice,
            "New bid price must be higher than the current bid"
        );

        // check if new bider is not the owner
        require(
            msg.sender != auction.creator,
            "Creator of the auction cannot place new bid"
        );
        
          Bidder memory bidder = Bidder({
            index : Bidderindex,
            auctionIndex : _auctionIndex,
            bidderAddress :msg.sender,
            bidAmount : _newBid
        });
        
        Allbidders.push(bidder);
        Bidderindex ++ ;
        // get ERC20 token contract
        IERC20 paymentToken = IERC20(auction.addressPaymentToken);

        // new bid is better than current bid!

        // approve 
        require(
            paymentToken.approve(address(this), _newBid ),
            "Tranfer of token failed"
        );
        
        // update auction info
        address payable newBidOwner = payable(msg.sender);
        auction.currentBidOwner = newBidOwner;
        auction.currentBidPrice = _newBid;
        auction.bidCount++;

        // Trigger public event
        emit NewBidOnAuction(_auctionIndex, _newBid);

        return true;
    }


//get all bids
function AllBids(uint256 _auctionIndex) public view returns (Bidder[] memory) {
        Bidder[] memory subBids = new Bidder[](Allbidders.length);
        uint count = 0;
        for (uint i=0; i<Allbidders.length ; i++)
        {
            if (Allbidders[i].auctionIndex == _auctionIndex)
            {
                subBids[count] = Allbidders[i];
                count++;
            }
        }
        return subBids; 
    }

//get bid details
function getBidDetails(uint bidIndex) public view returns (uint , uint , address , uint){

    Bidder memory Bids = Allbidders[bidIndex];
    return (Bids.index ,Bids.auctionIndex , Bids.bidderAddress , Bids.bidAmount);
} 

//get fix price details
function getFixPriceDetails(uint256 _fixIndex) public view returns (uint , uint , address ,address ,address , uint ,uint,  FixSaleStatus ){

  FixedPriceSell memory Sales = AllFixedPriceSell[_fixIndex];
  return (Sales.index,Sales.TokenId,Sales.CollectionAddress , Sales.CollectionOwnerAddress,Sales.NFTOwnerAddress,Sales.RoyaltyP,Sales.Price,Sales.Status);
}

//get auction details
function getAuctionDetails(uint256 _auctionIndex) public view returns (uint, address , address ,uint , address ,uint, address , address , uint ,uint ,uint){

  Auction memory Auctions = allAuctions[_auctionIndex];
  return (Auctions.index, Auctions.addressNFTCollection, Auctions.addressPaymentToken, Auctions.nftId, Auctions.creator, Auctions.RoyaltyP,Auctions.CollectionOwnerAddress ,Auctions.currentBidOwner, Auctions.currentBidPrice, Auctions.endAuction, Auctions.bidCount);
}

    /**
     * Function used by the winner of an auction
     * to withdraw his NFT.
     * When the NFT is withdrawn, the creator of the
     * auction will receive the payment tokens in his wallet
     * @param _auctionIndex Index of auction
     */
    function RewardNFT(uint256 _auctionIndex) external {
        require(_auctionIndex < allAuctions.length, "Invalid auction index");

        // Check if the auction is closed
        require(!isOpen(_auctionIndex), "Auction is still open");

        // Get auction
        Auction storage auction = allAuctions[_auctionIndex];

        // Check if the caller is the winner of the auction
        require(
            auction.creator == msg.sender,
            "NFT can be claimed/reward only by the creator owner"
        );

        //Get ERC20 Payment token contract
        IERC20 paymentToken = IERC20(auction.addressPaymentToken);
        // Transfer locked token from the marketplace
        // contract to the auction creator address
        require(
            paymentToken.transfer(auction.creator, auction.currentBidPrice)
        );

        // Get NFT collection contract
        IERC721 nftCollection = IERC721(
            auction.addressNFTCollection
        );

        // Transfer NFT from marketplace contract
        // to the winner address
            nftCollection.transferFrom(
                address(this),
                auction.currentBidOwner,
                auction.nftId
            );
    
        //emit NFTClaimed(_auctionIndex, auction.nftId, msg.sender);
    }

}