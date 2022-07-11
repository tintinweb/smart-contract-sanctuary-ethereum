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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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

pragma solidity 0.8.10;

/***
 * @dev Holds config values used by AuctionRaffle contract.
 * @author TrueFi Engineering team
 */
abstract contract Config {
    // The use of _randomMask and _bidderMask introduces an assumption on max number of participants: 2^32.
    // The use of _bidderMask also introduces an assumption on max bid amount: 2^224 wei.
    // Both of these values are fine for our use case.
    uint256 constant _randomMask = 0xffffffff;
    uint256 constant _randomMaskLength = 32;
    uint256 constant _winnersPerRandom = 256 / _randomMaskLength;
    uint256 constant _bidderMask = _randomMask;
    uint256 constant _bidderMaskLength = _randomMaskLength;

    uint256 immutable _biddingStartTime;
    uint256 immutable _biddingEndTime;
    uint256 immutable _claimingEndTime;
    uint256 immutable _auctionWinnersCount;
    uint256 immutable _raffleWinnersCount;
    uint256 immutable _reservePrice;
    uint256 immutable _minBidIncrement;

    constructor(
        uint256 biddingStartTime_,
        uint256 biddingEndTime_,
        uint256 claimingEndTime_,
        uint256 auctionWinnersCount_,
        uint256 raffleWinnersCount_,
        uint256 reservePrice_,
        uint256 minBidIncrement_
    ) {
        require(auctionWinnersCount_ > 0, "Config: auction winners count must be greater than 0");
        require(raffleWinnersCount_ > 0, "Config: raffle winners count must be greater than 0");
        require(raffleWinnersCount_ % _winnersPerRandom == 0, "Config: invalid raffle winners count");
        require(biddingStartTime_ < biddingEndTime_, "Config: bidding start time must be before bidding end time");
        require(biddingEndTime_ < claimingEndTime_, "Config: bidding end time must be before claiming end time");
        require(reservePrice_ > 0, "Config: reserve price must be greater than 0");
        require(minBidIncrement_ > 0, "Config: min bid increment must be greater than 0");
        require(
            biddingEndTime_ - biddingStartTime_ >= 6 hours,
            "Config: bidding start time and bidding end time must be at least 6h apart"
        );
        require(
            claimingEndTime_ - biddingEndTime_ >= 6 hours,
            "Config: bidding end time and claiming end time must be at least 6h apart"
        );

        _biddingStartTime = biddingStartTime_;
        _biddingEndTime = biddingEndTime_;
        _claimingEndTime = claimingEndTime_;
        _auctionWinnersCount = auctionWinnersCount_;
        _raffleWinnersCount = raffleWinnersCount_;
        _reservePrice = reservePrice_;
        _minBidIncrement = minBidIncrement_;
    }

    function biddingStartTime() external view returns (uint256) {
        return _biddingStartTime;
    }

    function biddingEndTime() external view returns (uint256) {
        return _biddingEndTime;
    }

    function claimingEndTime() external view returns (uint256) {
        return _claimingEndTime;
    }

    function auctionWinnersCount() external view returns (uint256) {
        return _auctionWinnersCount;
    }

    function raffleWinnersCount() external view returns (uint256) {
        return _raffleWinnersCount;
    }

    function reservePrice() external view returns (uint256) {
        return _reservePrice;
    }

    function minBidIncrement() external view returns (uint256) {
        return _minBidIncrement;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/***
 * @dev Defines bid related data types used by AuctionRaffle contract.
 * @author TrueFi Engineering team
 */
abstract contract BidModel {
    struct Bid {
        uint256 bidderID;
        uint256 amount;
        WinType winType;
        bool claimed;
    }

    struct BidWithAddress {
        address bidder;
        Bid bid;
    }

    enum WinType {
        LOSS,
        GOLDEN_TICKET,
        AUCTION,
        RAFFLE
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/***
 * @dev Defines state enums used by AuctionRaffle contract.
 * @author TrueFi Engineering team
 */
abstract contract StateModel {
    enum State {
        AWAITING_BIDDING,
        BIDDING_OPEN,
        BIDDING_CLOSED,
        AUCTION_SETTLED,
        RAFFLE_SETTLED,
        CLAIMING_CLOSED
    }

    enum SettleState {
        AWAITING_SETTLING,
        AUCTION_SETTLED,
        RAFFLE_SETTLED
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/***
 * @title Max Heap library
 * @notice Data structure used by the AuctionRaffle contract to store top bids.
 * It allows retrieving them in descending order on auction settlement.
 * @author TrueFi Engineering team
 */
library MaxHeap {
    function insert(uint256[] storage heap, uint256 key) internal {
        uint256 index = heap.length;
        heap.push(key);
        bubbleUp(heap, index, key);
    }

    function increaseKey(
        uint256[] storage heap,
        uint256 oldValue,
        uint256 newValue
    ) internal {
        uint256 index = findKey(heap, oldValue);
        increaseKeyAt(heap, index, newValue);
    }

    function increaseKeyAt(
        uint256[] storage heap,
        uint256 index,
        uint256 newValue
    ) internal {
        require(newValue > heap[index], "MaxHeap: new value must be bigger than old value");
        heap[index] = newValue;
        bubbleUp(heap, index, newValue);
    }

    function removeMax(uint256[] storage heap) internal returns (uint256 max) {
        require(heap.length > 0, "MaxHeap: cannot remove max element from empty heap");
        max = heap[0];
        heap[0] = heap[heap.length - 1];
        heap.pop();

        uint256 index = 0;
        while (true) {
            uint256 l = left(index);
            uint256 r = right(index);
            uint256 biggest = index;

            if (l < heap.length && heap[l] > heap[index]) {
                biggest = l;
            }
            if (r < heap.length && heap[r] > heap[biggest]) {
                biggest = r;
            }
            if (biggest == index) {
                break;
            }
            (heap[index], heap[biggest]) = (heap[biggest], heap[index]);
            index = biggest;
        }
        return max;
    }

    function bubbleUp(
        uint256[] storage heap,
        uint256 index,
        uint256 key
    ) internal {
        while (index > 0 && heap[parent(index)] < heap[index]) {
            (heap[parent(index)], heap[index]) = (key, heap[parent(index)]);
            index = parent(index);
        }
    }

    function findKey(uint256[] storage heap, uint256 value) internal view returns (uint256) {
        for (uint256 i = 0; i < heap.length; ++i) {
            if (heap[i] == value) {
                return i;
            }
        }
        revert("MaxHeap: key with given value not found");
    }

    function findMin(uint256[] storage heap) internal view returns (uint256 index, uint256 min) {
        uint256 heapLength = heap.length;
        require(heapLength > 0, "MaxHeap: cannot find minimum element on empty heap");

        uint256 n = heapLength / 2;
        min = heap[n];
        index = n;

        for (uint256 i = n + 1; i < heapLength; ++i) {
            uint256 element = heap[i];
            if (element < min) {
                min = element;
                index = i;
            }
        }
    }

    function parent(uint256 index) internal pure returns (uint256) {
        return (index - 1) / 2;
    }

    function left(uint256 index) internal pure returns (uint256) {
        return 2 * index + 1;
    }

    function right(uint256 index) internal pure returns (uint256) {
        return 2 * index + 2;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "Ownable.sol";
import "IERC20.sol";
import "SafeERC20.sol";

import "Config.sol";
import "BidModel.sol";
import "StateModel.sol";
import "MaxHeap.sol";

/***
 * @title Auction & Raffle
 * @notice Draws winners using a mixed auction & raffle scheme.
 * @author TrueFi Engineering team
 */
contract AuctionRaffle is Ownable, Config, BidModel, StateModel {
    using SafeERC20 for IERC20;
    using MaxHeap for uint256[];

    mapping(address => Bid) _bids; // bidder address -> Bid
    mapping(uint256 => address payable) _bidders; // bidderID -> bidder address
    uint256 _nextBidderID = 1;

    uint256[] _heap;
    uint256 _minKeyIndex;
    uint256 _minKeyValue = type(uint256).max;

    SettleState _settleState = SettleState.AWAITING_SETTLING;
    uint256[] _raffleParticipants;

    uint256[] _auctionWinners;
    uint256[] _raffleWinners;

    bool _proceedsClaimed;
    uint256 _claimedFeesIndex;

    uint256[] _tempWinners; // temp array for sorting auction winners used by settleAuction method

    /// @dev A new bid has been placed or an existing bid has been bumped
    event NewBid(address bidder, uint256 bidderID, uint256 bidAmount);

    /// @dev A bidder has been drawn as auction winner
    event NewAuctionWinner(uint256 bidderID);

    /// @dev A bidder has been drawn as raffle winner
    event NewRaffleWinner(uint256 bidderID);

    /// @dev A bidder has been drawn as the golden ticket winner
    event NewGoldenTicketWinner(uint256 bidderID);

    modifier onlyInState(State requiredState) {
        require(getState() == requiredState, "AuctionRaffle: is in invalid state");
        _;
    }

    modifier onlyExternalTransactions() {
        require(msg.sender == tx.origin, "AuctionRaffle: internal transactions are forbidden");
        _;
    }

    constructor(
        address initialOwner,
        uint256 biddingStartTime,
        uint256 biddingEndTime,
        uint256 claimingEndTime,
        uint256 auctionWinnersCount,
        uint256 raffleWinnersCount,
        uint256 reservePrice,
        uint256 minBidIncrement
    )
        Config(
            biddingStartTime,
            biddingEndTime,
            claimingEndTime,
            auctionWinnersCount,
            raffleWinnersCount,
            reservePrice,
            minBidIncrement
        )
        Ownable()
    {
        if (initialOwner != msg.sender) {
            Ownable.transferOwnership(initialOwner);
        }
    }

    receive() external payable {
        revert("AuctionRaffle: contract accepts ether transfers only by bid method");
    }

    fallback() external payable {
        revert("AuctionRaffle: contract accepts ether transfers only by bid method");
    }

    /***
     * @notice Places a new bid or bumps an existing bid.
     * @dev Assigns a unique bidderID to the sender address.
     */
    function bid() external payable onlyExternalTransactions onlyInState(State.BIDDING_OPEN) {
        Bid storage bidder = _bids[msg.sender];
        if (bidder.amount == 0) {
            require(msg.value >= _reservePrice, "AuctionRaffle: bid amount is below reserve price");
            bidder.amount = msg.value;
            bidder.bidderID = _nextBidderID++;
            _bidders[bidder.bidderID] = payable(msg.sender);
            _raffleParticipants.push(bidder.bidderID);

            addBidToHeap(bidder.bidderID, bidder.amount);
        } else {
            require(msg.value >= _minBidIncrement, "AuctionRaffle: bid increment too low");
            uint256 oldAmount = bidder.amount;
            bidder.amount += msg.value;

            updateHeapBid(bidder.bidderID, oldAmount, bidder.amount);
        }
        emit NewBid(msg.sender, bidder.bidderID, bidder.amount);
    }

    /**
     * @notice Draws auction winners and changes contract state to AUCTION_SETTLED.
     * @dev Removes highest bids from the heap, sets their WinType to AUCTION and adds them to _auctionWinners array.
     * Temporarily adds auction winner bidderIDs to a separate heap and then retrieves them in descending order.
     * This is done to efficiently remove auction winners from _raffleParticipants array as they no longer take part
     * in the raffle.
     */
    function settleAuction() external onlyOwner onlyInState(State.BIDDING_CLOSED) {
        _settleState = SettleState.AUCTION_SETTLED;
        uint256 biddersCount = getBiddersCount();
        uint256 raffleWinnersCount = _raffleWinnersCount;
        if (biddersCount <= raffleWinnersCount) {
            return;
        }

        uint256 auctionParticipantsCount = biddersCount - raffleWinnersCount;
        uint256 winnersLength = _auctionWinnersCount;
        if (auctionParticipantsCount < winnersLength) {
            winnersLength = auctionParticipantsCount;
        }

        for (uint256 i = 0; i < winnersLength; ++i) {
            uint256 key = _heap.removeMax();
            uint256 bidderID = extractBidderID(key);
            addAuctionWinner(bidderID);
            _tempWinners.insert(bidderID);
        }

        delete _heap;
        delete _minKeyIndex;
        delete _minKeyValue;

        for (uint256 i = 0; i < winnersLength; ++i) {
            uint256 bidderID = _tempWinners.removeMax();
            removeRaffleParticipant(bidderID - 1);
        }
    }

    /**
     * @notice Draws raffle winners and changes contract state to RAFFLE_SETTLED. The first selected raffle winner
     * becomes the Golden Ticket winner.
     * @dev Sets WinType of the first selected bid to GOLDEN_TICKET. Sets WinType to RAFFLE for the remaining selected
     * bids.
     * @param randomNumbers The source of randomness for the function. Each random number is used to draw at most
     * `_winnersPerRandom` raffle winners.
     */
    function settleRaffle(uint256[] memory randomNumbers) external onlyOwner onlyInState(State.AUCTION_SETTLED) {
        require(randomNumbers.length > 0, "AuctionRaffle: there must be at least one random number passed");

        _settleState = SettleState.RAFFLE_SETTLED;

        uint256 participantsLength = _raffleParticipants.length;
        if (participantsLength == 0) {
            return;
        }

        (participantsLength, randomNumbers[0]) = selectGoldenTicketWinner(participantsLength, randomNumbers[0]);

        uint256 raffleWinnersCount = _raffleWinnersCount;
        if (participantsLength < raffleWinnersCount) {
            selectAllRaffleParticipantsAsWinners(participantsLength);
            return;
        }

        require(
            randomNumbers.length == raffleWinnersCount / _winnersPerRandom,
            "AuctionRaffle: passed incorrect number of random numbers"
        );

        selectRaffleWinners(participantsLength, randomNumbers);
    }

    /**
     * @notice Allows a bidder to claim their funds after the raffle is settled.
     * Golden Ticket winner can withdraw the full bid amount.
     * Raffle winner can withdraw the bid amount minus `_reservePrice`.
     * Non-winning bidder can withdraw the bid amount minus 2% fee.
     * Auction winner pays the full bid amount and is not entitled to any withdrawal.
     */
    function claim(uint256 bidderID) external onlyInState(State.RAFFLE_SETTLED) {
        address payable bidderAddress = getBidderAddress(bidderID);
        Bid storage bidder = _bids[bidderAddress];
        require(!bidder.claimed, "AuctionRaffle: funds have already been claimed");
        require(bidder.winType != WinType.AUCTION, "AuctionRaffle: auction winners cannot claim funds");

        bidder.claimed = true;
        uint256 claimAmount;
        if (bidder.winType == WinType.RAFFLE) {
            claimAmount = bidder.amount - _reservePrice;
        } else if (bidder.winType == WinType.GOLDEN_TICKET) {
            claimAmount = bidder.amount;
        } else if (bidder.winType == WinType.LOSS) {
            claimAmount = (bidder.amount * 98) / 100;
        }

        if (claimAmount > 0) {
            bidderAddress.transfer(claimAmount);
        }
    }

    /**
     * @notice Allows the owner to claim proceeds from the ticket sale after the raffle is settled.
     * Proceeds include:
     * sum of auction winner bid amounts,
     * `_reservePrice` paid by each raffle winner (except the Golden Ticket winner).
     */
    function claimProceeds() external onlyOwner onlyInState(State.RAFFLE_SETTLED) {
        require(!_proceedsClaimed, "AuctionRaffle: proceeds have already been claimed");
        _proceedsClaimed = true;

        uint256 biddersCount = getBiddersCount();
        if (biddersCount == 0) {
            return;
        }

        uint256 totalAmount = 0;

        uint256 auctionWinnersCount = _auctionWinners.length;
        for (uint256 i = 0; i < auctionWinnersCount; ++i) {
            address bidderAddress = _bidders[_auctionWinners[i]];
            totalAmount += _bids[bidderAddress].amount;
        }

        uint256 raffleWinnersCount = _raffleWinnersCount - 1;
        if (biddersCount <= raffleWinnersCount) {
            raffleWinnersCount = biddersCount - 1;
        }
        totalAmount += raffleWinnersCount * _reservePrice;

        payable(owner()).transfer(totalAmount);
    }

    /**
     * @notice Allows the owner to claim the 2% fees from non-winning bids after the raffle is settled.
     * @dev This function is designed to be called multiple times, to split iteration though all non-winning bids across
     * multiple transactions.
     * @param bidsCount The number of bids to be processed at once.
     */
    function claimFees(uint256 bidsCount) external onlyOwner onlyInState(State.RAFFLE_SETTLED) {
        uint256 claimedFeesIndex = _claimedFeesIndex;
        uint256 feesCount = _raffleParticipants.length;
        require(feesCount > 0, "AuctionRaffle: there are no fees to claim");
        require(claimedFeesIndex < feesCount, "AuctionRaffle: fees have already been claimed");

        uint256 endIndex = claimedFeesIndex + bidsCount;
        if (endIndex > feesCount) {
            endIndex = feesCount;
        }

        uint256 fee = 0;
        for (uint256 i = claimedFeesIndex; i < endIndex; ++i) {
            address bidderAddress = getBidderAddress(_raffleParticipants[i]);
            uint256 bidAmount = _bids[bidderAddress].amount;
            fee += bidAmount - (bidAmount * 98) / 100;
        }

        _claimedFeesIndex = endIndex;
        payable(owner()).transfer(fee);
    }

    /**
     * @notice Allows the owner to withdraw all funds left in the contract by the participants.
     * Callable only after the claiming window is closed.
     */
    function withdrawUnclaimedFunds() external onlyOwner onlyInState(State.CLAIMING_CLOSED) {
        uint256 unclaimedFunds = address(this).balance;
        payable(owner()).transfer(unclaimedFunds);
    }

    /**
     * @notice Allows the owner to retrieve any ERC-20 tokens that were sent to the contract by accident.
     * @param tokenAddress The address of an ERC-20 token contract.
     */
    function rescueTokens(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));

        require(balance > 0, "AuctionRaffle: no tokens for given address");
        token.safeTransfer(owner(), balance);
    }

    function getRaffleParticipants() external view returns (uint256[] memory) {
        return _raffleParticipants;
    }

    /// @return A list of auction winner bidder IDs.
    function getAuctionWinners() external view returns (uint256[] memory) {
        return _auctionWinners;
    }

    /// @return A list of raffle winner bidder IDs.
    function getRaffleWinners() external view returns (uint256[] memory) {
        return _raffleWinners;
    }

    function getBid(address bidder) external view returns (Bid memory) {
        Bid storage bid_ = _bids[bidder];
        require(bid_.bidderID != 0, "AuctionRaffle: no bid by given address");
        return bid_;
    }

    function getBidByID(uint256 bidderID) external view returns (Bid memory) {
        address bidder = getBidderAddress(bidderID);
        return _bids[bidder];
    }

    function getBidsWithAddresses() external view returns (BidWithAddress[] memory) {
        uint256 totalBids = getBiddersCount();

        BidWithAddress[] memory bids = new BidWithAddress[](totalBids);

        for (uint256 i = 1; i <= totalBids; ++i) {
            BidWithAddress memory bid_ = getBidWithAddress(i);
            bids[i - 1] = bid_;
        }

        return bids;
    }

    function getBidWithAddress(uint256 bidderID) public view returns (BidWithAddress memory) {
        address bidder = getBidderAddress(bidderID);
        Bid storage bid_ = _bids[bidder];

        BidWithAddress memory bidWithAddress = BidWithAddress({bidder: bidder, bid: bid_});

        return bidWithAddress;
    }

    /// @return Address of bidder account for given bidder ID.
    function getBidderAddress(uint256 bidderID) public view returns (address payable) {
        address payable bidderAddress = _bidders[bidderID];
        require(bidderAddress != address(0), "AuctionRaffle: bidder with given ID does not exist");
        return bidderAddress;
    }

    function getBiddersCount() public view returns (uint256) {
        return _nextBidderID - 1;
    }

    function getState() public view returns (State) {
        if (block.timestamp >= _claimingEndTime) {
            return State.CLAIMING_CLOSED;
        }
        if (_settleState == SettleState.RAFFLE_SETTLED) {
            return State.RAFFLE_SETTLED;
        }
        if (_settleState == SettleState.AUCTION_SETTLED) {
            return State.AUCTION_SETTLED;
        }
        if (block.timestamp >= _biddingEndTime) {
            return State.BIDDING_CLOSED;
        }
        if (block.timestamp >= _biddingStartTime) {
            return State.BIDDING_OPEN;
        }
        return State.AWAITING_BIDDING;
    }

    /**
     * @notice Adds a bid to the heap if it isn't full or the heap key is greater than `_minKeyValue`.
     * @dev Updates _minKeyIndex and _minKeyValue if needed.
     * @param bidderID Unique bidder ID
     * @param amount The bid amount
     */
    function addBidToHeap(uint256 bidderID, uint256 amount) private {
        bool isHeapFull = getBiddersCount() > _auctionWinnersCount; // bid() already incremented _nextBidderID
        uint256 key = getKey(bidderID, amount);
        uint256 minKeyValue = _minKeyValue;

        if (isHeapFull) {
            if (key <= minKeyValue) {
                return;
            }
            _heap.increaseKey(minKeyValue, key);
            updateMinKey();
        } else {
            _heap.insert(key);
            if (key <= minKeyValue) {
                _minKeyIndex = _heap.length - 1;
                _minKeyValue = key;
                return;
            }
            updateMinKey();
        }
    }

    /**
     * @notice Updates an existing bid or replaces an existing bid with a new one in the heap.
     * @dev Updates _minKeyIndex and _minKeyValue if needed.
     * @param bidderID Unique bidder ID
     * @param oldAmount Previous bid amount
     * @param newAmount New bid amount
     */
    function updateHeapBid(
        uint256 bidderID,
        uint256 oldAmount,
        uint256 newAmount
    ) private {
        bool isHeapFull = getBiddersCount() >= _auctionWinnersCount;
        uint256 key = getKey(bidderID, newAmount);
        uint256 minKeyValue = _minKeyValue;

        bool shouldUpdateHeap = key > minKeyValue;
        if (isHeapFull && !shouldUpdateHeap) {
            return;
        }
        uint256 oldKey = getKey(bidderID, oldAmount);
        bool updatingMinKey = oldKey <= minKeyValue;
        if (updatingMinKey) {
            _heap.increaseKeyAt(_minKeyIndex, key);
            updateMinKey();
            return;
        }
        _heap.increaseKey(oldKey, key);
    }

    function updateMinKey() private {
        (_minKeyIndex, _minKeyValue) = _heap.findMin();
    }

    function addAuctionWinner(uint256 bidderID) private {
        setBidWinType(bidderID, WinType.AUCTION);
        _auctionWinners.push(bidderID);
        emit NewAuctionWinner(bidderID);
    }

    function addRaffleWinner(uint256 bidderID) private {
        setBidWinType(bidderID, WinType.RAFFLE);
        _raffleWinners.push(bidderID);
        emit NewRaffleWinner(bidderID);
    }

    function addGoldenTicketWinner(uint256 bidderID) private {
        setBidWinType(bidderID, WinType.GOLDEN_TICKET);
        _raffleWinners.push(bidderID);
        emit NewGoldenTicketWinner(bidderID);
    }

    function setBidWinType(uint256 bidderID, WinType winType) private {
        address bidderAddress = getBidderAddress(bidderID);
        _bids[bidderAddress].winType = winType;
    }

    /**
     * @dev Selects one Golden Ticket winner from a random number.
     * Saves the winner at the beginning of _raffleWinners array and sets bidder WinType to GOLDEN_TICKET.
     * @param participantsLength The length of current participants array
     * @param randomNumber The random number to select raffle winner from
     * @return participantsLength New participants array length
     * @return randomNumber Shifted random number by `_randomMaskLength` bits to the right
     */
    function selectGoldenTicketWinner(uint256 participantsLength, uint256 randomNumber)
        private
        returns (uint256, uint256)
    {
        uint256 winnerIndex = winnerIndexFromRandomNumber(participantsLength, randomNumber);

        uint256 bidderID = _raffleParticipants[winnerIndex];
        addGoldenTicketWinner(bidderID);

        removeRaffleParticipant(winnerIndex);
        return (participantsLength - 1, randomNumber >> _randomMaskLength);
    }

    function selectAllRaffleParticipantsAsWinners(uint256 participantsLength) private {
        for (uint256 i = 0; i < participantsLength; ++i) {
            uint256 bidderID = _raffleParticipants[i];
            addRaffleWinner(bidderID);
        }
        delete _raffleParticipants;
    }

    /**
     * @dev Selects `_winnersPerRandom` - 1 raffle winners for the first random number -- it assumes that one bidder
     * was selected before as the Golden Ticket winner. Then it selects `_winnersPerRandom` winners for each remaining
     * random number.
     * @param participantsLength The length of current participants array
     * @param randomNumbers The array of random numbers to select raffle winners from
     */
    function selectRaffleWinners(uint256 participantsLength, uint256[] memory randomNumbers) private {
        participantsLength = selectRandomRaffleWinners(participantsLength, randomNumbers[0], _winnersPerRandom - 1);
        for (uint256 i = 1; i < randomNumbers.length; ++i) {
            participantsLength = selectRandomRaffleWinners(participantsLength, randomNumbers[i], _winnersPerRandom);
        }
    }

    /**
     * @notice Selects a number of raffle winners from _raffleParticipants array. Saves the winners in _raffleWinners
     * array and sets their WinType to RAFFLE.
     * @dev Divides passed randomNumber into `_randomMaskLength` bit numbers and then selects one raffle winner using
     * each small number.
     * @param participantsLength The length of current participants array
     * @param randomNumber The random number used to select raffle winners
     * @param winnersCount The number of raffle winners to select from a single random number
     * @return New participants length
     */
    function selectRandomRaffleWinners(
        uint256 participantsLength,
        uint256 randomNumber,
        uint256 winnersCount
    ) private returns (uint256) {
        for (uint256 i = 0; i < winnersCount; ++i) {
            uint256 winnerIndex = winnerIndexFromRandomNumber(participantsLength, randomNumber);

            uint256 bidderID = _raffleParticipants[winnerIndex];
            addRaffleWinner(bidderID);

            removeRaffleParticipant(winnerIndex);
            --participantsLength;
            randomNumber = randomNumber >> _randomMaskLength;
        }

        return participantsLength;
    }

    /**
     * @notice Removes a participant from _raffleParticipants array.
     * @dev Swaps _raffleParticipants[index] with the last one, then removes the last one.
     * @param index The index of raffle participant to remove
     */
    function removeRaffleParticipant(uint256 index) private {
        uint256 participantsLength = _raffleParticipants.length;
        require(index < participantsLength, "AuctionRaffle: invalid raffle participant index");
        _raffleParticipants[index] = _raffleParticipants[participantsLength - 1];
        _raffleParticipants.pop();
    }

    /**
     * @notice Calculates unique heap key based on bidder ID and bid amount. The key is designed so that higher bids
     * are assigned a higher key value. In case of a draw in bid amount, lower bidder ID gives a higher key value.
     * @dev The difference between `_bidderMask` and bidderID is stored in lower bits of the returned key.
     * Bid amount is stored in higher bits of the returned key.
     * @param bidderID Unique bidder ID
     * @param amount The bid amount
     * @return Unique heap key
     */
    function getKey(uint256 bidderID, uint256 amount) private pure returns (uint256) {
        return (amount << _bidderMaskLength) | (_bidderMask - bidderID);
    }

    /**
     * @notice Extracts bidder ID from a heap key
     * @param key Heap key
     * @return Extracted bidder ID
     */
    function extractBidderID(uint256 key) private pure returns (uint256) {
        return _bidderMask - (key & _bidderMask);
    }

    /**
     * @notice Calculates winner index
     * @dev Calculates modulo of `_randomMaskLength` lower bits of randomNumber and participantsLength
     * @param participantsLength The length of current participants array
     * @param randomNumber The random number to select raffle winner from
     * @return Winner index
     */
    function winnerIndexFromRandomNumber(uint256 participantsLength, uint256 randomNumber)
        private
        pure
        returns (uint256)
    {
        uint256 smallRandom = randomNumber & _randomMask;
        return smallRandom % participantsLength;
    }
}