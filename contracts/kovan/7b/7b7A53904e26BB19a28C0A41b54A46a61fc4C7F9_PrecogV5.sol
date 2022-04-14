pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IIPCOGFactory.sol";
import "../precog-core/interfaces/IPrecogCore.sol";
import "../ipcog/interfaces/IIPCOG.sol";
import "../middleware-exchange/interfaces/IMiddlewareExchange.sol";
import "../withdrawal-register/interfaces/IWithdrawalRegister.sol";
import "./libraries/PrecogV5Library.sol";

contract PrecogV5 is IPrecogV5 {
    using SafeERC20 for IERC20;

    // Modifiers

    modifier onlyAdmin() {
        require(msg.sender == core.getCoreConfiguration().admin, "PrecogV5: NOT_ADMIN_ADDRESS");
        _;
    }

    modifier onlyPrecogCore() {
        require(msg.sender == address(core));
        _;
    }

    modifier onlyMiddleware() {
        require(
            msg.sender == core.getCoreConfiguration().middleware,
            "PrecogV5: NOT_MIDDLEWARE_ADDRESS"
        );
        _;
    }

    // Attributes

    IPrecogCore core;
    IIPCOGFactory factory;
    IMiddlewareExchange middlewareExchange;
    IWithdrawalRegister withdrawalRegister;

    function getConfig() external view returns (address _core, address _factory, address _middlewareExchange, address _withdrawalRegister) {
        _core = address(core);
        _factory = address(factory);
        _middlewareExchange = address(middlewareExchange);
        _withdrawalRegister = address(withdrawalRegister);
    }

    mapping(address => mapping(address => Investment[])) investmentsOf; ///// investmentOf[token][account] = Investment()
    mapping(address => mapping(address => uint)) profitOf; /////
    mapping(address => mapping(address => uint)) claimedProfitOf;
    mapping(address => Cycle[]) tradingCycles; //
    mapping(address => uint16) public override currentProfitId;
    mapping(address => mapping(address => uint16)) lastProfitIdOf;
    mapping(address => mapping(address => uint16)) lastInvestmentIdOf;
    mapping(address => bool) public override isExistingToken;
    mapping(address => address) public override tokenConvert;
    mapping(address => uint) public override liquidity;
    mapping(address => uint) public newLiquidity;
    mapping(address => uint[]) profits;
    mapping(address => mapping(uint16 => uint)) totalUnitsTradingCycle;
    mapping(address => mapping(address => bool)) isFirstRequestWithdrawal; 
    mapping(address => bool) isNotFirstInvestmentCycle;
    mapping(address => bool) isRemoved;
    mapping(address => mapping(address => bool)) isNotFirstIncreaseInvestment;
    mapping(address => mapping(address => uint)) availableAmount;
    mapping(address => mapping(address => uint)) depositedTimestampOf;
    mapping(address => uint) timestampApplyNewTradingCycle;
    mapping(address => uint) timestampApplyNewFundingCycle;
    mapping(address => uint) timestampApplyNewDefundingCycle;
    mapping(address => uint48) lastFundingDuration;
    mapping(address => uint48) lastDefundingDuration;
    address[] existingTokens;

    // Fallback funciton and constructor

    function getInvestmentOfByIndex(address token, address account, uint index) external view override returns (Investment memory investmentOf) {
        investmentOf = investmentsOf[token][account][index];
    }

    function getTradingCycleByIndex(address token, uint index) external view override returns (Cycle memory tradingCycle) {
        tradingCycle = tradingCycles[token][index];
    }

    function getProfitByIndex(address token, uint index) external view override returns (uint amount) {
        return profits[token][index];
    }

    function getTotalUnitOfTradingCycle(address token, uint16 index) external view override returns (uint unit) {
        return totalUnitsTradingCycle[token][index];
    }

    fallback() external override {
        require(false, "PrecogV5: WRONG_FUNCTION_NAME");
    }

    constructor(
        IPrecogCore _core,
        IMiddlewareExchange _middlewareExchange,
        IIPCOGFactory _factory
    ) {
        core = _core;
        middlewareExchange = _middlewareExchange;
        factory = _factory;
    }

    // View functions

    function getAccountProfitInfo(address token, address account) 
        external 
        view 
        returns (
            uint16 _lastProfitIdOf, 
            uint16 _lastInvestmentIdOf, 
            uint _profitOf, 
            uint _claimedProfitOf
        ) 
    {
        _lastProfitIdOf = lastProfitIdOf[token][account];
        _lastInvestmentIdOf = lastInvestmentIdOf[token][account];
        _profitOf = profitOf[token][account];
        _claimedProfitOf = claimedProfitOf[token][account];
        return (_lastProfitIdOf, _lastInvestmentIdOf, _profitOf, _claimedProfitOf);
    }

    function isLiquidityToken(address liqudityToken) public view override returns (bool) {
        return (isExistingToken[tokenConvert[liqudityToken]]);
    }

    function getExistingTokens() external view override returns (address[] memory tokens) {
        tokens = existingTokens;
    }

    function getExistingTokenByIndex(uint index) external view override returns (address token) {
        token = existingTokens[index];
    }

    function getLastInvestmentOf(address token, address account) public view override returns (Investment memory lastInvestmentOf) {
        uint lastInvestmentIndex = investmentsOf[token][account].length - 1;
        lastInvestmentOf = investmentsOf[token][account][lastInvestmentIndex];
    }

    function getCurrentTradingCycle(address token)
        external
        view
        override
        returns (
            Cycle memory currentTradingCycle
        )
    {
        currentTradingCycle = _getTradingCycleByTimestamp(token, block.timestamp);
    }

    // Functions for all role

    function updateCurrentTradingCycle(address token) public override {
        require(isExistingToken[token], "PrecogV5: TOKEN_WAS_NOT_ADDED_TO_POOL");
        Cycle memory lastTradingCycle = tradingCycles[token][tradingCycles[token].length - 1];
        uint48 newCycleStartTime;
        uint48 newCycleEndTime;
        uint48 duration;
        uint48 tradingCycle = core.getCycleConfiguration().tradingCycle;
        uint _timestampApplyNewTradingCycle = timestampApplyNewTradingCycle[token];
        while (uint48(block.timestamp) >= lastTradingCycle.endTime) {
            newCycleStartTime = lastTradingCycle.endTime;
            if (newCycleStartTime < _timestampApplyNewTradingCycle) {
                duration = lastTradingCycle.endTime - lastTradingCycle.startTime;
            } else {
                duration = tradingCycle;
            }
            newCycleEndTime = newCycleStartTime + duration;
            lastTradingCycle = Cycle(lastTradingCycle.id + 1, newCycleStartTime, newCycleEndTime);
            tradingCycles[token].push(lastTradingCycle);
            if(totalUnitsTradingCycle[token][lastTradingCycle.id] == 0) {
                totalUnitsTradingCycle[token][lastTradingCycle.id] = (liquidity[token] * (duration));
            } else {
                totalUnitsTradingCycle[token][lastTradingCycle.id] += (liquidity[token] * (duration));
                liquidity[token] = newLiquidity[token];
            }
        }
    }

    function calculateProfit(address token, address account) 
        external 
        view 
        override
        returns (
            uint newProfitOf,
            uint16 newInvestmentIdOf,
            uint16 newProfitIdOf
        )
    {
        (newProfitOf, newInvestmentIdOf, newProfitIdOf) = _calculateProfit(token, account);
    }

    function _calculateProfit(address _token, address _account)
        internal
        view
        returns (
            uint _profitOf,
            uint16 _investmentIdOf,
            uint16 _profitIdOf
        )
    {
        require(isExistingToken[_token], "PrecogV5: INVALID_TOKEN");
        Investment[] memory _investments = investmentsOf[_token][_account];
        Cycle[] memory _tradingCycles = tradingCycles[_token];
        uint[] memory _profits = profits[_token];
        uint16 _updatedLatestCycle = currentProfitId[_token];
        uint16 _lastAvailableProfitId;
        _profitIdOf = lastProfitIdOf[_token][_account];
        _investmentIdOf = lastInvestmentIdOf[_token][_account];
        _profitOf = profitOf[_token][_account];
        if (_profitIdOf < _updatedLatestCycle) {
            for (_investmentIdOf; _investmentIdOf < _investments.length; _investmentIdOf++) {
                Investment memory _nextInvestment = Investment(0, 0, 0, 0);
                if (_profitIdOf == _updatedLatestCycle && _updatedLatestCycle == _investments[_investmentIdOf].idChanged) 
                    return (_profitOf, _investmentIdOf, _profitIdOf);
                (_nextInvestment, _lastAvailableProfitId) = PrecogV5Library._chooseLastAvailableTradingId(_investments, _investmentIdOf, _updatedLatestCycle);
                for (_profitIdOf; _profitIdOf < _lastAvailableProfitId; _profitIdOf++) {
                    _profitOf += PrecogV5Library._calculateProfitAtCycle(_tradingCycles[_profitIdOf], _investments[_investmentIdOf], totalUnitsTradingCycle[_token][_profitIdOf], _profits[_profitIdOf], _profitIdOf);
                }
                if((_profitIdOf == _updatedLatestCycle && _updatedLatestCycle != _nextInvestment.idChanged))
                    return (_profitOf, _investmentIdOf, _profitIdOf);
            }
        }
    }

    // Functions for admin

    function setMiddlewareExchange(address newMiddlewareExchange) external onlyAdmin {
        middlewareExchange = IMiddlewareExchange(newMiddlewareExchange);
    }

    function setWithdrawalRegister(address newWithdrawalRegister) external onlyAdmin {
        withdrawalRegister = IWithdrawalRegister(newWithdrawalRegister);
    }

    function addLiquidityPool(address token) external onlyAdmin {
        require(!isExistingToken[token], "PrecogV5: TOKEN_WAS_ADDED_TO_POOL");
        require(!isLiquidityToken(token) && token != core.PCOG(), "PrecogV5: INVALID_TOKEN_ADDRESS");
        // Deploy new IPCOG
        address liquidityToken = factory.create(IERC20Metadata(token).decimals());
        tokenConvert[token] = liquidityToken;
        tokenConvert[liquidityToken] = token;
        isExistingToken[token] = true;
        existingTokens.push(token);

        _updateAdjustment(token);

        if (!isNotFirstInvestmentCycle[token]) {
            tradingCycles[token].push(
                Cycle(
                    0,
                    uint48(block.timestamp),
                    uint48(block.timestamp) + core.getCycleConfiguration().firstTradingCycle
                )
            );
            profits[token].push(0);
            isNotFirstInvestmentCycle[token] = true;
        }

        Cycle memory lastCycle = tradingCycles[token][tradingCycles[token].length - 1];
        if (isRemoved[token] == true) {
            if (block.timestamp >= lastCycle.endTime) {
                Cycle memory newCycle = Cycle(
                    lastCycle.id + 1,
                    uint48(block.timestamp),
                    uint48(block.timestamp) + core.getCycleConfiguration().tradingCycle
                );
                tradingCycles[token].push(newCycle);
                profits[token].push(0);
            }
            isRemoved[token] = false;
        }
        emit AddLiquidityPool(token, liquidityToken);
    }

    function removeLiquidityPool(address token) external onlyAdmin {
        require(
            isExistingToken[token] || isLiquidityToken(token),
            "PrecogV5: TOKEN_WAS_NOT_ADDED_TO_POOL"
        );
        // Identity token and liquidity token
        if (!isExistingToken[token]) {
            token = tokenConvert[token];
        }
        updateCurrentTradingCycle(token);
        address liquidityToken = tokenConvert[token];
        require(IERC20(liquidityToken).totalSupply() == 0, "PrecogV5: TOKEN_IS_STILL_IN_INVESTMENT");
        address[] memory _existingTokens = existingTokens;
        for (uint i = 0; i < _existingTokens.length; i++) {
            if (_existingTokens[i] == token) {
                existingTokens[i] = _existingTokens[_existingTokens.length - 1];
                existingTokens.pop();
                break;
            }
        }
        tokenConvert[token] = tokenConvert[liquidityToken] = address(0);
        isExistingToken[token] = false;
        isRemoved[token] = true;
        emit RemoveLiquidityPool(token, liquidityToken);
    }

    // Functions for middleware

    function takeInvestment(address token) external override onlyMiddleware {
        require(isExistingToken[token], "PrecogV5: TOKEN_WAS_NOT_ADDED_TO_POOL");
        updateCurrentTradingCycle(token);
        uint actualBalance = IERC20(token).balanceOf(address(this));
        uint idealRemainBalance = liquidity[token] / 10;
        if (idealRemainBalance < actualBalance) {
            uint amountOut = actualBalance - idealRemainBalance;
            IERC20(token).safeTransfer(msg.sender, amountOut);
        } else if (idealRemainBalance > actualBalance) {
            uint amountIn = idealRemainBalance - actualBalance;
            IERC20(token).safeTransferFrom(msg.sender, address(this), amountIn);
        }

        emit TakeInvestment(token, currentProfitId[token], (liquidity[token] * 9) / 10);
    }

    function _buyPCOG(address _token, uint _profitAmount, uint16 _currentProfitId) internal returns (uint _amountBoughtPCOG) {
        if (_profitAmount > 0) {
            uint _feeTrading = (_profitAmount * core.getFeeConfiguration().tradingFee) / 10**core.feeDecimalBase();
            uint _actualProfitAmount = _profitAmount - _feeTrading;
            IERC20(_token).safeTransfer(address(core), _feeTrading);
            if (IERC20(_token).allowance(address(this), address(middlewareExchange)) < _profitAmount) {
                IERC20(_token).safeApprove(address(middlewareExchange), 2**255);
            }
            _amountBoughtPCOG = middlewareExchange.buyPCOG(_token, _actualProfitAmount);
            profits[_token][_currentProfitId] = _amountBoughtPCOG;
        }
    }

    function sendProfit(address token, uint profitAmount) external override onlyMiddleware {
        require(isExistingToken[token], "PrecogV5: TOKEN_WAS_NOT_ADDED_TO_POOL");
        if (totalUnitsTradingCycle[token][currentProfitId[token]] == 0) {
            profitAmount = 0;
        }
        updateCurrentTradingCycle(token);
        IERC20(token).safeTransferFrom(msg.sender, address(this), profitAmount);
        uint16 _currentProfitId = currentProfitId[token];
        uint lastIndexProfitCycle = tradingCycles[token].length - 1;
        require(
            _currentProfitId < tradingCycles[token][lastIndexProfitCycle].id,
            "NOT_END_LAST_TRADING_CYCLE"
        );
        uint amountBoughtPCOG = _buyPCOG(token, profitAmount, _currentProfitId);
        currentProfitId[token]++;
        profits[token].push(0);
        emit SendProfit(token, profitAmount, amountBoughtPCOG); 
    }

    // Function for IPCOG

    function _getTradingCycleByTimestamp(
        address _token,
        uint _timestamp
    )
        internal
        view
        returns (Cycle memory _currentTradingCycle)
    {
        Cycle[] memory _tradingCycles = tradingCycles[_token];
        Cycle memory _lastTradingCycle = _tradingCycles[_tradingCycles.length - 1];
        uint48 _newCycleStartTime;
        uint48 _newCycleEndTime;
        uint48 _duration;
        if (isRemoved[_token]) {
            return _lastTradingCycle;
        }
        uint _timestampApplyNewTradingCycle = timestampApplyNewTradingCycle[_token];
        while (uint48(_timestamp) >= _lastTradingCycle.endTime) {
            _newCycleStartTime = _lastTradingCycle.endTime;
            if (_lastTradingCycle.endTime < _timestampApplyNewTradingCycle) {
                _duration = _lastTradingCycle.endTime - _lastTradingCycle.startTime;
            } else {
                _duration = core.getCycleConfiguration().tradingCycle;
            }
            _newCycleEndTime = _newCycleStartTime + _duration;
            _lastTradingCycle = (IPrecogV5.Cycle(_lastTradingCycle.id + 1, _newCycleStartTime, _newCycleEndTime));
        }
        _currentTradingCycle = _lastTradingCycle;
        return _currentTradingCycle;
    }

    function _updateAdjustment(address _token) internal {
        Cycle memory _firstTradingCycle = tradingCycles[_token][0];
        uint48 _fundingDuration;
        uint48 _defundingDuration;
        uint48 _nextTimestamp;
        {
            uint48 _nextFundingTimestamp = PrecogV5Library._calculateNextFundingTimestamp(_firstTradingCycle, _fundingDuration);
            timestampApplyNewFundingCycle[_token] = _nextFundingTimestamp;
            lastFundingDuration[_token] = core.getCycleConfiguration().fundingCycle;
            _nextTimestamp = _nextFundingTimestamp;
        }
        {
            uint48 _nextDefundingTimestamp = PrecogV5Library._calculateNextDefundingTimestamp(_firstTradingCycle, _defundingDuration);
            timestampApplyNewDefundingCycle[_token] = _nextDefundingTimestamp;
            lastDefundingDuration[_token] = core.getCycleConfiguration().defundingCycle;
            if(_nextTimestamp < _nextDefundingTimestamp) {
                _nextTimestamp = _nextDefundingTimestamp;
            }
        }
        Cycle memory _futureTradingcycle = _getTradingCycleByTimestamp(_token, _nextTimestamp);
        timestampApplyNewTradingCycle[_token] = _futureTradingcycle.endTime;
    }

    function updateAdjustment(address token) external onlyPrecogCore {
        _updateAdjustment(token);
    }

    function _updateLastFundingDuration(address _token) internal {
        bool _isAppliedChangedCycle = PrecogV5Library._isAppliedChangedCycle(timestampApplyNewFundingCycle[_token]);
        if(_isAppliedChangedCycle) {
            lastFundingDuration[_token] = core.getCycleConfiguration().fundingCycle;
        }
    }

    function _updateLastDefundingDuration(address _token) internal {
        bool _isAppliedChangedCycle = PrecogV5Library._isAppliedChangedCycle(timestampApplyNewDefundingCycle[_token]);
        if(_isAppliedChangedCycle) {
            lastDefundingDuration[_token] = core.getCycleConfiguration().defundingCycle;
        }
    }

    function _increaseInvestment(
        address _token,
        address _account,
        uint _amount
    ) internal {
        require(isExistingToken[_token], "PrecogV5: INVALID_TOKEN");
        Investment[] memory _investmentsOf = investmentsOf[_token][_account];
        uint48 _nextFundingTimestamp;
        Cycle memory _futureTradingCycle;
        {
            Cycle memory _firstTradingCycle = tradingCycles[_token][0];
            _updateLastFundingDuration(_token);
            _nextFundingTimestamp = PrecogV5Library._calculateNextFundingTimestamp(_firstTradingCycle, lastFundingDuration[_token]);
            _futureTradingCycle = _getTradingCycleByTimestamp(_token, _nextFundingTimestamp);
        }
         
        require(_futureTradingCycle.endTime >= uint48(block.timestamp), "PrecogV5: INVALID_TIMESTAMP");
        uint _unit = _amount * (_futureTradingCycle.endTime - _nextFundingTimestamp);
        uint _updatedUnit;
        if (!isNotFirstIncreaseInvestment[_token][_account]) {
            lastProfitIdOf[_token][_account] = uint16(_futureTradingCycle.id);
            isNotFirstIncreaseInvestment[_token][_account] = true;
        }
        if (_investmentsOf.length > 0) {
            Investment memory _lastInvestmentOf = _investmentsOf[_investmentsOf.length - 1];
            Investment memory _newInvestmentOf = Investment(_lastInvestmentOf.amount + _amount, _updatedUnit, _nextFundingTimestamp, _futureTradingCycle.id);
            if (_lastInvestmentOf.idChanged < _futureTradingCycle.id) {
                _newInvestmentOf.unit = _lastInvestmentOf.amount * (_futureTradingCycle.endTime - _futureTradingCycle.startTime) + _unit;
                investmentsOf[_token][_account].push(_newInvestmentOf);
            } else {
                _newInvestmentOf.unit = _lastInvestmentOf.unit + _unit;
                investmentsOf[_token][_account][_investmentsOf.length - 1] = _newInvestmentOf;
            }
        } else {
            Investment memory _newInvestmentOf = Investment(_amount, _unit, _nextFundingTimestamp, _futureTradingCycle.id);
            investmentsOf[_token][_account].push(_newInvestmentOf);
        }
        totalUnitsTradingCycle[_token][_futureTradingCycle.id] += _unit;
        emit IncreaseInvestment(_token, _account, _amount);
    }

    function increaseInvestment(
        address token,
        address account,
        uint amount
    ) external override {
        require(msg.sender == tokenConvert[token]);
        _increaseInvestment(token, account, amount);
    }

    function _decreaseInvestment(
        address _token,
        address _account,
        uint _amount
    ) internal returns (uint remainingAmount) {
        require(isExistingToken[_token], "PrecogV5: INVALID_TOKEN");
        require(!isBeforeFundingTime(_token, _account), "PrecogV5: CAN_NOT_DECREASE_BEFORE_INVESTMENT_TIME");
        
        Investment[] memory _investmentsOf = investmentsOf[_token][_account];
        uint48 _nextDefundingTimestamp;
        Cycle memory _futureTradingCycle;
        {
            Cycle memory _firstTradingCycle = tradingCycles[_token][0];
            _updateLastDefundingDuration(_token);
            _nextDefundingTimestamp = PrecogV5Library._calculateNextDefundingTimestamp(_firstTradingCycle, lastFundingDuration[_token]);
            _futureTradingCycle = _getTradingCycleByTimestamp(_token, _nextDefundingTimestamp);
        }

        Investment memory _lastInvestmentOf = _investmentsOf[_investmentsOf.length - 1];
        Investment memory _newInvestmentOf = Investment(_lastInvestmentOf.amount - _amount, _lastInvestmentOf.unit, _lastInvestmentOf.timestamp, _futureTradingCycle.id);
        remainingAmount = _newInvestmentOf.amount;
        uint _unit = _amount * (_futureTradingCycle.endTime - _nextDefundingTimestamp);
        if (_lastInvestmentOf.idChanged < _futureTradingCycle.id) {
            _newInvestmentOf.unit = _lastInvestmentOf.amount * (_futureTradingCycle.endTime - _futureTradingCycle.startTime) - _unit;
            _newInvestmentOf.timestamp = uint48(block.timestamp);
            investmentsOf[_token][_account].push(_newInvestmentOf);
        } else {
            _newInvestmentOf.unit = _lastInvestmentOf.unit - _unit;
            investmentsOf[_token][_account][_investmentsOf.length - 1] = _newInvestmentOf;
        }
    
        emit DecreaseInvestment(_token, _account, _amount);
    }

    function decreaseInvestment(
        address token,
        address account,
        uint amount
    ) external override {
        require(msg.sender == tokenConvert[token]);
        _decreaseInvestment(token, account, amount);
    }

    // Functions for user

    function updateProfit(address token, address account) public override {
        (uint newProfitOf, uint16 newInvestmentId, uint16 newProfitIdOf) = _calculateProfit(token,account);
        profitOf[token][account] = newProfitOf;
        lastInvestmentIdOf[token][account] = newInvestmentId;
        lastProfitIdOf[token][account] = newProfitIdOf;
    }

    function _updateDepsoitInfo(address _token, address _account, uint _amount) internal {
        Investment memory _lastInvestmentOf = getLastInvestmentOf(_token, _account);
        if(block.timestamp >= depositedTimestampOf[_token][_account]) {
            availableAmount[_token][msg.sender] = _amount;
            depositedTimestampOf[_token][_account] = _lastInvestmentOf.timestamp;
        } else {
            availableAmount[_token][msg.sender] += _amount;
        }
    }

    function availableDepositedAmount(address token, address account) public view returns (uint amount) {
        return depositedTimestampOf[token][account] > block.timestamp ? availableAmount[token][account] : 0;
    }

    function deposit(address token, uint amount) external override {
        require(isExistingToken[token], "PrecogV5: TOKEN_WAS_NO_ADDED_TO_POOL");
        require(amount > 0, "PrecogV5: AMOUNT_MUST_BE_POSITIVE");
        require(amount >= core.minFunding(token), "PrecogV5: AMOUNT_MUST_GREATER_THAN_MIN_VALUE");
        updateCurrentTradingCycle(token);
        // Calculate fees and actual deposit amount
        address liquidityToken = tokenConvert[token];
        uint feeDeposit = (amount * core.getFeeConfiguration().depositFee) / 10**core.feeDecimalBase();
        uint actualDepositAmount = amount - feeDeposit;
        // Push investment of user and increase liquidity
        _increaseInvestment(token, msg.sender, actualDepositAmount);
        newLiquidity[token] += actualDepositAmount;
        updateProfit(token, msg.sender);
        // Transfer tokens
        IERC20(token).safeTransferFrom(msg.sender, address(this), actualDepositAmount);
        IERC20(token).safeTransferFrom(msg.sender, address(core), feeDeposit);
        IIPCOG(liquidityToken).mint(msg.sender, actualDepositAmount);
        _updateDepsoitInfo(token, msg.sender, actualDepositAmount);
        emit Deposit(token, msg.sender, amount, feeDeposit);
    }

    function _registerWithdrawal(address _token, address _account, uint _amount) internal {
        Cycle memory _firstTradingCycle = tradingCycles[_token][0];
        uint48 _locktime;
        uint48 nextDefundingTimestamp;
        if (isFirstRequestWithdrawal[_token][_account] == false) {
            nextDefundingTimestamp = PrecogV5Library._calculateNextDefundingTimestamp(_firstTradingCycle, core.getCycleConfiguration().firstDefundingCycle);
            isFirstRequestWithdrawal[_token][_account] = true;
        } else {
            nextDefundingTimestamp = PrecogV5Library._calculateNextDefundingTimestamp(_firstTradingCycle, lastDefundingDuration[_token]);
            
        }
        _locktime = nextDefundingTimestamp - uint48(block.timestamp);
        withdrawalRegister.registerWithdrawal(_token, _account, _amount, _locktime);
    }

    function requestWithdrawal(address token, uint amount) external override {
        require(isExistingToken[token], "PrecogV5: INVALID_TOKEN_ADDRESS");
        require(isBeforeFundingTime(token, msg.sender), "PrecogV5: MUST_REQUEST_WITHDRAWAL_AFTER_INVESTMENT_TIME");
        require(amount > core.minDefunding(token), "PrecogV5: MUST_REQUEST_GREATER_THAN_MIN_DEFUNDING_AMOUNT");
        updateCurrentTradingCycle(token);
        uint remainingAmount = _decreaseInvestment(token, msg.sender, amount);
        require(remainingAmount == 0 || remainingAmount >= core.minFunding(token), "PrecogV5: MUST_HAVE_ENOUGH_INVESTMENT_OR_OUT_OF_REMAINING_TOKEN");
        liquidity[token] -= amount;
        newLiquidity[token] -= amount;
        _registerWithdrawal(token, msg.sender, amount);
        updateProfit(token, msg.sender);
        emit RequestWithdrawal(token, msg.sender, amount);
    }

    function takeProfit(address to, address token) external override {
        updateCurrentTradingCycle(token);
        updateProfit(token, msg.sender);
        uint profitOfAccount = profitOf[token][msg.sender];
        require(profitOfAccount > 0, "PrecogV5: ACCOUNT_HAS_NO_PROFIT");
        IERC20(core.PCOG()).safeTransfer(to, profitOfAccount);
        claimedProfitOf[token][to] += profitOfAccount;
        emit TakeProfit(token, msg.sender, profitOfAccount);
        profitOf[token][msg.sender] = 0;
    }

    function _decreaseInvestmentWhenWithdraw(address _token, address _account, uint _amount) internal returns (uint _remainingAmount) {
        Investment[] memory _investmentsOf = investmentsOf[_token][_account];
        Investment memory _lastInvestmentOf = _investmentsOf[_investmentsOf.length - 1];
        Cycle memory _futureTradingCycle = _getTradingCycleByTimestamp(_token, _lastInvestmentOf.timestamp);
        require(_futureTradingCycle.endTime >= uint48(block.timestamp), "PrecogV5: INVALID_TIMESTAMP");
        _lastInvestmentOf.amount -= _amount;
        _remainingAmount = _lastInvestmentOf.amount;
        uint256 _unit = _amount * (_futureTradingCycle.endTime - _futureTradingCycle.startTime);
        _lastInvestmentOf.unit -= _unit; 
        investmentsOf[_token][_account][_investmentsOf.length - 1] = _lastInvestmentOf;
        totalUnitsTradingCycle[_token][_futureTradingCycle.id] -= _unit;
        availableAmount[_token][msg.sender] -= _amount;
    }

    function _withdrawBeforeFundingTime(address _account, address _to, address _token, uint _amount, uint _fee) internal {
        require(_amount + _fee <= availableDepositedAmount(_token, _account), "PrecogV5: INVESTMENT_HAS_ALREADY_STARTED");
        require(_amount >= core.minDefunding(_token));
        uint remainingAmount = _decreaseInvestmentWhenWithdraw(_token, _account, _amount);
        require(remainingAmount == 0 || remainingAmount >= core.minFunding(_token), "PrecogV5: MUST_HAVE_ENOUGH_INVESTMENT_OR_OUT_OF_REMAINING_TOKEN");
        IERC20(_token).safeTransfer(_to, _amount - _fee);
        IERC20(_token).safeTransfer(address(core), _fee);
        liquidity[_token] -= _amount;
        newLiquidity[_token] -= _amount;
    }

    function isBeforeFundingTime(address token, address account) public view returns (bool) {
        bool isBeforeInvestmentCycle = availableDepositedAmount(token, account) > 0 ? true : false;
        return isBeforeInvestmentCycle;
    }

    function withdraw(
        address to,
        address token,
        uint amount,
        bool isWithdrawBeforeFundingTime
    ) external override {
        require(isExistingToken[token], "PrecogV5: NOT_A_LIQUIDITY_TOKEN");
        require(amount > 0, "PrecogV5: INVALID_AMOUNT_LIQUIDITY");
        updateCurrentTradingCycle(token);
        uint withdrawalFee = (amount * core.getFeeConfiguration().withdrawalFee) / 10**core.feeDecimalBase();
        IIPCOG(tokenConvert[token]).burnFrom(msg.sender, amount);
        if(isWithdrawBeforeFundingTime)
            _withdrawBeforeFundingTime(msg.sender, to, token, amount, withdrawalFee);
        else
            withdrawalRegister.claimWithdrawal(token, msg.sender, to, amount, withdrawalFee);
        emit Withdraw(token, msg.sender, to, amount, withdrawalFee);
    }

}

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

    event ClaimWithdrawal(
        address token,
        address account,
        uint256 amount
    );

    function precog() external view returns (address);
    function precogCore() external view returns (address);
    function register(address token, address account) external view returns (uint256 amount, uint256 deadline);

    function isInDeadline(address token, address account) external view returns (bool);
    function registerWithdrawal(address token, address account, uint256 amount, uint256 deadline) external;
    function claimWithdrawal(address token, address account, address to, uint256 amount, uint256 fee) external;
}

