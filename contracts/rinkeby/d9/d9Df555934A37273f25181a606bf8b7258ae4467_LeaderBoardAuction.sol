// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*----------------------------------------------------------\
|                             _                 _           |
|        /\                  | |     /\        | |          |
|       /  \__   ____ _ _ __ | |_   /  \   _ __| |_ ___     |
|      / /\ \ \ / / _` | '_ \| __| / /\ \ | '__| __/ _ \    |
|     / ____ \ V / (_| | | | | |_ / ____ \| |  | ||  __/    |
|    /_/    \_\_/ \__,_|_| |_|\__/_/    \_\_|   \__\___|    |
|                                                           |
|    https://avantarte.com/careers                          |
|    https://avantarte.com/support/contact                  |
|                                                           |
\----------------------------------------------------------*/

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {WithdrawsLib} from "../../libraries/Withdraws/WithdrawsLib.sol";
import {TimerData} from "../../libraries/Timer/TimerController.sol";
import {TimerLib} from "../../libraries/Timer/TimerLib.sol";
import {AdminControl} from "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../../constants/errors/AuctionErrorMessages.sol";

/// @notice a bid made to the auction
struct AuctionEntry {
    /// @notice the address for the entrant
    address addr;
    /// @notice the total bid for the entrant
    uint256 bid;
    /// @notice the id for the user/account
    bytes32 id;
    /// @notice the timestamp for the last entry/update
    uint256 time;
}

struct Props {
    uint256 floor;
    uint256 step;
    address nftAddr;
    address tokensVault;
    uint256 minutesIncrease;
    uint256 minutesPadding;
    bytes32 productId;
}

/// @title A contract to facilitate a leaderboard/footrace auction for avant arte
/// @author [email protected]
contract LeaderBoardAuction is AdminControl {
    using TimerLib for TimerLib.Timer;
    /// @dev the timer for the auction
    TimerLib.Timer private timer;

    /// @notice an event to call when a token is purchased
    /// @dev used to email users of aa and for record keeping
    /// @param walletAddress the wallet who made the purchase
    /// @param tokenId the token id purchased
    /// @param productId the product purchased
    /// @param accountId the account account who made the purchas
    event OnPurchase(
        address walletAddress,
        uint256 tokenId,
        bytes32 productId,
        bytes32 accountId
    );

    /// @notice an event to call when a bid is made
    event OnAuctionClosed(
        address recipient,
        uint256 revenue,
        bytes32 productId
    );

    /// @notice an event to call when a bid is made or updated
    /// @param entry the new entry
    /// @param bid the bid that was added to the entry or created the entry
    /// @param isNew if false this is a new entry, if true this is an increase for the entry
    event OnBid(AuctionEntry entry, bytes32 productId, uint256 bid, bool isNew);

    /// @dev when the auction has minutesPadding left, increase time by minutesIncrease
    uint256 public minutesIncrease;
    /// @dev the time before the end of the auction that the time increase happens
    uint256 public minutesPadding;
    /// @dev the address of the nft contract we use
    address public nftAddr;
    /// @dev the address of the nft contract we use
    address public tokensVault;
    /// @dev keeps track of the tokens we give to winners
    uint256[] public tokenIds;
    /// @dev the floor to enter the auction
    uint256 public floor;
    /// @dev required increments for bids
    uint256 public step;
    /// @dev tracks information for the entry - all entrants/winners will share entries for optimization.
    mapping(address => AuctionEntry) public entries;
    /// @dev tracks the size of the entrants mapping
    uint256 public entrantsSize;
    /// @dev tracks addresses that entered the auction
    mapping(uint256 => address) public entrants;
    /// @dev flags if the auction is closed
    bool public isClosed;
    /// @dev tracks the size of the winners mapping
    uint256 public winnersSize;
    /// @dev a mapping indexing winners to their position
    mapping(uint256 => address) public winners;
    /// @dev a mapping to check if an address is a winner (optimizes withdraws/claims)
    mapping(address => bool) public isWinners;
    /// @dev a mapping to check if a user already withdrawn their funds
    mapping(address => bool) public didWithdraw;
    /// @dev the product id for the auction
    bytes32 public productId;

    constructor(Props memory props) {
        floor = props.floor;
        step = props.step;
        nftAddr = props.nftAddr;
        tokensVault = props.tokensVault;
        minutesIncrease = props.minutesIncrease;
        minutesPadding = props.minutesPadding;
        productId = props.productId;
    }

    /// @dev increase bid
    /// @param addr an address to increase
    /// @param bid the score the address increase
    function _increaseBid(address addr, uint256 bid) private {
        require(!isClosed, AUCTION_ERR_CLOSED);
        require(bid % step == 0, AUCTION_ERR_STEP);
        entries[addr].bid += bid;
        entries[addr].time = TimerLib._now();
    }

    /// @dev adds bid to the leader board
    /// @param addr an address to enter/increase
    /// @param bid thr bid
    /// @param id the id associated with the draw entry
    function _addBid(
        address addr,
        uint256 bid,
        bytes32 id
    ) private {
        require(!isClosed, AUCTION_ERR_CLOSED);
        require(bid >= floor, AUCTION_ERR_FLOOR);
        require(bid % step == 0, AUCTION_ERR_STEP);
        entrants[entrantsSize] = addr;
        entrantsSize++;
        entries[addr] = AuctionEntry(addr, bid, id, TimerLib._now());
    }

    /// @notice set the tokens - should be the same length of array as the size of the winners
    /// @param _tokenIds the new list of tokens the contract can manage
    function setTokens(uint256[] memory _tokenIds) external adminRequired {
        tokenIds = _tokenIds;
    }

    /// @notice winners can claim tokens based on their position
    function claimToken() external {
        require(isWinners[msg.sender], AUCTION_ERR_NOT_WINNER);
        IERC721 nft = IERC721(nftAddr);

        // find the winner's position
        for (uint256 i = 0; i < winnersSize; i++) {
            if (winners[i] == msg.sender) {
                // transfer ownership for the token
                nft.transferFrom(tokensVault, msg.sender, tokenIds[i]);
                emit OnPurchase(
                    msg.sender,
                    tokenIds[i],
                    productId,
                    entries[msg.sender].id
                );
                return;
            }
        }
    }

    /// @notice allows admins to pause the auction if needed
    function setPaused(bool _paused) external adminRequired {
        timer.paused = _paused;
    }

    /// @notice checks if the auction is paused
    function paused() external view returns (bool) {
        return timer.paused;
    }

    /// @notice (admin) set a new floor price
    /// @param _floor the new floor price for the auction
    function setFloor(uint256 _floor) external adminRequired {
        floor = _floor;
    }

    /// @notice (admin) set a new product id
    /// @param _productId the new product id
    function setProductId(bytes32 _productId) external adminRequired {
        productId = _productId;
    }

    /// @notice (admin) set new timing logic
    /// @param _minutesIncrease the new time increase in minutes
    /// @param _minutesPadding the time padding in minutes
    function setTimingLogic(uint256 _minutesIncrease, uint256 _minutesPadding)
        external
        adminRequired
    {
        minutesIncrease = _minutesIncrease;
        minutesPadding = _minutesPadding;
    }

    /// @notice (admin) set a new step size
    /// @param _step the step size for the bids
    function setStep(uint256 _step) external adminRequired {
        step = _step;
    }

    /// @notice returns the count of the auction entries
    /// @return count how many entries are in the auction
    function count() external view returns (uint256) {
        return entrantsSize;
    }

    /// @notice get the list of auction entries with pagination
    /// @param skip skip n items in array
    /// @param limit limit how many items to get back
    function getEntries(uint256 skip, uint256 limit)
        external
        view
        returns (AuctionEntry[] memory)
    {
        uint256 len = entrantsSize - skip > limit ? limit : entrantsSize - skip;
        AuctionEntry[] memory auctionEntries = new AuctionEntry[](len);
        for (uint256 i = 0; i < len; i++) {
            auctionEntries[i] = entries[entrants[i + skip]];
        }
        return auctionEntries;
    }

    /// @notice gets the entries for the winners
    function getWinners() external view returns (AuctionEntry[] memory) {
        uint256 len = winnersSize;
        AuctionEntry[] memory auctionEntries = new AuctionEntry[](len);
        for (uint256 i = 0; i < len; ++i) {
            auctionEntries[i] = entries[winners[i]];
        }
        return auctionEntries;
    }

    /// @notice (admin) close the auction and collect the funds from the winners
    /// @param recipient the address to which we send the winners funds to
    /// @param _winners a list of addresses to be picked as winners
    function closeAuction(
        address payable recipient,
        address[] calldata _winners
    ) external adminRequired {
        isClosed = true;
        // collect the scores from the winners
        uint256 sum = 0;
        winnersSize = _winners.length;
        for (uint256 i = 0; i < winnersSize; i++) {
            address addr = _winners[i];
            sum += entries[addr].bid;
            isWinners[addr] = true;
            winners[i] = addr;
        }
        WithdrawsLib._withdraw(payable(recipient), sum);
        emit OnAuctionClosed(recipient, sum, productId);
    }

    /// @notice did the given address win the auction
    function didWin(address addr) public view returns (bool) {
        return isWinners[addr];
    }

    /// @dev withdraw bid for the address
    /// @param addr the address to which we refund the funds
    function _refundBid(address payable addr) private {
        require(!didWithdraw[addr], AUCTION_ERR_ALREADY_REFUNDED);
        didWithdraw[addr] = true;
        uint256 refund = entries[addr].bid;
        require(refund > 0, AUCTION_ERR_NOTHING_TO_REFUND);
        WithdrawsLib._withdraw(addr, refund);
    }

    /// @notice (admin) refund a bid manually by an admin
    /// @param addr the address to which we refund the funds
    function refundBid(address payable addr) external adminRequired {
        _refundBid(addr);
    }

    /// @notice withdraw bid for the address, non winners only
    function withdrawBid() external {
        require(isClosed, AUCTION_ERR_STILL_RUNNING);
        require(!didWin(msg.sender), AUCTION_ERR_IS_WINNER);
        _refundBid(payable(msg.sender));
    }

    /// @notice make a bid in he auction
    /// @param id the id of the aa user
    function makeBid(bytes32 id) external payable {
        require(!timer.paused, AUCTION_ERR_PAUSED);
        require(timer._isRunning(), AUCTION_ERR_IS_OVER);

        if (entries[msg.sender].addr == address(0)) {
            _addBid(msg.sender, msg.value, id);
            emit OnBid(entries[msg.sender], productId, msg.value, true);
        } else {
            _increaseBid(msg.sender, msg.value);
            emit OnBid(entries[msg.sender], productId, msg.value, false);
        }

        // if deadline is in less than minutesPadding away, add minutesIncrease
        if (
            TimerLib._now() + (minutesPadding * 1 minutes) > timer._deadline()
        ) {
            timer._updateRunningTime(
                timer.runningTime + (minutesIncrease * 1 minutes)
            );
        }
    }

    /// @notice (admin) allows to withdraw all funds from the contract manually
    /// @param to the address to get the funds
    function withdraw(address payable to, uint256 funds)
        external
        adminRequired
    {
        WithdrawsLib._withdraw(to, funds);
    }

    /// @notice (admin) start the release timer
    /// @param hoursTime the time for the release in hours
    function start(uint256 hoursTime) external adminRequired {
        timer._start(hoursTime * 1 hours);
        isClosed = false;
    }

    /// @notice provides data on the running timer
    /// @return TimerData the information from the timer
    function timerData() external view returns (TimerData memory) {
        return TimerData(timer.startTime, timer.runningTime);
    }

    /// @notice checks if the auction is currently open
    function isOpen() external view returns (bool) {
        return timer._isRunning() && !isClosed;
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
pragma solidity ^0.8.7;

/// @title provides functionality to use time
library WithdrawsLib {
    /// @notice an event to call when funds are withdrawn
    event OnWithdraw(address addr, uint256 balance);

    /// @notice allows to withdraw all the funds from the contract
    function _withdrawAllFunds(address payable _to) internal {
        _withdraw(_to, address(this).balance);
    }

    /// @notice allows to withdraw funds from the contract
    function _withdraw(address payable _to, uint256 amount) internal {
        require(_to != address(0), "address 0");
        uint256 balance = address(this).balance;
        require(balance >= amount, "no funds");

        emit OnWithdraw(_to, balance);
        /// solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _to.call{value: amount}("");
        require(success, "failed withdraw");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./TimerLib.sol";

struct TimerData {
    /// @notice the time the contract started (seconds)
    uint256 startTime;
    /// @notice the time the contract is running from startTime (seconds)
    uint256 runningTime;
}

/// @title provides functionality to use time
contract TimerController {
    using TimerLib for TimerLib.Timer;
    TimerLib.Timer private _timer;

    /// @dev makes sure the timer is running
    modifier onlyRunning() {
        require(_isTimerRunning(), "timer over");
        _;
    }

    /// @dev returns the timer data
    function _getTimerData() internal view returns (TimerData memory) {
        return TimerData(_timer.startTime, _timer.runningTime);
    }

    /// @dev checks if the timer is still running
    function _isTimerRunning() internal view returns (bool) {
        return _timer._isRunning();
    }

    /// @dev should be called in the constructor
    function _startTimer(uint256 endsInHours) internal {
        _timer._start(endsInHours * 1 hours);
    }

    /// @dev set a new end time in hours (from the given time)
    function _addHours(uint256 addedHours) internal {
        _timer._updateRunningTime(_timer.runningTime + (addedHours * 1 hours));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title provides functionality to use time
library TimerLib {
    using TimerLib for Timer;
    struct Timer {
        /// @notice the time the contract started
        uint256 startTime;
        /// @notice the time the contract is running from startTime
        uint256 runningTime;
        /// @notice is the timer paused
        bool paused;
    }

    /// @notice is the timer running - marked as running and has time remaining
    function _deadline(Timer storage self) internal view returns (uint256) {
        return self.startTime + self.runningTime;
    }

    function _now() internal view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }

    /// @notice is the timer running - marked as running and has time remaining
    function _isRunning(Timer storage self) internal view returns (bool) {
        return !self.paused && (self._deadline() > _now());
    }

    /// @notice starts the timer, call again to restart
    function _start(Timer storage self, uint256 runningTime) internal {
        self.paused = false;
        self.startTime = _now();
        self.runningTime = runningTime;
    }

    /// @notice updates the running time
    function _updateRunningTime(Timer storage self, uint256 runningTime)
        internal
    {
        self.runningTime = runningTime;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAdminControl.sol";

abstract contract AdminControl is Ownable, IAdminControl, ERC165 {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Track registered admins
    EnumerableSet.AddressSet private _admins;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IAdminControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Only allows approved admins to call the specified function
     */
    modifier adminRequired() {
        require(owner() == msg.sender || _admins.contains(msg.sender), "AdminControl: Must be owner or admin");
        _;
    }   

    /**
     * @dev See {IAdminControl-getAdmins}.
     */
    function getAdmins() external view override returns (address[] memory admins) {
        admins = new address[](_admins.length());
        for (uint i = 0; i < _admins.length(); i++) {
            admins[i] = _admins.at(i);
        }
        return admins;
    }

    /**
     * @dev See {IAdminControl-approveAdmin}.
     */
    function approveAdmin(address admin) external override onlyOwner {
        if (!_admins.contains(admin)) {
            emit AdminApproved(admin, msg.sender);
            _admins.add(admin);
        }
    }

    /**
     * @dev See {IAdminControl-revokeAdmin}.
     */
    function revokeAdmin(address admin) external override onlyOwner {
        if (_admins.contains(admin)) {
            emit AdminRevoked(admin, msg.sender);
            _admins.remove(admin);
        }
    }

    /**
     * @dev See {IAdminControl-isAdmin}.
     */
    function isAdmin(address admin) public override view returns (bool) {
        return (owner() == admin || _admins.contains(admin));
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
pragma solidity ^0.8.7;

string constant AUCTION_ERR_NOT_WINNER = "Auction: not winner";
string constant AUCTION_ERR_IS_WINNER = "Auction: is winner";
string constant AUCTION_ERR_CLOSED = "Auction: closed";
string constant AUCTION_ERR_PAUSED = "Auction: paused";
string constant AUCTION_ERR_IS_OVER = "Auction: is over";
string constant AUCTION_ERR_FLOOR = "Auction: lower than floor";
string constant AUCTION_ERR_STEP = "Auction: not within step";
string constant AUCTION_ERR_ALREADY_REFUNDED = "Auction: already refunded";
string constant AUCTION_ERR_NOTHING_TO_REFUND = "Auction: nothing to refund";
string constant AUCTION_ERR_STILL_RUNNING = "Auction: still running";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface for admin control
 */
interface IAdminControl is IERC165 {

    event AdminApproved(address indexed account, address indexed sender);
    event AdminRevoked(address indexed account, address indexed sender);

    /**
     * @dev gets address of all admins
     */
    function getAdmins() external view returns (address[] memory);

    /**
     * @dev add an admin.  Can only be called by contract owner.
     */
    function approveAdmin(address admin) external;

    /**
     * @dev remove an admin.  Can only be called by contract owner.
     */
    function revokeAdmin(address admin) external;

    /**
     * @dev checks whether or not given address is an admin
     * Returns True if they are
     */
    function isAdmin(address admin) external view returns (bool);

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