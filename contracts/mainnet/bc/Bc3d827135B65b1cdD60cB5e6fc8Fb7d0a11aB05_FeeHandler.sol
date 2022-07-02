// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../libraries/Percent.sol";
import "../timelock/OwnableTimelockUpgradeable.sol";

import "../interfaces/IHelixChefNFT.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// Handles routing received fees to internal contracts
contract FeeHandler is Initializable, OwnableUpgradeable, OwnableTimelockUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Emitted when a new treasury address is set by the owner
    event SetTreasury(address indexed setter, address _treasury);

    // Emitted when a new nftChef address is set by the owner
    event SetNftChef(address indexed setter, address _nftChef);

    // Emitted when a new nftChef percent is set by the owner
    event SetDefaultNftChefPercent(address indexed setter, uint256 _defaultNftChefPercent);

    event AddFeeCollector(address indexed setter, address indexed feeCollector);
    event RemoveFeeCollector(address indexed setter, address indexed feeCollector);

    // Emitted when a new nftChef percent relating to a particular source is set by the owner
    event SetNftChefPercents(
        address indexed setter, 
        address indexed source,
        uint256 _nftChefPercent
    );

    // Emitted when fees are transferred by the handler
    event TransferFee(
        address indexed token,
        address indexed from,
        address indexed rewardAccruer,
        address nftChef,
        address treasury,
        uint256 fee,
        uint256 nftChefAmount,
        uint256 treasuryAmount
    );

    /// Thrown when attempting to transfer a fee of 0
    error ZeroFee();

    /// Thrown when address(0) is encountered
    error ZeroAddress();

    error NotFeeCollector(address _feeCollector);
    error AlreadyFeeCollector(address _feeCollector);

    /// Thrown when this contract's balance of token is less than amount
    error InsufficientBalance(address token, uint256 amount);

    address public helixToken;

    /// Owner defined fee recipient
    address public treasury;

    /// Owner defined pool where fees can be staked
    IHelixChefNFT public nftChef;

    /// Determines default percentage of collector fees sent to nftChef
    uint256 public defaultNftChefPercent;

    /// Maps contract address to individual nftChef collector fee percents
    mapping(address => uint256) public nftChefPercents;

    /// Maps contrct address to true if address has nftChefPercent set and false otherwise
    mapping(address => bool) public hasNftChefPercent;

    /// Maps address to true if address is registered as a feeCollector and false otherwise
    mapping(address => bool) public isFeeCollector;
    
    modifier onlyValidFee(uint256 _fee) {
        require(_fee > 0, "FeeHandler: zero fee");
        _;
    }

    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "FeeHandler: zero address");
        _;
    }

    modifier onlyValidPercent(uint256 _percent) {
        require(Percent.isValidPercent(_percent), "FeeHandler: percent exceeds max");
        _;
    } 

    modifier onlyFeeCollector(address _feeCollector) {
        if (!isFeeCollector[_feeCollector]) revert NotFeeCollector(_feeCollector);
        _;
    }

    modifier notFeeCollector(address _feeCollector) {
        if (isFeeCollector[_feeCollector]) revert AlreadyFeeCollector(_feeCollector);
        _;
    }

    modifier hasBalance(address _token, uint256 _amount) {
        if (IERC20Upgradeable(_token).balanceOf(address(this)) < _amount) {
            revert InsufficientBalance(_token, _amount);
        }
        _;
    }

    function initialize(
        address _treasury, 
        address _nftChef, 
        address _helixToken, 
        uint256 _defaultNftChefPercent
    ) external initializer {
        __Ownable_init();
        __OwnableTimelock_init();
        treasury = _treasury;
        nftChef = IHelixChefNFT(_nftChef);
        helixToken = _helixToken;
        defaultNftChefPercent = _defaultNftChefPercent;
    }
    
    /// Called by a FeeCollector to send _amount of _token to this FeeHandler
    /// handles sending fees to treasury and staking with nftChef
    function transferFee(
        address _token, 
        address _from, 
        address _rewardAccruer, 
        uint256 _fee
    ) 
        external 
        onlyValidFee(_fee) 
    {
        (uint256 nftChefAmount, uint256 treasuryAmount) = getNftChefAndTreasuryAmounts(_token, _fee);
        
        if (nftChefAmount > 0) {
            IERC20Upgradeable(_token).safeTransferFrom(_from, address(nftChef), nftChefAmount);
            nftChef.accrueReward(_rewardAccruer, nftChefAmount);
        }

        if (treasuryAmount > 0) {
            IERC20Upgradeable(_token).safeTransferFrom(_from, treasury, treasuryAmount);
        }

        emit TransferFee(
            address(_token),
            _from,
            _rewardAccruer,
            address(nftChef),
            treasury,
            _fee,
            nftChefAmount,
            treasuryAmount
        );
    }

    /// Called by the owner to set a new _treasury address
    function setTreasury(address _treasury) external onlyTimelock onlyValidAddress(_treasury) { 
        treasury = _treasury;
        emit SetTreasury(msg.sender, _treasury);
    }

    /// Called by the owner to set a new _nftChef address
    function setNftChef(address _nftChef) 
        external 
        onlyOwner
        onlyValidAddress(_nftChef) 
    {
        nftChef = IHelixChefNFT(_nftChef);
        emit SetNftChef(msg.sender, _nftChef);
    }

    /// Called by the owner to set the _defaultNftChefPercent taken from the total collector fees
    /// and staked with the nftChef
    function setDefaultNftChefPercent(uint256 _defaultNftChefPercent) 
        external 
        onlyOwner 
        onlyValidPercent(_defaultNftChefPercent) 
    {
        defaultNftChefPercent = _defaultNftChefPercent;
        emit SetDefaultNftChefPercent(msg.sender, _defaultNftChefPercent);
    }

    /// Called by the owner to set the _nftChefPercent taken from the total collector fees
    /// when the fee is received from _source and staked with the nftChef
    function setNftChefPercent(address _source, uint256 _nftChefPercent) 
        external
        onlyOwner
        onlyValidPercent(_nftChefPercent)
    {
        nftChefPercents[_source] = _nftChefPercent;
        hasNftChefPercent[_source] = true;
        emit SetNftChefPercents(msg.sender, _source, _nftChefPercent);
    }

    /// Called by the owner to register a new _feeCollector
    function addFeeCollector(address _feeCollector) 
        external 
        onlyOwner 
        onlyValidAddress(_feeCollector) 
        notFeeCollector(_feeCollector)
    {
        isFeeCollector[_feeCollector] = true;
        emit AddFeeCollector(msg.sender, _feeCollector);
    }

    /// Called by the owner to remove a registered _feeCollector
    function removeFeeCollector(address _feeCollector)
        external
        onlyOwner
        onlyFeeCollector(_feeCollector)
    {
        isFeeCollector[_feeCollector] = false;
        emit RemoveFeeCollector(msg.sender, _feeCollector);
    }

    /// Return the nftChef fee computed from the _amount and the _caller's nftChefPercent
    function getNftChefFee(address _caller, uint256 _amount) external view returns (uint256 nftChefFee) {
        uint256 nftChefPercent = hasNftChefPercent[_caller] ? nftChefPercents[_caller] : defaultNftChefPercent;
        nftChefFee = _getFee(_amount, nftChefPercent);
    }

    /// Split _amount based on _caller's nftChef percent and return the nftChefFee and the remainder
    /// where remainder == _amount - nftChefFee
    function getNftChefFeeSplit(address _caller, uint256 _amount)
        external 
        view
        returns (uint256 nftChefFee, uint256 remainder)
    {
        uint256 nftChefPercent = hasNftChefPercent[_caller] ? nftChefPercents[_caller] : defaultNftChefPercent;
        (nftChefFee, remainder) = _getSplit(_amount, nftChefPercent);
    }

    /// Return the amounts to send to the nft chef and treasury based on the _fee and _token
    function getNftChefAndTreasuryAmounts(address _token, uint256 _fee) 
        public
        view 
        returns (uint256 nftChefAmount, uint256 treasuryAmount)
    {
        if (_token == helixToken) {
            uint256 nftChefPercent = hasNftChefPercent[msg.sender] ? nftChefPercents[msg.sender] : defaultNftChefPercent;
            (nftChefAmount, treasuryAmount) = _getSplit(_fee, nftChefPercent);
        } else {
            treasuryAmount = _fee;
        }
    }

    /// Return the fee computed from the _amount and the _percent
    function _getFee(uint256 _amount, uint256 _percent) 
        private 
        pure 
        returns (uint256 fee) 
    {
        fee = Percent.getPercentage(_amount, _percent);
    }

    /// Split _amount based on _percent and return the fee and the remainder
    /// where remainder == _amount - fee
    function _getSplit(uint256 _amount, uint256 _percent) 
        private 
        pure 
        returns (uint256 fee, uint256 remainder)
    {
        (fee, remainder) = Percent.splitByPercent(_amount, _percent);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

library Percent {
    uint256 public constant MAX_PERCENT = 100;

    modifier onlyValidPercent(uint256 _percent, uint256 _decimals) {
        require(_isValidPercent(_percent, _decimals), "Percent: invalid percent");
        _;
    }

    // Return true if the _percent is valid and false otherwise
    function isValidPercent(uint256 _percent)
        internal
        pure
        returns (bool)
    {
        return _isValidPercent(_percent, 0);
    }

    // Return true if the _percent with _decimals many decimals is valid and false otherwise
    function isValidPercent(uint256 _percent, uint256 _decimals)
        internal
        pure
        returns (bool)
    {
        return _isValidPercent(_percent, _decimals);
    }

    // Return true if the _percent with _decimals many decimals is valid and false otherwise
    function _isValidPercent(uint256 _percent, uint256 _decimals)
        private
        pure
        returns (bool)
    {
        return _percent <= MAX_PERCENT * 10 ** _decimals;
    }

    // Return _percent of _amount
    function getPercentage(uint256 _amount, uint256 _percent)
        internal 
        pure
        returns (uint256 percentage) 
    {
        percentage = _getPercentage(_amount, _percent, 0);
    }

    // Return _percent of _amount with _decimals many decimals
    function getPercentage(uint256 _amount, uint256 _percent, uint256 _decimals)
        internal 
        pure
        returns (uint256 percentage)
    {
        percentage =_getPercentage(_amount, _percent, _decimals);
    }

    // Return _percent of _amount with _decimals many decimals
    function _getPercentage(uint256 _amount, uint256 _percent, uint256 _decimals) 
        private
        pure
        onlyValidPercent(_percent, _decimals) 
        returns (uint256 percentage)
    {
        percentage = _amount * _percent / (MAX_PERCENT * 10 ** _decimals);
    }

    // Return _percent of _amount as the percentage and the remainder of _amount - percentage
    function splitByPercent(uint256 _amount, uint256 _percent) 
        internal 
        pure 
        returns (uint256 percentage, uint256 remainder) 
    {
        (percentage, remainder) = _splitByPercent(_amount, _percent, 0);
    }

    // Return _percent of _amount as the percentage and the remainder of _amount - percentage
    // with _decimals many decimals
    function splitByPercent(uint256 _amount, uint256 _percent, uint256 _decimals)
        internal 
        pure
        returns (uint256 percentage, uint256 remainder)
    {
        (percentage, remainder) = _splitByPercent(_amount, _percent, _decimals);
    }

    // Return _percent of _amount as the percentage and the remainder of _amount - percentage
    // with _decimals many decimals
    function _splitByPercent(uint256 _amount, uint256 _percent, uint256 _decimals)
        private
        pure
        onlyValidPercent(_percent, _decimals)
        returns (uint256 percentage, uint256 remainder)
    {
        percentage = _getPercentage(_amount, _percent, _decimals);
        remainder = _amount - percentage;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
abstract contract OwnableTimelockUpgradeable is Initializable, ContextUpgradeable {
    error CallerIsNotTimelockOwner();
    error ZeroTimelockAddress();

    address private _timelockOwner;

    event TimelockOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __OwnableTimelock_init() internal onlyInitializing {
        __OwnableTimelock_init_unchained();
    }

    function __OwnableTimelock_init_unchained() internal onlyInitializing {
        _transferTimelockOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyTimelock() {
        _checkTimelockOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function timelockOwner() public view virtual returns (address) {
        return _timelockOwner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkTimelockOwner() internal view virtual {
        if (timelockOwner() != _msgSender()) revert CallerIsNotTimelockOwner();
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceTimelockOwnership() public virtual onlyTimelock {
        _transferTimelockOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferTimelockOwnership(address newOwner) public virtual onlyTimelock {
        if (newOwner == address(0)) revert ZeroTimelockAddress();
        _transferTimelockOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferTimelockOwnership(address newOwner) internal virtual {
        address oldOwner = _timelockOwner;
        _timelockOwner = newOwner;
        emit TimelockOwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IHelixNFT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHelixChefNFT {
    function helixNFT() external view returns (IHelixNFT helixNFT);
    function rewardToken() external view returns (IERC20 rewardToken);
    function users(address _user) external view returns (uint256[] memory stakedNFTsId, uint256 pendingReward);
    function initialize(IHelixNFT _helixNFT, IERC20 _rewardToken) external;
    function stake(uint256[] memory _tokenIds) external;
    function unstake(uint256[] memory _tokenIds) external;
    function accrueReward(address _user, uint256 _fee) external;
    function withdrawRewardToken() external;
    function addAccruer(address _address) external;
    function removeAccruer(address _address) external;
    function pause() external;
    function unpause() external;
    function getAccruer(uint256 _index) external view returns (address accruer);
    function getUsersStakedWrappedNfts(address _user) external view returns(uint256 numStakedNfts);
    function pendingReward(address _user) external view returns (uint256 pendingReward);
    function getNumAccruers() external view returns (uint256 numAccruers);
    function getAccruedReward(address _user, uint256 _fee) external view returns (uint256 reward);
    function isAccruer(address _address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IHelixNFT {
    function setIsStaked(uint256 tokenId, bool isStaked) external;
    function getInfoForStaking(uint256 tokenId) external view returns(address tokenOwner, bool isStaked, uint256 wrappedNFTs);
   
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