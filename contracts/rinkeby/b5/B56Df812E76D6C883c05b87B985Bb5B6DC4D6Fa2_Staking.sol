// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CompoundRateKeeperV2.sol";
import "./interfaces/IStaking.sol";

contract Staking is IStaking, CompoundRateKeeperV2 {
    /// @notice Staking token contract address.
    IERC20 public token;

    struct Stake {
        uint256 amount;
        uint256 normalizedAmount;
        uint64 lastUpdate;
    }

    /// @notice Staker address to staker info.
    mapping(address => Stake) public addressToStake;
    /// @notice Stake start timestamp.
    uint64 public startTimestamp;
    /// @notice Stake end timestamp.
    uint64 public endTimestamp;
    /// @notice Period when address can't withdraw after stake.
    uint64 public lockPeriod;

    uint256 private aggregatedAmount;
    uint256 private aggregatedNormalizedAmount;

    constructor(
        IERC20 _token,
        uint64 _startTimestamp,
        uint64 _endTimestamp,
        uint64 _lockPeriod
    ) {
        require(_endTimestamp > block.timestamp, "Staking: incorrect end timestamps.");
        require(_endTimestamp > _startTimestamp, "Staking: incorrect start timestamps.");

        token = _token;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        lockPeriod = _lockPeriod;
    }

    /// @notice Update lock period.
    /// @param _lockPeriod Timestamp
    function setLockPeriod(uint64 _lockPeriod) external override onlyOwner {
        lockPeriod = _lockPeriod;
    }

    /// @notice Stake tokens to contract.
    /// @param _amount Stake amount
    function stake(uint256 _amount) external override returns (bool) {
        require(_amount > 0, "Staking: the amount cannot be a zero.");
        require(startTimestamp <= block.timestamp, "Staking: staking is not started.");
        require(endTimestamp >= block.timestamp, "Staking: staking is ended.");

        token.transferFrom(msg.sender, address(this), _amount);

        uint256 _compoundRate = getCompoundRate();
        uint256 _normalizedAmount = addressToStake[msg.sender].normalizedAmount;
        uint256 _newAmount;
        uint256 _newNormalizedAmount;

        if (_normalizedAmount > 0) {
            _newAmount = _getDenormalizedAmount(_normalizedAmount, _compoundRate) + _amount;
        } else {
            _newAmount = _amount;
        }
        _newNormalizedAmount = (_newAmount * _getDecimals()) / _compoundRate;

        aggregatedAmount = aggregatedAmount - addressToStake[msg.sender].amount + _newAmount;
        aggregatedNormalizedAmount = aggregatedNormalizedAmount - _normalizedAmount + _newNormalizedAmount;

        addressToStake[msg.sender].amount = _newAmount;
        addressToStake[msg.sender].normalizedAmount = _newNormalizedAmount;
        addressToStake[msg.sender].lastUpdate = uint64(block.timestamp);

        return true;
    }

    /// @notice Withdraw tokens from stake.
    /// @param _withdrawAmount Tokens amount to withdraw
    function withdraw(uint256 _withdrawAmount) external override returns (bool) {
        require(_withdrawAmount > 0, "Staking: the amount cannot be a zero.");

        uint256 _compoundRate = getCompoundRate();
        uint256 _normalizedAmount = addressToStake[msg.sender].normalizedAmount;
        uint256 _availableAmount = _getDenormalizedAmount(_normalizedAmount, _compoundRate);

        require(_availableAmount > 0, "Staking: available amount is zero.");
        require(
            addressToStake[msg.sender].lastUpdate + lockPeriod < block.timestamp,
            "Staking: wait for the lockout period to expire."
        );

        if (_availableAmount < _withdrawAmount) _withdrawAmount = _availableAmount;

        uint256 _newAmount = _availableAmount - _withdrawAmount;
        uint256 _newNormalizedAmount = (_newAmount * _getDecimals()) / _compoundRate;

        aggregatedAmount = aggregatedAmount - addressToStake[msg.sender].amount + _newAmount;
        aggregatedNormalizedAmount = aggregatedNormalizedAmount - _normalizedAmount + _newNormalizedAmount;

        addressToStake[msg.sender].amount = _newAmount;
        addressToStake[msg.sender].normalizedAmount = _newNormalizedAmount;

        token.transfer(msg.sender, _withdrawAmount);

        return true;
    }

    /// @notice Return amount of tokens + percents at this moment.
    /// @param _address Staker address
    function getDenormalizedAmount(address _address) external view override returns (uint256) {
        return _getDenormalizedAmount(addressToStake[_address].normalizedAmount, getCompoundRate());
    }

    /// @notice Return amount of tokens + percents at given timestamp.
    /// @param _address Staker address
    /// @param _timestamp Given timestamp (seconds)
    function getPotentialAmount(address _address, uint64 _timestamp) external view override returns (uint256) {
        return (addressToStake[_address].normalizedAmount * getPotentialCompoundRate(_timestamp)) / _getDecimals();
    }

    /// @notice Transfer tokens to contract as reward.
    /// @param _amount Token amount
    function supplyRewardPool(uint256 _amount) external override returns (bool) {
        return token.transferFrom(msg.sender, address(this), _amount);
    }

    /// @notice Return total reward amount.
    function getTotalRewardAmount() external view override returns (uint256) {
        return (aggregatedNormalizedAmount * getCompoundRate()) / _getDecimals() - aggregatedAmount;
    }

    /// @notice Return aggregated staked amount (without percents).
    function getAggregatedAmount() external view override returns (uint256) {
        return aggregatedAmount;
    }

    /// @notice Return aggregated normalized amount.
    function getAggregatedNormalizedAmount() external view override onlyOwner returns (uint256) {
        return aggregatedNormalizedAmount;
    }

    /// @notice Return coefficient in decimals. If coefficient more than 1, all holders will be able to receive awards.
    function monitorSecurityMargin() external view override onlyOwner returns (uint256) {
        uint256 _toWithdraw = (aggregatedNormalizedAmount * getCompoundRate()) / _getDecimals();

        if (_toWithdraw == 0) return _getDecimals();
        return (token.balanceOf(address(this)) * _getDecimals()) / _toWithdraw;
    }

    /// @notice Transfer stuck ERC20 tokens.
    /// @param _token Token address
    /// @param _to Address 'to'
    /// @param _amount Token amount
    function transferStuckERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external override onlyOwner returns (bool) {
        if (address(token) == address(_token)) {
            uint256 _availableAmount = token.balanceOf(address(this)) -
                (aggregatedNormalizedAmount * getCompoundRate()) /
                _getDecimals();
            _amount = _availableAmount < _amount ? _availableAmount : _amount;
        }

        return _token.transfer(_to, _amount);
    }

    /// @notice Transfer stuck native tokens.
    /// @param _to Address 'to'
    /// @param _amount Token amount
    function transferStuckNativeToken(address payable _to, uint256 _amount) external override onlyOwner {
        _to.transfer(_amount);
    }

    /// @dev Calculate denormalized amount.
    function _getDenormalizedAmount(uint256 _normalizedAmount, uint256 _compoundRate) private pure returns (uint256) {
        return (_normalizedAmount * _compoundRate) / _getDecimals();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
        // Revert is made to avoid incorrect calculations at the front
        if (_timestamp == _lastUpdate) {
            return currentRate;
        } else if (_timestamp < _lastUpdate) {
            revert("CompoundRateKeeperV2: timestamp can't be less then last update.");
        }

        uint64 _secondsPassed = _timestamp - _lastUpdate;

        uint64 _capitalizationPeriod = capitalizationPeriod;
        uint64 _capitalizationPeriodsNum = _secondsPassed / _capitalizationPeriod;
        uint64 _secondsLeft = _secondsPassed % _capitalizationPeriod;

        uint256 _annualPercent = annualPercent;
        uint256 _rate = currentRate;

        if (_capitalizationPeriodsNum != 0) {
            uint256 _capitalizationPeriodRate = _pow(_annualPercent, _capitalizationPeriodsNum, _getDecimals());
            _rate = (_rate * _capitalizationPeriodRate) / _getDecimals();
        }

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

interface IStaking is ICompoundRateKeeperV2 {
    /// @notice Update lock period.
    /// @param _lockPeriod Timestamp
    function setLockPeriod(uint64 _lockPeriod) external;

    /// @notice Stake tokens to contract.
    /// @param _amount Stake amount
    function stake(uint256 _amount) external returns (bool);

    /// @notice Withdraw tokens from stake.
    /// @param _withdrawAmount Tokens amount to withdraw
    function withdraw(uint256 _withdrawAmount) external returns (bool);

    /// @notice Return amount of tokens + percents at this moment.
    /// @param _address Staker address
    function getDenormalizedAmount(address _address) external view returns (uint256);

    /// @notice Return amount of tokens + percents at given timestamp.
    /// @param _address Staker address
    /// @param _timestamp Given timestamp (seconds)
    function getPotentialAmount(address _address, uint64 _timestamp) external view returns (uint256);

    /// @notice Transfer tokens to contract as reward.
    /// @param _amount Token amount
    function supplyRewardPool(uint256 _amount) external returns (bool);

    /// @notice Return total reward amount.
    function getTotalRewardAmount() external view returns (uint256);

    /// @notice Return aggregated staked amount (without percents).
    function getAggregatedAmount() external view returns (uint256);

    /// @notice Return aggregated normalized amount.
    function getAggregatedNormalizedAmount() external view returns (uint256);

    /// @notice Return coefficient in decimals. If coefficient more than 1, all holders will be able to receive awards.
    function monitorSecurityMargin() external view returns (uint256);

    /// @notice Transfer stuck ERC20 tokens.
    /// @param _token Token address
    /// @param _to Address 'to'
    /// @param _amount Token amount
    function transferStuckERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external returns (bool);

    /// @notice Transfer stuck native tokens.
    /// @param _to Address 'to'
    /// @param _amount Token amount
    function transferStuckNativeToken(address payable _to, uint256 _amount) external;
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