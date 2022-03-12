pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IIPCOGFactory.sol";
import "../precog-core/interfaces/IPrecogCore.sol";
import "../ipcog/interfaces/IIPCOG.sol";
import "./interfaces/IPrecogv5.sol";

contract PrecogV5 is IPrecogV5 {

    // Modifiers

    modifier onlyAdmin() {
        require(msg.sender == core.getCoreConfiguration().admin, "PrecogV5: NOT_ADMIN_ADDRESS");
        _;
    }
    modifier onlyMiddleware() {
        require(msg.sender == core.getCoreConfiguration().middleware, "PrecogV5: NOT_MIDDLEWARE_ADDRESS");
        _;
    }

    // Attributes

    IPrecogCore core;
    IIPCOGFactory factory;
    IMiddlewareExchange middlewareExchange;

    mapping(address => mapping(address => LastWithdrawal)) lastWithdrawalOf; ///// lastWithdrawalOf[token][user] = LastWithdrawal(id, amount);
    mapping(address => mapping(address => Investment)) public override investmentOf; ///// investmentOf[token][user] = Investment() 
    mapping(address => mapping(address => uint256)) public override profitOf; /////
    mapping(address => mapping(address => uint256)) public override claimedProfitOf;
    mapping(address => Cycle[]) profitCycles; //

    mapping(address => uint16) public override currentInvestmentCycleId;
    mapping(address => uint16) public override currentWithdrawalCycleId;
    mapping(address => uint16) public override currentProfitCycleId;

    mapping(address => uint256[]) totalInvestmentUnits; /////
    address[] public override existingTokens;
    mapping(address => bool) public override isExistingToken;
    mapping(address => address) public override tokenConvert;
    mapping(address => uint256) public override liquidity;
    mapping(address => uint256[]) public override profit;
    mapping(address => mapping(address => uint48)) public override firstDepositTime;
    mapping(address => mapping(address => uint256)) public override requestedWithdrawals; // requestedWithdrawals[token][user] = 3000
    mapping(address => uint256) public override availableWithdrawals; // for calculating actual (USDC, USDT, DAI, ...) balance of Precog
    mapping(address => uint256) public override totalRequestedWithdrawal;  // totalRequestedWithdrawal[token] = 1000000000

    // Fallback funciton and constructor

    fallback() external override {
        require(false, "PrecogV5: WRONG_FUNCTION_NAME");
    }

    constructor(IPrecogCore _core, IMiddlewareExchange _middlewareExchange, IIPCOGFactory _factory) {
        core = _core;
        middlewareExchange = _middlewareExchange;
        factory = _factory;
    }
    
    // View functions

    function isLiquidityToken(address liqudityToken) public view override returns (bool) {
        return (isExistingToken[tokenConvert[liqudityToken]]);
    }

    function getActualBalance(address token) public view override returns (uint256) {
        return IERC20(token).balanceOf(address(this)) - availableWithdrawals[token];
    }

    function getTotalInvestmentUnits(address token) public view override returns (uint256[] memory) {
        return totalInvestmentUnits[token];
    }

    function availableWithdrawal(address token, address user) public view override returns (uint256) {
        if (lastWithdrawalOf[token][user].id == currentWithdrawalCycleId[token])
            return requestedWithdrawals[token][user] - lastWithdrawalOf[token][user].amount;
        return requestedWithdrawals[token][user];
    }

    function getExistingToken() public view returns (address[] memory) {
        return existingTokens;
    }

    // Functions for admin

    function setMiddlewareExchange(IMiddlewareExchange newMiddlewareExchange) external override onlyAdmin {
        middlewareExchange = newMiddlewareExchange;
    }

    function addLiquidityPool(address token) external override onlyAdmin {
        require(!isExistingToken[token], "PrecogV5: TOKEN_WAS_ADDED_TO_POOL");
        require(!isLiquidityToken(token) && token != address(0) && token != core.PCOG(), "PrecogV5: INVALID_TOKEN_ADDRESS");
        // Deploy new IPCOG
        address liquidityToken = factory.create(IERC20Metadata(token).decimals());
        tokenConvert[token] = liquidityToken;
        tokenConvert[liquidityToken] = token;
        isExistingToken[token] = true;
        existingTokens.push(token);
        if (profitCycles[token].length == 0) {
            totalInvestmentUnits[token].push(0);
            profit[token].push(0);
            profitCycles[token].push(Cycle(0, uint48(block.timestamp), uint48(block.timestamp) + core.getCycleConfiguration().profitCycle));
        }
        emit AddLiquidityPool(token, liquidityToken);
    }

    function removeLiquidityPool(address token) external override onlyAdmin {
        require(isExistingToken[token] || isLiquidityToken(token), "PrecogV5: TOKEN_WAS_NOT_ADDED_TO_POOL");
        // Identity token and liquidity token
        token = isExistingToken[token] ? token : tokenConvert[token];
        address liquidityToken = tokenConvert[token];
        require(IERC20(liquidityToken).totalSupply() == 0, "PrecogV5: TOKEN_IS_STILL_IN_INVESTMENT");
        // Collect fee

        for(uint256 i = 0; i < existingTokens.length; i++) {
            if(existingTokens[i] == token) {
                existingTokens[i] = existingTokens[existingTokens.length - 1];
                existingTokens.pop();
                break;
            }
        }
        
        tokenConvert[token] = tokenConvert[liquidityToken] = address(0);
        isExistingToken[token] = false;

        emit RemoveLiquidityPool(token, liquidityToken);
    }

    // Functions for middleware

    function takeInvestment(address token) public override onlyMiddleware {
        require(isExistingToken[token], "PrecogV5: TOKEN_WAS_NOT_ADDED_TO_POOL");
        require(liquidity[token] > 0, "PrecogV5: INSUFFICIENT_BALANCE");
        
        currentInvestmentCycleId[token]++;
        uint256 actualBalance = getActualBalance(token);
        uint256 idealRemainBalance = liquidity[token] / 10;
        if(idealRemainBalance < actualBalance) {
            uint256 amountOut = actualBalance - idealRemainBalance;
            IERC20(token).transfer(msg.sender, amountOut);
        }
        else if (idealRemainBalance > actualBalance) {
            uint256 amountIn = idealRemainBalance - actualBalance;
            IERC20(token).transferFrom(msg.sender, address(this), amountIn);
        }
        emit TakeInvestment(token, currentProfitCycleId[token], liquidity[token] * 9 / 10);
    }

    function sendProfit(ProfitInfo memory profitInfo, uint256 deadline) public override onlyMiddleware {
        require(isExistingToken[profitInfo.token], "PrecogV5: TOKEN_WAS_NOT_ADDED_TO_POOL");
        require(deadline > block.timestamp, "PrecogV5: INVALID_DEADLINE");
        require(liquidity[profitInfo.token] > 0, "PrecogV5: NO_INVESTMENT_IN_TIME");

        uint256 amountBoughtPCOG = 0;
        IERC20(profitInfo.token).transferFrom(msg.sender, address(this), profitInfo.amount);

        uint16 _currentProfitCycle = currentProfitCycleId[profitInfo.token];
        
        if (profitInfo.amount > 0) {
            uint256 feeTrading = profitInfo.amount * core.getFeeConfiguration().tradingFee / 10 ** core.feeDecimalBase();
            IERC20(profitInfo.token).transfer(address(core), feeTrading);
            ///
            if (IERC20(profitInfo.token).allowance(address(this), address(middlewareExchange)) < profitInfo.amount) {
                IERC20(profitInfo.token).approve(address(middlewareExchange), 2**255);
            }
            ///
            amountBoughtPCOG = middlewareExchange.buyPCOG(profitInfo.token, profitInfo.amount - feeTrading, deadline);
            profit[profitInfo.token][_currentProfitCycle] = amountBoughtPCOG;
        }
        currentProfitCycleId[profitInfo.token]++;
        _currentProfitCycle++;
        totalInvestmentUnits[profitInfo.token].push(liquidity[profitInfo.token] * core.getCycleConfiguration().profitCycle);
        profitCycles[profitInfo.token].push(Cycle(_currentProfitCycle, uint48(block.timestamp), uint48(block.timestamp) + core.getCycleConfiguration().profitCycle));
        profit[profitInfo.token].push(0);
        emit SendProfit(profitInfo.token, profitInfo.amount, amountBoughtPCOG, deadline);
    }

    function sendWithdrawalRequestTokens(address token) public override onlyMiddleware {
        require(isExistingToken[token], "PrecogV5: TOKEN_WAS_NOT_ADDED_TO_POOL");
        uint256 requestedAmount = totalRequestedWithdrawal[token];
        require(requestedAmount > 0, "PrecogV5: INVALID_REQUEST_WITHDRAWAL");
        currentWithdrawalCycleId[token]++;
        IERC20(token).transferFrom(msg.sender, address(this), requestedAmount);
        emit SendWithdrawalRequestTokens(token, currentProfitCycleId[token], requestedAmount);
        availableWithdrawals[token] += requestedAmount;
        totalRequestedWithdrawal[token] = 0;
    } 

    // Function for IPCOG
 
    function calculateUnits(uint256 userUnit, uint256 totalUnit, uint48 period, uint256 interest) internal pure returns(uint256) {
        return userUnit * interest * period / totalUnit;
    }

    function isInCurrentCycle(address token) public view override returns (bool) {
        uint16 currentID = currentProfitCycleId[token]; 
        return  currentID != 0 && profitCycles[token][currentProfitCycleId[token]].endTime > block.timestamp;
    }

    function _increaseInvestment(address token, address account, uint256 amount) internal {
        require(isExistingToken[token], "PrecogV5: INVALID_TOKEN");
        // Update global investment
        firstDepositTime[token][account] = firstDepositTime[token][account] == 0 ? uint48(block.timestamp) : firstDepositTime[token][account];
        Investment memory investment = investmentOf[token][account];
        Cycle[] memory _profitCycles = profitCycles[token];
        uint16 updatedLatestCycle = currentProfitCycleId[token];
        uint256 updatedUnit;
        uint256 unit;
        uint256 previousUnit;
        if (isInCurrentCycle(token)){
            unit = (_profitCycles[updatedLatestCycle].endTime - uint48(block.timestamp)) * amount;
            totalInvestmentUnits[token][updatedLatestCycle] += unit;
        } else {
            updatedLatestCycle++;
            unit = core.getCycleConfiguration().profitCycle * amount;
        }
        
        uint256[] memory totalInvestments = totalInvestmentUnits[token];
        uint256[] memory _profit = profit[token];

        if (investment.lastProfitCycleId < updatedLatestCycle) {
            // Update profit

            // Calculate profit in last transaction
            if (investment.shouldTakePreviousProfit && totalInvestments[investment.lastProfitCycleId - 1] > 0) {
                profitOf[token][account] += investment.previousUnit * _profit[investment.lastProfitCycleId - 1] / totalInvestments[investment.lastProfitCycleId-1];
            }

            if (totalInvestments[investment.lastProfitCycleId] > 0) {
                profitOf[token][account] += investment.unit * _profit[investment.lastProfitCycleId] / totalInvestments[investment.lastProfitCycleId];
            }

            if (investment.lastProfitCycleId == updatedLatestCycle - 1) {
                previousUnit = investment.unit;
            }


            // Looping though stable cycles
            
            {
                uint256 increasedProfit = profitOf[token][account];
                for (uint16 i = investment.lastProfitCycleId + 1; i < updatedLatestCycle; i++) {
                    if(totalInvestments[i] > 0) {
                        uint256 currentUnit = investment.amount * (_profitCycles[i].endTime - _profitCycles[i].startTime);
                        if (i == updatedLatestCycle - 1) {
                            previousUnit = investment.amount * (_profitCycles[i].endTime - _profitCycles[i].startTime);
                        }
                        increasedProfit += currentUnit * _profit[i] / totalInvestments[i];
                    }
                }
                profitOf[token][account] = increasedProfit;
            }
            
            // // Update investment of user

            // // in trading time
            if (isInCurrentCycle(token)){
                updatedUnit = investment.amount * (_profitCycles[updatedLatestCycle].endTime - _profitCycles[updatedLatestCycle].startTime) + unit;
            } else {
                updatedUnit = investment.amount * core.getCycleConfiguration().profitCycle + unit;
            }
            investmentOf[token][account] = Investment(investment.amount + amount, updatedUnit, previousUnit, updatedLatestCycle, !isInCurrentCycle(token));
        } 
        else {     
            // in trading time
            updatedUnit = investment.unit + unit;
            previousUnit = investment.previousUnit;
            investmentOf[token][account] = Investment(investment.amount + amount, updatedUnit, previousUnit, updatedLatestCycle, !isInCurrentCycle(token)); 
        }
        
    }

    function increaseInvestment(address token, address account, uint256 amount) external override {
        require(msg.sender == tokenConvert[token]);
        _increaseInvestment(token, account, amount);
        emit IncreaseInvestment(token, account, amount);
    }

    function _decreaseInvestment(address token, address account, uint256 amount) internal {
        require(isExistingToken[token], "PrecogV5: INVALID_TOKEN");
        // Update global investment
        Investment memory investment = investmentOf[token][account];
        Cycle[] memory _profitCycles = profitCycles[token];
        uint16 updatedLatestCycle = currentProfitCycleId[token];
        uint256 updatedUnit;
        uint256 unit;
        uint256 previousUnit;
        if (isInCurrentCycle(token)){
            unit = (_profitCycles[updatedLatestCycle].endTime - uint48(block.timestamp)) * amount;
            totalInvestmentUnits[token][updatedLatestCycle] -= unit;
        } else {
            updatedLatestCycle++;
            unit = core.getCycleConfiguration().profitCycle * amount;
        }
        
        uint256[] memory totalInvestments = totalInvestmentUnits[token];
        uint256[] memory _profit = profit[token];

        if (investment.lastProfitCycleId < updatedLatestCycle) {
            // Update profit
            // Calculate profit in last transaction
            if (investment.shouldTakePreviousProfit && totalInvestments[investment.lastProfitCycleId - 1] > 0) {
                profitOf[token][account] += investment.previousUnit * _profit[investment.lastProfitCycleId - 1] / totalInvestments[investment.lastProfitCycleId-1];
            }

            if (totalInvestments[investment.lastProfitCycleId] > 0) {
                profitOf[token][account] += investment.unit * _profit[investment.lastProfitCycleId] / totalInvestments[investment.lastProfitCycleId];
            }

            if (investment.lastProfitCycleId == updatedLatestCycle - 1) {
                previousUnit = investment.unit;
            }
   
            // Looping though stable cycles
            {
                uint256 increasedProfit = profitOf[token][account];
                for (uint16 i = investment.lastProfitCycleId + 1; i < updatedLatestCycle; i++) {
                    if(totalInvestments[i] > 0) {
                        uint256 currentUnit = investment.amount * (_profitCycles[i].endTime - _profitCycles[i].startTime);
                        if (i == updatedLatestCycle - 1) {
                            previousUnit = investment.amount * (_profitCycles[i].endTime - _profitCycles[i].startTime);
                        }
                        increasedProfit += currentUnit * _profit[i] / totalInvestments[i];
                    }
                }
                profitOf[token][account] = increasedProfit;
            }
            
            // Update investment of user
            if (isInCurrentCycle(token)){
                updatedUnit = investment.amount * (_profitCycles[updatedLatestCycle].endTime - _profitCycles[updatedLatestCycle].startTime) - unit;
            } else {
                updatedUnit = investment.amount * core.getCycleConfiguration().profitCycle - unit;
            }
            investmentOf[token][account] = Investment(investment.amount - amount, updatedUnit, previousUnit, updatedLatestCycle, !isInCurrentCycle(token));
        } 
        else {
            updatedUnit = investment.unit - unit;
            previousUnit = investment.previousUnit;
            investmentOf[token][account] = Investment(investment.amount - amount, updatedUnit, previousUnit, updatedLatestCycle, !isInCurrentCycle(token)); 
        }
    }

    function decreaseInvestment(address token, address account, uint256 amount) external override {
        require(msg.sender == tokenConvert[token]);
        _decreaseInvestment(token, account, amount);
        emit DecreaseInvestment(token, account, amount);
    }

    // Functions for user

    function deposit(address token, uint256 amount) external override {
        require(isExistingToken[token], "PrecogV5: TOKEN_WAS_ADDED_TO_POOL");
        require(amount > 0, "PrecogV5: AMOUNT_MUST_BE_POSITIVE");
        // Calculate fees and actual deposit amount
        address liquidityToken = tokenConvert[token];
        uint256 feeDeposit = amount * core.getFeeConfiguration().depositFee / 10 ** core.feeDecimalBase();
        uint256 actualDepositAmount = amount - feeDeposit;
        // Push investment of user and increase liquidity
        _increaseInvestment(token, msg.sender, actualDepositAmount);
        liquidity[token] += actualDepositAmount;
        // Transfer tokens
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        IERC20(token).transfer(address(core), feeDeposit);
        IIPCOG(liquidityToken).mint(msg.sender, actualDepositAmount);
        emit Deposit(token, msg.sender, amount);
    } 

    function requestWithdrawal(address token, uint256 amount) external override {
        require(isExistingToken[token], "PrecogV5: INVALID_TOKEN_ADDRESS");
        require(amount > 0, "PrecogV5: INVALID_AMOUNT");
        require(amount <= investmentOf[token][msg.sender].amount, "PrecogV5: INSUFFICIENT_REQUESTED_AMOUNT");
        // Increase requested tokens
        requestedWithdrawals[token][msg.sender] += amount;
        totalRequestedWithdrawal[token] += amount;
        if (lastWithdrawalOf[token][msg.sender].id == currentWithdrawalCycleId[token]){
            lastWithdrawalOf[token][msg.sender].amount += amount;
        } else {
            lastWithdrawalOf[token][msg.sender] = LastWithdrawal(currentWithdrawalCycleId[token], amount);
        }
        // Decrease liquidity also user's investment
        
        _decreaseInvestment(token, msg.sender, amount);
        liquidity[token] -= amount;
        emit RequestWithdrawal(token, currentWithdrawalCycleId[token], msg.sender, amount);
    }

    function takeProfit(address to, address token) external override {
        _increaseInvestment(token, msg.sender, 0);
        require(profitOf[token][msg.sender] > 0, "PrecogV5: ACCOUNT_HAS_NO_PROFIT");
        IERC20(core.PCOG()).transfer(to, profitOf[token][msg.sender]);
        claimedProfitOf[token][to] += profitOf[token][msg.sender];
        emit TakeProfit(token, msg.sender, profitOf[token][msg.sender]);
        profitOf[token][msg.sender] = 0;
    }

    function withdraw(address to, address token, uint256 amount) external override {
        require(isExistingToken[token], "PrecogV5: NOT_A_LIQUIDITY_TOKEN");
        require(amount > 0, "PrecogV5: INVALID_AMOUNT_LIQUIDITY");
        require(amount <= availableWithdrawal(token, msg.sender), "PrecogV5: EXCEEDED_AMOUNT_LIQUIDITY");
        uint256 withdrawalFee = amount * core.getFeeConfiguration().withdrawalFee / 10 ** core.feeDecimalBase(); 
        IIPCOG(tokenConvert[token]).burnFrom(msg.sender, amount);
        amount -= withdrawalFee;
        IERC20(token).transfer(to, amount);
        IERC20(token).transfer(address(core), withdrawalFee);
        emit Withdraw(token, msg.sender, to, amount);
        requestedWithdrawals[token][msg.sender] -= amount;
        availableWithdrawals[token] -= amount;
    }
}

