// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./interfaces/IPrecogStorage.sol";

contract PrecogStorage is IPrecogStorage {
    modifier onlyAdmin() {
        require(msg.sender == admin, "PrecogStorage: Caller is not admin");
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "PrecogStorage: Caller is not operator");
        _;
    }

    // Admin address
    address private admin;

    // Middleware service address
    address private middlewareService;

    // Middleware exchange that interact to varity other exchange contract
    address private middlewareExchange;

    // PCOG token address
    address private PCOG;

    // GMT token address
    address private GMT;

    // PrecogInternal contract
    address private precogInternal;

    // PrecogCore contract
    address private precogCore;

    // PrecogFactory contract
    address private precogFactory;

    // PrecogVault contract
    address private precogVault;

    // PrecogProfit contract
    address private precogProfit;

    // Precog contract
    address private precog;

    // WithdrawalRegister contract
    address private withdrawalRegister;

    // List of existing token that be added in PrecogFactory contract
    address[] private existingTokens;

    // The operators are the addresses can modify data in this contract
    mapping(address => bool) private operators;

    // The id of the last trading cycle which is sent profit by middleware
    mapping(address => uint) private currentProfitId;

    // Check if the token address is added to pool
    mapping(address => bool) private isExistingToken;

    // Convert token address to liquidity token address and back up
    mapping(address => address) private tokenConvert;

    // The liquidity currently of the token bool
    mapping(address => uint) private liquidity;

    // The liquidity only for whitelist - it is a part of liquidity
    mapping(address => uint) private liquidityWhitelist;

    // Check if the token address is the first time added to pool to set up
    mapping(address => bool) private isNotFirstInvestmentCycle;

    // Check if the token address is removed from pool to stop the trading cycle
    mapping(address => bool) private isRemoved;

    // List of whitelist account that can receive profit by token
    mapping(address => address[]) private whitelists;

    mapping(address => mapping(address => bool)) private isInWhitelist;

    // Store the information of each trading cycles
    mapping(address => Cycle[]) private tradingCycles;

    // The profit of each trading cycle of token pool
    mapping(address => uint[]) private profits;

    // The profit by investment token of each trading cycle of token pool - it is a part of profits
    mapping(address => uint[]) private profitsForWhitelists;

    // Check if users interact with trading cycle id in the first time,
    // if the first time, they will update totalUnitsTradingCycle and changed value to true
    mapping(address => mapping(uint => bool)) private isUpdateUnitTradingCycle;

    // The total units of users in each trading cycle of token pool
    mapping(address => mapping(uint => uint)) private totalUnitsTradingCycle;

    // The total units of whitelist users in each trading cycle of token pool - it is a part of totalUnitsTradingCycle
    mapping(address => mapping(uint => uint)) private totalUnitsForWhitelistsTradingCycle;

    // Store the list investments data of user each token pool
    mapping(address => mapping(address => Investment[])) private investmentsOf;

    // Store the profit information of user each token pool
    mapping(address => mapping(address => AccountProfitInfo)) private accountProfitInfo;

    // Store the trading information of user each token pool
    mapping(address => mapping(address => AccountTradingInfo)) private accountTradingInfo;

    constructor(address _admin) {
        admin = _admin;
    }

    function isOperator(address operator) external view override returns (bool) {
        return operators[operator];
    }

    function _addOperator(address _operator) internal {
        operators[_operator] = true;
    }

    function _removeOperator(address _operator) internal {
        operators[_operator] = false;
    }

    function getAdmin() external view override returns (address) {
        return admin;
    }

    function transferAdmin(address newAdmin) external override onlyAdmin {
        admin = newAdmin;
    }

    function getMiddlewareService() external view override returns (address) {
        return middlewareService;
    }

    function setMiddlewareService(address newMiddlewareService) external override onlyAdmin {
        middlewareService = newMiddlewareService;
    }

    function getMiddlewareExchange() external view override returns (address) {
        return middlewareExchange;
    }

    function setMiddlewareExchange(address newMiddlewareExchange) external override onlyAdmin {
        _removeOperator(middlewareExchange);
        _addOperator(newMiddlewareExchange);
        middlewareExchange = newMiddlewareExchange;
    }

    function getPCOG() external view override returns (address) {
        return PCOG;
    }

    function setPCOG(address newPCOG) external override onlyAdmin {
        PCOG = newPCOG;
        emit SetPCOG(PCOG);
    }

    function getGMT() external view override returns (address) {
        return GMT;
    }

    function setGMT(address newGMT) external override onlyAdmin {
        GMT = newGMT;
        emit SetGMT(GMT);
    }

    function getPrecogInternal() external view override returns (address) {
        return precogInternal;
    }

    function setPrecogInternal(address newPrecogInternal) external override onlyAdmin {
        _removeOperator(precogInternal);
        _addOperator(newPrecogInternal);
        precogInternal = newPrecogInternal;
    }

    function getPrecogCore() external view override returns (address) {
        return precogCore;
    }

    function setPrecogCore(address newPrecogCore) external override onlyAdmin {
        _removeOperator(precogCore);
        _addOperator(newPrecogCore);
        precogCore = newPrecogCore;
    }

    function getPrecogFactory() external view override returns (address) {
        return precogFactory;
    }

    function setPrecogFactory(address newPrecogFactory) external override onlyAdmin {
        _removeOperator(precogFactory);
        _addOperator(newPrecogFactory);
        precogFactory = newPrecogFactory;
    }

    function getPrecogVault() external view override returns (address) {
        return precogVault;
    }

    function setPrecogVault(address newPrecogVault) external override onlyAdmin {
        _removeOperator(precogVault);
        _addOperator(newPrecogVault);
        precogVault = newPrecogVault;
    }

    function getPrecogProfit() external view override returns (address) {
        return precogProfit;
    }

    function setPrecogProfit(address newPrecogProfit) external override onlyAdmin {
        _removeOperator(precogProfit);
        _addOperator(newPrecogProfit);
        precogProfit = newPrecogProfit;
    }

    function getPrecog() external view override returns (address) {
        return precog;
    }

    function setPrecog(address newPrecog) external override onlyAdmin {
        _removeOperator(precog);
        _addOperator(newPrecog);
        precog = newPrecog;
    }

    function getWithdrawalRegister() external view override returns (address) {
        return withdrawalRegister;
    }

    function setWithdrawalRegister(address newWithdrawalRegister) external override onlyAdmin {
        _removeOperator(withdrawalRegister);
        _addOperator(newWithdrawalRegister);
        withdrawalRegister = newWithdrawalRegister;
    }

    function getExistingTokens() external view override returns (address[] memory tokens) {
        tokens = existingTokens;
    }

    function findExistingTokenIndex(address token) external view override returns (uint index) {
        address[] memory _existingTokens = existingTokens;
        for (uint i = 0; i < _existingTokens.length; i++) {
            if (_existingTokens[i] == token) {
                index = i;
                break;
            }
        }
    }

    function pushExistingToken(address token) external override onlyOperator {
        existingTokens.push(token);
    }

    function swapExistingTokensByIndex(uint indexTokenA, uint indexTokenB) external override onlyOperator {
        address tmpToken = existingTokens[indexTokenA];
        existingTokens[indexTokenA] = existingTokens[indexTokenB];
        existingTokens[indexTokenB] = tmpToken;
    }

    function popExistingToken() external override onlyOperator {
        existingTokens.pop();
    }

    function getExistingTokensPair() external view override returns (TokenPair[] memory pairs) {
        pairs = new TokenPair[](existingTokens.length);
        for (uint index = 0; index < existingTokens.length; index++) {
            pairs[index] = TokenPair({
                token: existingTokens[index],
                liquidityToken: tokenConvert[existingTokens[index]]
            });
        }
    }

    function getExistingTokenPairByIndex(uint index) external view override returns (TokenPair memory pair) {
        pair = TokenPair({token: existingTokens[index], liquidityToken: tokenConvert[existingTokens[index]]});
    }

    function getCurrentProfitId(address token) external view override returns (uint) {
        return currentProfitId[token];
    }

    function updateCurrentProfitId(address token, uint newValue) external override onlyOperator {
        currentProfitId[token] = newValue;
    }

    function checkIsExistingToken(address token) external view override returns (bool) {
        return isExistingToken[token];
    }

    function updateIsExistingToken(address token, bool newValue) external override onlyOperator {
        isExistingToken[token] = newValue;
    }

    function getTokenConvert(address token) external view override returns (address) {
        return tokenConvert[token];
    }

    function updateTokenConvert(address token, address newValue) external override onlyOperator {
        tokenConvert[token] = newValue;
    }

    function getLiquidity(address token) external view override returns (uint) {
        return liquidity[token];
    }

    function updateLiquidity(address token, uint newValue) external override onlyOperator {
        liquidity[token] = newValue;
    }

    function getLiquidityWhitelist(address token) external view override returns (uint) {
        return liquidityWhitelist[token];
    }

    function updateLiquidityWhitelist(address token, uint newValue) external override onlyOperator {
        liquidityWhitelist[token] = newValue;
    }

    function checkIsNotFirstInvestmentCycle(address token) external view override returns (bool) {
        return isNotFirstInvestmentCycle[token];
    }

    function updateIsNotFirstInvestmentCycle(address token, bool newValue) external override onlyOperator {
        isNotFirstInvestmentCycle[token] = newValue;
    }

    function checkIsRemoved(address token) external view override returns (bool) {
        return isRemoved[token];
    }

    function updateIsRemoved(address token, bool newValue) external override onlyOperator {
        isRemoved[token] = newValue;
    }

    function getWhitelist(address token) external view override returns (address[] memory) {
        return whitelists[token];
    }

    function pushWhitelist(address token, address account) external override onlyOperator {
        whitelists[token].push(account);
    }

    function removeFromWhitelist(address token, address account) external override onlyOperator {
        address[] memory _whitelists = whitelists[token];
        for (uint i = 0; i < _whitelists.length; i++) {
            if (_whitelists[i] == account) {
                whitelists[token][i] = _whitelists[_whitelists.length - 1];
                whitelists[token].pop();
            }
        }
    }

    function checkIsInWhitelist(address token, address account) external view override returns (bool) {
        return isInWhitelist[token][account];
    }

    function updateIsInWhitelist(
        address token,
        address account,
        bool newValue
    ) external override onlyOperator {
        isInWhitelist[token][account] = newValue;
    }

    function getTradingCycles(address token) external view override returns (Cycle[] memory) {
        return tradingCycles[token];
    }

    function getTradingCycleByIndex(address token, uint index) external view override returns (Cycle memory) {
        return tradingCycles[token][index];
    }

    function getInfoTradingCycleById(address token, uint id)
        external
        view
        override
        returns (
            uint48 startTime,
            uint48 endTime,
            uint unit,
            uint unitForWhitelist,
            uint profitAmount
        )
    {
        Cycle memory tradingCycle = tradingCycles[token][id];
        startTime = tradingCycle.startTime;
        endTime = tradingCycle.endTime;
        unit = totalUnitsTradingCycle[token][id];
        unitForWhitelist = totalUnitsForWhitelistsTradingCycle[token][id];
        if (id < profits[token].length) {
            profitAmount = profits[token][id];
        }
    }

    function getLastTradingCycle(address token) external view override returns (Cycle memory) {
        return tradingCycles[token][tradingCycles[token].length - 1];
    }

    function pushTradingCycle(address token, Cycle memory tradingCycle) external override onlyOperator {
        tradingCycles[token].push(tradingCycle);
    }

    function getProfits(address token) external view override returns (uint[] memory) {
        return profits[token];
    }

    function updateProfitByIndex(
        address token,
        uint index,
        uint newValue
    ) external override onlyOperator {
        profits[token][index] = newValue;
    }

    function pushProfit(address token, uint newValue) external override onlyOperator {
        profits[token].push(newValue);
    }

    function getProfitsForWhitelist(address token) external view override returns (uint[] memory) {
        return profitsForWhitelists[token];
    }

    function updateProfitForWhitelistByIndex(
        address token,
        uint index,
        uint newValue
    ) external override onlyOperator {
        profitsForWhitelists[token][index] = newValue;
    }

    function pushProfitForWhitelist(address token, uint newValue) external override onlyOperator {
        profitsForWhitelists[token].push(newValue);
    }

    function checkIsUpdateUnitTradingCycle(address token, uint index) external view override returns (bool) {
        return isUpdateUnitTradingCycle[token][index];
    }

    function updateIsUpdateUnitTradingCycle(
        address token,
        uint index,
        bool newValue
    ) external override onlyOperator {
        isUpdateUnitTradingCycle[token][index] = newValue;
    }

    function getTotalUnitsTradingCycle(address token, uint index) external view override returns (uint) {
        return totalUnitsTradingCycle[token][index];
    }

    function updateTotalUnitsTradingCycle(
        address token,
        uint index,
        uint newValue
    ) external override onlyOperator {
        totalUnitsTradingCycle[token][index] = newValue;
    }

    function getTotalUnitsForWhitelistTradingCycle(address token, uint index) external view override returns (uint) {
        return totalUnitsForWhitelistsTradingCycle[token][index];
    }

    function updateTotalUnitsForWhitelistTradingCycle(
        address token,
        uint index,
        uint newValue
    ) external override onlyOperator {
        totalUnitsForWhitelistsTradingCycle[token][index] = newValue;
    }

    function getInvestmentsOf(address token, address account) external view override returns (Investment[] memory) {
        return investmentsOf[token][account];
    }

    function getInvestmentOfByIndex(
        address token,
        address account,
        uint index
    ) external view override returns (Investment memory) {
        return investmentsOf[token][account][index];
    }

    function getLastInvestmentOf(address token, address account)
        external
        view
        override
        returns (Investment memory lastInvestmentOf)
    {
        lastInvestmentOf = investmentsOf[token][account][investmentsOf[token][account].length - 1];
    }

    function updateInvestmentOfByIndex(
        address token,
        address account,
        uint index,
        Investment memory newValue
    ) external override onlyOperator {
        investmentsOf[token][account][index] = newValue;
    }

    function pushInvestmentOf(
        address token,
        address account,
        Investment memory newInvestmentOf
    ) external override onlyOperator {
        investmentsOf[token][account].push(newInvestmentOf);
    }

    function popInvestmentOf(address token, address account) external override onlyOperator {
        investmentsOf[token][account].pop();
    }

    function getAccountProfitInfo(address token, address account)
        external
        view
        override
        returns (AccountProfitInfo memory)
    {
        return accountProfitInfo[token][account];
    }

    function updateAccountProfitInfo(
        address token,
        address account,
        AccountProfitInfo memory newValue
    ) external override onlyOperator {
        accountProfitInfo[token][account] = newValue;
    }

    function getAccountTradingInfo(address token, address account)
        external
        view
        override
        returns (AccountTradingInfo memory)
    {
        return accountTradingInfo[token][account];
    }

    function updateAccountTradingInfo(
        address token,
        address account,
        AccountTradingInfo memory newValue
    ) external override onlyOperator {
        accountTradingInfo[token][account] = newValue;
    }

    function getUnitInTradingCycle(
        address token,
        address account,
        uint id
    ) external view override returns (uint) {
        Cycle memory tradingCycle;
        if (id >= tradingCycles[token].length) {
            uint length;
            unchecked {
                length = tradingCycles[token].length - 1;
                tradingCycle = tradingCycles[token][length];
                tradingCycle.id++;
            }
        } else {
            tradingCycle = tradingCycles[token][id];
        }
        uint48 duration;
        unchecked {
            duration = tradingCycle.endTime - tradingCycle.startTime;
        }

        Investment[] memory investments = investmentsOf[token][account];
        for (uint investmentId = 0; investmentId < investments.length; ) {
            Investment memory nextInvestment = Investment({
                amount: 0,
                unit: 0,
                timestamp: 0,
                idChanged: 0,
                isWhitelist: false
            });
            if (investments[investmentId].idChanged == id) {
                return investments[investmentId].unit;
            } else if (investments[investmentId].idChanged < id && investmentId < investments.length - 1) {
                nextInvestment = investments[investmentId + 1];
                if (nextInvestment.idChanged > id) {
                    return investments[investmentId].amount * duration;
                } else if (nextInvestment.idChanged == id) {
                    return nextInvestment.unit;
                }
            }
            unchecked {
                investmentId++;
            }
        }
        return investments[investments.length - 1].amount * duration;
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