pragma solidity 0.8.12;

/**
 * @title Parameters
 * @author @InsureDAO
 * @notice This contract manages parameters of pools.
 * SPDX-License-Identifier: GPL-3.0
 */

import "./interfaces/IOwnership.sol";
import "./interfaces/IParameters.sol";
import "./interfaces/IPremiumModel.sol";

contract Parameters is IParameters {
    event VaultSet(address indexed token, address vault);
    event FeeRateSet(address indexed pool, uint256 rate);
    event RequestDurationSet(address indexed pool, uint256 duration);
    event WithdrawableDurationSet(address indexed pool, uint256 duration);
    event MaxListSet(address pool, uint256 max);
    event ConditionSet(bytes32 indexed ref, bytes32 condition);

    event PremiumModelSet(address indexed market, address model);
    event UnlockGracePeriodSet(address indexed market, uint256 period);
    event MaxInsureSpanSet(address indexed market, uint256 span);
    event MinInsureSpanSet(address indexed market, uint256 span);

    event UpperSlackSet(address indexed index, uint256 rate);
    event LowerSlackSet(address indexed index, uint256 rate);

    address public immutable ownership;

    //Global
    mapping(address => address) private _vaults; //address of the vault contract for each token
    mapping(address => uint256) private _fee; //fee rate in 1e6 (100% = 1e6)
    mapping(address => uint256) private _requestDuration; //funds lock up period after user requested to withdraw liquidity
    mapping(address => uint256) private _withdrawableTime; //a certain period a user can withdraw after lock up ends
    mapping(address => uint256) private _maxList; //maximum number of pools one index can allocate
    mapping(bytes32 => bytes32) private _conditions; //condition mapping for future use cases

    //Markets
    mapping(address => address) private _premiumModel; //address for each premium model contract
    mapping(address => uint256) private _grace; //grace before an insurance policy expires
    mapping(address => uint256) private _max; //maximum period to purchase an insurance policy
    mapping(address => uint256) private _min; //minimum period to purchase an insurance policy

    //Index
    mapping(address => uint256) private _lowerSlack; //lower slack range before adjustAlloc for index
    mapping(address => uint256) private _upperSlack; //upper slack range before adjustAlloc for index

    constructor(address _ownership) {
        require(_ownership != address(0), "ERROR: ZERO_ADDRESS");
        ownership = _ownership;
    }

    /**
     * @notice Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(IOwnership(ownership).owner() == msg.sender, "Caller is not allowed to operate");
        _;
    }

    /**
     * Global
     */

    /**
     * @notice Get the address of the owner
     * @return owner's address
     */
    function getOwner() external view returns (address) {
        return IOwnership(ownership).owner();
    }

    /**
     * @notice set the vault address corresponding to the token address
     * @param _token address of token
     * @param _vault vault for token
     */
    function setVault(address _token, address _vault) external onlyOwner {
        require(_vaults[_token] == address(0), "dev: already initialized");
        require(_vault != address(0), "dev: zero address");
        _vaults[_token] = _vault;
        emit VaultSet(_token, _vault);
    }

    function getVault(address _token) external view returns (address) {
        return _vaults[_token];
    }

    /**
     * @notice set the contract address of fee model
     * @param _pool address to set the fee model
     * @param _feeRate fee rate
     */
    function setFeeRate(address _pool, uint256 _feeRate) external onlyOwner {
        require(_feeRate <= 1000000, "ERROR: EXCEED_MAX_FEE_RATE");
        _fee[_pool] = _feeRate;
        emit FeeRateSet(_pool, _feeRate);
    }

    function getFeeRate(address _pool) external view returns (uint256) {
        uint256 _targetFee = _fee[_pool];
        if (_targetFee == 0) {
            return _fee[address(0)];
        } else {
            return _targetFee;
        }
    }

    /**
     * @notice set lock up periods in unix timestamp length
     * @param _pool address of pool to set the duration
     * @param _duration request time
     */
    function setRequestDuration(address _pool, uint256 _duration) external onlyOwner {
        _requestDuration[_pool] = _duration;
        emit RequestDurationSet(_pool, _duration);
    }

    function getRequestDuration(address _pool) external view returns (uint256) {
        uint256 _duration = _requestDuration[_pool];
        if (_duration == 0) {
            return _requestDuration[address(0)];
        } else {
            return _duration;
        }
    }

    /**
     * @notice set withdrawable period in unixtimestamp length
     * @param _pool address to set the parameter
     * @param _time parameter
     */
    function setWithdrawableDuration(address _pool, uint256 _time) external onlyOwner {
        _withdrawableTime[_pool] = _time;
        emit WithdrawableDurationSet(_pool, _time);
    }

    function getWithdrawableDuration(address _pool) external view returns (uint256) {
        uint256 _targetWithdrawable = _withdrawableTime[_pool];
        if (_targetWithdrawable == 0) {
            return _withdrawableTime[address(0)];
        } else {
            return _targetWithdrawable;
        }
    }

    /**
     * @notice set the max list number (e.g. 10)
     * @param _pool address to set the parameter
     * @param _maxLength max number of item
     */
    function setMaxList(address _pool, uint256 _maxLength) external onlyOwner {
        require(_maxLength > 1, "ERROR: MAX_LIST_UNDER_1");
        _maxList[_pool] = _maxLength;
        emit MaxListSet(_pool, _maxLength);
    }

    function getMaxList(address _pool) external view returns (uint256) {
        uint256 _poolMaxList = _maxList[_pool];
        if (_poolMaxList == 0) {
            return _maxList[address(0)];
        } else {
            return _poolMaxList;
        }
    }

    /**
     * @notice set the condition in bytes32 corresponding to bytes32
     * @param _reference bytes32 value to refer the parameter
     * @param _condition parameter
     */
    function setCondition(bytes32 _reference, bytes32 _condition) external onlyOwner {
        _conditions[_reference] = _condition;
        emit ConditionSet(_reference, _condition);
    }

    function getCondition(bytes32 _reference) external view returns (bytes32) {
        return _conditions[_reference];
    }

    /**
     * Market
     */

    /**
     * @notice set the contract address of premium model
     * @param _market address to set the premium model
     * @param _model premium model contract address
     */
    function setPremiumModel(address _market, address _model) external onlyOwner {
        require(_model != address(0), "dev: zero address");
        _premiumModel[_market] = _model;
        emit PremiumModelSet(_market, _model);
    }

    function getPremiumModel(address _market) external view returns (address) {
        address _model = _premiumModel[_market];
        if (_model == address(0)) {
            return _premiumModel[address(0)];
        } else {
            return _model;
        }
    }

    /**
     * @notice get premium amount for the specified conditions
     * @param _amount amount to get insured
     * @param _term term length
     * @param _totalLiquidity liquidity of the target contract's pool
     * @param _lockedAmount locked amount of the total liquidity
     * @param _market address of insurance market
     * @return premium amount
     */
    function getPremium(uint256 _amount, uint256 _term, uint256 _totalLiquidity, uint256 _lockedAmount, address _market)
        external
        view
        returns (uint256)
    {
        address _targetPremium = _premiumModel[_market];
        if (_targetPremium == address(0)) {
            return
                IPremiumModel(_premiumModel[address(0)]).getPremium(
                    _market,
                    _amount,
                    _term,
                    _totalLiquidity,
                    _lockedAmount
                );
        } else {
            return IPremiumModel(_targetPremium).getPremium(_market, _amount, _term, _totalLiquidity, _lockedAmount);
        }
    }

    /**
     * @notice set grace period length in unix timestamp length (1 day = 86400)
     * @param _market address to set the parameter
     * @param _period parameter
     */
    function setUnlockGracePeriod(address _market, uint256 _period) external onlyOwner {
        _grace[_market] = _period;
        emit UnlockGracePeriodSet(_market, _period);
    }

    function getUnlockGracePeriod(address _market) external view returns (uint256) {
        uint256 _targetGrace = _grace[_market];
        if (_targetGrace == 0) {
            return _grace[address(0)];
        } else {
            return _targetGrace;
        }
    }

    /**
     * @notice set max length in unix timestamp length (1 day = 86400)
     * @param _market address to set the parameter
     * @param _span parameter
     */
    function setMaxInsureSpan(address _market, uint256 _span) external onlyOwner {
        require(_min[_market] <= _span, "smaller than MinDate");
        _max[_market] = _span;
        emit MaxInsureSpanSet(_market, _span);
    }

    function getMaxInsureSpan(address _market) external view returns (uint256) {
        uint256 _maxDate = _max[_market];
        if (_maxDate == 0) {
            return _max[address(0)];
        } else {
            return _maxDate;
        }
    }

    /**
     * @notice set min length in unix timestamp length (1 day = 86400)
     * @param _market address to set the parameter
     * @param _span minimum period in unix timestamp
     */
    function setMinInsureSpan(address _market, uint256 _span) external onlyOwner {
        require(_span <= _max[_market], "greater than MaxDate");
        _min[_market] = _span;
        emit MinInsureSpanSet(_market, _span);
    }

    function getMinInsureSpan(address _market) external view returns (uint256) {
        uint256 _minDate = _min[_market];
        if (_minDate == 0) {
            return _min[address(0)];
        } else {
            return _minDate;
        }
    }

    /**
     * Index
     */

    /**
     * @notice set slack rate of leverage before adjustAlloc
     * @param _index address to set the parameter
     * @param _rate parameter (slack rate 100% = 1e6
     */
    function setUpperSlack(address _index, uint256 _rate) external onlyOwner {
        _upperSlack[_index] = _rate;
        emit UpperSlackSet(_index, _rate);
    }

    function getUpperSlack(address _index) external view returns (uint256) {
        uint256 _targetUpperSlack = _upperSlack[_index];
        if (_targetUpperSlack == 0) {
            return _upperSlack[address(0)];
        } else {
            return _targetUpperSlack;
        }
    }

    /**
     * @notice set slack rate of leverage before adjustAlloc
     * @param _index address to set the parameter
     * @param _rate parameter (slack rate 100% = 1000
     */
    function setLowerSlack(address _index, uint256 _rate) external onlyOwner {
        _lowerSlack[_index] = _rate;
        emit LowerSlackSet(_index, _rate);
    }

    function getLowerSlack(address _index) external view returns (uint256) {
        uint256 _targetLowerSlack = _lowerSlack[_index];
        if (_targetLowerSlack == 0) {
            return _lowerSlack[address(0)];
        } else {
            return _targetLowerSlack;
        }
    }
}

