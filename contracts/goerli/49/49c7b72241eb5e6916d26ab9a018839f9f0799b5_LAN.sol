/**
 *Submitted for verification at Etherscan.io on 2022-07-23
*/

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


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: src/LAN.sol

pragma solidity ^0.8.15;


contract LAN{
    event newPool(
        uint256 indexed poolId,
        address collectionAddress,
        uint256 nftId
    );
    event newBid(
        uint256 indexed bidAmount,
        address user,
        uint256 indexed bidNum
    );
    event sold(address newOwner, uint256 bidAmount);
    event auctionCancelled(uint256 Id);

    uint256 public count;
    struct Auction {
        address owner;
        address collectionAddress;
        uint256 nftId;
        uint256 startTime;
        uint256 endTime;
        uint256 reward;
        uint256 numBids;
        uint256 totalPoints;
        uint256 withdrawn;
        bool nftDeposited;
    }
    mapping(uint256 => Auction) public auctions;

    struct Bid {
        uint256 bidTime;
        uint256 bidAmount;
        address user;
        uint256 points;
        bool withdrawn;
    }
    mapping(uint256 => mapping(uint256 => Bid)) public bids; //1st arg is for auction #, 2nd is bid #

    IERC20 public immutable Token; //token to denominate all activity
    constructor(address _token) {
        Token = IERC20(_token);
    }

    function launch(address _collectionAddress, uint256 _nftId, uint256 _startTime, uint256 _endTime, uint256 _reward) public {
        require(_startTime >= block.timestamp, "LAN: start time in past");
        require(_endTime > _startTime, "LAN: start after end");
        Token.transferFrom(msg.sender, address(this), _reward);
        auctions[count] = Auction({
            owner: msg.sender,
            collectionAddress: _collectionAddress,
            nftId: _nftId,
            endTime: _endTime,
            startTime: _startTime,
            reward: _reward,
            numBids: 0,
            totalPoints: 0,
            withdrawn: 0,
            nftDeposited: false
        });
        bids[count][0] = Bid({
            bidTime: block.timestamp,
            bidAmount: 0,
            user: msg.sender,
            points: 0,
            withdrawn: false
        });
        emit newPool(count, _collectionAddress, _nftId);
        count++;
    }
    
    function depositNFT(uint256 _poolId) public {
        //transfer NFT
        IERC721 NFT = IERC721(auctions[_poolId].collectionAddress);
        NFT.safeTransferFrom(msg.sender, address(this), auctions[_poolId].nftId);
        auctions[_poolId].nftDeposited = true;
    }
    //borrow functionality if NFT is escrowed on auction pool
    function borrow(uint256 _poolId, uint _borrowAmount) public {
        require(auctions[_poolId].owner == msg.sender, "LAN: not owner");
        require(auctions[_poolId].endTime > block.timestamp, "LAN: already ended");
        require(auctions[_poolId].nftDeposited == true, "LAN: NFT not deposited");
        uint256 bidNum = auctions[_poolId].numBids;
        uint256 highestBid = bids[_poolId][bidNum].bidAmount;
        require(auctions[_poolId].withdrawn + _borrowAmount <= highestBid, "LAN: At/above borrow limit");
        auctions[_poolId].withdrawn += _borrowAmount;
        Token.transfer(msg.sender, _borrowAmount);
    }
    //allows anyone to repay pool debt, allows debt to be overpaid, so pay the right amount :wink:
    function repay(uint256 _poolId, uint _repayAmount) public {
        require(auctions[_poolId].owner == msg.sender, "LAN: not owner");
        require(auctions[_poolId].endTime > block.timestamp, "LAN: already ended");
        uint256 bidNum = auctions[_poolId].numBids;
        uint256 highestBid = bids[_poolId][bidNum].bidAmount;
        auctions[_poolId].withdrawn -= _repayAmount;
        Token.transferFrom(msg.sender, address(this), _repayAmount);
    }
    //cancel if auction hasn't started yet
    function cancel(uint256 _poolId) external {
        require(auctions[_poolId].owner == msg.sender, "LAN: not owner");
        require(auctions[_poolId].startTime < block.timestamp, "LAN: already started");
        delete auctions[_poolId];
        emit auctionCancelled(_poolId);
    }
    function bid(uint256 _poolId, uint256 _amount) external {
        require(auctions[_poolId].startTime <= block.timestamp, "LAN: not started");
        require(auctions[_poolId].endTime > block.timestamp, "LAN: already ended");
        uint256 numBids = auctions[_poolId].numBids + 1;
        auctions[_poolId].numBids = numBids;
        require(_amount > bids[_poolId][numBids-1].bidAmount, "LAN: bid not higher");
        Token.transferFrom(msg.sender, address(this), _amount);
        //record data
        bids[_poolId][numBids] = Bid({
            bidTime: block.timestamp,
            bidAmount: _amount,
            user: msg.sender,
            points: 0, //will be calculated on next bid or _finalize
            withdrawn: false
        });
        //calculate points for previous bidder
        uint256 durationOfLastBid = block.timestamp - bids[_poolId][numBids-1].bidTime;
        uint256 points = durationOfLastBid * bids[_poolId][numBids-1].bidAmount;
        bids[_poolId][numBids-1].points = points;
        auctions[_poolId].totalPoints += points;
        emit newBid(_amount, msg.sender, numBids);
    }
    function withdrawDeposit(uint256 _poolId, uint256 _bidNum) external {
        require(bids[_poolId][_bidNum].user == msg.sender, "LAN: not the bidder");
        if(bids[_poolId][_bidNum+1].user == address(0)){
            //you are the highest bidder, can only withdraw if owner does not accept bid 24 hrs after deadline
            require(auctions[_poolId].endTime + 24 hours <= block.timestamp, "LAN: you are the highest bidder!");
        }
        require(!bids[_poolId][_bidNum].withdrawn, "LAN: already withdrawn");
        uint256 bidAmount = bids[_poolId][_bidNum].bidAmount;
        bids[_poolId][_bidNum].withdrawn = true;
        Token.transfer(msg.sender, bidAmount);
    }
    //need to claim multiple times for multiple bids
    function claimReward(uint256 _poolId, uint256 _bidNum) external {
        require(bids[_poolId][_bidNum].user == msg.sender, "LAN: not the bidder");
        if(!_isFinalized(_poolId)){
            _finalize(_poolId);
        }
        uint256 points = bids[_poolId][_bidNum].points;
        require(points != 0, "LAN: already claimed");
        uint256 totalReward = auctions[_poolId].reward;
        uint256 totalPoints = auctions[_poolId].totalPoints;
        //calculate reward
        uint256 reward = totalReward*points/totalPoints;
        bids[_poolId][_bidNum].points = 0;
        Token.transfer(msg.sender, reward);
    }
    //anyone can call this function :shrug:, can change in future if needed
    //liquidate the NFT if by the end there is outstanding debt. remaining portion of the bid goes to the buyer
    function liquidateBid(uint256 _poolId) external {
        uint256 endTime = auctions[_poolId].endTime;
        uint256 numBids = auctions[_poolId].numBids;
        uint256 amtDebt = auctions[_poolId].withdrawn;
        require(endTime <= block.timestamp, "LAN: auction not ended");
        require(amtDebt > 0, "LAN: Debt paid off/never taken");
        //transfer NFT
        IERC721 NFT = IERC721(auctions[_poolId].collectionAddress);
        address newOwner = bids[_poolId][numBids].user;
        NFT.safeTransferFrom(msg.sender, newOwner, auctions[_poolId].nftId);
        //withdraw token
        uint256 bidAmount = bids[_poolId][numBids].bidAmount;
        bids[_poolId][numBids].withdrawn = true;
        Token.transfer(msg.sender, bidAmount - amtDebt);
        emit sold(newOwner, bidAmount);
    }
    //trigger the last bid standing if the owner decides to
    function acceptBid(uint256 _poolId) external {
        require(auctions[_poolId].owner == msg.sender, "LAN: not owner");
        uint256 endTime = auctions[_poolId].endTime;
        require(endTime <= block.timestamp, "LAN: auction not ended");
        require(endTime + 24 hours > block.timestamp, "LAN: offer expired");
        uint256 numBids = auctions[_poolId].numBids;
        require(!bids[_poolId][numBids].withdrawn, "LAN: offer already previously accepted");
        //transfer NFT
        IERC721 NFT = IERC721(auctions[_poolId].collectionAddress);
        address newOwner = bids[_poolId][numBids].user;
        NFT.safeTransferFrom(msg.sender, newOwner, auctions[_poolId].nftId);
        //withdraw token
        uint256 bidAmount = bids[_poolId][numBids].bidAmount;
        bids[_poolId][numBids].withdrawn = true;
        Token.transfer(msg.sender, bidAmount);
        emit sold(newOwner, bidAmount);
    }

    //checks if the last bidder has points (aka has finalized been called)
    function _isFinalized(uint256 _poolId) internal view returns (bool){
        uint256 numBids = auctions[_poolId].numBids;
        return (bids[_poolId][numBids].points != 0);
    }
    function _finalize(uint256 _poolId) internal {
        uint256 endTime = auctions[_poolId].endTime;
        require(endTime <= block.timestamp, "LAN: auction not ended");
        uint256 numBids = auctions[_poolId].numBids;
        //calculate points for last bidder
        uint256 durationOfLastBid = endTime - bids[_poolId][numBids].bidTime;
        uint256 points = durationOfLastBid * bids[_poolId][numBids].bidAmount;
        bids[_poolId][numBids].points = points;
        auctions[_poolId].totalPoints += points;
    }
    
}