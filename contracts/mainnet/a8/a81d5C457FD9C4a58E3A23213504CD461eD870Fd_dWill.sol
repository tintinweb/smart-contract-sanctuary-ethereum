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
pragma solidity 0.8.17;

import './Interfaces/IHeritage.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract dWill is IHeritage, Ownable{
    using SafeERC20 for IERC20;

    ///@notice Stores all will/inheritance data.
    /// For clarity we use "will" to refer to wills created by owner and "inheritance" to refer to inheritance intended for heir,
    /// however "will" and "inheritance" refer to the same data types.
    WillData[] public willData;
    
    ///@notice The IDs of wills made by a person.
    mapping(address => uint256[]) public ownerWills;
    ///@notice Index where given ID is in ownerWills[owner] array. It is independent of owner because each will can have only one owner.
    mapping(uint256 => uint256) private indexOfOwnerWillsId;
    ///@notice Owner's token amounts in all their wills. Used to check if owner has enough allowance for new will/to increase will amount.
    mapping(address => mapping(IERC20 => uint256)) public willAmountForToken;

    ///@notice The IDs of inheritances intended for a person.
    mapping(address => uint256[]) public heirInheritances;
    ///@notice Index where given ID is in heirInheritances[heir] array. It is independent of heir because each inheritance can have only one heir.
    mapping(uint256 => uint256) private indexOfHeirInheritanceId;

    ///@notice Address the fees are sent to.
    address public feeCollector;
    ///@notice Fee amount collected from each withdrawal. Can be in range from 0% to 5%. [10^18 == 100%].
    uint256 public fee;

    constructor(address _feeCollector, uint256 _fee) {  
      _setFeeCollector(_feeCollector);
      _setFee(_fee);
   }

    /**
     * @notice Create the will will provided parameters. Checks if owner has enough allowance and calculates and 
        calculates time interval for future use in resetTimers(). Emits AddWill event.
     * @param heir - Address to whom the tokens are inherited to.
     * @param token - Token to use in will.
     * @param withdrawalTime - Time when the heir will be able to withdraw tokens.
     * @param amount - Amount of tokens to send.
     *
     * @return ID - Id of the created will
    **/
    function addWill(
        address heir,
        IERC20 token,
        uint256 withdrawalTime,
        uint256 amount
    ) external returns (uint256 ID){
        require(heir != address(0), "dWill: Heir is address(0)");
        require(address(token) != address(0), "dWill: Token is address(0)");
        require(withdrawalTime > block.timestamp, "dWill: Withdrawal time has already expired");
        require(amount != 0, "dWill: Amount is 0");

        uint256 allowance = token.allowance(msg.sender, address(this));
        unchecked {
            willAmountForToken[msg.sender][token] += amount;
            require(willAmountForToken[msg.sender][token] >= amount, "dWill: Total will for token is more than max uint256");
        }
        require(allowance >= willAmountForToken[msg.sender][token], 'dWill: Not enough allowance');
       
        ID = willData.length;
        WillData memory _data = WillData({
            ID: ID,
            owner: msg.sender,
            heir: heir,
            token: token,
            creationTime: block.timestamp,
            withdrawalTime: withdrawalTime,
            timeInterval: withdrawalTime - block.timestamp,
            amount: amount,
            fee: fee, // We save fees at the moment of will creation to not have centralization with variable fees.
            done: false
        });
        willData.push(_data);

        // We write indexes of ID in ownerWills/heirInheritances arrays to the mappings to get rid of for-loops later.
        indexOfOwnerWillsId[ID] = ownerWills[msg.sender].length;
        indexOfHeirInheritanceId[ID] = heirInheritances[heir].length;

        ownerWills[msg.sender].push(ID);
        heirInheritances[heir].push(ID);

        emit AddWill(ID, msg.sender, heir, token, withdrawalTime, amount);
    }

    /**
     * @notice Reset timers for all sender's wills depending on calculated timeInterval. Emits UpdateWithdrawalTime events.
     * @param IDs - IDs of wills to reset timers for.
     * @custom:example If heritage was created on 25.02.2040 and the timeInterval is 10 years
     * @custom:example then the withdrawal time is 25.02.2050,
     * @custom:example but if in 25.02.2041 the resetTimers is called
     * @custom:example withdrawal time will be 25.02.2051 (25.02.2041 + timeInterval)
    **/
    function resetTimers(uint256[] memory IDs) external {
        for (uint256 i; i < IDs.length; i++) {
            WillData storage _data = willData[IDs[i]];
            _checkWillAvailability(_data);

            uint256 _withdrawalTime = _data.timeInterval + block.timestamp;
            emit UpdateWithdrawalTime(IDs[i], _data.withdrawalTime, _withdrawalTime);
            _data.withdrawalTime = _withdrawalTime;
        }
    }

    /**
     * @notice Update time when heir can withdraw their tokens and timeInterval. Emits UpdateWithdrawalTime event.
     * @param ID - ID of will to update.
     * @param _withdrawalTime - New withdrawal time.
    **/
    function updateWithdrawalTime(uint256 ID, uint256 _withdrawalTime) public {
        WillData storage _data = willData[ID];
        _checkWillAvailability(_data);
        require(_withdrawalTime > _data.creationTime, "dWill: Withdrawal time has already expired");

        emit UpdateWithdrawalTime(ID, _data.withdrawalTime, _withdrawalTime);
        _data.withdrawalTime = _withdrawalTime;
        _data.timeInterval = _withdrawalTime - _data.creationTime;
    }

    /**
     * @notice Sets new heir to the will. Emits UpdateHeir event.
     * @param ID - Id of the will to update.
     * @param _heir - New heir of the will.
    **/
    function updateHeir(uint256 ID, address _heir) public {
        WillData storage _data = willData[ID];
        _checkWillAvailability(_data);
        require(_data.heir != _heir, "dWill: New heir is the same");
        require(_heir != address(0), "dWill: Heir is address(0)");

        uint256[] storage _heirInheritances = heirInheritances[_data.heir];

        uint256 i = indexOfHeirInheritanceId[ID];
        uint256 _length = _heirInheritances.length - 1;
        if(i != _length){
            _heirInheritances[i] = _heirInheritances[_length];
            indexOfHeirInheritanceId[_heirInheritances[i]] = i;
        }
        _heirInheritances.pop();

        indexOfHeirInheritanceId[ID] = heirInheritances[_heir].length;
        heirInheritances[_heir].push(ID);

        emit UpdateHeir(ID, _data.heir, _heir);
        _data.heir = _heir;
    }

    /**
     * @notice Set new amount to the will. Checks if owner has enough allowance. Emits UpdateAmount event.
     * @param ID - Id of the will to update.
     * @param _amount - New amount of the will.
    **/
    function updateAmount(uint256 ID, uint256 _amount) public {
        WillData storage _data = willData[ID];
        _checkWillAvailability(_data);
        
        uint256 allowance = _data.token.allowance(_data.owner, address(this));

        unchecked {
            willAmountForToken[_data.owner][_data.token] = willAmountForToken[_data.owner][_data.token] - _data.amount + _amount;
            if(_amount > _data.amount){// If increased
                require(willAmountForToken[_data.owner][_data.token] >= _amount - _data.amount, "dWill: Total will for token is more than max uint256");
            }
        }
        require(allowance >= willAmountForToken[_data.owner][_data.token], 'dWill: Not enough allowance');

        emit UpdateAmount(ID, _data.amount, _amount);
        _data.amount = _amount;
    }

    /**
     * @notice Batch update will values.
     * @param ID - Id of the inheritwillance to update.
     * @param _withdrawalTime - New will withdrawal time.
     * @param _heir - New heir of the will.
     * @param _amount - New amount of the will.
    **/
    function update(
        uint256 ID, 
        uint256 _withdrawalTime, 
        address _heir, 
        uint256 _amount
    ) external {
        WillData memory _data = willData[ID];
        if(_withdrawalTime != _data.withdrawalTime){
            updateWithdrawalTime(ID, _withdrawalTime);
        }
        if (_heir != _data.heir) {
            updateHeir(ID, _heir);
        }
        if (_amount != _data.amount) {
            updateAmount(ID, _amount);
        }
    }

    /**
     * @notice Remove will from storage. Emits UpdaRemoveWillteHeir event.
     * @param ID - Id of the will to remove.
    **/
    function removeWill(uint256 ID) external {
        WillData memory _data = willData[ID];
        _checkWillAvailability(_data);

        uint256[] storage _ownerWills = ownerWills[_data.owner];
        uint256 i = indexOfOwnerWillsId[ID];
        uint256 _length = _ownerWills.length - 1;
        if(i != _length){
            _ownerWills[i] = _ownerWills[_length];
            indexOfOwnerWillsId[_ownerWills[i]] = i;
        }
        _ownerWills.pop();

        uint256[] storage _heirInheritances = heirInheritances[_data.heir];
        i = indexOfHeirInheritanceId[ID];
        _length = _heirInheritances.length - 1;
        if(i != _length){
            _heirInheritances[i] = _heirInheritances[_length];
            indexOfHeirInheritanceId[_heirInheritances[i]] = i;
        }
        _heirInheritances.pop();

        delete willData[ID];
        willAmountForToken[_data.owner][_data.token] -= _data.amount;
        emit RemoveWill(ID, _data.owner, _data.heir);
    }

    /**
     * @notice Withdraw tokens to heir. Emits Withdraw event.
     * @param ID - Id of the inheritance to withdraw.
     *
     * @return amount - Amount withdrawn.
    **/
    function withdraw(uint256 ID) external returns(uint256 amount){
        WillData storage _data = willData[ID];
        require(block.timestamp >= _data.withdrawalTime, "dWill: Withdrawal is not yet available");
        require(msg.sender == _data.heir, "dWill: Caller is not the heir");
        require(_data.done == false, "dWill: Already withdrawn");

        _data.done = true;
        uint256[] storage _ownerWills = ownerWills[_data.owner];
        uint256 i = indexOfOwnerWillsId[ID];
        uint256 _length = _ownerWills.length - 1;
        if(i != _length){
            _ownerWills[i] = _ownerWills[_length];
            indexOfOwnerWillsId[_ownerWills[i]] = i;
        }
        _ownerWills.pop();

        uint256[] storage _heirInheritances = heirInheritances[_data.heir];
        i = indexOfHeirInheritanceId[ID];
        _length = _heirInheritances.length - 1;
        if(i != _length){
            _heirInheritances[i] = _heirInheritances[_length];
            indexOfHeirInheritanceId[_heirInheritances[i]] = i;
        }
        _heirInheritances.pop();

        uint256 balance = _data.token.balanceOf(_data.owner);
        uint256 allowance = _data.token.allowance(_data.owner, address(this));
        amount = _data.amount;
        if (balance < amount) {
            amount = balance;
        } 
        if (allowance < amount) {
            amount = allowance;
        }
        willAmountForToken[_data.owner][_data.token] -= amount;

        uint256 feeAmount = amount * _data.fee / 1 ether;
        if(feeAmount > 0){
            _data.token.safeTransferFrom(_data.owner, feeCollector, feeAmount);
            emit CollectFee(ID, _data.token, feeAmount);

            amount -= feeAmount;
        }
        _data.token.safeTransferFrom(_data.owner, _data.heir, amount);

        emit Withdraw(ID, _data.owner, _data.heir, _data.token, block.timestamp, amount);
    }

    /**
     * @notice Returns owner's will at index.
     * @param owner - Owner of the will.
     * @param index - Index of the will in ownerWills to return.
     *
     * @return will - Info on will.
    **/
    function getWill(address owner, uint256 index) external view returns(WillData memory will) {
        uint256[] memory _ownerWills = ownerWills[owner];
        require(index < _ownerWills.length, "dWill: Index must be lower _heirInheritances.length");

        will = willData[_ownerWills[index]];
    }

    /**
     * @notice Returns user's inheritance  at index.
     * @param heir - Heir of the inheritance.
     * @param index - Index of the inheritance in heirInheritances to return.
     *
     * @return inheritance - Info on inheritance.
    **/
    function getInheritance(address heir, uint256 index) external view returns(WillData memory inheritance) {
        uint256[] memory _heirInheritances = heirInheritances[heir];
        require(index < _heirInheritances.length, "dWill: Index must be lower _heirInheritances.length");

        inheritance = willData[_heirInheritances[index]];
    }

    function getWillsLength(address owner) external view returns(uint256 _length) {
        _length = ownerWills[owner].length;
    }

    function getInheritancesLength(address heir) external view returns(uint256 _length) {
        _length = heirInheritances[heir].length;
    }

    function _checkWillAvailability(WillData memory _data) internal view {
        require(_data.owner == msg.sender, "dWill: Caller is not the owner");
        require(_data.done == false, "dWill: Already withdrawn");
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        _setFeeCollector(_feeCollector);
    }

    function setFee(uint256 _fee) external onlyOwner {
        _setFee(_fee);
    }

    function _setFeeCollector(address _feeCollector) internal {
        require (_feeCollector != address(0), "dWill: Can't set feeCollector to address(0)");

        emit SetFeeCollector(feeCollector, _feeCollector);
        feeCollector = _feeCollector;
    }

    function _setFee(uint256 _fee) internal {
        require (_fee <= 50000000000000000, "dWill: Fee must be lower or equal 5%");

        emit SetFee(fee, _fee);
        fee = _fee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IHeritage {

    struct WillData {
        uint256 ID;
        address owner;
        address heir;
        IERC20 token; 
        uint256 creationTime;
        uint256 withdrawalTime;
        uint256 timeInterval;
        uint256 amount;
        uint256 fee;
        bool done;
    }
    
    event AddWill(
        uint256 indexed ID,
        address indexed owner,
        address indexed heir,
        IERC20 token,
        uint256 withdrawalTime, 
        uint256 amount
    );

    event UpdateWithdrawalTime(
        uint256 indexed ID,
        uint256 oldWithdrawalTime,
        uint256 newWithdrawalTime
    );

    event UpdateHeir(
        uint256 indexed ID,
        address indexed oldHeir,
        address indexed newHeir
    );

    event UpdateAmount(
        uint256 indexed ID,
        uint256 oldAmount,
        uint256 newAmount
    );

    event RemoveWill(
        uint256 indexed ID,
        address indexed owner,
        address indexed heir
    );

    event Withdraw(
        uint256 indexed ID, 
        address indexed owner, 
        address indexed heir, 
        IERC20 token,
        uint256 time,
        uint256 amount
    );

    event CollectFee(
        uint256 indexed ID, 
        IERC20 indexed token,
        uint256 amount
    );

    event SetFeeCollector(
        address indexed oldFeeCollector,
        address indexed newFeeCollector
    );

    event SetFee(
        uint256 oldFee,
        uint256 newFee
    );
}