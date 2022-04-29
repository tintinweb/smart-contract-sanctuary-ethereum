// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import './interfaces/KeeperCompatibleInterface.sol';
import './interfaces/IToken.sol';
import './helpers/SafeERC20Upgradeable.sol';
import './helpers/SafeCast.sol';
import './helpers/BaseUpgradeable.sol';

contract MediciPool is Initializable, BaseUpgradeable, KeeperCompatibleInterface {
    using SafeERC20Upgradeable for IERC20;
    using SafeCast for uint256;

    //** ============ Structs ============ */
    struct User {
        uint128 principle; //amount of deposited tokens
        uint128 shares; //balance to be deducted for rewards calculation
        uint256 lastActionTime; // last time user withdrew or deposited
    }

    struct PoolInfo {
        uint128 pooledTokens; //deposited tokens + rewards
        uint128 totalShares; // shares per token
        uint256 currentApr; // 2 decimals
        uint256 aprSlowdown; // 2 decimals
        uint256 minApr; // 2 decimals
        uint256 secondsBetweenRewards; // 3600 multiplier min 3600 (1hour) max 86400 (1 day)
        uint256 nextInterestTime; // time in seconds
        uint256 minimumDepositTime; // minimum time to stake without penalty
        uint256 secondsInDay; // 86400
        uint256 earlyPenalty; // 2 decimals
    }

    //** ============ Variables ============ */
    uint256 keeperTimelimit;
    uint256 constant decimals = 10**2;
    PoolInfo info;

    address poolToken; // Deposit token and reward token are the same
    address bonusToken; // Bonus reward token
    address teamVault; // Gnosis Safe or treasury address
    mapping(address => User) public userInfo;

    //** ============ Events ============ */
    event Deposit(address indexed account, uint256 poolTokenAmount);
    event Penalty(address indexed account, uint256 fee);
    event Performance(address indexed account, uint256 fee);
    event Withdraw(address indexed account, uint256 withdrawTokenAmount);
    event WithdrawReward(address indexed account, uint256 poolTokenAmount);
    event InterestAdded(
        uint256 interest,
        uint256 pooledTokens,
        uint256 currentApr,
        uint256 indexed time
    );

    //** ============ Modifiers ============ */

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), 'contract not allowed');
        require(msg.sender == tx.origin, 'proxy contract not allowed');
        _;
    }

    /**
     * @notice Modifer to update pool on withdraw and deposit functions.
     */
    modifier poolUpdater() {
        updatePool();
        _;
    }

    /** @dev updates the pool if the nextInterestTime is less then block.timestamp */
    function updatePool() public {
        if (block.timestamp < info.nextInterestTime) {
            return;
        }

        uint256 timesToPay = ((block.timestamp - info.nextInterestTime) /
            info.secondsBetweenRewards) + 1;

        uint256 timesPerDayReward = info.secondsInDay / info.secondsBetweenRewards;

        // Performance based compounding. TotalTokens * APR
        // The more deposits / withdraws the more compounding.
        // EX. 10000 tokens.
        // 10000 * 500 = 50000 / 36500 / timePerDayReward
        // The total amount to make each year is divided by 365 days and then divided by the amount of compounded daily

        // 100 * .8000 / 365 / 12
        // 1 rebase period on 100 = 0.018 tokens, so all 12, 0.219 and for 5 day they 1.1,
        uint256 interest = (((info.pooledTokens * info.currentApr) / decimals) /
            36500 /
            timesPerDayReward) * timesToPay;

        // Add to the amount of pooled tokens, this will then divide by the total shares of all our poolers.
        info.pooledTokens += interest.toUint128();
        info.nextInterestTime += info.secondsBetweenRewards * timesToPay;

        // 1 state update and 1 sload at max.
        if (info.aprSlowdown != 0) {
            uint256 nextApr = info.currentApr - info.aprSlowdown;
            if (nextApr >= info.minApr) info.currentApr = nextApr;
        }

        emit InterestAdded(interest, info.pooledTokens, info.currentApr, block.timestamp);
    }

    /** @dev Deposit MDCI to earn shares 
        @param _amount {uint256}
    */
    function deposit(uint256 _amount) external notContract whenNotPaused poolUpdater {
        require(_amount != 0, 'ZERO_AMOUNT');

        User storage user = userInfo[msg.sender];
        // Transfer first and then emit event.
        IERC20(poolToken).safeTransferFrom(address(msg.sender), address(this), _amount);
        emit Deposit(msg.sender, _amount);

        user.principle += _amount.toUint128();

        if (info.totalShares != 0) {
            // total shares / pooledTokens = % in shares user owns in pooled tokens AKA Users Pool Weight
            // userShares - 10 shares 100 tokens, 1 share = 10 tokens. 1 token = 0.1 shares
            uint256 sharesPerToken = (info.totalShares * 1e18) / info.pooledTokens;
            uint256 userShares = (_amount * sharesPerToken) / 1e18; //calculate user shares
            user.shares += userShares.toUint128();
            info.totalShares += userShares.toUint128();
        } else {
            info.totalShares = _amount.toUint128();
            user.shares = _amount.toUint128();
        }

        user.lastActionTime = block.timestamp;
        info.pooledTokens += _amount.toUint128();
    }

    /** @dev Withdraw a certain amount of principle 
        @param amount {uint256}
    */
    function withdrawPrinciple(uint256 amount) external notContract whenNotPaused poolUpdater {
        User storage user = userInfo[msg.sender];

        // Calculate shares to remove
        uint256 sharesPerToken = (info.totalShares * 1e18) / info.pooledTokens;
        uint128 sharesWithdrawn = ((sharesPerToken * amount) / 1e18).toUint128();

        // Remove shares and principle from user
        user.shares -= sharesWithdrawn;
        user.principle -= amount.toUint128();

        // remove shares and tokens from info
        info.totalShares -= sharesWithdrawn;
        info.pooledTokens -= amount.toUint128();

        // Get Penalty
        if (user.lastActionTime > block.timestamp - info.minimumDepositTime) {
            uint256 penalty = ((amount * info.earlyPenalty) / decimals) / 100;
            IERC20(poolToken).safeTransfer(teamVault, penalty);
            amount -= penalty;
            emit Penalty(msg.sender, penalty);
        }

        // return amount
        IERC20(poolToken).safeTransfer(address(msg.sender), amount); //pay depositedTokens
        emit Withdraw(msg.sender, amount);
    }

    /** @dev Withdraw all current available rewards */
    function withdrawRewards() external notContract whenNotPaused poolUpdater {
        User storage user = userInfo[msg.sender];
        // Get Rewards
        uint256 reward = getReward(user);
        require(reward != 0, 'NOTHING TO WITHDRAW');

        // Recalc user shares remove shares from the user as if the user deposited principle today
        uint256 sharesPerToken = (info.totalShares * 1e18) / info.pooledTokens;
        uint256 rewardShares = (sharesPerToken * reward) / 1e18;
        user.shares -= rewardShares.toUint128();

        // Remove shares from total and remove reward from totals
        info.totalShares -= rewardShares.toUint128();
        info.pooledTokens -= reward.toUint128();

        // Finally mint the tokens for our user. Congrats!!
        IToken(poolToken).mint(address(msg.sender), reward);
        IToken(bonusToken).mint(address(msg.sender), reward);
        emit WithdrawReward(msg.sender, reward);
    }

    /** @dev Withdraw All rewards and tokens. */
    function withdrawAll() external notContract whenNotPaused poolUpdater {
        User storage user = userInfo[msg.sender];
        uint256 principle = user.principle;

        require(principle != 0, 'NOTHING TO WITHDRAW');

        // Get Penalty
        if (user.lastActionTime > block.timestamp - info.minimumDepositTime) {
            uint256 penalty = ((principle * info.earlyPenalty) / decimals) / 100;
            IERC20(poolToken).safeTransfer(teamVault, penalty);
            principle -= penalty;
            emit Penalty(msg.sender, penalty);
        }

        // Get Reward
        uint256 reward = getReward(user);

        // Remove from globals
        info.totalShares -= user.shares;
        info.pooledTokens -= reward.toUint128();
        info.pooledTokens -= user.principle;

        // Remove user from pool
        delete userInfo[msg.sender];

        // Gift reward
        if (reward != 0) {
            IToken(bonusToken).mint(address(msg.sender), reward);
            IToken(poolToken).mint(address(msg.sender), reward);
            emit WithdrawReward(msg.sender, reward);
        }

        // return principle
        IERC20(poolToken).transfer(address(msg.sender), principle); //pay depositedTokens
        emit Withdraw(msg.sender, principle);
    }

    // getter functions

    /** @dev Get Pending Rewards for user {Internal}
        @param user {User Storage}
     */
    function getReward(User storage user) internal view returns (uint256) {
        if (info.pooledTokens == 0) return 0;

        // (User Shares / totalShares) / pooledtokens - principle
        // This will get us the users rewards based on the % of shares they have in the pool.

        // Ensure there is no dust particles effecting reward.
        uint256 reward = (((user.shares * 1e18) / info.totalShares) * info.pooledTokens) / 1e18;
        if (reward < user.principle) return 0;
        return reward - user.principle;
    }

    /** @dev Get Pending rewards for an address
        @param _user {address}
     */
    function getPendingReward(address _user) external view returns (uint256) {
        User storage user = userInfo[_user];
        uint256 reward = getReward(user);
        return reward;
    }

    /** @dev Return pool info */
    function getPoolInfo() external view returns (PoolInfo memory) {
        return info;
    }

    // setter functions

    /** @dev Increase APr
        @param _addApr {uint256}
     */
    function increaseCurrentApr(uint256 _addApr) external onlyOwner {
        info.currentApr += _addApr;
    }

    /** @dev Subtract APr
        @param _subApr {uint256}
     */
    function decreaseCurrentApr(uint256 _subApr) external onlyOwner {
        info.currentApr -= _subApr;
    }

    /** @dev Slow down APr, the APr will be slowed down each poolUpdate by this number (note: 2 decimals).
        @param _aprSlowdown {uint256}
     */
    function setAprSlowdown(uint256 _aprSlowdown) external onlyOwner {
        info.aprSlowdown = _aprSlowdown;
    }

    /** @dev Set Seconds between rewards. The minimum must be 900 seconds, or else validators can becomes noisy.
        @param _secondsBetweenRewards {uint256}
     */
    function setSecondsBetweenRewards(uint256 _secondsBetweenRewards) external onlyOwner {
        require(_secondsBetweenRewards > 900, 'Minimum of 30 mins between rewards.');
        info.secondsBetweenRewards = _secondsBetweenRewards;
    }

    /** @dev set keeper time limit. Minimum time between rewards 
        @param _timeLimit {uint256}
    */
    function setKeeperTimeLimit(uint256 _timeLimit) external onlyOwner {
        keeperTimelimit = _timeLimit;
    }

    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targetted
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /** Initialize */
    function initialize(
        address _poolToken,
        address _bonusToken,
        address _teamVault,
        uint256 _currentApr,
        uint256 _aprSlowdown,
        uint256 _minApr,
        uint256 _secondsBetweenRewards,
        uint256 _secondsInDay,
        uint256 _keeperTimeLImit
    ) public initializer {
        __Base_init();

        poolToken = _poolToken; // MDCI token
        bonusToken = _bonusToken; // Bonus token
        teamVault = _teamVault;

        info.currentApr = _currentApr; //init to 80%
        info.aprSlowdown = _aprSlowdown; //init to 0%
        info.minApr = _minApr; //init to 10%
        info.secondsBetweenRewards = _secondsBetweenRewards; //init to 3600 for 2 hours
        info.nextInterestTime = block.timestamp; // next interest time
        info.secondsInDay = _secondsInDay; // 1 day
        info.minimumDepositTime = _secondsInDay * 3; // 3 days
        info.earlyPenalty = 200; // 2%

        keeperTimelimit = _keeperTimeLImit; // 3 days
    }

    /** Chainlink Keeper */
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        // give it a 60 second delay
        uint256 timeSinceLastRewards = block.timestamp - info.nextInterestTime;
        if (timeSinceLastRewards > keeperTimelimit) {
            upkeepNeeded = true;
        }

        return (upkeepNeeded, '');
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        updatePool();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

