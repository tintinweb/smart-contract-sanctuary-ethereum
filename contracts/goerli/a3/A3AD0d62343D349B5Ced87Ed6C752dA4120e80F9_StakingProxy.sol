/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// File: contracts/library/DetailsLibrary.sol

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library DetailsLibrary {
    
    struct eachTransaction {
        uint128 txId;
        uint128 initialDeposit;
        uint128 stakeAmount;
        uint128 depositTime;
        uint128 fullWithdrawlTime;
        uint128 withdrawlTime;
        uint128 lastClaimTime;
        uint128 claimTimeInitialized;
        uint128 withdrawnReward;
        // uint128 depositBlockNo;
        bool claimed;
        
    }

    struct UserData {
        uint128 noOfDeposits;
        uint128 noOfWithdrawls;
        mapping(uint128 => eachTransaction) eachUserStakes;
    }

    struct StakeTypeData {
        uint128 stakePeriod;
        uint128 depositFees;
        uint128 withdrawlFees;
        uint128 rewardRate;
        uint128 totalStakedIn;
    }

    
}
// File: contracts/interface/IStakedToken.sol



pragma solidity ^0.8.0;

interface IStakedToken {
    function transfer(address to, uint256 amount) external returns(bool);
    function transferFrom(address from, address to, uint256 amount) external returns(bool);
    function balanceOf(address owner) external returns(uint256);
    function name() external returns(string memory);
    function symbol() external returns(string memory);

}
// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/Staking.sol



pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/proxy/utils/Initializable.sol";





