// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/ITOPIA.sol';
import './interfaces/INFT.sol';
import './interfaces/IHUB.sol';


contract TopiaNFTVault is ReentrancyGuard, Ownable, IERC721Receiver {
    using SafeERC20 for IERC20;

    // The ERC721 token contracts
    INFT public ALPHA;
    INFT public GENESIS;
    INFT public RATS;
    IHUB public HUB;

    // The address of the DUST contract
    ITOPIA public TOPIA;

    address public sweepersTreasury;

    // The minimum amount of time left in an auction after a new bid is created
    uint32 public timeBufferThreshold;
    // The amount of time to add to the auction when a bid is placed under the timeBufferThreshold
    uint32 public timeBuffer;

    // The minimum percentage difference between the last bid amount and the current bid
    uint16 public minBidIncrementPercentage;

    address payable public Dev;
    uint256 public DevFee = 0.0005 ether;

    // The auction info
    struct Auction {
        // The Contract Address for the listed NFT
        INFT contractAddress;
        // The Token ID for the listed NFT
        uint16 tokenId;
        // The time that the auction started
        uint32 startTime;
        // The time that the auction is scheduled to end
        uint32 endTime;
        // The opening price for the auction
        uint256 startingPrice;
        // The current bid amount in DUST
        uint256 currentBid;
        // The previous bid amount in DUST
        uint256 previousBid;
        // The active bidId
        uint32 activeBidId;
        // The address of the current highest bid
        address bidder;
        // The number of bids placed
        uint16 numberBids;
        // The statuses of the auction
        bool blind;
        bool settled;
        bool failed;
        string hiddenImage;
    }
    mapping(uint32 => Auction) public auctionId;
    uint32 private currentAuctionId = 0;
    uint32 private currentBidId = 0;
    uint32 public activeAuctionCount;

    struct Bids {
        uint256 bidAmount;
        address bidder;
        uint32 auctionId;
        uint8 bidStatus; // 1 = active, 2 = outbid, 3 = canceled, 4 = accepted
    }
    mapping(uint32 => Bids) public bidId;
    mapping(uint32 => uint32[]) public auctionBids;
    mapping(address => uint32[]) public userBids;
    bool public mustHold;

    modifier holdsMetatopia() {
        require(!mustHold || ALPHA.balanceOf(msg.sender) > 0 || GENESIS.balanceOf(msg.sender) > 0 || RATS.balanceOf(msg.sender) > 0 || HUB.balanceOf(msg.sender) > 0, "Must hold a Sweeper NFT");
        _;
    }

    modifier onlySweepersTreasury() {
        require(msg.sender == sweepersTreasury || msg.sender == owner(), "Sender not allowed");
        _;
    }

    event AuctionCreated(uint32 indexed AuctionId, uint32 startTime, uint32 endTime, address indexed NFTContract, uint16 indexed TokenId, bool BlindAuction);
    event AuctionSettled(uint32 indexed AuctionId, address indexed NFTProjectAddress, uint16 tokenID, address buyer, uint256 finalAmount);
    event AuctionFailed(uint32 indexed AuctionId, address indexed NFTProjectAddress, uint16 tokenID);
    event AuctionCanceled(uint32 indexed AuctionId, address indexed NFTProjectAddress, uint16 tokenID);
    event AuctionExtended(uint32 indexed AuctionId, uint32 NewEndTime);
    event AuctionTimeBufferUpdated(uint32 timeBuffer);
    event AuctionMinBidIncrementPercentageUpdated(uint16 minBidIncrementPercentage);
    event BidPlaced(uint32 indexed BidId, uint32 indexed AuctionId, address sender, uint256 value);

    constructor(
        // address _alpha,
        // address _genesis,
        // address _rats,
        // address _hub,
        address _topia,
        uint32 _timeBuffer,
        uint16 _minBidIncrementPercentage
    ) {
        // ALPHA = INFT(_alpha);
        // GENESIS = INFT(_genesis);
        // RATS = INFT(_rats);
        // HUB = IHUB(_hub);
        TOPIA = ITOPIA(_topia);
        timeBuffer = _timeBuffer;
        timeBufferThreshold = _timeBuffer;
        minBidIncrementPercentage = _minBidIncrementPercentage;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @notice Set the auction time buffer.
     * @dev Only callable by the owner.
     */
    function setTimeBuffer(uint32 _timeBufferThreshold, uint32 _timeBuffer) external onlyOwner {
        require(timeBuffer >= timeBufferThreshold, 'timeBuffer must be >= timeBufferThreshold');
        timeBufferThreshold = _timeBufferThreshold;
        timeBuffer = _timeBuffer;

        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    function setDev(address _dev, uint256 _devFee) external onlyOwner {
        Dev = payable(_dev);
        DevFee = _devFee;
    }

    function setHUB(address _hub) external onlyOwner {
        HUB = IHUB(_hub);
    }

    function setMustHold(bool _flag) external onlyOwner {
        mustHold = _flag;
    }

    function updateSweepersTreasury(address _treasury) external onlyOwner {
        sweepersTreasury = _treasury;
    }

    /**
     * @notice Set the auction minimum bid increment percentage.
     * @dev Only callable by the owner.
     */
    function setMinBidIncrementPercentage(uint16 _minBidIncrementPercentage) external onlyOwner {
        minBidIncrementPercentage = _minBidIncrementPercentage;

        emit AuctionMinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
    }

    function createAuction(address _nftContract, uint16 _tokenId, uint32 _startTime, uint32 _endTime, uint256 _startingPrice) external onlySweepersTreasury nonReentrant {
        uint32 id = currentAuctionId++;

        auctionId[id] = Auction({
            contractAddress : INFT(_nftContract),
            tokenId : _tokenId,
            startTime : _startTime,
            endTime : _endTime,
            startingPrice : _startingPrice,
            currentBid : 0,
            previousBid : 0,
            activeBidId : 0,
            bidder : address(0),
            numberBids : 0,
            blind : false,
            settled : false,
            failed : false,
            hiddenImage : 'null'
        });
        activeAuctionCount++;

        IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId);

        emit AuctionCreated(id, _startTime, _endTime, _nftContract, _tokenId, false);
    }

    function createManyAuctionSameProject(address _nftContract, uint16[] calldata _tokenIds, uint32 _startTime, uint32 _endTime, uint256 _startingPrice) external onlySweepersTreasury nonReentrant {
        
        for(uint i = 0; i < _tokenIds.length; i++) {
            uint32 id = currentAuctionId++;
            auctionId[id] = Auction({
                contractAddress : INFT(_nftContract),
                tokenId : _tokenIds[i],
                startTime : _startTime,
                endTime : _endTime,
                startingPrice : _startingPrice,
                currentBid : 0,
                previousBid : 0,
                activeBidId : 0,
                bidder : address(0),
                numberBids : 0,
                blind : false,
                settled : false,
                failed : false,
                hiddenImage : 'null'
            });
            activeAuctionCount++;

            IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenIds[i]);

            emit AuctionCreated(id, _startTime, _endTime, _nftContract, _tokenIds[i], false);
        }
    }

    function createBlindAuction(address _nftContract, uint32 _startTime, uint32 _endTime, string calldata _hiddenImage, uint256 _startingPrice) external onlySweepersTreasury nonReentrant {
        uint32 id = currentAuctionId++;

        auctionId[id] = Auction({
            contractAddress : INFT(_nftContract),
            tokenId : 0,
            startTime : _startTime,
            endTime : _endTime,
            startingPrice : _startingPrice,
            currentBid : 0,
            previousBid : 0,
            activeBidId : 0,
            bidder : address(0),
            numberBids : 0,
            blind : true,
            settled : false,
            failed : false,
            hiddenImage : _hiddenImage
        });
        activeAuctionCount++;       

        emit AuctionCreated(id, _startTime, _endTime, _nftContract, 0, true);
    }

    function createManyBlindAuctionSameProject(address _nftContract, uint16 _numAuctions, uint32 _startTime, uint32 _endTime, string calldata _hiddenImage, uint256 _startingPrice) external onlySweepersTreasury nonReentrant {
        
        for(uint i = 0; i < _numAuctions; i++) {
            uint32 id = currentAuctionId++;
            auctionId[id] = Auction({
                contractAddress : INFT(_nftContract),
                tokenId : 0,
                startTime : _startTime,
                endTime : _endTime,
                startingPrice : _startingPrice,
                currentBid : 0,
                previousBid : 0,
                activeBidId : 0,
                bidder : address(0),
                numberBids : 0,
                blind : true,
                settled : false,
                failed : false,
                hiddenImage : _hiddenImage
            });
            activeAuctionCount++;

            emit AuctionCreated(id, _startTime, _endTime, _nftContract, 0, true);
        }
    }

    function updateBlindAuction(uint32 _id, uint16 _tokenId) external onlySweepersTreasury {
        require(auctionId[_id].tokenId == 0, "Auction already updated");
        auctionId[_id].tokenId = _tokenId;
        auctionId[_id].contractAddress.safeTransferFrom(msg.sender, address(this), _tokenId);
        auctionId[_id].blind = false;
    }

    function updateManyBlindAuction(uint32[] calldata _ids, uint16[] calldata _tokenIds) external onlySweepersTreasury {
        require(_ids.length == _tokenIds.length, "_id and tokenId must be same length");
        for(uint i = 0; i < _ids.length; i++) {
            require(auctionId[_ids[i]].tokenId == 0, "Auction already updated");
            auctionId[_ids[i]].tokenId = _tokenIds[i];
            auctionId[_ids[i]].contractAddress.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            auctionId[_ids[i]].blind = false;
        } 
    }

    function updateBlindImage(uint32 _id, string calldata _hiddenImage) external onlySweepersTreasury {
        auctionId[_id].hiddenImage = _hiddenImage;
    }

    function updateManyBlindImage(uint32[] calldata _ids, string calldata _hiddenImage) external onlySweepersTreasury {
        for(uint i = 0; i < _ids.length; i++) {
            auctionId[_ids[i]].hiddenImage = _hiddenImage;
        } 
    }

    function updateAuctionStartingPrice(uint32 _id, uint256 _startingPrice) external onlySweepersTreasury {
        require(auctionId[_id].currentBid < auctionId[_id].startingPrice, 'Auction already met startingPrice');
        auctionId[_id].startingPrice = _startingPrice;
    }

    function updateManyAuctionStartingPrice(uint32[] calldata _ids, uint256 _startingPrice) external onlySweepersTreasury {
        for(uint i = 0; i < _ids.length; i++) {
            if(auctionId[_ids[i]].currentBid < auctionId[_ids[i]].startingPrice) {
                auctionId[_ids[i]].startingPrice = _startingPrice;
            } else {
                continue;
            }
        }
    }

    function updateAuctionEndTime(uint32 _id, uint32 _newEndTime) external onlySweepersTreasury {
        require(auctionId[_id].currentBid == 0, 'Auction already met startingPrice');
        auctionId[_id].endTime = _newEndTime;
        emit AuctionExtended(_id, _newEndTime);
    }

    function updateManyAuctionEndTime(uint32[] calldata _ids, uint32 _newEndTime) external onlySweepersTreasury {
        for(uint i = 0; i < _ids.length; i++) {
            if(auctionId[_ids[i]].currentBid == 0) {
                auctionId[_ids[i]].endTime = _newEndTime;
                emit AuctionExtended(_ids[i], _newEndTime);
            } else {
                continue;
            }
        }
    }

    function emergencyCancelAllAuctions() external onlySweepersTreasury {
        for(uint32 i = 0; i < currentAuctionId; i++) {
            uint8 status = auctionStatus(i);
            if(status == 1) {
                _cancelAuction(i);
            } else {
                continue;
            }
        }
    }

    function emergencyCancelAuction(uint32 _id) external onlySweepersTreasury {
        require(auctionStatus(_id) == 1, 'Can only cancel active auctions');
        _cancelAuction(_id);
    }

    function _cancelAuction(uint32 _id) private {
        auctionId[_id].endTime = uint32(block.timestamp);
        auctionId[_id].failed = true;
        address lastBidder = auctionId[_id].bidder;

        // Refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            TOPIA.mint(lastBidder, auctionId[_id].currentBid);
            bidId[auctionId[_id].activeBidId].bidStatus = 3;
            auctionId[_id].previousBid = auctionId[_id].currentBid;
        }
        IERC721(auctionId[_id].contractAddress).transferFrom(address(this), Dev, auctionId[_id].tokenId);
        emit AuctionCanceled(_id, address(auctionId[_id].contractAddress), auctionId[_id].tokenId);
    }

    /**
     * @notice Create a bid for a NFT, with a given amount.
     * @dev This contract only accepts payment in TOPIA.
     */
    function createBid(uint32 _id, uint256 _bidAmount) external payable holdsMetatopia nonReentrant {
        require(auctionStatus(_id) == 1, 'Auction is not Active');
        require(block.timestamp < auctionId[_id].endTime, 'Auction expired');
        require(msg.value == DevFee, 'Fee not covered');
        require(_bidAmount >= auctionId[_id].startingPrice, 'Bid amount must be at least starting price');
        require(
            _bidAmount >= auctionId[_id].currentBid + ((auctionId[_id].currentBid * minBidIncrementPercentage) / 10000),
            'Must send more than last bid by minBidIncrementPercentage amount'
        );

        address lastBidder = auctionId[_id].bidder;
        uint32 _bidId = currentBidId++;

        // Refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            TOPIA.mint(lastBidder, auctionId[_id].currentBid);
            bidId[auctionId[_id].activeBidId].bidStatus = 2;
            auctionId[_id].previousBid = auctionId[_id].currentBid;
        }

        auctionId[_id].currentBid = _bidAmount;
        auctionId[_id].bidder = msg.sender;
        auctionId[_id].activeBidId = _bidId;
        auctionBids[_id].push(_bidId);
        auctionId[_id].numberBids++;
        bidId[_bidId].bidder = msg.sender;
        bidId[_bidId].bidAmount = _bidAmount;
        bidId[_bidId].auctionId = _id;
        bidId[_bidId].bidStatus = 1;
        userBids[msg.sender].push(_bidId);

        TOPIA.burnFrom(msg.sender, _bidAmount);

        // Extend the auction if the bid was received within `timeBufferThreshold` of the auction end time
        bool extended = auctionId[_id].endTime - block.timestamp < timeBufferThreshold;
        if (extended) {
            auctionId[_id].endTime = uint32(block.timestamp) + timeBuffer;
            emit AuctionExtended(_id, auctionId[_id].endTime);
        }

        Dev.transfer(DevFee);

        emit BidPlaced(_bidId, _id, msg.sender, _bidAmount);
    }

    /**
     * @notice Settle an auction, finalizing the bid and transferring the NFT to the winner.
     * @dev If there are no bids, the Auction is failed and can be relisted.
     */
    function _settleAuction(uint32 _id) external {
        require(auctionStatus(_id) == 2, "Auction can't be settled at this time");
        require(auctionId[_id].tokenId != 0, "Auction TokenId must be updated first");

        auctionId[_id].settled = true;
        if (auctionId[_id].bidder == address(0) && auctionId[_id].currentBid == 0) {
            auctionId[_id].failed = true;
            IERC721(auctionId[_id].contractAddress).transferFrom(address(this), Dev, auctionId[_id].tokenId);
            emit AuctionFailed(_id, address(auctionId[_id].contractAddress), auctionId[_id].tokenId);
        } else {
            IERC721(auctionId[_id].contractAddress).transferFrom(address(this), auctionId[_id].bidder, auctionId[_id].tokenId);
        }
        activeAuctionCount--;
        emit AuctionSettled(_id, address(auctionId[_id].contractAddress), auctionId[_id].tokenId, auctionId[_id].bidder, auctionId[_id].currentBid);
    }

    function auctionStatus(uint32 _id) public view returns (uint8) {
        if (block.timestamp >= auctionId[_id].endTime && auctionId[_id].tokenId == 0) {
        return 5; // AWAITING TOKENID - Auction finished
        }
        if (auctionId[_id].failed) {
        return 4; // FAILED - not sold by end time
        }
        if (auctionId[_id].settled) {
        return 3; // SUCCESS - Bidder won 
        }
        if (block.timestamp >= auctionId[_id].endTime) {
        return 2; // AWAITING SETTLEMENT - Auction finished
        }
        if (block.timestamp <= auctionId[_id].endTime && block.timestamp >= auctionId[_id].startTime) {
        return 1; // ACTIVE - bids enabled
        }
        return 0; // QUEUED - awaiting start time
    }

    function getBidsByAuctionId(uint32 _id) external view returns (uint32[] memory bidIds) {
        uint256 length = auctionBids[_id].length;
        bidIds = new uint32[](length);
        for(uint i = 0; i < length; i++) {
            bidIds[i] = auctionBids[_id][i];
        }
    }

    function getBidsByUser(address _user) external view returns (uint32[] memory bidIds) {
        uint256 length = userBids[_user].length;
        bidIds = new uint32[](length);
        for(uint i = 0; i < length; i++) {
            bidIds[i] = userBids[_user][i];
        }
    }

    function getTotalBidsLength() external view returns (uint32) {
        return currentBidId - 1;
    }

    function getBidsLengthForAuction(uint32 _id) external view returns (uint256) {
        return auctionBids[_id].length;
    }

    function getBidsLengthForUser(address _user) external view returns (uint256) {
        return userBids[_user].length;
    }

    function getBidInfoByIndex(uint32 _bidId) external view returns (address _bidder, uint256 _bidAmount, uint32 _auctionId, string memory _bidStatus) {
        _bidder = bidId[_bidId].bidder;
        _bidAmount = bidId[_bidId].bidAmount;
        _auctionId = bidId[_bidId].auctionId;
        if(bidId[_bidId].bidStatus == 1) {
            _bidStatus = 'active';
        } else if(bidId[_bidId].bidStatus == 2) {
            _bidStatus = 'outbid';
        } else if(bidId[_bidId].bidStatus == 3) {
            _bidStatus = 'canceled';
        } else if(bidId[_bidId].bidStatus == 4) {
            _bidStatus = 'accepted';
        } else {
            _bidStatus = 'invalid BidID';
        }
    }

    function getBidStatus(uint32 _bidId) external view returns (string memory _bidStatus) {
        if(bidId[_bidId].bidStatus == 1) {
            _bidStatus = 'active';
        } else if(bidId[_bidId].bidStatus == 2) {
            _bidStatus = 'outbid';
        } else if(bidId[_bidId].bidStatus == 3) {
            _bidStatus = 'canceled';
        } else if(bidId[_bidId].bidStatus == 4) {
            _bidStatus = 'accepted';
        } else {
            _bidStatus = 'invalid BidID';
        }
    }

    function getActiveAuctions() external view returns (uint32[] memory _activeAuctions) {
        _activeAuctions = new uint32[](activeAuctionCount);
        for(uint32 i = 0; i < currentAuctionId; i++) {
            uint32 z = 0;
            uint8 status = auctionStatus(i);
            if(status == 1) {
                _activeAuctions[z] = i;
                z++;
            } else {
                continue;
            }
        }
    }

    function getAllAuctions() external view returns (uint32[] memory auctions, uint8[] memory status) {
        auctions = new uint32[](currentAuctionId);
        status = new uint8[](currentAuctionId);
        for(uint32 i = 1; i <= currentAuctionId; i++) {
            auctions[i] = i;
            status[i] = auctionStatus(i);
        }
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IHUB {
    function emitGenesisStaked(address owner, uint16[] calldata tokenIds, uint8 gameId) external;
    function emitAlphaStaked(address owner, uint16[] calldata tokenIds, uint8 gameId) external;
    function emitGenesisUnstaked(address owner, uint16[] calldata tokenIds) external;
    function emitAlphaUnstaked(address owner, uint16[] calldata tokenIds) external;
    function emitTopiaClaimed(address owner, uint256 amount) external;
    function balanceOf(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface INFT is IERC721Enumerable {
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface ITOPIA {
	event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function burn(uint256 _amount) external;
    function burnFrom(address _from, uint256 _amount) external;
    function mint(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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