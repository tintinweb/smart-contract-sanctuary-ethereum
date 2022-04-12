/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/interfaces/IERC721Metadata.sol

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Metadata.sol)

pragma solidity ^0.8.0;

// File: contracts/ILandNFT721.sol


pragma solidity ^0.8.0;

interface ISNLand is IERC721Metadata {
    function setPause() external;
    function setUnpause() external;
    function getFloorPrice(uint256 tokenId) external view returns (uint256);
    function mint(address to, uint256 tokenId) external payable;
    function addPriceFloor(uint256 tokenId) external payable;
    function burn(uint256 tokenId) external;
}

// File: contracts/LandAuction.sol

pragma solidity ^0.8.6;


contract AuctionContract is Ownable{
    ISNLand nft;

    uint256 fee;
    uint256 extraTime;
    uint256 percentPrice;

    struct Auction {
        address seller;
        uint256 tokenId;
        uint256 minPrice;
        uint256 startTime;
        uint256 endTime;
    }

    struct BidInfo {
        address bidder;
        uint256 bidAmount;
        uint256 bidAt;
        bool claimed;
    }

    uint256 private numAuctions;
    Auction[] public auctions;

    mapping(uint256 => uint256) public tokenIdToAuctionId; 
    mapping(uint256 => address[]) public tokenIdtoBidders;

    mapping(address => uint256[]) public userSellingTokens; // seller => tokenIds

    mapping(uint256 => mapping(address => uint256)) public bidderToIndex; // tokenId => bidder => indexOfBid
    mapping(uint256 => mapping(uint256 => address)) public indexToBidder; // tokenId => indexOfBid => bidder
    mapping(address => mapping(uint256 => BidInfo)) public userBids;   // user => tokenID => BidInfo

    event CreateAuction(uint256 tokenId, uint256 startTime,uint256 endTime, uint256 minPrice, address indexed seller, uint256 auctionId);
    event BidOnToken(uint256 tokenId, address indexed bidder, uint256 amount);
    

    constructor(address _nftAddress){
        nft = ISNLand(_nftAddress);
        fee = 5;
        extraTime = 100;
        percentPrice = 10;
        auctions.push();
    }

    function createAuction(uint256 _tokenId, uint256 _startTime, uint256 _endTime, uint256 _minPrice) public onlyOwner returns(uint256) {
        address seller = msg.sender;

        // require(nft.ownerOf(_tokenId) == seller, "Auction: you are not the owner of this token");
        require(_minPrice > 0, "Auction: price must be granter than zero");
        require(_startTime > 0, "Auction: startTime must be granter than zero");
        require(_endTime > 0, "Auction: endTime must be granter than zero");
        require(_endTime > _startTime, "Auction: endTime must be granter than startTime");

        uint256 auctionId = numAuctions++;

        tokenIdToAuctionId[_tokenId] = auctionId;
        userSellingTokens[seller].push(_tokenId);

        Auction memory auction = Auction(seller, _tokenId, _minPrice, _startTime, _endTime);
        auctions.push(auction);

        emit CreateAuction(_tokenId, _startTime, _endTime, _minPrice, seller, auctionId);

        return auctionId;
    }

    function bidOnToken(uint256 _tokenId) public payable {
        address bidder = msg.sender;
        uint256 auctionId = tokenIdToAuctionId[_tokenId];
        require(block.timestamp >= auctions[auctionId].startTime, "Auction: wait to start");
        require(block.timestamp <= auctions[auctionId].endTime, "Auction: ended");

        uint256 lengthBidsOnToken = tokenIdtoBidders[_tokenId].length;
        address highestBidder = tokenIdtoBidders[_tokenId][lengthBidsOnToken-1];
        uint256 previosBidPrice = userBids[bidder][_tokenId].bidAmount;

        uint256 maxPreviousPrice = auctions[auctionId].minPrice;

        if (lengthBidsOnToken !=0) {
            maxPreviousPrice = userBids[highestBidder][_tokenId].bidAmount;
        }
        
        uint256 totalAmount = previosBidPrice + msg.value;

        require(totalAmount >= maxPreviousPrice*(100+ percentPrice)/100, "Auction: your bid amount must be greater highest");

        if (previosBidPrice !=0) {
            _removeBid(bidder, _tokenId);
        }

        _addNewBid(bidder, totalAmount, _tokenId);

        Auction storage auction = auctions[auctionId];
        auction.endTime += extraTime;

        emit BidOnToken(_tokenId, bidder, totalAmount);

    }

    function changeInfoAuction(uint256 _tokenId, uint256 _startTime, uint256 _endTime, uint256 _minPrice) public onlyOwner {
        require(tokenIdtoBidders[_tokenId].length == 0, "Auction: Can not change info when have bidder");
        uint256 auctionId = tokenIdToAuctionId[_tokenId];

        Auction storage auction = auctions[auctionId];

        auction.startTime = _startTime;
        auction.endTime = _endTime;
        auction.minPrice = _minPrice;
    }
    
    function _removeBid(address bidder, uint256 _tokenId) internal{
        uint256 indexBid = bidderToIndex[_tokenId][bidder];
        uint256 lengthBidsOnToken = tokenIdtoBidders[_tokenId].length;

        if( indexBid == lengthBidsOnToken -1){
            tokenIdtoBidders[_tokenId].pop();
            delete indexToBidder[_tokenId][indexBid];
        } else {
            for(uint256 i = indexBid; i < lengthBidsOnToken-1; i++){
                tokenIdtoBidders[_tokenId][i] = tokenIdtoBidders[_tokenId][i+1];
                indexToBidder[_tokenId][i] = indexToBidder[_tokenId][i+1];
            }

            tokenIdtoBidders[_tokenId].pop();
        }

        delete bidderToIndex[_tokenId][bidder];
        delete userBids[bidder][_tokenId];
    }

    function _addNewBid(address bidder, uint256 _amount, uint256 _tokenId) internal {
        BidInfo memory bidinfo = BidInfo(bidder, _amount, block.timestamp, false);

        tokenIdtoBidders[_tokenId].push(bidder);

        uint256 lengthBidsOnToken = tokenIdtoBidders[_tokenId].length;

        indexToBidder[_tokenId][lengthBidsOnToken - 1] = bidder;
        bidderToIndex[_tokenId][bidder] = lengthBidsOnToken - 1;

        userBids[bidder][_tokenId] = bidinfo;
    }

    function removeBid(uint256 _tokenId) public {
        uint256 auctionId = tokenIdToAuctionId[_tokenId];
        address bidder = msg.sender;
        require(block.timestamp >= auctions[auctionId].startTime);
        require(block.timestamp <= auctions[auctionId].endTime);
        require(bidder == userBids[bidder][_tokenId].bidder);

        uint256 bidAmount = userBids[bidder][_tokenId].bidAmount;

        _removeBid(bidder, _tokenId);
        payable(bidder).transfer(bidAmount);

    }

    // function removeAuction(uint256 _tokenId) public {
    //     uint256 auctionId = tokenIdToAuctionId[_tokenId];
    //     require(auctions[auctionId].seller == msg.sender, "You are not owner of auction");
    //     uint256 actionIndex = tokenIdToAuctionId[_tokenId];
    //     uint256 totalAuction = auctions.length;
        
    //     // Remove auction
    //     delete tokenIdToAuctionId[_tokenId];


    //     for (uint256 i = actionIndex; i < totalAuction; i++){
    //         auctions[i] = auctions[i+1];

    //         uint256 nextTokenId =  auctions[i + 1].tokenId;
    //         tokenIdToAuctionId[nextTokenId]--;
    //     }

    //     numAuctions--;
    //     auctions.pop();

    //     delete userSellingTokens[msg.sender][_tokenId];

    //     // Remove Bids
    //     uint256 lengthBidsOnToken = tokenIdtoBidders[_tokenId].length;
    //     for (uint256 i=0; i < lengthBidsOnToken; i++){
    //         address bidder = tokenIdtoBidders[_tokenId][i];
    //         BidInfo memory bidInfo = userBids[bidder][_tokenId];

    //         // TODO Trao giai nhat
    //         if (bidInfo.claimed == false) {
    //             payable(bidder).transfer(bidInfo.bidAmount);
    //         }

    //         delete userBids[bidder][_tokenId];
    //         delete bidderToIndex[_tokenId][bidder];
    //         delete indexToBidder[_tokenId][i];
    //     }

    //     delete tokenIdtoBidders[_tokenId];
    // }

    function getMaxBid(uint256 _tokenId) public view returns (BidInfo memory) {
        uint256 length = tokenIdtoBidders[_tokenId].length;
        address highestBidder = tokenIdtoBidders[_tokenId][length-1];
        return userBids[highestBidder][_tokenId];
    }

    function getAllBidder(uint256 _tokenId) public view returns (address[] memory)
    {
        return tokenIdtoBidders[_tokenId];
    }


    function getBidByUser(uint256 _tokenId, address addr) public view returns (BidInfo memory)
    {
        return userBids[addr][_tokenId];
    }

    function getAuctionsByUser(address user) public view returns (Auction[] memory)
    {
        Auction[] memory auctionOfUser = new Auction[](userSellingTokens[user].length);
        for (uint256 i = 0; i < userSellingTokens[user].length; i++) {
            uint256 auctionId = tokenIdToAuctionId[userSellingTokens[user][i]];
            Auction memory _auction = auctions[auctionId];
            auctionOfUser[i] = _auction;
        }
        return auctionOfUser;
    }

    function getAllAuctions() public view returns (Auction[] memory) {
        return auctions;
    }

    function getTotalAuction() public view returns(uint256){
        return auctions.length;
    }
    
    function mintNFT(uint256 _tokenId) public {
        address bidder = msg.sender;
        uint256 auctionId = tokenIdToAuctionId[_tokenId];
        require(block.timestamp > auctions[auctionId].endTime, "Auction: wait to endtime");

        uint256 lengthBidsOnToken = tokenIdtoBidders[_tokenId].length;
        address maxBidderOnToken = tokenIdtoBidders[_tokenId][lengthBidsOnToken-1];

        require(bidder != maxBidderOnToken, "Action: you are winner");
        uint256 feeOfToken = userBids[bidder][_tokenId].bidAmount*(fee+100)/100;
        nft.mint{value: feeOfToken}(bidder, _tokenId);
    }

     function withdraw(uint256 _tokenId) public {
        address bidder = msg.sender;
        uint256 auctionId = tokenIdToAuctionId[_tokenId];
        require(block.timestamp > auctions[auctionId].endTime, "Auction: wait to endtime");

        uint256 bidAmount = userBids[bidder][_tokenId].bidAmount;
        uint256 lengthBidsOnToken = tokenIdtoBidders[_tokenId].length;
        address maxBidderOnToken = tokenIdtoBidders[_tokenId][lengthBidsOnToken-1];

        require(bidder == maxBidderOnToken, "Action: you  are winner");

        userBids[bidder][_tokenId].claimed = true;
        payable(bidder).transfer(bidAmount);
            
    }
}