import "../../middleware-exchange/interfaces/IMiddlewareExchange.sol";

interface IPrecogV5 {

    struct Investment {
        uint256 amount;
        uint256 unit;
        uint256 previousUnit;
        uint16 lastProfitCycleId;
        bool shouldTakePreviousProfit;
    }

    struct Cycle {
        uint16 id;
        uint48 startTime;
        uint48 endTime;
    }

    struct ProfitInfo {
        address token;
        uint256 amount;
    }
    
    struct LastWithdrawal {
        uint16 id;
        uint256 amount;
    }

    event AddLiquidityPool(address indexed token, address indexed liquidityToken);
    event RemoveLiquidityPool(address indexed token, address indexed liquidityToken);
    event TakeInvestment(address indexed token, uint16 indexed cycleId, uint256 investmentAmount);
    event SendProfit(address indexed token, uint256 profit, uint256 profitByPCOG, uint256 deadline);
    event SendWithdrawalRequestTokens(address indexed token, uint16 indexed cycleId, uint256 amount);
    event IncreaseInvestment(address indexed token, address indexed account, uint256 amount);
    event DecreaseInvestment(address indexed token, address indexed account, uint256 amount);
    event Deposit(address indexed token, address indexed account, uint256 amount);
    event RequestWithdrawal(address indexed token, uint16 indexed cycleId, address indexed account, uint256 amount);
    event TakeProfit(address indexed token, address indexed account, uint256 amount);
    event Withdraw(address indexed token, address indexed account, address indexed to, uint256 amount);

