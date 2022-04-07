pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IIPCOGFactory.sol";
import "../precog-core/interfaces/IPrecogCore.sol";
import "../ipcog/interfaces/IIPCOG.sol";
import "../middleware-exchange/interfaces/IMiddlewareExchange.sol";
import "../withdrawal-investment/interfaces/IWithdrawalRegister.sol";
import "./libraries/PrecogV5Library.sol";
//import "./interfaces/IPrecogV5.sol";

contract PrecogV5 is IPrecogV5 {
    using SafeERC20 for IERC20;

    // Modifiers

    modifier onlyAdmin() {
        require(msg.sender == core.getCoreConfiguration().admin, "PrecogV5: NOT_ADMIN_ADDRESS");
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

    IPrecogCore public core;
    IIPCOGFactory public factory;
    IMiddlewareExchange public middlewareExchange;
    IWithdrawalRegister public withdrawalRegister;

    mapping(address => mapping(address => Investment[])) public override investmentsOf; ///// investmentOf[token][account] = Investment()
    mapping(address => mapping(address => uint)) public override profitOf; /////
    mapping(address => mapping(address => uint)) public override claimedProfitOf;
    mapping(address => Cycle[]) public override profitCycles; //
    mapping(address => uint16) public override currentInvestmentCycleId;
    mapping(address => uint16) public override currentProfitCycleId;
    mapping(address => mapping(address => uint16)) public override lastProfitCycleIdOf;
    mapping(address => mapping(address => uint16)) public override lastInvestmentIdOf;
    mapping(address => bool) public override isExistingToken;
    mapping(address => address) public override tokenConvert;
    mapping(address => uint) public override liquidity;
    mapping(address => uint) public newLiquidity;
    mapping(address => uint[]) public override profits;
    mapping(address => mapping(uint16 => uint)) public totalInvestmentUnits; /////
    mapping(address => mapping(address => mapping(uint => bool))) isIncreasedInvesmentInCycle; ///// isDepositedInCycle[token][account][0] = false
    mapping(address => mapping(address => bool)) isFirstRequestWithdrawal; ///// isFirstRequestWithdrawal[token][account] = false
    mapping(address => bool) isNotFirstInvestmentCycle;
    mapping(address => bool) isRemoved; // isRemoved[token] = false
    mapping(address => mapping(address => bool)) isNotFirstIncreaseInvestment;
    mapping(address => mapping(address => uint)) availableAmount;
    mapping(address => mapping(address => uint)) depositedTimestampOf;
    mapping(address => uint) currentDepositedTimestamp;
    mapping(address => uint) futureProfitCycleId;
    address[] existingTokens;

    // Fallback funciton and constructor

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

    function isLiquidityToken(address liqudityToken) public view override returns (bool) {
        return (isExistingToken[tokenConvert[liqudityToken]]);
    }

    function getExistingTokens() external view returns (address[] memory) {
        return existingTokens;
    }

    function getExistingTokenByIndex(uint index) external view returns (address) {
        return existingTokens[index];
    }

    function getCurrentProfitCycle(address token)
        external
        view
        returns (
            uint currentCycleId,
            uint currentCycleStartTime,
            uint currentCycleEndTime
        )
    {
        Cycle memory lastCycle = profitCycles[token][profitCycles[token].length - 1];
        uint _currentDepositedTimestamp = currentDepositedTimestamp[token];
        uint48 profitCycle = core.getCycleConfiguration().profitCycle;
        (currentCycleId, currentCycleStartTime, currentCycleEndTime) = 
        PrecogV5Library._getCurrentProfitCycleByTimestamp(lastCycle, block.timestamp, _currentDepositedTimestamp, profitCycle, isRemoved[token]);
    }

    // function _getCurrentProfitCycleByTimestamp(address _token, uint _timestamp)
    //     internal
    //     view
    //     returns (
    //         uint _currentCycleId,
    //         uint _currentCycleStartTime,
    //         uint _currentCycleEndTime
    //     )
    // {
    //     require(_timestamp >= block.timestamp, "PrecogV5: TIMESTAMP_MUST_NOT_LESS_THAN_NOW");
    //     Cycle memory _lastCycle = profitCycles[_token][profitCycles[_token].length - 1];
    //     uint48 _newCycleStartTime;
    //     uint48 _newCycleEndTime;
    //     uint48 _duration;
    //     uint48 _profitCycle = core.getCycleConfiguration().profitCycle;
    //     uint _currentDepositedTimestamp = currentDepositedTimestamp[_token];
    //     if (isRemoved[_token]) {
    //         return (_lastCycle.id, _lastCycle.startTime, _lastCycle.endTime);
    //     }
    //     while (uint48(_timestamp) >= _lastCycle.endTime) {
    //         _newCycleStartTime = _lastCycle.endTime;
    //         if (_lastCycle.endTime < _currentDepositedTimestamp) {
    //             _duration = _lastCycle.endTime - _lastCycle.startTime;
    //         } else {
    //             _duration = _profitCycle;
    //         }
    //         _newCycleEndTime = _newCycleStartTime + _duration;
    //         _lastCycle = (Cycle(_lastCycle.id + 1, _newCycleStartTime, _newCycleEndTime));
    //     }
    //     return (_lastCycle.id, _lastCycle.startTime, _lastCycle.endTime);
    // }

    // Functions for all role

    function updateProfitCycleToCurrentCycle(address token) public override {
        require(isExistingToken[token], "PrecogV5: TOKEN_WAS_NOT_ADDED_TO_POOL");
        Cycle memory lastCycle = profitCycles[token][profitCycles[token].length - 1];
        uint48 newCycleStartTime;
        uint48 newCycleEndTime;
        uint48 duration;
        uint48 profitCycle = core.getCycleConfiguration().profitCycle;
        uint _currentDepositedTimestamp = currentDepositedTimestamp[token];
        while (uint48(block.timestamp) >= lastCycle.endTime) {
            newCycleStartTime = lastCycle.endTime;
            if (newCycleStartTime < _currentDepositedTimestamp) {
                duration = lastCycle.endTime - lastCycle.startTime;
            } else {
                duration = profitCycle;
            }
            newCycleEndTime = newCycleStartTime + duration;
            lastCycle = Cycle(lastCycle.id + 1, newCycleStartTime, newCycleEndTime);
            profitCycles[token].push(lastCycle);
            if(totalInvestmentUnits[token][lastCycle.id] == 0) {
                totalInvestmentUnits[token][lastCycle.id] = (liquidity[token] * (duration));
            } else {
                totalInvestmentUnits[token][lastCycle.id] += (liquidity[token] * (duration));
                liquidity[token] = newLiquidity[token];
            }
        }
    }

    function calculateProfit(address token, address account) 
        external 
        view 
        returns (
            uint profitOfAccount,
            uint16 investmentId,
            uint16 lastProfitIdOf
        )
    {
        (profitOfAccount, investmentId, lastProfitIdOf) = _calculateProfit(token, account);
    }

    function _calculateProfit(address _token, address _account)
        internal
        view
        returns (
            uint _profitOfAccount,
            uint16 _investmentId,
            uint16 _lastProfitIdOf
        )
    {
        require(isExistingToken[_token], "PrecogV5: INVALID_TOKEN");
        Investment[] memory _investments = investmentsOf[_token][_account];
        Cycle[] memory _profitCycles = profitCycles[_token];
        uint[] memory _profits = profits[_token];
        uint16 _updatedLatestCycle = currentProfitCycleId[_token];
        uint16 _lastAvailableProfitId;
        _lastProfitIdOf = lastProfitCycleIdOf[_token][_account];
        _investmentId = lastInvestmentIdOf[_token][_account];
        _profitOfAccount = profitOf[_token][_account];
        if (_lastProfitIdOf < _updatedLatestCycle) {
            for (_investmentId; _investmentId < _investments.length; _investmentId++) {
                Investment memory _nextInvestment = Investment(0, 0, 0, 0);
                if (_investmentId < _investments.length - 1 && _investments[_investmentId].idChanged == _investments[_investmentId + 1].idChanged) 
                    continue;
                if (_lastProfitIdOf == _updatedLatestCycle && _updatedLatestCycle == _investments[_investmentId].idChanged) 
                    return (_profitOfAccount, _investmentId, _lastProfitIdOf);
                (_nextInvestment, _lastAvailableProfitId) = PrecogV5Library._chooseLastAvailableProfitId(_investments, _investmentId, _updatedLatestCycle);
                for (_lastProfitIdOf; _lastProfitIdOf < _lastAvailableProfitId; _lastProfitIdOf++) {
                    _profitOfAccount += PrecogV5Library._calculateProfitAtCycle(_profitCycles, _investments[_investmentId], totalInvestmentUnits[_token][_lastProfitIdOf], _profits[_lastProfitIdOf], _lastProfitIdOf);
                }
                if((_lastProfitIdOf == _updatedLatestCycle && _updatedLatestCycle != _nextInvestment.idChanged))
                    return (_profitOfAccount, _investmentId, _lastProfitIdOf);
            }
        }
    }

    // Functions for admin

    function setMiddlewareExchange(address newMiddlewareExchange) external override onlyAdmin {
        middlewareExchange = IMiddlewareExchange(newMiddlewareExchange);
    }

    function setWithdrawalRegister(address newWithdrawalRegister) external override onlyAdmin {
        withdrawalRegister = IWithdrawalRegister(newWithdrawalRegister);
    }

    function addLiquidityPool(address token) external override onlyAdmin {
        require(!isExistingToken[token], "PrecogV5: TOKEN_WAS_ADDED_TO_POOL");
        require(!isLiquidityToken(token) && token != core.PCOG(), "PrecogV5: INVALID_TOKEN_ADDRESS");
        // Deploy new IPCOG
        address liquidityToken = factory.create(IERC20Metadata(token).decimals());
        tokenConvert[token] = liquidityToken;
        tokenConvert[liquidityToken] = token;
        isExistingToken[token] = true;
        existingTokens.push(token);

        if (!isNotFirstInvestmentCycle[token]) {
            profitCycles[token].push(
                Cycle(
                    0,
                    uint48(block.timestamp),
                    uint48(block.timestamp) + core.getCycleConfiguration().firstInvestmentCycle
                )
            );
            profits[token].push(0);
            isNotFirstInvestmentCycle[token] = true;
        }

        if (isRemoved[token] == true) {
            Cycle memory lastCycle = profitCycles[token][profitCycles[token].length - 1];
            if (block.timestamp >= lastCycle.endTime) {
                Cycle memory newCycle = Cycle(
                    lastCycle.id + 1,
                    uint48(block.timestamp),
                    uint48(block.timestamp) + core.getCycleConfiguration().profitCycle
                );
                profitCycles[token].push(newCycle);
                profits[token].push(0);
            }
            isRemoved[token] = false;
        }
        emit AddLiquidityPool(token, liquidityToken);
    }

    function removeLiquidityPool(address token) external override onlyAdmin {
        require(
            isExistingToken[token] || isLiquidityToken(token),
            "PrecogV5: TOKEN_WAS_NOT_ADDED_TO_POOL"
        );
        // Identity token and liquidity token
        if (!isExistingToken[token]) {
            token = tokenConvert[token];
        }
        updateProfitCycleToCurrentCycle(token);
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
        updateProfitCycleToCurrentCycle(token);
        currentInvestmentCycleId[token]++;
        uint actualBalance = IERC20(token).balanceOf(address(this));
        uint idealRemainBalance = liquidity[token] / 10;
        if (idealRemainBalance < actualBalance) {
            uint amountOut = actualBalance - idealRemainBalance;
            IERC20(token).safeTransfer(msg.sender, amountOut);
        } else if (idealRemainBalance > actualBalance) {
            uint amountIn = idealRemainBalance - actualBalance;
            IERC20(token).safeTransferFrom(msg.sender, address(this), amountIn);
        }

        emit TakeInvestment(token, currentProfitCycleId[token], (liquidity[token] * 9) / 10);
    }

    function _buyPCOG(address _token, uint _profitAmount, uint16 _currentProfitCycleId) internal returns (uint _amountBoughtPCOG) {
        if (_profitAmount > 0) {
            uint _feeTrading = (_profitAmount * core.getFeeConfiguration().tradingFee) / 10**core.feeDecimalBase();
            uint _actualProfitAmount = _profitAmount - _feeTrading;
            IERC20(_token).safeTransfer(address(core), _feeTrading);
            if (IERC20(_token).allowance(address(this), address(middlewareExchange)) < _profitAmount) {
                IERC20(_token).safeApprove(address(middlewareExchange), 2**255);
            }
            _amountBoughtPCOG = middlewareExchange.buyPCOG(_token, _actualProfitAmount);
            profits[_token][_currentProfitCycleId] = _amountBoughtPCOG;
        }
    }

    function sendProfit(address token, uint profitAmount) external override onlyMiddleware {
        require(isExistingToken[token], "PrecogV5: TOKEN_WAS_NOT_ADDED_TO_POOL");
        if (totalInvestmentUnits[token][currentProfitCycleId[token]] == 0) {
            profitAmount = 0;
        }
        updateProfitCycleToCurrentCycle(token);
        IERC20(token).safeTransferFrom(msg.sender, address(this), profitAmount);
        uint16 _currentProfitCycleId = currentProfitCycleId[token];
        uint lastIndexProfitCycle = profitCycles[token].length - 1;
        require(
            _currentProfitCycleId < profitCycles[token][lastIndexProfitCycle].id,
            "NOT_END_LAST_PROFIT_CYCLE"
        );
        uint amountBoughtPCOG = _buyPCOG(token, profitAmount, _currentProfitCycleId);
        currentProfitCycleId[token]++;
        profits[token].push(0);
        emit SendProfit(token, profitAmount, amountBoughtPCOG); 
    }

    // Function for IPCOG

    function _getFutureProfitCycle(
        address _token,
        uint _futureTimestamp,
        uint48 _profitCycleDuration
        ) 
            internal 
            view 
            returns (Cycle memory _futureProfitCycle) 
    {
        Cycle memory _lastProfitCycle = profitCycles[_token][profitCycles[_token].length - 1];
        (uint _futureProfitCycleId, uint _futureStartTime, uint _futureEndTime) = 
        PrecogV5Library._getCurrentProfitCycleByTimestamp(_lastProfitCycle, _futureTimestamp, currentDepositedTimestamp[_token], _profitCycleDuration, isRemoved[_token]);
        _futureProfitCycle = IPrecogV5.Cycle(uint16(_futureProfitCycleId), uint48(_futureStartTime), uint48(_futureEndTime));
    }

    function _increaseInvestment(
        address _token,
        address _account,
        uint _amount
    ) internal {
        require(isExistingToken[_token], "PrecogV5: INVALID_TOKEN");
        Investment[] memory _investmentsOf = investmentsOf[_token][_account];
        Cycle[] memory _profitCycles = profitCycles[_token];
        Cycle memory _lastProfitCycle = _profitCycles[_profitCycles.length - 1];
        uint48 _duration;
        uint48 _nextInvestmentTimestamp;
        Cycle memory _futureProfitCycle;
        {
            _duration = PrecogV5Library._defineDurationInvestmentCycle(_lastProfitCycle, currentDepositedTimestamp[_token], core.getCycleConfiguration().investmentCycle);
            _nextInvestmentTimestamp = PrecogV5Library._calculateNextInvestmentTimestamp(_profitCycles[0], _duration);
            _futureProfitCycle = _getFutureProfitCycle(_token, _nextInvestmentTimestamp, _duration);
        }
         
        require(_futureProfitCycle.endTime >= uint48(block.timestamp), "PrecogV5: INVALID_TIMESTAMP");
        uint _unit = _amount * (_futureProfitCycle.endTime - _nextInvestmentTimestamp);
        uint _updatedUnit;
        if (!isNotFirstIncreaseInvestment[_token][_account]) {
            lastProfitCycleIdOf[_token][_account] = uint16(_futureProfitCycle.id);
            isNotFirstIncreaseInvestment[_token][_account] = true;
        }
        if (_investmentsOf.length > 0) {
            Investment memory _lastInvestmentOf = _investmentsOf[_investmentsOf.length - 1];
            Investment memory _newInvestmentOf = Investment(_lastInvestmentOf.amount + _amount, _updatedUnit, _nextInvestmentTimestamp, _futureProfitCycle.id);
            if (_lastInvestmentOf.idChanged < _futureProfitCycle.id) {
                _newInvestmentOf.unit = _lastInvestmentOf.amount * (_futureProfitCycle.endTime - _futureProfitCycle.startTime) + _unit;
                investmentsOf[_token][_account].push(_newInvestmentOf);
            } else {
                _newInvestmentOf.unit = _lastInvestmentOf.unit + _unit;
                investmentsOf[_token][_account][_investmentsOf.length - 1] = _newInvestmentOf;
            }
        } else {
            Investment memory _newInvestmentOf = Investment(_amount, _unit, _nextInvestmentTimestamp, _futureProfitCycle.id);
            investmentsOf[_token][_account].push(_newInvestmentOf);
        }
        totalInvestmentUnits[_token][_futureProfitCycle.id] += _unit;
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
    ) internal {
        require(isExistingToken[_token], "PrecogV5: INVALID_TOKEN");
        require(!isBeforeInvestmentTime(_token, _account), "PrecogV5: CAN_NOT_DECREASE_BEFORE_INVESTMENT_TIME");
        Investment[] memory _investmentsOf = investmentsOf[_token][_account];
        Cycle[] memory _profitCycles = profitCycles[_token];
        Cycle memory _lastProfitCycle = _profitCycles[_profitCycles.length - 1];
        require(_lastProfitCycle.endTime >= uint48(block.timestamp), "PrecogV5: INVALID_TIMESTAMP");
        if (_investmentsOf.length > 0) {
            Investment memory _lastInvestmentOf = _investmentsOf[_investmentsOf.length - 1];
            Investment memory _newInvestmentOf = Investment(_lastInvestmentOf.amount - _amount, _lastInvestmentOf.unit, _lastInvestmentOf.timestamp, _lastProfitCycle.id);
            if (_lastInvestmentOf.idChanged < _lastProfitCycle.id) {
                _newInvestmentOf.unit = _lastInvestmentOf.amount * (_lastProfitCycle.endTime - _lastProfitCycle.startTime);
                _newInvestmentOf.timestamp = uint48(block.timestamp);
                investmentsOf[_token][_account].push(_newInvestmentOf);
            } else {
                _newInvestmentOf.unit = _lastInvestmentOf.unit;
                investmentsOf[_token][_account][_investmentsOf.length - 1] = _newInvestmentOf;
            }
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
        (uint profitOfAccount, uint16 investmentId, uint16 lastProfitOfId) = _calculateProfit(token,account);
        profitOf[token][account] = profitOfAccount;
        lastInvestmentIdOf[token][account] = investmentId;
        lastProfitCycleIdOf[token][account] = lastProfitOfId;
    }

    function _updateDepsoitInfo(address _token, address _account, uint _amount) internal {
        Investment[] memory _investmentsOf = investmentsOf[_token][_account];
        Investment memory _lastInvestmentOf = _investmentsOf[_investmentsOf.length - 1];
        if(block.timestamp >= depositedTimestampOf[_token][_account]) {
            availableAmount[_token][msg.sender] = _amount;
            depositedTimestampOf[_token][_account] = _lastInvestmentOf.timestamp;
            if(currentDepositedTimestamp[_token] < _lastInvestmentOf.timestamp) {
                currentDepositedTimestamp[_token] = _lastInvestmentOf.timestamp;
            }
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
        require(amount >= core.minInvestment(token), "PrecogV5: AMOUNT_MUST_GREATER_THAN_MIN_VALUE");
        updateProfitCycleToCurrentCycle(token);
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
        uint48 _locktime;
        if (isFirstRequestWithdrawal[_token][_account] == false) {
            _locktime = core.getCycleConfiguration().firstWithdrawalCycle;
            isFirstRequestWithdrawal[_token][_account] = true;
        } else {
            _locktime = core.getCycleConfiguration().withdrawalCycle;
        }
        withdrawalRegister.registerWithdrawal(_token, _account, _amount, _locktime);
    }

    function requestWithdrawal(address token, uint amount) external override {
        require(isExistingToken[token], "PrecogV5: INVALID_TOKEN_ADDRESS");
        require(amount > 0, "PrecogV5: INVALID_AMOUNT");
        require(isBeforeInvestmentTime(token, msg.sender), "PrecogV5: MUST_REQUEST_WITHDRAWAL_AFTER_INVESTMENT_TIME");
        uint _lastIndexInvestmentOf = investmentsOf[token][msg.sender].length - 1;
        require(
            amount <= investmentsOf[token][msg.sender][_lastIndexInvestmentOf].amount,
            "PrecogV5: INSUFFICIENT_REQUESTED_AMOUNT"
        );
        updateProfitCycleToCurrentCycle(token);
        // Increase requested tokens
        _registerWithdrawal(token, msg.sender, amount);
        // Decrease liquidity also user's investment
        _decreaseInvestment(token, msg.sender, amount);
        liquidity[token] -= amount;
        newLiquidity[token] -= amount;
        updateProfit(token, msg.sender);
        emit RequestWithdrawal(token, msg.sender, amount);
    }

    function takeProfit(address to, address token) external override {
        updateProfitCycleToCurrentCycle(token);
        updateProfit(token, msg.sender);
        uint profitOfAccount = profitOf[token][msg.sender];
        require(profitOfAccount > 0, "PrecogV5: ACCOUNT_HAS_NO_PROFIT");
        IERC20(core.PCOG()).safeTransfer(to, profitOfAccount);
        claimedProfitOf[token][to] += profitOfAccount;
        emit TakeProfit(token, msg.sender, profitOfAccount);
        profitOf[token][msg.sender] = 0;
    }

    function _decreaseInvestmentWhenWithdraw(address _token, address _account, uint _amount) internal {
        Investment[] memory _investmentsOf = investmentsOf[_token][_account];
        Investment memory _lastInvestmentOf = _investmentsOf[_investmentsOf.length - 1];
        Cycle[] memory _profitCycles = profitCycles[_token];
        Cycle memory _lastProfitCycle = _profitCycles[_profitCycles.length - 1];
        uint _currentDepositedTimestamp = currentDepositedTimestamp[_token];
        uint48 _duration = PrecogV5Library._defineDurationInvestmentCycle(_lastProfitCycle, _currentDepositedTimestamp, core.getCycleConfiguration().investmentCycle);
        Cycle memory _futureProfitCycle = _getFutureProfitCycle(_token, _lastInvestmentOf.timestamp, _duration);
        require(_futureProfitCycle.endTime >= uint48(block.timestamp), "PrecogV5: INVALID_TIMESTAMP");
        _lastInvestmentOf.amount -= _amount;
        uint256 _unit = _amount * (_futureProfitCycle.endTime - _futureProfitCycle.startTime);
        _lastInvestmentOf.unit -= _unit; 
        investmentsOf[_token][_account][_investmentsOf.length - 1] = _lastInvestmentOf;
        totalInvestmentUnits[_token][_futureProfitCycle.id] -= _unit;
        availableAmount[_token][msg.sender] -= _amount;
    }

    function _withdrawBeforeInvestmentTime(address _account, address _to, address _token, uint _amount, uint _fee) internal {
        require(_amount + _fee <= availableDepositedAmount(_token, _account), "PrecogV5: INVESTMENT_HAS_ALREADY_STARTED");
        IERC20(_token).safeTransfer(_to, _amount - _fee);
        IERC20(_token).safeTransfer(address(core), _fee);
        _decreaseInvestmentWhenWithdraw(_token, _account, _amount);
        liquidity[_token] -= _amount;
        newLiquidity[_token] -= _amount;
    }

    function _withdrawAfterInvestmentTime(address _account, address _to, address _token, uint _amount, uint _fee) internal {
        withdrawalRegister.claimWithdrawal(_token, _account, _to, _amount, _fee);
    }

    function isBeforeInvestmentTime(address token, address account) public view returns (bool) {
        bool isBeforeInvestmentCycle = availableDepositedAmount(token, account) > 0 ? true : false;
        return isBeforeInvestmentCycle;
    }

    function withdraw(
        address to,
        address token,
        uint amount
    ) external override {
        require(isExistingToken[token], "PrecogV5: NOT_A_LIQUIDITY_TOKEN");
        require(amount > 0, "PrecogV5: INVALID_AMOUNT_LIQUIDITY");
        updateProfitCycleToCurrentCycle(token);
        uint withdrawalFee = (amount * core.getFeeConfiguration().withdrawalFee) / 10**core.feeDecimalBase();
        IIPCOG(tokenConvert[token]).burnFrom(msg.sender, amount);
        if(isBeforeInvestmentTime(token, msg.sender)) {
            _withdrawBeforeInvestmentTime(msg.sender, to, token, amount, withdrawalFee);
        } else {
            _withdrawAfterInvestmentTime(msg.sender, to, token, amount, withdrawalFee);
        }
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

    function _getCurrentProfitCycleByTimestamp( 
        IPrecogV5.Cycle memory _lastCycle,
        uint _timestamp, 
        uint _currentDepositedTimestamp,
        uint48 _profitCycleDuration,
        bool isRemoved
    )
        internal
        view
        returns (
            uint _currentCycleId,
            uint _currentCycleStartTime,
            uint _currentCycleEndTime
        )
    {
        require(_timestamp >= block.timestamp, "PrecogV5Library: TIMESTAMP_MUST_NOT_LESS_THAN_NOW");
        uint48 _newCycleStartTime;
        uint48 _newCycleEndTime;
        uint48 _duration;
        if (isRemoved) {
            return (_lastCycle.id, _lastCycle.startTime, _lastCycle.endTime);
        }
        while (uint48(_timestamp) >= _lastCycle.endTime) {
            _newCycleStartTime = _lastCycle.endTime;
            if (_lastCycle.endTime < _currentDepositedTimestamp) {
                _duration = _lastCycle.endTime - _lastCycle.startTime;
            } else {
                _duration = _profitCycleDuration;
            }
            _newCycleEndTime = _newCycleStartTime + _duration;
            _lastCycle = (IPrecogV5.Cycle(_lastCycle.id + 1, _newCycleStartTime, _newCycleEndTime));
        }
        return (_lastCycle.id, _lastCycle.startTime, _lastCycle.endTime);
    }

    function _isAfterLatestDepositedTime(uint _currentDepositedTimestamp) internal view returns (bool) {
        return block.timestamp > _currentDepositedTimestamp;
    }

    function _defineDurationInvestmentCycle(
        IPrecogV5.Cycle memory _lastProfitCycle, 
        uint _currentDepositedTimestamp, 
        uint48 _investmentCycleDuration
    ) 
        internal 
        view 
        returns (uint48 _duration) 
    {
        if(_isAfterLatestDepositedTime(_currentDepositedTimestamp)) {
            _duration = _investmentCycleDuration;
        } else {
            _duration = _lastProfitCycle.endTime - _lastProfitCycle.startTime;
        }
    }

    function _chooseLastAvailableProfitId(
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
        IPrecogV5.Cycle[] memory _profitCycles,
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
                IPrecogV5.Cycle memory lastCycle = _profitCycles[_lastProfitIdOf];
                _profitAtCycle = (_lastProfit * _investment.amount * (lastCycle.endTime - lastCycle.startTime)) / _totalInvestmentUnit;
            }
        }    
    }

    function _calculateNextInvestmentTimestamp(IPrecogV5.Cycle memory _firstProfitCycle, uint48 _duration) internal view returns (uint48 _nextInvestmentTimestamp) {
        return ((uint48(block.timestamp) - _firstProfitCycle.startTime) / _duration + 1) * _duration + _firstProfitCycle.startTime;
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

    function investmentsOf(address token, address account, uint index) external view returns (
        uint amount, 
        uint unit,
        uint48 timestamp,
        uint16 idChanged
    );



    function profitOf(address token, address account) external view returns (uint);
    function claimedProfitOf(address token, address account) external view returns (uint);
    function profitCycles(address token, uint id) external view returns (uint16, uint48, uint48);
    function currentInvestmentCycleId(address token) external view returns (uint16);
    function currentProfitCycleId(address token) external view returns (uint16);
    function lastProfitCycleIdOf(address token, address account) external view returns (uint16);
    function lastInvestmentIdOf(address token, address account) external view returns (uint16);

    function isExistingToken(address token) external view returns (bool);
    function tokenConvert(address token) external view returns (address);
    function liquidity(address token) external view returns (uint);
    function profits(address token, uint index) external view returns (uint);
    function isLiquidityToken(address liqudityToken) external view returns (bool);
    function getExistingTokens() external view returns (address[] memory);
    function getExistingTokenByIndex(uint index) external view returns (address);
    function calculateProfit(address token, address account) external view returns (uint, uint16, uint16);
    function getCurrentProfitCycle(address token) external view returns (
        uint currentCycleId, 
        uint currentCycleStartTime, 
        uint currentCycleEndTime
    );

    // Functions for all role

    function updateProfitCycleToCurrentCycle(address token) external;

    // Functions for admin
    
    function setMiddlewareExchange(address newMiddlewareExchange) external;
    function setWithdrawalRegister(address newWithdrawalRegister) external;
    function addLiquidityPool(address token) external;
    function removeLiquidityPool(address token) external;

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
    function withdraw(address to, address liquidityToken, uint amountLiquidity) external;
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
    function lastChangeProfitCycle() external view returns (uint32);
    function getCoreConfiguration() external view returns (CoreConfiguration memory);
    function getFeeConfiguration() external view returns (FeeConfiguration memory);
    function getCycleConfiguration() external view returns (CycleConfiguration memory);
    function minInvestment(address token) external view returns (uint256);
    function setCoreConfiguration(CoreConfiguration memory config) external;
    function setFeeConfiguration(FeeConfiguration memory config) external;
    function setCycleConfiguration(CycleConfiguration memory config) external;
    function collectFee(address token) external;
    function setMinInvestment(address token, uint256 amount) external;
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