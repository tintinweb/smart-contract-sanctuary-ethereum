/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// $$\      $$\  $$$$$$\  $$$$$$$\                                                                                                                        
// $$ | $\  $$ |$$  __$$\ $$  __$$\                                                                                                                       
// $$ |$$$\ $$ |$$ /  \__|$$ |  $$ |                                                                                                                      
// $$ $$ $$\$$ |$$ |      $$$$$$$  |                                                                                                                      
// $$$$  _$$$$ |$$ |      $$  ____/                                                                                                                       
// $$$  / \$$$ |$$ |  $$\ $$ |                                                                                                                            
// $$  /   \$$ |\$$$$$$$/|$$ |                                                                                                                            
// \__/     \__/ \_____/ |$$ |
//
//
// ░██╗░░░░░░░██╗░█████╗░██████╗░██╗░░░░░██████╗░  ░█████╗░██╗░░░██╗██████╗░  ██████╗░░█████╗░████████╗
// ░██║░░██╗░░██║██╔══██╗██╔══██╗██║░░░░░██╔══██╗  ██╔══██╗██║░░░██║██╔══██╗  ██╔══██╗██╔══██╗╚══██╔══╝
// ░╚██╗████╗██╔╝██║░░██║██████╔╝██║░░░░░██║░░██║  ██║░░╚═╝██║░░░██║██████╔╝  ██████╔╝██║░░██║░░░██║░░░
// ░░████╔═████║░██║░░██║██╔══██╗██║░░░░░██║░░██║  ██║░░██╗██║░░░██║██╔═══╝░  ██╔═══╝░██║░░██║░░░██║░░░
// ░░╚██╔╝░╚██╔╝░╚█████╔╝██║░░██║███████╗██████╔╝  ╚█████╔╝╚██████╔╝██║░░░░░  ██║░░░░░╚█████╔╝░░░██║░░░
// ░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚═╝╚══════╝╚═════╝░  ░╚════╝░░╚═════╝░╚═╝░░░░░  ╚═╝░░░░░░╚════╝░░░░╚═╝░░░
//

// Website: https://www.worldcuppot.io/
// Telegram: https://t.me/worldcuppot
// Twitter: https://twitter.com/worldcuppot
// Roadmap: https://www.worldcuppot.io/#roadmap
// WCPDapp: https://dapp.worldcuppot.io/
//
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


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

// File: BettingV2.sol


pragma solidity ^0.8.13;





