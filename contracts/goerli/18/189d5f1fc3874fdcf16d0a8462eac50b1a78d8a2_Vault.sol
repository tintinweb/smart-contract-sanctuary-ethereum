/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// File: contracts/ddMinter/vault/CollateralModule.sol


pragma solidity 0.8.14;


contract CollateralModule is Ownable {
    address public DDMinter;

    /// Collateral token details
    struct Collateral {
        uint256 min;
        uint256 rate;
        bool isCollateral;
    }

    mapping(address => Collateral) public collateralAssest;
    address[] public totalCollateralAssest;

    // Events details
    event ConfigureDDMinter(address ddminter);
    event ConversionRate(uint256 rate);
    event AddCollateral(address token, uint256 rate);

    /// @dev Throws error if called by any other than the DDMinter.
    modifier onlyDDMinter() {
        require(msg.sender == DDMinter, "Only DDMinter");
        _;
    }

    /// @dev Throws error if collateral token is not exist.
    modifier isCollateral(address token) {
        require(collateralAssest[token].isCollateral, "Only collateral assest");
        _;
    }

    /**
     * @notice Add the collateral token info
     * Can only be called by the DDMinter
     * @param token The address of the collateral token
     * @param conversionRate The conversion rate 
     * @param minimum The minimum deposit amount
     */
    function addCollateral(
        address token,
        uint256 conversionRate,
        uint256 minimum
    ) external onlyDDMinter {
        require(token != address(0x00), "Zero address");
        require(conversionRate > 0, "Zero conversion rate");

        if (minimum == 0) {
            minimum = 10**(IERC20Metadata(token).decimals());
        }

        collateralAssest[token] = Collateral(minimum, conversionRate, true);
        totalCollateralAssest.push(token);
        emit AddCollateral(token, conversionRate);
    }
 
    /**
     * @notice Set the collateral token conversion rate
     * The collateral token must be exist
     * Can only be called by the DDMinter
     * @param token The address of the collateral token
     * @param conversionRate The conversion rate 
     */
    function setConversionRate(address token, uint256 conversionRate)
        external
        onlyDDMinter
        isCollateral(token)
    {
        require(conversionRate > 0, "Zero conversion rate");
        collateralAssest[token].rate = conversionRate;

        emit ConversionRate(conversionRate);
    }

    /**
     * @notice Configure the DDMinter contract address
     * Can't be configured again.   
     * Can only be called by the current owner
     * @param ddMinter The address of the DDMinter contract
     */
    function configureDDMinter(address ddMinter) external onlyOwner {
        require(DDMinter == address(0x00), "Already initialized");
        DDMinter = ddMinter;
        emit ConfigureDDMinter(ddMinter);
    }

    // Read methods

    ///@dev Returns the total collateral token address.
    function getTotalCollateralAssest()
        external
        view
        returns (address[] memory totalAssest)
    {
        totalAssest = totalCollateralAssest;
        return totalAssest;
    }

    /**
     * @param token The address of collateral token.
     * @return It's return the collateral token info 
     */    
    function getCollateralAssestInfo(address token)
        external
        view
        returns (Collateral memory)
    {
        return collateralAssest[token];
    }
}

// File: contracts/ddMinter/vault/VaultBase.sol


pragma solidity 0.8.14;


