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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

interface IToken {
    struct UserAmount {
        address to;
        uint96 amount;
    }
    function airdrop(UserAmount[] calldata airdropData) external;
}

contract FairAuction is Ownable {

    modifier directOnly {
        require(msg.sender == tx.origin);
        _;
    }

    struct BidData {
        uint240 currentBid;
        bool mintClaimed;
        bool refundClaimed;
    }

    mapping(address => BidData) public userToBidData;

    // Auction settings
    bool public auctionOpen;
    uint256 public auctionSupply;
    uint256 public finalPrice;

    // Starting bid settings
    uint256 public baseBid;
    uint256 public startingBidMultiplier;
    uint256 public minBalanceToIncrement;

    // Secondary address
    address public secondaryAddress;
    uint256 public secondaryPercentage;

    // Token contract address
    IToken public token;

    event Bid(address indexed user, uint256 bidAmount, uint256 currentBid, uint256 totalBid);
    event AuctionClaimAndRefund(address indexed user, uint256 mint, uint256 refund);

    constructor() { 
        auctionSupply = 2888;
        baseBid = 0.04 ether;
        startingBidMultiplier = 0.01 ether;
        minBalanceToIncrement = 30 ether;
    }

    function bid() external payable directOnly {
        require(auctionOpen, "Auction is not live");

        // Bid must have value and be multiplier of 0.01 ETH
        require(msg.value > 0 && msg.value % 0.01 ether == 0, "Bid is not multiplier of 0.01 ETH");

        // First time bidder must bid higher than starting bid 
        if (userToBidData[msg.sender].currentBid == 0) {
            require (msg.value >= getStartingBid(), "Bid is lower than starting bid");
        }
        
        // Update existing bid
        emit Bid(msg.sender, msg.value, userToBidData[msg.sender].currentBid += uint240(msg.value), address(this).balance);
    }

    // Owner functions
    

    function setAuctionOpen(bool _status) external onlyOwner {
        auctionOpen = _status;
    }

    function setAuctionSupply(uint256 _supply) external onlyOwner {
        auctionSupply = _supply;
    }

    function setFinalPrice(uint256 _price) external onlyOwner {
        finalPrice = _price;
    }

    function setTokenAddress(address _address) external onlyOwner {
        token = IToken(_address);
    }

    function setSecondaryAddress(address _address) external onlyOwner {
        secondaryAddress = _address;
    }

    function setSecondaryPercentage(uint256 _percentage) external onlyOwner {
        secondaryPercentage = _percentage;
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(secondaryAddress != address(0), "Secondary address is not set");
        require(secondaryPercentage > 0, "Secondary percentage is not set");
        _sendETH(msg.sender, (100 - secondaryPercentage) * amount / 100);
        _sendETH(secondaryAddress, (secondaryPercentage) * amount / 100);
    }

    function deposit() external onlyOwner payable { }

    function adminProcessAuctionClaimAndRefund(address[] calldata users) external onlyOwner {
        unchecked {
            require(!auctionOpen, "Auction is still live");
            require(address(token) != address(0), "Token address is not set");
            require(finalPrice > 0, "Final price is not set");
            uint256 len = users.length;
            for (uint256 i = 0; i < len; ++i) {
                address userAddress = users[i];
                // Fetch amount of mint and refund
                uint256 amountToMint = getAmountToMint(userAddress);
                uint256 amountToRefund = getAmountToRefund(userAddress);
                require (amountToMint > 0 || amountToRefund > 0, "User doesn't have any mint or refund");

                // Set user mint and refund to true
                BidData memory bidData = userToBidData[userAddress];
                bidData.mintClaimed = true;
                bidData.refundClaimed = true;
                userToBidData[userAddress] = bidData;

                // Process
                if (amountToMint > 0) {
                    IToken.UserAmount[] memory airdropData = new IToken.UserAmount[](1);
                    airdropData[0] = IToken.UserAmount(userAddress, uint96(amountToMint));
                    token.airdrop(airdropData);
                }
                _sendETH(userAddress, amountToRefund);

                emit AuctionClaimAndRefund(userAddress, amountToMint, amountToRefund);
            }
        }
    }

    function setBaseBid(uint256 _value) external onlyOwner {
        baseBid = _value;
    }

    function setMinBalanceToIncrement(uint256 _value) external onlyOwner {
        minBalanceToIncrement = _value;
    }

    function setStartingBidMultiplier(uint256 _value) external onlyOwner {
        startingBidMultiplier = _value;
    }

    // View functions
    function getAmountToMint(address user) public view returns (uint256) {
        uint256 _finalPrice = finalPrice;
        require (_finalPrice > 0, "Final price is not set");
        BidData memory bidData = userToBidData[user];
        return bidData.mintClaimed ? 0 : bidData.currentBid / _finalPrice;
    }

    function getAmountToRefund(address user) public view returns (uint256) {
        uint256 _finalPrice = finalPrice;
        require (_finalPrice > 0, "Final price is not set");
        BidData memory bidData = userToBidData[user];
        return bidData.refundClaimed ? 0 : bidData.currentBid % _finalPrice;
    }

    function getStartingBid() public view returns (uint256) {
        return baseBid + (address(this).balance / minBalanceToIncrement) * startingBidMultiplier;
    }

    // Internal functions
    function _sendETH(address _to, uint256 _amount) internal {
        (bool success, ) = _to.call{ value: _amount }("");
        require(success, "Transfer failed");
    }    

}