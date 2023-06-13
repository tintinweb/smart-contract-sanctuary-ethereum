/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: GAIN.sol



pragma solidity 0.8.19;




/**
 * @title Interface for Auium Protocol's ERC20 token.
 */
interface IAuriumToken {
    function mint(uint256) external;

    function transfer(address, uint256) external returns (bool);

    function balanceOf(address) external view returns (uint256);
}

/**
 * @title Contract that manages the entire GODL network for GODL token/
 * @notice This contract performs the entire logic of GODL Network including user registration, reward distribution / reinvestment and reward tier level management.
 */
contract GodlAmbassadorInfluencerNetwork is
    Pausable,
    Ownable
{
    using SafeERC20 for IERC20;

    // PAXG token contract address.
    IERC20 private paxgToken_;
    // GODL token contract address.
    IAuriumToken private godlToken_;
    // Contract deployer wallet address.
    address private deployer_;
    // List of addresses that are in the top-line.
    address[] private toplineList_;
    // Total number of users in the GODL network, including the top-line.
    uint256 private totalUsers_;
    // Fee receiver address where join fee is sent at the time of registration.
    address private feeReceiver_;

    // ----- START: GODL Network Reward Configuration ----- //

    // Maximum referral levels that constitute any user's downline in the GODL network.
    uint256 private constant MAX_REFERRAL_LEVEL = 5;
    // Total PAXG rewards generated till date. This includes both, distributed and re-invested ones.
    uint256 private totalRewardsGenerated_;
    // Total PAXG rewardsre-invested for auto-purchase till date.
    uint256 private totalRewardsReinvested_;
    // Reward percentages for every downline. For example, first downline (0th index) gives 5% as rewards (in PAXG).
    uint256[] private rewardPercents_;
    // Reward tier package cost for all the five levels.
    uint256[] private rewardTierCosts_;
    // Reward Percents in 2D for reward calculations.
    uint256[][] private rewardPercentsIn2D_;

    // ----- END: GODL Network Reward Configuration ----- //

    struct User {
        uint256 uniqueId; // User's unique id that is used for network links.
        uint256 referrer; // The referrer's uniqueId. Zero in case of top-line.
        uint256 level; // Current reward tier level.
        bool reinvestFlag; // User can opt-in for re-investment which enables user's next reward tier auto-purchase mode.
        mapping(uint256 => uint256) referralCount; // No. of referrals at a given level.
        mapping(uint256 => uint256[]) referrals; // Referral ids at a given level.
        uint256 totalRewards; // Total PAXG rewards till date.
        uint256 rewardBalance; // User's PAXG rewards that are kept in the contract for auto-purchase of the next reward tier.
        uint256 registrationTime; // Time when user registered the GODL network.
    }

    // User's id to wallet address to store all the wallet addresses that have joined the GODL Network.
    mapping(uint256 => address) private idToWalletAddress;
    // User's wallet address to User struct mapping.
    mapping(address => User) private user;
    // User's wallet address to boolean true / false that maps status for the user being in top-line.
    mapping(address => bool) private isInTopline;
    // User's wallet address to index of "toplineList_" array
    mapping(address => uint256) private addressToToplineIndex;

    event NewToplineAddress(uint256 indexed newToplineCount); // UA: Do something here with names and what to emit?
    event NewUser(
        address indexed user,
        address indexed referrer,
        uint256 registrationTime
    );
    event Reward(
        address indexed user,
        address indexed referrer,
        uint256 amount
    );
    event LevelUp(address indexed user, uint256 level);
    event SetAutoPurchase(address indexed user, bool autoPurchase);
    event UpdateWalletAddress(
        address indexed oldWalletAddress,
        address indexed newWalletAddress
    );
    event UpdateFeeReceiver(
        address indexed oldFeeReceiver,
        address indexed newFeeReceiver
    );

    /**
     * @notice Function to initialize the contract.
     * @dev Contract uses OpenZeppelin's Initializable.sol to deploy upgradeable contracts.
     * @param _paxgToken : PAXG token contract address.
     * @param _godlToken: GODL token contract address.
     */
    constructor(address _paxgToken, address _godlToken) {
        require(
            _paxgToken != address(0),
            "Initialize: PAXG token cannot be zero address."
        );
        require(
            _godlToken != address(0),
            "Initialize: GODL token cannot be zero address."
        );

        paxgToken_ = IERC20(_paxgToken);
        godlToken_ = IAuriumToken(_godlToken);
        deployer_ = _msgSender();

        rewardPercents_ = [5, 4, 3, 2, 1];
        rewardTierCosts_ = [
            10000000000000000, // 0.01 PAXG
            25000000000000000, // 0.025 PAXG
            50000000000000000, // 0.05 PAXG
            100000000000000000, // 0.1 PAXG
            500000000000000000 // 0.5 PAXG
        ];
        rewardPercentsIn2D_ = [
            [5, 0, 0, 0, 0],
            [5, 4, 0, 0, 0],
            [5, 4, 3, 0, 0],
            [5, 4, 3, 2, 0],
            [5, 4, 3, 2, 1]
        ];
    }

    /**
     * @notice Function to join the GODL network.
     * @dev User joining, reward distribution in uplines and auto-purchase, all the three happens in this function.
     * @param _referrer : Referrer address that the user wishes to join with.
     * @param _level : Reward tier level that the user wishes to purchase.
     */
    function join(address _referrer, uint256 _level) public whenNotPaused {
        // Check that the _msgSender() is an EOA.

        // Check if user is already in the network.
        require(
            !isExistingUser(_msgSender()),
            "join : Sender is already a user in the GODL network."
        );

        // Only topline addresses can join the GODL network without any referrer address
        if (_referrer == address(0)) {
            require(
                isInTopline[_msgSender()],
                "join : Referrer address is invalid or the sender is not among the topline."
            );
            user[_msgSender()].referrer = 0;
        } else {
            // If referrer address is a valid ethereum address, this address must exist in the GODL network.
            require(
                isExistingUser(_referrer),
                "join : Referrer address does not exist in the network."
            );
            user[_msgSender()].referrer = user[_referrer].uniqueId;
        }

        // Tier level has to be between 1 and 5.
        require(
            _level > 0 && _level <= MAX_REFERRAL_LEVEL,
            "join : Invalid level."
        );

        // Update users data
        totalUsers_++;
        idToWalletAddress[totalUsers_] = _msgSender();

        // Sender struct is created here and is initialized with the referrer address and joining timestamp
        user[_msgSender()].uniqueId = totalUsers_;
        user[_msgSender()].registrationTime = block.timestamp;

        // Add referral user to the referrer's referral list
        if (!isInTopline[_msgSender()]) {
            uint256 i = 1;
            uint256 uplineCount = 1;
            address[] memory uplineUsers = new address[](5);
            uplineUsers[0] = _referrer;

            while (i < 5) {
                User storage userStruct = user[uplineUsers[i - 1]];
                if (userStruct.referrer != 0) {
                    uplineCount++;
                    uplineUsers[i] = idToWalletAddress[userStruct.referrer];
                } else {
                    break;
                }
                i++;
            }

            for (uint256 j = 0; j < uplineCount; j++) {
                User storage userStruct = user[uplineUsers[j]];
                userStruct.referralCount[j + 1]++;
                userStruct.referrals[j + 1].push(user[_msgSender()].uniqueId);
            }
        }

        buyLevelFor(_msgSender(), _level);

        emit NewUser(_msgSender(), _referrer, block.timestamp);
    }

    /**
     * @notice Function to buy / upgrade reward-tier package
     * @dev This function can be used to buy / upgrade the current level for any given user
     * @param _for : User address whose package level will be upgraded
     * @param _level : Level that user wish to upgrade
     */
    function buyLevelFor(address _for, uint256 _level) public whenNotPaused {
        require(_for != address(0), "buyLevelFor : Invalid address.");
        require(
            _level > 0 && _level <= MAX_REFERRAL_LEVEL,
            "buyLevelFor : Invalid level."
        );
        require(
            isExistingUser(_msgSender()),
            "buyLevelFor : Sender has not yet joined the GODL network."
        );
        require(
            user[_for].level < _level,
            "buyLevelFor : User current level is already equal or higher than the given level."
        );

        uint256 initialPaxgBalance = paxgToken_.balanceOf(address(this));
        uint256 rewardTierCost = getRewardTierCost(user[_for].level, _level);
        paxgToken_.safeTransferFrom(
            _msgSender(),
            address(this),
            rewardTierCost
        );

        uint256 paxgReceived = paxgToken_.balanceOf(address(this)) -
            initialPaxgBalance;

        // 1% to fee receiver
        uint256 paxgSentToFeeReceiver = rewardTierCost / 100;

        // distribute rewards
        (
            uint256 totalRewardDistributed,
            uint256 remainingRewardPercent
        ) = _distributeRewards(_msgSender(), rewardTierCost);

        // rest goes to fee receiver
        paxgSentToFeeReceiver +=
            (rewardTierCost * remainingRewardPercent) /
            100;

        paxgToken_.safeTransfer(feeReceiver_, paxgSentToFeeReceiver);

        uint256 paxgAmtToMintGodl = paxgReceived -
            totalRewardDistributed -
            paxgSentToFeeReceiver;

        _mintGodl(_msgSender(), paxgAmtToMintGodl);

        user[_for].level = _level;

        emit LevelUp(_for, _level);
    }

    /**
     * @notice Function to update the reward tier auto-purchase package feature on / off.
     * @param _reinvestFlag : Boolean true / false to set the auto-purchase on / off.
     */
    function setAutoPurchase(bool _reinvestFlag) public whenNotPaused {
        require(
            isExistingUser(_msgSender()),
            "setAutoPurchase : User has not yet joined the GODL network."
        );

        if (user[_msgSender()].rewardBalance > 0) {
            paxgToken_.safeTransfer(
                _msgSender(),
                user[_msgSender()].rewardBalance
            );
        }

        user[_msgSender()].reinvestFlag = _reinvestFlag;

        emit SetAutoPurchase(_msgSender(), _reinvestFlag);
    }

    /**
     * @notice Function to update the wallet addresses, in case user wish to change the existing one.
     * @dev Wallet address is mapped with a unique id. Updating this mapping will reflect the change in
     * the entire network graph of the given wallet address.
     * @param _newWalletAddress : New wallet address to replace the old one.
     */
    function updateWalletAddress(address _newWalletAddress)
        public
        whenNotPaused
    {
        require(
            isExistingUser(_msgSender()),
            "updateWalletAddress : The given sender does not exist in the GODL Network."
        );
        require(
            _newWalletAddress != address(0),
            "updateWalletAddress : New wallet address cannot be the zero address."
        );
        require(
            !isExistingUser(_newWalletAddress),
            "updateWalletAddress: New wallet address cannot be an existing user in the GODL Network."
        );

        if (user[_msgSender()].rewardBalance > 0) {
            paxgToken_.safeTransfer(
                _msgSender(),
                user[_msgSender()].rewardBalance
            );
        }

        uint256 uniqueId = user[_msgSender()].uniqueId;
        idToWalletAddress[uniqueId] = _newWalletAddress;

        // Initialize a new mapping with the _neWalletAddress
        user[_newWalletAddress].uniqueId = uniqueId;
        user[_newWalletAddress].referrer = user[_msgSender()].referrer;
        user[_newWalletAddress].level = user[_msgSender()].level;
        user[_newWalletAddress].reinvestFlag = user[_msgSender()].reinvestFlag;
        for (uint256 i = 0; i < 5; i++) {
            user[_newWalletAddress].referralCount[i] = user[_msgSender()]
                .referralCount[i];
            user[_newWalletAddress].referrals[i] = user[_msgSender()].referrals[
                i
            ];
        }
        user[_newWalletAddress].totalRewards = user[_msgSender()].totalRewards;
        user[_newWalletAddress].rewardBalance = 0;
        user[_newWalletAddress].registrationTime = user[_msgSender()]
            .registrationTime;

        // Clear the old mapping
        user[_msgSender()].uniqueId = 0;
        user[_msgSender()].referrer = 0;
        user[_msgSender()].level = 0;
        user[_msgSender()].reinvestFlag = false;
        for (uint256 i = 0; i < 5; i++) {
            user[_msgSender()].referralCount[i] = 0;
            user[_msgSender()].referrals[i] = new uint256[](0);
        }
        user[_msgSender()].totalRewards = 0;
        user[_msgSender()].rewardBalance = 0;
        user[_msgSender()].registrationTime = 0;

        // If in topline, remove the old address and add the new one.
        if (isInTopline[_msgSender()]) {
            isInTopline[_msgSender()] = false;
            isInTopline[_newWalletAddress] = true;

            // fetch the array index and replace the old address with the new one.
            uint256 toplineIndex = addressToToplineIndex[_msgSender()];
            toplineList_[toplineIndex - 1] = _newWalletAddress;
        }

        emit UpdateWalletAddress(_msgSender(), _newWalletAddress);
    }

    /**
     * @dev This function performs the entire logic of PAXG reward distribution during user joining process and is responsible
     * for upgrading reward tier packages for users that have their auto-purchase mode on.
     * @param _user : User address that is in the process of joining the GODL network.
     * @param _amount : Amount of PAXG to distribute in rewards.
     */
    function _distributeRewards(address _user, uint256 _amount)
        internal
        returns (uint256 totalRewardDistributed, uint256 remainingRewardPercent)
    {
        require(
            _user != address(0),
            "_distributeRewards : Invalid user address."
        );
        require(
            _amount > 0,
            "_distributeRewards : Amount must be greater than zero."
        );
        address currentReferrer = idToWalletAddress[user[_user].referrer];
        remainingRewardPercent = 15;

        for (uint256 i = 0; i < MAX_REFERRAL_LEVEL; i++) {
            if (currentReferrer == address(0)) {
                break;
            }

            if (user[currentReferrer].level - 1 < rewardPercentsIn2D_.length) {
                uint256 bonusPercentage = rewardPercentsIn2D_[
                    user[currentReferrer].level - 1
                ][i];
                uint256 reward = (_amount * bonusPercentage) / 100;

                if (reward > 0) {
                    if (user[currentReferrer].reinvestFlag) {
                        user[currentReferrer].rewardBalance += reward;
                        totalRewardsReinvested_ += reward;

                        // Check here if the temporaryBalance exceeds or matches the desired amount of next tier/level purchase.
                        // If yes, buy the next tier for this referrer.
                        if (
                            user[currentReferrer].level < 5 &&
                            user[currentReferrer].rewardBalance >=
                            getRewardTierCost(
                                user[currentReferrer].level,
                                (user[currentReferrer].level + 1)
                            )
                        ) {
                            buyLevelFor(
                                currentReferrer,
                                (user[currentReferrer].level + 1)
                            );
                        }
                    } else {
                        paxgToken_.safeTransfer(currentReferrer, reward);
                    }
                    user[currentReferrer].totalRewards += reward;
                    totalRewardsGenerated_ += reward;
                    totalRewardDistributed += reward;
                    emit Reward(_user, currentReferrer, reward);

                    remainingRewardPercent =
                        remainingRewardPercent -
                        (MAX_REFERRAL_LEVEL - i);
                }
            }

            currentReferrer = idToWalletAddress[user[currentReferrer].referrer];
        }
    }

    /**
     * @dev This function handles the minting of GODL token using the Aurium protocol.
     * @param _to : User address that will receive the newly minted GODL tokens.
     * @param _paxgAmount : PAXG amount that is transferred to the GODL token contract to mint the GODL token with the intrinsic value the contract holds.
     */
    function _mintGodl(address _to, uint256 _paxgAmount)
        internal
        whenNotPaused
    {
        // Before balance of GODL
        uint256 initialBalance = godlToken_.balanceOf(address(this));

        // approve PAXG for address(this)
        paxgToken_.approve(address(godlToken_), _paxgAmount);

        // Mint GODL tokens for the user.
        godlToken_.mint(_paxgAmount);

        // After balance of GODL
        uint256 afterBalance = godlToken_.balanceOf(address(this));

        // Use the transfer function of the GODL contract to trigger the deflationary mechanism.
        godlToken_.transfer(_to, (afterBalance - initialBalance));
    }

    // ---------- START: Owner Functions ---------- //

    /**
     * @notice Function to add addresses that will constitute the topline.
     * @dev toplineList_ will hold all the user addresses that will be the root level of the network.
     * @param _toplineList : An array of addresses to add in the toplineList_.
     */
    function addUserInTopline(address[] memory _toplineList) public onlyOwner {
        require(
            _toplineList.length <= 20,
            "addUserInTopline: Topline list must not exceed 20 addresses."
        );

        for (uint256 i = 0; i < _toplineList.length; i++) {
            // Require if the given address already address in the topline.
            require(
                !isInTopline[_toplineList[i]],
                "addUserInTopline: Given user is already added in the topline."
            );
            // Require if the given address has already joined the network.
            require(
                !isExistingUser(_toplineList[i]),
                "addUserInTopline: Given user has already joined the network."
            );

            toplineList_.push(_toplineList[i]);
            isInTopline[_toplineList[i]] = true;
            addressToToplineIndex[_msgSender()] = toplineList_.length;
        }

        emit NewToplineAddress(_toplineList.length);
    }

    /**
     * @notice Function to update feeReceiver.
     * @param feeReceiver : New fee receiver address.
     */
    function setFeeReceiver(address feeReceiver) public onlyOwner {
        address oldFeeReceiver = feeReceiver_;
        feeReceiver_ = feeReceiver;

        emit UpdateFeeReceiver(oldFeeReceiver, feeReceiver_);
    }

    /**
     * @notice Function to pause the GODL Network contract.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Function to unpasue the GODL Network contract.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    // ---------- END: Owner Functions ---------- //

    // ---------- START: Getter Functions ---------- //

    /**
     * @notice Function to get the PAXG token contract address.
     * @dev PAXG token is set during the time of initialization and is never changed during the course of this contract's life.
     * @return paxgToken : PAXG token address.
     */
    function getPaxgToken() public view returns (address paxgToken) {
        return address(paxgToken_);
    }

    /**
     * @notice Function to get the GODL token contract address.
     * @dev GODL token is set during the time of initialization and is never changed during the course of this contract's life.
     * @return godlToken : GODL token address.
     */
    function getGodlToken() public view returns (address godlToken) {
        return address(godlToken_);
    }

    /**
     * @notice Function to get the contract deployer's wallet address.
     * @dev Deployer address is set during the time of initialization.
     * @return deployer : Deployer's wallet address.
     */
    function getDeployerAddress() public view returns (address deployer) {
        return deployer_;
    }

    /**
     * @notice Function to get the total number of user that constitue the topline of the network tree.
     * @return toplineCount : Topline count.
     */
    function getToplineCount() public view returns (uint256 toplineCount) {
        return toplineList_.length;
    }

    /**
     * @notice Function to get the user's wallet address that are in the topline.
     * @param _index : Index of the topline address array.
     * @return  toplineUserAddress : Topline user's wallet address.
     */
    function getToplineUserAddress(uint256 _index)
        public
        view
        returns (address toplineUserAddress)
    {
        require(
            _index < getToplineCount(),
            "getToplineUserAddress: Invalid index. It must be less than the total topline count."
        );

        return toplineList_[_index];
    }

    /**
     * @notice Function to check if a given user address is in the network topline or not.
     * @param _userAddress: User's Ethereum wallet address.
     * @return inTopline : Boolean true / false if the user really is in the topline.
     */
    function checkIfUserIsInTopline(address _userAddress)
        public
        view
        returns (bool inTopline)
    {
        return isInTopline[_userAddress];
    }

    /**
     * @notice Function to get the topline index of a given wallet address.
     * @dev The index is incremented by one. To use it, decrease the retrun value by one.
     * @return toplineIndex : Topline index of the given wallet address.
     */
    function getToplineIndexByAddress(address _userAddress)
        public
        view
        returns (uint256 toplineIndex)
    {
        return addressToToplineIndex[_userAddress];
    }

    /**
     * @notice Funciton to get the total number of users in the GODL network, including the top-line.
     * @return totalUsers : Total user count.
     */
    function getTotalUsers() public view returns (uint256 totalUsers) {
        return totalUsers_;
    }

    /**
     * @notice Function to get the fee receiver address.
     * @return feeReceiver : Fee receiver address.
     */
    function getFeeReceiver() public view returns (address feeReceiver) {
        return feeReceiver_;
    }

    /**
     * @notice Function to get the maximum reward tier levels for the GODL Network.
     * @return maxTierLevels : Max reward tier levels.
     */
    function getMaxRewardTierLevels()
        public
        pure
        returns (uint256 maxTierLevels)
    {
        return MAX_REFERRAL_LEVEL;
    }

    /**
     * @notice Function to get the total PAXG rewards that have been generated so far.
     * @return totalRewardsGenerated : Total PAXG rewards generated so far.
     */
    function getTotalRewardsGenerated()
        public
        view
        returns (uint256 totalRewardsGenerated)
    {
        return totalRewardsGenerated_;
    }

    /**
     * @notice Function to get the total PAXG rewards that have been re-invested so far.
     * @return totalRewardsReinvested : Total PAXG rewards re-invested so far.
     */
    function getTotalRewardsReinvested()
        public
        view
        returns (uint256 totalRewardsReinvested)
    {
        return totalRewardsReinvested_;
    }

    /**
     * @notice Function to get the complete list of reward percents for every reward tier level.
     * @return rewardPercents : Array of length five, containing all the reward percents.
     */
    function getRewardPercents()
        public
        view
        returns (uint256[] memory rewardPercents)
    {
        return rewardPercents_;
    }

    /**
     * @notice Function to get the total reward percentages that is charged as fee when a user joins the network.
     * @return totalRewardPercent : Total fee to be charged.
     */
    function getTotalRewardPercents()
        public
        view
        returns (uint256 totalRewardPercent)
    {
        for (uint256 i = 0; i < rewardPercents_.length; i++) {
            totalRewardPercent += rewardPercents_[i];
        }

        return totalRewardPercent;
    }

    /**
     * @notice Function to get the reward tier cost (in PAXG) for a given reward tier level.
     * @dev rewardTierCost is calculated by adding all the costs from the user's current level upto a given reward tier level.
     * @param _currentLevel : Current reward tier level of the user.
     * @param _levelToPurchase : Reward Tier Level to purchase.
     * @return rewardTierCost : Total cost (in PAXG) to buy a given reward tier level.
     */
    function getRewardTierCost(uint256 _currentLevel, uint256 _levelToPurchase)
        public
        view
        returns (uint256 rewardTierCost)
    {
        require(
            _levelToPurchase > 0 && _levelToPurchase <= MAX_REFERRAL_LEVEL,
            "getRewardTierCost : Invalid level."
        );

        for (uint256 i = _currentLevel; i < _levelToPurchase; i++) {
            rewardTierCost += rewardTierCosts_[i];
        }

        return rewardTierCost;
    }

    /**
     * @notice Function to get the complete list of reward tier costs associated with every reward tiew level.
     * @return rewardTierCosts : Array of length five, containing all the reward tier costs.
     */
    function getAllRewardTierCosts()
        public
        view
        returns (uint256[] memory rewardTierCosts)
    {
        return rewardTierCosts_;
    }

    /**
     * @notice Function to get the wallet address mapped with the user's unique id.
     * @return userAddress : User address mapped with the provided unique id.
     */
    function getUserAddressFromId(uint256 _uniqueId)
        public
        view
        returns (address userAddress)
    {
        require(
            _uniqueId > 0 && _uniqueId <= totalUsers_,
            "getUserAddressFromId: Given unique id is invalid."
        );

        return idToWalletAddress[_uniqueId];
    }

    /**
     * @notice Function to fetch the user unique id from the wallet address.
     * @param _userAddress : User's wallet address.
     * @return uniqueId : User's unique id that represents the user in the GODL Network.
     */
    function getUserIdFromWalletAddress(address _userAddress)
        public
        view
        returns (uint256 uniqueId)
    {
        require(
            isExistingUser(_userAddress),
            "getUserIdFromWalletAddress: User has not yet joined the GODL Network."
        );

        return user[_userAddress].uniqueId;
    }

    /**
     * @notice Function to get an existing user's data from the User struce.
     * @param _userAddress : User's wallet address.
     * @return referrer : Referrer's wallet address.
     * @return currentLevel : Current reward tier level of the user.
     * @return reinvestFlag : Boolean true / false describing the mode.
     * @return referralCount : Array of referral counts for all the reward tiers.
     * @return totalRewards : Total rewards generated for hte user till date.
     * @return rewardBalance : Accumulated PAXG rewards of all the reward tier levels.
     * @return registrationTime : EPOCH time in seconds when the user joined the GODL network.
     */
    function getUser(address _userAddress)
        public
        view
        returns (
            address referrer,
            uint256 currentLevel,
            bool reinvestFlag,
            uint256[] memory referralCount,
            uint256 totalRewards,
            uint256 rewardBalance,
            uint256 registrationTime
        )
    {
        require(
            isExistingUser(_userAddress),
            "getUser: Given user has not yet joined the network."
        );

        referralCount = new uint256[](MAX_REFERRAL_LEVEL);
        for (uint256 i = 0; i < MAX_REFERRAL_LEVEL; i++) {
            referralCount[i] = user[_userAddress].referralCount[i + 1];
        }

        return (
            idToWalletAddress[user[_userAddress].referrer],
            user[_userAddress].level,
            user[_userAddress].reinvestFlag,
            referralCount,
            user[_userAddress].totalRewards,
            user[_userAddress].rewardBalance,
            user[_userAddress].registrationTime
        );
    }

    /**
     * @notice Function to get all the referral addresses of a given user for all the five downline levels.
     * @param _userAddress : User address that exists in the GODL network.
     * @return level1Referrals : User's level 1 referral address list.
     * @return level2Referrals : User's level 2 referral address list.
     * @return level3Referrals : User's level 3 referral address list.
     * @return level4Referrals : User's level 4 referral address list.
     * @return level5Referrals : User's level 5 referral address list.
     */
    function getUserReferrals(address _userAddress)
        public
        view
        returns (
            address[] memory level1Referrals,
            address[] memory level2Referrals,
            address[] memory level3Referrals,
            address[] memory level4Referrals,
            address[] memory level5Referrals
        )
    {
        require(
            isExistingUser(_userAddress),
            "getUser: Given user has not yet joined the network."
        );

        level1Referrals = new address[](user[_userAddress].referralCount[1]);
        level2Referrals = new address[](user[_userAddress].referralCount[2]);
        level3Referrals = new address[](user[_userAddress].referralCount[3]);
        level4Referrals = new address[](user[_userAddress].referralCount[4]);
        level5Referrals = new address[](user[_userAddress].referralCount[5]);

        level1Referrals = getUserReferralAddresses(_userAddress, 1);
        level2Referrals = getUserReferralAddresses(_userAddress, 2);
        level3Referrals = getUserReferralAddresses(_userAddress, 3);
        level4Referrals = getUserReferralAddresses(_userAddress, 4);
        level5Referrals = getUserReferralAddresses(_userAddress, 5);
    }

    function getUserReferralAddresses(address _userAddress, uint256 _level)
        public
        view
        returns (address[] memory referralAddresses)
    {
        require(
            isExistingUser(_userAddress),
            "getUser: Given user has not yet joined the network."
        );

        require(
            _level > 0 && _level <= MAX_REFERRAL_LEVEL,
            "getUserReferralAddresses : Invalid level."
        );

        referralAddresses = new address[](
            user[_userAddress].referralCount[_level]
        );

        for (uint256 i = 0; i < user[_userAddress].referralCount[_level]; i++) {
            referralAddresses[i] = idToWalletAddress[
                user[_userAddress].referrals[_level][i]
            ];
        }
        return referralAddresses;
    }

    // ---------- END: Getter Functions ---------- //

    // ---------- START: Helper Functions ---------- //

    /**
     * @notice Function to check if the given wallet address has registered in the GODL network.
     * @dev For a non-existing user, registrationTime is not yet and is thus is always zero.
     * @param _userAddress : User wallet address.
     * @return exists : Boolean true / false if the user is already registered.
     */
    function isExistingUser(address _userAddress)
        public
        view
        returns (bool exists)
    {
        return (user[_userAddress].registrationTime > 0);
    }

    // ---------- END: Helper Functions ---------- //
}