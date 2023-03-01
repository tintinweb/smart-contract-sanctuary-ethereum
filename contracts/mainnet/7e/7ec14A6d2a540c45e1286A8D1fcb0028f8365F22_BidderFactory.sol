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

// SPDX-License-Identifier: GPL-3.0

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {INounsAuctionHouse} from "./external/interfaces/INounsAuctionHouse.sol";

pragma solidity 0.8.17;

contract Bidder is Ownable {
    // Returned when a caller attempts to create a bid but this contract
    // is already the highest bidder
    error AlreadyHighestBidder();

    // Returned when the caller attempts to create a bid but the auction has
    // ended
    error AuctionEnded();

    // Returned when the caller attempts to call withdraw for a token auction
    // that has not ended yet
    error AuctionNotEnded();

    // Returned when an attempt is made to place a bid that exceeds the max
    // configurable amount
    error MaxBidExceeded();

    // Returned when an attempt is made to withdraw a token that has not been bid on
    error NoBidFoundForToken(uint256 tokenId);

    // Returned when an attempt is made to withdraw a token that has already been
    // transferred to the receiver
    error AlreadyWithdrawn();

    // Returned when an attempt is made to place a bid outside of the auction
    // bid window
    error NotInBidWindow();

    // Returned when updating config that does not have the receiver set
    error InvalidReceiver();

    // Emitted when a caller receives a gas refund
    event GasRefund(address indexed caller, uint256 refundAmount, bool refundSent);

    // Emitted when a token is withdrawn and last bidder tipped
    event WithdrawAndTip(
        address indexed caller, address indexed tipTo, uint256 tokenId, uint256 tipAmount, bool tipSent
    );

    // Emitted when config is updated
    event ConfigUpdate(Config config);

    // The structure of the config for this bidder
    struct Config {
        // Max bid that can be placed in an auction
        uint256 maxBid;
        // Min bid that can be placed in an auction
        uint256 minBid;
        // Max priority fee used to cap gas refunds
        uint256 maxPriorityFee;
        // Max gas units that will be refunded to a caller
        uint256 maxGasRefund;
        // Max base fee to refund a caller
        uint256 maxBaseFeeRefund;
        // Base gas to refund
        uint256 baseGasRefund;
        // Time in seconds a bid can be placed before auction end time
        uint256 bidWindow;
        // Tip rewarded for caller winning auction
        uint256 tip;
        // Address that will receive tokens when withdrawn
        address receiver;
    }

    // The structure of the last bid as a record for tipping purposes
    struct LastBid {
        // Last address to make the bid
        address bidder;
        // The time that the auction bid on ends
        uint256 auctionEndTime;
        // If the last bid was a winning bid and the token was transferred / settled
        bool settled;
    }

    // The config for this bidder
    Config public config;

    // The ERC721 token address that is being bid on
    IERC721 public immutable token;

    // The auction house address
    INounsAuctionHouse public immutable auctionHouse;

    // The last bidder for each token id
    mapping(uint256 => LastBid) internal lastBidForToken;

    constructor(IERC721 t, INounsAuctionHouse ah, address _owner, Config memory cfg) payable {
        token = t;
        auctionHouse = ah;
        config = cfg;

        // allow ownership to be transferred during instantiation; i.e. when
        // created by factory impl
        if (msg.sender != _owner) {
            _transferOwnership(_owner);
        }
    }

    /// @notice Submit a bid to the auction house
    function bid() external returns (uint256, uint256) {
        uint256 startGas = gasleft();

        (uint256 nounId, uint256 amount,, uint256 endTime, address bidder,) = auctionHouse.auction();

        if (block.timestamp > endTime) {
            revert AuctionEnded();
        }

        if (block.timestamp + config.bidWindow < endTime) {
            revert NotInBidWindow();
        }

        if (bidder == address(this)) {
            revert AlreadyHighestBidder();
        }

        uint256 value = auctionHouse.reservePrice();
        if (amount > 0) {
            value = amount + ((amount * auctionHouse.minBidIncrementPercentage()) / 100);
        }

        if (value < config.minBid) {
            value = config.minBid;
        }

        if (value > config.maxBid) {
            revert MaxBidExceeded();
        }

        auctionHouse.createBid{value: value}(nounId);

        lastBidForToken[nounId] = LastBid({bidder: msg.sender, auctionEndTime: endTime, settled: false});

        _refundGas(startGas);

        return (nounId, value);
    }

    /**
     * @notice Withdraw the given token id from this contract
     * @dev Reentrancy is defended against with `lb.settled` check
     */
    function withdraw(uint256 tId) external {
        uint256 startGas = gasleft();

        LastBid storage lb = lastBidForToken[tId];
        if (lb.bidder == address(0)) {
            revert NoBidFoundForToken(tId);
        }

        if (lb.settled) {
            revert AlreadyWithdrawn();
        }

        if (block.timestamp < lb.auctionEndTime) {
            revert AuctionNotEnded();
        }

        lb.settled = true;

        token.safeTransferFrom(address(this), config.receiver, tId);

        _tip(tId, lb.bidder);

        _refundGas(startGas);
    }

    /// @notice Withdraw contract balance
    function withdrawBalance() external onlyOwner {
        (bool sent,) = owner().call{value: address(this).balance}("");
        require(sent, "failed to withdraw ether");
    }

    /// @notice Handles updating the config for this bidder
    function setConfig(Config calldata cfg) external onlyOwner {
        if (cfg.receiver == address(0)) {
            revert InvalidReceiver();
        }

        config = cfg;
        emit ConfigUpdate(cfg);
    }

    /// @notice Returns the last bid for the given token id
    function getLastBid(uint256 tId) external view returns (LastBid memory) {
        return lastBidForToken[tId];
    }

    /// @notice Sends tip to address
    function _tip(uint256 tId, address to) internal {
        unchecked {
            uint256 balance = address(this).balance;
            if (balance == 0) {
                return;
            }

            uint256 tipAmount = min(config.tip, balance);
            (bool tipSent,) = to.call{value: tipAmount}("");

            emit WithdrawAndTip(msg.sender, to, tId, tipAmount, tipSent);
        }
    }

    /// @notice Refunds gas spent on transaction to the caller
    function _refundGas(uint256 startGas) internal {
        unchecked {
            uint256 balance = address(this).balance;
            if (balance == 0) {
                return;
            }

            uint256 basefee = min(block.basefee, config.maxBaseFeeRefund);
            uint256 gasPrice = min(tx.gasprice, basefee + config.maxPriorityFee);
            uint256 gasUsed = min(startGas - gasleft() + config.baseGasRefund, config.maxGasRefund);
            uint256 refundAmount = min(gasPrice * gasUsed, balance);
            (bool refundSent,) = tx.origin.call{value: refundAmount}("");
            emit GasRefund(tx.origin, refundAmount, refundSent);
        }
    }

    /// @notice Returns the min of two integers
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0

import {Bidder} from "./Bidder.sol";
import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {INounsAuctionHouse} from "./external/interfaces/INounsAuctionHouse.sol";

pragma solidity 0.8.17;

contract BidderFactory {
    event CreateBidder(address b);

    function deploy(address t, address ah, address _owner, Bidder.Config memory cfg)
        external
        payable
        returns (address)
    {
        Bidder b = new Bidder{value: msg.value}(IERC721(t), INounsAuctionHouse(ah), _owner, cfg);

        emit CreateBidder(address(b));

        return address(b);
    }
}

// SPDX-License-Identifier: GPL-3.0

/**
 *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *
 */

pragma solidity 0.8.17;

interface INounsAuctionHouse {
    struct Auction {
        // ID for the Noun (ERC721 token ID)
        uint256 nounId;
        // The current highest bid amount
        uint256 amount;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // The address of the current highest bid
        address payable bidder;
        // Whether or not the auction has been settled
        bool settled;
    }

    event AuctionCreated(uint256 indexed nounId, uint256 startTime, uint256 endTime);

    event AuctionBid(uint256 indexed nounId, address sender, uint256 value, bool extended);

    event AuctionExtended(uint256 indexed nounId, uint256 endTime);

    event AuctionSettled(uint256 indexed nounId, address winner, uint256 amount);

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    function auction()
        external
        view
        returns (
            uint256 nounId,
            uint256 amount,
            uint256 startTime,
            uint256 endTime,
            address payable bidder,
            bool settled
        );

    function reservePrice() external view returns (uint256);

    function minBidIncrementPercentage() external view returns (uint8);

    function settleAuction() external;

    function settleCurrentAndCreateNewAuction() external;

    function createBid(uint256 nounId) external payable;

    function pause() external;

    function unpause() external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;
}