pragma solidity ^0.8.0; 

import "../../precog-core/interfaces/IPrecogCore.sol";
import "../interfaces/IPrecogV5.sol";

library PrecogV5Library {

    function _isAppliedChangedCycle(uint _nextCycleApplyChangingTimestamp) internal view returns (bool) {
        return block.timestamp > _nextCycleApplyChangingTimestamp;
    }

    function _chooseLastAvailableTradingId(
        IPrecogV5.Investment[] memory _investments,
        uint16 _investmentId, 
        uint16 _value
    ) internal pure returns (
        IPrecogV5.Investment memory _nextInvestment,
        uint16 _lastAvailableProfitId) 
    {
        _nextInvestment = IPrecogV5.Investment(0, 0, 0, 0);
        _lastAvailableProfitId = _value;
        if (_investmentId < _investments.length - 1) {
            _nextInvestment = _investments[_investmentId + 1];
            if (_nextInvestment.idChanged <= _value) {
                _lastAvailableProfitId = _nextInvestment.idChanged;
            }
        }
    }

    function _calculateProfitAtCycle(
        IPrecogV5.Cycle memory _profitCycle,
        IPrecogV5.Investment memory _investment,
        uint _totalInvestmentUnit, 
        uint _lastProfit, 
        uint16 _lastProfitIdOf
    ) 
        internal 
        pure
        returns (uint _profitAtCycle) 
    {
        if (_totalInvestmentUnit > 0) {
            if (_lastProfitIdOf == _investment.idChanged) {
                _profitAtCycle = (_lastProfit * _investment.unit) / _totalInvestmentUnit;
            } else {
                IPrecogV5.Cycle memory lastCycle = _profitCycle;
                _profitAtCycle = (_lastProfit * _investment.amount * (lastCycle.endTime - lastCycle.startTime)) / _totalInvestmentUnit;
            }
        }    
    }

    function _calculateNextFundingTimestamp(IPrecogV5.Cycle memory _firstTradingCycle, uint48 _fundingDuration) internal view returns (uint48 _nextFundingTimestamp) {
        return ((uint48(block.timestamp) - _firstTradingCycle.startTime) / _fundingDuration + 1) * _fundingDuration + _firstTradingCycle.startTime;
    }

    function _calculateNextDefundingTimestamp(IPrecogV5.Cycle memory _firstTradingCycle, uint48 _defundingDuration) internal view returns (uint48 _nextDefundingTimestamp) {
        return ((uint48(block.timestamp) - _firstTradingCycle.startTime) / _defundingDuration + 1) * _defundingDuration + _firstTradingCycle.startTime;
    }

}

