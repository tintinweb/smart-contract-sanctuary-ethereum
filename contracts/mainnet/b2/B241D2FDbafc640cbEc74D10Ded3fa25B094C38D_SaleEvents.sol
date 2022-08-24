// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IS7NSManagement.sol";
import "./interfaces/IS7NSAvatar.sol";

contract SaleEvents {
    using SafeERC20 for IERC20;

    struct EventInfo {
        uint256 start;
        uint256 end;
        uint256 maxAllocation;      
        uint256 availableAmount;
        uint256 maxSaleAmount;
        bool isPublic;
        bool forcedTerminate;
    }
    
    bytes32 private constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    IS7NSManagement public management;
    uint256 public counter;
    
    mapping(uint256 => EventInfo) public events;
    mapping(uint256 => address) public nftTokens;
    mapping(uint256 => mapping(address => uint256)) public purchased;
    mapping(uint256 => mapping(address => uint256)) public prices;
    mapping(uint256 => mapping(address => bool)) public whitelist;

    event Purchased(
        uint256 indexed eventId,
        address indexed to,
        address indexed nftToken,
        address paymentToken,
        uint256 purchasedAmt,
        uint256 paymentAmt
    );

    event SetEvent(
        uint256 indexed eventId,
        uint256 indexed start,
        uint256 indexed end,
        uint256 maxSaleAmount,
        uint256 maxAllocation
    );

    event SetPrice(
        uint256 indexed eventId,
        address indexed token,
        uint256 indexed price
    );

    modifier onlyManager() {
        require(
            management.hasRole(MANAGER_ROLE, msg.sender), "OnlyManager"
        );
        _;
    }

    modifier checkEvent(uint256 eventId) {
        uint256 _current = block.timestamp;
        uint256 _endTime = events[eventId].end;
        require(
            _endTime != 0 && _current < _endTime && !events[eventId].forcedTerminate,
            "InvalidSetting"
        );
        _;
    }

    constructor(IS7NSManagement _management) {
        management = _management;
        counter = 1;
    }

    /**
        @notice Update a new address of S7NSManagement contract
        @dev  Caller must have MANAGER_ROLE
        @param _management          Address of new Governance contract

        Note: if `_management == 0x00`, this contract is deprecated
    */
    function setManagement(IS7NSManagement _management) external onlyManager {
        management = _management;
    }

    /**
        @notice Set a configuration of one `_eventId`
        @dev  Caller must have MANAGER_ROLE
        @param _eventId             The Event ID number
        @param _start               Starting time of `_eventId`
        @param _end                 Ending time of `_eventId`
        @param _maxAllocation       Max number of items can be purchased (per account) during the `_eventId`
        @param _maxSaleAmount       Max number of items can be purchased during the `_eventId`
        @param _nftToken            Address of NFT Token contract
        @param _isPublic            Public or Private Event
    */
    function setEvent(
        uint256 _eventId,
        uint256 _start,
        uint256 _end,
        uint256 _maxAllocation,
        uint256 _maxSaleAmount,
        address _nftToken,
        bool _isPublic
    ) external onlyManager {
        uint256 _current = block.timestamp;
        require(events[_eventId].end == 0, "EventExist");
        require(_start < _end && _current < _end, "InvalidSetting");

        events[_eventId].start = _start;
        events[_eventId].end = _end;
        events[_eventId].maxAllocation = _maxAllocation;
        events[_eventId].maxSaleAmount = _maxSaleAmount;
        events[_eventId].availableAmount = _maxSaleAmount;
        events[_eventId].isPublic = _isPublic;

        nftTokens[_eventId] = _nftToken;

        emit SetEvent(_eventId, _start, _end, _maxSaleAmount, _maxAllocation);
    }

    /**
        @notice Disable one `_eventId`
        @dev  Caller must have MANAGER_ROLE
        @param _eventId            Number id of an event

        Note: This method allows MANAGER_ROLE disable one event when it was set mistakenly
    */
    function terminate(uint256 _eventId) external onlyManager checkEvent(_eventId) {
        events[_eventId].forcedTerminate = true;
    }

    /**
        @notice Set fixed price (of one payment token) in the `_eventId`
        @dev  Caller must have MANAGER_ROLE
        @param _eventId            Number id of an event
        @param _token              Address of payment token (0x00 for native coin)
        @param _price              Amount to pay in the `_eventId`

        Note: Allow multiple payment tokens during the `_eventId`
    */
    function setPrice(uint256 _eventId, address _token, uint256 _price) external onlyManager checkEvent(_eventId) {
        require(management.paymentTokens(_token), "PaymentNotSupported");

        prices[_eventId][_token] = _price;

        emit SetPrice(_eventId, _token, _price);
    }

    /**
        @notice Add/Remove `_beneficiaries`
        @dev  Caller must have MANAGER_ROLE
        @param _eventId                     Number id of an event
        @param _beneficiaries               A list of `_beneficiaries`
        @param _opt                         Option choice (true = add, false = remove)

        Note: Allow to add/remove Beneficiaries during the Event
    */
    function setWhitelist(uint256 _eventId, address[] calldata _beneficiaries, bool _opt) external onlyManager checkEvent(_eventId) {
        uint256 _len = _beneficiaries.length;
        for(uint256 i; i < _len; i++) {
            if (_opt)
                whitelist[_eventId][_beneficiaries[i]] = true;
            else 
                delete whitelist[_eventId][_beneficiaries[i]];
        }
    }

    /**
        @notice Purchase NFT items during an `eventId`
        @dev  Caller must be in the whitelist of `eventId`
        @param _eventId                 ID number of an event
        @param _paymentToken            Address of payment token (0x00 - Native Coin)
        @param _purchaseAmt             Amount of items to purchase

        Note: 
        - When `halted = true` is set in the S7NSManagement contract, 
            the `S7NSAvatar` will be disable operations that relate to transferring (i.e., transfer, mint, burn)
            Thus, it's not neccessary to add a modifier `isMaintenance()` to this function
    */
    function purchase(
        uint256 _eventId,
        address _paymentToken,
        uint256 _purchaseAmt
    ) external payable {
        address _beneficiary = msg.sender;
        uint256 _paymentAmt = _precheck(_eventId, _paymentToken, _beneficiary, _purchaseAmt);

        //  if `purchasedAmt + _purchaseAmt` exceeds `maxAllocation` -> revert
        //  if `paymentToken` = 0x00 (native coin), check `msg.value = _paymentAmt`
        uint256 _purchasedAmt = purchased[_eventId][_beneficiary] + _purchaseAmt;
        require(_purchasedAmt <= events[_eventId].maxAllocation, "ExceedAllocation");
        if (_paymentToken == address(0))
            require(msg.value == _paymentAmt, "InvalidPaymentAmount");

        events[_eventId].availableAmount -= _purchaseAmt;         //  if `availableAmount` < `_purchaseAmt` -> underflow -> revert
        purchased[_eventId][_beneficiary] = _purchasedAmt;

        _makePayment(_paymentToken, _beneficiary, _paymentAmt);

        //  if `nftToken` not set for `_eventId` yet -> address(0) -> revert
        address _nftToken = nftTokens[_eventId];
        IS7NSAvatar(_nftToken).print(_beneficiary, counter, _purchaseAmt);
        counter += _purchasedAmt;

        emit Purchased(_eventId, _beneficiary, _nftToken, _paymentToken, _purchaseAmt, _paymentAmt);
    }

    function _precheck(
        uint256 _eventId,
        address _paymentToken,
        address _beneficiary,
        uint256 _purchaseAmt
    ) private view returns (uint256 _paymentAmt) {
        uint256 _currentTime = block.timestamp;
        require(!events[_eventId].forcedTerminate, "Terminated");
        require(
            _currentTime >= events[_eventId].start && _currentTime <= events[_eventId].end,
            "NotStartOrEnded"
        );
        if (!events[_eventId].isPublic)
            require(whitelist[_eventId][_beneficiary], "NotInWhitelist");
        
        uint256 _price = prices[_eventId][_paymentToken];
        require(_price != 0, "PaymentNotSupported");
        _paymentAmt = _price * _purchaseAmt;
    }

    function _makePayment(address _token, address _from, uint256 _amount) private {
        address _treasury = management.treasury();
        if (_token == address(0))
            Address.sendValue(payable(_treasury), _amount);
        else
            IERC20(_token).safeTransferFrom(_from, _treasury, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

/**
   @title IS7NSManagement contract
   @dev Provide interfaces that allow interaction to S7NSManagement contract
*/
interface IS7NSManagement {
    function treasury() external view returns (address);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function paymentTokens(address _token) external view returns (bool);
    function halted() external view returns (bool);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IS7NSAvatar {
	
    function nonces(uint256 _tokenId, address _account) external view returns (uint256);

	/**
       	@notice Mint Avatar to `_beneficiary`
       	@dev  Caller must have MINTER_ROLE
		@param	_beneficiary			Address of Beneficiary
		@param	_fromID					Start of TokenID
		@param	_amount					Amount of NFTs to be minted
    */
	function print(address _beneficiary, uint256 _fromID, uint256 _amount) external;
	/**
       	@notice Burn Avatars from `msg.sender`
       	@dev  Caller can be ANY
		@param	_ids				A list of `tokenIds` to be burned
		
		Note: MINTER_ROLE is granted a priviledge to burn NFTs
    */
	function burn(uint256[] calldata _ids) external;
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}