// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "Ownable.sol";
import "IProtocolToken.sol";

/**
 * @dev Time-locks tokens according to an unlock schedule
 * @dev Locked amount is involved in staking
 */
contract TokenLockStakeable is Ownable {
    // unlock rate during time
    // ex:
    // month:      1      2      3      4      5     ...
    // unlock %:   10%    10%    15%    15%    20%   ...
    struct UnlockRate {
        uint256 timestamp;
        uint256 unlockPercentage;
    }

    bool public paused;

    // lock and reward token
    address public immutable token;

    // time user can withdraw all
    uint256 public immutable unlockEnd;

    // the current unlock rate of this contract
    uint256 public currentUnlockRate;

    // locked amount of an address, never change since lock()
    mapping(address => uint256) public lockedAmounts;

    // amount has been claimed by users
    mapping(address => uint256) public claimedAmounts;

    // amount of reward tokens allocated for users
    mapping(address => uint256) public pendingRewards;

    // unlock rate config in constructor
    UnlockRate[] public unlockRates;

    // events
    event Locked(address indexed sender, address[] indexed recipients, uint256[] amounts, uint256[] rewards);
    event Claimed(address indexed recipient, uint256 amount);
    event ClaimedReward(address indexed recipient, uint256 amount);
    event PauseContract(uint256 indexed timestamp);
    event UnpauseContract(uint256 indexed timestamp);

    /**
     * @dev The pause mechanism
     */
    modifier pausable() {
        require(!paused, "PAUSED");
        _;
    }

    /**
     * @dev Constructor
     * @param _token The token this contract will lock
     * @param _unlockEnd The time at which the last token will be unlocked
     * @param _unlockTimestamps Array of timestamps when tokens will be unlocked
     * @param _unlockPercents Percent of tokens to unlock per unlock timestamp
     */
    constructor(
        address _token,
        uint256 _unlockEnd,
        uint256[] memory _unlockTimestamps,
        uint256[] memory _unlockPercents
    ) {
        // check input
        require(_token != address(0), "TOKEN_ADDRESS_ZERO");

        require(_unlockPercents.length > 0, "EMPTY_ARRAY");

        require(_unlockTimestamps.length == _unlockPercents.length, "INVALID_SCHEDULE");

        // assign to state variables
        token = _token;

        unlockEnd = _unlockEnd;

        // make sure _unlockTimestamps array has increasing order
        // and sum of _unlockPercents equal 100
        uint256 t = _unlockTimestamps[0];
        uint256 arraySum = 0;
        
        for (uint256 i; i < _unlockTimestamps.length; i++) {

            arraySum = arraySum + _unlockPercents[i];

            if (i > 0) {
                require(_unlockTimestamps[i] > t, "INVALID_TIMESTAMP");
                t = _unlockTimestamps[i];
            }
        }

        require(arraySum == 100, "INVALID_UNLOCK_RATES");

        unchecked {
            for (uint256 i = _unlockPercents.length - 1; i + 1 != 0; i--) {
                unlockRates.push(UnlockRate({ timestamp: _unlockTimestamps[i], unlockPercentage: _unlockPercents[i] }));
            }
        }

    }

    /**
     * @dev Pause the contract
     */
    function pause() external onlyOwner {
        paused = true;
        emit PauseContract(block.timestamp);
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyOwner {
        paused = false;
        emit UnpauseContract(block.timestamp);
    }

    /**
     * @dev Lock the tokens to the benefit of the recipients
     * @param recipients The accounts that are having tokens locked
     * @param amounts The amounts of tokens to lock per account
     * @param rewards The staking reward per account
     */
    function lock(
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256[] calldata rewards
    ) external onlyOwner {
        require(block.timestamp < unlockEnd, "UNLOCK_PERIOD_ENDED");

        require(recipients.length == amounts.length && recipients.length == rewards.length, "INVALID_ARRAY_LENGTHS");

        uint256 amount;
        for (uint256 i; i < recipients.length; i++) {
            // save lockedAmounts
            lockedAmounts[recipients[i]] += amounts[i];

            // save pendingRewards
            pendingRewards[recipients[i]] += rewards[i];

            amount += amounts[i];
        }

        bool success = IProtocolToken(token).transferFrom(msg.sender, address(this), amount);
        require(success, "TRANSFER_FAILED");

        emit Locked(msg.sender, recipients, amounts, rewards);
    }

    /// @dev Change the beneficiary address of the lockedAmounts tokens
    /// @param oldAddress The old address of the investor
    /// @param newAddress The new address of the investor
    function changePartnerAddress(address oldAddress, address newAddress) external onlyOwner {
        // can only change address before the first unlock period
        updateCurrentUnlockRate();
        require(currentUnlockRate == 0, "TOO_LATE");

        // lockedAmounts[oldAddress] must > 0
        require(lockedAmounts[oldAddress] > 0, "ZERO_LOCKED_AMOUNT");

        // lockedAmounts[newAddress] must = 0
        require(lockedAmounts[newAddress] == 0, "NEW_ADDRESS_ALREADY_HAS_LOCKED_TOKENS");

        // set the lockedAmounts of oldAddress to zero
        uint256 amount = lockedAmounts[oldAddress];
        lockedAmounts[oldAddress] = 0;

        // set the lockedAmounts of newAddress to the amount of oldAddress
        lockedAmounts[newAddress] = amount;

        // set reward to the new address
        uint256 _reward = pendingRewards[oldAddress];
        pendingRewards[oldAddress] = 0;
        pendingRewards[newAddress] = _reward;
    }

    /**
     * @dev Claims the caller's tokens that have been unlocked
     */
    function claim() external pausable {
        if (unlockRates.length > 0) {
            if (block.timestamp > unlockRates[unlockRates.length - 1].timestamp) {
                updateCurrentUnlockRate();
            }
        }
        uint256 claimable = _claimableBalance(msg.sender);

        // only transfer token if claimable > 0
        if (claimable > 0) {
            claimedAmounts[msg.sender] += claimable;

            bool success = IProtocolToken(token).transfer(msg.sender, claimable);
            require(success, "TRANSFER_FAILED");

            emit Claimed(msg.sender, claimable);
        }
    }

    /**
     * @dev Claims the caller's staking reward
     * @dev Can only claim after unlockeEnd
     */
    function claimReward() external pausable {
        require(block.timestamp > unlockEnd, "WAIT_UNTIL_UNLOCKEND");
        require(pendingRewards[msg.sender] > 0, "ZERO_REWARD");

        uint256 _reward = pendingRewards[msg.sender];
        pendingRewards[msg.sender] = 0;

        bool success = IProtocolToken(token).mintTo(msg.sender, _reward);
        require(success, "MINT_FAILED");
        
        emit ClaimedReward(msg.sender, _reward);

    }

    /// @dev update the currentUnlockRate
    function updateCurrentUnlockRate() public {
        if (currentUnlockRate == 100) return;

        unchecked {
            for (uint256 i = unlockRates.length - 1; i + 1 != 0; i--) {
                UnlockRate memory rate = unlockRates[i];
                if (block.timestamp > rate.timestamp) {
                    currentUnlockRate += rate.unlockPercentage;
                    unlockRates.pop();
                } else {
                    break;
                }
            }
        }
    }

    /**
     * @dev Returns the maximum number of tokens currently claimable by `owner`
     * @param owner The account to check the claimable balance of
     * @return The number of tokens currently claimable
     */
    function claimableBalance(address owner) external view returns (uint256) {
        uint256 locked = lockedAmounts[owner];
        uint256 claimed = claimedAmounts[owner];

        if (currentUnlockRate == 100) {
            return locked - claimed;
        }

        uint256 _currentUnlockRate = currentUnlockRate;

        unchecked {
            for (uint256 i = unlockRates.length - 1; i + 1 != 0; i--) {
                UnlockRate memory rate = unlockRates[i];
                if (block.timestamp > rate.timestamp) {
                    _currentUnlockRate += rate.unlockPercentage;
                } else {
                    break;
                }
            }
        }
        return (locked * _currentUnlockRate) / 100 - claimed;
    }

    /**
     * @dev Internally returns the maximum number of tokens currently claimable by `owner`
     * @param owner The account to check the claimable balance of
     * @return The number of tokens currently claimable
     */
    function _claimableBalance(address owner) internal view returns (uint256) {
        uint256 locked = lockedAmounts[owner];
        uint256 claimed = claimedAmounts[owner];
        if (currentUnlockRate == 100) {
            return locked - claimed;
        }
        return (locked * currentUnlockRate) / 100 - claimed;
    }

    /// @dev Set the reward for user
    /// @param _user The address of the beneficiary
    /// @param _reward The reward given to the beneficiary
    function setReward(address _user, uint256 _reward) external onlyOwner {
        require(block.timestamp < unlockEnd, "UNLOCK_ENDED");
        require(lockedAmounts[_user] > 0, "INVALID_USER");
        pendingRewards[_user] = _reward;
    }

    function unlockRatesLength() external view returns(uint256) {
        return unlockRates.length;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

pragma solidity ^0.8.9;

interface IProtocolToken {
    function mint(uint256 _amount) external returns (bool);

    function mintTo(address _recipient, uint256 _amount) external returns (bool);

    function burn(uint256 _amount) external returns (bool);

    function addAdmin(address _admin) external;

    function removeAdmin(address _admin) external;

    function setSupplyIncreaseRate(uint256 _rate) external;

    function setMaxSupply(uint224 _maxTokenSupply) external;

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}