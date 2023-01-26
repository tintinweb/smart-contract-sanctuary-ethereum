/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// todo function delete payee and set shares. OORRR assign the new array to old, i.e. overwrite

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../token/ERC20/IERC20.sol";
import "../utils/Address.sol";

/*************************************************************
 * @title PaymentSplitter                                    *
 *                                                           *
 * @notice This contract allows to split Ether payments      *
 * among a group of accounts. The sender does not need to    *
 * be aware that the Ether will be split in this way, since  *
 * it is handled transparently by the contract.              *
 *                                                           *
 * @dev The split can be in equal parts or in any other      *
 * arbitrary proportion. The distribution of shares is set   *
 * at the time ofcontract deployment, but can also be        *
 * updated, unlike the OZ `PaymentSplitter` contract.        *
 * `PaymentSplitter` follows a _push payment_ model, i.e.    *
 * that payments are automatically forwarded to the accounts.*
 * Does not support ERC20 tokens.                            *
 *                                                           *
 * @custom:security-contact [email protected]                    *
 *************************************************************/
contract PaymentSplitter {
    address private immutable _factory;
    // _owner is used for access control in setter functions.
    // Can only be set when initializing contract; the token seller can chose to which address to send funds, therefore they are the only ones who should control this contract.
    address private _owner; // todo is there an equivalent to `immutable` keyword for proxies that can't use the constructor?
    uint256 private _totalShares;

    mapping(address => uint256) private _shares;

    uint256 public gasLeft;
    uint256 public initialGas;

    address[] private _payees;
    // todo enumerablemap?
    // or two arrays of same length

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    /**
     * @dev equivalent to `initializer` modifier but cheaper because the clones won't need to write `initialized = true;` to storage each time
     * @dev only called in the master copy, never in clones
     * @dev todo hardcode a constant factory address preferibly and remove constructor.
     * @dev I.e. deploy factory first, then deploy master contract with harcoded address, then use a setter function in factory contract to set the master address
     */
    constructor(address factory_) {
        _factory = factory_;
    }

    /**
     * @dev Creates an instance of `PaymentSplitter` where each _account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     * @dev  _accounts and shares length MUST match and there should be more than one payee address, e.g. 'require( _accounts.length > 1 ? _accounts.length == shares_.length : false)'
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     * @param _data _totalShares saves having increment _totalShares at each loop like so: `_totalShares += shares_`. Instead assigns the total value to `_totalShares` directly once the loop is finished.

     */
    function initialize(bytes calldata _data) external {
        require(msg.sender == _factory);

        address[] memory accounts_;
        uint256[] memory shares_;

        (accounts_, shares_, _totalShares, _owner) = abi.decode(
            _data,
            (address[], uint256[], uint256, address)
        );

        // _owner = msg.sender; // there is no parameter currently for allowing to set the contract _owner to a different address, doesn't seem very useful

        // Storing `_payees.length` in memory may not be a massive gas saving (if not more expensive?) compared to looking it up in every loop of a for-loop, as the arrays are stored in memory
        uint256 i = accounts_.length;
        // using `do...while` loop instead of `while` because we know that the arrays must have at least one element, i.e. we save some gas by not checking the condition on the first loop
        // the caller can only be `_owner` address and therefore it is unnecessary to verify it.
        do {
            // ++i costs less gas compared to i++ or i += 1
            // decrement first because the `length` property is the array elements count, i.e. a starts at 0, i.e. index = length - 1
            --i;
            _payees.push(accounts_[i]);
            _shares[accounts_[i]] = shares_[i];
        } while (i > 0);
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * TODO do we need to use this.balanceOf instead of msg.value? in case ether is sent via selfdestruct for example, otherwise there would be no other way to withdraw such ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable {
        for (uint256 i; i < _payees.length; i++) {
            address account = _payees[i];
            uint256 payment = (msg.value * _shares[account]) / _totalShares;
            Address.sendValue(payable(account), payment);
        }
    }

    /**
     * @notice function to change one or more existing payees, i.e. only the shares receiver account(s), not the shares amount(s)
     * @param totalShares_ is the value that `_totalShares` should be after calling this function.
     +        This avoids calculating the total's difference inside of the function's code, which would be very expensive.
     *
     * MUST:
     *
     * - `_index` MUST be less or equal to `_shares.length - 1`.
     *
     * SHOULD:
     *
     *   - `require(payees[index] != address(0));` i.e. must overwrite an existing account at the specified array index, else `_shares[_account]` will be 0 by default as not initialized.
     *   - `_payees[_index]` must be different from `_account` otherwise the change will have no effect and waste gas
     *   - `_account` should not exist in the array already, else the entire shares calculation may be affected and the duplicated account will be paid twice.
     *   - array arguments `_index` and `_account` must have the same length (number of array items), or else the function may revert with an "index out of bounds" error
     */
    function setSharesAndPayees(
        address[] calldata _accounts,
        uint256[] calldata shares_,
        uint256 totalShares_
    ) external onlyOwner {
        uint256 i = _accounts.length;

        do {
            --i; // ++i costs less gas compared to i++ or i += 1, decrement first because the `length` property is the array elements count, i.e. a starts at 0, i.e. index = length - 1
            _shares[_accounts[i]] = shares_[i];
        } while (i > 0); // using `do...while` loop instead of `while` because we know that the arrays must have at least one element, i.e. we save some gas by not checking the condition on the first loop

        _payees = _accounts;

        _totalShares = totalShares_;
    }

    /***************************
     * External View Functions *
     **************************/

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() external view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the amount of shares held by an _account.
     */
    function shares(address _account) external view returns (uint256) {
        return _shares[_account];
    }

    function payee(uint256 _index) external view returns (address) {
        return _payees[_index];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function getSplitterSettings()
        external
        view
        returns (address[] memory, uint256[] memory, uint256)
    {
        uint256 i = _payees.length;
        uint256[] memory shares_ = new uint256[](i);
        do {
            --i;
            shares_[i] = _shares[_payees[i]];
        } while (i > 0);
        return (_payees, shares_, _totalShares);
    }

    function deleteSplitter() external onlyOwner {
        selfdestruct(payable(_owner));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity 0.8.17;

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
}