interface KeeperCompatibleInterface {
    /**
     * @notice method that is simulated by the keepers to see if any work actually
     * needs to be performed. This method does does not actually need to be
     * executable, and since it is only ever simulated it can consume lots of gas.
     * @dev To ensure that it is never called, you may want to add the
     * cannotExecute modifier from KeeperBase to your implementation of this
     * method.
     * @param checkData specified in the upkeep registration so it is always the
     * same for a registered upkeep. This can easilly be broken down into specific
     * arguments using `abi.decode`, so multiple upkeeps can be registered on the
     * same contract and easily differentiated by the contract.
     * @return upkeepNeeded boolean to indicate whether the keeper should call
     * performUpkeep or not.
     * @return performData bytes that the keeper should call performUpkeep with, if
     * upkeep is needed. If you would like to encode data to decode later, try
     * `abi.encode`.
     */
    function checkUpkeep(bytes calldata checkData)
        external
        returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice method that is actually executed by the keepers, via the registry.
     * The data returned by the checkUpkeep simulation will be passed into
     * this method to actually be executed.
     * @dev The input to this method should not be trusted, and the caller of the
     * method should not even be restricted to any single registry. Anyone should
     * be able call it, and the input should be validated, there is no guarantee
     * that the data passed in is the performData returned from checkUpkeep. This
     * could happen due to malicious keepers, racing keepers, or simply a state
     * change while the performUpkeep transaction is waiting for confirmation.
     * Always validate the data passed in.
     * @param performData is the data which was passed back from the checkData
     * simulation. If it is encoded, it can easily be decoded into other types by
     * calling `abi.decode`. This data should not be trusted, and should be
     * validated against the contract's current state.
     */
    function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
pragma solidity ^0.8.0;

interface IToken is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
            'SafeERC20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, 'SafeERC20: decreased allowance below zero');
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
            );
        }
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

        bytes memory returndata = address(token).functionCall(
            data,
            'SafeERC20: low-level call failed'
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

library SafeCast {
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

contract BaseUpgradeable is Initializable {
    bool public paused;
    address public owner;
    mapping(address => bool) public pausers;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PauseChanged(address indexed by, bool indexed paused);

    /** ========  MODIFIERS ========  */

    /** @notice modifier for owner only calls */
    modifier onlyOwner() {
        require(owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    /** @notice pause toggler */
    modifier onlyPauseToggler() {
        require(owner == msg.sender || pausers[msg.sender], 'Ownable: caller is not the owner');
        _;
    }

    /** @notice modifier for pausing contracts */
    modifier whenNotPaused() {
        require(!paused || owner == msg.sender || pausers[msg.sender], 'Feature is paused');
        _;
    }

    /** ========  INITALIZE ========  */
    function __Base_init() internal initializer {
        owner = msg.sender;
        paused = false;
    }

    /** ========  OWNERSHIP FUNCTIONS ========  */

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /** ===== PAUSER FUNCTIONS ========== */

    /** @dev allow owner to add or remove pausers */
    function setPauser(address _pauser, bool _allowed) external onlyOwner {
        pausers[_pauser] = _allowed;
    }

    /** @notice toggle pause on and off */
    function setPause(bool _paused) external onlyPauseToggler {
        paused = _paused;

        emit PauseChanged(msg.sender, _paused);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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