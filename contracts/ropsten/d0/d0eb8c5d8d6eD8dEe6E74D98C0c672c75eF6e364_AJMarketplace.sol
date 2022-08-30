/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;


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


    function getRoyaltyAndPlatformFeeDetails(uint256 _nftId) external view returns(uint256, address, uint256, address);
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }
}

contract AJMarketplace is ReentrancyGuard {
    address public nftContractAddr; 
    // uint256[] public nftAmount;
    address[] allBidersAddress;
    struct AuctionData {
        uint256 nftId;
        address seller;
        bool started;
        bool ended;
        uint256 endAt;
        uint256 highestBid;
        address highestBidder;
        uint256 totalBidAmount;
    }
    mapping(uint256 => AuctionData) public AuctionDataset;
    mapping(address => uint256) public bids;

    struct Item {
        uint256 tokenId;
        address nft;
        uint256 price;
        address payable seller;
        bool forSale;
        // bool forAuction;
    }
    mapping(uint256 => Item) public items;

    event Offered(uint256 tokenId, address indexed nft,  uint256 price, address indexed seller );
    event Bought(uint256 tokenId, address indexed nft, uint256 price, address indexed seller, address indexed buyer );

    constructor(address _nftContractAddr) {
        nftContractAddr = _nftContractAddr;
    }


   // --------------------------------- Auction Start ------------------------------------------ //

    function putOnAuction(uint256 _nftId, uint256 startingBid, uint256 _auctionTime) external {
        require(IERC721(nftContractAddr).ownerOf(_nftId) == msg.sender, "Only Nft Owner can Put NFT for Auction");
        require(!AuctionDataset[_nftId].started, "Already started!");
        // require(msg.sender == seller, "You can not start the auction!");
        AuctionDataset[_nftId].highestBid = startingBid;
        AuctionDataset[_nftId].nftId = _nftId;
        // nftId = _nftId;
        IERC721(nftContractAddr).transferFrom(msg.sender, address(this), _nftId);
        AuctionDataset[_nftId].started = true;
        AuctionDataset[_nftId].endAt = block.timestamp + _auctionTime;
        AuctionDataset[_nftId].seller = msg.sender;
    }

    function getNFTFinalRate(uint _sellPrice, uint256 _tokenId) view public returns(uint256){
        // get royalti details
        (uint256 royaltyPercent, , uint256 platformFee,) = getRoyaltyPlatformFee(_tokenId);
        return((_sellPrice*(100 + royaltyPercent + platformFee))/100);
    }

    function bid(uint256 _nftId) external payable {
        uint256 totalAmountUserPay = getNFTFinalRate(AuctionDataset[_nftId].highestBid, _nftId);        // getNFTFinalRate(uint _sellPrice, uint256 _tokenId)
        require(AuctionDataset[_nftId].started, "Not started.");
        require(block.timestamp < AuctionDataset[_nftId].endAt, "Ended!");
        // require(msg.value > AuctionDataset[_nftId].highestBid, "Please place high bid");
        require(msg.value >= totalAmountUserPay, "Not enough ether to cover item price and market fee, Price + Platfrom Fee + Royalty");

        // ether transfer to the seller
        payable(AuctionDataset[_nftId].seller).transfer(msg.value);
        AuctionDataset[_nftId].totalBidAmount += msg.value;

        AuctionDataset[_nftId].highestBid = msg.value;
        AuctionDataset[_nftId].highestBidder = msg.sender;
        bids[msg.sender] += msg.value;
        (bool result, ) = isAddressInArray(allBidersAddress, msg.sender);
        if (!result){
            allBidersAddress.push(msg.sender);
        }
    }



    function getAllBidders() public view returns(address[] memory){
        return allBidersAddress;
    }

    function transferToHigherBidder(uint256 _nftId) external payable {
        require(AuctionDataset[_nftId].started, "You need to start first!");
        require(block.timestamp >= AuctionDataset[_nftId].endAt, "Auction is still ongoing!");
        require(!AuctionDataset[_nftId].ended, "Auction already ended!");
        require(msg.sender == AuctionDataset[_nftId].seller, "Only Seller can Transfer NFT From marketplace!");
        if (AuctionDataset[_nftId].highestBidder != address(0)) {
            // transfer nft to higher bidder
            IERC721(nftContractAddr).safeTransferFrom(address(this), AuctionDataset[_nftId].highestBidder, _nftId); 
            (uint256 royaltyPercent, address royaltyAddr, uint256 platformFee, address platformAddr) = getRoyaltyPlatformFee(_nftId);

            // Refund Ethers to rest bidders
            for(uint256 i=0; i<allBidersAddress.length; i++){
                if (allBidersAddress[i] != AuctionDataset[_nftId].highestBidder){
                    // refund
                    payable(allBidersAddress[i]).transfer(bids[allBidersAddress[i]]);
                    bids[allBidersAddress[i]] = 0;
                }else{

                    uint256 NftPrice = AuctionDataset[_nftId].highestBid;
                    // uint256 totalAmountUserPay = getNFTFinalRate(NftPrice, _nftId);

                     // divide ether value in 2 part
                    uint256 etherValue_platform = (NftPrice * (platformFee))/100;
                    uint256 etherValue_royalty = (NftPrice * (royaltyPercent))/100;


                    // Distribute on 2 different address
                    // Transfer Platform Fee
                    payable(platformAddr).transfer(etherValue_platform);
                    // Transfer Royalty Fee
                    payable(royaltyAddr).transfer(etherValue_royalty);

                }
            }
        } else {
            IERC721(nftContractAddr).safeTransferFrom(address(this), AuctionDataset[_nftId].seller, _nftId); // transfer nft to seller
            
        }
        AuctionDataset[_nftId].ended = true;
    }


    function AuctionRemainingTime(uint256 _nftId) public view returns(uint256){
        uint256 currentTime = block.timestamp;
        if (AuctionDataset[_nftId].endAt > currentTime){
            return (AuctionDataset[_nftId].endAt - currentTime);
        }else{
            return 0;
        }

    }

    // --------------------------------- Auction Ended ------------------------------------------ //

    // Check Address Present or not in given Address Array
    function isAddressInArray(address[] memory _addrArray, address _addr) private pure returns (bool, uint256) {
        bool tempbool = false;
        uint256 index = 0;
        while (index < _addrArray.length) {
            if (_addrArray[index] == _addr) {
                tempbool = true;
                break;
            }
            index++;
        }
        return (tempbool, index);
    }


    // --------------------------------- FixSale Start ------------------------------------------ //

    // Make item to offer on the marketplace
    function putOnSale(uint256 _tokenId, uint256 _price) external nonReentrant {
        require(_price > 0, "Price must be greater than zero");
        Item storage item = items[_tokenId];
        // require(!item.forAuction, "item already exist on Auction");
        require(!item.forSale, "item already exist on Fixed Price");
        
        // transfer nft
        IERC721(nftContractAddr).transferFrom(msg.sender, address(this), _tokenId);
         // increment itemCount
        
        // add new item to items mapping
        items[_tokenId] = Item (_tokenId, nftContractAddr, _price, payable(msg.sender), true);
        // emit Offered event
        emit Offered(_tokenId, nftContractAddr,  _price, msg.sender);
    }


    function removeFromSale(uint256 _tokenId) external nonReentrant {
        Item storage item = items[_tokenId];
        require(address(item.seller) == msg.sender, "Only Nft owner can remove the NFT from sale");
        IERC721(nftContractAddr).transferFrom(address(this), msg.sender, item.tokenId);
        items[_tokenId] = Item (0, address(0), 0, payable(address(0)), false);
    }


    function purchaseNFT(uint256 _tokenId) external payable nonReentrant {
        Item storage item = items[_tokenId];
        (uint256 royaltyPercent, address royaltyAddr, uint256 platformFee, address platformAddr) = getRoyaltyPlatformFee(_tokenId);
        uint256 totalAmountUserPay = getNFTFinalRate(item.price, _tokenId);        // getNFTFinalRate(uint _sellPrice, uint256 _tokenId)


        require(msg.sender != address(0), "Zero address");
        require(item.forSale, "item doesn't exist");
        require(msg.value >= totalAmountUserPay, "Not enough ether to cover item price and market fee, Price + Platfrom Fee + Royalty");


        // divide ether value in 3 part
        uint256 etherValue_platform = (item.price * (platformFee))/100;
        uint256 etherValue_royalty = (item.price * (royaltyPercent))/100;
        uint256 etherValue_Selling = item.price;



        // Distribute on 3 different address
        payable(platformAddr).transfer(etherValue_platform);
        payable(royaltyAddr).transfer(etherValue_royalty);
        payable(item.seller).transfer(etherValue_Selling); // to creator address
        
     
        // // pay seller and royaltyAccount
        // item.seller.transfer(item.price);
        // payable(royaltyAddr).transfer(_totalPrice - item.price);

        // update item to sold
        item.forSale = false;
        // transfer nft to buyer
        IERC721(nftContractAddr).transferFrom(address(this), msg.sender, item.tokenId);
        // emit Bought event
        emit Bought(item.tokenId, item.nft, item.price, item.seller, msg.sender);

    }

    // function getTotalPrice(uint256 _tokenId) view public returns(uint256){
    //     // get royalti details
    //     (uint256 royaltyPercent, address royaltyAddr, uint256 platformFee, address platformAddr) = getRoyaltyPlatformFee(_tokenId);
    //     return((items[_tokenId].price*(100 + royaltyPercent))/100);
    // }

    function getRoyaltyPlatformFee(uint256 _nftId) public view returns(uint256, address, uint256, address){
          return IERC721(nftContractAddr).getRoyaltyAndPlatformFeeDetails(_nftId);
    }

    // --------------------------------- FixSale Ended ------------------------------------------ //

} 




    // function auctionBiding(uint256 _tokenId)  external nonReentrant payable {
    //     uint256 _totalPrice = getTotalPrice(_tokenId);
    //     Item storage item = items[_tokenId];
    //     // require(item.forAuction, "item doesn't available for Auction");
    //     require(msg.value > _totalPrice, "not enough ether to cover item price and market fee");
    //     (bool result, ) = isAddressInArray(auctionData[_tokenId].userAddr, msg.sender);
    //     require(!result, "User Already Present");
        
    //     // nft price + royalty transfer to seller
    //     item.seller.transfer(_totalPrice);

   
    //     auctionData[_tokenId].nftAmount.push(msg.value - _totalPrice); 
    //     auctionData[_tokenId].royaltiAmount.push(_totalPrice - item.price); 
    //     auctionData[_tokenId].userAddr.push(msg.sender); 
    //     // auctionData[_tokenId].status.push(true); 
    //     // auctionData[_tokenId].length += 1 ; 

    //     if (msg.value > auctionData[_tokenId].higherBidderAmnt){
    //         auctionData[_tokenId].higherBidderAmnt = msg.value;
    //         auctionData[_tokenId].higherBidderAddr = msg.sender;
    //     }
        
    // }