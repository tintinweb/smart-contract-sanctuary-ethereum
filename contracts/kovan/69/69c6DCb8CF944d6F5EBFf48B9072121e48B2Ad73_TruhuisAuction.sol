//SPDX-Licence-Identifier: MIT
pragma solidity 0.8.13;

import "Ownable.sol";
import "ReentrancyGuard.sol";
import "IERC20.sol";
import "IERC721.sol";
import "Pausable.sol";
import "TruhuisAddressRegistryAdapter.sol";
import "ICitizen.sol";
import "IStateGovernment.sol";

contract TruhuisAuction is 
    Ownable,
    ReentrancyGuard,
    TruhuisAddressRegistryAdapter,
    Pausable
{
    struct Auction {
        bool exists;
        bool isResulted;
        address currency;
        address auctioneer;
        uint256 minBid;
        uint256 reservePrice;
        uint256 startTime;
        uint256 endTime;
    }

    struct HighestBid {
        address bidder;
        uint256 bid;
        uint256 lastBidTime;
    }

    address public auctionOwner;
    uint256 public auctionCommissionFranction;

    mapping(uint256 => Auction) public s_auctions;
    mapping(uint256 => HighestBid) public s_highestBids;

    uint256 public minBidAllowed = 1; 
    uint256 public bidWithdrawalLockTime = 25 minutes;
    /// @dev Set corridor between auction start time and end time.
    uint256 public corridor = 86400;

    modifier auctionExists(uint256 _tokenId) {
        require(isAuctionExistent(_tokenId), "auction not exists");
        _;
    }

    modifier auctionStarted(uint256 _tokenId) {
        require(isAuctionStarted(_tokenId), "auction is not started");
        _;
    }

    modifier auctionNotExists(uint256 _tokenId) {
        require(!isAuctionExistent(_tokenId), "auction already exists");
        _;
    }

    modifier auctionNotStarted(uint256 _tokenId) {
        require(!isAuctionStarted(_tokenId), "auction is already started");
        _;
    }

    modifier auctionNotEnded(uint256 _tokenId) {
        require(isAuctionEnded(_tokenId), "auction seems to be ended");
        _;
    }

    modifier auctionNotResulted(uint256 _tokenId) {
        require(!isAuctionResulted(_tokenId), "auction seems to be resulted or nonexistent");
        _;
    }

    modifier onlyAuctioneer(address _auctioneer, uint256 _tokenId) {
        validateAuctioneer(_auctioneer, _tokenId);
        _;
    }

    modifier onlyBidder(address _bidder, uint256 _tokenId) {
        validateBidder(_bidder, _tokenId);
        _;
    }

    constructor(address _auctionOwner, address _addressRegistry, uint256 _marketplaceCommissionFraction) {
        auctionOwner = _auctionOwner;
        auctionCommissionFranction = _marketplaceCommissionFraction;
        _updateAddressRegistry(_addressRegistry);
    }

    function pause() external onlyOwner {_pause();}

    function unpause() external onlyOwner {_unpause();}

    // AUCTION

    function createAuction(
        address _currency,
        uint256 _tokenId,
        uint256 _reservePrice,
        uint256 _startTime,
        bool _minBidReserve,
        uint256 _endTime
    )
        external
        whenNotPaused
        auctionNotExists(_tokenId)
        onlyAuctioneer(msg.sender, _tokenId)
    {
        require(isAllowedCurrency(_currency), "invalid currency");
        validateStartEndTimes(_startTime, _endTime);

        uint256 minBid = 0;
        uint256 tokenId = _tokenId;

        if (_minBidReserve) {
            minBid = _reservePrice;
        }

        s_auctions[_tokenId].exists = true;
        s_auctions[tokenId].isResulted = false;
        s_auctions[tokenId].currency = _currency;
        s_auctions[tokenId].auctioneer = msg.sender;
        s_auctions[tokenId].minBid = minBid;
        s_auctions[tokenId].reservePrice = _reservePrice;
        s_auctions[tokenId].startTime = _startTime;
        s_auctions[tokenId].endTime = _endTime;

        //emit AuctionCreated(msg.sender, tokenId);
    }

    function cancelAuction(uint256 _tokenId)
        external
        nonReentrant
        onlyAuctioneer(msg.sender, _tokenId)
        auctionExists(_tokenId)
        auctionNotEnded(_tokenId)
        auctionNotResulted(_tokenId)
    {
        HighestBid storage highestBid = s_highestBids[_tokenId];
        
        if (highestBid.bidder != address(0)) {
            _refundHighestBidder(
                _tokenId,
                highestBid.bidder,
                highestBid.bid
            );

            delete s_highestBids[_tokenId];
        }

        delete s_auctions[_tokenId];

        //emit AuctionCancelled(msg.sender, _tokenId);
    }    

    function makeBid(uint256 _tokenId, uint256 _madeBid)
        external
        nonReentrant
        whenNotPaused 
        onlyBidder(msg.sender, _tokenId)
        auctionExists(_tokenId)
        auctionStarted(_tokenId)
        auctionNotEnded(_tokenId)
        auctionNotResulted(_tokenId)
    {
        Auction memory auction = s_auctions[_tokenId];
        HighestBid memory highestBid = s_highestBids[_tokenId];

        uint256 minBidRequired = highestBid.bid + minBidAllowed; // + 1 EUR or + 1 USDT or + 1 WETH

        _validateMadeBid(_tokenId, _madeBid, minBidRequired);

        _sendMadeBid(msg.sender, auction.currency, _madeBid);
        _refundHighestBidder(_tokenId, highestBid.bidder, highestBid.bid);
        _defineNewHighestBidder(msg.sender, _madeBid, _tokenId, _getNow());

        //emit BidMade(_tokenId, msg.sender, _madeBid);
    }

    function withdrawBid(uint256 _tokenId)
        external
        nonReentrant
        whenNotPaused 
        onlyBidder(msg.sender, _tokenId)
        auctionExists(_tokenId)
        auctionStarted(_tokenId)
        auctionNotEnded(_tokenId)
        auctionNotResulted(_tokenId)
    {
        HighestBid memory highestBid = s_highestBids[_tokenId];

        _validateBidWithdrawer(msg.sender, highestBid.bidder);
        _validateBidWithdrawal(s_auctions[_tokenId].endTime);

        uint256 previousBid = highestBid.bid;

        delete s_highestBids[_tokenId];
        _refundHighestBidder(_tokenId, msg.sender, previousBid);

        //emit BidWithdrawn()
    }

    function resultAuction(uint256 _tokenId)
        external
        nonReentrant
        onlyAuctioneer(msg.sender, _tokenId)
        auctionExists(_tokenId)
        auctionStarted(_tokenId)
        auctionNotEnded(_tokenId)
        auctionNotResulted(_tokenId)
    {
        Auction memory auction = s_auctions[_tokenId];
        HighestBid memory highestBid = s_highestBids[_tokenId];

        _validateWinner(highestBid.bidder, highestBid.bid, auction.reservePrice);

        uint256 tokenId = _tokenId;
        address currency = auction.currency;
        address bidder = highestBid.bidder;
        uint256 madeBid = highestBid.bid;
        uint256 auctionCommission = getAuctionCommission(madeBid);
        uint256 transferTax = getTransferTax(tokenId, madeBid - auctionCommission);

        require(isAuctionApproved(auction.auctioneer), "auction should be approved");

        delete s_highestBids[tokenId];

        _setAuctionIsResulted(tokenId);
        _sendAuctionCommission(currency, auctionCommission);
        _sendTransferTax(currency, tokenId, transferTax);
        _sendFundsTo(msg.sender, currency, madeBid - auctionCommission - transferTax);
        _transferNftFrom(msg.sender, bidder, tokenId);

        delete s_auctions[tokenId];
    }

    //          xxxxxxxxxxx                xxxxxxxxxxxxx
    // UPDATE
    //                          xxxxxxxxxxxxx               xxxxxxxxxxxxx

    function updateAuctionEndTime(uint256 _tokenId, uint256 _endTime)
        external 
        onlyAuctioneer(msg.sender, _tokenId)
        auctionExists(_tokenId)
        auctionNotEnded(_tokenId)
        auctionNotResulted(_tokenId)
    {
        Auction storage auction = s_auctions[_tokenId];
        validateEndTime(auction.startTime, _endTime);
        auction.endTime = _endTime;
    }

    function updateAuctionReservePrice(uint256 _tokenId, uint256 _reservePrice)
        external 
        onlyAuctioneer(msg.sender, _tokenId)
        auctionExists(_tokenId)
        auctionNotEnded(_tokenId)
        auctionNotResulted(_tokenId)
    {
        Auction storage auction = s_auctions[_tokenId];
        auction.reservePrice = _reservePrice;
    }

    function updateAuctionStartTime(uint256 _tokenId, uint256 _startTime)
        external 
        onlyAuctioneer(msg.sender, _tokenId)
        auctionExists(_tokenId)
        auctionNotStarted(_tokenId)
    {
        validateStartTime(_startTime);
        Auction storage auction = s_auctions[_tokenId];
        auction.startTime = _startTime;
    }

    function updateBidWithdrawalLockTime(uint256 _bidWithdrawalLockTime) external onlyOwner {
        bidWithdrawalLockTime = _bidWithdrawalLockTime;
    }

    function updateAuctionCommissionFraction(uint256 _newCommissionFraction)
        external
        onlyOwner
    {
        auctionCommissionFranction = _newCommissionFraction;
    }

    function updateAuctionOwner(address _newOwner)
        external
        onlyOwner
    {
        auctionOwner = _newOwner;
    }

    function reclaimERC20(address _currency) external onlyOwner {
        require(_currency != address(0), "invalid currency address");
        uint256 balance = IERC20(_currency).balanceOf(address(this));
        require(IERC20(_currency).transfer(msg.sender, balance), "failed to transfer");
    }

    // GET

    function getAuction(uint256 _tokenId) external view returns (Auction memory) {
        return s_auctions[_tokenId];
    }

    function getIsResulted(uint256 _tokenId) external view returns (bool) {
        return s_auctions[_tokenId].isResulted;
    }

    function getHighestBidder(uint256 _tokenId) external view returns (HighestBid memory) {
        return s_highestBids[_tokenId];
    }

    function getAuctionCommission(uint256 _bid) public view returns (uint256) {
        return marketplace().getMarketplaceCommission(_bid);
    }

    function getTransferTaxReceiver(uint256 _tokenId) public view returns (address) {
        (address transferTaxReceiver, uint256 transferTax) = cadastre().royaltyInfo(_tokenId, uint256(1));
        return transferTaxReceiver;
    }

    function getTransferTax(uint256 _tokenId, uint256 _salePrice) public view returns (uint256) {
        (address transferTaxReceiver, uint256 transferTax) = cadastre().royaltyInfo(_tokenId, _salePrice);
        return transferTax;
    }

    function getStartTime(uint256 _tokenId) external view returns (uint256) {
        return s_auctions[_tokenId].startTime;
    }

    //          xxxxxxxxxxx                xxxxxxxxxxxxx
    // PUBLIC VIEW RETURNS
    //                          xxxxxxxxxxxxx               xxxxxxxxxxxxx

    function areSimilarCountries(address _account, uint256 _tokenId) public view returns (bool) {
        (address transferTaxReceiver, uint256 transferTax) = cadastre().royaltyInfo(_tokenId, uint256(1));
        bytes3 realEstateCountry = IStateGovernment(transferTaxReceiver).getCountry();
        bytes3 citizenship = citizen(_account).citizenship();
        return realEstateCountry == citizenship;
    }

    function hasEnoughFunds(address _account, address _currency, uint256 _amount) public view returns (bool) {
        return IERC20(_currency).balanceOf(_account) > _amount;
    }

    function isAllowedCurrency(address _currency) public view returns (bool) {
        return currencyRegistry().isAllowed(_currency);
    }

    function isAuctionApproved(address _auctioneer) public view returns (bool) {
        return cadastre().isApprovedForAll(_auctioneer, address(this));
    }

    function isAuctionEnded(uint256 _tokenId) public view returns (bool) {
        return _getNow() > s_auctions[_tokenId].endTime;
    }

    function isAuctionExistent(uint256 _tokenId) public view returns (bool) {
        return s_auctions[_tokenId].exists;
    }

    function isAuctionResulted(uint256 _tokenId) public view returns (bool) {
        return s_auctions[_tokenId].isResulted;
    }

    function isAuctionStarted(uint256 _tokenId) public view returns (bool) {
        require(isAuctionExistent(_tokenId), "auction not exists");
        Auction memory auction = s_auctions[_tokenId];
        return _getNow() > auction.startTime + 120;
    }

    function isHuman(address _account) public view returns (bool) {
        uint256 codeLength;
        assembly {codeLength := extcodesize(_account)}
        return codeLength == 0 && _account != address(0);
    }

    function isPropertyOwner(address _auctioneer, uint256 _tokenId) public view returns (bool) {
        return cadastre().isOwner(_auctioneer, _tokenId);
    }

    function isValidEndTime(uint256 _startTime, uint256 _endTime) public view returns (bool) {
        return _endTime >= _startTime + corridor;
    }

    function isValidStartTime(uint256 _startTime) public view returns (bool) {
        return _startTime + 60 > _getNow();
    }

    function isVerifiedAuctioneer(address _auctioneer, uint256 _tokenId) public view returns (bool) {
        return marketplace().isVerifiedSeller(_auctioneer, _tokenId);
    }

    function isVerifiedBidder(address _bidder, uint256 _tokenId) public view returns (bool) {
        return marketplace().isVerifiedBuyer(_bidder, _tokenId);
    }

    //          xxxxxxxxxxx                xxxxxxxxxxxxx
    // PUBLIC VIEW 
    //                          xxxxxxxxxxxxx               xxxxxxxxxxxxx

    function validateAuctioneer(address _auctioneer, uint256 _tokenId) public {
        if (!isVerifiedAuctioneer(_auctioneer, _tokenId)) {
            marketplace().verifySeller(_auctioneer, _tokenId);
        }
        require(_auctioneer == s_auctions[_tokenId].auctioneer, "auctioneer must be the auction owner");
    }

    function validateBidder(address _bidder, uint256 _tokenId) public {
        if (!isVerifiedBidder(_bidder, _tokenId)) {
            marketplace().verifySeller(_bidder, _tokenId);
        }
        require(_bidder != s_auctions[_tokenId].auctioneer, "bidder can not be an auctioneer");
    }

    function validateEndTime(uint256 _startTime, uint256 _endTime) public view {
        require(isValidEndTime(_startTime, _endTime), "invalid end time");
    }

    function validateStartEndTimes(uint256 _startTime, uint256 _endTime) public view {
        require(isValidStartTime(_startTime), "start time must be greater than current time");
        require(isValidEndTime(_startTime, _endTime),
            "end time must be greater than start time (by 24 hours)"
        );
    }

    function validateStartTime(uint256 _startTime) public view {
        require(isValidStartTime(_startTime), "start time must be greater than current time");
    }

    //          xxxxxxxxxxx                xxxxxxxxxxxxx
    // INTERNAL  &   PRIVATE 
    //                          xxxxxxxxxxxxx               xxxxxxxxxxxxx

    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }
    
    function _sendTransferTax(address _currency, uint256 _tokenId, uint256 _transferTax) private {
        address transferTaxReceiver = getTransferTaxReceiver(_tokenId);
        require(transferTaxReceiver != address(0) || _transferTax > 0, "invalid transfer tax info");
        IERC20(_currency).transfer(transferTaxReceiver, _transferTax);
    }

    function _transferNftFrom(address _auctioneer, address _bidder, uint256 _tokenId) private {
        IERC721(addressRegistry().cadastre()).transferFrom(_auctioneer, _bidder, _tokenId);
    }

    function _sendMadeBid(address _bidder, address _currency, uint256 _madeBid) private {
        require(hasEnoughFunds(_bidder, _currency, _madeBid), "insufficient balance");
        require(
            IERC20(_currency).transferFrom(_bidder, address(this), _madeBid),
            "not approved"
        );
    }

    function _refundHighestBidder(
        uint256 _tokenId,
        address _highestBidder,
        uint256 _highestBid
    ) private {
        Auction memory auction = s_auctions[_tokenId];

        require(
            IERC20(auction.currency).transfer(_highestBidder, _highestBid),
            "failed to refund previous bidder"
        );
    }

    function _sendAuctionCommission(address _currency, uint256 _commission) private {
        IERC20(_currency).transfer(auctionOwner, _commission);
    }

    function _setAuctionIsResulted(uint256 _tokenId) private {
        Auction storage auction = s_auctions[_tokenId];
        auction.isResulted = true;
    }

    function _sendFundsTo(
        address _auctioneer, address _currency, uint256 _payAmount
    ) private {
        IERC20(_currency).transfer(_auctioneer, _payAmount);
    }

    function _defineNewHighestBidder(address _bidder, uint256 _madeBid, uint256 _tokenId, uint256 _lastBidTime) private {
        HighestBid storage highestBid = s_highestBids[_tokenId];
        highestBid.bidder = _bidder;
        highestBid.bid = _madeBid;
        highestBid.lastBidTime = _lastBidTime;
    }

    function _validateStartTime(uint256 _startTime) private view {
        require(_startTime > _getNow(), "start time must be greater than current time");
    }

    function _validateBidWithdrawal(uint256 _endTime) private view {
        require(
            _getNow() > _endTime && (_getNow() - _endTime >= 43200),
            "can withdraw only after 12 hours"
        );
    }

    function _validateBidWithdrawer(address _withdrawer, address _highestBidder) private pure {
        require(
            _withdrawer == _highestBidder,
            "bid withdrawer is not the highest bidder"
        );
    }

    function _validateMadeBid(uint256 _tokenId, uint256 _madeBid, uint256 _minBidRequired) private view {
        Auction memory auction = s_auctions[_tokenId];
        if (auction.minBid == auction.reservePrice) {
            require(_madeBid >= auction.reservePrice, "bid must be higher than reserve price");
        }
        require(_madeBid >= _minBidRequired, "made bid must be greater than previous highest bid");
    }

    function _validateWinner(address _winner, uint256 _highestBid, uint256 _reservePrice) private view {
        require(isHuman(_winner), "winner can not be a contract");
        require(_highestBid > _reservePrice, "highest bid must be greater than reserve price");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-Licence-Identifier: MIT

pragma solidity 0.8.13;

import "Ownable.sol";
import "ICitizen.sol";
import "IStateGovernment.sol";
import "ITruhuisAddressRegistry.sol";
import "ITruhuisAuction.sol";
import "ITruhuisCurrencyRegistry.sol";
import "ITruhuisCadastre.sol";
import "ITruhuisMarketplace.sol";

abstract contract TruhuisAddressRegistryAdapter is Ownable {
    ITruhuisAddressRegistry private _addressRegistry;

    function updateAddressRegistry(address _registry) public virtual onlyOwner {
        _updateAddressRegistry(_registry);
    }

    function auction() public view virtual returns (ITruhuisAuction) {
        return ITruhuisAuction(_addressRegistry.auction());
    }

    function addressRegistry() public view virtual returns (ITruhuisAddressRegistry) {
        return _addressRegistry;
    }

    function citizen(address _citizen) public view virtual returns (ICitizen) {
        return ICitizen(_citizen);
    }

    function currencyRegistry() public view virtual returns (ITruhuisCurrencyRegistry) {
        return ITruhuisCurrencyRegistry(_addressRegistry.currencyRegistry());
    }

    function stateGovernment(bytes3 _country) public view virtual returns (IStateGovernment) {
        return IStateGovernment(_addressRegistry.stateGovernment(_country));
    }

    function cadastre() public view virtual returns (ITruhuisCadastre) {
        return ITruhuisCadastre(_addressRegistry.cadastre());
    }

    function marketplace() public view virtual returns (ITruhuisMarketplace) {
        return ITruhuisMarketplace(_addressRegistry.marketplace());
    }

    function _updateAddressRegistry(address _registry) internal virtual {
        _addressRegistry = ITruhuisAddressRegistry(_registry);
    }
}

// SPDX-Licence-Identifier: MIT
pragma solidity 0.8.13;

interface ICitizen {
    function updateFirstName(bytes32 _firstName, uint256 _txIndex) external;

    function updateLastName(bytes32 _lastName, uint256 _txIndex) external;

    function updateBirthtime(uint256 _birthtime, uint256 _txIndex) external;

    function updateBirthDay(uint256 _birthDay, uint256 _txIndex) external;

    function updateBirthMonth(uint256 _birthMonth, uint256 _txIndex) external;

    function updateBirthYear(uint256 _birthYear, uint256 _txIndex) external;

    function updateBirthCity(bytes32 _city, uint256 _txIndex) external;

    function updateBirthState(bytes32 _state, uint256 _txIndex) external;

    function updateBirthCountry(bytes3 _country, uint256 _txIndex) external;

    function updateAccount(address _account, uint256 _txIndex) external;

    function updateBiometricInfoURI(string memory _uri, uint256 _txIndex) external;

    function updatePhotoURI(string memory _uri, uint256 _txIndex) external;

    function updateCitizenship(bytes3 _citizenship, uint256 _txIndex) external;

    function fullName() external view returns (bytes32, bytes32);

    function firstName() external view returns (bytes32);

    function lastName() external view returns (bytes32);

    function birthtime() external view returns (uint256);

    function birthDay() external view returns (uint256);

    function birthMonth() external view returns (uint256);

    function birthYear() external view returns (uint256);

    function birthCity() external view returns (bytes32);

    function birthState() external view returns (bytes32);

    function birthCountry() external view returns (bytes3);

    function account() external view returns (address);

    function biometricInfoURI() external view returns (string memory);

    function photoURI() external view returns (string memory);

    function citizenship() external view returns (bytes3);
}

// SPDX-Licence-Identifier: MIT
pragma solidity 0.8.13;

interface IStateGovernment {
    function registerCitizen(
        bytes32[] memory _name,
        uint24[] memory _dateOfBirth,
        bytes32[] memory _placeOfBirth,
        address[] memory _account,
        string[] memory _uri,
        bytes3[] memory _citizenship
    ) external;
    //function registerCitizen(address _citizenAccount, address _citizenContractAddr) external;
    
    function getAddress() external view returns (address);
    function getCitizenContractAddress(address _citizen) external view returns (address);
    function getCoolingOffPeriod() external view returns (uint256);
    function getCountry() external view returns (bytes3);
    function getIsCitizenContractRegistered(address _citizen) external view returns (bool);
    function getTransferTax() external view returns (uint96);
}

// SPDX-Licence-Identifier: MIT
pragma solidity 0.8.13;

interface ITruhuisAddressRegistry {
    function auction() external view returns (address);
    function citizen(address _citizen) external view returns (address);
    function currencyRegistry() external view returns (address);
    function stateGovernment(bytes3 _country) external view returns (address);
    function cadastre() external view returns (address);
    function marketplace() external view returns (address);
}

// SPDX-Licence-Identifier: MIT
pragma solidity 0.8.13;

interface ITruhuisAuction {
    function getStartTime(uint256 _tokenId) external view returns (uint256);
    function getIsResulted(uint256 _tokenId) external view returns (bool);
    function isAuctionApproved(address _account) external view returns (bool);
}

// SPDX-Licence-Identifier: MIT
pragma solidity 0.8.13;

interface ITruhuisCurrencyRegistry {
    function isAllowed(address _tokenAddr) external view returns (bool);
}

// SPDX-Licence-Identifier: MIT
pragma solidity 0.8.13;

import "IERC721.sol";

interface ITruhuisCadastre is IERC721 {
    function getRealEstateCountry(uint256 _tokenId) external view returns (bytes3);
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);
    function isOwner(address _account, uint256 _tokenId) external view returns (bool);
}

// SPDX-Licence-Identifier: MIT
pragma solidity 0.8.13;

interface ITruhuisMarketplace {
    function verifySeller(address _seller, uint256 _tokenId) external;
    function verifyBuyer(address _buyer, uint256 _tokenId) external;
    function getMarketplaceCommission(uint256 _salePrice) external view returns (uint256);

    function getRoyaltyCommission(uint256 _tokenId, uint256 _salePrice) external view returns (uint256);
    function getRoyaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);
    function getRoyaltyReceiver(uint256 _tokenId) external view returns (address);

    function hasEnoughFunds(address _account, address _currency, uint256 _amount) external view returns (bool);

    function isHuman(address _account) external view returns (bool);

    function isVerifiedBuyer(address _buyer, uint256 _tokenId) external view returns (bool);

    function isVerifiedSeller(address _seller, uint256 _tokenId) external view returns (bool);

}