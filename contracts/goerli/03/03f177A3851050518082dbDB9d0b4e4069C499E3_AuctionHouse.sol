// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
* @title Sealed Bid Auction House
* @author kyrers
* @notice Allows a live auction to accept sealed bids, for users to open them and, if done in due time, recover their deposit if they're not the winners
*/
contract AuctionHouse is Ownable {
    /*------------------------------------------------------------
                                 VARIABLES
    --------------------------------------------------------------*/

    mapping(address => uint256) private bids;
    
    address[] public bidders;
    address public highestBidder;

    uint256 public highestBid;
    //End of auction
    uint256 public auctionEnd;
    //Limit for opening bids
    uint256 public openBidDeadline;
    
    /*------------------------------------------------------------
                                 MODIFIERS
    --------------------------------------------------------------*/
    modifier noLiveAuction() {
        if (block.timestamp <= openBidDeadline) revert AuctionAlreadyLive();
        _;
    }

    modifier validDuration(uint256 _duration) {
        if(_duration > 1440) revert LongerThanOneDay();
        _;
    }

    modifier liveAuction() {
        if (block.timestamp > auctionEnd) revert NoAuctionLive();
        _;
    }

    modifier isWithinOpeningPeriod() {
        if(block.timestamp <= auctionEnd || block.timestamp > openBidDeadline) revert OutsideBidOpeningPeriod();
        _;
    }
    
    /*------------------------------------------------------------
                                 EVENTS
    --------------------------------------------------------------*/
    event AuctionStarted(uint256 _auctionEnd, uint256 _openBidDeadline);
    event BidPlaced(address _account);
    event Withdrawal(address _account, uint256 _amount);

    /*------------------------------------------------------------
                                 ERRORS
    --------------------------------------------------------------*/
    error AuctionAlreadyLive();
    error LongerThanOneDay();
    error NoAuctionLive();
    error OutsideBidOpeningPeriod();
    error NoFundsSent();
    error NotEnoughBalance();
    error FailedToSendFunds();

    /*------------------------------------------------------------
                                 FUNCTIONS
    --------------------------------------------------------------*/
    /**
    * @notice Empty constructor
    */
    constructor() {}

    /**
    * @notice Allows owner to start an auction
    * @param _duration Duration of the auction in minutes
    */
    function startAuction(uint256 _duration) external onlyOwner noLiveAuction validDuration(_duration) {
        //Delete mappings
        resetMappings();

        //Update timestamps
        auctionEnd = block.timestamp + _duration * 1 minutes;
        openBidDeadline = auctionEnd + 5 minutes;

        //Update auction info
        highestBidder = address(0);
        highestBid = type(uint256).min;

        emit AuctionStarted(auctionEnd, openBidDeadline);
    }

    /**
    * @notice Allow user to make a bid
    */
    function placeBid() external payable liveAuction {
        //Check no value sent
        if (msg.value <= 0) revert NoFundsSent();

        //Update user bid and bidders array
        bids[msg.sender] += msg.value;
        bidders.push(msg.sender);
        
        emit BidPlaced(msg.sender);
    }

    /**
    * @notice Allow user to open the bid and recover funds if done in time and not the highest bidder
    * @dev If the highest bid is equal to msg.value, the older bid will stay as the highest
    */
    function openBid() external isWithinOpeningPeriod {
        uint256 bidValue = bids[msg.sender];

        //Check no bid made
        if (bidValue <= 0) revert NotEnoughBalance();

        //Check if highest bid
        if(highestBid == 0) {
            highestBid = bidValue;
            highestBidder = msg.sender;
        } else if(bidValue > highestBid) {
            uint256 previousHighestBid = highestBid;
            address previousHighestBidder = highestBidder;

            //Update previous highest bidder user balance
            bids[previousHighestBidder] = 0;

            highestBid = bidValue;
            highestBidder = msg.sender;

            //Process withdrawal to dethroned highest bidder
            if(previousHighestBidder != address(0)) {
                (bool success,) = address(previousHighestBidder).call{value: previousHighestBid}("");
                if(!success) revert FailedToSendFunds();

                emit Withdrawal(previousHighestBidder, previousHighestBid);
            }
        } else {
            //Update user balance
            bids[msg.sender] = 0;

            //Process withdrawal
            (bool success,) = address(msg.sender).call{value: bidValue}("");
            if(!success) revert FailedToSendFunds();
 
            emit Withdrawal(msg.sender, bidValue);
        }
    }

    /**
    * @notice Reset mappings and bidders array upon new auction start
    */
    function resetMappings() private {
        for (uint i=0; i< bidders.length ; i++){
            delete bids[bidders[i]];
        }

        delete bidders;
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