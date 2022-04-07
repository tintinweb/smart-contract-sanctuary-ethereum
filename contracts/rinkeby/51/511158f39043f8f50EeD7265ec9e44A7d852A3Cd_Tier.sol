// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./CompoundRateKeeperV2.sol";
import "./interfaces/ITier.sol";

/// @title Tier contract
contract Tier is ITier, CompoundRateKeeperV2 {
    /// @dev START CONTRACT SETTING PARAMS
    /// @notice Payment token address
    IERC20 public paymentToken;
    /// @notice Contain timestamp. After stake, tokens will be lock for due period
    uint64 public lockPeriod;
    /// @dev END CONTRACT SETTING PARAMS

    /// @dev START TIER INFO
    struct TierInfo {
        string name;
        uint256 requiredAmount;
        bool isActive;
    }
    /// @notice Contain tier number to required amount
    mapping(uint64 => TierInfo) public tiers;
    /// @notice Contain tiers count
    uint64 public tiersCount;
    /// @dev END TIER INFO

    /// @dev START USER STAKE INFO
    struct StakeInfo {
        uint256 normalizedAmount;
        uint256 amount;
        uint64 stakeTimestamp;
    }
    /// @notice Address to tier to user stakes.
    mapping(address => StakeInfo) public userStakes;
    /// @dev END USER STAKE INFO

    /// @dev START CONTRACT VIEW VARIABLE
    uint256 public totalUsersCount;
    /// @dev END CONTRACT VIEW VARIABLE

    uint256 public aggregatedAmount;
    uint256 public aggregatedNormalizedAmount;

    modifier onlyEOA() {
        address _sender = msg.sender;
        require(_sender == tx.origin, "onlyEOA: invalid sender (1).");

        uint256 size;
        assembly {
            size := extcodesize(_sender)
        }
        require(size == 0, "onlyEOA: invalid sender (2).");

        _;
    }

    constructor(address _paymentToken) {
        require(_paymentToken != address(0), "Tier: address of payment token can't be a zero.");

        paymentToken = IERC20(_paymentToken);
    }

    /// @notice Set lock period for stake
    /// @param _lockPeriod Seconds
    function setLockPeriod(uint64 _lockPeriod) external override onlyOwner {
        lockPeriod = _lockPeriod;
    }

    /// @notice Create new tier
    /// @param _amount Required amount. Wei
    function createTier(string calldata _name, uint256 _amount) external override onlyOwner {
        require(_amount > 0, "Tier: the amount can't be a zero.");
        uint64 _tiersCount = tiersCount;

        if (_tiersCount > 0)
            require(_amount > tiers[_tiersCount].requiredAmount, "Tier: amount can not be less than in previous tier.");

        tiers[_tiersCount + 1] = TierInfo(_name, _amount, true);
        tiersCount = _tiersCount + 1;

        emit TierCreated(_tiersCount + 1);
    }

    /// @notice Update tier name
    /// @param _tierId Tier id
    /// @param _name New name
    function updateTierName(uint64 _tierId, string calldata _name) external override onlyOwner {
        require(_tierId != 0 && _tierId <= tiersCount, "Tier: invalid tier ID.");

        tiers[_tierId].name = _name;

        emit TierNameChanged(_tierId, _name);
    }

    /// @notice Update existed tier
    /// @param _tierId Tier id
    /// @param _amount Required amount
    function updateTierRequiredAmount(uint64 _tierId, uint256 _amount) external override onlyOwner {
        uint256 _tiersCount = tiersCount;
        require(_tierId != 0 && _tierId <= _tiersCount, "Tier: invalid tier ID.");
        require(_amount > 0, "Tier: the amount can't be a zero.");

        if (_tiersCount > 1) {
            if (_tierId > 1)
                require(
                    _amount > tiers[_tierId - 1].requiredAmount,
                    "Tier: amount can not be less than in previous tier."
                );

            if (_tierId < _tiersCount)
                require(_amount < tiers[_tierId + 1].requiredAmount, "Tier: amount can not be more than in next tier.");
        }

        tiers[_tierId].requiredAmount = _amount;

        emit TierRequiredAmountChanged(_tierId, _amount);
    }

    /// @notice Update tier status
    /// @param _tierId Tier id
    /// @param _status New status
    function updateTierStatus(uint64 _tierId, bool _status) external override onlyOwner {
        require(_tierId != 0 && _tierId <= tiersCount, "Tier: invalid tier ID.");
        require(tiers[_tierId].isActive != _status, "Tier: the new status the same as the old.");

        tiers[_tierId].isActive = _status;

        emit TierStatusChanged(_tierId, _status);
    }

    /// @notice Stake tokens.
    /// @param _amount Staked amount
    function stake(uint256 _amount) external override onlyEOA {
        require(_amount > 0, "Tier: stake amount can't be a zero.");

        uint256 _compoundRate = getCompoundRate();

        uint256 _currentAmount;
        uint256 _normalizedAmount = userStakes[msg.sender].normalizedAmount;
        if (_normalizedAmount == 0) {
            totalUsersCount++;
        } else {
            _currentAmount = _getExistedStakeAmount(_normalizedAmount, _compoundRate);
        }

        uint256 _newStakedAmount = _amount + _currentAmount;
        uint256 _newNormalizedAmount = (_newStakedAmount * _getDecimals()) / _compoundRate;
        require(_newNormalizedAmount > 0, "Tier: stake amount too small.");

        paymentToken.transferFrom(msg.sender, address(this), _amount);

        aggregatedNormalizedAmount += _newNormalizedAmount - _normalizedAmount;
        aggregatedAmount += _amount;

        userStakes[msg.sender].amount += _amount;
        userStakes[msg.sender].normalizedAmount = _newNormalizedAmount;
        userStakes[msg.sender].stakeTimestamp = uint64(block.timestamp);

        emit AddressStaked(msg.sender, _amount);
    }

    /// @notice Withdraw staked tokens.
    /// @param _amount Withdraw amount
    function withdraw(uint256 _amount) external override {
        require(_amount > 0, "Tier: withdraw amount can't be a zero.");
        require(
            userStakes[msg.sender].stakeTimestamp + lockPeriod < block.timestamp,
            "Tier: your tokens are locked. Wait until the lockout period is over."
        );

        uint256 _normalizedAmount = userStakes[msg.sender].normalizedAmount;
        require(_normalizedAmount > 0, "Tier: you have nothing to withdraw.");

        uint256 _compoundRate = getCompoundRate();
        uint256 _existedStakedAmount = _getExistedStakeAmount(_normalizedAmount, _compoundRate);

        if (_existedStakedAmount <= _amount) {
            _amount = _existedStakedAmount;
            totalUsersCount--;
        }
        uint256 _newNormalizedAmount = ((_existedStakedAmount - _amount) * _getDecimals()) / _compoundRate;

        aggregatedNormalizedAmount -= _normalizedAmount - _newNormalizedAmount;
        aggregatedAmount = aggregatedAmount + _existedStakedAmount - userStakes[msg.sender].amount - _amount;

        userStakes[msg.sender].amount = _existedStakedAmount - _amount;
        userStakes[msg.sender].normalizedAmount = _newNormalizedAmount;

        paymentToken.transfer(msg.sender, _amount);

        emit AddressWithdrawn(msg.sender, _amount);
    }

    /// @notice Return max tier number for address
    /// @param _address Address
    function getTierIdByAddress(address _address) external view override returns (uint64) {
        uint256 _stakeAmount = _getExistedStakeAmount(userStakes[_address].normalizedAmount, getCompoundRate());
        if (_stakeAmount == 0) return 0;

        uint64 _tiersCount = tiersCount;
        for (uint64 i = _tiersCount; i > 0; i--) {
            if (tiers[i].requiredAmount <= _stakeAmount && tiers[i].isActive) {
                return i;
            }
        }

        return 0;
    }

    /// @notice Checks if the address has the requested tier.
    /// @param _tierId Requested tier ID
    /// @param _address Address
    function hasTier(uint64 _tierId, address _address) external view override returns (bool) {
        require(_tierId != 0 && _tierId <= tiersCount, "Tier: invalid tier ID.");

        return
            tiers[_tierId].requiredAmount <=
            _getExistedStakeAmount(userStakes[_address].normalizedAmount, getCompoundRate()) &&
            tiers[_tierId].isActive;
    }

    /// @notice Return address balance considering the interest at the moment
    function getExistedStakeAmount(address _address) external view override returns (uint256) {
        return _getExistedStakeAmount(userStakes[_address].normalizedAmount, getCompoundRate());
    }

    /// @notice Add payment tokens to contract address to be spent as rewards.
    /// @param _amount Token amount that will be added to contract as reward
    function supplyRewardPool(uint256 _amount) external override {
        paymentToken.transferFrom(msg.sender, address(this), _amount);
    }

    /// @notice Get the amount of tokens that should be on the contract if all users withdraw their stakes
    /// @notice at the current time.
    function getCollateralAmount() external view override returns (uint256) {
        return _getCollateralAmount();
    }

    /// @notice Get coefficient. Tokens on the contract / total stake + total reward to be paid
    function monitorSecurityMargin() external view override onlyOwner returns (uint256) {
        uint256 _contractBalance = paymentToken.balanceOf(address(this));
        uint256 _toReward = _getCollateralAmount();

        if (_contractBalance == 0 || _toReward == 0) return 0;
        return (_contractBalance * _getDecimals()) / _toReward;
    }

    /// @notice Withdraw rest of rewards to address
    /// @param _amount Amount to withdraw
    /// @param _address Token recipient address
    function withdrawRest(uint256 _amount, address _address) external override onlyOwner {
        require(
            _getCollateralAmount() <= paymentToken.balanceOf(address(this)) - _amount,
            "Tier: Cannot withdraw reward funds."
        );

        paymentToken.transfer(_address, _amount);
    }

    /// @notice Transfer stuck tokens.
    /// @param _token Token contract address
    /// @param _to Receiver address
    /// @param _amount Token amount
    function withdrawStuckERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external override onlyOwner {
        require(address(_token) != address(paymentToken), "Tier: transfer for related contact is not possible.");
        _token.transfer(_to, _amount);
    }

    /// @notice Withdraw native token from contract
    /// @param _to Token receiver
    function withdrawNative(address _to) external override onlyOwner {
        payable(_to).transfer(address(this).balance);
    }

    function _getCollateralAmount() private view returns (uint256) {
        return _getExistedStakeAmount(aggregatedNormalizedAmount, getCompoundRate());
    }

    function _getExistedStakeAmount(uint256 _normalizedAmount, uint256 _compoundRate) private pure returns (uint256) {
        return (_normalizedAmount * _compoundRate) / _getDecimals();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICompoundRateKeeperV2.sol";

/// @notice CompoundRateKeeperV2 contract.
contract CompoundRateKeeperV2 is ICompoundRateKeeperV2, Ownable {
    uint256 public currentRate;
    uint256 public annualPercent;

    uint64 public capitalizationPeriod;
    uint64 public lastUpdate;

    bool public hasMaxRateReached;

    constructor() {
        capitalizationPeriod = 31536000;
        lastUpdate = uint64(block.timestamp);

        annualPercent = _getDecimals();
        currentRate = _getDecimals();
    }

    /// @notice Set new capitalization period
    /// @param _capitalizationPeriod Seconds
    function setCapitalizationPeriod(uint32 _capitalizationPeriod) external override onlyOwner {
        require(_capitalizationPeriod > 0, "CompoundRateKeeperV2: capitalization period can't be a zero.");

        currentRate = _getPotentialCompoundRate(uint64(block.timestamp));
        capitalizationPeriod = _capitalizationPeriod;

        lastUpdate = uint64(block.timestamp);

        emit CapitalizationPeriodChanged(_capitalizationPeriod);
    }

    /// @notice Set new annual percent
    /// @param _annualPercent = 1*10^27 (0% per period), 1.1*10^27 (10% per period), 2*10^27 (100% per period)
    function setAnnualPercent(uint256 _annualPercent) external override onlyOwner {
        require(!hasMaxRateReached, "CompoundRateKeeperV2: the rate maximum has been reached.");
        require(_annualPercent >= _getDecimals(), "CompoundRateKeeperV2: annual percent can't be less then 1.");

        currentRate = _getPotentialCompoundRate(uint64(block.timestamp));
        annualPercent = _annualPercent;

        lastUpdate = uint64(block.timestamp);

        emit AnnualPercentChanged(_annualPercent);
    }

    /// @notice Call this function only when getCompoundRate() or getPotentialCompoundRate() throw error
    /// @notice Update hasMaxRateReached switcher to True
    function emergencyUpdateCompoundRate() external override {
        try this.getCompoundRate() returns (uint256 _rate) {
            if (_rate == _getMaxRate()) hasMaxRateReached = true;
        } catch {
            hasMaxRateReached = true;
        }
    }

    /// @notice Calculate compound rate for this moment.
    function getCompoundRate() public view override returns (uint256) {
        return _getPotentialCompoundRate(uint64(block.timestamp));
    }

    /// @notice Calculate compound rate at a particular time.
    /// @param _timestamp Seconds
    function getPotentialCompoundRate(uint64 _timestamp) public view override returns (uint256) {
        return _getPotentialCompoundRate(_timestamp);
    }

    /// @dev Main contract logic, calculate actual compound rate
    /// @dev If rate bigger than _getMaxRate(), return _getMaxRate()
    /// @dev Return actual rate, max rate if actual bigger than max, and throw error when values to big
    /// @dev If function return error, call emergencyUpdateCompoundRate()
    function _getPotentialCompoundRate(uint64 _timestamp) private view returns (uint256) {
        uint256 _maxRate = _getMaxRate();
        if (hasMaxRateReached) return _maxRate;

        uint64 _lastUpdate = lastUpdate;
        require(_timestamp >= _lastUpdate, "CompoundRateKeeperV2: timestamp can't be less then last update.");

        uint64 _secondsPassed = _timestamp - _lastUpdate;

        uint64 _capitalizationPeriod = capitalizationPeriod;
        uint64 _capitalizationPeriodsNum = _secondsPassed / _capitalizationPeriod;
        uint64 _secondsLeft = _secondsPassed % _capitalizationPeriod;

        uint256 _annualPercent = annualPercent;
        uint256 _capitalizationPeriodRate = _pow(_annualPercent, _capitalizationPeriodsNum, _getDecimals());

        uint256 _rate = (currentRate * _capitalizationPeriodRate) / _getDecimals();

        if (_secondsLeft > 0) {
            uint256 _rateLeft = _getDecimals() +
                ((_annualPercent - _getDecimals()) * _secondsLeft) /
                _capitalizationPeriod;

            _rate = (_rate * _rateLeft) / _getDecimals();
        }

        return _rate > _maxRate ? _maxRate : _rate;
    }

    /// @dev Decimals for number.
    function _getDecimals() internal pure returns (uint256) {
        return 10**27;
    }

    /// @dev Max accessible compound rate.
    function _getMaxRate() private pure returns (uint256) {
        return type(uint128).max * _getDecimals();
    }

    /// @dev github.com/makerdao/dss implementation of exponentiation by squaring
    function _pow(
        uint256 _num,
        uint256 _exponent,
        uint256 _base
    ) private pure returns (uint256 _res) {
        assembly {
            function power(x, n, b) -> z {
                switch x
                case 0 {
                    switch n
                    case 0 {
                        z := b
                    }
                    default {
                        z := 0
                    }
                }
                default {
                    switch mod(n, 2)
                    case 0 {
                        z := b
                    }
                    default {
                        z := x
                    }

                    let half := div(b, 2)
                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if iszero(eq(div(xx, x), x)) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, b)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                                revert(0, 0)
                            }

                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }

                            z := div(zxRound, b)
                        }
                    }
                }
            }

            _res := power(_num, _exponent, _base)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICompoundRateKeeperV2.sol";