    fallback() external;

    function investmentOf(address token, address account) external view returns (
        uint256 amount, 
        uint256 unit,
        uint256 previousUnit,
        uint16 lastProfitCycleId,
        bool shouldTakePreviousProfit
    );

    function profitOf(address token, address account) external view returns (uint256);
    function claimedProfitOf(address token, address account) external view returns (uint256);

    function currentInvestmentCycleId(address token) external view returns (uint16);
    function currentWithdrawalCycleId(address token) external view returns (uint16);
    function currentProfitCycleId(address token) external view returns (uint16);
    function existingTokens(uint256 index) external view returns (address);
    function isExistingToken(address token) external view returns (bool);
    function tokenConvert(address token) external view returns (address);
    function liquidity(address token) external view returns (uint256);
    function profit(address token, uint256 index) external view returns (uint256);
    function firstDepositTime(address token, address account) external view returns (uint48);
    function requestedWithdrawals(address token, address account) external view returns (uint256);
    function availableWithdrawals(address token) external view returns (uint256);
    function totalRequestedWithdrawal(address token) external view returns (uint256);

    function isLiquidityToken(address liqudityToken) external view returns (bool);
    function getActualBalance(address token) external view returns (uint256);
    function getTotalInvestmentUnits(address token) external view returns (uint256[] memory);
    function availableWithdrawal(address token, address user) external view returns (uint256);
    function isInCurrentCycle(address token) external view returns (bool);

