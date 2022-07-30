//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC20.sol';
import './IERC20Metadata.sol';
import './SafeERC20.sol';
import './Pausable.sol';
import './AccessControl.sol';
import './IStrategy.sol';

/**
 *
 * @title DSF Protocol
 *
 * @notice Contract for Convex&Curve protocols optimize.
 * Users can use this contract for optimize yield and gas.
 *
 *
 * @dev DSF is main contract.
 * Contract does not store user funds.
 * All user funds goes to Convex&Curve pools.
 *
 */

contract DSF is ERC20, Pausable, AccessControl {
    using SafeERC20 for IERC20Metadata;

    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');

    struct PendingWithdrawal {
        uint256 lpShares;
        uint256[3] tokenAmounts;
    }

    struct PoolInfo {
        IStrategy strategy;
        uint256 startTime;
        uint256 lpShares;
    }

    uint8 public constant POOL_ASSETS = 3;
    uint256 public constant LP_RATIO_MULTIPLIER = 1e18;
    uint256 public constant FEE_DENOMINATOR = 1000;
    uint256 public constant MIN_LOCK_TIME = 1 days;
    uint256 public constant FUNDS_DENOMINATOR = 10_000;
    uint8 public constant ALL_WITHDRAWAL_TYPES_MASK = uint8(3); // Binary 11 = 2^0 + 2^1;

    PoolInfo[] internal _poolInfo;
    uint256 public defaultDepositPid;
    uint256 public defaultWithdrawPid;
    uint8 public availableWithdrawalTypes;

    address[POOL_ASSETS] public tokens;
    uint256[POOL_ASSETS] public decimalsMultipliers;

    mapping(address => uint256[POOL_ASSETS]) internal _pendingDeposits;
    mapping(address => PendingWithdrawal) internal _pendingWithdrawals;

    uint256 public totalDeposited = 0;
    uint256 public managementFee = 100; // 10%
    bool public launched = false;

    event CreatedPendingDeposit(address indexed depositor, uint256[POOL_ASSETS] amounts);
    event CreatedPendingWithdrawal(
        address indexed withdrawer,
        uint256 lpShares,
        uint256[POOL_ASSETS] tokenAmounts
    );
    event Deposited(address indexed depositor, uint256[POOL_ASSETS] amounts, uint256 lpShares);
    event Withdrawn(
        address indexed withdrawer,
        IStrategy.WithdrawalType withdrawalType,
        uint256[POOL_ASSETS] tokenAmounts,
        uint256 lpShares,
        uint128 tokenIndex
    );

    event AddedPool(uint256 pid, address strategyAddr, uint256 startTime);
    event FailedDeposit(address indexed depositor, uint256[POOL_ASSETS] amounts, uint256 lpShares);
    event FailedWithdrawal(
        address indexed withdrawer,
        uint256[POOL_ASSETS] amounts,
        uint256 lpShares
    );
    event SetDefaultDepositPid(uint256 pid);
    event SetDefaultWithdrawPid(uint256 pid);
    event ClaimedAllManagementFee(uint256 feeValue);
    event AutoCompoundAll();

    modifier startedPool() {
        require(_poolInfo.length != 0, 'DSF: pool not existed!');
        require(
            block.timestamp >= _poolInfo[defaultDepositPid].startTime,
            'DSF: default deposit pool not started yet!'
        );
        require(
            block.timestamp >= _poolInfo[defaultWithdrawPid].startTime,
            'DSF: default withdraw pool not started yet!'
        );
        _;
    }

    constructor(address[POOL_ASSETS] memory _tokens) ERC20('DSFLP', 'DSFLP') {
        tokens = _tokens;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);

        for (uint256 i; i < POOL_ASSETS; i++) {
            uint256 decimals = IERC20Metadata(tokens[i]).decimals();
            if (decimals < 18) {
                decimalsMultipliers[i] = 10**(18 - decimals);
            } else {
                decimalsMultipliers[i] = 1;
            }
        }

        availableWithdrawalTypes = ALL_WITHDRAWAL_TYPES_MASK;
    }

    function poolInfo(uint256 pid) external view returns (PoolInfo memory) {
        return _poolInfo[pid];
    }

    function pendingDeposits(address user) external view returns (uint256[POOL_ASSETS] memory) {
        return _pendingDeposits[user];
    }

    function pendingDepositsToken(address user, uint256 tokenIndex) external view returns (uint256) {
        return _pendingDeposits[user][tokenIndex];
    }

    function pendingWithdrawals(address user) external view returns (PendingWithdrawal memory) {
        return _pendingWithdrawals[user];
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setAvailableWithdrawalTypes(uint8 newAvailableWithdrawalTypes)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            newAvailableWithdrawalTypes <= ALL_WITHDRAWAL_TYPES_MASK,
            'DSF: wrong available withdrawal types'
        );
        availableWithdrawalTypes = newAvailableWithdrawalTypes;
    }

    /**
     * @dev update managementFee, this is a DSF commission from protocol profit
     * @param  newManagementFee - minAmount 0, maxAmount FEE_DENOMINATOR - 1
     */
    function setManagementFee(uint256 newManagementFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newManagementFee < FEE_DENOMINATOR, 'DSF: wrong fee');
        managementFee = newManagementFee;
    }

    /**
     * @dev Returns managementFee for strategy's when contract sell rewards
     * @return Returns commission on the amount of profit in the transaction
     * @param amount - amount of profit for calculate managementFee
     */
    function calcManagementFee(uint256 amount) external view returns (uint256) {
        return (amount * managementFee) / FEE_DENOMINATOR;
    }

    /**
     * @dev Claims managementFee from all active strategies
     */
    function claimAllManagementFee() external {
        uint256 feeTotalValue;
        for (uint256 i = 0; i < _poolInfo.length; i++) {
            feeTotalValue += _poolInfo[i].strategy.claimManagementFees();
        }

        emit ClaimedAllManagementFee(feeTotalValue);
    }

    function autoCompoundAll() external {
        for (uint256 i = 0; i < _poolInfo.length; i++) {
            _poolInfo[i].strategy.autoCompound();
        }
        emit AutoCompoundAll();
    }

    /**
     * @dev Returns total holdings for all pools (strategy's)
     * @return Returns sum holdings (USD) for all pools
     */
    function totalHoldings() public view returns (uint256) {
        uint256 length = _poolInfo.length;
        uint256 totalHold = 0;
        for (uint256 pid = 0; pid < length; pid++) {
            totalHold += _poolInfo[pid].strategy.totalHoldings();
        }
        return totalHold;
    }

    /**
     * @dev Returns price depends on the income of users
     * @return Returns currently price of ZLP (1e18 = 1$)
     */
    function lpPrice() external view returns (uint256) {
        return (totalHoldings() * 1e18) / totalSupply();
    }

    /**
     * @dev Returns number of pools
     * @return number of pools
     */
    function poolCount() external view returns (uint256) {
        return _poolInfo.length;
    }

    /**
     * @dev in this func user sends funds to the contract and then waits for the completion
     * of the transaction for all users
     * @param amounts - array of deposit amounts by user
     */
    function delegateDeposit(uint256[3] memory amounts) external whenNotPaused {
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] > 0) {
                IERC20Metadata(tokens[i]).safeTransferFrom(_msgSender(), address(this), amounts[i]);
                _pendingDeposits[_msgSender()][i] += amounts[i];
            }
        }

        emit CreatedPendingDeposit(_msgSender(), amounts);
    }

    /**
     * @dev in this func user sends pending withdraw to the contract and then waits
     * for the completion of the transaction for all users
     * @param  lpShares - amount of ZLP for withdraw
     * @param tokenAmounts - array of amounts stablecoins that user want minimum receive
     */
    function delegateWithdrawal(uint256 lpShares, uint256[POOL_ASSETS] memory tokenAmounts)
        external
        whenNotPaused
    {
        require(lpShares > 0, 'DSF: lpAmount must be higher 0');

        PendingWithdrawal memory withdrawal;
        address userAddr = _msgSender();

        withdrawal.lpShares = lpShares;
        withdrawal.tokenAmounts = tokenAmounts;

        _pendingWithdrawals[userAddr] = withdrawal;

        emit CreatedPendingWithdrawal(userAddr, lpShares, tokenAmounts);
    }

    /**
     * @dev DSF protocol owner complete all active pending deposits of users
     * @param userList - dev send array of users from pending to complete
     */
    function completeDeposits(address[] memory userList)
        external
        onlyRole(OPERATOR_ROLE)
        startedPool
    {
        IStrategy strategy = _poolInfo[defaultDepositPid].strategy;
        uint256 currentTotalHoldings = totalHoldings();

        uint256 newHoldings = 0;
        uint256[3] memory totalAmounts;
        uint256[] memory userCompleteHoldings = new uint256[](userList.length);
        for (uint256 i = 0; i < userList.length; i++) {
            newHoldings = 0;

            for (uint256 x = 0; x < totalAmounts.length; x++) {
                uint256 userTokenDeposit = _pendingDeposits[userList[i]][x];
                totalAmounts[x] += userTokenDeposit;
                newHoldings += userTokenDeposit * decimalsMultipliers[x];
            }
            userCompleteHoldings[i] = newHoldings;
        }

        newHoldings = 0;
        for (uint256 y = 0; y < POOL_ASSETS; y++) {
            uint256 totalTokenAmount = totalAmounts[y];
            if (totalTokenAmount > 0) {
                newHoldings += totalTokenAmount * decimalsMultipliers[y];
                IERC20Metadata(tokens[y]).safeTransfer(address(strategy), totalTokenAmount);
            }
        }
        uint256 totalDepositedNow = strategy.deposit(totalAmounts);
        require(totalDepositedNow > 0, 'DSF: too low deposit!');
        uint256 lpShares = 0;
        uint256 addedHoldings = 0;
        uint256 userDeposited = 0;

        for (uint256 z = 0; z < userList.length; z++) {
            userDeposited = (totalDepositedNow * userCompleteHoldings[z]) / newHoldings;
            address userAddr = userList[z];
            if (totalSupply() == 0) {
                lpShares = userDeposited;
            } else {
                lpShares = (totalSupply() * userDeposited) / (currentTotalHoldings + addedHoldings);
            }
            addedHoldings += userDeposited;
            _mint(userAddr, lpShares);
            _poolInfo[defaultDepositPid].lpShares += lpShares;
            emit Deposited(userAddr, _pendingDeposits[userAddr], lpShares);

            // remove deposit from list
            delete _pendingDeposits[userAddr];
        }
        totalDeposited += addedHoldings;
    }

    /**
     * @dev DSF protocol owner complete all active pending withdrawals of users
     * @param userList - array of users from pending withdraw to complete
     */
    function completeWithdrawals(address[] memory userList)
        external
        onlyRole(OPERATOR_ROLE)
        startedPool
    {
        require(userList.length > 0, 'DSF: there are no pending withdrawals requests');

        IStrategy strategy = _poolInfo[defaultWithdrawPid].strategy;

        address user;
        PendingWithdrawal memory withdrawal;
        for (uint256 i = 0; i < userList.length; i++) {
            user = userList[i];
            withdrawal = _pendingWithdrawals[user];

            if (balanceOf(user) < withdrawal.lpShares) {
                emit FailedWithdrawal(user, withdrawal.tokenAmounts, withdrawal.lpShares);
                delete _pendingWithdrawals[user];
                continue;
            }

            if (
                !(
                    strategy.withdraw(
                        user,
                        calcLpRatioSafe(
                            withdrawal.lpShares,
                            _poolInfo[defaultWithdrawPid].lpShares
                        ),
                        withdrawal.tokenAmounts,
                        IStrategy.WithdrawalType.Base,
                        0
                    )
                )
            ) {
                emit FailedWithdrawal(user, withdrawal.tokenAmounts, withdrawal.lpShares);
                delete _pendingWithdrawals[user];
                continue;
            }

            uint256 userDeposit = (totalDeposited * withdrawal.lpShares) / totalSupply();
            _burn(user, withdrawal.lpShares);
            _poolInfo[defaultWithdrawPid].lpShares -= withdrawal.lpShares;
            totalDeposited -= userDeposit;

            emit Withdrawn(
                user,
                IStrategy.WithdrawalType.Base,
                withdrawal.tokenAmounts,
                withdrawal.lpShares,
                0
            );
            delete _pendingWithdrawals[user];
        }
    }

    function calcLpRatioSafe(uint256 outLpShares, uint256 strategyLpShares)
        internal
        pure
        returns (uint256 lpShareRatio)
    {
        lpShareRatio = (outLpShares * LP_RATIO_MULTIPLIER) / strategyLpShares;
        require(
            lpShareRatio > 0 && lpShareRatio <= LP_RATIO_MULTIPLIER,
            'DSF: Wrong out lp Ratio'
        );
    }

    function completeWithdrawalsOptimized(address[] memory userList)
        external
        onlyRole(OPERATOR_ROLE)
        startedPool
    {
        require(userList.length > 0, 'DSF: there are no pending withdrawals requests');

        IStrategy strategy = _poolInfo[defaultWithdrawPid].strategy;

        uint256 lpSharesTotal;
        uint256[POOL_ASSETS] memory minAmountsTotal;

        uint256 i;
        address user;
        PendingWithdrawal memory withdrawal;
        for (i = 0; i < userList.length; i++) {
            user = userList[i];
            withdrawal = _pendingWithdrawals[user];

            if (balanceOf(user) < withdrawal.lpShares) {
                emit FailedWithdrawal(user, withdrawal.tokenAmounts, withdrawal.lpShares);
                delete _pendingWithdrawals[user];
                continue;
            }

            lpSharesTotal += withdrawal.lpShares;
            minAmountsTotal[0] += withdrawal.tokenAmounts[0];
            minAmountsTotal[1] += withdrawal.tokenAmounts[1];
            minAmountsTotal[2] += withdrawal.tokenAmounts[2];

            emit Withdrawn(
                user,
                IStrategy.WithdrawalType.Base,
                withdrawal.tokenAmounts,
                withdrawal.lpShares,
                0
            );
        }

        require(
            lpSharesTotal <= _poolInfo[defaultWithdrawPid].lpShares,
            'DSF: Insufficient pool LP shares'
        );

        uint256[POOL_ASSETS] memory prevBalances;
        for (i = 0; i < 3; i++) {
            prevBalances[i] = IERC20Metadata(tokens[i]).balanceOf(address(this));
        }

        if (
            !strategy.withdraw(
                address(this),
                calcLpRatioSafe(lpSharesTotal, _poolInfo[defaultWithdrawPid].lpShares),
                minAmountsTotal,
                IStrategy.WithdrawalType.Base,
                0
            )
        ) {
            for (i = 0; i < userList.length; i++) {
                user = userList[i];
                withdrawal = _pendingWithdrawals[user];

                emit FailedWithdrawal(user, withdrawal.tokenAmounts, withdrawal.lpShares);
                delete _pendingWithdrawals[user];
            }
            return;
        }

        uint256[POOL_ASSETS] memory diffBalances;
        for (i = 0; i < 3; i++) {
            diffBalances[i] = IERC20Metadata(tokens[i]).balanceOf(address(this)) - prevBalances[i];
        }

        for (i = 0; i < userList.length; i++) {
            user = userList[i];
            withdrawal = _pendingWithdrawals[user];

            uint256 userDeposit = (totalDeposited * withdrawal.lpShares) / totalSupply();
            _burn(user, withdrawal.lpShares);
            _poolInfo[defaultWithdrawPid].lpShares -= withdrawal.lpShares;
            totalDeposited -= userDeposit;

            uint256 transferAmount;
            for (uint256 j = 0; j < 3; j++) {
                transferAmount = (diffBalances[j] * withdrawal.lpShares) / lpSharesTotal;
                if(transferAmount > 0) {
                    IERC20Metadata(tokens[j]).safeTransfer(
                        user,
                        transferAmount
                    );
                }
            }

            delete _pendingWithdrawals[user];
        }
    }

    /**
     * @dev deposit in one tx, without waiting complete by dev
     * @return Returns amount of lpShares minted for user
     * @param amounts - user send amounts of stablecoins to deposit
     */
    function deposit(uint256[POOL_ASSETS] memory amounts)
        external
        whenNotPaused
        startedPool
        returns (uint256)
    {
        IStrategy strategy = _poolInfo[defaultDepositPid].strategy;
        uint256 holdings = totalHoldings();

        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] > 0) {
                IERC20Metadata(tokens[i]).safeTransferFrom(
                    _msgSender(),
                    address(strategy),
                    amounts[i]
                );
            }
        }
        uint256 newDeposited = strategy.deposit(amounts);
        require(newDeposited > 0, 'DSF: too low deposit!');

        uint256 lpShares = 0;
        if (totalSupply() == 0) {
            lpShares = newDeposited;
        } else {
            lpShares = (totalSupply() * newDeposited) / holdings;
        }
        _mint(_msgSender(), lpShares);
        _poolInfo[defaultDepositPid].lpShares += lpShares;
        totalDeposited += newDeposited;

        emit Deposited(_msgSender(), amounts, lpShares);
        return lpShares;
    }

    /**
     * @dev withdraw in one tx, without waiting complete by dev
     * @param lpShares - amount of ZLP for withdraw
     * @param tokenAmounts -  array of amounts stablecoins that user want minimum receive
     */
    function withdraw(
        uint256 lpShares,
        uint256[POOL_ASSETS] memory tokenAmounts,
        IStrategy.WithdrawalType withdrawalType,
        uint128 tokenIndex
    ) external whenNotPaused startedPool {
        require(
            checkBit(availableWithdrawalTypes, uint8(withdrawalType)),
            'DSF: withdrawal type not available'
        );
        IStrategy strategy = _poolInfo[defaultWithdrawPid].strategy;
        address userAddr = _msgSender();

        require(balanceOf(userAddr) >= lpShares, 'DSF: not enough LP balance');
        require(
            strategy.withdraw(
                userAddr,
                calcLpRatioSafe(lpShares, _poolInfo[defaultWithdrawPid].lpShares),
                tokenAmounts,
                withdrawalType,
                tokenIndex
            ),
            'DSF: incorrect withdraw params'
        );

        uint256 userDeposit = (totalDeposited * lpShares) / totalSupply();
        _burn(userAddr, lpShares);
        _poolInfo[defaultWithdrawPid].lpShares -= lpShares;

        totalDeposited -= userDeposit;

        emit Withdrawn(userAddr, withdrawalType, tokenAmounts, lpShares, tokenIndex);
    }

    function calcWithdrawOneCoin(uint256 lpShares, uint128 tokenIndex)
        external
        view
        returns (uint256 tokenAmount)
    {
        require(lpShares <= balanceOf(_msgSender()), 'DSF: not enough LP balance');

        uint256 lpShareRatio = calcLpRatioSafe(lpShares, _poolInfo[defaultWithdrawPid].lpShares);
        return _poolInfo[defaultWithdrawPid].strategy.calcWithdrawOneCoin(lpShareRatio, tokenIndex);
    }

    function calcSharesAmount(uint256[3] memory tokenAmounts, bool isDeposit)
        external
        view
        returns (uint256 lpShares)
    {
        return _poolInfo[defaultWithdrawPid].strategy.calcSharesAmount(tokenAmounts, isDeposit);
    }

    /**
     * @dev add a new pool, deposits in the new pool are blocked for one day for safety
     * @param _strategyAddr - the new pool strategy address
     */

    function addPool(address _strategyAddr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_strategyAddr != address(0), 'DSF: zero strategy addr');
        uint256 startTime = block.timestamp + (launched ? MIN_LOCK_TIME : 0);
        _poolInfo.push(
            PoolInfo({ strategy: IStrategy(_strategyAddr), startTime: startTime, lpShares: 0 })
        );
        emit AddedPool(_poolInfo.length - 1, _strategyAddr, startTime);
    }

    /**
     * @dev set a default pool for deposit funds
     * @param _newPoolId - new pool id
     */
    function setDefaultDepositPid(uint256 _newPoolId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newPoolId < _poolInfo.length, 'DSF: incorrect default deposit pool id');

        defaultDepositPid = _newPoolId;
        emit SetDefaultDepositPid(_newPoolId);
    }

    /**
     * @dev set a default pool for withdraw funds
     * @param _newPoolId - new pool id
     */
    function setDefaultWithdrawPid(uint256 _newPoolId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newPoolId < _poolInfo.length, 'DSF: incorrect default withdraw pool id');

        defaultWithdrawPid = _newPoolId;
        emit SetDefaultWithdrawPid(_newPoolId);
    }

    function launch() external onlyRole(DEFAULT_ADMIN_ROLE) {
        launched = true;
    }

    /**
     * @dev dev can transfer funds from few strategy's to one strategy for better APY
     * @param _strategies - array of strategy's, from which funds are withdrawn
     * @param withdrawalsPercents - A percentage of the funds that should be transfered
     * @param _receiverStrategyId - number strategy, to which funds are deposited
     */
    function moveFundsBatch(
        uint256[] memory _strategies,
        uint256[] memory withdrawalsPercents,
        uint256 _receiverStrategyId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _strategies.length == withdrawalsPercents.length,
            'DSF: incorrect arguments for the moveFundsBatch'
        );
        require(_receiverStrategyId < _poolInfo.length, 'DSF: incorrect a reciver strategy ID');

        uint256[POOL_ASSETS] memory tokenBalance;
        for (uint256 y = 0; y < POOL_ASSETS; y++) {
            tokenBalance[y] = IERC20Metadata(tokens[y]).balanceOf(address(this));
        }

        uint256 pid;
        uint256 DSFLp;
        for (uint256 i = 0; i < _strategies.length; i++) {
            pid = _strategies[i];
            DSFLp += _moveFunds(pid, withdrawalsPercents[i]);
        }

        uint256[POOL_ASSETS] memory tokensRemainder;
        for (uint256 y = 0; y < POOL_ASSETS; y++) {
            tokensRemainder[y] =
                IERC20Metadata(tokens[y]).balanceOf(address(this)) -
                tokenBalance[y];
            if (tokensRemainder[y] > 0) {
                IERC20Metadata(tokens[y]).safeTransfer(
                    address(_poolInfo[_receiverStrategyId].strategy),
                    tokensRemainder[y]
                );
            }
        }

        _poolInfo[_receiverStrategyId].lpShares += DSFLp;

        require(
            _poolInfo[_receiverStrategyId].strategy.deposit(tokensRemainder) > 0,
            'DSF: Too low amount!'
        );
    }

    function _moveFunds(uint256 pid, uint256 withdrawAmount) private returns (uint256) {
        uint256 currentLpAmount;

        if (withdrawAmount == FUNDS_DENOMINATOR) {
            _poolInfo[pid].strategy.withdrawAll();

            currentLpAmount = _poolInfo[pid].lpShares;
            _poolInfo[pid].lpShares = 0;
        } else {
            currentLpAmount = (_poolInfo[pid].lpShares * withdrawAmount) / FUNDS_DENOMINATOR;
            uint256[POOL_ASSETS] memory minAmounts;

            _poolInfo[pid].strategy.withdraw(
                address(this),
                calcLpRatioSafe(currentLpAmount, _poolInfo[pid].lpShares),
                minAmounts,
                IStrategy.WithdrawalType.Base,
                0
            );
            _poolInfo[pid].lpShares = _poolInfo[pid].lpShares - currentLpAmount;
        }

        return currentLpAmount;
    }

    /**
     * @dev user remove his active pending deposit
     */
    function removePendingDeposit() external {
        for (uint256 i = 0; i < POOL_ASSETS; i++) {
            if (_pendingDeposits[_msgSender()][i] > 0) {
                IERC20Metadata(tokens[i]).safeTransfer(
                    _msgSender(),
                    _pendingDeposits[_msgSender()][i]
                );
            }
        }
        delete _pendingDeposits[_msgSender()];
    }

    function removePendingWithdrawal() external {
        delete _pendingWithdrawals[_msgSender()];
    }

    /**
     * @dev governance can withdraw all stuck funds in emergency case
     * @param _token - IERC20Metadata token that should be fully withdraw from DSF
     */
    function withdrawStuckToken(IERC20Metadata _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 tokenBalance = _token.balanceOf(address(this));
        if(tokenBalance > 0) {
            _token.safeTransfer(_msgSender(), tokenBalance);
        }
    }

    /**
     * @dev governance can add new operator for complete pending deposits and withdrawals
     * @param _newOperator - address that governance add in list of operators
     */
    function updateOperator(address _newOperator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(OPERATOR_ROLE, _newOperator);
    }

    // Get bit value at position
    function checkBit(uint8 mask, uint8 bit) internal pure returns (bool) {
        return mask & (0x01 << bit) != 0;
    }
}