contract MasterWCP is Ownable {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    Counters.Counter private _bettingIdCounter;

    address public admin;
    uint256 public bettingFee = 1e4; // 10%

    struct Betting {
        BettingInfo bettingInfo;
        uint256 totalBetsA;
        uint256 totalBetsB;
        uint256 totalBetsDraw;
        uint256 finalBettingAmount;
        uint256 fee;
        uint256 usersCountTeamA;
        uint256 usersCountTeamB;
        uint256 usersCountDraw;
        bool isBetLive;
        bool isBetStart;
        IERC20 token;
    }

    struct BettingInfo {
        string title;
        string description;
        string teamA;
        string teamB;
    }

    enum ResultStatus {
        NotDeclare, // 0
        WinnerA, // 1
        WinnerB, // 2
        Draw, // 3
        Cancel // 4
    }

    mapping(uint256 => Betting) bettingDetails;
    mapping(uint256 => ResultStatus) public resultStatus;

    mapping(address => mapping(uint256 => uint256)) userBets;
    mapping(address => mapping(uint256 => uint8)) userChoice;
    mapping(address => mapping(uint256 => bool)) userClaimed;

    event NewBetting(uint256 indexed id);
    event Bet(uint256 indexed _id, uint256 _team, uint256 _amount);
    event DeclareResult(uint256 indexed id, uint256 indexed choice);
    event Claim(
        uint256 indexed id,
        address indexed user,
        uint256 indexed amount
    );

    modifier isBettingIdexist(uint256 _id) {
        require(
            _id > 0 && _id <= _bettingIdCounter.current(),
            "BettingId does not exist"
        );
        _;
    }

    modifier isBetStart(uint256 _id) {
        Betting memory _bettingDetails = bettingDetails[_id];
        require(_bettingDetails.isBetStart, "Betting not started yet");
        _;
    }

    modifier isBetLive(uint256 _id) {
        Betting memory _bettingDetails = bettingDetails[_id];
        require(_bettingDetails.isBetLive, "Betting not live");
        _;
    }

    modifier notStart(uint256 _id) {
        Betting memory _bettingDetails = bettingDetails[_id];
        require(!(_bettingDetails.isBetStart), "Betting already started");
        _;
    }

    modifier notDeclare(uint256 _id) {
        require(
            resultStatus[_id] == ResultStatus.NotDeclare,
            "result already delcare"
        );
        _;
    }

    modifier minAmount(uint256 _amnt) {
        require(_amnt > 0, "bet value 0");
        _;
    }

    modifier declare(uint256 _id) {
        require(resultStatus[_id] != ResultStatus.NotDeclare, "not delcare");
        _;
    }

    modifier notClaimed(address _user, uint256 _id) {
        require(!userClaimed[_user][_id], "claimed!");
        _;
    }

    constructor(address _admin) {
        admin = _admin;
    }

    function bet(
        uint256 _id,
        uint8 _option,
        uint256 _amount
    )
        external
        isBettingIdexist(_id)
        notDeclare(_id)
        isBetLive(_id)
        minAmount(_amount)
        returns (bool)
    {
        require(_option == 1 || _option == 2 || _option == 3, "bet: invalid choice");
        Betting storage _bettingDetails = bettingDetails[_id];

        address _user = msg.sender;
        uint256 previousBet = userBets[_user][_id];

        if (_option == 1) {
            _bettingDetails.totalBetsA += _amount;
            if (previousBet > 0) {
                require(userChoice[_user][_id] == 1, "bet: wrong choice");
                userBets[_user][_id] += _amount;
            } else {
                userBets[_user][_id] = _amount;
                userChoice[_user][_id] = 1;
                unchecked {
                    _bettingDetails.usersCountTeamA++;
                }
            }
        } else if (_option == 2) {
            _bettingDetails.totalBetsB += _amount;
            if (previousBet > 0) {
                require(userChoice[_user][_id] == 2, "bet: wrong choice");
                userBets[_user][_id] += _amount;
            } else {
                userBets[_user][_id] = _amount;
                userChoice[_user][_id] = 2;
                unchecked {
                    _bettingDetails.usersCountTeamB++;
                }
            }
        } else {
            _bettingDetails.totalBetsDraw += _amount;
            if (previousBet > 0) {
                require(userChoice[_user][_id] == 3, "bet: wrong choice");
                userBets[_user][_id] += _amount;
            } else {
                userBets[_user][_id] = _amount;
                userChoice[_user][_id] = 3;
                unchecked {
                    _bettingDetails.usersCountDraw++;
                }
            }
        }

        emit Bet(_id, _option, _amount);
        _bettingDetails.token.safeTransferFrom(_user, address(this), _amount);
        return true;
    }

    function claim(uint256 _id)
        external
        isBettingIdexist(_id)
        declare(_id)
        notClaimed(msg.sender, _id)
        returns (bool)
    {
        Betting memory _bettingDetails = bettingDetails[_id];
        address _user = msg.sender;
        uint256 claimAmount = getUserClaimAmount(_user, _id);
        userClaimed[_user][_id] = true;
        emit Claim(_id, _user, claimAmount);
        if (claimAmount > 0) {
            _bettingDetails.token.safeTransfer(_user, claimAmount);
        }
        return true;
    }

    function createBetting(
        string calldata _title,
        string calldata _description,
        string calldata _teamA,
        string calldata _teamB,
        IERC20 _token
    ) external onlyOwner returns (bool) {
        _bettingIdCounter.increment();
        uint256 _id = _bettingIdCounter.current();
        Betting storage _bettingDetails = bettingDetails[_id];

        _bettingDetails.bettingInfo.title = _title;
        _bettingDetails.bettingInfo.description = _description;
        _bettingDetails.bettingInfo.teamA = _teamA;
        _bettingDetails.bettingInfo.teamB = _teamB;
        _bettingDetails.token = _token;
        _bettingDetails.fee = bettingFee;
        emit NewBetting(_id);
        return true;
    }

    function declareResult(uint256 _id, ResultStatus _result)
        external
        isBettingIdexist(_id)
        notDeclare(_id)
        onlyOwner
        returns (bool)
    {
        resultStatus[_id] = _result;
        require(_result != ResultStatus.NotDeclare, "declareResult: invalid");
        bettingDetails[_id].isBetLive = false;
        emit DeclareResult(_id, uint256(_result));
        if (_result != ResultStatus.Cancel) {
            Betting memory _bettingDetails = bettingDetails[_id];
            uint256 totalBets = _bettingDetails.totalBetsA +
                _bettingDetails.totalBetsB +
                _bettingDetails.totalBetsDraw;
            uint256 feeAmount = (totalBets * _bettingDetails.fee) / 1e5;
            bettingDetails[_id].finalBettingAmount = totalBets - feeAmount;
            _bettingDetails.token.safeTransfer(admin, feeAmount);
        }
        return true;
    }

    function changeBettingInfo(
        uint256 _id,
        string calldata _title,
        string calldata _description,
        string calldata _teamA,
        string calldata _teamB
    ) external isBettingIdexist(_id) notStart(_id) returns (bool) {
        BettingInfo storage _bettingDetailsInfo = bettingDetails[_id]
            .bettingInfo;
        _bettingDetailsInfo.title = _title;
        _bettingDetailsInfo.description = _description;
        _bettingDetailsInfo.teamA = _teamA;
        _bettingDetailsInfo.teamB = _teamB;
        return true;
    }

    function changeBettingToken(uint256 _id, IERC20 _token)
        external
        isBettingIdexist(_id)
        notStart(_id)
        returns (bool)
    {
        bettingDetails[_id].token = _token;
        return true;
    }

    function changeFee(uint256 _newfee) external onlyOwner returns (bool) {
        bettingFee = _newfee;
        return true;
    }

    function changeAdmin(address _admin) external onlyOwner returns (bool) {
        admin = _admin;
        return true;
    }

    function startBetting(uint256 _id)
        external
        onlyOwner
        isBettingIdexist(_id)
        notDeclare(_id)
        returns (bool)
    {
        bettingDetails[_id].isBetStart = true;
        bettingDetails[_id].isBetLive = true;
        return true;
    }

    function stopBetting(uint256 _id)
        external
        onlyOwner
        isBettingIdexist(_id)
        isBetStart(_id)
        returns (bool)
    {
        bettingDetails[_id].isBetLive = false;
        return true;
    }

    function resumeBetting(uint256 _id)
        external
        onlyOwner
        isBettingIdexist(_id)
        isBetStart(_id)
        notDeclare(_id)
        returns (bool)
    {
        bettingDetails[_id].isBetLive = true;
        return true;
    }

    function isBettingLive(uint256 _id) external view returns (bool) {
        if (_id > _bettingIdCounter.current()) {
            return false;
        }
        return bettingDetails[_id].isBetLive;
    }

    function isBettingStart(uint256 _id) external view returns (bool) {
        if (_id > _bettingIdCounter.current()) {
            return false;
        }
        return bettingDetails[_id].isBetStart;
    }

    function getTotalBettingIds() external view returns (uint256) {
        return _bettingIdCounter.current();
    }

    function getBettingResult(uint256 _id)
        external
        view
        returns (string memory)
    {
        BettingInfo memory _bettingInfo = bettingDetails[_id].bettingInfo;
        string memory prefix = "Winer is ";

        uint256 status = uint256(resultStatus[_id]);
        if (status == 0) {
            return "Not Declared";
        } else if (status == 1) {
            return string(abi.encodePacked(prefix, _bettingInfo.teamA));
        } else if (status == 2) {
            return string(abi.encodePacked(prefix, _bettingInfo.teamB));
        } else if (status == 3) {
            return "Match Draw";
        } else {
            return "Match Cancel";
        }
    }

    function getBettingFullDetails(uint256 _id)
        external
        view
        returns (Betting memory)
    {
        return bettingDetails[_id];
    }

    function getBettingInfo(uint256 _id)
        external
        view
        returns (
            string memory,
            string memory,
            string memory,
            string memory
        )
    {
        BettingInfo memory _bettingInfo = bettingDetails[_id].bettingInfo;
        return (
            _bettingInfo.title,
            _bettingInfo.description,
            _bettingInfo.teamA,
            _bettingInfo.teamB
        );
    }

    function getTotalBets(uint256 _id) external view returns (uint256) {
        Betting memory _bettingDetails = bettingDetails[_id];
        uint256 totalBets = _bettingDetails.totalBetsA +
            _bettingDetails.totalBetsB +
            _bettingDetails.totalBetsDraw;
        return totalBets;
    }

    function getIndividualBets(uint256 _id)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        Betting memory _bettingDetails = bettingDetails[_id];
        return (
            _bettingDetails.totalBetsA,
            _bettingDetails.totalBetsB,
            _bettingDetails.totalBetsDraw
        );
    }

    function getFinalBettingAmount(uint256 _id)
        external
        view
        returns (uint256)
    {
        return bettingDetails[_id].finalBettingAmount;
    }

    function getBettingToken(uint256 _id) external view returns (address) {
        return address(bettingDetails[_id].token);
    }

    function getUsersCount(uint256 _id)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        Betting memory _bettingDetails = bettingDetails[_id];
        return (
            _bettingDetails.usersCountTeamA,
            _bettingDetails.usersCountTeamB,
            _bettingDetails.usersCountDraw
        );
    }

    function getUserBets(address _user, uint256 _id)
        external
        view
        returns (uint256)
    {
        return userBets[_user][_id];
    }

    function getUserChoice(address _user, uint256 _id)
        external
        view
        returns (uint256)
    {
        return userChoice[_user][_id];
    }

    function getUserClaim(address _user, uint256 _id)
        external
        view
        returns (bool)
    {
        return userClaimed[_user][_id];
    }

    function getUserClaimAmount(address _user, uint256 _id)
        public
        view
        returns (uint256)
    {
        Betting memory _bettingDetails = bettingDetails[_id];
        ResultStatus resultstatus = resultStatus[_id];
        uint256 amount = userBets[_user][_id];
        uint8 choice = userChoice[_user][_id];

        if (resultstatus == ResultStatus.NotDeclare) {
            return 0;
        } else if (resultstatus == ResultStatus.Cancel) {
            return amount;
        } else if (resultstatus == ResultStatus.WinnerA) {
            return
                (choice == 1)
                    ? (_bettingDetails.finalBettingAmount * amount) /
                        (_bettingDetails.totalBetsA)
                    : 0;
        } else if (resultstatus == ResultStatus.WinnerB) {
            return
                (choice == 2)
                    ? (_bettingDetails.finalBettingAmount * amount) /
                        (_bettingDetails.totalBetsB)
                    : 0;
        } else {
            return
                (choice == 3)
                    ? (_bettingDetails.finalBettingAmount * amount) /
                        (_bettingDetails.totalBetsDraw)
                    : 0;
        }
    }
}