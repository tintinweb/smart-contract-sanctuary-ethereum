/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

// File: contracts\precog\interfaces\IPrecogStorage.sol
// SPDX-License-Identifier: MIT


pragma solidity ^0.8.2;
interface IPrecogStorage {
    
    struct Investment {
        uint amount;
        uint unit;
        uint48 timestamp;
        uint16 idChanged;
    }

    struct Cycle {
        uint16 id;
        uint48 startTime;
        uint48 endTime;
    }

    struct CyclesChangedInfo {
        uint48 tradingApplyTime;
        uint48 fundingApplyTime;
        uint48 defundingApplyTime;
        uint48 fundingDuration;
        uint48 firstDefundingDuration;
        uint48 defundingDuration;
    }

    struct TokenPair {
        address token;
        address liquidityToken;
    }

    struct AccountProfitInfo {
        uint profitOf;
        uint claimedProfitOf;
        uint lastProfitIdOf;
        uint lastInvestmentIdOf;
    }

    struct AccountTradingInfo {
        uint depositedTimestampOf;
        uint availableAmount;
        bool isNotFirstIncreaseInvestment;
    }

    function getAdmin() external view returns (address);
    function transferAdmin(address newAdmin) external;
    function getMiddlewareService() external view returns (address);
    function setMiddlewareService(address newMiddlewareService) external;
    function getPCOG() external view returns (address);
    function setPCOG(address newPCOG) external;
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
    function getExistingTokenPairByIndex(uint index) external view returns (TokenPair memory pair);
    function getCurrentProfitId(address token) external view returns (uint);
    function updateCurrentProfitId(address token, uint newValue) external;
    function checkIsExistingToken(address token) external view returns (bool);
    function updateIsExistingToken(address token, bool newValue) external;
    function getTokenConvert(address token) external view returns (address);
    function updateTokenConvert(address token, address newValue) external;
    function getLiquidity(address token) external view returns (uint);
    function updateLiquidity(address token, uint newValue) external;
    function checkIsNotFirstInvestmentCycle(address token) external view returns (bool);
    function updateIsNotFirstInvestmentCycle(address token, bool newValue) external;
    function checkIsRemoved(address token) external view returns (bool);
    function updateIsRemoved(address token, bool newValue) external;
    function getTradingCycles(address token) external view returns (Cycle[] memory);
    function getTradingCycleByIndex(address token, uint index) external view returns (Cycle memory);
    function getInfoTradingCycleById(address token, uint16 id)
        external
        view
        returns (
            uint48 startTime,
            uint48 endTime,
            uint unit,
            uint profitAmount
        );
    function getLastTradingCycle(address token) external view returns(Cycle memory);
    function pushTradingCycle(address token, Cycle memory tradingCycle) external;
    function getProfits(address token) external view returns (uint[] memory);
    function updateProfitByIndex(address token, uint index, uint newValue) external;
    function pushProfit(address token, uint newValue) external;
    function checkIsUpdateUnitTradingCycle(address token, uint index) external view returns (bool);
    function updateIsUpdateUnitTradingCycle(address token, uint index, bool newValue) external;
    function getTotalUnitsTradingCycle(address token, uint index) external view returns (uint);
    function updateTotalUnitsTradingCycle(address token, uint index, uint newValue) external;
    function getInvestmentsOf(address token, address account) external view returns (Investment[] memory);
    function getInvestmentOfByIndex(address token, address account, uint index) external view returns (Investment memory);
    /**
     * @dev Returns the last investment of user
     * @param token is token address
     * @param account is account address
     * @return lastInvestmentOf is the last Investment of user
     */
    function getLastInvestmentOf(address token, address account) external view returns (Investment memory);
    function updateInvestmentOfByIndex(address token, address account, uint index, Investment memory newValue) external;
    function pushInvestmentOf(address token, address account, Investment memory newInvestmentOf) external;
    function popInvestmentOf(address token, address account) external;
    function getAccountProfitInfo(address token, address account) external view returns (AccountProfitInfo memory);
    function updateAccountProfitInfo(address token, address account, AccountProfitInfo memory newValue) external;
    function getAccountTradingInfo(address token, address account) external view returns (AccountTradingInfo memory);
    function updateAccountTradingInfo(address token, address account, AccountTradingInfo memory newValue) external;
    function getUnitInTradingCycle(address token, address account, uint id) external view returns (uint);
}

// File: contracts\precog\PrecogStorage.sol


