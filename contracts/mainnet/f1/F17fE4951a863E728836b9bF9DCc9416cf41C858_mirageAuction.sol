/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: auction.sol

/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMNOOXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXO0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMk,'lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc.,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMNo...cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc...lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMK:....cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc....:0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMk,.....cKMMMMMMMMMMMMMMMMMMMMMMMMMMWKc.....,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMNd.......cKWMMMMMMMMMMMMMMMMMMMMMMMKkc.......oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMKc........cKMMMMMMMMMMMMMMMMMMMMMMKc'........cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMO,.........cKMMMMMMMMMMMMMMMMMMMMKc..........,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMWd'..........cKWMMMMMMMMMMMMMMMMMKl............dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMXc...;;.......cKMMMMMMMMMMMMMMMMKc...'co,......cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMO;..,x0:.......cKMMMMMMMMMMMMMMKl...cxKKc......;OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMWd'..;0W0:.......cKWMMMMMMMMMMMKc...cKWMNo......'xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMXl...lXMW0:.......c0WMMMMMMMMMKl...cKMMMWx'......lXXkxxddddoddddxxxkO0KXXNWWWMMMMMMMMMMM
MMMMMMMMMMMM0;...dWMMW0:.......c0WMMMMMMMKl...cKMMMMMO;......;0k,.'''',,''.......'',;::cxXMMMMMMMMMM
MMMMMMMMMMMWx'..,kMMMMW0:.......c0WMMMMMKl...cKMMMMWWKc......'xXOO00KKKKK00Okdoc,'......cKMMMMMMMMMM
MMMMMMMMMMMXl...:0MMMMMW0:.......:0WMMMKl...cKMMWKkdxKd.......oNMMMMMMMMMMMMMMMWXOd:'...lXMMMMMMMMMM
MMMMMMMMMMM0:...lXMMMMMMWO:.......:0MMKl...cKMWKo,..;0k,......:KMMMMMMMMMMMMMMMMMMWNOc'.oNMMMMMMMMMM
MMMMMMMMMMWx'..'dWMMMMMMMW0:.......:0Kl...cKMNk;....,k0:......,kMMMMMMMMMMMMMMMMMMMMMXl'oNMMMMMMMMMM
MMMMMMMMMMNl...,OMMMMMMMMMW0:.......;;...cKWXo'......dKl.......oNMMMMMMMMMMMMMMMMMMMMM0:dWMMMMMMMMMM
MMMMMMMMMM0:...:KMMMMMMMMMMW0c..........lKMNo'.......oXd'......cKMMMMMMMMMMMMMMMMMMMMMNKXMMMMMMMMMMM
MMMMMMMMMWk,...lXMMMMMMMMMMMWKc........cKMWx,.......,kWk,......,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMNo...'dWMMMMMMMMMMMMMKl......lKMMK:........:KMK:.......dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMWO;...'xWMMMMMMMMMMMMMMXl'...lKMMWx'........lXMXl.......;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMNKOOd;.....;dkO0NMMMMMMMMMMMXo''lXMMMNo.........lNW0:........,lxkO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMN0kkkkkkkkkkxxkOXWMMMMMMMMMMMN0ONMMMMNo.........lXWXOkkkkxxxxxxxxxk0WMXOkkkkkkkkkkkkkkkkkOXMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.........:0MMMMMMMMMMMMMMMMMMMMN0OOxl,........,lxO0NMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx'........'xWMMMMMMMMMMMMMMMMMMMMMMMMNd'......'dNMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:.........:KMMMMMMMMMMMMMMMMMMMMMMMMMk,......'xWMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd'.........oXMMMMMMMMMMMMMMMMMMMMMMMMO,......'kWMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.........'oXMMMMMMMMMMMMMMMMMMMMMMMO,......'kMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo'.........c0WMMMMMMMMMMMMMMMMMMMMMO,......'kMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;.........,dXWMMMMMMMMMMMMMMMMMMMO,......'kMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo;'........;d0NMMMMMMMMMMMMMMMMMO,......'kWMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOxc'.......':dOKNWMMMMMMMMMMMWk,......'kWMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xl;'.......,:ldxkO00KK00Od:.......;OMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kdl:;''.......''''''....',;cox0NMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0OkxxddddddddxxkkO0XNWMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
*/

// Contract authored by August Rosedale (@augustfr)
// https://miragegallery.ai

// This is a modifed version of an auction contact from Foundation

pragma solidity ^0.8.19;



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

/// @param auctionId The already listed auctionId for this NFT.
error NFTMarketReserveAuction_Already_Listed(uint256 auctionId);
/// @param minAmount The minimum amount that must be bid in order for it to be accepted.
error NFTMarketReserveAuction_Bid_Must_Be_At_Least_Min_Amount(uint256 minAmount);
/// @param reservePrice The current reserve price.
error NFTMarketReserveAuction_Cannot_Bid_Lower_Than_Reserve_Price(uint256 reservePrice);
/// @param endTime The timestamp at which the auction had ended.
error NFTMarketReserveAuction_Cannot_Bid_On_Ended_Auction(uint256 endTime);
error NFTMarketReserveAuction_Cannot_Bid_On_Nonexistent_Auction();
error NFTMarketReserveAuction_Cannot_Finalize_Already_Settled_Auction();
/// @param endTime The timestamp at which the auction will end.
error NFTMarketReserveAuction_Cannot_Finalize_Auction_In_Progress(uint256 endTime);
error NFTMarketReserveAuction_Cannot_Rebid_Over_Outstanding_Bid();
/// @param maxDuration The maximum configuration for a duration of the auction, in seconds.
error NFTMarketReserveAuction_Exceeds_Max_Duration(uint256 maxDuration);
/// @param extensionDuration The extension duration, in seconds.
error NFTMarketReserveAuction_Less_Than_Extension_Duration(uint256 extensionDuration);
/// @param seller The current owner of the NFT.
error NFTMarketReserveAuction_Not_Matching_Seller(address seller);
error NFTMarketReserveAuction_Too_Much_Value_Provided();

contract mirageAuction is Ownable, ReentrancyGuard {

    struct ReserveAuctionStorage {
        address nftContract;
        uint256 tokenId;
        address payable payee1;
        uint256 payee1Amount;
        address payable payee2;
        address creator;
        uint256 endTime;
        address payable bidder;
        uint256 amount;
        uint256 numBids;
        bool finalized;
    }

    struct ReserveAuction {
      address nftContract;
      uint256 tokenId;
      address payable payee1;
      uint256 payee1Amount;
      address payable payee2;
      address creator;
      uint256 duration;
      uint256 extensionDuration;
      uint256 endTime;
      address payable bidder;
      uint256 amount;
      uint256 numBids;
      bool finalized;
    }

    uint256 private DURATION;

    uint256 private constant EXTENSION_DURATION = 10 minutes;

    uint256 private constant MAX_MAX_DURATION = 1000 days;

    uint256 private nextAuctionId = 1;

    uint256 constant BASIS_POINTS = 10000;

    uint256 constant MIN_PERCENT_INCREMENT_DENOMINATOR = BASIS_POINTS / 1000;

    mapping(address => mapping(uint256 => uint256)) private nftContractToTokenIdToAuctionId;
    mapping(uint256 => ReserveAuctionStorage) private auctionIdToAuction;

    event ReserveAuctionCreated(
        address payee1,
        uint256 payee1Percentage,
        address payee2,
        address creator,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 duration,
        uint256 extensionDuration,
        uint256 reservePrice,
        uint256 auctionId
    );

    event ReserveAuctionFinalized(
        uint256 indexed auctionId,
        address payee1,
        address payee2,
        address creator,
        address indexed bidder
    );

    struct Bid {
      address[] bidder;
      uint256[] amount;
      uint256[] timestamp;
    }

    mapping(uint256 => Bid) bids;
    mapping(uint256 => address[]) bidders;

    event ReserveAuctionInvalidated(uint256 indexed auctionId);
    event ReserveAuctionBidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 endTime);
  
    constructor(uint256 duration) {
      if (duration > MAX_MAX_DURATION) {
          revert NFTMarketReserveAuction_Exceeds_Max_Duration(MAX_MAX_DURATION);
        }
        if (duration < EXTENSION_DURATION) {
          revert NFTMarketReserveAuction_Less_Than_Extension_Duration(EXTENSION_DURATION);
        } 
        
        DURATION = duration; // duration in seconds
      }

    function _getNextAndIncrementAuctionId() internal returns (uint256) {
      unchecked {
        return nextAuctionId++;
      }
    }

    function getCurrentAuctionId() public view returns (uint256) {
      return nextAuctionId - 1;
    }
    
    function updateDuration(uint256 newDuration) external onlyOwner {
      if (newDuration > MAX_MAX_DURATION) {
          revert NFTMarketReserveAuction_Exceeds_Max_Duration(MAX_MAX_DURATION);
        }
        if (newDuration < EXTENSION_DURATION) {
          revert NFTMarketReserveAuction_Less_Than_Extension_Duration(EXTENSION_DURATION);
        } 
      DURATION = newDuration;
    }

    function createAuction(address nftContract, uint256 tokenId, uint256 reservePrice, address payee1, uint256 payee1Amount, address payee2) external onlyOwner {
        uint256 auctionId = _getNextAndIncrementAuctionId();
           

        // If the `msg.sender` is not the owner of the NFT, transferring into escrow should fail.
        _transferToEscrow(nftContract, tokenId);

        // This check must be after _transferToEscrow in case auto-settle was required
        if (nftContractToTokenIdToAuctionId[nftContract][tokenId] != 0) {
        revert NFTMarketReserveAuction_Already_Listed(nftContractToTokenIdToAuctionId[nftContract][tokenId]);
        }

        // Store the auction details
        nftContractToTokenIdToAuctionId[nftContract][tokenId] = auctionId;
        ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];
        auction.nftContract = nftContract;
        auction.tokenId = tokenId;
        auction.payee1 = payable(payee1);
        auction.payee1Amount = payee1Amount;
        auction.payee2 = payable(payee2);
        auction.creator = msg.sender;
        auction.amount = reservePrice;
        auction.endTime = block.timestamp + DURATION;
        auction.numBids = 0;
        auction.finalized = false;

        emit ReserveAuctionCreated(payee1, payee1Amount, payee2, msg.sender, nftContract, tokenId, DURATION, EXTENSION_DURATION, reservePrice, auctionId);
    }

    function getReserveAuction(uint256 auctionId) external view returns (ReserveAuction memory auction) {
      ReserveAuctionStorage storage auctionStorage = auctionIdToAuction[auctionId];
      auction = ReserveAuction(
        auctionStorage.nftContract,
        auctionStorage.tokenId,
        auctionStorage.payee1,
        auctionStorage.payee1Amount,
        auctionStorage.payee2,
        auctionStorage.creator,
        DURATION,
        EXTENSION_DURATION,
        auctionStorage.endTime,
        auctionStorage.bidder,
        auctionStorage.amount,
        auctionStorage.numBids,
        auctionStorage.finalized
      );
    }

    function _transferToEscrow(address nftContract, uint256 tokenId) internal virtual {
      uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
      if (auctionId == 0) {
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        return;
      }
    }

    function _transferFromEscrow(address nftContract, uint256 tokenId, address recipient, address authorizeSeller) internal virtual {
      uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
      ReserveAuctionStorage memory auction = auctionIdToAuction[auctionId];
      if (!auction.finalized) {
        if (auction.numBids == 0) {
          // The auction has not received any bids yet so it may be invalided.

          if (authorizeSeller != address(0)) {
            // The account trying to transfer the NFT is not the current owner.
            revert NFTMarketReserveAuction_Not_Matching_Seller(auction.payee1);
          }

          emit ReserveAuctionInvalidated(auctionId);
        } else {
          // If the auction has ended, the highest bidder will be the new owner
          // and if the auction is in progress, this will revert.

          // `authorizeSeller != address(0)` does not apply here since an unsettled auction must go
          // through this path to know who the authorized seller should be.
          if (auction.bidder != authorizeSeller) {
            revert NFTMarketReserveAuction_Not_Matching_Seller(auction.bidder);
          }

          // Finalization will revert if the auction has not yet ended.
          _finalizeReserveAuction({ auctionId: auctionId });
        }
        // The seller authorization has been confirmed.
        authorizeSeller = address(0);
      }

      IERC721(nftContract).transferFrom(address(this), recipient, tokenId);

    }

    function finalizeReserveAuction(uint256 auctionId) external nonReentrant {
      if (auctionIdToAuction[auctionId].endTime == 0) {
        revert NFTMarketReserveAuction_Cannot_Finalize_Already_Settled_Auction();
      }
      _finalizeReserveAuction({auctionId: auctionId});
    }

    function _finalizeReserveAuction(uint256 auctionId) private {
      ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];

      if (auction.endTime >= block.timestamp) {
        revert NFTMarketReserveAuction_Cannot_Finalize_Auction_In_Progress(auction.endTime);
      }

      auction.finalized = true;
      if (auction.bidder != address(0)) {
        _transferFromEscrow(auction.nftContract, auction.tokenId, auction.bidder, address(0));
        _distributeFunds(auction.payee1, auction.payee1Amount, auction.payee2, auction.amount);
      } else {
        _transferFromEscrow(auction.nftContract, auction.tokenId, auction.creator, address(0));
      }

      emit ReserveAuctionFinalized(auctionId, auction.payee1, auction.payee2, auction.creator, auction.bidder);
    }

    function _distributeFunds(address payee1, uint256 payee1Amount, address payee2, uint256 amount) internal {
      uint256 amountToPayee1 = amount / 100 * payee1Amount;
      uint256 amountToPayee2 = amount - amountToPayee1;
      payable(payee1).transfer(amountToPayee1);
      payable(payee2).transfer(amountToPayee2);
    }

    function placeBid(uint256 auctionId) public payable nonReentrant {
      ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];
      uint256 amount = msg.value;
      if (auction.amount == 0) {
        revert NFTMarketReserveAuction_Cannot_Bid_On_Nonexistent_Auction();
      } else if (amount < msg.value) {
        revert NFTMarketReserveAuction_Too_Much_Value_Provided();
      }

      uint256 endTime = auction.endTime;

      if (endTime < block.timestamp) {
        revert NFTMarketReserveAuction_Cannot_Bid_On_Ended_Auction(endTime);
      } else if (auction.bidder == msg.sender) {
        revert NFTMarketReserveAuction_Cannot_Rebid_Over_Outstanding_Bid();
      } else {
        uint256 minIncrement = _getMinIncrement(auction.amount);
        if (amount < minIncrement) {
          revert NFTMarketReserveAuction_Bid_Must_Be_At_Least_Min_Amount(minIncrement);
        }
      }

      if (auction.numBids > 0) {
        uint256 originalAmount = auction.amount;
        address payable originalBidder = auction.bidder;
        payable(originalBidder).transfer(originalAmount);
      }

      auction.amount = amount;
      auction.bidder = payable(msg.sender);

      unchecked {

        uint256 endTimeWithExtension = block.timestamp + EXTENSION_DURATION;
        if (endTime < endTimeWithExtension) {
          endTime = endTimeWithExtension;
          auction.endTime = endTime;
        }
      }

      auction.numBids++;
      bidders[auctionId].push(msg.sender);
      bids[auctionId].bidder.push(msg.sender);
      bids[auctionId].amount.push(msg.value);
      bids[auctionId].timestamp.push(block.timestamp);
      emit ReserveAuctionBidPlaced(auctionId, msg.sender, amount, endTime);
    }

    function _getMinIncrement(uint256 currentAmount) internal pure returns (uint256) {
    uint256 minIncrement = currentAmount;
    unchecked {
      minIncrement /= MIN_PERCENT_INCREMENT_DENOMINATOR;
    }
    if (minIncrement == 0) {
      // Since minIncrement reduces from the currentAmount, this cannot overflow.
      // The next amount must be at least 1 wei greater than the current.
      return currentAmount + 1;
    }

    return minIncrement + currentAmount;
  }

  function getAllBids(uint256 auctionId) public view returns (Bid memory) {
    return bids[auctionId];
  }

  function withdraw() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}