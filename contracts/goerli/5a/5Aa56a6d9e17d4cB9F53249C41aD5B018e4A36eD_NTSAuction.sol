// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function transferFrom(
        address,
        address,
        uint
    ) external;
}

contract NTSAuction is Ownable{

    event Start();
    event Withdraw(address indexed bidder, uint amount);
    event End(address winner, BidStr highestBid);
    event Bid(address indexed sender, BidStr highestBid);
    
    address private cath = 0x56bDc5fE7f9752E7F5a381E394acFE72A724462b;

    //define our bidding structure
    struct BidStr {
            uint BidValue;
            string imageId;
            string name;
        }

    BidStr public highestBid;

    uint public minIncrement = 100000000000000000; //0.1 eth in wei
    uint bidTimeExtension = 15 minutes;

    address public highestBidder;

    address payable public seller;
    uint public endAt;
    bool public started;
    bool public ended;
    
    mapping(address => uint) public bids;
    address[] public bidders;

    constructor(
        uint _startingBid,
        string memory _startingId,
        string memory _startingName
    ) {
        seller = payable(msg.sender);
        highestBid = BidStr(_startingBid, _startingId,_startingName);
    }


    function start() external onlyOwner {
        require(!started, "started");
        started = true;
        endAt = block.timestamp + 12 hours;
        emit Start();
    }

    function bid(
                string memory _imageID,
                string memory _imageName) external payable {
        require(started, "Auction not started yet");
        require(block.timestamp < endAt, "Auction is already over");
        require(msg.value >= highestBid.BidValue + minIncrement, "You must bid at least 0.1 eth higher than the previous bid");
        require(msg.sender != highestBidder, "You are already the highest bidder");

        address previousHighestBidder = highestBidder;
        
        highestBidder = msg.sender;
        highestBid = BidStr(msg.value, _imageID, _imageName);
        bids[highestBidder] += highestBid.BidValue;
        
        //send money back to previously highest bidder
        payable(previousHighestBidder).transfer(bids[previousHighestBidder]);
        bids[previousHighestBidder] = 0;

        // Allow 15 minutes for next bid if auction is almost done.
        if(endAt - block.timestamp < bidTimeExtension) {
            endAt = block.timestamp + bidTimeExtension;
        }
        
        emit Bid(msg.sender, highestBid);
    }

    function gethighestBid() public view returns (BidStr memory) {
        return highestBid;
    }

    function getHighestBidder() public view returns (address) {
        return highestBidder;
    }

    function end() public {
        require(endAt <= block.timestamp, "Auction is not over yet!");
        require(!ended, "End already called");

        payable(cath).transfer((highestBid.BidValue * 9) / 10);
        payable(owner()).transfer((highestBid.BidValue  / 10));

        bids[highestBidder] = 0;

        ended = true;
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