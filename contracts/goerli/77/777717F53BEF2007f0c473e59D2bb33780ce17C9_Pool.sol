/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IERC20 {
    function balanceOf(address) external view returns(uint);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    function transfer(address, uint) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IFactory {
    function getFee() external view returns (address to, uint feeMantissa);
}

/// @title Pool
/// @author Moaz Mohsen & Nour Haridy
/// @notice A Surge lending pool for a single collateral and loan token pair
/// @dev This contract asssumes that the collateral and loan tokens are valid non-rebasing ERC20-compliant tokens
contract Pool {

    IFactory public immutable FACTORY;
    IERC20 public immutable COLLATERAL_TOKEN;
    IERC20 public immutable LOAN_TOKEN;
    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    uint private constant RATE_CEILING = 100e18; // 10,000% borrow APR
    uint public immutable MIN_RATE;
    uint public immutable SURGE_RATE;
    uint public immutable MAX_RATE;
    uint public immutable MAX_COLLATERAL_RATIO_MANTISSA;
    uint public immutable SURGE_MANTISSA;
    uint public immutable COLLATERAL_RATIO_FALL_DURATION;
    uint public immutable COLLATERAL_RATIO_RECOVERY_DURATION;
    bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 private constant TRANSFER_FROM_SELECTOR = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    uint public lastCollateralRatioMantissa;
    uint public debtSharesSupply;
    mapping (address => uint) public debtSharesBalanceOf;
    uint public lastTotalDebt;
    uint public lastAccrueInterestTime;
    uint public totalSupply;
    mapping (address => mapping (address => uint)) public allowance;
    mapping (address => uint) public balanceOf;
    mapping (address => uint) public collateralBalanceOf;

    constructor(
        string memory _symbol,
        string memory _name,
        IERC20 _collateralToken,
        IERC20 _loanToken,
        uint _maxCollateralRatioMantissa,
        uint _surgeMantissa,
        uint _collateralRatioFallDuration,
        uint _collateralRatioRecoveryDuration,
        uint _minRateMantissa,
        uint _surgeRateMantissa,
        uint _maxRateMantissa
    ) {
        require(_collateralToken != _loanToken, "Pool: collateral and loan tokens are the same");
        require(_collateralRatioFallDuration > 0, "Pool: _collateralRatioFallDuration too low");
        require(_collateralRatioRecoveryDuration > 0, "Pool: _collateralRatioRecoveryDuration too low");
        require(_maxCollateralRatioMantissa > 0, "Pool: _maxCollateralRatioMantissa too low");
        require(_surgeMantissa < 1e18, "Pool: _surgeMantissa too high");
        require(_minRateMantissa <= _surgeRateMantissa, "Pool: _minRateMantissa too high");
        require(_surgeRateMantissa <= _maxRateMantissa, "Pool: _surgeRateMantissa too high");
        require(_maxRateMantissa <= RATE_CEILING, "Pool: _maxRateMantissa too high");
        symbol = _symbol;
        name = _name;
        FACTORY = IFactory(msg.sender);
        COLLATERAL_TOKEN = _collateralToken;
        LOAN_TOKEN = _loanToken;
        MAX_COLLATERAL_RATIO_MANTISSA = _maxCollateralRatioMantissa;
        SURGE_MANTISSA = _surgeMantissa;
        COLLATERAL_RATIO_FALL_DURATION = _collateralRatioFallDuration;
        COLLATERAL_RATIO_RECOVERY_DURATION = _collateralRatioRecoveryDuration;
        lastCollateralRatioMantissa = _maxCollateralRatioMantissa;
        MIN_RATE = _minRateMantissa;
        SURGE_RATE = _surgeRateMantissa;
        MAX_RATE = _maxRateMantissa;
    }

    function safeTransfer(IERC20 token, address to, uint value) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(TRANSFER_SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Pool: TRANSFER_FAILED');
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(TRANSFER_FROM_SELECTOR, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Pool: TRANSFER_FROM_FAILED');
    }

    /// @notice Gets the current state of pool variables based on the current time
    /// @param _loanTokenBalance The current balance of the loan token in the pool
    /// @param _feeMantissa The fee to be charged on interest accrual
    /// @param _lastCollateralRatioMantissa The collateral ratio at the last interest accrual
    /// @param _totalSupply The total supply of pool tokens at the last interest accrual
    /// @param _lastAccrueInterestTime The last time interest was accrued
    /// @param _totalDebt The total debt of the pool at the last interest accrual
    /// @return _currentTotalSupply The current total supply of pool tokens
    /// @return _accruedFeeShares The accrued fee shares to be transferred to the fee recipient
    /// @return _currentCollateralRatioMantissa The current collateral ratio
    /// @return _currentTotalDebt The current total debt of the pool
    /// @dev This view function behaves as a pure function with the exception of immutable variables (which are constant)
    function getCurrentState(
        uint _loanTokenBalance,
        uint _feeMantissa,
        uint _lastCollateralRatioMantissa,
        uint _totalSupply,
        uint _lastAccrueInterestTime,
        uint _totalDebt
        ) internal view returns (
            uint _currentTotalSupply,
            uint _accruedFeeShares,
            uint _currentCollateralRatioMantissa,
            uint _currentTotalDebt
        ) {
        
        // 1. Set default return values
        _currentTotalSupply = _totalSupply;
        _currentTotalDebt = _totalDebt;
        _currentCollateralRatioMantissa = _lastCollateralRatioMantissa;
        // _accruedFeeShares = 0;

        // 2. Get the time passed since the last interest accrual
        uint _timeDelta = block.timestamp - _lastAccrueInterestTime;
        
        // 3. If the time passed is 0, return the current values
        if(_timeDelta == 0) return (_currentTotalSupply, _accruedFeeShares, _currentCollateralRatioMantissa, _currentTotalDebt);
        
        // 4. Calculate the supplied value
        uint _supplied = _totalDebt + _loanTokenBalance;
        // 5. Calculate the utilization
        uint _util = getUtilizationMantissa(_totalDebt, _supplied);

        // 6. Calculate the collateral ratio
        _currentCollateralRatioMantissa = getCollateralRatioMantissa(
            _util,
            _lastAccrueInterestTime,
            block.timestamp,
            _lastCollateralRatioMantissa,
            COLLATERAL_RATIO_FALL_DURATION,
            COLLATERAL_RATIO_RECOVERY_DURATION,
            MAX_COLLATERAL_RATIO_MANTISSA,
            SURGE_MANTISSA
        );

        // 7. If there is no debt, return the current values
        if(_totalDebt == 0) return (_currentTotalSupply, _accruedFeeShares, _currentCollateralRatioMantissa, _currentTotalDebt);

        // 8. Calculate the borrow rate
        uint _borrowRate = getBorrowRateMantissa(_util, SURGE_MANTISSA, MIN_RATE, SURGE_RATE, MAX_RATE);
        // 9. Calculate the interest
        uint _interest = _totalDebt * _borrowRate * _timeDelta / (365 days * 1e18); // does the optimizer optimize this? or should it be a constant?
        // 10. Update the total debt
        _currentTotalDebt += _interest;
        
        // 11. If there is no fee, return the current values
        if(_feeMantissa == 0) return (_currentTotalSupply, _accruedFeeShares, _currentCollateralRatioMantissa, _currentTotalDebt);
        // 12. Calculate the fee
        uint fee = _interest * _feeMantissa / 1e18;
        // 13. Calculate the accrued fee shares
        _accruedFeeShares = fee * _totalSupply / _supplied; // if supplied is 0, we will have returned at step 7
        // 14. Update the total supply
        _currentTotalSupply += _accruedFeeShares;
    }

    /// @notice Gets the current borrow rate in mantissa (scaled by 1e18)
    /// @param _util The utilization in mantissa (scaled by 1e18)
    /// @param _surgeMantissa The utilization at which the borrow rate will be at the surge rate in mantissa (scaled by 1e18)
    /// @param _minRateMantissa The minimum borrow rate at 0% utilization in mantissa (scaled by 1e18)
    /// @param _surgeRateMantissa The borrow rate at the surge utilization in mantissa (scaled by 1e18)
    /// @param _maxRateMantissa The maximum borrow rate at 100% utilization in mantissa (scaled by 1e18)
    /// @return uint The borrow rate in mantissa (scaled by 1e18)
    function getBorrowRateMantissa(uint _util, uint _surgeMantissa, uint _minRateMantissa, uint _surgeRateMantissa, uint _maxRateMantissa) internal pure returns (uint) {
        if(_util <= _surgeMantissa) {
            return (_surgeRateMantissa - _minRateMantissa) * 1e18 * _util / _surgeMantissa / 1e18 + _minRateMantissa; // is this optimized by the optimized?
        } else {
            uint excessUtil = _util - _surgeMantissa;
            return (_maxRateMantissa - _surgeRateMantissa) * 1e18 * excessUtil / (1e18 - _surgeMantissa) / 1e18 + _surgeRateMantissa; // is this optimized by the optimizer?
        }
    }

    /// @notice Gets the current pool utilization rate in mantissa (scaled by 1e18)
    /// @param _totalDebt The total debt of the pool
    /// @param _supplied The total supplied loan tokens of the pool
    /// @return uint The pool utilization rate in mantissa (scaled by 1e18)
    function getUtilizationMantissa(uint _totalDebt, uint _supplied) internal pure returns (uint) {
        if(_supplied == 0) return 0;
        return _totalDebt * 1e18 / _supplied;
    }

    /// @notice Converts a loan token amount to shares
    /// @param _tokenAmount The loan token amount to convert
    /// @param _supplied The total supplied loan tokens of the pool
    /// @param _sharesTotalSupply The total supply of shares of the pool
    /// @param roundUpCheck Whether to check and round up the shares amount
    /// @return uint The shares amount
    function tokenToShares (uint _tokenAmount, uint _supplied, uint _sharesTotalSupply, bool roundUpCheck) internal pure returns (uint) {
        if(_supplied == 0) return _tokenAmount;
        uint shares = _tokenAmount * _sharesTotalSupply / _supplied;
        if(roundUpCheck && shares * _supplied < _tokenAmount * _sharesTotalSupply) shares++;
        return shares;
    }

    /// @notice Gets the pool collateral ratio in mantissa (scaled by 1e18)
    /// @param _util The utilization in mantissa (scaled by 1e18)
    /// @param _lastAccrueInterestTime The last time the pool accrued interest
    /// @param _now The current time
    /// @param _lastCollateralRatioMantissa The last collateral ratio of the pool in mantissa (scaled by 1e18)
    /// @param _collateralRatioFallDuration The duration of the collateral ratio fall from max to 0 in seconds
    /// @param _collateralRatioRecoveryDuration The duration of the collateral ratio recovery from 0 to max in seconds
    /// @param _maxCollateralRatioMantissa The maximum collateral ratio of the pool in mantissa (scaled by 1e18)
    /// @param _surgeMantissa The utilization at which the surge threshold is triggered in mantissa (scaled by 1e18)
    /// @return uint The pool collateral ratio in mantissa (scaled by 1e18)
    function getCollateralRatioMantissa(
        uint _util,
        uint _lastAccrueInterestTime,
        uint _now,
        uint _lastCollateralRatioMantissa,
        uint _collateralRatioFallDuration,
        uint _collateralRatioRecoveryDuration,
        uint _maxCollateralRatioMantissa,
        uint _surgeMantissa
        ) internal pure returns (uint) {
        unchecked {
            if(_lastAccrueInterestTime == _now) return _lastCollateralRatioMantissa;
            
            // If utilization is less than or equal to surge, we are increasing collateral ratio
            if(_util <= _surgeMantissa) {
                // The collateral ratio can only increase if it is less than the max collateral ratio
                if(_lastCollateralRatioMantissa == _maxCollateralRatioMantissa) return _lastCollateralRatioMantissa;

                // If the collateral ratio can increase, we calculate the increase
                uint timeDelta = _now - _lastAccrueInterestTime;
                uint change = timeDelta * _maxCollateralRatioMantissa / _collateralRatioRecoveryDuration;

                // If the change in collateral ratio is greater than the max collateral ratio, we set the collateral ratio to the max collateral ratio
                if(_lastCollateralRatioMantissa + change >= _maxCollateralRatioMantissa) {
                    return _maxCollateralRatioMantissa;
                } else {
                    // Otherwise we increase the collateral ratio by the change
                    return _lastCollateralRatioMantissa + change;
                }
            } else {
                // If utilization is greater than the surge, we are decreasing collateral ratio
                // The collateral ratio can only decrease if it is greater than 0
                if(_lastCollateralRatioMantissa == 0) return 0;

                // If the collateral ratio can decrease, we calculate the decrease
                uint timeDelta = _now - _lastAccrueInterestTime;
                uint change = timeDelta * _maxCollateralRatioMantissa / _collateralRatioFallDuration;

                // If the change in collateral ratio is greater than the collateral ratio, we set the collateral ratio to 0
                if(_lastCollateralRatioMantissa <= change) {
                    return 0;
                } else {
                    // Otherwise we decrease the collateral ratio by the change
                    return _lastCollateralRatioMantissa - change;
                }
            }
        }
    }

    /// @notice Transfers pool tokens to the recipient
    /// @param to The address of the recipient
    /// @param amount The amount of pool tokens to transfer
    /// @return bool that indicates if the operation was successful
    function transfer(address to, uint amount) external returns (bool) {
        require(to != address(0), "Pool: to cannot be address 0");
        balanceOf[msg.sender] -= amount;
        unchecked {
            balanceOf[to] += amount;
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Transfers pool tokens on behalf of one address to another
    /// @param from The address of the sender
    /// @param to The address of the recipient
    /// @param amount The amount of pool tokens to transfer
    /// @return bool that indicates if the operation was successful
    function transferFrom(address from, address to, uint amount) external returns (bool) {
        require(to != address(0), "Pool: to cannot be address 0");
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        unchecked {
            balanceOf[to] += amount;
        }
        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Approves an address to spend pool tokens on behalf of the sender
    /// @param spender The address of the spender
    /// @param amount The amount of pool tokens to approve
    /// @return bool that indicates if the operation was successful
    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Deposit loan tokens in exchange for pool tokens
    /// @param amount The amount of loan tokens to deposit
    function deposit(uint amount) external {
        uint _loanTokenBalance = LOAN_TOKEN.balanceOf(address(this));
        (address _feeRecipient, uint _feeMantissa) = FACTORY.getFee();
        (  
            uint _currentTotalSupply,
            uint _accruedFeeShares,
            uint _currentCollateralRatioMantissa,
            uint _currentTotalDebt
        ) = getCurrentState(
            _loanTokenBalance,
            _feeMantissa,
            lastCollateralRatioMantissa,
            totalSupply,
            lastAccrueInterestTime,
            lastTotalDebt
        );

        uint _shares = tokenToShares(amount, (_currentTotalDebt + _loanTokenBalance), _currentTotalSupply, false);
        require(_shares > 0, "Pool: 0 shares");
        _currentTotalSupply += _shares;

        // commit current state
        balanceOf[msg.sender] += _shares;
        totalSupply = _currentTotalSupply;
        lastTotalDebt = _currentTotalDebt;
        lastAccrueInterestTime = block.timestamp;
        lastCollateralRatioMantissa = _currentCollateralRatioMantissa;
        emit Deposit(msg.sender, amount);
        emit Transfer(address(0), msg.sender, _shares);
        if(_accruedFeeShares > 0) {
            balanceOf[_feeRecipient] += _accruedFeeShares;
            emit Transfer(address(0), _feeRecipient, _accruedFeeShares);
        }

        // interactions
        safeTransferFrom(LOAN_TOKEN, msg.sender, address(this), amount);
    }

    /// @notice Withdraw loan tokens in exchange for pool tokens
    /// @param amount The amount of loan tokens to withdraw
    /// @dev If amount is type(uint).max, withdraws all loan tokens
    function withdraw(uint amount) external {
        uint _loanTokenBalance = LOAN_TOKEN.balanceOf(address(this));
        (address _feeRecipient, uint _feeMantissa) = FACTORY.getFee();
        (  
            uint _currentTotalSupply,
            uint _accruedFeeShares,
            uint _currentCollateralRatioMantissa,
            uint _currentTotalDebt
        ) = getCurrentState(
            _loanTokenBalance,
            _feeMantissa,
            lastCollateralRatioMantissa,
            totalSupply,
            lastAccrueInterestTime,
            lastTotalDebt
        );

        uint _shares;
        if (amount == type(uint).max) {
            amount = balanceOf[msg.sender] * (_currentTotalDebt + _loanTokenBalance) / _currentTotalSupply;
            _shares = balanceOf[msg.sender];
        } else {
            _shares = tokenToShares(amount, (_currentTotalDebt + _loanTokenBalance), _currentTotalSupply, true);
        }
        _currentTotalSupply -= _shares;

        // commit current state
        balanceOf[msg.sender] -= _shares;
        totalSupply = _currentTotalSupply;
        lastTotalDebt = _currentTotalDebt;
        lastAccrueInterestTime = block.timestamp;
        lastCollateralRatioMantissa = _currentCollateralRatioMantissa;
        emit Withdraw(msg.sender, amount);
        emit Transfer(msg.sender, address(0), _shares);
        if(_accruedFeeShares > 0) {
            balanceOf[_feeRecipient] += _accruedFeeShares;
            emit Transfer(address(0), _feeRecipient, _accruedFeeShares);
        }

        // interactions
        safeTransfer(LOAN_TOKEN, msg.sender, amount);
    }

    /// @notice Deposit collateral tokens
    /// @param to The address to receive the collateral deposit
    /// @param amount The amount of collateral tokens to deposit
    function addCollateral(address to, uint amount) external {
        collateralBalanceOf[to] += amount;
        safeTransferFrom(COLLATERAL_TOKEN, msg.sender, address(this), amount);
        emit AddCollateral(to, msg.sender, amount);
    }

    /// @notice Gets the debt of a user
    /// @param _userDebtShares The amount of debt shares of the user
    /// @param _debtSharesSupply The total amount of debt shares
    /// @param _totalDebt The total amount of debt
    /// @return uint The debt of the user
    function getDebtOf(uint _userDebtShares, uint _debtSharesSupply, uint _totalDebt) internal pure returns (uint) {
        if (_debtSharesSupply == 0) return 0;
        uint debt = _userDebtShares * _totalDebt / _debtSharesSupply;
        if(debt * _debtSharesSupply < _userDebtShares * _totalDebt) debt++;
        return debt;
    }
    
    /// @notice Withdraw collateral tokens
    /// @param amount The amount of collateral tokens to withdraw
    function removeCollateral(uint amount) external {
        uint _loanTokenBalance = LOAN_TOKEN.balanceOf(address(this));
        (address _feeRecipient, uint _feeMantissa) = FACTORY.getFee();
        (  
            uint _currentTotalSupply,
            uint _accruedFeeShares,
            uint _currentCollateralRatioMantissa,
            uint _currentTotalDebt
        ) = getCurrentState(
            _loanTokenBalance,
            _feeMantissa,
            lastCollateralRatioMantissa,
            totalSupply,
            lastAccrueInterestTime,
            lastTotalDebt
        );

        uint userDebt = getDebtOf(debtSharesBalanceOf[msg.sender], debtSharesSupply, _currentTotalDebt);
        if(userDebt > 0) {
            uint userCollateralRatioMantissa = userDebt * 1e18 / (collateralBalanceOf[msg.sender] - amount);
            require(userCollateralRatioMantissa <= _currentCollateralRatioMantissa, "Pool: user collateral ratio too high");
        }

        // commit current state
        totalSupply = _currentTotalSupply;
        lastTotalDebt = _currentTotalDebt;
        lastAccrueInterestTime = block.timestamp;
        lastCollateralRatioMantissa = _currentCollateralRatioMantissa;
        collateralBalanceOf[msg.sender] -= amount;
        emit RemoveCollateral(msg.sender, amount);
        if(_accruedFeeShares > 0) {
            balanceOf[_feeRecipient] += _accruedFeeShares;
            emit Transfer(address(0), _feeRecipient, _accruedFeeShares);
        }

        // interactions
        safeTransfer(COLLATERAL_TOKEN, msg.sender, amount);
    }

    /// @notice Borrow loan tokens
    /// @param amount The amount of loan tokens to borrow
    function borrow(uint amount) external {
        uint _loanTokenBalance = LOAN_TOKEN.balanceOf(address(this));
        (address _feeRecipient, uint _feeMantissa) = FACTORY.getFee();
        (  
            uint _currentTotalSupply,
            uint _accruedFeeShares,
            uint _currentCollateralRatioMantissa,
            uint _currentTotalDebt
        ) = getCurrentState(
            _loanTokenBalance,
            _feeMantissa,
            lastCollateralRatioMantissa,
            totalSupply,
            lastAccrueInterestTime,
            lastTotalDebt
        );

        uint _debtSharesSupply = debtSharesSupply;
        uint userDebt = getDebtOf(debtSharesBalanceOf[msg.sender], _debtSharesSupply, _currentTotalDebt) + amount;
        uint userCollateralRatioMantissa = userDebt * 1e18 / collateralBalanceOf[msg.sender];
        require(userCollateralRatioMantissa <= _currentCollateralRatioMantissa, "Pool: user collateral ratio too high");

        uint _newUtil = getUtilizationMantissa(_currentTotalDebt + amount, (_currentTotalDebt + _loanTokenBalance));
        require(_newUtil <= SURGE_MANTISSA, "Pool: utilization too high");

        uint _shares = tokenToShares(amount, _currentTotalDebt, _debtSharesSupply, true);
        _currentTotalDebt += amount;

        // commit current state
        debtSharesBalanceOf[msg.sender] += _shares;
        debtSharesSupply = _debtSharesSupply + _shares;
        totalSupply = _currentTotalSupply;
        lastTotalDebt = _currentTotalDebt;
        lastAccrueInterestTime = block.timestamp;
        lastCollateralRatioMantissa = _currentCollateralRatioMantissa;
        emit Borrow(msg.sender, amount);
        if(_accruedFeeShares > 0) {
            balanceOf[_feeRecipient] += _accruedFeeShares;
            emit Transfer(address(0), _feeRecipient, _accruedFeeShares);
        }

        // interactions
        safeTransfer(LOAN_TOKEN, msg.sender, amount);
    }

    /// @notice Repay loan tokens debt
    /// @param borrower The address of the borrower to repay on their behalf
    /// @param amount The amount of loan tokens to repay
    /// @dev If amount is max uint, all debt will be repaid
    function repay(address borrower, uint amount) external {
        uint _loanTokenBalance = LOAN_TOKEN.balanceOf(address(this));
        (address _feeRecipient, uint _feeMantissa) = FACTORY.getFee();
        (  
            uint _currentTotalSupply,
            uint _accruedFeeShares,
            uint _currentCollateralRatioMantissa,
            uint _currentTotalDebt
        ) = getCurrentState(
            _loanTokenBalance,
            _feeMantissa,
            lastCollateralRatioMantissa,
            totalSupply,
            lastAccrueInterestTime,
            lastTotalDebt
        );

        uint _debtSharesSupply = debtSharesSupply;

        uint _shares;
        if(amount == type(uint).max) {
            amount = getDebtOf(debtSharesBalanceOf[borrower], _debtSharesSupply, _currentTotalDebt);
            _shares = debtSharesBalanceOf[borrower];
        } else {
            _shares = tokenToShares(amount, _currentTotalDebt, _debtSharesSupply, false);
        }
        _currentTotalDebt -= amount;

        // commit current state
        debtSharesBalanceOf[borrower] -= _shares;
        debtSharesSupply = _debtSharesSupply - _shares;
        totalSupply = _currentTotalSupply;
        lastTotalDebt = _currentTotalDebt;
        lastAccrueInterestTime = block.timestamp;
        lastCollateralRatioMantissa = _currentCollateralRatioMantissa;
        emit Repay(borrower, msg.sender, amount);
        if(_accruedFeeShares > 0) {
            balanceOf[_feeRecipient] += _accruedFeeShares;
            emit Transfer(address(0), _feeRecipient, _accruedFeeShares);
        }

        // interactions
        safeTransferFrom(LOAN_TOKEN, msg.sender, address(this), amount);
    }

    /// @notice Seize collateral from an underwater borrower in exchange for repaying their debt
    /// @param borrower The address of the borrower to liquidate
    /// @param amount The amount of debt to repay
    /// @dev If amount is max uint, all debt will be liquidated
    function liquidate(address borrower, uint amount) external {
        uint _loanTokenBalance = LOAN_TOKEN.balanceOf(address(this));
        (address _feeRecipient, uint _feeMantissa) = FACTORY.getFee();
        (  
            uint _currentTotalSupply,
            uint _accruedFeeShares,
            uint _currentCollateralRatioMantissa,
            uint _currentTotalDebt
        ) = getCurrentState(
            _loanTokenBalance,
            _feeMantissa,
            lastCollateralRatioMantissa,
            totalSupply,
            lastAccrueInterestTime,
            lastTotalDebt
        );

        uint collateralBalance = collateralBalanceOf[borrower];
        uint _debtSharesSupply = debtSharesSupply;
        uint userDebt = getDebtOf(debtSharesBalanceOf[borrower], _debtSharesSupply, _currentTotalDebt);
        uint userCollateralRatioMantissa = userDebt * 1e18 / collateralBalance;
        require(userCollateralRatioMantissa > _currentCollateralRatioMantissa, "Pool: borrower not liquidatable");

        address _borrower = borrower; // avoid stack too deep
        uint _amount = amount; // avoid stack too deep
        uint _shares;
        uint collateralReward;
        if(_amount == type(uint).max || _amount == userDebt) {
            collateralReward = collateralBalance;
            _shares = debtSharesBalanceOf[_borrower];
            _amount = userDebt;
        } else {
            uint userInvertedCollateralRatioMantissa = collateralBalance * 1e18 / userDebt;
            collateralReward = _amount * userInvertedCollateralRatioMantissa / 1e18; // rounds down
            _shares = tokenToShares(_amount, _currentTotalDebt, _debtSharesSupply, false);
        }
        _currentTotalDebt -= _amount;

        // commit current state
        debtSharesBalanceOf[_borrower] -= _shares;
        debtSharesSupply = _debtSharesSupply - _shares;
        collateralBalanceOf[_borrower] = collateralBalance - collateralReward;
        totalSupply = _currentTotalSupply;
        lastTotalDebt = _currentTotalDebt;
        lastAccrueInterestTime = block.timestamp;
        lastCollateralRatioMantissa = _currentCollateralRatioMantissa;
        emit Liquidate(_borrower, _amount, collateralReward);
        if(_accruedFeeShares > 0) {
            address __feeRecipient = _feeRecipient; // avoid stack too deep
            balanceOf[__feeRecipient] += _accruedFeeShares;
            emit Transfer(address(0), __feeRecipient, _accruedFeeShares);
        }

        // interactions
        safeTransferFrom(LOAN_TOKEN, msg.sender, address(this), _amount);
        safeTransfer(COLLATERAL_TOKEN, msg.sender, collateralReward);
    }

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    event Borrow(address indexed user, uint amount);
    event Repay(address indexed user, address indexed caller, uint amount);
    event Liquidate(address indexed user, uint amount, uint collateralReward);
    event AddCollateral(address indexed user, address indexed caller, uint amount);
    event RemoveCollateral(address indexed user, uint amount);
}