interface IPrecogV5 {

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
    
    // Events

    event AddLiquidityPool(address indexed token, address indexed liquidityToken);
    event RemoveLiquidityPool(address indexed token, address indexed liquidityToken);
    event TakeInvestment(address indexed token, uint16 indexed cycleId, uint investmentAmount);
    event SendProfit(address indexed token, uint profit, uint profitByPCOG);
    event IncreaseInvestment(address indexed token, address indexed account, uint amount);
    event DecreaseInvestment(address indexed token, address indexed account, uint amount);
    event Deposit(address indexed token, address indexed account, uint amount, uint fee);
    event RequestWithdrawal(address indexed token, address indexed account, uint amount);
    event TakeProfit(address indexed token, address indexed account, uint amount);
    event Withdraw(address indexed token, address indexed account, address indexed to, uint amount, uint fee);

    fallback() external;

    // View functions

    function getInvestmentOfByIndex(address token, address account, uint index) external view returns (Investment memory investmentOf);
    function getTradingCycleByIndex(address token, uint index) external view returns (Cycle memory tradingCycle);
    function currentProfitId(address token) external view returns (uint16);
    function getLastInvestmentOf(address token, address account) external view returns (Investment memory lastInvestmentOf);
    function isExistingToken(address token) external view returns (bool);
    function tokenConvert(address token) external view returns (address);
    function liquidity(address token) external view returns (uint);
    function getProfitByIndex(address token, uint index) external view returns (uint);
    function isLiquidityToken(address liqudityToken) external view returns (bool);
    function getExistingTokens() external view returns (address[] memory);
    function getExistingTokenByIndex(uint index) external view returns (address);
    function calculateProfit(address token, address account) external view returns (uint, uint16, uint16);
    function getCurrentTradingCycle(address token) external view returns (Cycle memory currentProfitCycle);
    function getTotalUnitOfTradingCycle(address token, uint16 index) external view returns (uint unit);