/// @title Tier contract
interface ITier is ICompoundRateKeeperV2 {
    event TierCreated(uint64 id);
    event TierNameChanged(uint64 id, string newName);
    event TierRequiredAmountChanged(uint64 id, uint256 newRequiredAmount);
    event TierStatusChanged(uint64 id, bool newStatus);
    event AddressStaked(address staker, uint256 amount);
    event AddressWithdrawn(address staker, uint256 amount);

    /// @notice Set lock period for stake
    /// @param _lockPeriod Seconds
    function setLockPeriod(uint64 _lockPeriod) external;

    /// @notice Create new tier
    /// @param _amount Required amount. Wei
    function createTier(string calldata _name, uint256 _amount) external;

    /// @notice Update tier name
    /// @param _tierId Tier id
    /// @param _name New name
    function updateTierName(uint64 _tierId, string calldata _name) external;

    /// @notice Update existed tier
    /// @param _tierId Tier id
    /// @param _amount Required amount
    function updateTierRequiredAmount(uint64 _tierId, uint256 _amount) external;

    /// @notice Update tier status
    /// @param _tierId Tier id
    /// @param _status New status
    function updateTierStatus(uint64 _tierId, bool _status) external;

    /// @notice Stake tokens.
    /// @param _amount Staked amount
    function stake(uint256 _amount) external;

