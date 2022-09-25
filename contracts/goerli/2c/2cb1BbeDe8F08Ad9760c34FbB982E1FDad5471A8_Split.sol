// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "solmate/src/auth/Owned.sol";

/// @title Split
///
/// @dev This contract allows to split Ether payments among a group of accounts. The sender does not need
/// to be aware that the Ether will be split in this way, since it is handled transparently by the contract.
///
/// The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by
/// assigning each account to a number of shares. Of all the Ether that this contract receives, each account
/// will then be able to claim an amount proportional to the percentage of total shares they were assigned.
///
/// `Split` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
/// accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling
/// the {release} function.
///
/// @author Ahmed Ali <github.com/ahmedali8>
contract Split is Context, Owned {
    /*//////////////////////////////////////////////////////////////
                                VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev Getter for the total shares held by payees.
    uint256 public totalShares;

    /// @dev Getter for the total amount of Ether already released.
    uint256 public totalReleased;

    /// @dev Getter for the amount of shares held by an account.
    mapping(address => uint256) public shares;

    /// @dev Getter for the amount of Ether already released to a payee.
    mapping(address => uint256) public released;

    /// @dev Getter for the address of the payee number `index`.
    address[] public payees;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event PayeeAdded(address account, uint256 shares);
    event PayeeRemoved(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @dev Sets `owner_` as {owner} of contract.
    ///
    /// @param owner_ addres - address of owner for contract.
    constructor(address owner_) payable Owned(owner_) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /*//////////////////////////////////////////////////////////////
                                RECEIVE
    //////////////////////////////////////////////////////////////*/

    /// @dev The Ether received will be logged with {PaymentReceived} events.
    /// Note that these events are not fully reliable: it's possible for a
    /// contract to receive Ether without triggering this function. This only
    /// affects the reliability of the events, and not the actual splitting of Ether.
    ///
    /// To learn more about this see the Solidity documentation for
    /// https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function
    receive() external payable {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /*//////////////////////////////////////////////////////////////
                        NON-VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Triggers a transfer to `account` of the amount of Ether they are owed,
    /// according to their percentage of the total shares and their previous withdrawals.
    ///
    /// @param account_ address - address of payee.
    function release(address payable account_) external {
        require(shares[account_] != 0, "N0_SHARES");

        uint256 payment_ = releasable(account_);

        require(payment_ != 0, "NO_DUE_PAYMENT");

        // _totalReleased is the sum of all values in _released.
        // If "_totalReleased += payment_" does not overflow, then "_released[account] += payment_" cannot overflow.
        totalReleased += payment_;
        unchecked {
            released[account_] += payment_;
        }

        emit PaymentReleased(account_, payment_);
        Address.sendValue(account_, payment_);
    }

    /// @dev Each account in `payees` is assigned the number of shares at
    /// the matching position in the `shares` array.
    ///
    /// @param payees_ address[] - addresses to add in {payees} array.
    /// @param shares_ uint256[] - shares of respective addresses.
    ///
    /// Note - All addresses in `payees` must be non-zero. Both arrays must have the same
    /// non-zero length, and there must be no duplicates in `payees`.
    function addPayees(address[] calldata payees_, uint256[] calldata shares_) external onlyOwner {
        uint256 payeesLen_ = payees_.length;

        require(payeesLen_ != 0 && payeesLen_ == shares_.length, "INVALID_LENGTH");

        for (uint256 i = 0; i < payeesLen_; ) {
            _addPayee(payees_[i], shares_[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Account in `payee` is assigned the number of share.
    ///
    /// @param payee_ address - address to add in {payees} array.
    /// @param share_ uint256 - share of respective address.
    ///
    /// Note - Address in `payee` must be non-zero and must not be a duplicate.
    function addPayee(address payee_, uint256 share_) external onlyOwner {
        _addPayee(payee_, share_);
    }

    /// @dev Remove payee from payees list with index `index_`.
    ///
    /// @param index_ uint256 - index of payee in payees array.
    ///
    /// Note - `index_` must be of valid payee.
    function removePayee(uint256 index_) external onlyOwner {
        // no need for any checks as if payee not present at index it would result in
        // revert with panic code 0x32 (Array accessed at an out-of-bounds or negative index)
        address account_ = payees[index_];
        // no need to check share_ as an account cannot have zero share
        uint256 share_ = shares[account_];

        emit PayeeRemoved(account_, share_);

        // swap last index payee with index_ payee and then pop
        payees[index_] = payees[payees.length - 1];
        payees.pop();

        // delete account_ share and decrement from totalShares
        delete shares[account_];
        totalShares -= share_;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Getter for the amount of payee's releasable Ether.
    ///
    /// @param account_ address - payee address.
    /// @return uint256 - pending releasable amount.
    function releasable(address account_) public view returns (uint256) {
        uint256 totalReceived_ = address(this).balance + totalReleased;

        return _pendingPayment(account_, totalReceived_, released[account_]);
    }

    /// @dev Getter for payees length.
    /// @return uint256 - length of payees.
    function totalPayees() external view returns (uint256) {
        return payees.length;
    }

    /// @dev Getter for payees array.
    /// @return address[] - payees array.
    function allPayees() external view returns (address[] memory) {
        return payees;
    }

    /*//////////////////////////////////////////////////////////////
                            PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Internal logic for computing the pending payment of an `account`
    /// given the ether historical balances and already released amounts.
    ///
    /// @param account_ address - payee address.
    /// @param totalReceived_ uint256 - balance of contract + {totalReceived}
    /// @param alreadyReleased_ uint256 - released amount of payee.
    /// @return uint256 - pending payment of `account_`.
    function _pendingPayment(
        address account_,
        uint256 totalReceived_,
        uint256 alreadyReleased_
    ) private view returns (uint256) {
        return (totalReceived_ * shares[account_]) / totalShares - alreadyReleased_;
    }

    /// @dev Adds a new payee to the contract.
    ///
    /// @param account_ The address of the payee to add.
    /// @param share_ The number of share owned by the payee.
    function _addPayee(address account_, uint256 share_) private {
        require(account_ != address(0), "ZERO_ADDRESS");
        require(share_ != 0, "ZERO_SHARE");
        require(shares[account_] == 0, "ALREADY_HAS_SHARES");

        emit PayeeAdded(account_, share_);

        payees.push(account_);
        shares[account_] = share_;
        totalShares += share_;
    }
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}