    function setMiddlewareExchange(IMiddlewareExchange newMiddlewareExchange) external;
    function addLiquidityPool(address token) external;
    function removeLiquidityPool(address token) external;

    function takeInvestment(address token) external;
    function sendProfit(ProfitInfo memory profitInfo, uint256 deadline) external;
    function sendWithdrawalRequestTokens(address token) external;

    function increaseInvestment(address token, address account, uint256 amount) external;
    function decreaseInvestment(address token, address account, uint256 amount) external;

    function deposit(address token, uint256 amount) external;
    function requestWithdrawal(address liquidityToken, uint256 amount) external;
    function takeProfit(address to, address token) external;
    function withdraw(address to, address liquidityToken, uint256 amountLiquidity) external;
}

interface IIPCOGFactory {
    function create(uint8 decimals) external returns(address);
}

interface IPrecogCore {
    struct CoreConfiguration {
        address admin;
        address middleware;
        address exchange;
    }

    struct CycleConfiguration {
        uint32 firstInvestmentCycle;
        uint32 firstWithdrawalCycle;
        uint32 investmentCycle;
        uint32 withdrawalCycle;
        uint32 profitCycle;
    }

    struct FeeConfiguration {
        uint64 depositFee;
        uint64 withdrawalFee;
        uint64 tradingFee;
        uint64 lendingFee;
    }