    /// @notice Withdraw staked tokens.
    /// @param _amount Withdraw amount
    function withdraw(uint256 _amount) external;

    /// @notice Return max tier number for address
    /// @param _address Address
    function getTierIdByAddress(address _address) external view returns (uint64);

    /// @notice Checks if the address has the requested tier.
    /// @param _tierId Requested tier ID
    /// @param _address Address
    function hasTier(uint64 _tierId, address _address) external view returns (bool);

    /// @notice Return address balance considering the interest at the moment
    function getExistedStakeAmount(address _address) external view returns (uint256);

    /// @notice Add payment tokens to contract address to be spent as rewards.
    /// @param _amount Token amount that will be added to contract as reward
    function supplyRewardPool(uint256 _amount) external;

    /// @notice Get the amount of tokens that should be on the contract if all users withdraw their stakes
    /// @notice at the current time.
    function getCollateralAmount() external view returns (uint256);

    /// @notice Get coefficient. Tokens on the contract / total stake + total reward to be paid
    function monitorSecurityMargin() external view returns (uint256);

    /// @notice Withdraw rest of rewards to address
    /// @param _amount Amount to withdraw
    /// @param _address Token recipient address
    function withdrawRest(uint256 _amount, address _address) external;

    /// @notice Transfer stuck tokens.
    /// @param _token Token contract address
    /// @param _to Receiver address
    /// @param _amount Token amount
    function withdrawStuckERC20(IERC20 _token, address _to, uint256 _amount) external;

    /// @notice Withdraw native token from contract
    /// @param _to Token receiver
    function withdrawNative(address _to) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/// @notice Interface for CompoundRateKeeperV2 contract.
interface ICompoundRateKeeperV2 {
    event CapitalizationPeriodChanged(uint256 indexed newCapitalizationPeriod);
    event AnnualPercentChanged(uint256 indexed newAnnualPercent);

    /// @notice Set new capitalization period
    /// @param _capitalizationPeriod Seconds
    function setCapitalizationPeriod(uint32 _capitalizationPeriod) external;

    /// @notice Set new annual percent
    /// @param _annualPercent = 1*10^27 (0% per period), 1.1*10^27 (10% per period), 2*10^27 (100% per period)
    function setAnnualPercent(uint256 _annualPercent) external;

    /// @notice Call this function only when getCompoundRate() or getPotentialCompoundRate() throw error
    /// @notice Update hasMaxRateReached switcher to True
    function emergencyUpdateCompoundRate() external;

    /// @notice Calculate compound rate for this moment.
    function getCompoundRate() external view returns (uint256);

    /// @notice Calculate compound rate at a particular time.
    /// @param _timestamp Seconds
    function getPotentialCompoundRate(uint64 _timestamp) external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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