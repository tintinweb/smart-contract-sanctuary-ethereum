// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libraries/PrecogV5Library.sol";
import "../withdrawal-register/interfaces/IWithdrawalRegister.sol";
import "./interfaces/IPrecogV5.sol";
import "./interfaces/IPrecogCore.sol";
import "./interfaces/IPrecogInternal.sol";

contract PrecogCore is IPrecogCore {
    using SafeERC20 for IERC20;

    modifier onlyAdmin() {
        require(msg.sender == precogStorage.getAdmin(), "PrecogCore: Caller is not admin");
        _;
    }

    modifier onlyOperator() {
        require(precogStorage.isOperator(msg.sender), "PrecogCore: Caller is not an operator");
        _;
    }

    IPrecogStorage public precogStorage;
    IPrecogInternal public precogInternal;

    FeeConfiguration private feeConfiguration;
    CycleConfiguration private cycleConfiguration;
    uint8 public constant override feeDecimalBase = 18;
    mapping(address => CyclesChangedInfo) cyclesChangedInfo;
    mapping(address => uint) public override minFunding;
    mapping(address => uint) public override maxFunding;
    mapping(address => uint) public override maxFundingPool;
    mapping(address => uint) public override minDefunding;

    constructor(IPrecogStorage _precogStorage, IPrecogInternal _precogInternal) {
        precogStorage = _precogStorage;
        precogInternal = _precogInternal;
        feeConfiguration = FeeConfiguration({
            depositFee: 1000000000000000,
            withdrawalFee: 1000000000000000,
            tradingFee: 1000000000000000,
            lendingFee: 1000000000000000
        });
        cycleConfiguration = CycleConfiguration({
            firstDefundingCycle: 259200,
            fundingCycle: 86400,
            defundingCycle: 86400,
            tradingCycle: 604800
        });
    }

    function getFeeConfiguration() external view override returns (FeeConfiguration memory) {
        return feeConfiguration;
    }

    function getCycleConfiguration() external view override returns (CycleConfiguration memory) {
        return cycleConfiguration;
    }

    function getCyclesChangedInfo(address _token) external view override returns (CyclesChangedInfo memory) {
        return cyclesChangedInfo[_token];
    }

    function setCycleConfiguration(CycleConfiguration memory newCycleConfiguration) external onlyAdmin {
        uint32 firstDefundingCycle = newCycleConfiguration.firstDefundingCycle;
        uint32 fundingCycle = newCycleConfiguration.fundingCycle;
        uint32 defundingCycle = newCycleConfiguration.defundingCycle;
        uint32 tradingCycle = newCycleConfiguration.tradingCycle;

        require(firstDefundingCycle > 0 && defundingCycle > 0 && fundingCycle > 0);
        require(fundingCycle <= tradingCycle);
        require(tradingCycle >= firstDefundingCycle && tradingCycle >= defundingCycle);
        require((firstDefundingCycle / defundingCycle) * defundingCycle == firstDefundingCycle);

        _updateAdjustments(newCycleConfiguration);

        cycleConfiguration = newCycleConfiguration;
        emit SetCycleConfiguration({
            admin: precogStorage.getAdmin(),
            firstDefundingDuration: firstDefundingCycle,
            fundingDuration: fundingCycle,
            defundingDuration: defundingCycle,
            tradingDuration: tradingCycle
        });
    }

    function setCyclesChangedInfo(address _token, CyclesChangedInfo memory _cyclesChangedInfo)
        external
        override
        onlyOperator
    {
        cyclesChangedInfo[_token] = _cyclesChangedInfo;
    }

    function _updateAdjustments(CycleConfiguration memory _newCycleConfiguration) internal {
        TokenPair[] memory _pairs = IPrecogStorage(precogStorage).getExistingTokensPair();
        for (uint i = 0; i < _pairs.length; i++) {
            precogInternal.updateCurrentTradingCycle(_pairs[i].token, false, 2**255);
            CyclesChangedInfo memory _cycleChangedInfo = cyclesChangedInfo[_pairs[i].token];

            {
                Cycle memory _currentTradingcycle = precogInternal.getCurrentTradingCycle(_pairs[i].token);
                uint _tradingDuration = _currentTradingcycle.endTime - _currentTradingcycle.startTime;
                require(
                    _newCycleConfiguration.firstDefundingCycle <= _tradingDuration &&
                        _newCycleConfiguration.fundingCycle <= _tradingDuration &&
                        _newCycleConfiguration.defundingCycle <= _tradingDuration,
                    "PrecogCore: Funding and defunding duration must be less than current trading duration"
                );
            }

            uint48 _nextFundingTime = PrecogV5Library._nextFundingTime(
                _cycleChangedInfo.fundingApplyTime,
                _cycleChangedInfo.fundingDuration
            );
            uint48 _nextTradingTime = _nextFundingTime;

            uint48 _nextDefundingTime = PrecogV5Library._nextDefundingTime(
                _cycleChangedInfo.defundingApplyTime,
                _cycleChangedInfo.defundingDuration,
                _cycleChangedInfo.firstDefundingDuration
            );

            if (_nextFundingTime < _nextDefundingTime) {
                _nextTradingTime = _nextDefundingTime;
            }

            Cycle memory _futureTradingcycle = precogInternal.getTradingCycle(_pairs[i].token, _nextTradingTime);

            if (_cycleChangedInfo.tradingApplyTime < _futureTradingcycle.endTime) {
                _cycleChangedInfo.tradingApplyTime = _futureTradingcycle.endTime;
            }

            _nextDefundingTime = PrecogV5Library._nextDefundingTime(
                _cycleChangedInfo.defundingApplyTime,
                _cycleChangedInfo.defundingDuration,
                0
            );
            cyclesChangedInfo[_pairs[i].token] = CyclesChangedInfo({
                tradingApplyTime: _cycleChangedInfo.tradingApplyTime,
                fundingApplyTime: _nextFundingTime,
                defundingApplyTime: _nextDefundingTime,
                fundingDuration: _cycleChangedInfo.fundingDuration,
                firstDefundingDuration: _cycleChangedInfo.firstDefundingDuration,
                defundingDuration: _cycleChangedInfo.defundingDuration
            });
        }
    }

    function setFeeConfiguration(FeeConfiguration memory _feeConfiguration) external onlyAdmin {
        feeConfiguration = _feeConfiguration;
        emit SetFeeConfiguration({
            admin: precogStorage.getAdmin(),
            depositFee: _feeConfiguration.depositFee,
            withdrawalFee: _feeConfiguration.withdrawalFee,
            tradingFee: _feeConfiguration.tradingFee,
            lendingFee: _feeConfiguration.lendingFee
        });
    }

    function collectFee(address token) external onlyAdmin {
        address admin = precogStorage.getAdmin();
        uint balanceOf = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(admin, balanceOf);
        emit CollectFee({admin: admin, token: token, amount: balanceOf});
    }

    function setMinFunding(address token, uint amount) external onlyAdmin {
        minFunding[token] = amount;
    }

    function setMaxFunding(address token, uint limitation) external onlyAdmin {
        maxFunding[token] = limitation;
    }

    function setMaxFundingPool(address token, uint limitation) external onlyAdmin {
        maxFundingPool[token] = limitation;
    }

    function setMinDefunding(address token, uint amount) external onlyAdmin {
        require(amount <= minFunding[token], "PrecogCore: MIN_DEFUNDING_MUST_LESS_THAN_MIN_FUNDING");
        minDefunding[token] = amount;
    }

    function getCurrentFundingCycle(address token)
        external
        view
        override
        returns (uint lastFundingStartTime, uint nextFundingStartTime)
    {
        CyclesChangedInfo memory _cycleChangedInfo = cyclesChangedInfo[token];
        uint48 fundingApplyTime = _cycleChangedInfo.fundingApplyTime;
        uint48 fundingDuration = fundingApplyTime >= block.timestamp
            ? cycleConfiguration.fundingCycle
            : _cycleChangedInfo.fundingDuration;
        nextFundingStartTime = PrecogV5Library._nextFundingTime(fundingApplyTime, fundingDuration);
        lastFundingStartTime = nextFundingStartTime - fundingDuration;
    }

    function getCurrentDefundingCycle(address token)
        external
        view
        override
        returns (uint lastDefundingStartTime, uint nextDefundingStartTime)
    {
        CyclesChangedInfo memory cycleChangedInfo = cyclesChangedInfo[token];
        uint48 defundingApplyTime = cycleChangedInfo.defundingApplyTime;
        uint48 defundingDuration = cycleChangedInfo.defundingDuration;
        uint48 firstDefundingDuration = cycleChangedInfo.firstDefundingDuration;
        if (defundingApplyTime >= block.timestamp) {
            defundingDuration = cycleConfiguration.defundingCycle;
            firstDefundingDuration = cycleConfiguration.firstDefundingCycle;
        }
        address withdrawalRegister = IPrecogStorage(precogStorage).getWithdrawalRegister();
        if (IWithdrawalRegister(withdrawalRegister).isFirstWithdraw(token, msg.sender)) {
            if (IWithdrawalRegister(withdrawalRegister).isInDeadline(token, msg.sender)) {
                nextDefundingStartTime = IWithdrawalRegister(withdrawalRegister)
                    .getRegister(token, msg.sender)
                    .deadline;
            } else {
                nextDefundingStartTime = PrecogV5Library._nextDefundingTime(
                    defundingApplyTime,
                    defundingDuration,
                    firstDefundingDuration
                );
            }
        } else {
            nextDefundingStartTime = PrecogV5Library._nextDefundingTime(defundingApplyTime, defundingDuration, 0);
        }
        lastDefundingStartTime =
            PrecogV5Library._nextDefundingTime(defundingApplyTime, defundingDuration, 0) -
            defundingDuration;
    }

    function updateFundingDuration(address token) external override {
        if (PrecogV5Library._isAppliedChangedCycle(cyclesChangedInfo[token].fundingApplyTime)) {
            cyclesChangedInfo[token].fundingDuration = cycleConfiguration.fundingCycle;
        }
    }

    /**
     * @notice Use to update the defunding cycle after the applied time when admin change cycle configuration
     * @param token is token address
     */
    function updateDefundingDuration(address token) external override {
        if (PrecogV5Library._isAppliedChangedCycle(cyclesChangedInfo[token].defundingApplyTime)) {
            cyclesChangedInfo[token].firstDefundingDuration = cycleConfiguration.firstDefundingCycle;
            cyclesChangedInfo[token].defundingDuration = cycleConfiguration.defundingCycle;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IWithdrawalRegister {
    struct Register {
        uint256 amount;
        uint256 deadline;
    }


    event RegisterWithdrawal(
        address token,
        address account, 
        uint256 amount,
        uint256 deadline
    );

    /**
     * @dev Emits when user claim the token amount
     * @param token is token address
     * @param account is account address
     * @param amount is token amount
     */
    event ClaimWithdrawal(
        address token,
        address account,
        uint256 amount
    );

    /**
     * @dev Returns the precog address
     */
    function precog() external view returns (address);

    /**
     * @dev Returns the precog core address
     */
    function precogCore() external view returns (address);

    /**
     * @notice Returns the register of user that includes amount and deadline
     * @param token is token address
     * @param account is user address
     * @return register is the set of amount and deadline for token address and account address
     */
    function getRegister(address token, address account) external view returns (Register memory register);

    /**
     * @notice Check if user has a first request withdrawal
     * @param token is token address
     * @param account is user address
     * @return _isFirstWithdrawal is the value if user has a first request withdrawal or not
     */
    function isFirstWithdraw(address token, address account) external view returns (bool _isFirstWithdrawal);

    /**
     * @notice Check if register of user is in deadline
     * @param token is token address
     * @param account is user address
     * @return _isInDeadline - the value of register if it is in deadline or not
     */
    function isInDeadline(address token, address account) external view returns (bool _isInDeadline);

    /**
     * @notice Register the token amount and deadline for user
     * @dev Requirements:
     * - Must be called by only precog contract
     * - Deadline of register must be less than or equal to param `deadline`
     * - If deadline of register is completed, user must claim withdrawal before calling this function
     * @param token is token address that user wants to request withdrawal
     * @param account is user address
     * @param amount is token amount that user wants to request withdrawal  
     * @param deadline is deadline that precog calculates and is used for locking token amount of user 
     */
    function registerWithdrawal(address token, address account, uint256 amount, uint256 deadline) external;

    /**
     * @notice Withdraw token amount that user registered and out of deadline
     * @dev Requirements:
     * - Must be called only by precog contract
     * - Deadline of register must be less than or equal to now
     * - Amount of register must be greater than or equal to param `amount`
     * - This contract has enough token amount for user
     * @param token is token address that user want to claim the requested withdrawal
     * @param account is user address
     * @param to is account address that user want to transfer when claiming requested withdrawal
     * @param amount is amount token that user want to claim
     * @param fee is fee token that precog core charges when user claim token
     */
    function claimWithdrawal(address token, address account, address to, uint256 amount, uint256 fee) external;

    /**
     * @notice Modify register info
     * @dev Requirements:
     * Only Precog address can call this function
     * @param token is token address
     * @param account is user address
     * @param newRegister is new register data for user with the `token`  
     */
    function modifyRegister(address token, address account, Register memory newRegister) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "../interfaces/IPrecogStorage.sol";


library PrecogV5Library {
    function _isAppliedChangedCycle(uint _nextCycleApplyChangingTimestamp) internal view returns (bool) {
        return block.timestamp > _nextCycleApplyChangingTimestamp;
    }

    function _chooseLastAvailableTradingId(
        IContractStructure.Investment[] memory _investments,
        uint _investmentId,
        uint _value
    ) internal pure returns (IContractStructure.Investment memory _nextInvestment, uint _lastAvailableProfitId) {
        unchecked {
            _nextInvestment = IContractStructure.Investment({
                amount: 0,
                unit: 0,
                timestamp: 0,
                idChanged: 0,
                isWhitelist: false
            });
            _lastAvailableProfitId = _value;
            if (_investmentId < _investments.length - 1) {
                _nextInvestment = _investments[_investmentId + 1];
                if (_nextInvestment.idChanged <= _value) {
                    _lastAvailableProfitId = _nextInvestment.idChanged;
                }
            }
        }
    }

    function _calculateProfitAtCycle(
        IContractStructure.Cycle memory _profitCycle,
        IContractStructure.Investment memory _investment,
        uint _totalInvestmentUnit,
        uint _lastProfit,
        uint _lastProfitIdOf
    ) internal pure returns (uint _profitAtCycle) {
        unchecked {
            if (_totalInvestmentUnit > 0) {
                if (_lastProfitIdOf == _investment.idChanged) {
                    _profitAtCycle = (_lastProfit * _investment.unit) / _totalInvestmentUnit;
                } else {
                    IContractStructure.Cycle memory lastCycle = _profitCycle;
                    _profitAtCycle =
                        (_lastProfit * _investment.amount * (lastCycle.endTime - lastCycle.startTime)) /
                        _totalInvestmentUnit;
                }
            }
        }
    }

    function _calculateTradingCycleByTimestamp(
        IContractStructure.Cycle memory _lastTradingCycle,
        uint48 _tradingCycleDuration,
        uint _tradingApplyTime,
        uint timestamp
    ) internal pure returns (IContractStructure.Cycle memory currentCycle) {
        unchecked {
            while (uint48(timestamp) >= _lastTradingCycle.endTime) {
                uint48 _newCycleStartTime = _lastTradingCycle.endTime;
                uint48 _duration;
                
                if (_lastTradingCycle.endTime < _tradingApplyTime) {
                    _duration = _lastTradingCycle.endTime - _lastTradingCycle.startTime;
                } else {
                    _duration = _tradingCycleDuration;
                }
                uint48 _newCycleEndTime = _newCycleStartTime + _duration;
                _lastTradingCycle = (
                    IContractStructure.Cycle(_lastTradingCycle.id + 1, _newCycleStartTime, _newCycleEndTime)
                );
            }
            currentCycle = _lastTradingCycle;
        }
    }

    function _nextFundingTime(uint48 _newFirstFundingStartTime, uint48 _fundingDuration)
        internal
        view
        returns (uint48 _nextFundingTimestamp)
    {
        unchecked {
            if (block.timestamp < _newFirstFundingStartTime) {
                _nextFundingTimestamp = _newFirstFundingStartTime;
            } else {
                _nextFundingTimestamp =
                    ((uint48(block.timestamp) - _newFirstFundingStartTime) / _fundingDuration + 1) *
                    _fundingDuration +
                    _newFirstFundingStartTime;
            }
        }
    }

    function _nextDefundingTime(
        uint48 _newFirstDefundingStartTime,
        uint48 _defundingDuration,
        uint48 _firstDefundingDuration
    ) internal view returns (uint48 _nextDefundingTimestamp) {
        unchecked {
            if (_firstDefundingDuration > 0) {
                if (block.timestamp < _newFirstDefundingStartTime) {
                    return _newFirstDefundingStartTime + _firstDefundingDuration - _defundingDuration;
                } else {
                    return
                        ((uint48(block.timestamp) - _newFirstDefundingStartTime) / _defundingDuration) *
                        _defundingDuration +
                        _newFirstDefundingStartTime +
                        _firstDefundingDuration;
                }
            } else {
                if (block.timestamp < _newFirstDefundingStartTime) {
                    return _newFirstDefundingStartTime;
                } else {
                    return
                        ((uint48(block.timestamp) - _newFirstDefundingStartTime) / _defundingDuration + 1) *
                        _defundingDuration +
                        _newFirstDefundingStartTime;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


import "./IPrecogInternal.sol";


interface IPrecogV5 {
    // Events
    event Deposit(
        address indexed token, 
        address indexed account, 
        uint amount, 
        uint fee
    );
    event RequestWithdrawal(
        address indexed token, 
        address indexed account, 
        uint amount
    );
    event Withdraw(
        address indexed token,
        address indexed account,
        address indexed to,
        uint amount,
        uint fee
    );
    
    function precogStorage() external view returns (IPrecogStorage);

    function precogInternal() external view returns (IPrecogInternal);

    /**
     * @notice Use to deposit the token amount to contract
     * @dev Requirements:
     * - `token` must be added to pool
     * - user must approve token for this contract
     * - `amount` must be greater than or equal the min funding amount
     * @param token is token address
     * @param amount is token amount that user will deposit to contract
     */
    function deposit(address token, uint amount) external;

    /**
     * 
     */
    function requestWithdrawal(address liquidityToken, uint amount) external;

    function withdraw(address to, address token, uint amount, bool isEmergency) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IContractStructure.sol";

interface IPrecogStorage is IContractStructure {
    event TransferAdmin(address oldAdmin, address newAdmin);
    event AddOperator(address operator);
    event RemoveOperator(address operator);
    event SetPCOG(address pcog);
    event SetGMT(address gmt);

    function getAdmin() external view returns (address);

    function transferAdmin(address newAdmin) external;

    function getMiddlewareService() external view returns (address);

    function setMiddlewareService(address newMiddlewareService) external;

    function getPCOG() external view returns (address);

    function setPCOG(address newPCOG) external;

    function getGMT() external view returns (address);

    function setGMT(address newGMT) external;

    function isOperator(address operator) external view returns (bool);

    function getPrecog() external view returns (address);

    function setPrecog(address newPrecog) external;

    function getPrecogInternal() external view returns (address);

    function setPrecogInternal(address newPrecogInternal) external;

    function getPrecogCore() external view returns (address);

    function setPrecogCore(address newPrecogCore) external;

    function getPrecogFactory() external view returns (address);

    function setPrecogFactory(address newPrecogFactory) external;

    function getPrecogVault() external view returns (address);

    function setPrecogVault(address newPrecogVault) external;

    function getPrecogProfit() external view returns (address);

    function setPrecogProfit(address newPrecogProfit) external;

    function getMiddlewareExchange() external view returns (address);

    function setMiddlewareExchange(address newMiddlewareExchange) external;

    function getWithdrawalRegister() external view returns (address);

    function setWithdrawalRegister(address newWithdrawalRegister) external;

    function getExistingTokens() external view returns (address[] memory tokens);

    function findExistingTokenIndex(address token) external view returns (uint index);

    function pushExistingToken(address token) external;

    function swapExistingTokensByIndex(uint indexTokenA, uint indexTokenB) external;

    function popExistingToken() external;

    function getExistingTokensPair() external view returns (TokenPair[] memory pairs);

    function getExistingTokenPairByIndex(uint index)
        external
        view
        returns (TokenPair memory pair);

    function getCurrentProfitId(address token) external view returns (uint);

    function updateCurrentProfitId(address token, uint newValue) external;

    function checkIsExistingToken(address token) external view returns (bool);

    function updateIsExistingToken(address token, bool newValue) external;

    function getTokenConvert(address token) external view returns (address);

    function updateTokenConvert(address token, address newValue) external;

    function getLiquidity(address token) external view returns (uint);

    function updateLiquidity(address token, uint newValue) external;

    function getLiquidityWhitelist(address token) external view returns (uint);

    function updateLiquidityWhitelist(address token, uint newValue) external;

    function checkIsNotFirstInvestmentCycle(address token) external view returns (bool);

    function updateIsNotFirstInvestmentCycle(address token, bool newValue) external;

    function checkIsRemoved(address token) external view returns (bool);

    function updateIsRemoved(address token, bool newValue) external;

    function getWhitelist(address token) external view returns (address[] memory);

    function pushWhitelist(address token, address account) external;

    function removeFromWhitelist(address token, address account) external;

    function checkIsInWhitelist(address token, address account)
        external
        view
        returns (bool);

    function updateIsInWhitelist(
        address token,
        address account,
        bool newValue
    ) external;

    function getTradingCycles(address token) external view returns (Cycle[] memory);

    function getTradingCycleByIndex(address token, uint index)
        external
        view
        returns (Cycle memory);

    function getInfoTradingCycleById(address token, uint id)
        external
        view
        returns (
            uint48 startTime,
            uint48 endTime,
            uint unit,
            uint unitForWhitelist,
            uint profitAmount
        );

    function getLastTradingCycle(address token) external view returns (Cycle memory);

    function pushTradingCycle(address token, Cycle memory tradingCycle) external;

    function getProfits(address token) external view returns (uint[] memory);

    function updateProfitByIndex(
        address token,
        uint index,
        uint newValue
    ) external;

    function pushProfit(address token, uint newValue) external;

    function getProfitsForWhitelist(address token) external view returns (uint[] memory);

    function updateProfitForWhitelistByIndex(address token, uint index, uint newValue) external;

    function pushProfitForWhitelist(address token, uint newValue) external;

    function checkIsUpdateUnitTradingCycle(address token, uint index)
        external
        view
        returns (bool);

    function updateIsUpdateUnitTradingCycle(
        address token,
        uint index,
        bool newValue
    ) external;

    function getTotalUnitsTradingCycle(address token, uint index)
        external
        view
        returns (uint);

    function updateTotalUnitsTradingCycle(
        address token,
        uint index,
        uint newValue
    ) external;

    function getTotalUnitsForWhitelistTradingCycle(address token, uint index) external view returns (uint);

    function updateTotalUnitsForWhitelistTradingCycle(address token, uint index, uint newValue) external;

    function getInvestmentsOf(address token, address account)
        external
        view
        returns (Investment[] memory);

    function getInvestmentOfByIndex(
        address token,
        address account,
        uint index
    ) external view returns (Investment memory);

    /**
     * @dev Returns the last investment of user
     * @param token is token address
     * @param account is account address
     * @return lastInvestmentOf is the last Investment of user
     */
    function getLastInvestmentOf(address token, address account)
        external
        view
        returns (Investment memory);

    function updateInvestmentOfByIndex(
        address token,
        address account,
        uint index,
        Investment memory newValue
    ) external;

    function pushInvestmentOf(
        address token,
        address account,
        Investment memory newInvestmentOf
    ) external;

    function popInvestmentOf(address token, address account) external;

    function getAccountProfitInfo(address token, address account)
        external
        view
        returns (AccountProfitInfo memory);

    function updateAccountProfitInfo(
        address token,
        address account,
        AccountProfitInfo memory newValue
    ) external;

    function getAccountTradingInfo(address token, address account)
        external
        view
        returns (AccountTradingInfo memory);

    function updateAccountTradingInfo(
        address token,
        address account,
        AccountTradingInfo memory newValue
    ) external;

    function getUnitInTradingCycle(
        address token,
        address account,
        uint id
    ) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IPrecogStorage.sol";

interface IPrecogInternal is IContractStructure {
    event UpdateTradingCycle(address indexed token, uint indexed cycleId, uint liquidity, uint duration);

    function getTradingCycleByTimestamp(address token, uint timestamp)
        external
        view
        returns (Cycle memory currentTradingCycleByTimestamp);

    function calculateProfit(address _token, address _account)
        external
        view
        returns (AccountProfitInfo memory accountProfitInfo);

    function updateProfit(address _token, address _account) external;

    function increaseInvestment(
        address _token,
        address _account,
        uint _amount, 
        uint48 _timestamp
    ) external;

    function isBeforeFundingTime(address _token, address _account)
        external
        view
        returns (bool _isBeforeInvestmentCycle);

    function decreaseInvestment(
        address _token,
        address _account,
        uint _amount,
        uint48 _timestamp
    ) external returns (uint remainingAmount);

    function updateDepositInfo(
        address _token,
        address _account,
        uint _amount
    ) external;

    function availableDepositedAmount(address token, address account)
        external
        view
        returns (
            uint amount
        );

    function updateCurrentTradingCycle(
        address token,
        bool isLimitedTradingCycles,
        uint limitTradingCycles
    ) external;

    function getTradingCycle(address token, uint48 tradingTime) external view returns (Cycle memory);
    
    function getCurrentTradingCycle(address token) external view returns (Cycle memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IContractStructure.sol";

interface IPrecogCore is IContractStructure {
    

    /**
     * @dev Emits when admin set cycles configurations of trading
     * @param admin is address admin that sets cycles configurations
     * @param firstDefundingDuration is a duration is used when user requests withdrawal for the first time
     * @param fundingDuration is a duration is used when user deposits or transfers IPCOG
     * @param defundingDuration is a duration is used when user requests withdrawal or transfers IPCOG
     * @param tradingDuration is a duration is used to calculate profit for users when middleware sends profit
     */
    event SetCycleConfiguration(
        address indexed admin,
        uint32 firstDefundingDuration,
        uint32 fundingDuration,
        uint32 defundingDuration,
        uint32 tradingDuration
    );

    /**
     * @dev Emits when admin set fees configurations of trading
     * @param admin is address admin that sets fees configurations
     * @param depositFee is deposit fees when user deposit to trading pool
     * @param withdrawalFee is withdrawal fees when user withdraw tokens from trading pool
     * @param tradingFee is trading fees charge from users when middleware service sends profit to trading pool
     * @param lendingFee is lending fees when user lend tokens
     */
    event SetFeeConfiguration(
        address indexed admin,
        uint64 depositFee,
        uint64 withdrawalFee,
        uint64 tradingFee,
        uint64 lendingFee
    );
    event CollectFee(address indexed admin, address indexed token, uint amount);

    function feeDecimalBase() external view returns (uint8);

    function getFeeConfiguration() external view returns (FeeConfiguration memory);

    function getCycleConfiguration() external view returns (CycleConfiguration memory);

    /**
     * @notice Returns the data of CyclesChangedInfo of token address
     * @dev See {Struct - CyclesChangedInfo} to get explaination of CyclesChangedInfo
     * @param token is token address
     * @return CyclesChangedInfo of token
     */
    function getCyclesChangedInfo(address token) external view returns (CyclesChangedInfo memory);

    /**
     * @dev Be used by precog to change CyclesChangedInfo of token address
     * @param token is token address
     * @param config is new CyclesChangedInfo
     */
    function setCyclesChangedInfo(address token, CyclesChangedInfo memory config) external;

    /**
     * @notice Returns the last funding start time and next funding start time when middleware will take investment
     * @param token is token address
     * @return lastFundingStartTime is the last time middleware took investment
     * @return nextFundingStartTime is the next time middleware will take investment
     */
    function getCurrentFundingCycle(address token)
        external
        view
        returns (uint lastFundingStartTime, uint nextFundingStartTime);

    /**
     * @notice Returns the last defunding start time and next defunding start time 
     * when middleware will send requested withdrawal for users
     * @param token is token address
     * @return lastDefundingStartTime is the last time middleware sent requested withdrawal
     * @return nextDefundingStartTime is the next time middleware will send requested withdrawal
     */
    function getCurrentDefundingCycle(address token)
        external
        view
        returns (uint lastDefundingStartTime, uint nextDefundingStartTime);

    /**
     * @notice Returns the minimum amount token when user deposits
     * @param token is token address
     * @return the minimum funding amount
     */
    function minFunding(address token) external view returns (uint);

    /**
     * @notice Returns the maximum amount token when user deposits for token pool
     * @param token is token address
     * @return the maximum funding amount
     */
    function maxFunding(address token) external view returns (uint);

    /**
     * @notice Returns the maximum amount of liquidity pool that users can deposit
     * @param token is token address
     * @return the minimum funding amount of liquidity pool
     */
    function maxFundingPool(address token) external view returns (uint);

    /**
     * @notice Returns the minimum amount token when user requests withdrawal or force withdraws
     * @param token is token address
     * @return the minimum defunding amount
     */
    function minDefunding(address token) external view returns (uint);

    /**
     * @notice Updates defunding duration after admin changes cycles and applied time
     * @param token is token address
     */
    function updateDefundingDuration(address token) external;

    /**
     * @notice Updates funding duration after admin changes cycles and applied time
     * @param token is token address
     */
    function updateFundingDuration(address token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IContractStructure {
    struct Investment {
        uint amount;
        uint unit;
        uint48 timestamp;
        uint16 idChanged;
        bool isWhitelist;
    }

    struct Cycle {
        uint16 id;
        uint48 startTime;
        uint48 endTime;
    }

    struct TokenPair {
        address token;
        address liquidityToken;
    }

    struct AccountProfitInfo {
        uint profit;
        uint profitForWhitelist;
        uint claimedProfit;
        uint claimedProfitForWhitelist;
        uint lastProfitId;
        uint lastInvestmentId;
    }

    struct AccountTradingInfo {
        uint depositedTimestampOf;
        uint availableAmount;
        bool isNotFirstIncreaseInvestment;
    }

    /**
     * @dev Structure about fee configurations for interacting with functions of Precog contract
     * This configurations use feeDecimalBase() function to calculate the rate of fees
     * NOTE Explainations of params in struct:
     * - `depositFee` - a fee base that be charged when user deposits into Precog
     * - `withdrawalFee` - a fee base that be charged when user withdraws from Precog
     * - `tradingFee` - a fee base that be charged when middleware sends profit to Precog
     * - `lendingFee` - a fee base that be charged when user lends to Precog
     */
    struct FeeConfiguration {
        uint64 depositFee;
        uint64 withdrawalFee;
        uint64 tradingFee;
        uint64 lendingFee;
    }

    /**
     * @dev Structure about cycle configurations when users interact in Precog contract:
     * - Taking investment
     * - Sending requested withdrawal
     * - Calculating profit
     * - Locking time
     * NOTE Explainations of params in struct:
     * - `firstDefundingCycle` - a duration is used when user requests withdrawal for the first time
     * - `fundingCycle` - a duration is used when user deposits or transfers IPCOG
     * - `defundingCycle` - a duration is used when user requests withdrawal or transfers IPCOG
     * - `tradingCycle` - a duration is used to calculate profit for users when middleware sends profit
     */
    struct CycleConfiguration {
        uint32 firstDefundingCycle;
        uint32 fundingCycle;
        uint32 defundingCycle;
        uint32 tradingCycle;
    }

    /**
     * @dev Structure about the time apply cycle configurations when admin set new cycle configurations
     * NOTE Explainations of params in struct:
     * - `firstDefundingDuration` - a duration is used when user requests withdrawal for the first time
     * - `fundingDuration` - a duration is used when user deposits or transfers IPCOG
     * - `defundingDuration` - a duration is used when user requests withdrawal or transfers IPCOG
     * - `tradingDuration` - a duration is used to calculate profit for users when middleware sends profit
     */
    struct CyclesChangedInfo {
        uint48 tradingApplyTime;
        uint48 fundingApplyTime;
        uint48 defundingApplyTime;
        uint48 fundingDuration;
        uint48 firstDefundingDuration;
        uint48 defundingDuration;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.2;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.2;

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