    // Functions for all role
    function updateCurrentTradingCycle(address token) external;

    // Function for precog core
    function updateAdjustment(address token) external;

    // Functions for middleware

    function takeInvestment(address token) external;
    function sendProfit(address token, uint profitAmount) external;

    // Functions for IPCOG
    function increaseInvestment(address token, address account, uint amount) external;
    function decreaseInvestment(address token, address account, uint amount) external;

    // Functions for user 
    function updateProfit(address token, address account) external;
    function deposit(address token, uint amount) external;
    function requestWithdrawal(address liquidityToken, uint amount) external;
    function takeProfit(address to, address token) external;
    function withdraw(address to, address token, uint amount, bool isWithdrawBeforeFundingTime) external;
    
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

    struct CycleConfiguration {
        uint32 firstTradingCycle;
        uint32 firstDefundingCycle;
        uint32 fundingCycle;
        uint32 defundingCycle;
        uint32 tradingCycle;
    }

    event SetCycleConfiguration(
        address indexed admin, 
        uint32 firstTradingCycle,
        uint32 firstDefundingCycle,
        uint32 fundingCycle,
        uint32 defundingCycle,
        uint32 tradingCycle
    );

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
    function PCOG() external view returns (address);
    function feeDecimalBase() external view returns (uint8);
    function lastChangeCyclesTimestamp() external view returns (uint48);
    function getCoreConfiguration() external view returns (CoreConfiguration memory);
    function getFeeConfiguration() external view returns (FeeConfiguration memory);
    function getCycleConfiguration() external view returns (CycleConfiguration memory);
    function minFunding(address token) external view returns (uint256);
    function minDefunding(address token) external view returns (uint256);
}

pragma solidity ^0.8.0;

interface IMiddlewareExchange {
  function buyPCOG(address token, uint256 amount) external returns (uint256);
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

pragma solidity ^0.8.0;

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