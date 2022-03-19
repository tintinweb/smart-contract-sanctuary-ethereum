pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IIPCOGFactory.sol";
import "../precog-core/interfaces/IPrecogCore.sol";
import "../ipcog/interfaces/IIPCOG.sol";
import "./interfaces/IPrecogv5.sol";

contract PrecogV5 is IPrecogV5 { 

    using SafeERC20 for IERC20;

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
    mapping(address => Cycle[]) public override profitCycles; //

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
    mapping(address => mapping(uint16 => uint256)) updatedProfitCycle;///// token => profitCycleId => updatedCycle

    uint32 firstInvestmentCycle = 60; // 7 days
    uint32 firstWithdrawalCycle = 60; // 7days
    uint32 investmentCycle = 60; // 1 day
    uint32 withdrawalCycle = 60; // 2 days
    uint32 profitCycle = 60; // 1 day

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

    function getCycleConfiguration() external view override returns (CycleConfiguration memory) {
        return CycleConfiguration(firstInvestmentCycle, firstWithdrawalCycle, investmentCycle, withdrawalCycle, profitCycle);
    }

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

    function setCycleConfiguration(CycleConfiguration memory config) external override onlyAdmin {
        require(
            config.firstInvestmentCycle != 0 &&
            config.firstWithdrawalCycle != 0 &&
            config.investmentCycle != 0 &&
            config.withdrawalCycle != 0 &&
            config.profitCycle != 0
        );

        firstInvestmentCycle = config.firstInvestmentCycle;
        firstWithdrawalCycle = config.firstWithdrawalCycle;
        investmentCycle = config.investmentCycle;
        withdrawalCycle = config.withdrawalCycle;
        profitCycle = config.profitCycle;

        for(uint256 i = 0; i < existingTokens.length; i++) {
            updatedProfitCycle[existingTokens[i]][currentProfitCycleId[existingTokens[i]] + 1] = profitCycle;
        }

        emit SetCycleConfiguration(
            core.getCoreConfiguration().admin, 
            firstInvestmentCycle, 
            firstWithdrawalCycle, 
            investmentCycle, 
            withdrawalCycle, 
            profitCycle
        );
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
            profitCycles[token].push(Cycle(0, uint48(block.timestamp), uint48(block.timestamp) + profitCycle));
        }
        updatedProfitCycle[token][currentProfitCycleId[token]] = profitCycle;
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
            IERC20(token).safeTransfer(msg.sender, amountOut);
        }
        else if (idealRemainBalance > actualBalance) {
            uint256 amountIn = idealRemainBalance - actualBalance;
            IERC20(token).safeTransferFrom(msg.sender, address(this), amountIn);
        }
        emit TakeInvestment(token, currentProfitCycleId[token], liquidity[token] * 9 / 10);
    }

    function sendProfit(ProfitInfo memory profitInfo, uint256 deadline) public override onlyMiddleware {
        require(isExistingToken[profitInfo.token], "PrecogV5: TOKEN_WAS_NOT_ADDED_TO_POOL");
        require(deadline > block.timestamp, "PrecogV5: INVALID_DEADLINE");
        require(liquidity[profitInfo.token] > 0, "PrecogV5: NO_INVESTMENT_IN_TIME");

        uint256 amountBoughtPCOG = 0;
        IERC20(profitInfo.token).safeTransferFrom(msg.sender, address(this), profitInfo.amount);

        uint16 _currentProfitCycle = currentProfitCycleId[profitInfo.token];
        
        if (profitInfo.amount > 0) {
            uint256 feeTrading = profitInfo.amount * core.getFeeConfiguration().tradingFee / 10 ** core.feeDecimalBase();
            IERC20(profitInfo.token).safeTransfer(address(core), feeTrading);
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
        totalInvestmentUnits[profitInfo.token].push(liquidity[profitInfo.token] * profitCycle);
        profitCycles[profitInfo.token].push(Cycle(_currentProfitCycle, uint48(block.timestamp), uint48(block.timestamp) + profitCycle));
        profit[profitInfo.token].push(0);
        emit SendProfit(profitInfo.token, profitInfo.amount, amountBoughtPCOG, deadline);
    }

    function sendWithdrawalRequestTokens(address token) public override onlyMiddleware {
        require(isExistingToken[token], "PrecogV5: TOKEN_WAS_NOT_ADDED_TO_POOL");
        uint256 requestedAmount = totalRequestedWithdrawal[token];
        require(requestedAmount > 0, "PrecogV5: INVALID_REQUEST_WITHDRAWAL");
        currentWithdrawalCycleId[token]++;
        if(getActualBalance(token) < requestedAmount) IERC20(token).safeTransferFrom(msg.sender, address(this), requestedAmount - getActualBalance(token));
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

    

    function calculateProfit(address token, address account) external view returns (uint256 _profitOf) {
        require(isExistingToken[token], "PrecogV5: INVALID_TOKEN");
        Investment memory investment = investmentOf[token][account];
        uint256 updatedLatestCycle = currentProfitCycleId[token];
        
        Cycle[] memory _profitCycles = profitCycles[token];
        _profitOf = profitOf[token][account];
        uint256[] memory totalInvestments = totalInvestmentUnits[token];
        uint256[] memory _profit = profit[token];

        // Update profit
        // Calculate profit in last transaction
        if(investment.lastProfitCycleId > 0) {
            if (investment.shouldTakePreviousProfit && totalInvestments[investment.lastProfitCycleId - 1] > 0) {
                _profitOf += investment.previousUnit * _profit[investment.lastProfitCycleId - 1] / totalInvestments[investment.lastProfitCycleId-1];
            }
        }
        
        if (totalInvestments.length > investment.lastProfitCycleId && totalInvestments[investment.lastProfitCycleId] > 0) {
            _profitOf += investment.unit * _profit[investment.lastProfitCycleId] / totalInvestments[investment.lastProfitCycleId];
        }
        // Looping though stable cycles
        
    
        for (uint16 i = investment.lastProfitCycleId + 1; i < updatedLatestCycle; i++) {
            if(totalInvestments[i] > 0) {
                uint256 currentUnit = investment.amount * (_profitCycles[i].endTime - _profitCycles[i].startTime);
                _profitOf += currentUnit * _profit[i] / totalInvestments[i];
            }
        }
    
        
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
            unit = profitCycle * amount;
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
                if (investment.shouldTakePreviousProfit){
                    profitOf[token][account] += (investment.amount * (_profitCycles[investment.lastProfitCycleId].endTime - _profitCycles[investment.lastProfitCycleId].startTime)) * _profit[investment.lastProfitCycleId] / totalInvestments[investment.lastProfitCycleId];
                } else {
                    profitOf[token][account] += investment.unit * _profit[investment.lastProfitCycleId] / totalInvestments[investment.lastProfitCycleId];
                }
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
                            previousUnit = currentUnit;
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
                updatedUnit = investment.amount * profitCycle + unit; 
            }
            investmentOf[token][account] = Investment(investment.amount + amount, updatedUnit, previousUnit, updatedLatestCycle, !isInCurrentCycle(token));
        } 
        else {     
            // in trading time
            uint256 updatedAmount = investment.amount + amount;
            if (!isInCurrentCycle(token)){
                updatedUnit = updatedAmount * profitCycle;
                investmentOf[token][account] = Investment(updatedAmount, updatedUnit, previousUnit, updatedLatestCycle, false);
            } else if (investment.shouldTakePreviousProfit) {
                updatedUnit = investment.amount * (_profitCycles[updatedLatestCycle].endTime - _profitCycles[updatedLatestCycle].startTime) + unit;
                previousUnit = investment.previousUnit;
                investmentOf[token][account] = Investment(updatedAmount, updatedUnit, previousUnit, updatedLatestCycle, true); 
            } else {
                updatedUnit = investment.unit + unit;                
                previousUnit = investment.previousUnit;
                investmentOf[token][account] = Investment(updatedAmount, updatedUnit, previousUnit, updatedLatestCycle, true); 
            }
        }
        emit IncreaseInvestment(token, account, amount);
    }

    function increaseInvestment(address token, address account, uint256 amount) external override {
        require(msg.sender == tokenConvert[token]);
        _increaseInvestment(token, account, amount);
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
            unit = profitCycle * amount;
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
                if (investment.shouldTakePreviousProfit){
                    profitOf[token][account] += (investment.amount * (_profitCycles[investment.lastProfitCycleId].endTime - _profitCycles[investment.lastProfitCycleId].startTime)) * _profit[investment.lastProfitCycleId] / totalInvestments[investment.lastProfitCycleId];
                } else {
                    profitOf[token][account] += investment.unit * _profit[investment.lastProfitCycleId] / totalInvestments[investment.lastProfitCycleId];
                }
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
                            previousUnit = currentUnit;
                        }
                        increasedProfit += currentUnit * _profit[i] / totalInvestments[i];
                    }
                }
                profitOf[token][account] = increasedProfit;
            }
            
            // Update investment of user
            if (isInCurrentCycle(token)){/////
                updatedUnit = investment.amount * (_profitCycles[updatedLatestCycle].endTime - _profitCycles[updatedLatestCycle].startTime) - unit;
                investmentOf[token][account] = Investment(investment.amount - amount, updatedUnit, previousUnit, updatedLatestCycle, !isInCurrentCycle(token));
            }
            else {
                updatedUnit = investment.amount * profitCycle - unit;
                investmentOf[token][account] = Investment(investment.amount - amount, updatedUnit, previousUnit, updatedLatestCycle, !isInCurrentCycle(token));
            }
        } 
        else {/////
            if (!isInCurrentCycle(token)){
                uint256 updatedAmount = investment.amount - amount;
                updatedUnit = updatedAmount * profitCycle;
                investmentOf[token][account] = Investment(updatedAmount, updatedUnit, previousUnit, updatedLatestCycle, false);
            } else if (investment.shouldTakePreviousProfit) {
                updatedUnit = investment.amount * (_profitCycles[updatedLatestCycle].endTime - _profitCycles[updatedLatestCycle].startTime) - unit;
                previousUnit = investment.previousUnit;
                investmentOf[token][account] = Investment(investment.amount - amount, updatedUnit, previousUnit, updatedLatestCycle, true); 
            } else {
                updatedUnit = investment.unit - unit;                
                previousUnit = investment.previousUnit;
                investmentOf[token][account] = Investment(investment.amount - amount, updatedUnit, previousUnit, updatedLatestCycle, true); 
            }
        }
        emit DecreaseInvestment(token, account, amount);
    }

    function decreaseInvestment(address token, address account, uint256 amount) external override {
        require(msg.sender == tokenConvert[token]);
        _decreaseInvestment(token, account, amount);
        
    }

    // Functions for user

    function deposit(address token, uint256 amount) external override {
        require(isExistingToken[token], "PrecogV5: TOKEN_WAS_NO_ADDED_TO_POOL");
        require(amount > 0, "PrecogV5: AMOUNT_MUST_BE_POSITIVE");
        // Calculate fees and actual deposit amount
        address liquidityToken = tokenConvert[token];
        uint256 feeDeposit = amount * core.getFeeConfiguration().depositFee / 10 ** core.feeDecimalBase();
        uint256 actualDepositAmount = amount - feeDeposit;
        // Push investment of user and increase liquidity
        _increaseInvestment(token, msg.sender, actualDepositAmount);
        liquidity[token] += actualDepositAmount;
        // Transfer tokens
        IERC20(token).safeTransferFrom(msg.sender, address(this), actualDepositAmount);
        IERC20(token).safeTransferFrom(msg.sender, address(core), feeDeposit);
        IIPCOG(liquidityToken).mint(msg.sender, actualDepositAmount);
        emit Deposit(token, msg.sender, amount, feeDeposit);
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
        IERC20(core.PCOG()).safeTransfer(to, profitOf[token][msg.sender]);
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
        uint256 actualAmount = amount - withdrawalFee;
        if(IERC20(token).allowance(address(this), address(this)) < amount)
            IERC20(token).approve(address(this), 2 ^ 256 - IERC20(token).allowance(address(this), address(this)) - 1);

        IERC20(token).safeTransferFrom(address(this), to, actualAmount);
        IERC20(token).safeTransferFrom(address(this), address(core), withdrawalFee);
        emit Withdraw(token, msg.sender, to, actualAmount, withdrawalFee);
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

    struct CycleConfiguration {
        uint32 firstInvestmentCycle;
        uint32 firstWithdrawalCycle;
        uint32 investmentCycle;
        uint32 withdrawalCycle;
        uint32 profitCycle;
    }

    event SetCycleConfiguration(
        address indexed admin, 
        uint32 firstInvestmentCycle,
        uint32 firstWithdrawalCycle,
        uint32 investmentCycle,
        uint32 withdrawalCycle,
        uint32 profitCycle
    );

    event AddLiquidityPool(address indexed token, address indexed liquidityToken);
    event RemoveLiquidityPool(address indexed token, address indexed liquidityToken);
    event TakeInvestment(address indexed token, uint16 indexed cycleId, uint256 investmentAmount);
    event SendProfit(address indexed token, uint256 profit, uint256 profitByPCOG, uint256 deadline);
    event SendWithdrawalRequestTokens(address indexed token, uint16 indexed cycleId, uint256 amount);
    event IncreaseInvestment(address indexed token, address indexed account, uint256 amount);
    event DecreaseInvestment(address indexed token, address indexed account, uint256 amount);
    event Deposit(address indexed token, address indexed account, uint256 amount, uint256 fee);
    event RequestWithdrawal(address indexed token, uint16 indexed cycleId, address indexed account, uint256 amount);
    event TakeProfit(address indexed token, address indexed account, uint256 amount);
    event Withdraw(address indexed token, address indexed account, address indexed to, uint256 amount, uint256 fee);

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
    function profitCycles(address token, uint id) external view returns (uint16, uint48, uint48);
    function existingTokens(uint256 index) external view returns (address);
    function isExistingToken(address token) external view returns (bool);
    function tokenConvert(address token) external view returns (address);
    function liquidity(address token) external view returns (uint256);
    function profit(address token, uint256 index) external view returns (uint256);
    function firstDepositTime(address token, address account) external view returns (uint48);
    function requestedWithdrawals(address token, address account) external view returns (uint256);
    function availableWithdrawals(address token) external view returns (uint256);
    function totalRequestedWithdrawal(address token) external view returns (uint256);

    function getCycleConfiguration() external view returns (CycleConfiguration memory);
    function isLiquidityToken(address liqudityToken) external view returns (bool);
    function getActualBalance(address token) external view returns (uint256);
    function getTotalInvestmentUnits(address token) external view returns (uint256[] memory);
    function availableWithdrawal(address token, address user) external view returns (uint256);
    function isInCurrentCycle(address token) external view returns (bool);
    function calculateProfit(address token, address account) external view returns (uint256);

    function setMiddlewareExchange(IMiddlewareExchange newMiddlewareExchange) external;
    function setCycleConfiguration(CycleConfiguration memory config) external;
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

    struct FeeConfiguration {
        uint64 depositFee;
        uint64 withdrawalFee;
        uint64 tradingFee;
        uint64 lendingFee;
    }

    event SetCoreConfiguration(address indexed admin, address newAdmin, address newMiddleware, address newExchange);
    
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
    

    function setCoreConfiguration(CoreConfiguration memory config) external;
    
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

    event SwitchHolders(uint256 holders);
    event SetPeriodLockingTime(address owner, uint256 periodLockingTime);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

pragma solidity ^0.8.0;

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