contract VaultBase is CollateralModule {
    address public DD;

    /// Total collateral position created
    uint public totalCDP;

    struct CDP {
        address user;
        address token;
        uint deposited;
        uint amount;
    }

    struct User {
        uint[] cdp;
        mapping(uint => uint) index;
    }

    mapping(address => User) internal userInfo;
    mapping(uint => CDP) public CDPInfo;

    // Event details
    event CreateVault(
        uint cdpId,
        address token,
        address user,
        uint deposited,
        uint minted
    );
    event Deposit(uint cdp, address user, uint amount);
    event Withdraw(uint cdp, address user, uint amount);
    event MintDD(uint cdp, address user, uint ddamount);
    event BurnDD(uint cdp, address user, uint ddamount);
    event TransferVault(uint cdp, address user, address to);
    event CloseVault(uint cdp, address user);

    // Internal method

    function _required(uint cdp, address user) internal view {
        require(cdp <= totalCDP, "Vault not exist");
        require(CDPInfo[cdp].user == user, "Incorrect user");
        // check the vault is active
        require(CDPInfo[cdp].deposited != 0, "Vault is closed");
    }

    function remainingToken(
        uint deposited,
        address token,
        uint ddAmount
    ) internal view returns (uint) {
        return (deposited - convertDDToCollateralAssest(token, ddAmount));
    }

    /**
     * @param token The address of the collateral token
     * @param amount The amount collateral token to be converted as DD
     * @return It's return the converted DD token amount.
     */    
    function convertcollateralAssestToDD(address token, uint amount)
        public
        view
        returns (uint)
    {
        return ((amount * collateralAssest[token].rate) /
            (10 ** IERC20Metadata(token).decimals()) );
    }

    /**
     * @param token The address of the collateral token
     * @param ddamount The amount DD token to be converted as collateral token
     * @return It's return the converted collateral token amount.
     */ 
    function convertDDToCollateralAssest(address token, uint ddamount)
        public
        view
        returns (uint)
    {
        uint amount = ( (10 ** IERC20Metadata(token).decimals()) *
            (10 ** IERC20Metadata(DD).decimals()) );
        amount = amount / collateralAssest[token].rate;

        return ( (amount * ddamount) / (10 ** IERC20Metadata(DD).decimals()) ) + 5;
    }

    /**
     * @param user The address of user.
     * @return It's return the total created cdp id. 
     */     
    function getUserTotalCDP(address user)
        external
        view
        returns (uint[] memory)
    {
        return userInfo[user].cdp;
    }

    /**
     * @param user The address of user.
     * @return It's return the cdp index id. 
     */  
    function getUserCDPByIndex(address user, uint index)
        external
        view
        returns (uint)
    {
        return userInfo[user].cdp[index];
    }

    /**
     * @param user The address of user.
     * @return ids This methods returns user created cdp ids
     * Based on given starting and ending index.
     */ 
    function getUserCDP(
        address user,
        uint strIndex,
        uint endIndex
    ) external view returns (uint[] memory ids) {
        uint j = 0;
        for (uint i = strIndex; i <= endIndex; i++) {
            ids[j] = userInfo[user].cdp[i];
            j++;
        }
        return ids;
    }

    /**
     * @param user The address of user.
     * @param cdp The cdp id.
     * @return index This methods returns the index of cdp.
     */
    function getUserCDPIndex(address user, uint cdp)
        external
        view
        returns (uint index)
    {
        return userInfo[user].index[cdp];
    }
}

// File: contracts/ddMinter/vault/Vault.sol


pragma solidity 0.8.14;


