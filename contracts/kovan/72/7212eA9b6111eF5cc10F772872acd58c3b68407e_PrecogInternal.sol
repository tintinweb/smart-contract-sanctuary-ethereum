// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "../../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libraries/PrecogV5Library.sol";
import "./interfaces/IPrecogCore.sol";
import "./interfaces/IPrecogInternal.sol";

contract PrecogInternal is IPrecogInternal {
    using SafeERC20 for IERC20;

    IPrecogStorage public precogStorage;

    modifier onlyPrecog() {
        require(msg.sender == precogStorage.getPrecog(), "PrecogInternal: Caller is not accessible");
        _;
    }

    modifier isExistingToken(address token) {
        require(precogStorage.checkIsExistingToken(token), "PrecogInternal: Token is not in trading");
        _;
    }

    constructor(IPrecogStorage _precogStorage) {
        precogStorage = _precogStorage;
    }

    function _getCoreInstance() internal view returns (IPrecogCore core) {
        return IPrecogCore(precogStorage.getPrecogCore());
    }

    /**
     * @dev Returns the trading cycle following the timestamp
     * @param _token is token address
     * @param _timestamp is the timestamp that be used to calculate trading cycle
     * @return _currentTradingCycleByTimestamp is the trading cycle is calculated by timestamp
     */
    function _getTradingCycleByTimestamp(address _token, uint _timestamp)
        internal
        view
        returns (Cycle memory _currentTradingCycleByTimestamp)
    {
        Cycle[] memory _tradingCycles = precogStorage.getTradingCycles(_token);
        Cycle memory _lastTradingCycle = _tradingCycles[_tradingCycles.length - 1];

        // Returns the last cycle if token pool has been removed
        if (precogStorage.checkIsRemoved(_token)) {
            return _lastTradingCycle;
        }

        // Get current trading cycle by timestamp
        _currentTradingCycleByTimestamp = PrecogV5Library._calculateTradingCycleByTimestamp(
            _lastTradingCycle,
            _getCoreInstance().getCycleConfiguration().tradingCycle,
            _getCoreInstance().getCyclesChangedInfo(_token).tradingApplyTime,
            _timestamp
        );
    }

    function getTradingCycleByTimestamp(address token, uint timestamp)
        external
        view
        override
        returns (Cycle memory currentTradingCycleByTimestamp)
    {
        currentTradingCycleByTimestamp = _getTradingCycleByTimestamp(token, timestamp);
    }

    /**
     * @dev Returns profit of account from investment and profit of trading cycles
     * @param _token is token address
     * @param _account is account address
     * @return _accountProfitInfo is profit info of account
     * NOTE Function get virtual data, not storage data
     */
    function _calculateProfit(address _token, address _account)
        internal
        view
        returns (AccountProfitInfo memory _accountProfitInfo)
    {
        // Declare memory datas
        Investment[] memory _investments = precogStorage.getInvestmentsOf(_token, _account);
        Cycle[] memory _tradingCycles = precogStorage.getTradingCycles(_token);
        uint[] memory _profits = precogStorage.getProfits(_token);
        uint[] memory _profitsForWhitelist = precogStorage.getProfitsForWhitelist(_token);
        uint _updatedLatestCycle = precogStorage.getCurrentProfitId(_token);
        uint _lastAvailableProfitId;
        _accountProfitInfo = precogStorage.getAccountProfitInfo(_token, _account);
        if (_accountProfitInfo.lastProfitId < _updatedLatestCycle) {
            // Start the loop of investmentsOf
            for (_accountProfitInfo.lastInvestmentId; _accountProfitInfo.lastInvestmentId < _investments.length; ) {
                Investment memory _nextInvestment;
                // Return the algorithm (1)
                if (
                    _accountProfitInfo.lastProfitId == _updatedLatestCycle &&
                    _updatedLatestCycle == _investments[_accountProfitInfo.lastInvestmentId].idChanged
                ) {
                    return _accountProfitInfo;
                }
                // Get next investment of account and available profit id for the loop of profitId
                (_nextInvestment, _lastAvailableProfitId) = PrecogV5Library._chooseLastAvailableTradingId(
                    _investments,
                    _accountProfitInfo.lastInvestmentId,
                    _updatedLatestCycle
                );
                // Start the loop of profitId
                for (_accountProfitInfo.lastProfitId; _accountProfitInfo.lastProfitId < _lastAvailableProfitId; ) {
                    // Calculate profit for whitelist at trading cycle
                    if (_investments[_accountProfitInfo.lastInvestmentId].isWhitelist) {
                        // Get total units for whitelists
                        uint _totalUnitsForWhitelist = precogStorage.getTotalUnitsForWhitelistTradingCycle(
                            _token,
                            _accountProfitInfo.lastProfitId
                        );
                        // Calculate profit for account at trading cycle
                        _accountProfitInfo.profitForWhitelist += PrecogV5Library._calculateProfitAtCycle(
                            _tradingCycles[_accountProfitInfo.lastProfitId],
                            _investments[_accountProfitInfo.lastInvestmentId],
                            _totalUnitsForWhitelist,
                            _profitsForWhitelist[_accountProfitInfo.lastProfitId],
                            _accountProfitInfo.lastProfitId
                        );
                    }
                    // Calcuclate profit for normal account at trading cycle
                    else {
                        // Get total units for normal accounts
                        uint _totalUnits = (precogStorage.getTotalUnitsTradingCycle(
                            _token,
                            _accountProfitInfo.lastProfitId
                        ) -
                            precogStorage.getTotalUnitsForWhitelistTradingCycle(
                                _token,
                                _accountProfitInfo.lastProfitId
                            ));
                        // Calculate profit for account at trading cycle
                        _accountProfitInfo.profit += PrecogV5Library._calculateProfitAtCycle(
                            _tradingCycles[_accountProfitInfo.lastProfitId],
                            _investments[_accountProfitInfo.lastInvestmentId],
                            _totalUnits,
                            _profits[_accountProfitInfo.lastProfitId],
                            _accountProfitInfo.lastProfitId
                        );
                    }
                    unchecked {
                        _accountProfitInfo.lastProfitId++;
                    }
                }
                // Return the algorithm (2)
                if (
                    _accountProfitInfo.lastProfitId == _updatedLatestCycle &&
                    _updatedLatestCycle != _nextInvestment.idChanged
                ) {
                    return _accountProfitInfo;
                }

                unchecked {
                    _accountProfitInfo.lastInvestmentId++;
                }

                // NOTE:
                // (1) happens when the current profit id of trading cycle is at the middle of two investmentsOf
                // (2) happens when the current profit id of trading cycle is at the start of investmentOf
            }
        }
    }

    function calculateProfit(address token, address account)
        external
        view
        override
        returns (AccountProfitInfo memory accountProfitInfo)
    {
        accountProfitInfo = _calculateProfit(token, account);
    }

    /**
     * @dev Calculates and updates profit of account from investment and profit of trading cycles
     * @param _token is token address
     * @param _account is account address
     */
    function _updateProfit(address _token, address _account) internal {
        precogStorage.updateAccountProfitInfo(_token, _account, _calculateProfit(_token, _account));
    }

    function updateProfit(address token, address account) external override {
        _updateProfit(token, account);
    }

    function _processFirstTimeIncreaseInvestment(
        address _token,
        address _account,
        Cycle memory _futureTradingCycle
    ) internal {
        AccountTradingInfo memory _accountTradingInfo = precogStorage.getAccountTradingInfo(
            _token,
            _account
        );
        AccountProfitInfo memory _accountProfitInfo = precogStorage.getAccountProfitInfo(
            _token,
            _account
        );

        if (!precogStorage.getAccountTradingInfo(_token, _account).isNotFirstIncreaseInvestment) {
            // Modify the profit id to future trading cycle
            _accountProfitInfo.lastProfitId = uint16(_futureTradingCycle.id);

            // Mark that the account has deposited for the first time at token pool
            _accountTradingInfo.isNotFirstIncreaseInvestment = true;

            // Update account trading info and account profit info
            precogStorage.updateAccountTradingInfo(_token, _account, _accountTradingInfo);
            precogStorage.updateAccountProfitInfo(_token, _account, _accountProfitInfo);
        }
    }

    function _updateTotalUnitsForFirstTimeOfTradingCycle(
        address _token,
        Cycle memory _futureTradingCycle
    ) internal {
        if (!precogStorage.checkIsUpdateUnitTradingCycle(_token, _futureTradingCycle.id)) {
            uint _duration;
            uint _newTotalUnits;
            uint _newTotalUnitsForWhitelist;

            // Get duration of future trading cycle
            unchecked {
                _duration = _futureTradingCycle.endTime - _futureTradingCycle.startTime;
            }

            // Update total units for trading cycle
            unchecked {
                _newTotalUnits =
                    precogStorage.getTotalUnitsTradingCycle(_token, _futureTradingCycle.id) +
                    (precogStorage.getLiquidity(_token) * _duration);
            }

            precogStorage.updateTotalUnitsTradingCycle(_token, _futureTradingCycle.id, _newTotalUnits);

            // Update total units of whitelists for trading cycle

            unchecked {
                _newTotalUnitsForWhitelist =
                    precogStorage.getTotalUnitsForWhitelistTradingCycle(_token, _futureTradingCycle.id) +
                    (precogStorage.getLiquidityWhitelist(_token) * _duration);
            }

            precogStorage.updateTotalUnitsForWhitelistTradingCycle(
                _token,
                _futureTradingCycle.id,
                _newTotalUnitsForWhitelist
            );

            // Mark the trading cycle is updated total units
            precogStorage.updateIsUpdateUnitTradingCycle(_token, _futureTradingCycle.id, true);
        }
    }

    function _processIncreaseInvestment(
        address _token,
        address _account,
        uint _amount,
        uint48 _timestamp,
        Cycle memory _futureTradingCycle
    ) internal {
        Investment[] memory _investmentsOf = precogStorage.getInvestmentsOf(_token, _account);
        uint _unit;

        // Calculate increased unit for account
        unchecked {
            _unit = _amount * (_futureTradingCycle.endTime - _timestamp);
        }
        if (_investmentsOf.length > 0) {
            Investment memory _lastInvestmentOf = _investmentsOf[_investmentsOf.length - 1];
            Investment memory _newInvestmentOf = Investment({
                amount: _lastInvestmentOf.amount + _amount,
                unit: 0,
                timestamp: _timestamp,
                idChanged: _futureTradingCycle.id,
                isWhitelist: precogStorage.checkIsInWhitelist(_token, _account)
            });
            if (_lastInvestmentOf.idChanged < _futureTradingCycle.id) {
                unchecked {
                    _newInvestmentOf.unit =
                        _lastInvestmentOf.amount *
                        (_futureTradingCycle.endTime - _futureTradingCycle.startTime) +
                        _unit;
                }
                precogStorage.pushInvestmentOf(_token, _account, _newInvestmentOf);
            } else if (_lastInvestmentOf.idChanged == _futureTradingCycle.id) {
                unchecked {
                    _newInvestmentOf.unit = _lastInvestmentOf.unit + _unit;
                }
                precogStorage.updateInvestmentOfByIndex(_token, _account, _investmentsOf.length - 1, _newInvestmentOf);
            }
            uint newTotalUnits = precogStorage.getTotalUnitsForWhitelistTradingCycle(_token, _futureTradingCycle.id);
            // Last investment and current investment are different from isWhitelist
            if (_lastInvestmentOf.isWhitelist != _newInvestmentOf.isWhitelist) {
                // Current investment is whitelist
                if (_newInvestmentOf.isWhitelist) {
                    // Transfer all unit of investment into totalUnitsForWhitelist
                    newTotalUnits += _newInvestmentOf.unit;
                } else {
                    // Current investment is not whitelist
                    newTotalUnits -= _newInvestmentOf.unit;
                }
            } else {
                if (_newInvestmentOf.isWhitelist) {
                    newTotalUnits += _unit;
                }
            }
            precogStorage.updateTotalUnitsForWhitelistTradingCycle(_token, _futureTradingCycle.id, newTotalUnits);
        } else {
            Investment memory _newInvestmentOf = Investment({
                amount: _amount,
                unit: _unit,
                timestamp: _timestamp,
                idChanged: _futureTradingCycle.id,
                isWhitelist: precogStorage.checkIsInWhitelist(_token, _account)
            });
            precogStorage.pushInvestmentOf(_token, _account, _newInvestmentOf);
            if (_newInvestmentOf.isWhitelist) {
                precogStorage.updateTotalUnitsForWhitelistTradingCycle(_token, _futureTradingCycle.id, _unit);
            }
        }

        uint _newUnit;
        unchecked {
            _newUnit = precogStorage.getTotalUnitsTradingCycle(_token, _futureTradingCycle.id) + _unit;
        }
        precogStorage.updateTotalUnitsTradingCycle(_token, _futureTradingCycle.id, _newUnit);
    }

    /**
     * @dev Calculates and updates investment amount, unit, 
     trading cycle id at current investment or push new investment into array
     * @param _token is token address
     * @param _account is account address
     * @param _amount is token amount that is used to increase unit in trading cycle
     * @param _timestamp is timestamp that is the next funding cycle with deposit or block.timestamp with transfer IPCOG
     */
    function _increaseInvestment(
        address _token,
        address _account,
        uint _amount,
        uint48 _timestamp
    ) internal {
        Cycle memory _futureTradingCycle = _getTradingCycleByTimestamp(_token, _timestamp);
        _processFirstTimeIncreaseInvestment(_token, _account, _futureTradingCycle);
        _updateTotalUnitsForFirstTimeOfTradingCycle(_token, _futureTradingCycle);
        _processIncreaseInvestment(_token, _account, _amount, _timestamp, _futureTradingCycle);
    }

    function increaseInvestment(
        address token,
        address account,
        uint amount,
        uint48 timestamp
    ) external override isExistingToken(token) {
        require(precogStorage.isOperator(msg.sender), "PrecogInternal: Caller is not allowed");
        _increaseInvestment(token, account, amount, timestamp);
    }

    function _isBeforeFundingTime(address _token, address _account)
        internal
        view
        returns (bool _isBeforeInvestmentCycle)
    {
        _isBeforeInvestmentCycle = _availableDepositedAmount(_token, _account) > 0;
    }

    function isBeforeFundingTime(address token, address account)
        external
        view
        override
        returns (bool _isBeforeInvestmentCycle)
    {
        _isBeforeInvestmentCycle = _isBeforeFundingTime(token, account);
    }

    function _processDecreaseInvestment(
        address _token,
        address _account,
        uint _amount,
        uint48 _timestamp,
        Cycle memory _futureTradingCycle
    ) internal returns (uint _remainingAmount) {
        Investment[] memory _investmentsOf = precogStorage.getInvestmentsOf(_token, _account);
        Investment memory _lastInvestmentOf = _investmentsOf[_investmentsOf.length - 1];
        Investment memory _newInvestmentOf = Investment({
            amount: _lastInvestmentOf.amount - _amount,
            unit: 0,
            timestamp: _lastInvestmentOf.timestamp,
            idChanged: _futureTradingCycle.id,
            isWhitelist: precogStorage.checkIsInWhitelist(_token, _account)
        });
        _remainingAmount = _newInvestmentOf.amount;
        uint _unit = _amount * (_futureTradingCycle.endTime - _timestamp);

        if (_lastInvestmentOf.idChanged < _futureTradingCycle.id) {
            _newInvestmentOf.unit = (_lastInvestmentOf.amount *
                (_futureTradingCycle.endTime - _futureTradingCycle.startTime) -
                _unit);
            precogStorage.pushInvestmentOf(_token, _account, _newInvestmentOf);
        } else {
            _newInvestmentOf.unit = _lastInvestmentOf.unit - _unit;
            precogStorage.updateInvestmentOfByIndex(_token, _account, _investmentsOf.length - 1, _newInvestmentOf);
        }
        uint newTotalUnits = precogStorage.getTotalUnitsForWhitelistTradingCycle(_token, _futureTradingCycle.id);
        // Last investment and current investment are different from isWhitelist
        if (_lastInvestmentOf.isWhitelist != _newInvestmentOf.isWhitelist) {
            // Current investment is whitelist
            if (_newInvestmentOf.isWhitelist) {
                // Transfer all unit of investment into totalUnitsForWhitelist
                newTotalUnits += _newInvestmentOf.unit;
            } else {
                // Current investment is not whitelist
                newTotalUnits -= _newInvestmentOf.unit;
            }
        } else {
            if (_newInvestmentOf.isWhitelist) {
                newTotalUnits -= _unit;
            }
        }
        precogStorage.updateTotalUnitsForWhitelistTradingCycle(_token, _futureTradingCycle.id, newTotalUnits);
        uint _newUnit = precogStorage.getTotalUnitsTradingCycle(_token, _futureTradingCycle.id) - _unit;
        precogStorage.updateTotalUnitsTradingCycle(_token, _futureTradingCycle.id, _newUnit);
    }

    function _decreaseInvestment(
        address _token,
        address _account,
        uint _amount,
        uint48 _timestamp
    ) internal returns (uint _remainingAmount) {
        require(
            !_isBeforeFundingTime(_token, _account),
            "PrecogInternal: Cannot request withdrawal before funding time"
        );

        Cycle memory _futureTradingCycle = _getTradingCycleByTimestamp(_token, _timestamp);
        _updateTotalUnitsForFirstTimeOfTradingCycle(_token, _futureTradingCycle);
        _remainingAmount = _processDecreaseInvestment(_token, _account, _amount, _timestamp, _futureTradingCycle);
    }

    function decreaseInvestment(
        address token,
        address account,
        uint amount,
        uint48 timestamp
    ) external override isExistingToken(token) returns (uint remainingAmount) {
        require(precogStorage.isOperator(msg.sender), "PrecogInternal: Caller is not allowed");
        remainingAmount = _decreaseInvestment(token, account, amount, timestamp);
    }

    function _updateDepositInfo(
        address _token,
        address _account,
        uint _amount
    ) internal {
        AccountTradingInfo memory _accountTradingInfo = precogStorage.getAccountTradingInfo(
            _token,
            _account
        );
        if (block.timestamp >= _accountTradingInfo.depositedTimestampOf) {
            _accountTradingInfo.availableAmount = _amount;
            _accountTradingInfo.depositedTimestampOf = precogStorage.getLastInvestmentOf(_token, _account).timestamp;
        } else {
            unchecked {
                _accountTradingInfo.availableAmount += _amount;
            }
        }
        precogStorage.updateAccountTradingInfo(_token, _account, _accountTradingInfo);
    }

    function updateDepositInfo(
        address token,
        address account,
        uint amount
    ) external override onlyPrecog {
        _updateDepositInfo(token, account, amount);
    }

    function _availableDepositedAmount(address _token, address _account) internal view returns (uint _amount) {
        AccountTradingInfo memory _accountTradingInfo = precogStorage.getAccountTradingInfo(
            _token,
            _account
        );
        _amount = _accountTradingInfo.depositedTimestampOf > block.timestamp ? _accountTradingInfo.availableAmount : 0;
    }

    function availableDepositedAmount(address token, address account) external view override returns (uint amount) {
        amount = _availableDepositedAmount(token, account);
    }

    /**
     * @dev Updates last trading cycle to current trading cycle when anyone interacts with contract
     * @param _token is token address
     * @param _isLimitedTradingCycles is check if msg.sender want to limit the trading cycles to update
     * @param _limitTradingCycles is the limit of trading cycles to update
     * NOTE The trading cycle get by
     * entTradingCycle function in Precog contract is virtual data,
     * it is not updated in storage real time so that when anyone interacts with contract,
     * it will be updated the storage
     */
    function _updateCurrentTradingCycle(
        address _token,
        bool _isLimitedTradingCycles,
        uint _limitTradingCycles
    ) internal {
        _getCoreInstance().updateFundingDuration(_token);
        _getCoreInstance().updateDefundingDuration(_token);
        Cycle memory _lastTradingCycle = precogStorage.getLastTradingCycle(_token);
        uint48 _newCycleStartTime;
        uint48 _duration;
        uint48 _tradingCycle = _getCoreInstance().getCycleConfiguration().tradingCycle;
        uint _timestampApplyNewTradingCycle = _getCoreInstance().getCyclesChangedInfo(_token).tradingApplyTime;
        while (uint48(block.timestamp) >= _lastTradingCycle.endTime) {
            if (_isLimitedTradingCycles) {
                if (_limitTradingCycles > 0) {
                    unchecked {
                        _limitTradingCycles--;
                    }
                } else {
                    return;
                }
            }
            emit UpdateTradingCycle({
                token: _token,
                cycleId: _lastTradingCycle.id,
                liquidity: precogStorage.getLiquidity(_token),
                duration: _lastTradingCycle.endTime - _lastTradingCycle.startTime
            });

            unchecked {
                _newCycleStartTime = _lastTradingCycle.endTime;
                _duration = _newCycleStartTime < _timestampApplyNewTradingCycle
                    ? _lastTradingCycle.endTime - _lastTradingCycle.startTime
                    : _duration = _tradingCycle;

                _lastTradingCycle = Cycle({
                    id: _lastTradingCycle.id + 1,
                    startTime: _newCycleStartTime,
                    endTime: _newCycleStartTime + _duration
                });
            }

            precogStorage.pushTradingCycle(_token, _lastTradingCycle);
            _updateTotalUnitsForFirstTimeOfTradingCycle(_token, _lastTradingCycle);
        }
    }

    function updateCurrentTradingCycle(
        address token,
        bool isLimitedTradingCycles,
        uint limitTradingCycles
    ) external override isExistingToken(token) {
        _updateCurrentTradingCycle(token, isLimitedTradingCycles, limitTradingCycles);
    }

    function getCurrentTradingCycle(address token) external view override returns (Cycle memory) {
        return _getTradingCycleByTimestamp(token, block.timestamp);
    }

    function getTradingCycle(address token, uint48 tradingTime)
        external
        view
        override
        returns (Cycle memory)
    {
        return _getTradingCycleByTimestamp(token, tradingTime);
    }
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