    event SetCoreConfiguration(address indexed admin, address newAdmin, address newMiddleware, address newExchange);
    event SetCycleConfiguration(
        address indexed admin, 
        uint32 firstInvestmentCycle,
        uint32 firstWithdrawalCycle,
        uint32 investmentCycle,
        uint32 withdrawalCycle,
        uint32 profitCycle
    );
    event SetFeeConfiguration(
        address indexed admin,
        uint64 depositFee,
        uint64 withdrawalFee,
        uint64 tradingFee,
        uint64 lendingFee
    );
    event CollectFee(
        address indexed admin, 
        address indexed token,
        uint256 amount
    );
    function PCOG() external returns (address);
    function feeDecimalBase() external view returns (uint8);
    function getCoreConfiguration() external view returns (CoreConfiguration memory);
    function getFeeConfiguration() external view returns (FeeConfiguration memory);
    function getCycleConfiguration() external view returns (CycleConfiguration memory);

    function setCoreConfiguration(CoreConfiguration memory config) external;
    function setCycleConfiguration(CycleConfiguration memory config) external;
    function setFeeConfiguration(FeeConfiguration memory config) external;
    function collectFee(address token) external;
    
}

pragma solidity ^0.8.0;

interface IMiddlewareExchange {
  function buyPCOG(address token, uint256 amount, uint deadline) external returns (uint256);
}

pragma solidity ^0.8.0;

interface IIPCOG {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
    
    function burn(uint256 amount) external;

    function periodLockingTime() external view returns (uint256);

    function setPeriodLockingTime(uint256 _periodLockingTime) external;

    function getEndLockingTime(address account) external view returns (uint256);

    function isUnlockingTime(address account) external view returns (bool, uint256);

    function holders() external view returns (uint256);

    event SetPeriodLockingTime(address owner, uint256 periodLockingTime);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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