contract Staking is OwnableUpgradeable, ReentrancyGuard {
    using DetailsLibrary for DetailsLibrary.UserData;
    using DetailsLibrary for DetailsLibrary.StakeTypeData;

    IStakedToken public stakedToken;

    
    string public name;
    string public symbol;
    address public ownerWallet;
    // address public owner;
    uint128 public totalStaked;
    uint128 public totalPoolTypes;
    

    bool public claimAndWithdrawFreeze;

    mapping(uint128 => DetailsLibrary.StakeTypeData) public stakeTypes;

    mapping(uint128 => bool) public stakeTypeExist;

    mapping(address => DetailsLibrary.UserData) public usersStakes;

    mapping(address => mapping(uint128 => DetailsLibrary.eachTransaction)) public userInfo;

    mapping(address => mapping(uint128 => uint128)) public userTotalPerPool; //address-->stakeType--->totalStaked

    // mapping(address => mapping(uint256 => uint256)) public userTxIdWithType;

    event Deposit(uint128 stakeAmount, uint128 stakeType, uint128 id, uint128 stakePeriod);
    event Withdraw(uint128 stakeAmount, uint128 stakeType, uint128 id, uint128 stakePeriod, uint128 rewardAmount);
    event Compound(uint128 rewardAmount, uint128 stakeType, uint128 id);
    event Claim(uint128 rewardAmount, uint128 stakeType, uint128 id);


    // modifier onlyOwner{
    //     require(owner == msg.sender, "ONLY_OWNER_CAN_CALL");
    //     _;
    // }

    function initialize(address _ownerWallet, address _stakedToken, 
                        uint128 _stakeType, uint128 _stakePeriod, uint128 _depositFees, 
                        uint128 _withdrawlsFees, uint128 _rewardRate) 
                        external initializer  {
        require(_depositFees < 100 && _withdrawlsFees < 100, "FEES_CANNOT_BE_EQUAL_OR_MORE_THAN_100");
        require(_rewardRate > 0, "INTEREST_RATE_CANNOT_BE_ZERO");
        __Ownable_init();

        stakedToken = IStakedToken(_stakedToken);
        // rewardToken = IRewardToken(_rewardToken);
        stakeTypes[_stakeType].stakePeriod = _stakePeriod;
        stakeTypes[_stakeType].depositFees = _depositFees;
        stakeTypes[_stakeType].withdrawlFees = _withdrawlsFees;
        stakeTypes[_stakeType].rewardRate = _rewardRate;
        totalPoolTypes++;
        stakeTypeExist[_stakeType] = true;
        ownerWallet = _ownerWallet;    
        // owner = _owner;
        name = IStakedToken(_stakedToken).name();
        symbol = IStakedToken(_stakedToken).symbol();

    }

    function deposit(uint128 _amount, uint128 _stakeType) external nonReentrant {
        require(_amount>0, "STAKE_MORE_THAN_ZERO");
        require(stakeTypeExist[_stakeType], "STAKE_TYPE_DOES_NOT_EXIST");

        
        usersStakes[msg.sender].noOfDeposits++;
        uint128 id = usersStakes[msg.sender].noOfDeposits;
        usersStakes[msg.sender].eachUserStakes[id].txId = id;
        
        
        usersStakes[msg.sender].eachUserStakes[id].depositTime = uint128(block.timestamp);
        usersStakes[msg.sender].eachUserStakes[id].claimTimeInitialized = uint128(block.timestamp);
        usersStakes[msg.sender].eachUserStakes[id].lastClaimTime = uint128(block.timestamp);
        usersStakes[msg.sender].eachUserStakes[id].fullWithdrawlTime = uint128(block.timestamp) + stakeTypes[_stakeType].stakePeriod;
        
        // usersStakes[msg.sender].eachUserStakes[id].depositBlockNo = uint128(block.number);
    
        // userTxIdWithType[msg.sender][id] = _stakeType;
        usersStakes[msg.sender].eachUserStakes[id].initialDeposit = _amount;
        uint128 _depositFees = stakeTypes[_stakeType].depositFees;

        if(_depositFees !=0) {
            uint128 fees = _amount * _depositFees *10 / 1000;
            uint128 actualAmount = _amount - fees;

            usersStakes[msg.sender].eachUserStakes[id].stakeAmount = actualAmount;
            stakeTypes[_stakeType].totalStakedIn += actualAmount;
            userTotalPerPool[msg.sender][_stakeType] +=  actualAmount;
            totalStaked +=actualAmount;

            stakedToken.transferFrom(msg.sender, ownerWallet, fees);
            bool success = stakedToken.transferFrom(msg.sender, address(this), actualAmount);
            if(!success) revert();
            emit Deposit(actualAmount, _stakeType, id, stakeTypes[_stakeType].stakePeriod);

        } else {
            usersStakes[msg.sender].eachUserStakes[id].stakeAmount = _amount;
            stakeTypes[_stakeType].totalStakedIn += _amount;
            userTotalPerPool[msg.sender][_stakeType] +=  _amount;
            totalStaked +=_amount;

            bool success = stakedToken.transferFrom(msg.sender, address(this), _amount);
            if(!success) revert();
            emit Deposit(_amount, _stakeType, id, stakeTypes[_stakeType].stakePeriod);
        }

        userInfo[msg.sender][id] = usersStakes[msg.sender].eachUserStakes[id];

        

    }

    function withdraw(uint128 _stakeType, uint128 _id) external nonReentrant {
        // require(_amount>0, "INVALID_WITHDRAW_AMOUNT");

        uint128 stakedValue = usersStakes[msg.sender].eachUserStakes[_id].stakeAmount;
        require(stakedValue > 0, "NOTHING_AT_STAKE");
        // uint128 _initialDeposit = usersStakes[msg.sender].eachUserStakes[_id].initialDeposit;
        // require(_initialDeposit > 0, "NOTHING_AT_STAKE");

        // require(_amount == stakedValue, "CAN'T_UNSTAKE_AMOUNT_LESS_THAN_STAKED_AMOUNT");
        
        require(stakeTypeExist[_stakeType], "STAKE_TYPE_DOES_NOT_EXIST");
        require(!usersStakes[msg.sender].eachUserStakes[_id].claimed, "ALREADY_CLAIMED");

        usersStakes[msg.sender].eachUserStakes[_id].withdrawlTime = uint128(block.timestamp);

        uint128 stakeTimecheck = usersStakes[msg.sender].eachUserStakes[_id].withdrawlTime - usersStakes[msg.sender].eachUserStakes[_id].depositTime;
        require(stakeTimecheck > stakeTypes[_stakeType].stakePeriod, "CANT_UNSTAKE_BEFORE_LOCKPERIOD");

        // totalStaked -=_initialOrCompoundedDeposit; // here do check

        uint128 stakeTimeForReward;
        {
        uint128 _fullWithdrawlTime = usersStakes[msg.sender].eachUserStakes[_id].fullWithdrawlTime;
        uint128 _lastClaimTime = usersStakes[msg.sender].eachUserStakes[_id].lastClaimTime;

        // if(_lastClaimTime !=0) {
        //     stakedValue = 
        // }
        
        if(_lastClaimTime != usersStakes[msg.sender].eachUserStakes[_id].claimTimeInitialized) {
            
            stakeTimeForReward = (_fullWithdrawlTime - _lastClaimTime);
            

        } else {
            
            stakeTimeForReward = (_fullWithdrawlTime - usersStakes[msg.sender].eachUserStakes[_id].depositTime);
            
        }
        }

        usersStakes[msg.sender].noOfWithdrawls++;
        stakeTypes[_stakeType].totalStakedIn -= stakedValue;
        userTotalPerPool[msg.sender][_stakeType] =  0;

        totalStaked -= stakedValue;

        uint128 _withdrawlFees = stakeTypes[_stakeType].withdrawlFees;

        if (_withdrawlFees !=0) {
            uint128 fees = stakedValue * _withdrawlFees * 10 / 1000;
            uint128 withdrawableAmount = stakedValue - fees;
            
            usersStakes[msg.sender].eachUserStakes[_id].initialDeposit = 0;
            usersStakes[msg.sender].eachUserStakes[_id].claimed = true;
            usersStakes[msg.sender].eachUserStakes[_id].stakeAmount = 0;
            // stakeTypes[_stakeType].totalStakedIn -= stakedValue;

            if(stakeTimeForReward == 0) {
                stakedToken.transfer(ownerWallet, fees);
                bool success = stakedToken.transfer(msg.sender, withdrawableAmount);
                if(!success) revert();

            } else {
                uint128 calculatedReward = rewardCalculation(withdrawableAmount, _stakeType, stakeTimeForReward);
                usersStakes[msg.sender].eachUserStakes[_id].withdrawnReward += calculatedReward;

                stakedToken.transfer(ownerWallet, fees);
                bool success = stakedToken.transfer(msg.sender, withdrawableAmount);
                if(!success) revert();
                claimReward(msg.sender, calculatedReward);
                
            }

            emit Withdraw(withdrawableAmount, _stakeType, _id, stakeTypes[_stakeType].stakePeriod, usersStakes[msg.sender].eachUserStakes[_id].withdrawnReward);
            
        } else {
            usersStakes[msg.sender].eachUserStakes[_id].initialDeposit = 0;
            usersStakes[msg.sender].eachUserStakes[_id].claimed = true;
            usersStakes[msg.sender].eachUserStakes[_id].stakeAmount = 0;
            // stakeTypes[_stakeType].totalStakedIn -= stakedValue;

            if(stakeTimeForReward == 0) {
                bool success = stakedToken.transfer(msg.sender, stakedValue);
                if(!success) revert();
            } else {
                bool success = stakedToken.transfer(msg.sender, stakedValue);
                if(!success) revert();
                
                uint128 calculatedReward = rewardCalculation(stakedValue, _stakeType, stakeTimeForReward);
                usersStakes[msg.sender].eachUserStakes[_id].withdrawnReward += calculatedReward;
                claimReward(msg.sender, calculatedReward);
                
            }

            emit Withdraw(stakedValue, _stakeType, _id, stakeTypes[_stakeType].stakePeriod, usersStakes[msg.sender].eachUserStakes[_id].withdrawnReward);
        }
         userInfo[msg.sender][_id] = usersStakes[msg.sender].eachUserStakes[_id];


    }

    function rewardCalculation(uint128 _amount, uint128 _stakeType, uint128 _time) public view returns(uint128) {
        require(_amount > 0, "AMOUNT_SHOULD_BE_GREATER_THAN_ZERO");
        require(stakeTypeExist[_stakeType], "STAKE_TYPE_DOES_NOT_EXISTS");
        require(_time > 0, "INVALID_TIME");
        uint128 rate = stakeTypes[_stakeType].rewardRate;
        
        uint128 interest = (_amount * rate * 10 * _time) / (1000 * stakeTypes[_stakeType].stakePeriod);
        return interest;
        
    }

    function claimReward(address to, uint128 _rewardAmount) internal {
        require(to != address(0), "INVALID_CLAIMER");
        require(_rewardAmount > 0, "INVALID_REWARD_AMOUNT");
        uint128 ownerBal = uint128(stakedToken.balanceOf(ownerWallet));
        if(_rewardAmount > ownerBal) claimAndWithdrawFreeze = true;
        require(!claimAndWithdrawFreeze, "CLAIM_AND_WITHDRAW_FREEZED");
        bool success = stakedToken.transferFrom(ownerWallet, to, _rewardAmount);
        if(!success) revert();
        

    }

    function compound(uint128 _stakeType, uint128 _id) external nonReentrant{
        uint128 valueStaked = usersStakes[msg.sender].eachUserStakes[_id].stakeAmount;
        require(valueStaked > 0, "NOTHING_AT_STAKE");

        uint128 _initialDeposit = usersStakes[msg.sender].eachUserStakes[_id].initialDeposit;

        uint128 _lastClaimTime = usersStakes[msg.sender].eachUserStakes[_id].lastClaimTime;

        if(_lastClaimTime != usersStakes[msg.sender].eachUserStakes[_id].claimTimeInitialized) {
            _initialDeposit = valueStaked;
        }
        // require(_lastClaimTime <= usersStakes[msg.sender].eachUserStakes[_id].fullWithdrawlTime, "ALL_CLAIMED");

        uint128 _withdrawlTime = usersStakes[msg.sender].eachUserStakes[_id].withdrawlTime;
        require(_withdrawlTime==0, "ALREADY_WITHDRAWN");

        // uint256 withdrawFees = stakeTypes[_stakeType].withdrawlFees;
        // if( withdrawFees !=0 ) {
        //     uint256 fees = valueStaked * withdrawFees * 10 / 1000;
        //     valueStaked = valueStaked - fees;
        // }
        uint128 _fullWithdrawlTime = usersStakes[msg.sender].eachUserStakes[_id].fullWithdrawlTime;
        if (uint128(block.timestamp) < _fullWithdrawlTime) {
            usersStakes[msg.sender].eachUserStakes[_id].lastClaimTime = uint128(block.timestamp);
            uint128 claimTimeCheck = usersStakes[msg.sender].eachUserStakes[_id].lastClaimTime - _lastClaimTime   ;
            

            require(claimTimeCheck > 0, "ALL_COMPOUNDED");
            
            
            uint128 rewardValue = rewardCalculation(valueStaked, _stakeType, claimTimeCheck);
            usersStakes[msg.sender].eachUserStakes[_id].stakeAmount += rewardValue;
            userTotalPerPool[msg.sender][_stakeType] +=  rewardValue;
            totalStaked +=rewardValue;
            
            usersStakes[msg.sender].eachUserStakes[_id].withdrawnReward += rewardValue;
            stakeTypes[_stakeType].totalStakedIn += rewardValue;
            //compound reward = withdrawn reward
            claimReward(address(this), rewardValue);
            
            emit Compound(rewardValue, _stakeType, _id);
        } else {
            usersStakes[msg.sender].eachUserStakes[_id].lastClaimTime = _fullWithdrawlTime;
            uint128 claimTimeCheck = usersStakes[msg.sender].eachUserStakes[_id].lastClaimTime - _lastClaimTime;
            
            require(claimTimeCheck > 0, "ALL_COMPOUNDED");
            
            uint128 rewardValue = rewardCalculation(valueStaked, _stakeType, claimTimeCheck);
            usersStakes[msg.sender].eachUserStakes[_id].stakeAmount += rewardValue;
            userTotalPerPool[msg.sender][_stakeType] +=  rewardValue;
            totalStaked +=rewardValue;
            
            usersStakes[msg.sender].eachUserStakes[_id].withdrawnReward += rewardValue;
            stakeTypes[_stakeType].totalStakedIn += rewardValue; 
            
            claimReward(address(this), rewardValue);
            
            emit Compound(rewardValue, _stakeType, _id);
        }

        userInfo[msg.sender][_id] = usersStakes[msg.sender].eachUserStakes[_id];

    }

    function claim(uint128 _stakeType, uint128 _id) external nonReentrant {
        uint128 valueStaked = usersStakes[msg.sender].eachUserStakes[_id].stakeAmount;
        require(valueStaked > 0, "NOTHING_AT_STAKE");

        uint128 _initialDeposit = usersStakes[msg.sender].eachUserStakes[_id].initialDeposit;

        uint128 _lastClaimTime = usersStakes[msg.sender].eachUserStakes[_id].lastClaimTime;

        if(_lastClaimTime != usersStakes[msg.sender].eachUserStakes[_id].claimTimeInitialized) {
            _initialDeposit = valueStaked;
        }
        // require(_lastClaimTime <= usersStakes[msg.sender].eachUserStakes[_id].fullWithdrawlTime, "ALL_CLAIMED");

        uint128 _withdrawlTime = usersStakes[msg.sender].eachUserStakes[_id].withdrawlTime;
        require(_withdrawlTime==0, "ALREADY_WITHDRAWN");

        // uint256 withdrawFees = stakeTypes[_stakeType].withdrawlFees;
        // if( withdrawFees !=0 ) {
        //     uint256 fees = valueStaked * withdrawFees * 10 / 1000;
        //     valueStaked = valueStaked - fees;
        // }
        uint128 _fullWithdrawlTime = usersStakes[msg.sender].eachUserStakes[_id].fullWithdrawlTime;
        if (uint128(block.timestamp) < _fullWithdrawlTime) {
            usersStakes[msg.sender].eachUserStakes[_id].lastClaimTime = uint128(block.timestamp);
            uint128 claimTimeCheck = usersStakes[msg.sender].eachUserStakes[_id].lastClaimTime - _lastClaimTime   ;
            

            require(claimTimeCheck > 0, "ALL_CLAIMED");
            
            
            uint128 rewardValue = rewardCalculation(valueStaked, _stakeType, claimTimeCheck);
            // usersStakes[msg.sender].eachUserStakes[_id].stakeAmount += rewardValue;
            // totalStaked +=rewardValue;
            
            usersStakes[msg.sender].eachUserStakes[_id].withdrawnReward += rewardValue;
            // stakeTypes[_stakeType].totalStakedIn += rewardValue;
            //compound reward = withdrawn reward
            claimReward(msg.sender, rewardValue);
            
            emit Claim(rewardValue, _stakeType, _id);
        } else {
            usersStakes[msg.sender].eachUserStakes[_id].lastClaimTime = _fullWithdrawlTime;
            uint128 claimTimeCheck = usersStakes[msg.sender].eachUserStakes[_id].lastClaimTime - _lastClaimTime;
            
            require(claimTimeCheck > 0, "ALL_CLAIMED");
            
            uint128 rewardValue = rewardCalculation(valueStaked, _stakeType, claimTimeCheck);
            // usersStakes[msg.sender].eachUserStakes[_id].stakeAmount += rewardValue;
            // totalStaked +=rewardValue;
            
            usersStakes[msg.sender].eachUserStakes[_id].withdrawnReward += rewardValue;
            // stakeTypes[_stakeType].totalStakedIn += rewardValue; 
            
            claimReward(msg.sender, rewardValue);
            
            emit Claim(rewardValue, _stakeType, _id);
        }

        userInfo[msg.sender][_id] = usersStakes[msg.sender].eachUserStakes[_id];

    }

    function addStakedType(uint128 _stakeType, uint128 _stakePeriod, uint128 _depositFees, uint128 _withdrawlFees, uint128 _rewardRate) external onlyOwner {
        require(!stakeTypeExist[_stakeType], "STAKE_TYPE_EXISTS");
        require(_depositFees < 100 && _withdrawlFees < 100, "FEES_CANNOT_BE_EQUAL_OR_MORE_THAN_100");
        require(_rewardRate > 0, "INTEREST_RATE_CANNOT_BE_ZERO");
        stakeTypeExist[_stakeType] = true;
        stakeTypes[_stakeType].stakePeriod = _stakePeriod;
        stakeTypes[_stakeType].depositFees = _depositFees;
        stakeTypes[_stakeType].withdrawlFees = _withdrawlFees;
        stakeTypes[_stakeType].rewardRate = _rewardRate;
        totalPoolTypes++;

    }

    function getPoolData(uint128 _stakeType) external view returns(uint128 _stakePeriod, uint128 _depositFees, uint128 _withdrawlFees, uint128 _rewardRate, uint128 _totalStakedIn) {
        require(stakeTypeExist[_stakeType], "INVALID_STAKE_TYPE");
        _stakePeriod = stakeTypes[_stakeType].stakePeriod;
        _depositFees = stakeTypes[_stakeType].depositFees;
        _withdrawlFees = stakeTypes[_stakeType].withdrawlFees;
        _rewardRate = stakeTypes[_stakeType].rewardRate;
        _totalStakedIn = stakeTypes[_stakeType].totalStakedIn;

    }

    function rewardWithdrawn(address _user, uint128 _id) external view returns(uint128) {
        return usersStakes[_user].eachUserStakes[_id].withdrawnReward;
    }

    // function transferOwnership(address newOwner) external onlyOwner {
    //     require(newOwner != address(0), "OWNER_CANT_BE_ZERO_ADDRESS");
    //     owner = newOwner;
    // }

    function getUserDeposits(address _user) public view returns(DetailsLibrary.eachTransaction[] memory){
                uint128 totalDeposits = usersStakes[_user].noOfDeposits;
                DetailsLibrary.eachTransaction[] memory eachDepositData = new DetailsLibrary.eachTransaction[](totalDeposits);
                DetailsLibrary.eachTransaction memory dataInstance;
                
                uint128 j;
            
                for (uint128 i=1; i<=totalDeposits; i++) {
                        
                        dataInstance = usersStakes[_user].eachUserStakes[i];
                        eachDepositData[j] = (DetailsLibrary.eachTransaction(dataInstance.txId, dataInstance.initialDeposit, dataInstance.stakeAmount, 
                                                                dataInstance.depositTime, dataInstance.fullWithdrawlTime, dataInstance.withdrawlTime, 
                                                                dataInstance.lastClaimTime, dataInstance.claimTimeInitialized, dataInstance.withdrawnReward, 
                                                                dataInstance.claimed));
                        j++;
                }
                return eachDepositData;

    }



    // function getEndBlockNo(address _user, uint128 _id) external view returns(uint128 _withdrawlBlockNo) {
    //     uint128 blocksMinted = (usersStakes[_user].eachUserStakes[_id].fullWithdrawlTime - usersStakes[_user].eachUserStakes[_id].depositTime) / 12 ;
    //     _withdrawlBlockNo = blocksMinted + usersStakes[_user].eachUserStakes[_id].depositBlockNo;
    // }

    
    // function emergencyWithdraw(uint256 _stakeType, uint256 _id) external {
    //     uint256 emergencyFund = usersStakes[msg.sender].eachUserStakes[_id].stakeAmount;
    //     require(emergencyFund > 0, "NO_FUND_TO_WITHDRAW");
    //     uint256 fee = stakeTypes[_stakeType].withdrawlFees;
    //     usersStakes[msg.sender].eachUserStakes[_id].stakeAmount = 0;
    //     usersStakes[msg.sender].eachUserStakes[_id].claimed = true;
    //     usersStakes[msg.sender].eachUserStakes[_id].withdrawlTime = block.timestamp;

    //     if(fee !=0) {
    //         uint256 feeAmount = emergencyFund * fee * 10 / 1000;
    //         uint256 actualFund = emergencyFund - feeAmount;
    //         stakedToken.transfer(ownerWallet, feeAmount);
    //         bool success = stakedToken.transfer(msg.sender, actualFund);
    //         if(!success) revert();
    //     } else {
    //         bool success = stakedToken.transfer(msg.sender, emergencyFund);
    //         if(!success) revert();
    //     }
    //     userInfo[msg.sender][_id] = usersStakes[msg.sender].eachUserStakes[_id];
        
    // }

}
// File: contracts/StakingProxy.sol


pragma solidity >=0.7.0 <0.9.0;


contract StakingProxy {
    
    bytes32 private constant master = keccak256("com.saitama.proxy.master");
    bytes32 private constant proxyOwnerPosition = keccak256("com.saitama.proxy.owner");
   
    // constructor() {
    //     setProxyOwner(msg.sender);
    // }


    function setProxyOwner(address newProxyOwner) external  {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, newProxyOwner)
        }
    }

    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }

    function setImplementation(address _newImplementation) public {
        // require(proxyOwner() == msg.sender, "INVALID_ADMIN");
        bytes32 position = master;
        assembly {
            sstore(position, _newImplementation)
        }
    }

    function implementation() public view returns (address impl) {
        bytes32 position = master;
        assembly {
            impl := sload(position)
        }
    }
    


    fallback() external payable {
        address _impl = implementation();
            assembly 
                {
                let ptr := mload(0x40)

                // (1) copy incoming call data
                calldatacopy(ptr, 0, calldatasize())

                // (2) forward call to logic contract
                let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
                let size := returndatasize()

                // (3) retrieve return data
                returndatacopy(ptr, 0, size)

                // (4) forward return data back to caller
                switch result
                case 0 { revert(ptr, size) }
                default { return(ptr, size) }
                }
    }
}