contract Vault is VaultBase {
    using SafeERC20 for IERC20;

    constructor(address _DD) {
        DD = _DD;
    }

    /**@notice The function allows opens a Vault to user.
     * Locks collateral into it, and draws out DD.
     * Can only be called by the DDMinter.
     * @param user The address of user.
     * @param token The collateral token address
     * @param amount The specified amount of collateral to deposit.
     * @param ddAmount The specified amount of dd to mint.
     * @return Returns amount of DD to mint.
     */
    function create(
        address user,
        address token,
        uint256 amount,
        uint256 ddAmount
    ) external onlyDDMinter isCollateral(token) returns (uint256) {
        require(amount >= collateralAssest[token].min, "Less than minimum");
        require((ddAmount == 0) || (ddAmount >= 1e18), "Less than minimum");

        totalCDP++;
        uint256 id = totalCDP;

        if (ddAmount > 0) {
            require(
                convertcollateralAssestToDD(token, amount) >= ddAmount,
                "Insufficient collateral"
            );
        }
        IERC20(token).safeTransferFrom(user, address(this), amount);
        CDPInfo[id] = CDP(user, token, amount, ddAmount);

        userInfo[user].index[id] = userInfo[user].cdp.length;
        userInfo[user].cdp.push(id);

        emit CreateVault(id, token, user, amount, ddAmount);

        return ddAmount;
    }

    /**@notice The function allows to add more collateral a specified Vault.
     * Locks collateral into it.
     * Required the vault must be exist.
     * Can only be called by the DDMinter.
     * @param cdp The id of vault.
     * @param user The address of user.
     * @param amount The specified amount of collateral to deposit.
     */
    function deposit(
        uint256 cdp,
        address user,
        uint256 amount
    ) external onlyDDMinter {
        _required(cdp, user);
        require(
            amount >= collateralAssest[CDPInfo[cdp].token].min,
            "Less than minimum"
        );
        IERC20(CDPInfo[cdp].token).safeTransferFrom(
            user,
            address(this),
            amount
        );
        CDPInfo[cdp].deposited += amount;
        emit Deposit(cdp, user, amount);
    }

    /**@notice The function allows to remove collateral a specified Vault.
     * Transfer collateral amount of token to user.
     * Required the vault must be exist.
     * Can only be called by the DDMinter.
     * @param cdp The id of vault.
     * @param user The address of user.
     * @param amount The specified amount of collateral to withdraw.
     */
    function withdraw(
        uint256 cdp,
        address user,
        uint256 amount
    ) external onlyDDMinter {
        _required(cdp, user);

        if (
            remainingToken(
                CDPInfo[cdp].deposited,
                CDPInfo[cdp].token,
                CDPInfo[cdp].amount
            ) >= amount
        ) {
            CDPInfo[cdp].deposited -= amount;
            IERC20(CDPInfo[cdp].token).safeTransfer(user, amount);
        } else {
            revert("Insufficient amount");
        }

        emit Withdraw(cdp, user, amount);
    }

    /**@notice The function allows to generate DD.
     * Required the vault must be exist.
     * Can only be called by the DDMinter.
     * @param cdp The id of vault.
     * @param user The address of user.
     * @param ddamount The specified amount of DD to mint.
     * @return Returns amount of DD to mint.
     */
    function mintDD(
        uint256 cdp,
        address user,
        uint256 ddamount
    ) external onlyDDMinter returns (uint256) {
        _required(cdp, user);
        require(ddamount >= 1e18, "Less than minimum");

        uint256 totalDD = convertcollateralAssestToDD(
            CDPInfo[cdp].token,
            CDPInfo[cdp].deposited
        );

        if ((totalDD - CDPInfo[cdp].amount) >= ddamount) {
            CDPInfo[cdp].amount += ddamount;
        } else {
            revert("Insufficient amount");
        }

        emit MintDD(cdp, user, ddamount);

        return ddamount;
    }

    /**
     * @notice The function allows to payback DD.
     * Required the vault must be exist.
     * Can only be called by the DDMinter.
     * @param cdp The id of vault.
     * @param user The address of user.
     * @param ddamount The specified amount of DD to burn.
     */
    function burnDD(
        uint256 cdp,
        address user,
        uint256 ddamount
    ) external onlyDDMinter {
        _required(cdp, user);

        require(ddamount <= CDPInfo[cdp].amount, "More than minted");

        CDPInfo[cdp].amount -= ddamount;

        emit BurnDD(cdp, user, ddamount);
    }

    /**@notice The function allows to transfer vault for specified recipient.
     * Required the vault must be exist.
     * Can only be called by the DDMinter.
     * @param cdp The id of vault.
     * @param user The address of user.
     * @param to Vault receiving recipient.
     */
    function transferVault(
        uint256 cdp,
        address user,
        address to
    ) external onlyDDMinter {
        _required(cdp, user);

        CDPInfo[cdp].user = to;

        // Remove vault from current owner
        uint256 index = userInfo[user].index[cdp];
        uint256 length = userInfo[user].cdp.length;

        if ((length != 1) && (length != index)) {
            userInfo[user].index[cdp] = 0;
            userInfo[user].cdp[index] = userInfo[user].cdp[length - 1];
        }

        userInfo[user].cdp.pop();
        userInfo[user].index[cdp] = 0;

        userInfo[to].index[cdp] = userInfo[to].cdp.length;
        userInfo[to].cdp.push(cdp);

        emit TransferVault(cdp, user, to);
    }

    /**@notice The function allows to close vault.
     * Transfer the deposited collateral amount of the token to the user.
     * Required the vault must be exist.
     * Can only be called by the DDMinter.
     * @param cdp The id of vault.
     * @param user The address of user.
     */
    function closeVault(uint256 cdp, address user) external onlyDDMinter {
        _required(cdp, user);

        require(CDPInfo[cdp].amount == 0, "Pay back debt");

        uint256 deposited = CDPInfo[cdp].deposited;
        CDPInfo[cdp].deposited = 0;

        IERC20(CDPInfo[cdp].token).safeTransfer(user, deposited);

        emit CloseVault(cdp, user);
    }
}