pragma solidity ^0.8.2;
contract PrecogStorage is IPrecogStorage {

    modifier onlyAdmin() {
        require(msg.sender == admin, "PrecogStorage: Caller is not admin");
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "PrecogStorage: Caller is not operator");
        _;
    }

    address private admin;
    address private middlewareService;
    address private middlewareExchange;
    address private PCOG;
    address private precogInternal;
    address private precogCore;
    address private precogFactory;
    address private precogVault;
    address private precogProfit;
    address private precog;
    address private withdrawalRegister;
    address[] private existingTokens;
    mapping(address => bool) private operators;
    mapping(address => uint) private currentProfitId;
    mapping(address => bool) private isExistingToken;
    mapping(address => address) private tokenConvert;
    mapping(address => uint) private liquidity;
    mapping(address => bool) private isNotFirstInvestmentCycle;
    mapping(address => bool) private isRemoved;
    mapping(address => Cycle[]) private tradingCycles; 
    mapping(address => uint[]) private profits;
    mapping(address => mapping(uint => bool)) private isUpdateUnitTradingCycle;
    mapping(address => mapping(uint => uint)) private totalUnitsTradingCycle;
    mapping(address => mapping(address => Investment[])) private investmentsOf;
    mapping(address => mapping(address => AccountProfitInfo)) private accountProfitInfo;
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

    function getExistingTokensPair() external view override onlyOperator returns (TokenPair[] memory pairs) {
        pairs = new TokenPair[](existingTokens.length);
        for (uint index = 0; index < existingTokens.length; index++) {
            pairs[index] = TokenPair({
                token: existingTokens[index], 
                liquidityToken: tokenConvert[existingTokens[index]]
            });
        }
    }

    function getExistingTokenPairByIndex(uint index) external view override returns (TokenPair memory pair) {
        pair = TokenPair({
            token: existingTokens[index], 
            liquidityToken: tokenConvert[existingTokens[index]]
        });
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

    function getTradingCycles(address token) external view override returns (Cycle[] memory) {
        return tradingCycles[token];
    }

    function getTradingCycleByIndex(address token, uint index) external view override returns (Cycle memory) {
        return tradingCycles[token][index];
    }

    function getInfoTradingCycleById(address token, uint16 id)
        external
        view
        override
        returns (
            uint48 startTime,
            uint48 endTime,
            uint unit,
            uint profitAmount
        )
    {
        Cycle memory tradingCycle = tradingCycles[token][id];
        startTime = tradingCycle.startTime;
        endTime = tradingCycle.endTime;
        unit = totalUnitsTradingCycle[token][id];
        if (id < profits[token].length) {
            profitAmount = profits[token][id];
        }
    }

    function getLastTradingCycle(address token) external view override returns(Cycle memory) {
        return tradingCycles[token][tradingCycles[token].length - 1];
    }

    function pushTradingCycle(address token, Cycle memory tradingCycle) external override onlyOperator {
        tradingCycles[token].push(tradingCycle);
    }

    function getProfits(address token) external view override returns (uint[] memory) {
        return profits[token];
    }

    function updateProfitByIndex(address token, uint index, uint newValue) external override onlyOperator {
        profits[token][index] = newValue;
    }

    function pushProfit(address token, uint newValue) external override onlyOperator {
        profits[token].push(newValue);
    }

    function checkIsUpdateUnitTradingCycle(address token, uint index) external view override returns (bool) {
        return isUpdateUnitTradingCycle[token][index];
    }

    function updateIsUpdateUnitTradingCycle(address token, uint index, bool newValue) external override onlyOperator {
        isUpdateUnitTradingCycle[token][index] = newValue;
    }

    function getTotalUnitsTradingCycle(address token, uint index) external view override returns (uint) {
        return totalUnitsTradingCycle[token][index];
    }

    function updateTotalUnitsTradingCycle(address token, uint index, uint newValue) external override onlyOperator {
        totalUnitsTradingCycle[token][index] = newValue;
    }

    function getInvestmentsOf(address token, address account) external view override returns (Investment[] memory) {
        return investmentsOf[token][account];
    }

    function getInvestmentOfByIndex(address token, address account, uint index) external view override returns (Investment memory) {
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

    function updateInvestmentOfByIndex(address token, address account, uint index, Investment memory newValue) external override onlyOperator {
        investmentsOf[token][account][index] = newValue;
    }

    function pushInvestmentOf(address token, address account, Investment memory newInvestmentOf) external override onlyOperator {
        investmentsOf[token][account].push(newInvestmentOf);
    }

    function popInvestmentOf(address token, address account) external override onlyOperator {
        investmentsOf[token][account].pop();
    }

    function getAccountProfitInfo(address token, address account) external view override returns (AccountProfitInfo memory) {
        return accountProfitInfo[token][account];
    }

    function updateAccountProfitInfo(address token, address account, AccountProfitInfo memory newValue) external override onlyOperator {
        accountProfitInfo[token][account] = newValue;
    }

    function getAccountTradingInfo(address token, address account) external view override returns (AccountTradingInfo memory) {
        return accountTradingInfo[token][account];
    }

    function updateAccountTradingInfo(address token, address account, AccountTradingInfo memory newValue) external override onlyOperator {
        accountTradingInfo[token][account] = newValue;
    }

    function getUnitInTradingCycle(address token, address account, uint id) external view override returns (uint) {
        Cycle memory tradingCycle;

        if(id >= tradingCycles[token].length) {
            tradingCycle = tradingCycles[token][tradingCycles[token].length - 1];
            tradingCycle.id++;
        } else {
            tradingCycle = tradingCycles[token][id];
        }
        uint48 duration = tradingCycle.endTime - tradingCycle.startTime;
        Investment[] memory investments = investmentsOf[token][account];
        for(uint investmentId = 0; investmentId < investments.length; investmentId++) {
            IPrecogStorage.Investment memory nextInvestment = IPrecogStorage.Investment(0, 0, 0, 0);
            if(investments[investmentId].idChanged == id) {
                return investments[investmentId].unit;
            } else if (
                investments[investmentId].idChanged < id && 
                investmentId < investments.length - 1
            ) {
                nextInvestment = investments[investmentId + 1];
                if(nextInvestment.idChanged > id) {
                    return investments[investmentId].amount * duration;
                } else if(nextInvestment.idChanged == id) {
                    return nextInvestment.unit;
                }
            }
        }
        return investments[investments.length - 1].amount * duration;
    }
}