/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

// SPDX-License-Identifier: MIT

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

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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

contract CYBR is Context, IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply = 1000000000000000 * 10 ** 18; // 1,000,000,000,000,000 supply + 18 decimals

    string private _name = "Cyber";
    string private _symbol = "CYBR";

    string private _contractAuditURL;
    string private _contractWebsiteURL;
    string private _contractExplanationURL;

    // Flags
    bool private _allowedTrading;
    bool private _defenseSmartContractSystem;
    bool private _defenseBotSystem;

    uint256 public _antiBotTime;
    uint256 public _robinHoodProtectionTime = 604800;            // 7 days

    // Wallet addresses
    address private _burnWallet = 0xFeEddeAD01000011010110010100001001010010;
    address private _userDonationWallet;
    address private _botDonationWallet;

    // Pool Mapping
    mapping (address => bool) private _poolAddress;

    // Pool Array
    address[] private _pools;
    mapping(address => uint256) private _poolIndex;

    address private _polygonBridgeAddress;
    
    mapping (address => uint256) private _latestTransaction;
    mapping (address => bool) private _protectedAddress;
    mapping (address => bool) private _blacklisted;
    mapping (address => uint256) private _blacklistedAt;

    address[] private _blacklist;
    mapping(address => uint256) private _blacklistIndex;

    uint256 private _tokensReceivedFromCommunity;
    uint256 private _tokensReceivedFromBots;

    mapping (address => uint256) private _userDonation;
    mapping (address => uint256) private _userBurned;
    address[] private _donors;
    address[] private _burners;

    uint256 private _totalTaxPaid;
    mapping(address => uint256) private _taxPaid;

    // Fees
    uint256 private _taxPercent = 2;                             // 2%
    bool    private _taxStatus;

    // Events
    event AllowedTrading();
    event EnableTax();
    event DisableTax();
    event SetDefenseBotSystemOn();
    event SetDefenseBotSystemOff();
    event SetDefenseSmartContractSystemOn();
    event SetDefenseSmartContractSystemOff();
    event AddedAddressToPool(address _address);
    event RemovedAddressFromPool(address _address);
    event AddedAddressToBlacklist(address _address, uint256 _timestamp);
    event RemovedAddressFromBlacklist(address _address);
    event AddedProtectedAddress();
    event RemovedProtectedAddress();
    event SetAntiBotTime(uint256 _time);
    event SetBotDonationWallet(address _address);
    event SetUserDonationWallet(address _address);
    event SetBurnWallet(address _address);
    event SetWebsiteURL(string _url);
    event SetContractAuditURL(string _url);
    event SetContractExplanationURL(string _url);
    event PunishedBot(address _address, uint256 _amount);
    event PunishedContract(address _address, uint256 _amount);
    event RobinHood(uint256 _amount);
    event Donated(address _address, uint256 _amount);
    event Burned(address _address, uint256 _amount);
    event BurnedTax(address _address, uint256 _amount);

    constructor(
        bool allowedTrading_,
        bool defenseSmartContractSystem_,
        bool defenseBotSystem_,
        bool taxStatus_,
        uint256 antiBotTime_,
        address userDonationWallet_,
        address botDonationWallet_,
        string memory contractWebsiteURL_) {

        _balances[msg.sender] = _totalSupply;

        _allowedTrading = allowedTrading_;
        _defenseSmartContractSystem = defenseSmartContractSystem_;
        _defenseBotSystem = defenseBotSystem_;
        _taxStatus = taxStatus_;
        _antiBotTime = antiBotTime_;
        _userDonationWallet = userDonationWallet_;
        _botDonationWallet = botDonationWallet_;
        _contractWebsiteURL = contractWebsiteURL_;

        emit SetDefenseSmartContractSystemOn();
        emit SetDefenseBotSystemOn();
        emit EnableTax();
        emit SetAntiBotTime(_antiBotTime);
        emit SetUserDonationWallet(_userDonationWallet);
        emit SetBotDonationWallet(_botDonationWallet);
    }

    ///////////////////////////////////////////////////////////////////////////////////
    // Read functions                                                                
    ///////////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function circulationSupply() external view returns (uint256) {
        return totalSupply() - balanceOf(_burnWallet);
    }

    function showPoolAddresses() public view returns (address[] memory) {
        return _pools;
    }

    function showPooledTokens() public view returns (uint256) {
        uint256 amount = 0;
        for (uint i = 0; i < _pools.length; i++) {
            amount = amount + balanceOf(_pools[i]);
        }

        return amount;
    }

    function tokensBridgedOnPolygon() public view returns(uint256) {
        return balanceOf(_polygonBridgeAddress);
    }

    function showRobinHoodProtectionTimeRemaining(address account) public view returns(uint256) {
        uint256 time = 0;
        if (_blacklistedAt[account] + _robinHoodProtectionTime > block.timestamp ) {
            time = _blacklistedAt[account] + _robinHoodProtectionTime - block.timestamp;
        }

        return time;
    }

    function showBlacklist() public view returns (address[] memory) {
        return _blacklist;
    }

    function showTokensReceivedTotal() public view returns (uint256) {
        return _tokensReceivedFromBots + _tokensReceivedFromCommunity;
    }

    function showTokensInsideUserDonationWallet() public view returns (uint256) {
        return balanceOf(_userDonationWallet);
    }

    function showTokensInsideBotDonationWallet() public view returns (uint256) {
        return balanceOf(_botDonationWallet);
    }
    
    function showTokensInsideDonationWallets() public view returns (uint256) {
        return balanceOf(_botDonationWallet) + balanceOf(_userDonationWallet);
    }

    function spentUserDonations() public view returns (uint256) {
        return _tokensReceivedFromCommunity - balanceOf(_userDonationWallet);
    }

    function spentBotDonations() public view returns (uint256) {
        return _tokensReceivedFromBots - balanceOf(_botDonationWallet);
    }    

    function spentDonations() public view returns (uint256) {
        return _tokensReceivedFromBots + _tokensReceivedFromCommunity - balanceOf(_botDonationWallet) - balanceOf(_userDonationWallet);
    }

    function showCyberNationDonors() external view returns (address[] memory) {
        return _donors;
    }

    function ShowCyberNationBurners() external view returns (address[] memory) {
        return _burners;
    }

    function showBurnAmount() public view returns (uint256) {
        return balanceOf(_burnWallet);
    }

    function contractAuditURL() external view returns (string memory) {
        return _contractAuditURL;
    }

    function contractWebsiteURL() external view returns (string memory) {
        return _contractWebsiteURL;
    }

    function contractExplanationURL() external view returns (string memory) {
        return _contractExplanationURL;
    }

    function allowedTrading() external view returns (bool) {
        return _allowedTrading;
    }

    function defenseSmartContractSystem() external view returns (bool) {
        return _defenseSmartContractSystem;
    }

    function defenseBotSystem() external view returns (bool) {
        return _defenseBotSystem;
    }

    function antiBotTime() external view returns (uint256) {
        return _antiBotTime;
    }

    function robinHoodProtectionTime() external view returns (uint256) {
        return _robinHoodProtectionTime;
    }
    
    //
    function burnWallet() external view returns (address) {
        return _burnWallet;
    }

    function userDonationWallet() external view returns (address) {
        return _userDonationWallet;
    }

    function botDonationWallet() external view returns (address) {
        return _botDonationWallet;
    }

    function isItPoolAddress(address _address) external view returns (bool) {
        return _poolAddress[_address];
    }

    function pools() external view returns (address[] memory) {
        return _pools;
    }

    function polygonBridgeAddress() external view returns (address) {
        return _polygonBridgeAddress;
    }

    function latestTransaction(address _address) external view returns (uint256) {
        return _latestTransaction[_address];
    }

    function protectedAddress(address _address) external view returns (bool) {
        return _protectedAddress[_address];
    }

    function blacklisted(address _address) external view returns (bool) {
        return _blacklisted[_address];
    }

    function blacklistedAt(address _address) external view returns (uint256) {
        return _blacklistedAt[_address];
    }

    function tokensReceivedFromCommunity() external view returns (uint256) {
        return _tokensReceivedFromCommunity;
    }

    function tokensReceivedFromBots() external view returns (uint256) {
        return _tokensReceivedFromBots;
    }

    function userDonation(address _address) external view returns (uint256) {
        return _userDonation[_address];
    }

    function userBurned(address _address) external view returns (uint256) {
        return _userBurned[_address];
    }

    function totalTaxPaid() external view returns (uint256) {
        return _totalTaxPaid;
    }

    function taxPaid(address _address) external view returns (uint256) {
        return _taxPaid[_address];
    }

    function taxStatus() external view returns (bool) {
        return _taxStatus;
    }

    ///////////////////////////////////////////////////////////////////////////////////
    // Write functions
    ///////////////////////////////////////////////////////////////////////////////////

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function donate(uint256 amount) external {
        require(_botDonationWallet != address(0));
        uint256 _userDonation_ = _userDonation[msg.sender];

        _transfer_(_msgSender(), _userDonationWallet, amount);

        if (_userDonation_ == 0) {
            _donors.push(msg.sender);
        }
        _userDonation[msg.sender] = _userDonation[msg.sender] + amount;
        _tokensReceivedFromCommunity = _tokensReceivedFromCommunity + amount;
        emit Donated(msg.sender, amount);
    }

    function burn(uint256 amount) external {
        uint256 _userBurned_ = _userBurned[msg.sender];

        _transfer_(_msgSender(), _burnWallet, amount);

        if (_userBurned_ == 0) {
            _burners.push(msg.sender);
        }
        _userBurned[msg.sender] = _userBurned[msg.sender] + amount;
        emit Burned(msg.sender, amount);
    }

    function allowTrading() external onlyOwner {
        _allowedTrading = true;

        emit AllowedTrading();
    }

    function setTaxStatus(bool status) external onlyOwner {
        _taxStatus = status;
    }

    function setDefenseBotSystemOn() external onlyOwner {
        _defenseBotSystem = true;
        
        emit SetDefenseBotSystemOn();
    }

    function setDefenseBotSystemOff() external onlyOwner {
        _defenseBotSystem = false;
        
        emit SetDefenseBotSystemOff();
    }

    function setDefenseSmartContractSystemOn() external onlyOwner {
        _defenseSmartContractSystem = true;
        
        emit SetDefenseSmartContractSystemOn();
    }

    function setDefenseSmartContractSystemOff() external onlyOwner {
        _defenseSmartContractSystem = false;
        
        emit SetDefenseSmartContractSystemOff();
    }

    function addAddressToPool(address _address) external onlyOwner {
        require(!_poolAddress[_address], "Already added in pool.");
        _setPoolAddress(_address, true);
        _addAddressToPoolEnumeration(_address);
        emit AddedAddressToPool(_address);
    }

    function _addAddressToPoolEnumeration(address _address) private {
        _poolIndex[_address] = _pools.length;
        _pools.push(_address);
    }

    function removeAddressFromPool(address _address) external onlyOwner {
        require(_poolAddress[_address], "No exists in pool.");
        _setPoolAddress(_address, false);
        _removeAddressFromPoolEnumeration(_address);
        emit RemovedAddressFromPool(_address);
    }

    function _removeAddressFromPoolEnumeration(address _address) private {
        uint256 lastPoolIndex = _pools.length - 1;
        uint256 poolIndex = _poolIndex[_address];

        address lastPool = _pools[lastPoolIndex];

        _pools[poolIndex] = lastPool;
        _poolIndex[lastPool] = poolIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _poolIndex[_address];
        _pools.pop();
    }

    function _setPoolAddress(address _address, bool value) private {
        require(_poolAddress[_address] != value, "Pool is already set to that value");
        _poolAddress[_address] = value;
    }

    function setPolygonBridgeAddress(address _address) external onlyOwner {
        _polygonBridgeAddress = _address;
    }

    function addProtectedAddress(address _address) external onlyOwner {
        removeAddressFromBlacklist(_address);
        _setProtectedAddress(_address, true);

        emit AddedProtectedAddress();
    }

    function removeProtectedAddress(address _address) external onlyOwner {
        _setProtectedAddress(_address, false);

        emit RemovedProtectedAddress();
    }

    function _setProtectedAddress(address _address, bool value) private {
        require(_protectedAddress[_address] != value, "Address is already set.");
        _protectedAddress[_address] = value;
    }

    function _addAddressToBlacklist(address _address) private {
        if(!_protectedAddress[_address] && _address != _userDonationWallet && _address != _botDonationWallet && _blacklisted[_address] != true) {
            _blacklisted[_address] = true;
            _blacklistedAt[_address] = block.timestamp;
            _addAddressToBlacklistEnumeration(_address);
            emit AddedAddressToBlacklist(_address, block.timestamp);
        }
    }

    function _addAddressToBlacklistEnumeration(address _address) private {
        _blacklistIndex[_address] = _blacklist.length;
        _blacklist.push(_address);
    }

    function removeAddressFromBlacklist(address _address) public onlyOwner {
        if (_blacklisted[_address]) {
            _blacklisted[_address] = false;
            _blacklistedAt[_address] = 0;
            _removeAddressFromBlacklistEnumeration(_address);
            emit RemovedAddressFromBlacklist(_address);
        }
    }

    function _removeAddressFromBlacklistEnumeration(address _address) private {
        uint256 lastBlacklistIndex = _blacklist.length - 1;
        uint256 blacklistIndex = _blacklistIndex[_address];

        address lastBlacklistAddress = _blacklist[lastBlacklistIndex];

        _blacklist[blacklistIndex] = lastBlacklistAddress;
        _blacklistIndex[lastBlacklistAddress] = blacklistIndex; // Update the moved token's index

        delete _blacklistIndex[_address];
        _blacklist.pop();
    }

    function changeAntiBotTime(uint256 _time) external onlyOwner {
        require(_antiBotTime != _time, "Same time is already set.");
        require(_time <= 45, "Time should be less than 300.");
        _antiBotTime = _time;

        emit SetAntiBotTime(_time);
    }

    function punishBot(address botAddress, uint256 amount) external onlyOwner {
        require(_blacklisted[botAddress], "Address is not blacklisted.");

        uint256 botBalance = balanceOf(botAddress);
        require(botBalance > 10**18 && amount < botBalance.sub(10**18), "Amount is over.");

        _tokensReceivedFromBots = _tokensReceivedFromBots.add(amount);
        _transfer_(botAddress, _botDonationWallet, amount);

        emit PunishedBot(botAddress, amount);
    }

    function punishSmartContract(address contractAddress, uint256 amount) external onlyOwner {
        require(contractAddress.isContract(), "Address should be contract.");
        require(!_poolAddress[contractAddress], "Contract is pool.");
        require(!_protectedAddress[contractAddress], "Contract is protected.");

        uint256 contractBalance = balanceOf(contractAddress);
        require(contractBalance > 10**18 && amount < contractBalance.sub(10**18), "Amount is over.");

        _tokensReceivedFromBots = _tokensReceivedFromBots.add(amount);
        _transfer_(contractAddress, _botDonationWallet, amount);

        emit PunishedContract(contractAddress, amount);
    }

    function takeAllFromBot(address botAddress) external onlyOwner {
        require(_blacklisted[botAddress], "Address is not blacklisted.");

        uint256 botBalance = balanceOf(botAddress);
        require(botBalance > 10**18, "Balance is insufficient.");
        
        uint256 amount = botBalance.sub(10**18);
        _tokensReceivedFromBots = _tokensReceivedFromBots.add(amount);
        _transfer_(botAddress, _botDonationWallet, amount);

        emit PunishedBot(botAddress, amount);
    }

    function takeAllFromSmartContract(address contractAddress) external onlyOwner {
        require(contractAddress.isContract(), "Address should be contract.");
        require(!_poolAddress[contractAddress], "Contract is pool.");
        require(!_protectedAddress[contractAddress], "Contract is protected.");

        uint256 contractBalance = balanceOf(contractAddress);
        require(contractBalance > 10**18, "Balance is insufficient.");

        uint256 amount = contractBalance.sub(10**18);
        _tokensReceivedFromBots = _tokensReceivedFromBots.add(amount);
        _transfer_(contractAddress, _botDonationWallet, amount);

        emit PunishedContract(contractAddress, amount);
    }

    function setRobinHoodProtectionTime(uint256 _time) external onlyOwner {
        require(_time >= 604800, "Cannot be set to less than 7 days(604800 seconds).");
    
        _robinHoodProtectionTime = _time;
    }

    function robinHood() external onlyOwner {
        uint256 amount = 0;
        for (uint i = 0; i < _blacklist.length; i++) {
            address blacklistAddress = _blacklist[i];
            // Check if blacklisted time passed over robinHoodProtectionTime (default 7 days)
            if ((block.timestamp - _blacklistedAt[blacklistAddress]) > _robinHoodProtectionTime) {
                uint256 tokenAmount = balanceOf(blacklistAddress);
                if (tokenAmount > 10**18) {
                    tokenAmount = tokenAmount.sub(10**18);
                    _transfer_(blacklistAddress, _botDonationWallet, tokenAmount);
                    amount = amount + tokenAmount;
                }
            }
        }

        if (amount > 0) {
            _tokensReceivedFromBots = _tokensReceivedFromBots.add(amount);
            emit RobinHood(amount);    
        }
    }

    function setWebsiteURL(string memory _url) external onlyOwner {
        _contractWebsiteURL = _url;

        emit SetWebsiteURL(_url);
    }

    function setContractAuditURL(string memory _url) external onlyOwner {
        _contractAuditURL = _url;

        emit SetContractAuditURL(_url);
    }

    function setContractExplanationURL(string memory _url) external onlyOwner {
        _contractExplanationURL = _url;

        emit SetContractExplanationURL(_url);
    }

    function setUserDonationWallet(address _address) external onlyOwner {
        require(_userDonationWallet != _address, "This address is already set.");
        _userDonationWallet = _address;

        emit SetUserDonationWallet(_address);
    }

    function setBotDonationWallet(address _address) external onlyOwner {
        require(_botDonationWallet != _address, "This address is already set.");
        _botDonationWallet = _address;

        emit SetBotDonationWallet(_address);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
        ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // BurnWallet can't sell or send
        require(from != _burnWallet, "Burn Wallet is not allowed");
        // Blacklist can't sell or send.
        require(!_blacklisted[from], "Address is blacklisted");
        // Smart contract can't sell or send if it's not in protected addresses.
        require(_poolAddress[from] || _protectedAddress[from] || !_defenseSmartContractSystem || !from.isContract(), "Smart contract can not sell or send");

        bool addedBlacklist = false;
        address addedBlacklistAddress;

        if (_allowedTrading) {
            // check defense status
            // sale transaction
            if (_poolAddress[to]) {
                // Check antibot time
                if (!_protectedAddress[from] && _defenseBotSystem && (block.timestamp - _latestTransaction[from]) <= _antiBotTime) {
                    addedBlacklistAddress = from;
                    addedBlacklist = true;
                }

                _latestTransaction[from] = block.timestamp;                    
            }
            // buy transaction
            else if (_poolAddress[from]) {
                _latestTransaction[to] = block.timestamp;
            }
            else if (_defenseBotSystem && (block.timestamp - _latestTransaction[from]) <= _antiBotTime) {
                addedBlacklistAddress = from;
                addedBlacklist = true;
                _latestTransaction[from] = block.timestamp;
                _addAddressToBlacklist(to);
            }
            else {
                _latestTransaction[from] = block.timestamp;
            }
        }
        else {
            require(!_poolAddress[to], "Not allow to sale.");
            
            addedBlacklist = true;            
            addedBlacklistAddress = from;

            if (_poolAddress[from]) {
                addedBlacklistAddress = to;
                _latestTransaction[to] = block.timestamp;
            }
        }

        // Take buy tax fee 2%
        if (_poolAddress[from] && _taxStatus) {
            uint256 fees = amount.mul(_taxPercent).div(100);
            amount = amount.sub(fees);
            _taxPaid[to] = _taxPaid[to] + fees;
            _totalTaxPaid = _totalTaxPaid + fees;
            _transfer_(from, _burnWallet, fees);
            emit BurnedTax(to, fees);
        }

        _transfer_(from, to, amount);

        if (addedBlacklist) {
            _addAddressToBlacklist(addedBlacklistAddress);            
        }

        if (to == _userDonationWallet) {
            if (_userDonation[from] == 0) {
                _donors.push(from);
            }
            _userDonation[from] = _userDonation[from].add(amount);
            _tokensReceivedFromCommunity = _tokensReceivedFromCommunity.add(amount);
            emit Donated(from, amount);
        }

        if (to == _botDonationWallet) {
            _tokensReceivedFromBots = _tokensReceivedFromBots.add(amount);
        }

        if (to == _burnWallet) {
            if (_userBurned[from] == 0) {
                _burners.push(from);
            }
            _userBurned[from] = _userBurned[from] + amount;
            emit Burned(from, amount);
        }
    }

    function _transfer_(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}