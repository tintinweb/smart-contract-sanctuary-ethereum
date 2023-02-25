//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TicketAuction is Ownable, IERC721Receiver, IERC1155Receiver, ReentrancyGuard {

    enum Phase {
        INIT,
        NFT_RECEIVED,
        AUCTION,
        CLAIM,
        DONE
    }
    Phase public currentPhase = Phase.INIT;

    struct BidValue {
        uint256 ethAmountInWei;
        uint256 ticketAmount;
    }

    struct Bid {
        address bidder;
        BidValue value;
    }

    Bid public currentWinningBid;
    uint256 public amountBids;

    event BidEvent(address bidder, uint256 ethAmountInWei, uint256 ticketAmount, uint256 usdValue, uint256 timestamp);
    event AuctionExtended(uint oldEndTime, uint newEndTime);

    IERC1155 public ticketContract;
    uint256 public ticketTokenId;

    IERC721 public nftContract;
    uint256 public nftTokenId;

    AggregatorV3Interface public ethUSDPriceFeed;
    uint256 public ticketUSDValue;

    address auctionBeneficiary;

    uint public endTime;
    uint public extensionTime;
    
    /**
        @dev    ticketUSDValue should be in USD * 10^18 (wei conversion),      
                e.g. 22 USD = 22000000000000000000
    */
    constructor(address ethUSDFeedAddress, uint256 _ticketUSDValue, 
                address _ticketContract, uint256 _ticketTokenId, 
                address _nftContract, uint256 _nftTokenId,
                address _auctionBeneficiary
    ) {
        ethUSDPriceFeed = AggregatorV3Interface(ethUSDFeedAddress);
        ticketUSDValue = _ticketUSDValue;

        IERC165 check1155 = IERC165(_ticketContract);
        require(check1155.supportsInterface(type(IERC1155).interfaceId), "Ticket Contract address must be ERC1155");
        ticketContract = IERC1155(_ticketContract);
        ticketTokenId = _ticketTokenId;

        IERC165 check721 = IERC165(_nftContract);
        require(check721.supportsInterface(type(IERC721).interfaceId), "NFT Contract address must be ERC721");
        nftContract = IERC721(_nftContract);
        nftTokenId = _nftTokenId;

        currentWinningBid = Bid(0x0000000000000000000000000000000000000000, BidValue(0, 0));
        auctionBeneficiary = _auctionBeneficiary;
    }

    // Auction functions

    function bid(uint256 ticketAmount) external payable nonReentrant {
        require(msg.sender == tx.origin, "No contract bidding");
        require(currentPhase == Phase.AUCTION, "Must be in auction phase");
        require(block.timestamp < endTime, "Must be before auction has ended!");
        require(msg.value > 0 || ticketAmount > 0, "Bid must be nonzero!");

        uint256 newBidUSD = ethAndTicketsToUSD(msg.value, ticketAmount);
        require(newBidUSD > bidValueToUSD(currentWinningBid.value), "Must be a greater bid than the current bid!");
        if (ticketAmount > 0) {
            ticketContract.safeTransferFrom(msg.sender, address(this), ticketTokenId, ticketAmount, "0x0");
        }

        if (currentWinningBid.value.ticketAmount > 0) {
            ticketContract.safeTransferFrom(address(this), currentWinningBid.bidder, ticketTokenId, currentWinningBid.value.ticketAmount, "0x0");
        }
        if (currentWinningBid.value.ethAmountInWei > 0) {
            payable(currentWinningBid.bidder).transfer(currentWinningBid.value.ethAmountInWei);
        }

        currentWinningBid = Bid(msg.sender, BidValue(msg.value, ticketAmount));

        if (endTime - block.timestamp < extensionTime) {
            uint newEndTime = block.timestamp + extensionTime;
            emit AuctionExtended(endTime, newEndTime);
            endTime = newEndTime;
        }

        // Sanity checks
        require(ticketContract.balanceOf(address(this), ticketTokenId) == ticketAmount, "Ticket transfer failed");
        require(address(this).balance == msg.value, "ETH transfer failed");

        emit BidEvent(msg.sender, msg.value, ticketAmount, newBidUSD, block.timestamp);
        amountBids++;
    }

    function topupBid(uint256 ticketAmount) external payable nonReentrant {
        require(msg.sender == tx.origin, "No contract bidding");
        require(currentPhase == Phase.AUCTION, "Must be in auction phase");
        require(block.timestamp < endTime, "Must be before auction has ended!");
        require(currentWinningBid.bidder == msg.sender, "Must be current winning bidder to topup bid");
        require(msg.value > 0 || ticketAmount > 0, "Bid must be nonzero!");
        
        uint256 newEthAmount = msg.value + currentWinningBid.value.ethAmountInWei;
        uint256 newTicketAmount = ticketAmount + currentWinningBid.value.ticketAmount;
        uint256 newBidUSD = ethAndTicketsToUSD(newEthAmount, newTicketAmount);
        if (ticketAmount > 0) {
            ticketContract.safeTransferFrom(msg.sender, address(this), ticketTokenId, ticketAmount, "0x0");
        }

        currentWinningBid.value = BidValue(newEthAmount, newTicketAmount);

        if (endTime - block.timestamp < extensionTime) {
            uint newEndTime = block.timestamp + extensionTime;
            emit AuctionExtended(endTime, newEndTime);
            endTime = newEndTime;
        }

        // Sanity checks
        require(ticketContract.balanceOf(address(this), ticketTokenId) == newTicketAmount, "Ticket transfer failed");
        require(address(this).balance == newEthAmount, "ETH transfer failed");

        emit BidEvent(msg.sender, newEthAmount, newTicketAmount, newBidUSD, block.timestamp);
        amountBids++;
    }

    function claim() external {
        if (currentPhase == Phase.AUCTION && block.timestamp >= endTime) {
            currentPhase = Phase.CLAIM;
        }
        require(currentPhase == Phase.CLAIM, "Must be claim phase!");
        require(msg.sender == currentWinningBid.bidder, "Must be the winner of the auction!");
        nftContract.safeTransferFrom(address(this), msg.sender, nftTokenId);
        currentPhase = Phase.DONE;
    }

    // Owner Functions

    function commitNFT(address nftOwner) external onlyOwner {
        require(currentPhase == Phase.INIT);
        nftContract.safeTransferFrom(nftOwner, address(this), nftTokenId);
    }

    function startAuction(uint _endTime, uint _extensionTime) external onlyOwner {
        require(currentPhase == Phase.NFT_RECEIVED, "Must have sent the NFT to the contract!");
        require(block.timestamp < _endTime, "End time must be in future");
        endTime = _endTime;
        extensionTime = _extensionTime;
        currentPhase = Phase.AUCTION;
    }

    function withdrawValue() public onlyOwner {
        if (currentPhase == Phase.AUCTION && block.timestamp >= endTime) {
            currentPhase = Phase.CLAIM;
        }
        require(currentPhase == Phase.CLAIM || currentPhase == Phase.DONE, "Must withdraw in correct phase");
        ticketContract.safeTransferFrom(address(this), auctionBeneficiary, ticketTokenId, ticketContract.balanceOf(address(this), ticketTokenId), "0x0");
        payable(auctionBeneficiary).transfer(address(this).balance);
    }

    function ownerFinishClaim() external onlyOwner {
        if (currentPhase == Phase.AUCTION && block.timestamp >= endTime) {
            currentPhase = Phase.CLAIM;
        }
        require(currentPhase == Phase.CLAIM, "Must be claim phase!");
        if (currentWinningBid.bidder == address(0)) {
            nftContract.safeTransferFrom(address(this), auctionBeneficiary, nftTokenId);
        } else {
            nftContract.safeTransferFrom(address(this), currentWinningBid.bidder, nftTokenId);
        }
        currentPhase = Phase.DONE;
        withdrawValue();
    }

    function setExtensionTime(uint _extensionTime) external onlyOwner {
        extensionTime = _extensionTime;
    }

    // OnReceived

    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 tokenId,
        bytes calldata /* data */
    ) external returns (bytes4) {
        require(msg.sender == address(nftContract), "ERC721 Received must be from correct contract!");
        require(tokenId == nftTokenId, "ERC721 Received must be correct token ID!");
        require(currentPhase == Phase.INIT, "Phase must be INIT.");
        currentPhase = Phase.NFT_RECEIVED;
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address /* from */,
        uint256 /* id */,
        uint256 /* value */,
        bytes calldata /* data */
    ) external view returns (bytes4) {
        require(msg.sender == address(ticketContract), "ERC1155 Received must be from correct contract!");
        require(operator == address(this), "Must be operated by this contract!");
        require(currentPhase == Phase.AUCTION, "Must be in the auction phase!");
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address /* operator */,
        address /* from */,
        uint256[] calldata /* ids */,
        uint256[] calldata /* values */,
        bytes calldata /* data */
    ) external pure returns (bytes4) {
        revert("No batch receiving");
    }

    // Views

    function getInfo(address user) public view 
    returns (
        Phase phase, Bid memory winningBid,
        uint256 tickets, bool hasApproved,
        uint256 auctionEndTime, bool hasAuctionEnded, 
        uint256 topBidValue, uint256 ethUSDPrice,
        uint256 ticketUSDPrice, uint256 userBalance,
        uint256 blockHeight
    ) {
        phase = currentPhase;
        winningBid = currentWinningBid;
        if (user != address(0)) {
            tickets = ticketContract.balanceOf(user, ticketTokenId);
            hasApproved = ticketContract.isApprovedForAll(user, address(this));
            userBalance = payable(user).balance;
        } else {
            tickets = 0;
            hasApproved = false;
            userBalance = 0;
        }
        auctionEndTime = endTime;
        hasAuctionEnded = block.timestamp >= endTime;
        topBidValue = bidValueToUSD(currentWinningBid.value);
        ethUSDPrice = getETHUSDPrice();
        ticketUSDPrice = ticketUSDValue;
        blockHeight = block.number;
    }

    /**
        @dev    returns in wei format (usd * 10^18)
    */
    function getETHUSDPrice() public view returns (uint256) {
        (, int256 answer, , ,) = ethUSDPriceFeed.latestRoundData();
        require(answer > 0, "ETH/USD Price invalid");
        return uint256(answer) * 10**10;
    }

    /**
        @dev    returns in wei format (usd * 10^18)
    */
    function ethToUSD(uint256 amountInWei) public view returns (uint256) {
        return (amountInWei * getETHUSDPrice()) / 10**18;
    }

    function ethAndTicketsToUSD(uint256 ethAmountInWei, uint256 ticketAmount) public view returns (uint256) {
        return ethToUSD(ethAmountInWei) + (ticketAmount * ticketUSDValue);
    }

    /**
        @dev    returns in wei format (usd * 10^18)
    */
    function bidValueToUSD(BidValue memory bidValue) public view returns (uint256) {
        return ethToUSD(bidValue.ethAmountInWei) + (bidValue.ticketAmount * ticketUSDValue);
    }

    function getTopBid() public view returns (Bid memory topBid, uint256 value) {
        topBid = currentWinningBid;
        value = bidValueToUSD(currentWinningBid.value);
    }

    // Setters

    function setTicketUSDValue(uint256 _ticketUSDValue) external onlyOwner {
        ticketUSDValue = _ticketUSDValue;
    }

    // IERC165

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || interfaceId == type(IERC721Receiver).interfaceId;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155Receiver.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721Receiver.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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