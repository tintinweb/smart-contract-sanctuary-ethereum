// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

/**
 * @title Market
 * @author @InsureDAO
 * @notice InsureDAO's Depeg insurance data and underwiters token
 **/
import {IMarketParameters, IAssetManagement, IMigrationAsset, IMarket, IPremiumModel, IRefundModel, IRewardPool} from "../interfaces/AllInterfaces.sol";
import "../libs/ERC20Reward.sol";
import "../libs/MarketVolatility.sol";
import "../securities/Restriction.sol";
import "../securities/Pausable.sol";
import "../securities/AbstractOwner.sol";

// import "forge-std/console2.sol";

contract Market is IMarket, ERC20Reward, MarketVolatility, Restriction, Pausable, AbstractOwner {
    uint256 private constant MAGIC_SCALE_1E8 = 1e8; //internal multiplication scale 1e8 to reduce decimal truncation

    /**
     * Storage
     */

    /// @notice External contract call addresses
    IMarketParameters public immutable parameters;
    IAssetManagement public override manager;

    /// @notice inherit MarketVolatility
    function _marketParameters() internal view override returns (IMarketParameters) {
        return parameters;
    }

    /// @notice Market variables
    mapping(address => Withdrawal) public withdrawalReq;
    mapping(uint256 => Insurance) public insurances;
    uint256 public allInsuranceCount;
    mapping(address => bool) public delegators;

    /**
     * Modifiers
     */
    modifier onlyWhenNotVolatile() {
        if (isVolatile()) revert TooVolatile();
        _;
    }

    modifier onlyDelegator() {
        if (!delegators[msg.sender]) revert OnlyDelegator();
        _;
    }

    modifier onlyDepeg() {
        if (!isDepeg()) revert NotApplicable();
        _;
    }

    modifier notZeroAddress(address _account) {
        if (_account == address(0)) revert ZeroAddress();
        _;
    }

    modifier checkInsurance(uint256 _id) {
        Insurance memory _insurance = insurances[_id];
        if (!_insurance.status) revert InsuranceNotActive();
        if (block.timestamp + parameters.getMinDate(address(this)) > _insurance.endTime) revert OutOfSpan();
        if (_insurance.insured != msg.sender) revert NotYourInsurance();
        _;
    }

    /**
     * Initialize interaction
     */
    constructor(
        address _initDepositor,
        uint256 _initDepositAmount,
        address _parameters,
        address _manager
    ) {
        string memory _name = "InsureDAO DEPEG Insurance LP";
        string memory _symbol = "iUSDTDEPEG";
        uint8 _decimals = 6;
        initializeToken(_name, _symbol, _decimals);

        parameters = IMarketParameters(_parameters);
        manager = IAssetManagement(_manager);

        // marketStatus = MarketStatus.Trading;
        if (_initDepositAmount != 0) {
            _depositFrom(_initDepositAmount, _initDepositor);
        }
    }

    /**
     * Public Functions
     */

    /// @notice inherit IMarket
    function deposit(uint256 _amount) external override whenNotPaused returns (uint256) {
        return _depositFrom(_amount, msg.sender);
    }

    function _depositFrom(uint256 _amount, address _from) internal returns (uint256 _mintAmount) {
        if (_amount == 0) revert AmountZero();
        _mintAmount = worth(_amount);
        //add to manager
        manager.addValue(_amount, _from);

        // reward pool
        uint256 _reward = _updateReward(_from);
        if (_reward > 0) {
            address _rewardPool = parameters.getRewardPool(address(this));
            IRewardPool(_rewardPool).addReward(_reward, _from);
            manager.withdrawReward(_reward, _rewardPool);
        }

        //mint iToken
        _mint(_from, _mintAmount);
        emit Deposit(_from, _amount, _mintAmount, rate());
    }

    /// @notice inherit IMarket
    function requestWithdraw(uint256 _amount) external override {
        if (_amount == 0) revert AmountZero();
        if (balanceOf(msg.sender) < _amount) revert RequestExceedBalance();

        uint256 _unlocksAt = block.timestamp + parameters.getLockup(address(this));

        withdrawalReq[msg.sender].timestamp = _unlocksAt;
        withdrawalReq[msg.sender].amount = _amount;
        emit WithdrawRequested(msg.sender, _amount, _unlocksAt);
    }

    /// @notice inherit IMarket
    function withdraw(uint256 _amount) external override returns (uint256 _retVal) {
        if (_amount == 0) revert AmountZero();
        Withdrawal memory request = withdrawalReq[msg.sender];

        // check period
        if (block.timestamp < request.timestamp) revert YetTime();
        if (block.timestamp > request.timestamp + parameters.getWithdrawablePeriod(address(this))) revert OverTime();

        //reduce requested amount
        if (request.amount < _amount) revert AmountExceeded();
        unchecked {
            withdrawalReq[msg.sender].amount -= _amount;
        }

        // withdraw liquidity
        uint256 _supply = totalSupply();
        if (_supply == 0) revert NoSupply();
        _retVal = (_amount * totalLiquidity()) / _supply;
        manager.withdrawValue(_retVal, msg.sender);
        emit Withdraw(msg.sender, _amount, _retVal, rate());

        // reward pool
        uint256 _reward = _updateReward(msg.sender);
        if (_reward > 0) {
            address _rewardPool = parameters.getRewardPool(address(this));
            IRewardPool(_rewardPool).addReward(_reward, msg.sender);
            manager.withdrawReward(_reward, _rewardPool);
        }

        _burn(msg.sender, _amount);
    }

    /// @notice inherit IMarket
    function unlockBatch(uint256[] calldata _ids) external override {
        uint256 idsLength = _ids.length;
        for (uint256 i; i < idsLength; ) {
            _unlock(_ids[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice inherit IMarket
    function unlock(uint256 _id) external override {
        _unlock(_id);
    }

    /// @notice inherit IMarket
    function terminateBatch(uint256[] calldata _ids) external override {
        uint256 idsLength = _ids.length;
        for (uint256 i; i < idsLength; ) {
            _terminate(_ids[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice inherit IMarket
    function terminate(uint256 _id) external override {
        _terminate(_id);
    }

    /**
     * @notice Unlock funds locked in the expired insurance (for internal usage)
     * @param _id id of the insurance policy to unlock liquidity
     */
    function _unlock(uint256 _id) internal {
        if (!insurances[_id].status) revert InsuranceNotActive();
        if (insurances[_id].endTime + parameters.getGrace(address(this)) >= block.timestamp)
            revert InsuranceNotExpired();

        _deactivate(_id);

        emit Unlocked(_id, insurances[_id].amount);
    }

    /**
     * @notice Terminate and unlock funds locked in the insurance if a price is beyond a certain threshold
     * @param _id id of the insurance policy to unlock liquidity
     */
    function _terminate(uint256 _id) internal {
        if (!insurances[_id].status) revert InsuranceNotActive();
        if (!isTerminatable()) revert NotTerminatable();

        _deactivate(_id);

        emit Terminated(_id, insurances[_id].amount);
    }

    /**
     * @notice Common internal function to unutilize the underlying funds
     * @param _id id of the insurance policy to unlock liquidity
     */
    function _deactivate(uint256 _id) internal {
        insurances[_id].status = false;
        uint256 _amount = insurances[_id].amount;
        manager.unutilize(_amount);
    }

    /// @notice inherit IMarket
    function insureByPeriod(uint256 _amount, uint48 _period) external override notRestricted returns (uint256) {
        return _insure(_amount, _periodToSpan(_period), msg.sender);
    }

    /// @notice inherit IMarket
    function insureByPeriodDelegate(
        uint256 _amount,
        uint48 _period,
        address _consignor
    ) external override onlyDelegator notZeroAddress(_consignor) returns (uint256) {
        return _insure(_amount, _periodToSpan(_period), _consignor);
    }

    /// @notice inherit IMarket
    function insure(uint256 _amount, uint256 _span) external override notRestricted returns (uint256) {
        return _insure(_amount, _span, msg.sender);
    }

    /// @notice inherit IMarket
    function insureDelegate(
        uint256 _amount,
        uint256 _span,
        address _consignor
    ) external override onlyDelegator notZeroAddress(_consignor) returns (uint256) {
        return _insure(_amount, _span, _consignor);
    }

    function _insure(
        uint256 _amount,
        uint256 _span,
        address _consignor
    ) internal onlyWhenNotVolatile whenNotPaused returns (uint256 _id) {
        if (_span > parameters.getMaxDate(address(this)) || _span < parameters.getMinDate(address(this)))
            revert OutOfSpan();

        //Distribute premium and fee
        (uint256 _premium, uint256 _fee) = _getPremiumAndFee(_amount, _span);
        manager.utilize(_amount, _premium, _fee, _consignor);

        //Lock covered amount
        uint256 _endTime = _span + block.timestamp;
        _id = allInsuranceCount++;
        insurances[_id] = Insurance(_id, (uint48)(block.timestamp), (uint48)(_endTime), _amount, msg.sender, true);

        emit Insured(_id, _amount, block.timestamp, _endTime, msg.sender, _premium);
    }

    /// @notice inherit IMarket
    function extendInsurance(uint256 _id, uint48 _span)
        external
        override
        onlyWhenNotVolatile
        whenNotPaused
        notRestricted
        checkInsurance(_id)
    {
        Insurance memory _insurance = insurances[_id];
        uint48 _newEndTime = _insurance.endTime + _span;
        uint256 _newSpan = _newEndTime - block.timestamp;
        if (_newSpan >= parameters.getMaxDate(address(this))) revert InsureExceededMaxSpan();

        (uint256 _premium, uint256 _fee) = _getPremiumAndFee(_insurance.amount, _span);
        manager.payFees(_premium, _fee, msg.sender);
        insurances[_id].endTime = _newEndTime;

        emit InsuranceExtended(_id, _newEndTime);
    }

    /// @notice inherit IMarket
    function increaseInsuranceDelegate(
        uint256 _id,
        uint256 _amount,
        address _consignor
    ) external override onlyDelegator notZeroAddress(_consignor) {
        _increaseInsurance(_id, _amount, _consignor);
    }

    /// @notice inherit IMarket
    function increaseInsurance(uint256 _id, uint256 _amount) external override notRestricted {
        _increaseInsurance(_id, _amount, msg.sender);
    }

    /// @notice inherit IMarket
    function _increaseInsurance(
        uint256 _id,
        uint256 _amount,
        address _consignor
    ) internal onlyWhenNotVolatile whenNotPaused checkInsurance(_id) {
        Insurance memory _insurance = insurances[_id];
        uint256 _span = _insurance.endTime - block.timestamp;
        (uint256 _premium, uint256 _fee) = _getPremiumAndFee(_amount, _span);
        manager.utilize(_amount, _premium, _fee, _consignor);

        insurances[_id].amount += _amount;
        emit InsuranceIncreased(_id, _amount);
    }

    /// @notice inherit IMarket
    function transferInsurance(uint256 _id, address _newInsured)
        external
        override
        onlyWhenNotVolatile
        whenNotPaused
        notRestricted
        checkInsurance(_id)
    {
        Insurance storage _insurance = insurances[_id];
        _insurance.insured = _newInsured;
        emit TransferInsurance(_id, msg.sender, _newInsured);
    }

    /// @notice inherit IMarket
    function decreaseInsurance(
        uint256 _id,
        uint256 _amount,
        address _consignor
    ) external override onlyWhenNotVolatile whenNotPaused notRestricted checkInsurance(_id) {
        Insurance storage _insurance = insurances[_id];
        if (_insurance.amount < _amount) revert AmountExceeded();

        _insurance.amount -= _amount;
        if (_insurance.amount == 0) {
            _insurance.status = false;
        }

        uint256[] memory _params = IRefundModel(parameters.getRefundModel(address(this))).getRefundAmount(
            _amount,
            _insurance.endTime
        );
        manager.cancel(_amount, _params, _consignor);

        emit InsuranceDecreased(_id, _amount, _insurance.amount, _insurance.insured, _insurance.status);
    }

    /// @notice inherit IMarket
    function redeem(uint256 _id, uint256 _amount) external override {
        _redeem(_id, _amount, msg.sender, address(0));
    }

    /// @notice inherit IMarket
    function redeemDelegate(
        uint256 _id,
        uint256 _amount,
        address _beneficiary
    ) external override onlyDelegator notZeroAddress(_beneficiary) {
        _redeem(_id, _amount, _beneficiary, address(0));
    }

    /// @notice inherit IMarket
    function redeemByToken(
        uint256 _id,
        uint256 _amount,
        address _redeemToken
    ) external override {
        _redeem(_id, _amount, msg.sender, _redeemToken);
    }

    /// @notice inherit IMarket
    function redeemByTokenDelegate(
        uint256 _id,
        uint256 _amount,
        address _beneficiary,
        address _redeemToken
    ) external override onlyDelegator notZeroAddress(_beneficiary) {
        _redeem(_id, _amount, _beneficiary, _redeemToken);
    }

    /// @notice inherit IMarket
    function _redeem(
        uint256 _id,
        uint256 _amount,
        address _beneficiary,
        address _redeemToken
    ) internal onlyDepeg {
        Insurance memory _insurance = insurances[_id];
        if (!_insurance.status) revert InsuranceNotActive();
        if (insurances[_id].endTime + parameters.getGrace(address(this)) < block.timestamp) revert InsuranceExpired();
        if (_insurance.insured != msg.sender) revert NotYourInsurance();
        if (_insurance.amount < _amount) revert AmountExceeded();

        uint256 _remaining = _insurance.amount - _amount;
        insurances[_id].amount = _remaining;
        if (_remaining == 0) {
            insurances[_id].status = false;
        }

        manager.repayAndRedeem(_amount, _beneficiary, _redeemToken);

        emit Redeemed(_id, _amount, _remaining, _insurance.insured, _remaining != 0);
    }

    /**
     * Utilities
     */

    /// @notice inherit IMarket
    function getCostByPeriod(uint256 _amount, uint48 _endTime) external view override returns (uint256) {
        return getCost(_amount, _endTime - block.timestamp);
    }

    /// @notice inherit IMarket
    function getCost(uint256 _amount, uint256 _span) public view override returns (uint256) {
        (uint256 _premium, uint256 _fee) = _getPremiumAndFee(_amount, _span);
        return _premium + _fee;
    }

    function _getPremiumAndFee(uint256 _amount, uint256 _span) private view returns (uint256 _premium, uint256 _fee) {
        _premium = IPremiumModel(parameters.getPremiumModel(address(this))).getPremium(
            _amount,
            _span,
            parameters.getPremiumRate(address(this)),
            parameters.getCommissionRate(address(this)),
            maxCapacity(),
            availableBalance()
        );
        _fee = IPremiumModel(parameters.getPremiumModel(address(this))).getFee(
            _amount,
            _span,
            parameters.getFeeRate(address(this))
        );
    }

    /// @notice inherit IMarket
    function rate() public view override returns (uint256) {
        uint256 _supply = totalSupply();
        if (_supply != 0) {
            return (totalLiquidity() * MAGIC_SCALE_1E8) / _supply;
        }
        return 0;
    }

    /// @notice inherit IMarket
    function valueOfUnderlying(address _owner) external view override returns (uint256) {
        uint256 _supply = totalSupply();
        if (_supply != 0) {
            return (balanceOf(_owner) * totalLiquidity()) / _supply;
        }
        return 0;
    }

    /// @notice inherit IMarket
    function worth(uint256 _value) public view override returns (uint256) {
        uint256 _supply = totalSupply();
        if (_supply == 0) {
            return _value;
        } else {
            uint256 _principal = totalLiquidity();
            if (_principal == 0) {
                return _value * _supply;
            } else {
                return (_value * _supply) / _principal;
            }
        }
    }

    /// @notice inherit IMarket
    function availableBalance() public view override returns (uint256) {
        return manager.getAvailableOrAaveAvailable();
    }

    /// @notice inherit IMarket
    function totalLiquidity() public view override returns (uint256) {
        return manager.getPrincipal();
    }

    /// @notice inherit IMarket
    function withdrawableAmount() external view override returns (uint256) {
        return manager.getWithdrawable();
    }

    /// @notice inherit IMarket
    function shortPositions() external view override returns (uint256) {
        return manager.originalDebt();
    }

    /// @notice inherit IMarket
    function getAccruedReward() public view override returns (uint256) {
        return manager.getAccruedReward();
    }

    /// @notice inherit IMarket
    function maxCapacity() public view override returns (uint256) {
        return manager.getMaxBorrowable();
    }

    /// @notice inherit IMarket
    function isRewardMode() public view override returns (bool) {
        if (parameters.getRewardMode(address(this)) == 1) return true;
        return false;
    }

    /// @notice inherit IMarket
    function setManager(address _manager) external onlyOwner {
        if (address(manager) != address(0)) revert AlreadySetManager();
        manager = IAssetManagement(_manager);
    }

    /// @notice implement for Restriction
    function setDelegator(address _delegator, bool _allowance) external onlyOwner {
        delegators[_delegator] = _allowance;
    }

    /// @notice implement for Restriction
    function restrict(bool _restriction) external onlyOwner {
        _restrict(_restriction);
    }

    /// @notice implement for Restriction
    function permit(address _target, bool _approval) external onlyOwner {
        _permit(_target, _approval);
    }

    /// @notice implement for Pausable
    function setPaused(bool _state) external onlyOwner {
        _pause(_state);
    }

    /**
     * Migration Function
     */
    /// @notice inherit IMarket
    function migrate(
        address _to,
        address[] calldata _references,
        uint256[] calldata _params
    ) external override onlyOwner {
        IMigrationAsset(address(manager)).emigrate(_to, _references, _params);
        address _from = address(manager);
        manager = IAssetManagement(_to);
        emit Migration(_from, _to);
    }

    /**
     * Internal functions
     */
    function _periodToSpan(uint48 _period) internal view returns (uint256 _span) {
        if (_period < block.timestamp) revert BeforeNow();
        unchecked {
            _span = uint256(_period) - block.timestamp;
        }
    }

    /**
     * @notice Internal function to offset withdraw request and latest balance
     * @param from the account who send
     * @param to a
     * @param amount the amount of tokens to offset
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from != address(0)) {
            uint256 reqAmount = withdrawalReq[from].amount;
            if (reqAmount != 0) {
                uint256 _after = balanceOf(from) - amount;
                if (_after < reqAmount) {
                    withdrawalReq[from].amount = _after;
                }
            }
        }
    }

    /// @notice inherit AbstractOwner
    function getOwner() public view override returns (address) {
        return parameters.getOwner();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IAaveV3Pool} from "./IAaveV3Pool.sol";
import {IAaveV3Reward} from "./IAaveV3Reward.sol";
import {IAssetManagement} from "./IAssetManagement.sol";
import {IExchangeLogic} from "./IExchangeLogic.sol";
import {IFungibleInitializer} from "./IFungibleInitializer.sol";
import {IFungiblePolicy} from "./IFungiblePolicy.sol";
import {IManagerParameters} from "./IManagerParameters.sol";
import {IMarket} from "./IMarket.sol";
import {IMarketParameters} from "./IMarketParameters.sol";
import {IMarketVolatility} from "./IMarketVolatility.sol";
import {IMigrationAsset} from "./IMigrationAsset.sol";
import {IOwnership} from "./IOwnership.sol";
import {IPlatypusPool} from "./IPlatypusPool.sol";
import {IPolicyFactory} from "./IPolicyFactory.sol";
import {IRefundModel} from "./IRefundModel.sol";
import {IPremiumModel} from "./IPremiumModel.sol";
import {IRewardPool} from "./IRewardPool.sol";
// import {ITwapOracle} from "./ITwapOracle.sol";

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import {IMarketParameters, IMarketVolatility} from "../interfaces/AllInterfaces.sol";
import "../twaps/ChainlinkTwap.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

// import "forge-std/console2.sol";

/**
 * @title MarketVolatility
 * @author @InsureDAO
 * @notice InsureDAO's Depeg insurance management of price oracle
 **/
abstract contract MarketVolatility is IMarketVolatility {
    using ChainlinkTwap for AggregatorV2V3Interface;
    uint256 private constant MAGIC_SCALE_1E8 = 1e8; //internal multiplication scale 1e8 to reduce decimal truncation

    /**
     * @notice get MarketParameters
     * @return MarketParameters MarketParameters address
     */
    function _marketParameters() internal view virtual returns (IMarketParameters);

    /// @notice inherit IMarketVolatility
    function isDepeg() public view override returns (bool) {
        uint256 _threshold = _marketParameters().getDepegThreshold(address(this));
        if (targetTwap() <= _threshold) return true;
        return false;
    }

    /// @notice inherit IMarketVolatility
    function isTerminatable() public view override returns (bool) {
        //spot
        uint256 _spotThreshold = _marketParameters().getSpotThreshold(address(this));
        if (spotRate() >= _spotThreshold) return true;
        //twap
        uint256 _threshold = _marketParameters().getThreshold(address(this));
        if (twapRate() >= _threshold) return true;
        return false;
    }

    /// @notice inherit IMarketVolatility
    function isVolatile() public view override returns (bool) {
        uint256 _spot = targetSpotPrice();
        uint256 _allowance = _marketParameters().getVolatilityAllowance(address(this));
        if (_spot >= MAGIC_SCALE_1E8 + _allowance || _spot <= MAGIC_SCALE_1E8 - _allowance) return true;
        return false;
    }

    /// @notice inherit IMarketVolatility
    function targetTwap() public view override returns (uint256) {
        AggregatorV2V3Interface _target = AggregatorV2V3Interface(
            _marketParameters().getChainlinkTarget(address(this))
        );
        return
            _target.getTwap(
                _marketParameters().getTwapLength(address(this)),
                _marketParameters().getTwapFrequency(address(this))
            );
    }

    /// @notice inherit IMarketVolatility
    function baseTwap() public view override returns (uint256) {
        AggregatorV2V3Interface _base = AggregatorV2V3Interface(_marketParameters().getChainlinkBase(address(this)));
        return
            _base.getTwap(
                _marketParameters().getTwapLength(address(this)),
                _marketParameters().getTwapFrequency(address(this))
            );
    }

    /// @notice inherit IMarketVolatility
    function targetSpotPrice() public view override returns (uint256) {
        AggregatorV2V3Interface _target = AggregatorV2V3Interface(
            _marketParameters().getChainlinkTarget(address(this))
        );
        return _target.getLatestPrice();
    }

    /// @notice inherit IMarketVolatility
    function baseSpotPrice() public view override returns (uint256) {
        AggregatorV2V3Interface _base = AggregatorV2V3Interface(_marketParameters().getChainlinkBase(address(this)));
        return _base.getLatestPrice();
    }

    /// @notice inherit IMarketVolatility
    function twapRate() public view override returns (uint256) {
        return (baseTwap() * MAGIC_SCALE_1E8) / targetTwap();
    }

    /// @notice inherit IMarketVolatility
    function spotRate() public view override returns (uint256) {
        return (baseSpotPrice() * MAGIC_SCALE_1E8) / targetSpotPrice();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;
/**
 * @title Restriction
 * @author @InsureDAO
 * @notice InsureDAO's Depeg insurance access controll for specific user
 **/
contract Restriction {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event RestrictionChanged(bool _restrictionMode);

    error Restricted();
    error AlreadyRestriction();

    mapping(address => bool) public permission;
    bool public restrictionMode;

    modifier notRestricted() {
        if (restrictionMode && !permission[msg.sender]) revert Restricted();
        _;
    }

    constructor() {
        restrictionMode = false;
    }

    /**
     * @notice Restrict buyers of insurances
     * @param _restrictionMode true if restricted
     */
    function _restrict(bool _restrictionMode) internal virtual {
        if (restrictionMode == _restrictionMode) revert AlreadyRestriction();
        restrictionMode = _restrictionMode;
        emit RestrictionChanged(_restrictionMode);
    }    

    /**
     * @notice permit who can do something
     * @param _target operator address
     * @param _approval true to get approved
     */
    function _permit(address _target, bool _approval) internal virtual {
        permission[_target] = _approval;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;
/**
 * @title Pausable
 * @author @InsureDAO
 * @notice InsureDAO's Depeg insurance access controll
 **/
abstract contract Pausable {
    error PausedError();
    error UnPausedError();
    error AlreadyPausedOrUnpausedError();

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(bool _pause);

    bool public paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        paused = false;
    }

    modifier whenNotPaused() {
        if (paused) revert PausedError();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert UnPausedError();
        _;
    }

    function _pause(bool _status) internal virtual {
        if (paused == _status) revert AlreadyPausedOrUnpausedError();
        paused = _status;
        emit Paused(_status);
    }    
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;
/**
 * @title AbstractOwner
 * @author @InsureDAO
 * @notice InsureDAO's Depeg insurance access management of owner
 **/
abstract contract AbstractOwner {
    error OnlyOwner();

    modifier onlyOwner() {
        if (getOwner() != msg.sender) revert OnlyOwner();
        _;
    }

    function getOwner() public virtual returns(address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

/**
 * @title ERC20Reward
 * @author @InsureDAO
 * @notice InsureDAO's Depeg insurance calclator of token rewards
 **/
import "./InsureDAOERC20.sol";

interface IERC20Reward {
    event UpdateReward(address _staker, uint256 _reward);

    function getAccruedReward() external view returns (uint256);

    function calculateReward(address _staker) external view returns (uint256 _reward, uint256 _rewardPerTokenStored);
}

abstract contract ERC20Reward is InsureDAOERC20, IERC20Reward {
    uint256 private constant MAGIC_SCALE_1E8 = 1e8; //internal multiplication scale 1e8 to reduce decimal truncation

    /**
     * Storage
     */
    uint256 public lastAccruedReward;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;

    /**
     * Private Functions
     */
    function _updateReward(address _staker) internal virtual returns (uint256) {
        if (!isRewardMode()) return 0;
        //calculate this terms rewards
        (uint256 _reward, uint256 _rewardPerTokenStored) = calculateReward(_staker);
        // after state
        rewardPerTokenStored = _rewardPerTokenStored;
        userRewardPerTokenPaid[_staker] = _rewardPerTokenStored;
        lastAccruedReward = getAccruedReward() - _reward; //must claim rewards

        emit UpdateReward(_staker, _reward);
        return _reward;
    }

    /**
     * Public Functions
     */
    function getAccruedReward() public view virtual override returns (uint256);

    function calculateReward(address _staker)
        public
        view
        override
        returns (uint256 _reward, uint256 _rewardPerTokenStored)
    {
        uint256 _termsReward = getAccruedReward() - lastAccruedReward;
        if (totalSupply() > 0) {
            _rewardPerTokenStored = (MAGIC_SCALE_1E8 * _termsReward) / totalSupply() + rewardPerTokenStored;
        } else {
            _rewardPerTokenStored = rewardPerTokenStored;
        }
        _reward = ((_rewardPerTokenStored - userRewardPerTokenPaid[_staker]) * balanceOf(_staker)) / MAGIC_SCALE_1E8;
    }

    function isRewardMode() public virtual returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IMigrationAsset.sol";

/**
 * @title IAssetManagement
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Asset Management.
 **/
interface IAssetManagement is IMigrationAsset {
    /**
     * STRUCTS
     */
    ///@notice aave tokens
    struct AaveTokens {
        address aBaseToken;
        address aTargetToken;
        address vTargetDebt;
        address sTargetDebt;
    }
    struct Performance {
        int256 lastUnderwriterFee;
        uint256 withdrawableProtocolFee;
    }

    /**
     * EVENTS
     */
    event ExchangeLogic(address exchangeLogic);
    event Aave(address _aave);

    /**
     * FUNCTIONS
     */

    /**
     * @notice A market contract can deposit collateral and get attribution point in return
     * @param  _amount amount of tokens to deposit
     * @param _from sender's address
     */
    function addValue(uint256 _amount, address _from) external;

    /**
     * @notice an address that has balance in the vault can withdraw underlying value
     * @param _amount amount of tokens to withdraw
     * @param _to address to get underlying tokens
     */
    function withdrawValue(uint256 _amount, address _to) external;

    /**
     * @notice apply leverage and create position of depeg coverage. used when insure() is called
     * @param _amount amount of USDT position
     * @param _premium premium amount
     * @param _protocolFee fee amount
     * @param _from who pays fees
     */
    function utilize(
        uint256 _amount,
        uint256 _premium,
        uint256 _protocolFee,
        address _from
    ) external;

    /**
     * @notice dissolve and deleverage positions
     * @param _amount amount to unutilize
     */
    function unutilize(uint256 _amount) external;

    /**
     * @notice unutilize and pay premium back
     * @param _amount amount to unutilize
     * @param _params parameters
     * @param _to address to get premium back
     */
    function cancel(
        uint256 _amount,
        uint256[] memory _params,
        address _to
    ) external;

    /**
     * @notice repay USDT debt and redeem USDC. Expected to be used when depeg happend.
     * @param _amount amount to redeem
     * @param _from redeem destination
     */
    function repayAndRedeem(
        uint256 _amount,
        address _from,
        address _redeemToken
    ) external;

    /**
     * @notice pay fees. Expected to use when extend the position holding length.
     * @param _premium premium amount
     * @param _protocolFee fee amount
     * @param _from who pays fees
     */
    function payFees(
        uint256 _premium,
        uint256 _protocolFee,
        address _from
    ) external;

    /**
     * @notice withdraw Aave's accrued reward tokens
     * @param _rewardAmount market's receipient amount
     * @param _to receipient of reward
     */
    function withdrawReward(uint256 _rewardAmount, address _to) external;

    /**
     * @notice get debt amount without interest
     */
    function originalDebt() external view returns (uint256);

    /**
     * @notice get principal value in USDC.
     */
    function getPrincipal() external view returns (uint256);

    /**
     * @notice get the latest status of performance and principal
     */
    function getPerformance()
        external
        view
        returns (
            uint256 _principal,
            uint256 _protocolPerformance,
            uint256 _underwritersPerformance
        );

    /**
     * @notice get how much can one withdraw USDC.
     */
    function getWithdrawable() external view returns (uint256);

    /**
     * @notice get maximum USDT short positions can be hold in the contract.
     */
    function getMaxBorrowable() external view returns (uint256);

    /**
     * @notice get how much USDT short positions can be hold in the contract.
     */
    function getAvailable() external view returns (uint256);

    /**
     * @notice avairable for deposit USDC within aave max utilization(USDT borrowable).
     */
    function getAvailableOrAaveAvailable() external view returns (uint256);

    /**
     * @notice get how much usdt short position can be taken safely from this account.
     * maxUtilizationRateAfterBorrow prevents borrwing too much and increase utilization beyond allowance.
     */
    function calcAaveAvailableBorrow() external view returns (uint256 avairableBorrow);

    /**
     * @notice get how much usdc deposit position can be taken safely from this account.
     * maxOccupancyRate prevents supplying too much
     */
    function calcAaveAvailableSupplyUsdc() external view returns (uint256 avairableSupply);

    /**
     * @notice get Aave's accrured rewards
     */
    function getAccruedReward() external view returns (uint256);

    /**
     * @notice set exchangeLogic and approve it
     * @param _exchangeLogic exchangeLogic
     */
    function setExchangeLogic(address _exchangeLogic) external;

    /**
     * @notice set aave lending pool address and approve it
     * @param _aave aave lending pool address
     */
    function setAave(address _aave) external;

    /**
     * @notice withdraw redundant token stored in this contract
     * @param _token token address
     * @param _to beneficiary's address
     */
    function withdrawRedundant(address _token, address _to) external;

    /**
     * @notice swap redundant targetToken and supply it
     */
    function supplyRedundantTargetToken() external returns (uint256 _supplyed);

    /**
     * @notice withdraw accrued protocol fees.
     * @param _to withdrawn fee destination
     */
    function withdrawProtocolReserve(address _to) external;

    /**
     * ERRORS
     */
    error OnlyMarket();
    error ZeroAddress();
    error AmmountExceeded();
    error LackOfPremium();
    error AaveMismatch();
    error AaveExceedUtilizationCap();
    error AaveOccupyTooMuch();
    error UnsupportedRedeemToken();
    error LessSwappedThanEstimated();
    error ExceedReserved();
    error ZeroBalance();
    error NonWithdrawableToken();
    error ZeroAmount();
    error SwapFailed();
    error BeyondSlippageTolerance();
    error LackOfOriginalSupply();
}

// SPDX-License-Identifier: AGPL-3.0
// Forked and minimized from https://github.com/aave/aave-v3-core/blob/master/contracts/interfaces/IPool.sol
pragma solidity ^0.8.0;

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 **/
interface IAaveV3Pool {
    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
     * equivalent debt tokens
     * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
     * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
     * balance is not enough to cover the whole debt
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @return The final amount repaid
     **/
    function repayWithATokens(
        address asset,
        uint256 amount,
        uint256 interestRateMode
    ) external returns (uint256);

    /**
     * @notice Allows a user to use the protocol in eMode
     * @param categoryId The id of the category
     */
    function setUserEMode(uint8 categoryId) external;

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @dev Deprecated: Use the `supply` function instead
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @notice Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @notice Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
     * @return totalDebtBase The total debt of the user in the base currency used by the price feed
     * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
     * @return currentLiquidationThreshold The liquidation threshold of the user
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     **/
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
     * @param asset The address of the asset being flash-borrowed
     * @param amount The amount of the asset being flash-borrowed
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Returns the total fee on flash loans
     * @return The total fee on flashloans
     */
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

    /**
     * @notice Returns the part of the flashloan fees sent to protocol
     * @return The flashloan fee sent to the protocol treasury
     */
    function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);
}

// SPDX-License-Identifier: agpl-3.0
// Forked and minimized from https://github.com/aave/aave-v3-periphery/blob/master/contracts/rewards/interfaces/IRewardsDistributor.sol
pragma solidity ^0.8.0;

interface IAaveV3Reward {
    // /**
    //  * @dev Sets the end date for the distribution
    //  * @param asset The asset to incentivize
    //  * @param reward The reward token that incentives the asset
    //  * @param newDistributionEnd The end date of the incentivization, in unix time format
    //  **/
    // function setDistributionEnd(
    //   address asset,
    //   address reward,
    //   uint32 newDistributionEnd
    // ) external;

    // /**
    //  * @dev Sets the emission per second of a set of reward distributions
    //  * @param asset The asset is being incentivized
    //  * @param rewards List of reward addresses are being distributed
    //  * @param newEmissionsPerSecond List of new reward emissions per second
    //  */
    // function setEmissionPerSecond(
    //   address asset,
    //   address[] calldata rewards,
    //   uint88[] calldata newEmissionsPerSecond
    // ) external;

    // /**
    //  * @dev Gets the end date for the distribution
    //  * @param asset The incentivized asset
    //  * @param reward The reward token of the incentivized asset
    //  * @return The timestamp with the end of the distribution, in unix time format
    //  **/
    // function getDistributionEnd(address asset, address reward) external view returns (uint256);

    // /**
    //  * @dev Returns the index of a user on a reward distribution
    //  * @param user Address of the user
    //  * @param asset The incentivized asset
    //  * @param reward The reward token of the incentivized asset
    //  * @return The current user asset index, not including new distributions
    //  **/
    // function getUserAssetIndex(
    //   address user,
    //   address asset,
    //   address reward
    // ) external view returns (uint256);

    // /**
    //  * @dev Returns the configuration of the distribution reward for a certain asset
    //  * @param asset The incentivized asset
    //  * @param reward The reward token of the incentivized asset
    //  * @return The index of the asset distribution
    //  * @return The emission per second of the reward distribution
    //  * @return The timestamp of the last update of the index
    //  * @return The timestamp of the distribution end
    //  **/
    // function getRewardsData(address asset, address reward)
    //   external
    //   view
    //   returns (
    //     uint256,
    //     uint256,
    //     uint256,
    //     uint256
    //   );

    // /**
    //  * @dev Returns the list of available reward token addresses of an incentivized asset
    //  * @param asset The incentivized asset
    //  * @return List of rewards addresses of the input asset
    //  **/
    // function getRewardsByAsset(address asset) external view returns (address[] memory);

    // /**
    //  * @dev Returns the list of available reward addresses
    //  * @return List of rewards supported in this contract
    //  **/
    // function getRewardsList() external view returns (address[] memory);

    /**
     * @dev Returns the accrued rewards balance of a user, not including virtually accrued rewards since last distribution.
     * @param user The address of the user
     * @param reward The address of the reward token
     * @return Unclaimed rewards, not including new distributions
     **/
    function getUserAccruedRewards(address user, address reward) external view returns (uint256);

    // /**
    //  * @dev Returns a single rewards balance of a user, including virtually accrued and unrealized claimable rewards.
    //  * @param assets List of incentivized assets to check eligible distributions
    //  * @param user The address of the user
    //  * @param reward The address of the reward token
    //  * @return The rewards amount
    //  **/
    // function getUserRewards(
    //   address[] calldata assets,
    //   address user,
    //   address reward
    // ) external view returns (uint256);

    // /**
    //  * @dev Returns a list all rewards of a user, including already accrued and unrealized claimable rewards
    //  * @param assets List of incentivized assets to check eligible distributions
    //  * @param user The address of the user
    //  * @return The list of reward addresses
    //  * @return The list of unclaimed amount of rewards
    //  **/
    // function getAllUserRewards(address[] calldata assets, address user)
    //   external
    //   view
    //   returns (address[] memory, uint256[] memory);

    // /**
    //  * @dev Returns the decimals of an asset to calculate the distribution delta
    //  * @param asset The address to retrieve decimals
    //  * @return The decimals of an underlying asset
    //  */
    // function getAssetDecimals(address asset) external view returns (uint8);

    // /**
    //  * @dev Returns the address of the emission manager
    //  * @return The address of the EmissionManager
    //  */
    // function getEmissionManager() external view returns (address);

    // /**
    //  * @dev Updates the address of the emission manager
    //  * @param emissionManager The address of the new EmissionManager
    //  */
    // function setEmissionManager(address emissionManager) external;

    //   /**
    //  * @dev Whitelists an address to claim the rewards on behalf of another address
    //  * @param user The address of the user
    //  * @param claimer The address of the claimer
    //  */
    // function setClaimer(address user, address claimer) external;

    // /**
    //  * @dev Sets a TransferStrategy logic contract that determines the logic of the rewards transfer
    //  * @param reward The address of the reward token
    //  * @param transferStrategy The address of the TransferStrategy logic contract
    //  */
    // // function setTransferStrategy(address reward, ITransferStrategyBase transferStrategy) external;

    // /**
    //  * @dev Sets an Aave Oracle contract to enforce rewards with a source of value.
    //  * @notice At the moment of reward configuration, the Incentives Controller performs
    //  * a check to see if the reward asset oracle is compatible with IEACAggregator proxy.
    //  * This check is enforced for integrators to be able to show incentives at
    //  * the current Aave UI without the need to setup an external price registry
    //  * @param reward The address of the reward to set the price aggregator
    //  * @param rewardOracle The address of price aggregator that follows IEACAggregatorProxy interface
    //  */
    // // function setRewardOracle(address reward, IEACAggregatorProxy rewardOracle) external;

    // /**
    //  * @dev Get the price aggregator oracle address
    //  * @param reward The address of the reward
    //  * @return The price oracle of the reward
    //  */
    // function getRewardOracle(address reward) external view returns (address);

    // /**
    //  * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
    //  * @param user The address of the user
    //  * @return The claimer address
    //  */
    // function getClaimer(address user) external view returns (address);

    // /**
    //  * @dev Returns the Transfer Strategy implementation contract address being used for a reward address
    //  * @param reward The address of the reward
    //  * @return The address of the TransferStrategy contract
    //  */
    // function getTransferStrategy(address reward) external view returns (address);

    // /**
    //  * @dev Configure assets to incentivize with an emission of rewards per second until the end of distribution.
    //  * @param config The assets configuration input, the list of structs contains the following fields:
    //  *   uint104 emissionPerSecond: The emission per second following rewards unit decimals.
    //  *   uint256 totalSupply: The total supply of the asset to incentivize
    //  *   uint40 distributionEnd: The end of the distribution of the incentives for an asset
    //  *   address asset: The asset address to incentivize
    //  *   address reward: The reward token address
    //  *   ITransferStrategy transferStrategy: The TransferStrategy address with the install hook and claim logic.
    //  *   IEACAggregatorProxy rewardOracle: The Price Oracle of a reward to visualize the incentives at the UI Frontend.
    //  *                                     Must follow Chainlink Aggregator IEACAggregatorProxy interface to be compatible.
    //  */
    // // function configureAssets(RewardsDataTypes.RewardsConfigInput[] memory config) external;

    // /**
    //  * @dev Called by the corresponding asset on any update that affects the rewards distribution
    //  * @param user The address of the user
    //  * @param userBalance The user balance of the asset
    //  * @param totalSupply The total supply of the asset
    //  **/
    // function handleAction(
    //   address user,
    //   uint256 userBalance,
    //   uint256 totalSupply
    // ) external;

    /**
     * @dev Claims reward for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
     * @param assets List of assets to check eligible distributions before claiming rewards
     * @param amount The amount of rewards to claim
     * @param to The address that will be receiving the rewards
     * @param reward The address of the reward token
     * @return The amount of rewards claimed
     **/
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to,
        address reward
    ) external returns (uint256);

    // /**
    //  * @dev Claims reward for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The
    //  * caller must be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
    //  * @param assets The list of assets to check eligible distributions before claiming rewards
    //  * @param amount The amount of rewards to claim
    //  * @param user The address to check and claim rewards
    //  * @param to The address that will be receiving the rewards
    //  * @param reward The address of the reward token
    //  * @return The amount of rewards claimed
    //  **/
    // function claimRewardsOnBehalf(
    //   address[] calldata assets,
    //   uint256 amount,
    //   address user,
    //   address to,
    //   address reward
    // ) external returns (uint256);

    // /**
    //  * @dev Claims reward for msg.sender, on all the assets of the pool, accumulating the pending rewards
    //  * @param assets The list of assets to check eligible distributions before claiming rewards
    //  * @param amount The amount of rewards to claim
    //  * @param reward The address of the reward token
    //  * @return The amount of rewards claimed
    //  **/
    // function claimRewardsToSelf(
    //   address[] calldata assets,
    //   uint256 amount,
    //   address reward
    // ) external returns (uint256);

    /**
     * @dev Claims all rewards for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
     * @param assets The list of assets to check eligible distributions before claiming rewards
     * @param to The address that will be receiving the rewards
     * @return rewardsList List of addresses of the reward tokens
     * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardList"
     **/
    function claimAllRewards(address[] calldata assets, address to)
        external
        returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

    // /**
    //  * @dev Claims all rewards for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The caller must
    //  * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
    //  * @param assets The list of assets to check eligible distributions before claiming rewards
    //  * @param user The address to check and claim rewards
    //  * @param to The address that will be receiving the rewards
    //  * @return rewardsList List of addresses of the reward tokens
    //  * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
    //  **/
    // function claimAllRewardsOnBehalf(
    //   address[] calldata assets,
    //   address user,
    //   address to
    // ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

    // /**
    //  * @dev Claims all reward for msg.sender, on all the assets of the pool, accumulating the pending rewards
    //  * @param assets The list of assets to check eligible distributions before claiming rewards
    //  * @return rewardsList List of addresses of the reward tokens
    //  * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
    //  **/
    // function claimAllRewardsToSelf(address[] calldata assets)
    //   external
    //   returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IExchangeLogic
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Exchange Logic.
 **/
interface IExchangeLogic {
    /**
     * @notice get swapper(router) address
     * @return swapper_ swapper address
     */
    function swapper() external returns (address);

    /**
     * @notice get encoded bytes of swapping to call swap by sender address
     * @param _tokenIn address of input token
     * @param _tokenOut address of output token
     * @param _amountIn amount of input token
     * @param _amountOutMin amount of minimum output token
     * @param _to to address
     * @return abiEncoded returns encoded bytes
     */
    function abiEncodeSwap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) external view returns (bytes memory);

    /**
     * @notice estimate being swapped amounts of _tokenOut
     * @param _tokenIn address of input token
     * @param _tokenOut address of output token
     * @param _amountIn amount of input token
     * @return amountOut_ returns the amount of _tokenOut swapped
     */
    function estimateAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256);

    /**
     * @notice estimate needed amounts of _tokenIn
     * @param _tokenIn address of input token
     * @param _tokenOut address of output token
     * @param _amountOutMin amount of minimum output token
     * @return amountIn_ returns the amount of _tokenIn needed
     */
    function estimateAmountIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOutMin
    ) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IAssetManagement.sol";

/**
 * @title IMarket
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Market.
 **/
interface IMarket {
    /**
     * STRUCTS
     */
    ///@notice user's withdrawal status management
    struct Withdrawal {
        uint256 timestamp;
        uint256 amount;
    }

    ///@notice insurance status management
    struct Insurance {
        uint256 id; //each insuance has their own id
        uint48 startTime; //timestamp of starttime
        uint48 endTime; //timestamp of endtime
        uint256 amount; //insured amount
        address insured; //the address holds the right to get insured
        bool status; //true if insurance is not expired
    }

    /**
     * EVENTS
     */
    event Deposit(address indexed depositor, uint256 amount, uint256 mint, uint256 pricePerToken);
    event WithdrawRequested(address indexed withdrawer, uint256 amount, uint256 unlockTime);
    event Withdraw(address indexed withdrawer, uint256 amount, uint256 retVal, uint256 pricePerToken);
    event Unlocked(uint256 indexed id, uint256 amount);
    event Terminated(uint256 indexed id, uint256 amount);
    event Insured(
        uint256 indexed id,
        uint256 amount,
        uint256 startTime,
        uint256 indexed endTime,
        address indexed insured,
        uint256 premium
    );
    event InsuranceIncreased(uint256 indexed id, uint256 amount);
    event InsuranceExtended(uint256 indexed id, uint256 endTime);
    event Redeemed(uint256 indexed id, uint256 payout, uint256 amount, address insured, bool status);
    event UnInsured(uint256 indexed id, uint256 feeback, uint256 amount, address insured, bool status);

    event Manager(address manager);
    event Migration(address from, address to);
    event InsuranceDecreased(uint256 id, uint256 amount, uint256 _newAmount, address insured, bool status);
    event TransferInsurance(uint256 indexed id, address from, address indexed newInsured);

    /**
     * FUNCTIONS
     */
    /**
     * @notice A liquidity provider supplies tokens to the pool and receives iTokens
     * @param _amount amount of tokens to deposit
     * @return _mintAmount the amount of iTokens minted from the transaction
     */
    function deposit(uint256 _amount) external returns (uint256);

    /**
     * @notice A liquidity provider request withdrawal of collateral
     * @param _amount amount of iTokens to burn
     */
    function requestWithdraw(uint256 _amount) external;

    /**
     * @notice A liquidity provider burns iTokens and receives collateral from the pool
     * @param _amount amount of iTokens to burn
     * @return _retVal the amount underlying tokens returned
     */
    function withdraw(uint256 _amount) external returns (uint256 _retVal);

    /**
     * @notice Unlocks an array of insurances
     * @param _ids array of ids to unlock
     */
    function unlockBatch(uint256[] calldata _ids) external;

    /**
     * @notice Unlock an insurance
     * @param _id id of the insurance policy to unlock liquidity
     */
    function unlock(uint256 _id) external;

    /**
     * @notice Terminates an array of insurances
     * @param _ids array of ids to unlock
     */
    function terminateBatch(uint256[] calldata _ids) external;

    /**
     * @notice Terminates an insurance
     * @param _id id of the insurance policy to unlock liquidity
     */
    function terminate(uint256 _id) external;

    /**
     * @notice Get insured for the specified amount for specified period
     * @param _amount target amount to get covered
     * @param _period end date to be covered(timestamp)
     * @return _id of the insurance policy
     */
    function insureByPeriod(uint256 _amount, uint48 _period) external returns (uint256);

    /**
     * @notice Get insured for the specified amount for specified period by delegator
     * @param _amount target amount to get covered
     * @param _period end date to be covered(timestamp)
     * @param _consignor consignor(payer) address
     * @return _id of the insurance policy
     */
    function insureByPeriodDelegate(
        uint256 _amount,
        uint48 _period,
        address _consignor
    ) external returns (uint256);

    /**
     * @notice Get insured for the specified amount for specified span
     * @param _amount target amount to get covered
     * @param _span length to get covered(e.g. 7 days)
     * @return _id of the insurance policy
     */
    function insure(uint256 _amount, uint256 _span) external returns (uint256);

    /**
     * @notice Get insured for the specified amount for specified span by delegator
     * @param _amount target amount to get covered
     * @param _span length to get covered(e.g. 7 days)
     * @param _consignor consignor(payer) address
     * @return _id of the insurance policy
     */
    function insureDelegate(
        uint256 _amount,
        uint256 _span,
        address _consignor
    ) external returns (uint256);

    /**
     * @notice extend end time of an insurance policy
     * @param _id id of a policy
     * @param _span length to extend(e.g. 7 days)
     */
    function extendInsurance(uint256 _id, uint48 _span) external;

    /**
     * @notice increase the coverage of an insurance policy by delegator
     * @param _id id of a policy
     * @param _amount coverage to increase
     * @param _consignor consignor(payer) address
     */
    function increaseInsuranceDelegate(
        uint256 _id,
        uint256 _amount,
        address _consignor
    ) external;

    /**
     * @notice increase the coverage of an insurance policy
     * @param _id id of a policy
     * @param _amount coverage to increase
     */
    function increaseInsurance(uint256 _id, uint256 _amount) external;

    /**
     * @notice Transfers an active insurance
     * @param _id id of the insurance policy
     * @param _newInsured new insured address
     */
    function transferInsurance(uint256 _id, address _newInsured) external;

    /**
     * @notice Transfers an active insurance
     * @param _id id of the insurance policy
     * @param _amount new insured address
     * @param _consignor address paid fee back
     */
    function decreaseInsurance(
        uint256 _id,
        uint256 _amount,
        address _consignor
    ) external;

    /**
     * @notice Redeem an insurance policy.
     * Allow split redemption for multiple times within the coverage amount.
     * @param _id the id of the insurance policy
     * @param _amount redeem amount
     */
    function redeem(uint256 _id, uint256 _amount) external;

    /**
     * @notice Redeem an insurance policy by delegator
     * Allow split redemption for multiple times within the coverage amount.
     * @param _id the id of the insurance policy
     * @param _amount redeem amount
     * @param _beneficiary address to get paid fee
     */
    function redeemDelegate(
        uint256 _id,
        uint256 _amount,
        address _beneficiary
    ) external;

    /**
     * @notice Redeem an insurance policy to payout other token
     * Allow split redemption for multiple times within the coverage amount.
     * @param _id the id of the insurance policy
     * @param _amount redeem amount
     * @param _redeemToken redeem by other tokens
     */
    function redeemByToken(
        uint256 _id,
        uint256 _amount,
        address _redeemToken
    ) external;

    /**
     * @notice Redeem an insurance policy to payout other token by delegator
     * Allow split redemption for multiple times within the coverage amount.
     * @param _id the id of the insurance policy
     * @param _amount redeem amount
     * @param _redeemToken redeem by other tokens
     * @param _beneficiary address to get paid token
     */
    function redeemByTokenDelegate(
        uint256 _id,
        uint256 _amount,
        address _beneficiary,
        address _redeemToken
    ) external;

    /**
     * @notice Get how much premium + fee for the specified amount and span
     * @param _amount amount to get insured
     * @param _endTime end time to get covered(timestamp)
     */
    function getCostByPeriod(uint256 _amount, uint48 _endTime) external view returns (uint256);

    /**
     * @notice Get how much premium + fee for the specified amount and span
     * @param _amount amount to get insured
     * @param _span span to get covered
     */
    function getCost(uint256 _amount, uint256 _span) external view returns (uint256);

    /**
     * @notice get how much value per one iToken supply. scaled by 1e8
     */
    function rate() external view returns (uint256);

    /**
     * @notice Get the underlying balance of the `owner`
     * @param _owner the target address to look up value
     * @return _value The balance of underlying tokens for the specified address
     */
    function valueOfUnderlying(address _owner) external view returns (uint256);

    /**
     * @notice Get token number for the specified underlying value
     * @param _value the amount of the underlying
     * @return _amount the number of the iTokens corresponding to _value
     */
    function worth(uint256 _value) external view returns (uint256);

    /**
     * @notice Returns the availability of cover
     * @return available liquidity of this pool
     */
    function availableBalance() external view returns (uint256);

    /**
     * @notice Pool's Liquidity
     * @return total liquidity of this pool
     */
    function totalLiquidity() external view returns (uint256);

    /**
     * @notice Deposited amount not utilized yet
     * @return withdrawableAmount max withdrawable amount
     */
    function withdrawableAmount() external view returns (uint256);

    /**
     * @notice Return short positions (=covered amount)
     * @return amount short positions
     */
    function shortPositions() external view returns (uint256);

    /**
     * @notice Pool's max capacity
     * @return total capacity of this pool
     */
    function maxCapacity() external view returns (uint256);

    /**
     * @notice manager address
     * @return manager AssetManagement address
     */
    function manager() external view returns (IAssetManagement);

    /**
     * @notice set delegators
     * @param _manager manager address
     */
    function setManager(address _manager) external;

    /**
     * @notice set delegators
     * @param _delegator delegator address
     * @param _allowance allowed or not
     */
    function setDelegator(address _delegator, bool _allowance) external;

    /**
     * @notice Enable mmigration of manager contract.
     * Expected to use when there is updates on contract or underlying conditions
     * @param _to next manager contract
     * @param _references address params to pass to the new manager
     * @param _params parameters to pass to the new contract
     */
    function migrate(
        address _to,
        address[] calldata _references,
        uint256[] calldata _params
    ) external;

    /**
     * ERRORS
     */
    error NotApplicable();
    error NotTerminatable();
    error TooVolatile();
    error OnlyDelegator();
    error AmountZero();
    error RequestExceedBalance();
    error YetTime();
    error OverTime();
    error AmountExceeded();
    error NoSupply();
    error ZeroAddress();
    error BeforeNow();
    error OutOfSpan();
    error InsuranceNotActive();
    error InsuranceExpired();
    error InsuranceNotExpired();
    error InsureExceededMaxSpan();
    error NotYourInsurance();
    error MigrationFailed();
    error OnlyManager();
    error AlreadySetManager();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IManagerParameters
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Manager Parameters.
 **/
interface IManagerParameters {
    function setLeverage(address _target, uint256 _value) external;

    function getLeverage(address _target) external view returns (uint256);

    function setPerformanceFeeRate(address _target, uint256 _value) external;

    function getPerformanceFeeRate(address _target) external view returns (uint256);

    function setBorrowingPower(address _target, uint256 _value) external;

    function getBorrowingPower(address _target) external view returns (uint256);

    function setMaxUtilizationRateAfterBorrow(address _target, uint256 _value) external;

    function getMaxUtilizationRateAfterBorrow(address _target) external view returns (uint256);

    function setMaxOccupancyRate(address _target, uint256 _value) external;

    function getMaxOccupancyRate(address _target) external view returns (uint256);

    function setSlippageTolerance(address _target, uint256 _value) external;

    function getSlippageTolerance(address _target) external view returns (uint256);

    function setPerformancePool(address _target, address _address) external;

    function getPerformancePool(address _target) external view returns (address);

    function getOwner() external view returns (address);

    error OnlyUpper();
    error ZeroAddress();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IMarketParameters
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Market Parameters.
 **/
interface IMarketParameters {
    /**
     * FUNCTIONS
     */
    function setLockup(address _target, uint256 _value) external;

    function getLockup(address _target) external view returns (uint256);

    function setMaxDate(address _target, uint256 _value) external;

    function getMaxDate(address _target) external view returns (uint256);

    function setMinDate(address _target, uint256 _value) external;

    function getMinDate(address _target) external view returns (uint256);

    function setPremiumModel(address _target, address _address) external;

    function getPremiumModel(address _market) external view returns (address);

    function setPremiumRate(address _target, uint256 _value) external;

    function getPremiumRate(address _target) external view returns (uint256);

    function setCommissionRate(address _target, uint256 _value) external;

    function getCommissionRate(address _target) external view returns (uint256);

    function setWithdrawablePeriod(address _target, uint256 _value) external;

    function getWithdrawablePeriod(address _target) external view returns (uint256);

    function setGrace(address _target, uint256 _value) external;

    function getGrace(address _target) external view returns (uint256);

    function setTwapLength(address _target, uint256 _value) external;

    function getTwapLength(address _target) external view returns (uint256);

    function setTwapFrequency(address _target, uint256 _value) external;

    function getTwapFrequency(address _target) external view returns (uint256);

    function setDepegThreshold(address _target, uint256 _value) external;

    function getDepegThreshold(address _target) external view returns (uint256);

    function setThreshold(address _target, uint256 _value) external;

    function getThreshold(address _target) external view returns (uint256);

    function setSpotThreshold(address _target, uint256 _value) external;

    function getSpotThreshold(address _target) external view returns (uint256);

    function setVolatilityAllowance(address _target, uint256 _value) external;

    function getVolatilityAllowance(address _target) external view returns (uint256);

    function setRewardMode(address _target, uint256 _value) external;

    function getRewardMode(address _target) external view returns (uint256);

    function setRewardPool(address _target, address _address) external;

    function getRewardPool(address _target) external view returns (address);

    function setChainlinkTarget(address _target, address _address) external;

    function getChainlinkTarget(address _target) external view returns (address);

    function setChainlinkBase(address _target, address _address) external;

    function getChainlinkBase(address _target) external view returns (address);

    function setRefundModel(address _target, address _address) external;

    function getRefundModel(address _market) external view returns (address);

    function setFeeRate(address _target, uint256 _value) external;

    function getFeeRate(address _target) external view returns (uint256);

    function getOwner() external view returns (address);

    /**
     * ERRORS
     */
    error ZeroAddress();
    error SmallerThanMindate();
    error LargerThanMaxdate();
    error ExceedMaxFeeRate();
    error ExceedOneDoller();
    error SameNumber();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IMigrationAsset
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Asset Migration.
 **/
interface IMigrationAsset {
    /**
     * EVENTS
     */
    event Immigration(
        address _from,
        uint256 _principal,
        uint256 _feePool,
        uint256 _shortPosition,
        address[] _references,
        uint256[] _params
    );

    event Emigration(
        address _to,
        uint256 _principal,
        uint256 _feePool,
        uint256 _shortPosition,
        address[] _references,
        uint256[] _params
    );

    /**
     * FUNCTIONS
     */
    /**
     * @notice immigrate positon settings to a new manager contract
     * @param _principal principal amount that is migtated to new manager
     * @param _feePool fee reserve that is migrated to new manager
     * @param _shortPosition constructed short position to new manager to reconstruct
     * @param _deposit deposit amount
     * @param _references address params to pass to the new manager
     * @param _params parameters to pass to the new contract
     */
    function immigrate(
        uint256 _principal,
        uint256 _feePool,
        uint256 _shortPosition,
        uint256 _deposit,
        address[] calldata _references,
        uint256[] calldata _params
    ) external;

    /**
     * @notice emmigrate positon settings to a new manager contract
     * @param _to next manager contract
     * @param _references address params to pass to the new manager
     * @param _params parameters to pass to the new contract
     */
    function emigrate(
        address _to,
        address[] calldata _references,
        uint256[] calldata _params
    ) external;

    /**
     * ERRORS
     */
    error OnlyFromManager();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IFungibleInitializer.sol";

/**
 * @title IFungiblePolicy
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Fungible Policy.
 **/
interface IFungiblePolicy is IFungibleInitializer {
    /**
     * FUNCTIONS
     */

    /**
     * @notice get insurance end time
     * @return endTime
     */
    function endTime() external returns (uint48);

    /**
     * @notice purchase a fungible position of depeg insurance with a fixed date end policy
     * mint ERC20 token in exchange for paying a premium
     * @param _amount amount to redeem
     */
    function insure(uint256 _amount) external;

    /**
     * @notice redeem usdc in exchange for usdt.
     * @param _amount amount to redeem
     * @param _redeemToken option to redeem usdc as collateral tokens
     */
    function redeem(uint256 _amount, address _redeemToken) external;

    /**
     * ERRORS
     */
    error RequestExceedBalance();
    error AmountZero();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IFungibleInitializer
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Fungible Initializer.
 **/
interface IFungibleInitializer {
    /**
     * @notice initialize functions for proxy contracts.
     * @param  _name contract's name
     * @param  _symbol contract's symbol (supported ERC20)
     * @param  _params initilizing params
     * @param  _references initilizing addresses
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        uint256[] calldata _params,
        address[] calldata _references
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

/**
 * @title IMarketVolatility
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Market Volatility.
 **/
interface IMarketVolatility {

    /**
     * @notice returns true if the coverage can be applied
     */
    function isDepeg() external view returns (bool);
    /**
     * @notice returns true if insurance positions can be terminated
     */
    function isTerminatable() external view returns (bool);
    /**
     * @notice returns true if volatility is beyond a certain level
     */
    function isVolatile() external view returns (bool);

    /**
     * @notice returns twap price of target currency set by parameters
     */
    function targetTwap() external view returns(uint256);
    /**
     * @notice returns twap price of base currency set by parameters
     */
    function baseTwap() external view returns(uint256);
    /**
     * @notice returns spot price of target currency set by parameters
     */
    function targetSpotPrice() external view returns(uint256);
    /**
     * @notice returns spot price of base currency set by parameters
     */
    function baseSpotPrice() external view returns(uint256);
    /**
     * @notice returns twap rate of target currency / base currency
     */
    function twapRate() external view returns(uint256);
    /**
     * @notice returns spot rate of target currency / base currency
     */
    function spotRate() external view returns(uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IOwnership
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Ownership.
 **/
interface IOwnership {
    function owner() external view returns (address);

    function futureOwner() external view returns (address);

    function commitTransferOwnership(address newOwner) external;

    function acceptTransferOwnership() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IRefundModel
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Premium Back Model.
 **/
interface IRefundModel {
    /**
     * @notice get fee rate for the specified conditions
     * @param _amount premium amount
     * @param _endTime insure's end time
     * @return fee insure back fee
     */
    function getRefundAmount(uint256 _amount, uint48 _endTime) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: BUSL-1.1
// Forked and minimized from https://github.com/platypus-finance/core/blob/master/contracts/interfaces/IPool.sol
pragma solidity ^0.8.0;

interface IPlatypusPool {
    function assetOf(address token) external view returns (address);

    function deposit(
        address token,
        uint256 amount,
        address to,
        uint256 deadline
    ) external returns (uint256 liquidity);

    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function withdrawFromOtherAsset(
        address initialToken,
        address wantedToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 actualToAmount, uint256 haircut);

    function quotePotentialSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external view returns (uint256 potentialOutcome, uint256 haircut);

    function quotePotentialWithdraw(address token, uint256 liquidity)
        external
        view
        returns (
            uint256 amount,
            uint256 fee,
            bool enoughCash
        );

    function quotePotentialWithdrawFromOtherAsset(
        address initialToken,
        address wantedToken,
        uint256 liquidity
    ) external view returns (uint256 amount, uint256 fee);

    function quoteMaxInitialAssetWithdrawable(address initialToken, address wantedToken)
        external
        view
        returns (uint256 maxInitialAssetAmount);

    function getTokenAddresses() external view returns (address[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPremiumModel
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Premium Model.
 **/
interface IPremiumModel {
    /**
     * FUNCTIONS
     */
    /**
     * @notice get fee rate for the specified conditions
     * @param _amount premium amount
     * @param _term insure's term
     * @param _targetRate target contract's rate
     * @return fee
     */
    function getFee(
        uint256 _amount,
        uint256 _term,
        uint256 _targetRate
    ) external view returns (uint256);

    /**
     * @notice get fee rate for the specified conditions
     * @param _amount premium amount
     * @param _term insure's term
     * @param _targetRate target contract's rate
     * @param _totalLiquidity total liquidity
     * @param _lockedAmount locked amount
     * @return fee
     */
    function getPremium(
        uint256 _amount,
        uint256 _term,
        uint256 _targetRate,
        uint256 _commissionRate,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IRewardPool
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Reward Pool.
 **/
interface IRewardPool {
    /**
     * EVENTS
     */
    event Market(address _market);
    event RewardAdded(uint256 _reward, address _account);
    event RewardWithdrawal(uint256 _reward, address _account);
    event OwnerWithdrawableTimestamp(uint256 _ownerWithdrawableTimestamp);

    /**
     * FUNCTIONS
     */
    /**
     * @notice add reward amount
     * @param _reward reward amount
     * @param _account rewarded address
     */
    function addReward(uint256 _reward, address _account) external;
    /**
     * @notice withdraw reward
     * @param _reward reward amount
     */
    function withdrawReward(uint256 _reward) external;
    /**
     * @notice withdraw all reward
     */
    function withdrawAllReward() external;
    /**
     * @notice withdraw token stored in this contract
     * @param _token token address
     * @param _to beneficiary's address
     */
    function withdrawRedundant(address _token, address _to) external;
    /**
     * @notice get reward amount
     * @param _account reward address
     */
    function rewards(address _account) external returns(uint256);
    /**
     * @notice set owner withdrawable timestamp (for withdrawRedundant)
     * @param _ownerWithdrawableTimestamp new withdrawable timestamp must be bigger than old
     */
    function setOwnerWithdrawableTimestamp(uint256 _ownerWithdrawableTimestamp) external;
    /**
     * @notice set market address
     * @param _market market address
     */
    function setMarket(address _market) external;

    /**
     * ERRORS
     */
    error YetWithdrawableTime();
    error OnlyMarket();
    error ZeroAddress();
    error AmountZero();
    error AmountExceeded();
    error OnlyUpper();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IFungibleInitializer.sol";

/**
 * @title IPolicyFactory
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Policy Factory.
 **/
interface IPolicyFactory {
    /**
     * EVENTS
     */
    event TemplateApproved(address _templateAddr, bool _approval);
    event FungibleCreated(
        address indexed _fungible,
        address indexed _template,
        string  _name,
        string _symbol,
        uint256[] _params,
        address[] _references
    );

    /**
     * FUNCTIONS
     */
    /**
     * @notice A function to approve or disapprove templates.
     * Only owner of the contract can operate.
     * @param _template template address, which must be registered
     * @param _approval true if a market is allowed to create based on the template
     */
    function approveTemplate(IFungibleInitializer _template, bool _approval) external;

    /**
     * @notice A function to create markets.
     * This function is market model agnostic.
     * @param _template template address, which must be registered
     * @param _name token name
     * @param _symbol token symbol
     * @param _params initialized parameters
     * @param _references initialized reference addresses
     * @return created market address
     */
    function createFungible(
        IFungibleInitializer _template,
        string memory _name,
        string memory _symbol,
        uint256[] calldata _params,
        address[] calldata _references
    ) external returns (address);

    /**
     * ERRORS
     */
    error ZeroAddress();
    error UnauthorizedTemplate();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "./ChainlinkRoundIdFetcher.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

// import "forge-std/console2.sol";

/**
 * @title ChainlinkTwap
 * @author @InsureDAO
 * @notice InsureDAO's Depeg insurance twap for chainlink oracle
 **/
library ChainlinkTwap {
    error RoundNotComplete();
    error FrequencyTooLow();

    /**
     * @notice returns price by timestamp
     * @param _feed address of price feed
     * @param _timestamp timestamp
     * @return _price spot price
     */
    function getHistoricalPrice(AggregatorV2V3Interface _feed, uint256 _timestamp) public view returns (uint256) {
        uint80 _roundId = ChainlinkRoundIdFetcher.getRoundId(_feed, _timestamp);
        (, int256 _price, , uint256 _updatedAt, ) = _feed.getRoundData(_roundId);
        if (_updatedAt == 0) revert RoundNotComplete();
        return uint256(_price);
    }

    /**
     * @notice returns latest price
     * @param _feed address of price feed
     * @return _price spot price
     */
    function getLatestPrice(AggregatorV2V3Interface _feed) public view returns (uint256) {
        int256 _latestPrice = _feed.latestAnswer();
        return uint256(_latestPrice);
    }

    /**
     * Returns TWAP price for a specified span.
     */
    /**
     * @notice returns twap price of target currency set by parameters
     * @param _feed address of price feed
     * @param _length twap length
     * @param _frequency number of twap price points within length
     * @return _twap twap price
     */
    function getTwap(
        AggregatorV2V3Interface _feed,
        uint256 _length,
        uint256 _frequency
    ) public view returns (uint256) {
        if (_length == 0) return getLatestPrice(_feed);
        if (_frequency < 2) revert FrequencyTooLow();

        // get start and end price
        (, int256 _latestPrice, , uint256 _latestUpdatedAt, ) = _feed.latestRoundData();
        uint256 _oldestTimestamp = _latestUpdatedAt - _length;
        uint256 _oldestPrice = getHistoricalPrice(_feed, _oldestTimestamp);

        // calculate cumlative price while getting price between start and end
        uint256 _cumlativePrice = uint256(_latestPrice) + _oldestPrice;
        uint256 _remainingFrequency = _frequency - 2; // deduct start and end
        uint256 _span = _length / (_frequency - 1);
        uint256 _targetTimestamp = _oldestTimestamp + _span;
        for (uint256 i; i < _remainingFrequency; ) {
            _cumlativePrice += getHistoricalPrice(_feed, _targetTimestamp);
            _targetTimestamp += _span;
            unchecked {
                i++;
            }
        }
        // calculate twap
        return _cumlativePrice / _frequency;
    }

    /**
     * @notice returns frequency
     * @param _length twap length
     * @param _span time span of next price points
     * @return _frequency frequency
     */
    function calcFrequency(uint256 _length, uint256 _span) external pure returns (uint256) {
        uint256 _frequency = _length / _span;
        return _frequency + 2;
    }
}

// SPDX-License-Identifier: MIT
// Forked as library from https://github.com/altalabsdev/bartrr/blob/main/contracts/RoundIdFetcher.sol
pragma solidity ^0.8.16;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

/// @title Chainlink RoundId Fetcher
/// @dev Used to get historical pricing data from Chainlink data feeds
library ChainlinkRoundIdFetcher {

    /// @notice Gets the phase that contains the target time
    /// @param _feed Address of the chainlink data feed

    /// @param _targetTime Target time to fetch the round id for
    /// @return The first roundId of the phase that contains the target time
    /// @return The timestamp of the phase that contains the target time
    /// @return The first roundId of the current phase
    function getPhaseForTimestamp(AggregatorV2V3Interface _feed, uint256 _targetTime) public view returns (uint80, uint256, uint80) {
        uint16 currentPhase = uint16(_feed.latestRound() >> 64);
        uint80 firstRoundOfCurrentPhase = (uint80(currentPhase) << 64) + 1;
        
        for (uint16 phase = currentPhase; phase >= 1; phase--) {
            uint80 firstRoundOfPhase = (uint80(phase) << 64) + 1;
            uint256 firstTimeOfPhase = _feed.getTimestamp(firstRoundOfPhase);

            if (_targetTime > firstTimeOfPhase) {
                return (firstRoundOfPhase, firstTimeOfPhase, firstRoundOfCurrentPhase);
            }
        }
        return (0,0, firstRoundOfCurrentPhase);
    }

    /// @notice Performs a binary search on the data feed to find the first round id after the target time
    /// @param _feed Address of the chainlink data feed
    /// @param _targetTime Target time to fetch the round id for
    /// @param _lhRound Lower bound roundId (typically the first roundId of the targeted phase)
    /// @param _lhTime Lower bound timestamp (typically the first timestamp of the targeted phase)
    /// @param _rhRound Upper bound roundId (typically the last roundId of the targeted phase)
    /// @return targetRound The first roundId after the target timestamp
    function _binarySearchForTimestamp(AggregatorV2V3Interface _feed, uint256 _targetTime, uint80 _lhRound, uint256 _lhTime, uint80 _rhRound) public view returns (uint80 targetRound) {

        if (_lhTime > _targetTime) return 0; // targetTime not in range

        uint80 guessRound = _rhRound;
        while (_rhRound - _lhRound > 1) {
            guessRound = uint80(int80(_lhRound) + int80(_rhRound - _lhRound)/2);
            uint256 guessTime = _feed.getTimestamp(uint256(guessRound));
            if (guessTime == 0 || guessTime > _targetTime) {
                _rhRound = guessRound;
            } else if (guessTime < _targetTime) {
                (_lhRound, _lhTime) = (guessRound, guessTime);
            }
        }
        return guessRound;
    }

    /// @notice Gets the round id for a given timestamp
    /// @param _feed Address of the chainlink data feed
    /// @param _timeStamp Target time to fetch the round id for
    /// @return roundId The roundId for the given timestamp
    function getRoundId(AggregatorV2V3Interface _feed, uint256 _timeStamp) public view returns (uint80 roundId) {

        (uint80 lhRound, uint256 lhTime, uint80 firstRoundOfCurrentPhase) = getPhaseForTimestamp(_feed, _timeStamp);

        uint80 rhRound;
        if (lhRound == 0) {
            // Date is too far in the past, no data available
            return 0;
        } else if (lhRound == firstRoundOfCurrentPhase) {
            (rhRound,,,,) = _feed.latestRoundData();
        } else {
            // No good way to get last round of phase from Chainlink feed, so our binary search function will have to use trial & error.
            // Use 2**16 == 65536 as a upper bound on the number of rounds to search in a single Chainlink phase.
            
            rhRound = lhRound + 2**16; 
        } 

        uint80 foundRoundId = _binarySearchForTimestamp(_feed, _timeStamp, lhRound, lhTime, rhRound);
        roundId = getRoundIdForTimestamp(_feed, _timeStamp, foundRoundId, lhRound);
        
        return roundId;
    }

    function getRoundIdForTimestamp(AggregatorV2V3Interface _feed, uint256 _timeStamp, uint80 _roundId, uint80 _firstRoundOfPhase) internal view returns (uint80) {
        uint256 roundTimeStamp = _feed.getTimestamp(_roundId);

        if (roundTimeStamp > _timeStamp && _roundId > _firstRoundOfPhase) {
            _roundId = getRoundIdForTimestamp(_feed, _timeStamp, _roundId - 1, _firstRoundOfPhase);
        } else if (roundTimeStamp > _timeStamp && _roundId == _firstRoundOfPhase) {
            _roundId = 0;
        }
            return _roundId;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
/**
 * @title InsureDAOERC20
 * @author @InsureDAO
 * @notice InsureDAO's Depeg insurance InsureDAO's ERC20 token
 **/
contract InsureDAOERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    bool tokenInitialized;
    string private _name = "InsureDAO LP Token";
    string private _symbol = "iLP";
    uint8 private _decimals = 18;

    function initializeToken(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) internal {
        /***
         *@notice initialize token. Only called internally.
         *
         */
        require(!tokenInitialized, "Token is already initialized");
        tokenInitialized = true;
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual override returns (string memory) {
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
    function decimals() external view virtual override returns (uint8) {
        return _decimals;
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        if (amount != 0) {
            uint256 currentAllowance = _allowances[sender][msg.sender];
            if (currentAllowance != type(uint256).max) {
                require(
                    currentAllowance >= amount,
                    "Transfer amount > allowance"
                );
                unchecked {
                    _approve(sender, msg.sender, currentAllowance - amount);
                }
            }

            _transfer(sender, recipient, amount);
        }

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
    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        if (addedValue != 0) {
            _approve(
                msg.sender,
                spender,
                _allowances[msg.sender][spender] + addedValue
            );
        }
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        if (subtractedValue != 0) {
            uint256 currentAllowance = _allowances[msg.sender][spender];
            require(
                currentAllowance >= subtractedValue,
                "Decreased allowance below zero"
            );

            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        if (amount != 0) {
            require(sender != address(0), "Transfer from the zero address");
            require(recipient != address(0), "Transfer to the zero address");

            _beforeTokenTransfer(sender, recipient, amount);

            uint256 senderBalance = _balances[sender];
            require(senderBalance >= amount, "Transfer amount exceeds balance");

            unchecked {
                _balances[sender] = senderBalance - amount;
            }

            _balances[recipient] += amount;

            emit Transfer(sender, recipient, amount);

            _afterTokenTransfer(sender, recipient, amount);
        }
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        if (amount != 0) {
            require(account != address(0), "Mint to the zero address");

            _beforeTokenTransfer(address(0), account, amount);

            _totalSupply += amount;
            _balances[account] += amount;
            emit Transfer(address(0), account, amount);

            _afterTokenTransfer(address(0), account, amount);
        }
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        if (amount != 0) {
            require(account != address(0), "Burn from the zero address");

            _beforeTokenTransfer(account, address(0), amount);

            uint256 accountBalance = _balances[account];
            require(accountBalance >= amount, "Burn amount exceeds balance");
            unchecked {
                _balances[account] = accountBalance - amount;
            }

            _totalSupply -= amount;

            emit Transfer(account, address(0), amount);

            _afterTokenTransfer(account, address(0), amount);
        }
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
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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