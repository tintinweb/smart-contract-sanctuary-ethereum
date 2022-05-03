/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// File: contracts/VestingV2.sol


pragma solidity ^0.8.7;




/**
* @title Sahara Vesting Smart Contract
* @author SAHARA
* @notice Vesting initializable contract for beneficiary management and unlocked token claiming.
*/
contract VestingV2 is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable private token;
    uint private poolCount;
    uint private listingDate;
    event Claim(address indexed from, uint indexed poolIndex, uint tokenAmount);
    event VestingPoolAdded(uint indexed poolIndex, uint totalPoolTokenAmount);
    event BeneficiaryAdded(uint indexed poolIndex, address indexed beneficiary, uint addedTokenAmount);
    event BeneficiaryRemoved(uint indexed poolIndex, address indexed beneficiary, uint unlockedPoolAmount);
    event ListingDateChanged(uint oldDate, uint newDate);
    enum UnlockTypes{
        DAILY, 
        MONTHLY
    }
    struct Beneficiary {
        uint totalTokens;
        uint listingTokenAmount;
        uint cliffTokenAmount;
        uint vestedTokenAmount;
        uint claimedTotalTokenAmount;
    }
    struct Pool {
        string name;
        uint listingPercentageDividend;
        uint listingPercentageDivisor;
        uint cliffInDays;
        uint cliffEndDate;
        uint cliffPercentageDividend;
        uint cliffPercentageDivisor;
        uint vestingDurationInMonths;
        uint vestingDurationInDays;
        uint vestingEndDate;
        mapping(address => Beneficiary) beneficiaries;
        UnlockTypes unlockType;
        uint totalPoolTokenAmount;
        uint lockedPoolTokens;
    }
    mapping(uint => Pool) private vestingPools;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
    function initialize(IERC20Upgradeable _token, uint _listingDate) 
        public
        initializer
        validListingDate(_listingDate)
    {
        __Ownable_init();
        token = _token;
        poolCount = 0;
        listingDate = _listingDate;
        /* name, listing percentage, cliff period, cliff percentage, vesting months, unlock type, total token amount */
        addVestingPool('Angel Round', 0, 1, 90, 1, 20, 36, UnlockTypes.DAILY, 13000000 * 10 ** 18);
        addVestingPool('Seed',  0, 1, 90, 1, 20, 24, UnlockTypes.DAILY, 32500000 * 10 ** 18);
        addVestingPool('Private A',  0, 1, 90, 1, 20, 22, UnlockTypes.DAILY, 26000000 * 10 ** 18);
        addVestingPool('Private B', 0, 1, 60, 1, 20, 20, UnlockTypes.DAILY, 19500000 * 10 ** 18);
        addVestingPool('Marketing Round', 1, 20, 0, 0, 1, 24, UnlockTypes.DAILY, 19500000 * 10 ** 18);
        addVestingPool('Community', 0, 1, 360, 0, 1, 48, UnlockTypes.DAILY, 104000000 * 10 ** 18);
        addVestingPool('Team', 0, 1, 360, 0, 1, 48, UnlockTypes.DAILY, 110000000 * 10 ** 18);
        addVestingPool('Advisors',  0, 1, 180, 0, 1, 18, UnlockTypes.DAILY, 39000000 * 10 ** 18);
        addVestingPool('Staking/Yield farming', 0, 1, 0, 0, 1, 120, UnlockTypes.DAILY, 227500000 * 10 ** 18);
    }
    /**
    * @notice Checks whether the address is not zero.
    */
    modifier addressNotZero(address _address) {
        require(
            _address != address(0),
            "Wallet address can not be zero."
        );
        _;
    }
    /**
    * @notice Checks whether the listing date is not in the past.
    */
    modifier validListingDate(uint _listingDate) {
        require(
            _listingDate >= block.timestamp,
            "Listing date can be only set in the future."
        );
        _;
    }
    /**
    * @notice Checks whether the editable vesting pool exists.
    */
    modifier poolExists(uint _poolIndex) {
        require(
           vestingPools[_poolIndex].cliffPercentageDivisor > 0,
            "Pool does not exist."
        );
        _;
    }
    /**
    * @notice Checks whether new pool's name does not already exist.
    */
    modifier nameDoesNotExist(string memory _name) {
        bool exists = false;
        for(uint i = 0; i < poolCount; i++){
            if(keccak256(abi.encodePacked(vestingPools[i].name)) == keccak256(abi.encodePacked(_name))){
                exists = true;
                break;
            }
        }
        require( 
            !exists, 
            "Vesting pool with such name already exists.");
        _;
    }
    /**
    * @notice Checks whether token amount > 0.
    */
    modifier tokenNotZero(uint _tokenAmount) {
        require(
            _tokenAmount > 0,
            "Token amount can not be 0."
        );
        _;
    }
    /**
    * @notice Checks whether the address is beneficiary of the pool.
    */
    modifier onlyBeneficiary(uint _poolIndex) {
        require(
            vestingPools[_poolIndex].beneficiaries[msg.sender].totalTokens > 0,
            "Address is not in the beneficiary list."
        );
        _;
    }
    /**
    * @notice Adds new vesting pool and pushes new id to ID array.
    * @param _name Vesting pool name.
    * @param _listingPercentageDividend Percentage fractional form dividend part.
    * @param _listingPercentageDivisor Percentage fractional form divisor part.
    * @param _cliffInDays Period of the first lock (cliff) in days.
    * @param _cliffPercentageDividend Percentage fractional form dividend part.
    * @param _cliffPercentageDivisor Percentage fractional form divisor part.
    * @param _vestingDurationInMonths Duration of the vesting period.
    */
    function addVestingPool (
        string memory _name,
        uint _listingPercentageDividend,
        uint _listingPercentageDivisor,
        uint _cliffInDays,
        uint _cliffPercentageDividend,
        uint _cliffPercentageDivisor,
        uint _vestingDurationInMonths,
        UnlockTypes _unlockType,
        uint _totalPoolTokenAmount)
        public
        onlyOwner
        nameDoesNotExist(_name)
        tokenNotZero(_totalPoolTokenAmount)
    {
        require(
           (_listingPercentageDivisor > 0 && _cliffPercentageDivisor > 0),
            "Percentage divisor can not be zero."
            );
        require( 
            (_listingPercentageDividend * _cliffPercentageDivisor) + 
            (_cliffPercentageDividend * _listingPercentageDivisor) <=
            (_listingPercentageDivisor * _cliffPercentageDivisor),
            "Listing and cliff percentage can not exceed 100."
            );
       require(
           (_vestingDurationInMonths > 0),
            "Vesting duration can not be 0."
            );
        Pool storage p = vestingPools[poolCount];
        p.name = _name;
        p.listingPercentageDividend = _listingPercentageDividend;
        p.listingPercentageDivisor = _listingPercentageDivisor;
        p.cliffInDays = _cliffInDays;
        p.cliffEndDate = listingDate + (_cliffInDays * 1 days);
        p.cliffPercentageDividend = _cliffPercentageDividend;
        p.cliffPercentageDivisor = _cliffPercentageDivisor;
        p.vestingDurationInDays = _vestingDurationInMonths * 30;
        p.vestingDurationInMonths = _vestingDurationInMonths;
        p.vestingEndDate  = p.cliffEndDate + (p.vestingDurationInDays * 1 days);
        p.unlockType = _unlockType;
        p.totalPoolTokenAmount = _totalPoolTokenAmount;
        poolCount++;
        emit VestingPoolAdded(poolCount - 1, _totalPoolTokenAmount);
    }
    /**
    * @notice Adds address with purchased token amount to vesting pool.
    * @param _poolIndex Index that refers to vesting pool object.
    * @param _address Address of the beneficiary wallet.
    * @param _tokenAmount Purchased token absolute amount (with included decimals).
    */
    function addToBeneficiariesList(
        uint _poolIndex,
        address _address,
        uint _tokenAmount)
        public
        onlyOwner
        addressNotZero(_address)
        poolExists(_poolIndex)
        tokenNotZero(_tokenAmount)
    {
        Pool storage p = vestingPools[_poolIndex];
        require(
            p.totalPoolTokenAmount >= (p.lockedPoolTokens + _tokenAmount),
            "Allocated token amount will exceed total pool amount."
        );
        p.lockedPoolTokens += _tokenAmount;
        Beneficiary storage b = p.beneficiaries[_address];
        b.totalTokens += _tokenAmount;
        b.listingTokenAmount = getTokensByPercentage(b.totalTokens,
                                                    p.listingPercentageDividend,
                                                    p.listingPercentageDivisor);
        b.cliffTokenAmount = getTokensByPercentage(b.totalTokens,
                                                    p.cliffPercentageDividend, 
                                                    p.cliffPercentageDivisor);
        b.vestedTokenAmount = b.totalTokens - b.listingTokenAmount - b.cliffTokenAmount;
        emit BeneficiaryAdded(_poolIndex, _address, _tokenAmount);
    }
    /**
    * @notice Adds addresses with purchased token amount to the beneficiary list.
    * @param _poolIndex Index that refers to vesting pool object.
    * @param _addresses List of whitelisted addresses.
    * @param _tokenAmount Purchased token absolute amount (with included decimals).
    * @dev Example of parameters: ["address1","address2"], ["address1Amount", "address2Amount"].
    */
    function addToBeneficiariesListMultiple(
        uint _poolIndex,
        address[] calldata _addresses,
        uint[] calldata _tokenAmount)
        external
        onlyOwner
    {
        require(
            _addresses.length == _tokenAmount.length, 
            "Addresses and token amount arrays must be the same size."
            );
        for (uint i = 0; i < _addresses.length; i++) {
           addToBeneficiariesList(_poolIndex, _addresses[i], _tokenAmount[i]);
        }
    }
    /**
    * @notice Sets new listing date and recalculates cliff and vesting end dates for all pools.
    * @param newListingDate new listing date.
    */
    function changeListingDate(uint newListingDate)
        external
        onlyOwner
        validListingDate(newListingDate)
    {
        uint oldListingDate = listingDate;
        listingDate = newListingDate;
        for(uint i; i < poolCount; i++){
            Pool storage p = vestingPools[i];
            p.cliffEndDate = listingDate + (p.cliffInDays * 1 days);
            p.vestingEndDate = p.cliffEndDate + (p.vestingDurationInDays * 1 days);
        }
        emit ListingDateChanged(oldListingDate, newListingDate);
    }
    /**
    * @notice Function lets caller claim unlocked tokens from specified vesting pool.
    * @param _poolIndex Index that refers to vesting pool object.
    * if the vesting period has ended - beneficiary is transferred all unclaimed tokens.
    */
    function claimTokens(uint _poolIndex)
        external
        poolExists(_poolIndex)
        addressNotZero(msg.sender)
        onlyBeneficiary(_poolIndex)
    {
        uint unlockedTokens = unlockedTokenAmount(_poolIndex, msg.sender);
        require(
            unlockedTokens > 0, 
            "There are no claimable tokens."
        );
        require(
            unlockedTokens <= token.balanceOf(address(this)),
            "There are not enough tokens in the contract."
        );
        vestingPools[_poolIndex].beneficiaries[msg.sender].claimedTotalTokenAmount += unlockedTokens;
        token.safeTransfer(msg.sender, unlockedTokens);
        emit Claim(msg.sender, _poolIndex, unlockedTokens);
    }
    /**
    * @notice Removes beneficiary from the structure.
    * @param _poolIndex Index that refers to vesting pool object.
    * @param _address Address of the beneficiary wallet.
    */
    function removeBeneficiary(uint _poolIndex, address _address)
        external
        onlyOwner
        poolExists(_poolIndex)
    {
        Pool storage p = vestingPools[_poolIndex];
        Beneficiary storage b = p.beneficiaries[_address];
        uint unlockedPoolAmount = b.totalTokens - b.claimedTotalTokenAmount;
        p.lockedPoolTokens -= unlockedPoolAmount;
        delete p.beneficiaries[_address];
        emit BeneficiaryRemoved(_poolIndex, _address, unlockedPoolAmount);
    }
    /**
    * @notice Transfers tokens to the selected recipient.
    * @param _customToken ERC20 token address.
    * @param _address Address of the recipient.
    * @param _tokenAmount Absolute token amount (with included decimals).
    */
    function withdrawContractTokens(
        IERC20Upgradeable _customToken, 
        address _address, 
        uint256 _tokenAmount)
        external 
        onlyOwner 
        addressNotZero(_address) 
    {
        require(
            _customToken != token,
            "You can not withdraw vested contract tokens."
        );
        _customToken.safeTransfer(_address, _tokenAmount);
    }
    /**
    * @notice Calculates unlocked and unclaimed tokens based on the days passed.
    * @param _address Address of the beneficiary wallet.
    * @param _poolIndex Index that refers to vesting pool object.
    * @return uint total unlocked and unclaimed tokens.
    */
    function unlockedTokenAmount(uint _poolIndex, address _address)
        public
        view
        returns (uint)
    {
        Pool storage p = vestingPools[_poolIndex];
        Beneficiary storage b = p.beneficiaries[_address];
        uint unlockedTokens = 0;
        if (block.timestamp < listingDate) { // Listing has not begun yet. Return 0.
            return unlockedTokens;
        } else if (block.timestamp < p.cliffEndDate) { // Cliff period has not ended yet. Unlocked listing tokens.
            unlockedTokens = b.listingTokenAmount;
        } else if (block.timestamp >= p.vestingEndDate) { // Vesting period has ended. Unlocked all tokens.
            unlockedTokens = b.totalTokens;
        } else { // Cliff period has ended. Calculate vested tokens.
            (uint duration, uint periodsPassed) = vestingPeriodsPassed(_poolIndex);
            unlockedTokens = b.listingTokenAmount + b.cliffTokenAmount + 
                            (b.vestedTokenAmount * periodsPassed / duration);
        }
        return unlockedTokens - b.claimedTotalTokenAmount;
    }
    /**
    * @notice Calculates how many full days or months have passed since the cliff end.
    * @param _poolIndex Index that refers to vesting pool object.   
    * @return If unlock type is daily: vesting duration in days, else: in months.
    * @return If unlock type is daily: number of days passed, else: number of months passed.
    */
    function vestingPeriodsPassed(uint _poolIndex)
        public
        view
        returns (uint, uint)
    {
        Pool storage p = vestingPools[_poolIndex];
        // Cliff not ended yet
        if(block.timestamp < p.cliffEndDate){
            return (p.vestingDurationInMonths, 0);
        }
        // Unlock type daily
        else if (p.unlockType == UnlockTypes.DAILY) { 
            return (p.vestingDurationInDays, (block.timestamp - p.cliffEndDate) / 1 days);
        // Unlock type monthly
        } else {
            return (p.vestingDurationInMonths, (block.timestamp - p.cliffEndDate) / 30 days);
        }
    }
    /**
    * @notice Calculate token amount based on the provided prcentage.
    * @param totalAmount Token amount which will be used for percentage calculation.
    * @param dividend The number from which total amount will be multiplied.
    * @param divisor The number from which total amount will be divided.
    */
    function getTokensByPercentage(uint totalAmount, uint dividend, uint divisor) 
        internal
        pure
        returns (uint)
    {
        return totalAmount * dividend / divisor;
    }
    /**
    * @notice Checks how many tokens unlocked in a pool (not allocated to any user).
    * @param _poolIndex Index that refers to vesting pool object.
    */
    function totalUnlockedPoolTokens(uint _poolIndex) 
        external
        view
        returns (uint)
    {
        Pool storage p = vestingPools[_poolIndex];
        return p.totalPoolTokenAmount - p.lockedPoolTokens;
    }
    /**
    * @notice View of the beneficiary structure.
    * @param _poolIndex Index that refers to vesting pool object.
    * @param _address Address of the beneficiary wallet.
    * @return Beneficiary structure information.
    */
    function beneficiaryInformation(uint _poolIndex, address _address)
        external
        view
        returns (
            uint, 
            uint, 
            uint,
            uint, 
            uint
        )
    {
        Beneficiary storage b = vestingPools[_poolIndex].beneficiaries[_address];
        return (
            b.totalTokens,
            b.listingTokenAmount,
            b.cliffTokenAmount,
            b.vestedTokenAmount,
            b.claimedTotalTokenAmount
        );
    }
    /**
    * @notice Return global listing date value (in epoch timestamp format).
    * @return uint listing date.
    */ 
    function getListingDate() 
        external
        view
        returns (uint)
    {
        return listingDate;
    }
    /**
    * @notice Return number of pools in contract.
    * @return uint pool count.
    */ 
    function getPoolCount() 
        external
        view
        returns (uint)
    {
        return poolCount;
    }
    /**
    * @notice Return claimable token address
    * @return IERC20 token.
    */ 
    function getToken() 
        external
        view
        returns (IERC20Upgradeable)
    {
        return token;
    }
    /**
    * @notice View of the vesting pool structure.
    * @param _poolIndex Index that refers to vesting pool object.
    * @return Part of the vesting pool information.
    */
    function poolDates(uint _poolIndex)
        external
        view
        returns (
            uint, 
            uint, 
            uint, 
            uint,
            uint
        )
    {
        Pool storage p = vestingPools[_poolIndex];
        return (
            p.cliffInDays,
            p.cliffEndDate,
            p.vestingDurationInDays,
            p.vestingDurationInMonths,
            p.vestingEndDate
        );
    }
    /**
    * @notice View of the vesting pool structure.
    * @param _poolIndex Index that refers to vesting pool object.
    * @return Part of the vesting pool information.
    */
    function poolData(uint _poolIndex)
        external
        view
        returns (
            string memory,
            uint,
            uint, 
            uint,
            uint,
            UnlockTypes,
            uint
        )
    {
        Pool storage p = vestingPools[_poolIndex];
        return (
            p.name,
            p.listingPercentageDividend,
            p.listingPercentageDivisor,
            p.cliffPercentageDividend,
            p.cliffPercentageDivisor,
            p.unlockType,
            p.totalPoolTokenAmount
        );
    }
    event VestingPoolAmountChanged(uint indexed poolIndex, uint oldAmount, uint newAmount);
    /**
    * @notice Sets listing pool total amount.
    * @param _poolIndex vesting pool index.
    * @param _amount token amount.
    */
    function addToPoolAmount(uint _poolIndex, uint _amount)
        external
        onlyOwner
        tokenNotZero(_amount)
    {
        Pool storage p = vestingPools[_poolIndex];
        uint oldAmount = p.totalPoolTokenAmount;
        p.totalPoolTokenAmount += _amount;
        emit VestingPoolAmountChanged(_poolIndex, oldAmount, _amount);
    }
}