pragma solidity 0.8.12;

//SPDX-License-Identifier: MIT

interface IOwnership {
    function owner() external view returns (address);

    function futureOwner() external view returns (address);

    function commitTransferOwnership(address newOwner) external;

    function acceptTransferOwnership() external;
}

pragma solidity 0.8.12;

interface IParameters {
    function setVault(address _token, address _vault) external;

    function setRequestDuration(address _address, uint256 _target) external;

    function setUnlockGracePeriod(address _address, uint256 _target) external;

    function setMaxInsureSpan(address _address, uint256 _target) external;

    function setMinInsureSpan(address _address, uint256 _target) external;

    function setUpperSlack(address _address, uint256 _target) external;

    function setLowerSlack(address _address, uint256 _target) external;

    function setWithdrawableDuration(address _address, uint256 _target) external;

    function setPremiumModel(address _address, address _target) external;

    function setFeeRate(address _address, uint256 _target) external;

    function setMaxList(address _address, uint256 _target) external;

    function setCondition(bytes32 _reference, bytes32 _target) external;

    function getOwner() external view returns (address);

    function getVault(address _token) external view returns (address);

    function getPremium(
        uint256 _amount,
        uint256 _term,
        uint256 _totalLiquidity,
        uint256 _lockedAmount,
        address _target
    ) external view returns (uint256);

    function getFeeRate(address _target) external view returns (uint256);

    function getUpperSlack(address _target) external view returns (uint256);

    function getLowerSlack(address _target) external view returns (uint256);

    function getRequestDuration(address _target) external view returns (uint256);

    function getWithdrawableDuration(address _target) external view returns (uint256);

    function getUnlockGracePeriod(address _target) external view returns (uint256);

    function getMaxInsureSpan(address _target) external view returns (uint256);

    function getMinInsureSpan(address _target) external view returns (uint256);

    function getMaxList(address _target) external view returns (uint256);

    function getCondition(bytes32 _reference) external view returns (bytes32);

    function getPremiumModel(address _market) external view returns (address);
}

pragma solidity 0.8.12;

interface IPremiumModel {
    function getCurrentPremiumRate(
        address _market,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view returns (uint256);

    function getPremiumRate(
        address _market,
        uint256 _amount,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view returns (uint256);

    function getPremium(
        address _market,
        uint256 _amount,
        uint256 _term,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view returns (uint256);
}