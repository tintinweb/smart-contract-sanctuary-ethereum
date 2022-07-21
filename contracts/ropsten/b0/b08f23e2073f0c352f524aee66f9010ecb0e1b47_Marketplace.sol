/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// SPDX-License-Identifier: MIT


pragma solidity ^ 0.8.0;
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
) external returns(bytes4);
}
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns(bool);
}
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
    function balanceOf(address owner) external view returns(uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns(address owner);

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
    function getApproved(uint256 tokenId) external view returns(address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns(bool);
}


contract Marketplace is IERC721Receiver {
    // Name of the marketplace
    string public name;

    // Index of auctions
    uint256 public index = 0;

    // Structure to define auction properties
    struct MarketItem {
        uint256 index; // MarketItem Index
        address addressNFTCollection; // Address of the ERC721 NFT Collection contract
        uint256 nftId; // NFT Id
        address creator; // Creator of the MarketItem
        uint price;
        address payable currentBidOwner; // Address of the highest bider
        uint256 currentBidPrice; // Current highest bid for the auction
        uint256 endTime; // Timestamp for the end day&time of the auction
        uint256 bidCount; // Number of bid placed on the auction
        bool isAuction;

    }

    // Array will all auctions
    MarketItem[] public allMarketItems;

    // Public event to notify that a new auction has been created
    event NewMarketItemCreated(
        uint256 index,
        address addressNFTCollection,
        uint256 nftId,
        address mintedBy,
        address currentBidOwner,
        uint256 currentBidPrice,
        uint256 endTime,
        uint256 bidCount,
        uint price,
        bool isAuction
    );

    // Public event to notify that a new bid has been placed
    event NewBidOnAuction(uint256 auctionIndex, uint256 newBid);

    // Public event to notif that winner of an
    // auction claim for his reward
    event NFTClaimed(uint256 auctionIndex, uint256 nftId, address claimedBy);

    // Public event to notify that the creator of
    // an auction claimed for his money
    event TokensClaimed(uint256 auctionIndex, uint256 nftId, address claimedBy);

    // Public event to notify that an NFT has been refunded to the
    // creator of an auction
    event NFTRefunded(uint256 auctionIndex, uint256 nftId, address claimedBy);

    event NFTBuy(uint256 tokenID, address from, address to, uint256 price);

    // constructor of the contract
    constructor(string memory _name) {
        name = _name;
    }

    modifier isAuction(uint _index){
        require(allMarketItems[_index].isAuction, "Invalid Auction");
        _;
    }

    /**
     * Check if a specific address is
     * a contract address
     * @param _addr: address to verify
     */
    function isContract(address _addr) private view returns(bool) {
        uint256 size;
        assembly {
            size:= extcodesize(_addr)
        }
        return size > 0;
    }

    /**
     * Create a new auction of a specific NFT
     * @param _addressNFTCollection address of the ERC721 NFT collection contract
     * @param _nftId Id of the NFT for sale
     * @param _priceOrIntialBid Inital bid decided by the creator of the auction
     * @param _endTime Timestamp with the end date and time of the auction
     */
    function createSellOrAuction(
        address _addressNFTCollection,
        uint256 _nftId,
        uint256 _priceOrIntialBid,
        uint256 _endTime,
        bool _isAuction
    ) external returns(uint256) {
        //Check is addresses are valid
        require(
            isContract(_addressNFTCollection),
            "Invalid NFT Collection contract address"
        );


        // Check if the endTime time is valid
        require(_endTime > block.timestamp, "Invalid end date for auction");

        // Check if the initial bid price is > 0
        require(_priceOrIntialBid > 0, "Invalid initial bid or  price");

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
        nftCollection.safeTransferFrom(msg.sender, address(this), _nftId);

        //Casting from address to address payable
        address payable currentBidOwner = payable(address(0));

        // Create new MarketItem object
        MarketItem memory newAuction = MarketItem({
            index: index,
            addressNFTCollection: _addressNFTCollection,
            nftId: _nftId,
            creator: msg.sender,
            currentBidOwner: currentBidOwner,
            currentBidPrice: _priceOrIntialBid,
            endTime: _endTime,
            bidCount: 0,
            price: _priceOrIntialBid,
            isAuction: _isAuction
        });

        //update list
        allMarketItems.push(newAuction);

        // increment auction sequence
        index++;

        // Trigger event and return index of new auction
        emit NewMarketItemCreated(
            index,
            _addressNFTCollection,
            _nftId,
            msg.sender,
            currentBidOwner,
            _priceOrIntialBid,
            _endTime,
            0,
            _priceOrIntialBid,
            _isAuction
        );
        return index;
    }

    /**
     * Check if an auction is open
     * @param _index Index of the auction
     */
    function isOpen(uint256 _index) public view returns(bool) {
        MarketItem storage auction = allMarketItems[_index];
        if (block.timestamp >= auction.endTime) return false;
        return true;
    }

    /**
    * Return the address of the current highest bider
    * for a specific auction
    * @param _index Index of the auction
    */
    function getMarketItem(uint _index) public view returns(MarketItem memory) {

        require(_index < allMarketItems.length, "Invalid auction index");
        return allMarketItems[_index];

    }


    /**
     * Return the address of the current highest bider
     * for a specific auction
     * @param _index Index of the auction
     */
    function getCurrentBidOwner(uint256 _index)
    public
    view
    isAuction(_index)
    returns(address)
    {
        require(_index < allMarketItems.length, "Invalid auction index");

        return allMarketItems[_index].currentBidOwner;
    }

    /**
     * Return the current highest bid price
     * for a specific auction
     * @param _index Index of the auction
     */
    function getCurrentBid(uint256 _index)
    public
    view
    isAuction(_index)
    returns(uint256)
    {
        require(_index < allMarketItems.length, "Invalid auction index");
        return allMarketItems[_index].currentBidPrice;
    }

    /**
     * Place new bid on a specific auction
     * @param _index Index of auction
     */
    function bid(uint256 _index)
        external payable
    isAuction(_index)
    returns(bool)
    {
        uint _newBid = msg.value;
        require(_index < allMarketItems.length, "Invalid auction index");
        MarketItem storage auction = allMarketItems[_index];

        // check if auction is still open
        require(isOpen(_index), "MarketItem is not open");

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



        // new bid is valid so must refund the current bid owner (if there is one!)
        if (auction.bidCount > 0) {

            auction.currentBidOwner.transfer(auction.currentBidPrice);
        }

        // update auction info
        address payable newBidOwner = payable(msg.sender);
        auction.currentBidOwner = newBidOwner;
        auction.currentBidPrice = _newBid;
        auction.bidCount++;

        // Trigger public event
        emit NewBidOnAuction(_index, _newBid);

        return true;
    }

    /**
     * Place new bid on a specific auction
     * @param _index Index of auction
     */
    function buy(uint _index) external payable {

        // check if  still open
        require(isOpen(_index), "MarketItem is not open");
        // check if it is for sale or auction
        require(!allMarketItems[_index].isAuction, "Item not for sale"); 

        MarketItem memory item = allMarketItems[_index];

        require(msg.value == item.price, "NFTMarket: incorrect price");

        IERC721(item.addressNFTCollection).transferFrom(address(this), msg.sender, _index);

        payable(item.creator).transfer(item.price);

        emit NFTBuy(_index, item.creator, msg.sender, item.price);



    }


    /**
     * Function used by the winner of an auction
     * to withdraw his NFT.
     * When the NFT is withdrawn, the creator of the
     * auction will receive the payment tokens in his wallet
     * @param _index Index of auction
     */
    function claimNFT(uint256 _index) external payable isAuction(_index) {
        require(_index < allMarketItems.length, "Invalid auction index");

        // Check if the auction is closed
        require(!isOpen(_index), "MarketItem is still open");

        // Get auction
        MarketItem storage auction = allMarketItems[_index];

        // Check if the caller is the winner of the auction
        require(
            auction.currentBidOwner == msg.sender,
            "NFT can be claimed only by the current bid owner"
        );

        // Get NFT collection contract
        IERC721 nftCollection = IERC721(
            auction.addressNFTCollection
        );
        // Transfer NFT from marketplace contract
        // to the winner address

        nftCollection.safeTransferFrom(
            address(this),
            auction.currentBidOwner,
            _index
        );

        // Get ERC20 Payment token contract

        // Transfer locked token from the marketplace
        // contract to the auction creator address

        // paymentToken.transfer(auction.creator, auction.currentBidPrice)
        payable(auction.creator).transfer(auction.currentBidPrice);

        emit NFTClaimed(_index, auction.nftId, msg.sender);
    }



    /**
     * Function used by the creator of an auction
     * to get his NFT back in case the auction is closed
     * but there is no bider to make the NFT won't stay locked
     * in the contract
     * @param _index Index of the auction
     */
    function refund(uint256 _index) external {
        require(_index < allMarketItems.length, "Invalid auction index");

        // Check if the auction is closed
        require(!isOpen(_index), "MarketItem is still open");

        // Get auction
        MarketItem storage auction = allMarketItems[_index];

        // Check if the caller is the creator of the auction
        require(
            auction.creator == msg.sender,
            "Tokens can be claimed only by the creator of the auction"
        );

        require(
            auction.currentBidOwner == address(0),
            "Existing bider for this auction"
        );

        // Get NFT Collection contract
        IERC721 nftCollection = IERC721(
            auction.addressNFTCollection
        );
        // Transfer NFT back from marketplace contract
        // to the creator of the auction
        nftCollection.transferFrom(
            address(this),
            auction.creator,
            auction.nftId
        );

        emit NFTRefunded(_index, auction.nftId, msg.sender);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns(bytes4) {
        return this.onERC721Received.selector;
    }
}