// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/ISynthToken.sol";
import "../interfaces/IHelixToken.sol";
import "../interfaces/IHelixChefNFT.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// Lock helixToken and earn synthToken. Longer lock durations and staking nfts increases rewards. 
contract SynthReactor is 
    Initializable,
    OwnableUpgradeable, 
    PausableUpgradeable, 
    ReentrancyGuardUpgradeable
{
    struct User {
        uint256[] depositIndices;       // indices of all deposits opened by the user
        uint256 depositedHelix;         // sum of all unwithdrawn deposits
        uint256 weightedDeposits;       // sum of all unwithdrawn deposits modified by weight
        uint256 shares;                 // weightedDeposits modified by stakedNfts
        uint256 rewardDebt;             // used for calculating rewards
    }

    struct Deposit {
        address depositor;              // user making the deposit
        uint256 amount;                 // amount of deposited helix
        uint256 weight;                 // weight based on lock duration
        uint256 depositTimestamp;       // when the deposit was made
        uint256 unlockTimestamp;        // when the deposit can be unlocked
        bool withdrawn;                 // only true if the deposit has been withdrawn
    }
    
    struct LockModifier {
        uint256 duration;               // length of time a deposit will be locked (in seconds)
        uint256 weight;                 // modifies the reward based on the lock duration
    }

    /// Maps a user's address to a User
    mapping(address => User) public users;

    /// Maps depositIndices to a Deposit
    Deposit[] public deposits;

    /// Owner-curated list of valid deposit durations and associated weights
    LockModifier[] public lockModifiers;

    /// Token locked in the reactor
    address public helixToken;

    /// Token rewarded by the reactor
    address public synthToken;

    /// Contract the reactor references for stakedNfts
    address public nftChef;

    /// Last block that update was called
    uint256 public lastUpdateBlock;

    /// Used for calculating rewards
    uint256 public accTokenPerShare;
    uint256 private constant _REWARD_PRECISION = 1e19;
    uint256 private constant _WEIGHT_PRECISION = 100;
    
    /// Amount of synthToken to mint per block
    uint256 public synthToMintPerBlock;

    /// Sum of shares held by all users
    uint256 public totalShares;

    event Lock(
        address user, 
        uint256 depositId, 
        uint256 weight, 
        uint256 unlockTimestamp,
        uint256 depositedHelix,
        uint256 weightedDeposits,
        uint256 shares,
        uint256 totalShares
    );
    event Unlock(
        address user,
        uint256 depositIndex,
        uint256 depositedHelix,
        uint256 weightedDeposits,
        uint256 shares,
        uint256 totalShares
    );
    event UpdateUserStakedNfts(
        address user,
        uint256 stakedNfts,
        uint256 userShares,
        uint256 totalShares
    );
    event HarvestReward(address user, uint256 reward, uint256 rewardDebt);
    event UpdatePool(uint256 accTokenPerShare, uint256 lastUpdateBlock);
    event SetNftChef(address nftChef);
    event SetSynthToMintPerBlock(uint256 synthToMintPerBlock);
    event SetLockModifier(uint256 lockModifierIndex, uint256 duration, uint256 weight);
    event AddLockModifier(uint256 duration, uint256 weight, uint256 lockModifiersLength);
    event RemoveLockModifier(uint256 lockModifierIndex, uint256 lockModifiersLength);
    event EmergencyWithdrawErc20(address token, uint256 amount);

    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "invalid address");
        _;
    }

    modifier onlyValidDepositIndex(uint256 _depositIndex) {
        require(_depositIndex < deposits.length, "invalid deposit index");
        _;
    }

    modifier onlyValidLockModifierIndex(uint256 lockModifierIndex) {
        require(lockModifierIndex < lockModifiers.length, "invalid lock modifier index");
        _;
    }

    modifier onlyValidDuration(uint256 _duration) {
        require(_duration > 0, "invalid duration");
        _;
    }

    modifier onlyValidWeight(uint256 _weight) {
        require(_weight > 0, "invalid weight");
        _;
    }

    modifier onlyValidAmount(uint256 _amount) {
        require(_amount > 0, "invalid amount");
        _;
    }

    modifier onlyNftChef() {
        require(msg.sender == nftChef, "caller is not nftChef");
        _;
    }

    function initialize(
        address _helixToken,
        address _synthToken,
        address _nftChef
    ) 
        external 
        initializer 
        onlyValidAddress(_helixToken)
        onlyValidAddress(_synthToken)
        onlyValidAddress(_nftChef)
    {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        helixToken = _helixToken;
        synthToken = _synthToken;
        nftChef = _nftChef;

        synthToMintPerBlock = 135 * 1e17;   // 13.5

        lastUpdateBlock = block.number;

        // default locked deposit durations and their weights
        lockModifiers.push(LockModifier(90 days, 5));
        lockModifiers.push(LockModifier(180 days, 10));
        lockModifiers.push(LockModifier(360 days, 30));
        lockModifiers.push(LockModifier(540 days, 50));
        lockModifiers.push(LockModifier(720 days, 100));
    }

    /// Create a new deposit and lock _amount of helixToken for _lockModifierIndex duration
    function lock(uint256 _amount, uint256 _lockModifierIndex) 
        external 
        whenNotPaused
        nonReentrant
        onlyValidAmount(_amount) 
        onlyValidLockModifierIndex(_lockModifierIndex) 
    {
        _harvestReward(msg.sender);

        User storage user = users[msg.sender];

        uint256 depositIndex = deposits.length;
        user.depositIndices.push(depositIndex);

        user.depositedHelix += _amount;

        uint256 weight = lockModifiers[_lockModifierIndex].weight;
        user.weightedDeposits += _getWeightedDepositIncrement(_amount, weight);

        uint256 stakedNfts = _getUserStakedNfts(msg.sender);
        uint256 prevShares = user.shares;
        uint256 shares = _getShares(user.weightedDeposits, stakedNfts);

        assert(shares >= prevShares);
        totalShares += shares - prevShares;

        user.shares = shares;
        user.rewardDebt = shares * accTokenPerShare / _REWARD_PRECISION;
         
        uint256 unlockTimestamp = block.timestamp + lockModifiers[_lockModifierIndex].duration;
        deposits.push(
            Deposit({
                depositor: msg.sender, 
                amount: _amount,
                weight: weight,
                depositTimestamp: block.timestamp,
                unlockTimestamp: unlockTimestamp,
                withdrawn: false
            })
        );

        TransferHelper.safeTransferFrom(helixToken, msg.sender, address(this), _amount);

        emit Lock(
            msg.sender, 
            depositIndex, 
            weight,
            unlockTimestamp,
            user.depositedHelix, 
            user.weightedDeposits,
            user.shares,
            totalShares
        );
    }

    /// Unlock a deposit based on _depositIndex and return the caller's locked helixToken
    function unlock(uint256 _depositIndex) 
        external 
        whenNotPaused 
        nonReentrant 
        onlyValidDepositIndex(_depositIndex)
    {
        _harvestReward(msg.sender);

        Deposit storage deposit = deposits[_depositIndex];
        require(msg.sender == deposit.depositor, "caller is not depositor");
        require(block.timestamp >= deposit.unlockTimestamp, "deposit is locked");

        User storage user = users[msg.sender];
    
        uint256 amount = deposit.amount;
        user.depositedHelix -= amount;
        user.weightedDeposits -= _getWeightedDepositIncrement(amount, deposit.weight);

        uint256 stakedNfts = _getUserStakedNfts(msg.sender);
        uint256 prevShares = user.shares;
        uint256 shares = _getShares(user.weightedDeposits, stakedNfts);

        assert(prevShares >= shares);
        totalShares -= prevShares - shares;

        user.shares = shares;
        user.rewardDebt = shares * accTokenPerShare / _REWARD_PRECISION;

        deposit.withdrawn = true;

        TransferHelper.safeTransfer(helixToken, msg.sender, amount);

        emit Unlock(
            msg.sender, 
            _depositIndex,
            user.depositedHelix,
            user.weightedDeposits,
            user.shares,
            totalShares
        );
    }

    /// Return the _user's pending synthToken reward
    function getPendingReward(address _user) 
        external
        view 
        onlyValidAddress(_user)
        returns (uint256)
    {
        uint256 _accTokenPerShare = accTokenPerShare;
        if (block.number > lastUpdateBlock) {
            _accTokenPerShare += _getAccTokenPerShareIncrement();
        }
        User memory user = users[_user];     
        uint256 toMint = user.shares * _accTokenPerShare / _REWARD_PRECISION;
        return toMint > user.rewardDebt ? toMint - user.rewardDebt : 0;
    }

    /// Update user and contract shares when the user stakes or unstakes nfts
    function updateUserStakedNfts(address _user, uint256 _stakedNfts) 
        external 
        onlyNftChef 
        nonReentrant
    {
        // Do nothing if the user has no open deposits
        if (users[_user].depositedHelix <= 0) {
            return;
        }

        _harvestReward(_user);

        User storage user = users[_user];
        uint256 prevShares = user.shares;
        uint256 shares = _getShares(user.weightedDeposits, _stakedNfts);

        if (shares >= prevShares) {
            // if the user has increased their stakedNfts
            totalShares += shares - prevShares;
        } else {
            // if the user has decreased their staked nfts
            totalShares -= prevShares - shares;
        }

        user.shares = shares;
        user.rewardDebt = shares * accTokenPerShare / _REWARD_PRECISION;

        emit UpdateUserStakedNfts(_user, _stakedNfts, user.shares, totalShares);
    }

    /// Set the amount of synthToken to mint per block
    function setSynthToMintPerBlock(uint256 _synthToMintPerBlock) external onlyOwner {
        synthToMintPerBlock = _synthToMintPerBlock;
        emit SetSynthToMintPerBlock(_synthToMintPerBlock);
    }
    
    /// Set a lockModifierIndex's _duration and _weight pair
    function setLockModifier(uint256 _lockModifierIndex, uint256 _duration, uint256 _weight)
        external
        onlyOwner
        onlyValidLockModifierIndex(_lockModifierIndex)
        onlyValidDuration(_duration)
        onlyValidWeight(_weight)  
    {
        lockModifiers[_lockModifierIndex].duration = _duration;
        lockModifiers[_lockModifierIndex].weight = _weight;
        emit SetLockModifier(_lockModifierIndex, _duration, _weight);
    }
   
    /// Add a new _duration and _weight pair
    function addLockModifier(uint256 _duration, uint256 _weight) 
        external 
        onlyOwner
        onlyValidDuration(_duration) 
        onlyValidWeight(_weight)
    {
        lockModifiers.push(LockModifier(_duration, _weight));
        emit AddLockModifier(_duration, _weight, lockModifiers.length);
    }

    /// Remove an existing _duration and _weight pair by _lockModifierIndex
    function removeLockModifier(uint256 _lockModifierIndex) 
        external 
        onlyOwner
        onlyValidLockModifierIndex(_lockModifierIndex)
    {
        // remove by array shift to preserve order
        uint256 length = lockModifiers.length - 1;
        for (uint256 i = _lockModifierIndex; i < length; i++) {
            lockModifiers[i] = lockModifiers[i + 1];
        }
        lockModifiers.pop();
        emit RemoveLockModifier(_lockModifierIndex, lockModifiers.length);
    }

    /// Set the _nftChef contract that the reactor uses to get a user's stakedNfts
    function setNftChef(address _nftChef) external onlyOwner onlyValidAddress(_nftChef) {
        nftChef = _nftChef;
        emit SetNftChef(_nftChef);
    }

    /// Pause the reactor and prevent user interaction
    function pause() external onlyOwner {
        _pause();
    }

    /// Unpause the reactor and allow user interaction
    function unpause() external onlyOwner {
        _unpause();
    }

    /// Withdraw all the tokens in this contract. Emergency ONLY
    function emergencyWithdrawErc20(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        emit EmergencyWithdrawErc20(_token, amount); 
        TransferHelper.safeTransfer(_token, msg.sender, amount);
    }

    // Return the user's array of depositIndices
    function getUserDepositIndices(address _user) external view returns (uint[] memory) {
        return users[_user].depositIndices;
    }

    /// Return the length of the lockModifiers array
    function getLockModifiersLength() external view returns (uint256) {
        return lockModifiers.length;
    }

    /// Return the length of the deposits array
    function getDepositsLength() external view returns (uint256) {
        return deposits.length;
    }

    /// Harvest rewards accrued in synthToken by the caller's deposits
    function harvestReward() 
        external
    {
        _harvestReward(msg.sender);
    }

    /// Update the pool
    function updatePool() public {
        if (block.number <= lastUpdateBlock) {
            return;
        }

        accTokenPerShare += _getAccTokenPerShareIncrement();
        lastUpdateBlock = block.number;
        emit UpdatePool(accTokenPerShare, lastUpdateBlock);
    }

    // Harvest rewards accrued in synthToken by the _caller's deposits
    function _harvestReward(address _caller) private {
        if (paused()) {
            return;
        }

        updatePool();

        User storage user = users[_caller];

        uint256 reward = user.shares * accTokenPerShare / _REWARD_PRECISION;
        uint256 toMint = reward > user.rewardDebt ? reward - user.rewardDebt : 0;
        user.rewardDebt = reward;

        emit HarvestReward(_caller, toMint, user.rewardDebt);
        if (toMint > 0) {
            bool success = ISynthToken(synthToken).mint(_caller, toMint);
            require(success, "harvest reward failed");
        }
    }

    // Return the _user's stakedNfts
    function _getUserStakedNfts(address _user) private view returns (uint256) {
        return IHelixChefNFT(nftChef).getUserStakedNfts(_user); 
    }

    // Return the amount to increment the accTokenPerShare by
    function _getAccTokenPerShareIncrement() private view returns (uint256) {
        if (totalShares == 0) {
            return 0;
        }
        uint256 blockDelta = block.number - lastUpdateBlock;
        return blockDelta * synthToMintPerBlock * _REWARD_PRECISION / totalShares;
    }

    // Return the deposit _amount weighted by _weight
    function _getWeightedDepositIncrement(uint256 _amount, uint256 _weight) 
        private 
        pure 
        returns (uint256) 
    {
        return _amount * (_WEIGHT_PRECISION + _weight) / _WEIGHT_PRECISION;
    }

    // Return the shares held by a user with _weightedDeposit and _stakedNfts
    function _getShares(uint256 _weightedDeposit, uint256 _stakedNfts) private pure returns (uint256) {   
        if (_stakedNfts <= 0) {
            return _weightedDeposit;
        }
        if (_stakedNfts <= 2) {
            return _weightedDeposit * 15 / 10;
        }
        else {
            return _weightedDeposit * 2;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface ISynthToken {
    function mint(address to, uint256 amount) external returns(bool);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IHelixToken {
    function mint(address to, uint256 amount) external returns(bool);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IHelixNFT.sol";
import "./IHelixToken.sol";

interface IHelixChefNFT {
    function helixNFT() external view returns (IHelixNFT helixNFT);
    function helixToken() external view returns (IHelixToken helixToken);
    function initialize(address _helixNFT, address _helixToken, address feeMinter) external;
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
    function users(address _user) external view returns (
        uint256[] memory stakedNFTsId, 
        uint256 accruedReward,
        uint256 rewardDebt,
        uint256 stakedNfts
    );
    function getUserStakedNfts(address _user) external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
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
pragma solidity >= 0.8.0;

interface IHelixNFT {
    function setIsStaked(uint256 tokenId, bool isStaked) external;
    function getInfoForStaking(uint256 tokenId) external view returns(address tokenOwner, bool isStaked, uint256 wrappedNFTs);
   
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