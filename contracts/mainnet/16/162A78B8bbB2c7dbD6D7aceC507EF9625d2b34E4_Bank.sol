// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./config/Constant.sol";
import "./interfaces/IGlobalConfig.sol";
import "./interfaces/ICToken.sol";
import "./interfaces/ICETH.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Bank is BPYConstant, Initializable {
    using SafeMath for uint256;
    // globalConfig should be initialized per pool
    IGlobalConfig public globalConfig; // global configuration contract address

    // NOTICE struct to avoid below error:
    // "Contract has 16 states declarations but allowed no more than 15"
    struct BankConfig {
        address poolRegistry;
        // maxUtilToCalcBorrowAPR = 1 - rateCurveConstant / MaxBorrowAPR%
        // ex: minBorrowAPR% = 3%
        // MaxBorrowAPR% = 150%
        // rateCurveConstant = minBorrowAPR = 3
        // maxUtilToCalcBorrowAPR = 1 - 3 / 150 = 0.98 = 98%
        // variable stores value in format => 10^18 = 100%
        uint256 maxUtilToCalcBorrowAPR; // Max Utilization to Calculate Borrow APR
        // rateCurveConstantMultiplier = 1 / (1 - maxUtilToCalcBorrowAPR)
        // ex: maxUtilToCalcBorrowAPR = 0.98 = 98%
        // rateCurveConstantMultiplier = 1 / (1 - 0.98) = 50
        uint256 rateCurveConstantMultiplier;
    }

    // Bank Config to avoid errors
    BankConfig public bankConfig;
    // token => amount
    mapping(address => uint256) public totalLoans; // amount of lended tokens
    // token => amount
    mapping(address => uint256) public totalReserve; // amount of tokens in reservation
    // token => amount
    mapping(address => uint256) public totalCompound; // amount of tokens in compound
    // Token => block-num => rate
    mapping(address => mapping(uint256 => uint256)) public depositeRateIndex; // the index curve of deposit rate
    // Token => block-num => rate
    mapping(address => mapping(uint256 => uint256)) public borrowRateIndex; // the index curve of borrow rate
    // token address => block number
    mapping(address => uint256) public lastCheckpoint; // last checkpoint on the index curve
    // cToken address => rate
    mapping(address => uint256) public lastCTokenExchangeRate; // last compound cToken exchange rate
    mapping(address => ThirdPartyPool) public compoundPool; // the compound pool

    mapping(address => mapping(uint256 => uint256)) public depositFINRateIndex;
    mapping(address => mapping(uint256 => uint256)) public borrowFINRateIndex;
    mapping(address => uint256) public lastDepositFINRateCheckpoint;
    mapping(address => uint256) public lastBorrowFINRateCheckpoint;

    modifier onlyAuthorized() {
        require(
            msg.sender == address(globalConfig.savingAccount()) || msg.sender == address(globalConfig.accounts()),
            "Only authorized to call from DeFiner internal contracts."
        );
        _;
    }

    modifier onlyGlobalConfig() {
        require(msg.sender == address(globalConfig), "not authorized");
        _;
    }

    struct ThirdPartyPool {
        bool supported; // if the token is supported by the third party platforms such as Compound
        uint256 capitalRatio; // the ratio of the capital in third party to the total asset
        uint256 depositRatePerBlock; // the deposit rate of the token in third party
        uint256 borrowRatePerBlock; // the borrow rate of the token in third party
    }

    event UpdateIndex(address indexed token, uint256 depositeRateIndex, uint256 borrowRateIndex);
    event UpdateDepositFINIndex(address indexed _token, uint256 depositFINRateIndex);
    event UpdateBorrowFINIndex(address indexed _token, uint256 borrowFINRateIndex);

    /**
     * @notice The Bank contract is upgradeable, hence, constructor is not allowed.
     * But `BLOCKS_PER_YEAR` is `immutable` present in `BPYConstant` contract
     * threfore we need to initialize blocksPerYear from the constructor.
     * The `immutable` variables are also does not takes storage slot just like `constant`.
     * refer: https://docs.soliditylang.org/en/v0.8.4/contracts.html?#constant-and-immutable-state-variables
     **/
    // solhint-disable-next-line no-empty-blocks
    constructor(uint256 _blocksPerYear) BPYConstant(_blocksPerYear) {}

    /**
     * Initialize the Bank
     * @param _globalConfig the global configuration contract
     */
    function initialize(IGlobalConfig _globalConfig, address _poolRegistry) public initializer {
        globalConfig = _globalConfig;
        bankConfig.poolRegistry = _poolRegistry;
    }

    /**
     * @dev Configuration of Max Utilization to Calculate Borrow APR and rateCurveConstantMultiplier
     * is done only once from the PoolRegistry
     */
    function configureMaxUtilToCalcBorrowAPR(uint256 _maxBorrowAPR) external onlyGlobalConfig {
        // 1 - rateCurveConstant / MaxBorrowAPR
        // ex:
        // rateCurveConstant = 3e16 = 3%
        // _maxBorrowAPR = 150e16 = 150%
        // maxUtilToCalcBorrowAPR = 1e18 - ((3e16 * 1e18) / 150e16) = 980_000_000_000_000_000 = 0.98 = 98%
        uint256 maxUtilToCalcBorrowAPR = INT_UNIT - ((globalConfig.rateCurveConstant() * INT_UNIT) / _maxBorrowAPR);

        // rateCurveConstantMultiplier = 1 / (1 - maxUtilToCalcBorrowAPR)
        // rateCurveConstantMultiplier = 1e18 / (1e18 - maxUtilToCalcBorrowAPR)
        // but to keep value in 18 decimal, multiply hence
        // rateCurveConstantMultiplier = (1e18 * 1e18) / (1e18 - maxUtilToCalcBorrowAPR)
        // above calculation results in multiplier in 18 decimals, so that we can avoid decimal truncation
        // when maxUtilToCalcBorrowAPR is in lower bound
        // ex:
        // maxUtilToCalcBorrowAPR = 980_000_000_000_000_000 = 0.98 = 98%
        // rateCurveConstantMultiplier
        //      = (1e18 * 1e18) / (1e18 - 980_000_000_000_000_000) = 50_000_000_000_000_000_000 = 50
        bankConfig.rateCurveConstantMultiplier = (INT_UNIT * INT_UNIT) / (INT_UNIT - maxUtilToCalcBorrowAPR);

        // stored at last to avoid storage read
        bankConfig.maxUtilToCalcBorrowAPR = maxUtilToCalcBorrowAPR;
    }

    /**
     * Total amount of the token in Saving account
     * @param _token token address
     */
    function getTotalDepositStore(address _token) public view returns (uint256) {
        address cToken = globalConfig.tokenRegistry().getCToken(_token);
        // totalLoans[_token] = U   totalReserve[_token] = R
        // return totalAmount = C + U + R
        return totalCompound[cToken].add(totalLoans[_token]).add(totalReserve[_token]);
    }

    /**
     * Update total amount of token in Compound as the cToken price changed
     * @param _token token address
     */
    function updateTotalCompound(address _token) internal {
        address cToken = globalConfig.tokenRegistry().getCToken(_token);
        if (cToken != address(0)) {
            totalCompound[cToken] = ICToken(cToken).balanceOfUnderlying(address(globalConfig.savingAccount()));
        }
    }

    /**
     * Update the total reservation. Before run this function, make sure that totalCompound has been updated
     * by calling updateTotalCompound. Otherwise, totalCompound may not equal to the exact amount of the
     * token in Compound.
     * @param _token token address
     * @param _action indicate if user's operation is deposit or withdraw, and borrow or repay.
     * @return compoundAmount the actual amount deposit/withdraw from the saving pool
     */
    // solhint-disable-next-line code-complexity
    function updateTotalReserve(
        address _token,
        uint256 _amount,
        ActionType _action
    ) internal returns (uint256 compoundAmount) {
        address cToken = globalConfig.tokenRegistry().getCToken(_token);
        uint256 totalAmount = getTotalDepositStore(_token);
        if (_action == ActionType.DepositAction || _action == ActionType.RepayAction) {
            // Total amount of token after deposit or repay
            if (_action == ActionType.DepositAction) {
                totalAmount = totalAmount.add(_amount);
            } else {
                totalLoans[_token] = totalLoans[_token].sub(_amount);
            }

            // Expected total amount of token in reservation after deposit or repay
            uint256 totalReserveBeforeAdjust = totalReserve[_token].add(_amount);

            if (
                cToken != address(0) &&
                totalReserveBeforeAdjust > totalAmount.mul(globalConfig.maxReserveRatio()).div(100)
            ) {
                uint256 toCompoundAmount = totalReserveBeforeAdjust.sub(
                    totalAmount.mul(globalConfig.midReserveRatio()).div(100)
                );
                //toCompound(_token, toCompoundAmount);
                compoundAmount = toCompoundAmount;
                totalCompound[cToken] = totalCompound[cToken].add(toCompoundAmount);
                totalReserve[_token] = totalReserve[_token].add(_amount).sub(toCompoundAmount);
            } else {
                totalReserve[_token] = totalReserve[_token].add(_amount);
            }
        } else if (_action == ActionType.LiquidateRepayAction) {
            // When liquidation is called the `totalLoans` amount should be reduced.
            // We dont need to update other variables as all the amounts are adjusted internally,
            // hence does not require updation of `totalReserve` / `totalCompound`
            totalLoans[_token] = totalLoans[_token].sub(_amount);
        } else {
            // The lack of liquidity exception happens when the pool doesn't have enough tokens for borrow/withdraw
            // It happens when part of the token has lended to the other accounts.
            // However in case of withdrawAll, even if the token has no loan, this requirment may still false because
            // of the precision loss in the rate calcuation. So we put a logic here to deal with this case: in case
            // of withdrawAll and there is no loans for the token, we just adjust the balance in bank contract to the
            // to the balance of that individual account.
            if (_action == ActionType.WithdrawAction) {
                if (totalLoans[_token] != 0) {
                    require(getPoolAmount(_token) >= _amount, "Lack of liquidity when withdraw.");
                } else if (getPoolAmount(_token) < _amount) {
                    totalReserve[_token] = _amount.sub(totalCompound[cToken]);
                }
                totalAmount = getTotalDepositStore(_token);
            } else require(getPoolAmount(_token) >= _amount, "Lack of liquidity when borrow.");

            // Total amount of token after withdraw or borrow
            if (_action == ActionType.WithdrawAction) {
                totalAmount = totalAmount.sub(_amount);
            } else {
                totalLoans[_token] = totalLoans[_token].add(_amount);
            }

            // Expected total amount of token in reservation after deposit or repay
            uint256 totalReserveBeforeAdjust = totalReserve[_token] > _amount ? totalReserve[_token].sub(_amount) : 0;

            // Trigger fromCompound if the new reservation ratio is less than 10%
            if (
                cToken != address(0) &&
                (totalAmount == 0 ||
                    totalReserveBeforeAdjust < totalAmount.mul(globalConfig.minReserveRatio()).div(100))
            ) {
                uint256 totalAvailable = totalReserve[_token].add(totalCompound[cToken]).sub(_amount);
                if (totalAvailable < totalAmount.mul(globalConfig.midReserveRatio()).div(100)) {
                    // Withdraw all the tokens from Compound
                    compoundAmount = totalCompound[cToken];
                    totalCompound[cToken] = 0;
                    totalReserve[_token] = totalAvailable;
                } else {
                    // Withdraw partial tokens from Compound
                    uint256 totalInCompound = totalAvailable.sub(
                        totalAmount.mul(globalConfig.midReserveRatio()).div(100)
                    );
                    compoundAmount = totalCompound[cToken].sub(totalInCompound);
                    totalCompound[cToken] = totalInCompound;
                    totalReserve[_token] = totalAvailable.sub(totalInCompound);
                }
            } else {
                totalReserve[_token] = totalReserve[_token].sub(_amount);
            }
        }
        return compoundAmount;
    }

    function update(
        address _token,
        uint256 _amount,
        ActionType _action
    ) public onlyAuthorized returns (uint256 compoundAmount) {
        updateTotalCompound(_token);
        // updateTotalLoan(_token);
        compoundAmount = updateTotalReserve(_token, _amount, _action);
        return compoundAmount;
    }

    /**
     * The function is called in Bank.deposit(), Bank.withdraw() and Accounts.claim() functions.
     * The function should be called AFTER the newRateIndexCheckpoint function so that the account balances are
     * accurate, and BEFORE the account balance acutally updated due to deposit/withdraw activities.
     */
    function updateDepositFINIndex(address _token) public onlyAuthorized {
        uint256 currentBlock = getBlockNumber();
        uint256 deltaBlock;
        // If it is the first deposit FIN rate checkpoint, set the deltaBlock value be 0 so that the first
        // point on depositFINRateIndex is zero.
        deltaBlock = lastDepositFINRateCheckpoint[_token] == 0
            ? 0
            : currentBlock.sub(lastDepositFINRateCheckpoint[_token]);
        // If the totalDeposit of the token is zero, no FIN token should be mined and the FINRateIndex is unchanged.
        depositFINRateIndex[_token][currentBlock] = depositFINRateIndex[_token][lastDepositFINRateCheckpoint[_token]]
            .add(
                getTotalDepositStore(_token) == 0
                    ? 0
                    : depositeRateIndex[_token][lastCheckpoint[_token]]
                        .mul(deltaBlock)
                        .mul(globalConfig.tokenRegistry().depositeMiningSpeeds(_token))
                        .div(getTotalDepositStore(_token))
            );
        lastDepositFINRateCheckpoint[_token] = currentBlock;

        emit UpdateDepositFINIndex(_token, depositFINRateIndex[_token][currentBlock]);
    }

    function updateBorrowFINIndex(address _token) public onlyAuthorized {
        uint256 currentBlock = getBlockNumber();
        uint256 deltaBlock;
        // If it is the first borrow FIN rate checkpoint, set the deltaBlock value be 0 so that the first
        // point on borrowFINRateIndex is zero.
        deltaBlock = lastBorrowFINRateCheckpoint[_token] == 0
            ? 0
            : currentBlock.sub(lastBorrowFINRateCheckpoint[_token]);
        // If the totalBorrow of the token is zero, no FIN token should be mined and the FINRateIndex is unchanged.
        borrowFINRateIndex[_token][currentBlock] = borrowFINRateIndex[_token][lastBorrowFINRateCheckpoint[_token]].add(
            totalLoans[_token] == 0
                ? 0
                : borrowRateIndex[_token][lastCheckpoint[_token]]
                    .mul(deltaBlock)
                    .mul(globalConfig.tokenRegistry().borrowMiningSpeeds(_token))
                    .div(totalLoans[_token])
        );
        lastBorrowFINRateCheckpoint[_token] = currentBlock;

        emit UpdateBorrowFINIndex(_token, borrowFINRateIndex[_token][currentBlock]);
    }

    function updateMining(address _token) public onlyAuthorized {
        newRateIndexCheckpoint(_token);
        updateTotalCompound(_token);
    }

    /**
     * Get the borrowing interest rate.
     * @param _token token address
     * @return the borrow rate for the current block
     */
    function getBorrowRatePerBlock(address _token) public view returns (uint256) {
        uint256 capitalUtilizationRatio = getCapitalUtilizationRatio(_token);
        // rateCurveConstant = <'3 * (10)^16'_rateCurveConstant_configurable>
        uint256 rateCurveConstant = globalConfig.rateCurveConstant();
        // compoundSupply = Compound Supply Rate * <'0.4'_supplyRateWeights_configurable>
        uint256 compoundSupply = compoundPool[_token].depositRatePerBlock.mul(globalConfig.compoundSupplyRateWeights());
        // compoundBorrow = Compound Borrow Rate * <'0.6'_borrowRateWeights_configurable>
        uint256 compoundBorrow = compoundPool[_token].borrowRatePerBlock.mul(globalConfig.compoundBorrowRateWeights());
        // nonUtilizedCapRatio = (1 - U) // Non utilized capital ratio
        uint256 nonUtilizedCapRatio = INT_UNIT.sub(capitalUtilizationRatio);

        bool isSupportedOnCompound = globalConfig.tokenRegistry().isSupportedOnCompound(_token);
        if (isSupportedOnCompound) {
            uint256 compoundSupplyPlusBorrow = compoundSupply.add(compoundBorrow).div(10);
            uint256 rateConstant;
            // if the token is supported in third party (like Compound), check if U = 1
            if (capitalUtilizationRatio > bankConfig.maxUtilToCalcBorrowAPR) {
                // > 0.999
                // if U = 1,
                // borrowing rate =
                //  compoundSupply + compoundBorrow +
                //  ((rateCurveConstant * rateCurveConstantMultiplier) / BLOCKS_PER_YEAR).div(INT_UNIT)

                // NOTICE: rateCurveConstantMultiplier is in 18 decimals, to normalize
                // it divide by INT_UNIT after multiplication
                rateConstant = rateCurveConstant.mul(bankConfig.rateCurveConstantMultiplier).div(BLOCKS_PER_YEAR).div(
                    INT_UNIT
                );
                return compoundSupplyPlusBorrow.add(rateConstant);
            } else {
                // if U != 1,
                // borrowing rate = compoundSupply + compoundBorrow + ((rateCurveConstant / (1 - U)) / BLOCKS_PER_YEAR)
                rateConstant = rateCurveConstant.mul(10**18).div(nonUtilizedCapRatio).div(BLOCKS_PER_YEAR);
                return compoundSupplyPlusBorrow.add(rateConstant);
            }
        } else {
            // If the token is NOT supported by the third party, check if U = 1
            if (capitalUtilizationRatio > bankConfig.maxUtilToCalcBorrowAPR) {
                // > 0.999
                // if U = 1, borrowing rate = rateCurveConstant * rateCurveConstantMultiplier

                // NOTICE: rateCurveConstantMultiplier is in 18 decimals, to normalize
                // it divide by INT_UNIT after multiplication
                return rateCurveConstant.mul(bankConfig.rateCurveConstantMultiplier).div(BLOCKS_PER_YEAR).div(INT_UNIT);
            } else {
                // if 0 < U < 1, borrowing rate = 3% / (1 - U)
                return rateCurveConstant.mul(10**18).div(nonUtilizedCapRatio).div(BLOCKS_PER_YEAR);
            }
        }
    }

    /**
     * Get Deposit Rate.  Deposit APR = (Borrow APR * Utilization Rate (U) +  Compound Supply Rate *
     * Capital Compound Ratio (C) )* (1- DeFiner Community Fund Ratio (D)). The scaling is 10 ** 18
     * @param _token token address
     * @return deposite rate of blocks before the current block
     */
    function getDepositRatePerBlock(address _token) public view returns (uint256) {
        uint256 borrowRatePerBlock = getBorrowRatePerBlock(_token);
        uint256 capitalUtilRatio = getCapitalUtilizationRatio(_token);
        if (!globalConfig.tokenRegistry().isSupportedOnCompound(_token))
            return borrowRatePerBlock.mul(capitalUtilRatio).div(INT_UNIT);

        return
            borrowRatePerBlock
                .mul(capitalUtilRatio)
                .add(compoundPool[_token].depositRatePerBlock.mul(compoundPool[_token].capitalRatio))
                .div(INT_UNIT);
    }

    /**
     * Get capital utilization. Capital Utilization Rate (U )= total loan outstanding / Total market deposit
     * @param _token token address
     * @return Capital utilization ratio `U`.
     *  Valid range: 0 ≤ U ≤ 10^18
     */
    function getCapitalUtilizationRatio(address _token) public view returns (uint256) {
        uint256 totalDepositsNow = getTotalDepositStore(_token);
        if (totalDepositsNow == 0) {
            return 0;
        } else {
            return totalLoans[_token].mul(INT_UNIT).div(totalDepositsNow);
        }
    }

    /**
     * Ratio of the capital in Compound
     * @param _token token address
     */
    function getCapitalCompoundRatio(address _token) public view returns (uint256) {
        address cToken = globalConfig.tokenRegistry().getCToken(_token);
        if (totalCompound[cToken] == 0) {
            return 0;
        } else {
            return uint256(totalCompound[cToken].mul(INT_UNIT).div(getTotalDepositStore(_token)));
        }
    }

    /**
     * It's a utility function. Get the cummulative deposit rate in a block interval ending in current block
     * @param _token token address
     * @param _depositRateRecordStart the start block of the interval
     * @dev This function should always be called after current block is set as a new rateIndex point.
     */
    function getDepositAccruedRate(address _token, uint256 _depositRateRecordStart) external view returns (uint256) {
        uint256 depositRate = depositeRateIndex[_token][_depositRateRecordStart];
        require(depositRate != 0, "_depositRateRecordStart is not a check point on index curve.");
        return depositeRateIndexNow(_token).mul(INT_UNIT).div(depositRate);
    }

    /**
     * Get the cummulative borrow rate in a block interval ending in current block
     * @param _token token address
     * @param _borrowRateRecordStart the start block of the interval
     * @dev This function should always be called after current block is set as a new rateIndex point.
     */
    function getBorrowAccruedRate(address _token, uint256 _borrowRateRecordStart) external view returns (uint256) {
        uint256 borrowRate = borrowRateIndex[_token][_borrowRateRecordStart];
        require(borrowRate != 0, "_borrowRateRecordStart is not a check point on index curve.");
        return borrowRateIndexNow(_token).mul(INT_UNIT).div(borrowRate);
    }

    /**
     * Set a new rate index checkpoint.
     * @param _token token address
     * @dev The rate set at the checkpoint is the rate from the last checkpoint to this checkpoint
     */
    function newRateIndexCheckpoint(address _token) public onlyAuthorized {
        // return if the rate check point already exists
        uint256 blockNumber = getBlockNumber();
        if (blockNumber == lastCheckpoint[_token]) return;

        address cToken = globalConfig.tokenRegistry().getCToken(_token);

        // If it is the first check point, initialize the rate index
        uint256 previousCheckpoint = lastCheckpoint[_token];
        if (lastCheckpoint[_token] == 0) {
            if (cToken == address(0)) {
                compoundPool[_token].supported = false;
                borrowRateIndex[_token][blockNumber] = INT_UNIT;
                depositeRateIndex[_token][blockNumber] = INT_UNIT;
                // Update the last checkpoint
                lastCheckpoint[_token] = blockNumber;
            } else {
                compoundPool[_token].supported = true;
                uint256 cTokenExchangeRate = ICToken(cToken).exchangeRateCurrent();
                // Get the curretn cToken exchange rate in Compound, which is need to calculate DeFiner's rate
                compoundPool[_token].capitalRatio = getCapitalCompoundRatio(_token);
                compoundPool[_token].borrowRatePerBlock = ICToken(cToken).borrowRatePerBlock(); // initial value
                compoundPool[_token].depositRatePerBlock = ICToken(cToken).supplyRatePerBlock(); // initial value
                borrowRateIndex[_token][blockNumber] = INT_UNIT;
                depositeRateIndex[_token][blockNumber] = INT_UNIT;
                // Update the last checkpoint
                lastCheckpoint[_token] = blockNumber;
                lastCTokenExchangeRate[cToken] = cTokenExchangeRate;
            }
        } else {
            if (cToken == address(0)) {
                compoundPool[_token].supported = false;
                borrowRateIndex[_token][blockNumber] = borrowRateIndexNow(_token);
                depositeRateIndex[_token][blockNumber] = depositeRateIndexNow(_token);
                // Update the last checkpoint
                lastCheckpoint[_token] = blockNumber;
            } else {
                compoundPool[_token].supported = true;
                uint256 cTokenExchangeRate = ICToken(cToken).exchangeRateCurrent();
                // Get the curretn cToken exchange rate in Compound, which is need to calculate DeFiner's rate
                compoundPool[_token].capitalRatio = getCapitalCompoundRatio(_token);
                compoundPool[_token].borrowRatePerBlock = ICToken(cToken).borrowRatePerBlock();
                compoundPool[_token].depositRatePerBlock = cTokenExchangeRate
                    .mul(INT_UNIT)
                    .div(lastCTokenExchangeRate[cToken])
                    .sub(INT_UNIT)
                    .div(blockNumber.sub(lastCheckpoint[_token]));
                borrowRateIndex[_token][blockNumber] = borrowRateIndexNow(_token);
                depositeRateIndex[_token][blockNumber] = depositeRateIndexNow(_token);
                // Update the last checkpoint
                lastCheckpoint[_token] = blockNumber;
                lastCTokenExchangeRate[cToken] = cTokenExchangeRate;
            }
        }

        // Update the total loan
        if (borrowRateIndex[_token][blockNumber] != INT_UNIT) {
            totalLoans[_token] = totalLoans[_token].mul(borrowRateIndex[_token][blockNumber]).div(
                borrowRateIndex[_token][previousCheckpoint]
            );
        }

        emit UpdateIndex(
            _token,
            depositeRateIndex[_token][getBlockNumber()],
            borrowRateIndex[_token][getBlockNumber()]
        );
    }

    /**
     * Calculate a token deposite rate of current block
     * @param _token token address
     * @dev This is an looking forward estimation from last checkpoint and not the exactly rate
     *      that the user will pay or earn.
     */
    function depositeRateIndexNow(address _token) public view returns (uint256) {
        uint256 lcp = lastCheckpoint[_token];
        // If this is the first checkpoint, set the index be 1.
        if (lcp == 0) return INT_UNIT;

        uint256 lastDepositeRateIndex = depositeRateIndex[_token][lcp];
        uint256 depositRatePerBlock = getDepositRatePerBlock(_token);
        // newIndex = oldIndex*(1+r*delta_block).
        // If delta_block = 0, i.e. the last checkpoint is current block, index doesn't change.
        return
            lastDepositeRateIndex.mul(getBlockNumber().sub(lcp).mul(depositRatePerBlock).add(INT_UNIT)).div(INT_UNIT);
    }

    /**
     * Calculate a token borrow rate of current block
     * @param _token token address
     */
    function borrowRateIndexNow(address _token) public view returns (uint256) {
        uint256 lcp = lastCheckpoint[_token];
        // If this is the first checkpoint, set the index be 1.
        if (lcp == 0) return INT_UNIT;
        uint256 lastBorrowRateIndex = borrowRateIndex[_token][lcp];
        uint256 borrowRatePerBlock = getBorrowRatePerBlock(_token);
        return lastBorrowRateIndex.mul(getBlockNumber().sub(lcp).mul(borrowRatePerBlock).add(INT_UNIT)).div(INT_UNIT);
    }

    /**
     * Get the state of the given token
     * @param _token token address
     */
    function getTokenState(address _token)
        public
        view
        returns (
            uint256 deposits,
            uint256 loans,
            uint256 reserveBalance,
            uint256 remainingAssets
        )
    {
        return (
            getTotalDepositStore(_token),
            totalLoans[_token],
            totalReserve[_token],
            totalReserve[_token].add(totalCompound[globalConfig.tokenRegistry().getCToken(_token)])
        );
    }

    function getPoolAmount(address _token) public view returns (uint256) {
        return totalReserve[_token].add(totalCompound[globalConfig.tokenRegistry().getCToken(_token)]);
    }

    function deposit(
        address _to,
        address _token,
        uint256 _amount
    ) external onlyAuthorized {
        require(_amount != 0, "Amount is zero");

        // Add a new checkpoint on the index curve.
        newRateIndexCheckpoint(_token);
        updateDepositFINIndex(_token);

        // Update tokenInfo. Add the _amount to principal, and update the last deposit block in tokenInfo
        globalConfig.accounts().deposit(_to, _token, _amount);

        // Update the amount of tokens in compound and loans, i.e. derive the new values
        // of C (Compound Ratio) and U (Utilization Ratio).
        uint256 compoundAmount = update(_token, _amount, ActionType.DepositAction);

        if (compoundAmount > 0) {
            globalConfig.savingAccount().toCompound(_token, compoundAmount);
        }
    }

    function borrow(
        address _from,
        address _token,
        uint256 _amount
    ) external onlyAuthorized {
        // Add a new checkpoint on the index curve.
        newRateIndexCheckpoint(_token);
        updateBorrowFINIndex(_token);

        // Update tokenInfo for the user
        globalConfig.accounts().borrow(_from, _token, _amount);

        // Update pool balance
        // Update the amount of tokens in compound and loans, i.e. derive the new values
        // of C (Compound Ratio) and U (Utilization Ratio).
        uint256 compoundAmount = update(_token, _amount, ActionType.BorrowAction);

        if (compoundAmount > 0) {
            globalConfig.savingAccount().fromCompound(_token, compoundAmount);
        }
    }

    function repay(
        address _to,
        address _token,
        uint256 _amount
    ) external onlyAuthorized returns (uint256) {
        // Add a new checkpoint on the index curve.
        newRateIndexCheckpoint(_token);
        updateBorrowFINIndex(_token);

        // Sanity check
        require(globalConfig.accounts().getBorrowPrincipal(_to, _token) > 0, "Token BorrowPrincipal must be > 0");

        // Update tokenInfo
        uint256 remain = globalConfig.accounts().repay(_to, _token, _amount);

        // Update the amount of tokens in compound and loans, i.e. derive the new values
        // of C (Compound Ratio) and U (Utilization Ratio).
        uint256 compoundAmount = update(_token, _amount.sub(remain), ActionType.RepayAction);
        if (compoundAmount > 0) {
            globalConfig.savingAccount().toCompound(_token, compoundAmount);
        }

        // Return actual amount repaid
        return _amount.sub(remain);
    }

    /**
     * Withdraw a token from an address
     * @param _from address to be withdrawn from
     * @param _token token address
     * @param _amount amount to be withdrawn
     * @return The actually amount withdrawed, which will be the amount requested minus the commission fee.
     */
    function withdraw(
        address _from,
        address _token,
        uint256 _amount
    ) external onlyAuthorized returns (uint256) {
        require(_amount != 0, "Amount is zero");

        // Add a new checkpoint on the index curve.
        newRateIndexCheckpoint(_token);
        updateDepositFINIndex(_token);

        // Withdraw from the account
        uint256 amount = globalConfig.accounts().withdraw(_from, _token, _amount);

        // Update pool balance
        // Update the amount of tokens in compound and loans, i.e. derive the new values
        // of C (Compound Ratio) and U (Utilization Ratio).
        uint256 compoundAmount = update(_token, amount, ActionType.WithdrawAction);

        // Check if there are enough tokens in the pool.
        if (compoundAmount > 0) {
            globalConfig.savingAccount().fromCompound(_token, compoundAmount);
        }

        return amount;
    }

    /**
     * Get current block number
     * @return the current block number
     */
    function getBlockNumber() private view returns (uint256) {
        return block.number;
    }

    function version() public pure returns (string memory) {
        return "v2.0.0";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

enum ActionType {
    DepositAction,
    WithdrawAction,
    BorrowAction,
    RepayAction,
    LiquidateRepayAction
}

abstract contract Constant {
    address public constant ETH_ADDR = 0x000000000000000000000000000000000000000E;
    uint256 public constant INT_UNIT = 10**uint256(18);
    uint256 public constant ACCURACY = 10**uint256(18);
}

/**
 * @dev Only some of the contracts uses BLOCKS_PER_YEAR in their code.
 * Hence, only those contracts would have to inherit from BPYConstant.
 * This is done to minimize the argument passing from other contracts.
 */
abstract contract BPYConstant is Constant {
    // solhint-disable-next-line var-name-mixedcase
    uint256 public immutable BLOCKS_PER_YEAR;

    constructor(uint256 _blocksPerYear) {
        BLOCKS_PER_YEAR = _blocksPerYear;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "./ITokenRegistry.sol";
import "./IBank.sol";
import "./ISavingAccount.sol";
import "./IAccounts.sol";
import "./IConstant.sol";

interface IGlobalConfig {
    function initialize(
        address _gemGlobalConfig,
        address _bank,
        address _savingAccount,
        address _tokenRegistry,
        address _accounts,
        address _poolRegistry
    ) external;

    function tokenRegistry() external view returns (ITokenRegistry);

    function chainLink() external view returns (address);

    function bank() external view returns (IBank);

    function savingAccount() external view returns (ISavingAccount);

    function accounts() external view returns (IAccounts);

    function maxReserveRatio() external view returns (uint256);

    function midReserveRatio() external view returns (uint256);

    function minReserveRatio() external view returns (uint256);

    function rateCurveConstant() external view returns (uint256);

    function compoundSupplyRateWeights() external view returns (uint256);

    function compoundBorrowRateWeights() external view returns (uint256);

    function deFinerRate() external view returns (uint256);

    function liquidationThreshold() external view returns (uint256);

    function liquidationDiscountRatio() external view returns (uint256);

    function governor() external view returns (address);

    function updateMinMaxBorrowAPR(uint256 _minBorrowAPRInPercent, uint256 _maxBorrowAPRInPercent) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface ICToken {
    function supplyRatePerBlock() external view returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function redeem(uint256 redeemAmount) external returns (uint256);

    function exchangeRateStore() external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface ICETH {
    function mint() external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface ITokenRegistry {
    function initialize(
        address _gemGlobalConfig,
        address _poolRegistry,
        address _globalConfig
    ) external;

    function tokenInfo(address _token)
        external
        view
        returns (
            uint8 index,
            uint8 decimals,
            bool enabled,
            bool _isSupportedOnCompound, // compiler warning
            address cToken,
            address chainLinkOracle,
            uint256 borrowLTV
        );

    function addTokenByPoolRegistry(
        address _token,
        bool _isSupportedOnCompound,
        address _cToken,
        address _chainLinkOracle,
        uint256 _borrowLTV
    ) external;

    function getTokenDecimals(address) external view returns (uint8);

    function getCToken(address) external view returns (address);

    function getCTokens() external view returns (address[] calldata);

    function depositeMiningSpeeds(address _token) external view returns (uint256);

    function borrowMiningSpeeds(address _token) external view returns (uint256);

    function isSupportedOnCompound(address) external view returns (bool);

    function getTokens() external view returns (address[] calldata);

    function getTokenInfoFromAddress(address _token)
        external
        view
        returns (
            uint8,
            uint256,
            uint256,
            uint256
        );

    function getTokenInfoFromIndex(uint256 index)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        );

    function getTokenIndex(address _token) external view returns (uint8);

    function addressFromIndex(uint256 index) external view returns (address);

    function isTokenExist(address _token) external view returns (bool isExist);

    function isTokenEnabled(address _token) external view returns (bool);

    function priceFromAddress(address _token) external view returns (uint256);

    function updateMiningSpeed(
        address _token,
        uint256 _depositeMiningSpeed,
        uint256 _borrowMiningSpeed
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import { ActionType } from "../config/Constant.sol";

interface IBank {
    /* solhint-disable func-name-mixedcase */
    function BLOCKS_PER_YEAR() external view returns (uint256);

    function initialize(address _globalConfig, address _poolRegistry) external;

    function newRateIndexCheckpoint(address) external;

    function deposit(
        address _to,
        address _token,
        uint256 _amount
    ) external;

    function withdraw(
        address _from,
        address _token,
        uint256 _amount
    ) external returns (uint256);

    function borrow(
        address _from,
        address _token,
        uint256 _amount
    ) external;

    function repay(
        address _to,
        address _token,
        uint256 _amount
    ) external returns (uint256);

    function getDepositAccruedRate(address _token, uint256 _depositRateRecordStart) external view returns (uint256);

    function getBorrowAccruedRate(address _token, uint256 _borrowRateRecordStart) external view returns (uint256);

    function depositeRateIndex(address _token, uint256 _blockNum) external view returns (uint256);

    function borrowRateIndex(address _token, uint256 _blockNum) external view returns (uint256);

    function depositeRateIndexNow(address _token) external view returns (uint256);

    function borrowRateIndexNow(address _token) external view returns (uint256);

    function updateMining(address _token) external;

    function updateDepositFINIndex(address _token) external;

    function updateBorrowFINIndex(address _token) external;

    function update(
        address _token,
        uint256 _amount,
        ActionType _action
    ) external returns (uint256 compoundAmount);

    function depositFINRateIndex(address, uint256) external view returns (uint256);

    function borrowFINRateIndex(address, uint256) external view returns (uint256);

    function getTotalDepositStore(address _token) external view returns (uint256);

    function totalLoans(address _token) external view returns (uint256);

    function totalReserve(address _token) external view returns (uint256);

    function totalCompound(address _token) external view returns (uint256);

    function getBorrowRatePerBlock(address _token) external view returns (uint256);

    function getDepositRatePerBlock(address _token) external view returns (uint256);

    function getTokenState(address _token)
        external
        view
        returns (
            uint256 deposits,
            uint256 loans,
            uint256 reserveBalance,
            uint256 remainingAssets
        );

    function configureMaxUtilToCalcBorrowAPR(uint256 _maxBorrowAPR) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface ISavingAccount {
    function initialize(
        address[] memory _tokenAddresses,
        address[] memory _cTokenAddresses,
        address _globalConfig,
        address _poolRegistry,
        uint256 _poolId
    ) external;

    function configure(
        address _baseToken,
        address _miningToken,
        uint256 _maturesOn
    ) external;

    function toCompound(address, uint256) external;

    function fromCompound(address, uint256) external;

    function approveAll(address _token) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface IAccounts {
    function initialize(address _globalConfig, address _gemGlobalConfig) external;

    function deposit(
        address,
        address,
        uint256
    ) external;

    function borrow(
        address,
        address,
        uint256
    ) external;

    function getBorrowPrincipal(address, address) external view returns (uint256);

    function withdraw(
        address,
        address,
        uint256
    ) external returns (uint256);

    function repay(
        address,
        address,
        uint256
    ) external returns (uint256);

    function getDepositPrincipal(address _accountAddr, address _token) external view returns (uint256);

    function getDepositBalanceCurrent(address _token, address _accountAddr) external view returns (uint256);

    function getDepositInterest(address _account, address _token) external view returns (uint256);

    function getBorrowInterest(address _accountAddr, address _token) external view returns (uint256);

    function getBorrowBalanceCurrent(address _token, address _accountAddr)
        external
        view
        returns (uint256 borrowBalance);

    function getBorrowETH(address _accountAddr) external view returns (uint256 borrowETH);

    function getDepositETH(address _accountAddr) external view returns (uint256 depositETH);

    function getBorrowPower(address _borrower) external view returns (uint256 power);

    function liquidate(
        address _liquidator,
        address _borrower,
        address _borrowedToken,
        address _collateralToken
    ) external returns (uint256, uint256);

    function claim(address _account) external returns (uint256);

    function claimForToken(address _account, address _token) external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

/* solhint-disable */
interface IConstant {
    function ETH_ADDR() external view returns (address);

    function INT_UNIT() external view returns (uint256);

    function ACCURACY() external view returns (uint256);

    function BLOCKS_PER_YEAR() external view returns (uint256);
}
/* solhint-enable */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
                /// @solidity memory-safe-assembly
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