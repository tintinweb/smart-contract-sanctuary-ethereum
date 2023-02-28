// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapConnector.sol";
import "./interfaces/IBalancerVault.sol";
import "./interfaces/IS1NotionalFinanceLendProxy.sol";
import "./proxies/S1NotionalFinanceLendProxy.sol";
import "./Ownable.sol";


interface IFees {
    function feeCollector(uint256 _index) external view returns (address);
    function depositStatus(uint256 _index) external view returns (bool);
    function calcFee(
        uint256 _strategyId,
        address _user,
        address _feeToken
    ) external view returns (uint256);
    function whitelistedDepositCurrencies(uint256 _index, address _token) external view returns(bool);
}


contract S1NotionalFinanceLend is Ownable {
    bool public enableEarlyWithdraw = false;
    bool public enableRollToNewMaturity = false;
    uint8 constant public strategyIndex = 20;
    address public feesAddress;
    address public uniswapConnector;
    address public wethAddress;

    // protocols
    address public notionalProxy;

    mapping(address => address) public depositors;

    constructor(
        address _feesAddress,
        address _uniswapConnector,
        address _wethAddress,
        address _notionalProxy
    ) {
        feesAddress = _feesAddress;
        uniswapConnector = _uniswapConnector;
        wethAddress = _wethAddress;
        notionalProxy = _notionalProxy;
    }

    event Deposit(address indexed _depositor, address indexed _token, address indexed _yieldCurrency, uint256 _amountIn, uint256 _amountOut);

    event ProxyCreation(address indexed _depositor, address indexed _proxy);

    event Withdraw(address indexed _depositor, address indexed _token, address indexed _yieldCurrency, uint256 _amount, uint256 _fee, bool _beforeMaturityDate);

    event RollToNewMaturity(address indexed _depositor, address indexed _yieldCurrency, uint88 _amount, uint8 _ethMarketIndex, uint256 _maturity);

    /*
    * ADMIN METHODS
    */
    function setEarlyWithdraw(bool _bool) external onlyOwner {
        enableEarlyWithdraw = _bool;
    }

    function setRollToNewMaturity(bool _bool) external onlyOwner {
        enableRollToNewMaturity = _bool;
    }

    function getfCashNotional(
        address account,
        uint16 currencyId,
        uint256 maturity
    ) public view returns(int256) {
        return INotionalFinance(notionalProxy).getfCashNotional(account, currencyId, maturity);
    }

    function getActiveMarkets(uint16 currencyId) public view returns(INotionalFinance.MarketParameters[] memory) {
        return INotionalFinance(notionalProxy).getActiveMarkets(currencyId);
    }

    function getAccountPortfolio(address _address) public view returns(INotionalFinance.PortfolioAsset[] memory) {
        return INotionalFinance(notionalProxy).getAccountPortfolio(depositors[_address]);
    }

    function getAccountBalance(address _address, uint8 _yieldCurrencyId) external view returns(int256, int256, uint256) {
        if (depositors[_address] != address(0)) {
            return INotionalFinance(notionalProxy).getAccountBalance(_yieldCurrencyId, depositors[_address]);
        } else {
            return (0, 0, 0);
        }
    }

    function getCashAmountGivenfCashAmount(
        uint16 currencyId,
        int88 fCashAmount,
        uint256 marketIndex
    ) external view returns (int256, int256) {
        return INotionalFinance(notionalProxy).getCashAmountGivenfCashAmount(
            currencyId,
            fCashAmount,
            marketIndex,
            block.timestamp
        );
    }

    function getPresentfCashValue(
        uint16 currencyId,
        uint256 maturity,
        int256 notional,
        bool riskAdjusted
    ) external view returns (int256 presentValue) {
        return INotionalFinance(notionalProxy).getPresentfCashValue(
            currencyId,
            maturity, 
            notional,
            block.timestamp,
            riskAdjusted
        );
    }

    function depositETH(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amountOutMin, INotionalFinance.DepositActionType _actionType, uint256 _maturity, uint32 _minLendRate) external payable {
        require(IFees(feesAddress).depositStatus(strategyIndex), "ERR: DEPOSITS_STOPPED");

        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            _yieldDeposit(_yieldCurrency, _yieldCurrencyId, msg.value, _actionType, _maturity, _minLendRate);

            emit Deposit(msg.sender, wethAddress, _yieldCurrency, msg.value, msg.value);  
        } else {
            uint256 depositAmount = IUniswapConnector(uniswapConnector).swapETHForToken{value: msg.value}(
                _yieldCurrency, 
                0, 
                _amountOutMin, 
                address(this)
            );
            _yieldDeposit(_yieldCurrency, _yieldCurrencyId, depositAmount, _actionType, _maturity, _minLendRate);

            emit Deposit(msg.sender, wethAddress, _yieldCurrency, msg.value, depositAmount);  
        }
    }

    function depositToken(address _yieldCurrency, uint8 _yieldCurrencyId, address _token, uint256 _amount, uint256 _amountOutMin, INotionalFinance.DepositActionType _actionType, uint256 _maturity, uint32 _minLendRate) external {
        require(IFees(feesAddress).depositStatus(strategyIndex), "ERR: DEPOSITS_STOPPED");
        require(IFees(feesAddress).whitelistedDepositCurrencies(strategyIndex, _token), "ERR: INVALID_DEPOSIT_TOKEN");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        uint256 depositAmount;
        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            if (IERC20(_token).allowance(address(this), uniswapConnector) == 0) {
                IERC20(_token).approve(uniswapConnector, 2**256 - 1);
            }
            
            depositAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
                _token,
                wethAddress, 
                _amount, 
                _amountOutMin, 
                address(this)
            );
            IWETH(wethAddress).withdraw(depositAmount);
            _yieldDeposit(_yieldCurrency, _yieldCurrencyId, depositAmount, _actionType, _maturity, _minLendRate);
        } else {
            if (_token != _yieldCurrency) {
                if (IERC20(_token).allowance(address(this), uniswapConnector) == 0) {
                    IERC20(_token).approve(uniswapConnector, 2**256 - 1);
                }

                depositAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
                    _token,
                    _yieldCurrency, 
                    _amount, 
                    _amountOutMin, 
                    address(this)
                );
            } else {
                depositAmount = _amount;
            }
            _yieldDeposit(_yieldCurrency, _yieldCurrencyId, depositAmount, _actionType, _maturity, _minLendRate);
        }
 
        emit Deposit(msg.sender, _token, _yieldCurrency, _amount, depositAmount);
    }

    function _yieldDeposit(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, INotionalFinance.DepositActionType _actionType, uint256 _maturity, uint32 _minLendRate) private {
        if (depositors[msg.sender] == address(0)) {
            // deploy new proxy contract
            S1NotionalFinanceLendProxy s1proxy = new S1NotionalFinanceLendProxy(
                address(this),
                notionalProxy
            );
            depositors[msg.sender] = address(s1proxy);
            if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
                s1proxy.deposit{value: _amount}(_yieldCurrency, _yieldCurrencyId, _amount, _actionType, _maturity, _minLendRate);
            } else {
                IERC20(_yieldCurrency).approve(depositors[msg.sender], 2**256 - 1);
                s1proxy.deposit(_yieldCurrency, _yieldCurrencyId, _amount, _actionType, _maturity, _minLendRate);
            }

            emit ProxyCreation(msg.sender, address(s1proxy));
        } else {
            // send the deposit to the existing proxy contract
            if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
                IS1NotionalFinanceLendProxy(depositors[msg.sender]).deposit{value: _amount}(_yieldCurrency, _yieldCurrencyId, _amount, _actionType, _maturity, _minLendRate);
            } else {
                if (IERC20(_yieldCurrency).allowance(address(this), depositors[msg.sender]) == 0) {
                    IERC20(_yieldCurrency).approve(depositors[msg.sender], 2**256 - 1); 
                }

                IS1NotionalFinanceLendProxy(depositors[msg.sender]).deposit(_yieldCurrency, _yieldCurrencyId, _amount, _actionType, _maturity, _minLendRate);
            }
        }
    }

    function withdrawETH(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, uint256 _amountOutMin, address _feeToken, uint256 _withdrawAmountInternalPrecision, bool _withdrawEntireCashBalance, bool _redeemToUnderlying, INotionalFinance.DepositActionType _actionType) external {
        withdrawToken(_yieldCurrency, _yieldCurrencyId, wethAddress, _amount, _amountOutMin, _feeToken, _withdrawAmountInternalPrecision, _withdrawEntireCashBalance, _redeemToUnderlying, _actionType);
    }

    function withdrawToken(address _yieldCurrency, uint8 _yieldCurrencyId, address _token, uint256 _amount, uint256 _amountOutMin, address _feeToken, uint256 _withdrawAmountInternalPrecision, bool _withdrawEntireCashBalance, bool _redeemToUnderlying, INotionalFinance.DepositActionType _actionType) public {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        
        uint256 amountToBeWithdrawn = IS1NotionalFinanceLendProxy(depositors[msg.sender]).withdraw(_yieldCurrency, _yieldCurrencyId, _amount, _withdrawAmountInternalPrecision, _withdrawEntireCashBalance, _redeemToUnderlying, _actionType);
        (uint256 deposit, uint256 fee) = _splitYieldDepositAndFee(amountToBeWithdrawn, _yieldCurrency, _yieldCurrencyId, _feeToken);
        
        _proceedWithWithdraw(_yieldCurrency, _yieldCurrencyId, _token, _amountOutMin, deposit, fee, false);
    }

    function withdrawETHBeforeMaturityDate(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, uint256 _amountOutMin, address _feeToken, INotionalFinance.DepositActionType _actionType, uint8 _ethMarketIndex, uint32 _maxImpliedRate) external {
        withdrawTokenBeforeMaturityDate(_yieldCurrency, _yieldCurrencyId, wethAddress, _amount, _amountOutMin, _feeToken, _actionType, _ethMarketIndex, _maxImpliedRate);
    }

    function withdrawTokenBeforeMaturityDate(address _yieldCurrency, uint8 _yieldCurrencyId, address _token, uint256 _amount, uint256 _amountOutMin, address _feeToken, INotionalFinance.DepositActionType _actionType, uint8 _ethMarketIndex, uint32 _maxImpliedRate) public {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        require(enableEarlyWithdraw == true, "ERR: EARLY_WITHDRAW_STOPPED");

        uint256 amountToBeWithdrawn = IS1NotionalFinanceLendProxy(depositors[msg.sender]).withdrawBeforeMaturityDate(_yieldCurrency, _yieldCurrencyId, uint88(_amount), _actionType, _ethMarketIndex, _maxImpliedRate);
        (uint256 deposit, uint256 fee) = _splitYieldDepositAndFee(amountToBeWithdrawn, _yieldCurrency, _yieldCurrencyId, _feeToken);
        
        _proceedWithWithdraw(_yieldCurrency, _yieldCurrencyId, _token, _amountOutMin, deposit, fee, true);
    }

    function _splitYieldDepositAndFee(uint256 amountToBeWithdrawn, address _yieldCurrency, uint8 _yieldCurrencyId,  address _feeToken) private returns(uint256, uint256) {
        uint256 fee = (amountToBeWithdrawn * IFees(feesAddress).calcFee(strategyIndex, msg.sender, _feeToken)) / 1000;
        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            if (fee > 0) {
                (bool success, ) = payable(IFees(feesAddress).feeCollector(strategyIndex)).call{value: fee}("");
                require(success, "ERR: FAIL_SENDING_ETH");
            }
        } else {
            IERC20(_yieldCurrency).transferFrom(depositors[msg.sender], address(this), amountToBeWithdrawn);
            
            if (fee > 0) {
                IERC20(_yieldCurrency).transfer(
                    IFees(feesAddress).feeCollector(strategyIndex),
                    fee
                );
            }
        }
        return (amountToBeWithdrawn, fee);
    }

    function _proceedWithWithdraw(address _yieldCurrency, uint8 _yieldCurrencyId, address _token, uint256 _amountOutMin, uint256 _deposit, uint256 _fee, bool _beforeMaturityDate) private {
        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            if (_token == wethAddress) {
                // withdraw ETH
                (bool success, ) = payable(msg.sender).call{value: _deposit - _fee}("");
                require(success, "ERR: FAIL_SENDING_ETH");
                emit Withdraw(msg.sender, wethAddress, _yieldCurrency, _deposit - _fee, _fee, _beforeMaturityDate);
            } else {
                uint256 tokenAmount = IUniswapConnector(uniswapConnector).swapETHForToken{value: _deposit - _fee}(
                    _token, 
                    0, 
                    _amountOutMin,
                    msg.sender
                );

                emit Withdraw(msg.sender, _token, _yieldCurrency, tokenAmount, _fee, _beforeMaturityDate);
            }
        } else {
            if (_token == _yieldCurrency) {
                IERC20(_yieldCurrency).transfer(
                    msg.sender,
                    _deposit - _fee
                );

                emit Withdraw(msg.sender, _token, _yieldCurrency, _deposit - _fee, _fee, _beforeMaturityDate);
            } else {
                if (IERC20(_yieldCurrency).allowance(address(this), uniswapConnector) == 0) {
                    IERC20(_yieldCurrency).approve(uniswapConnector, 2**256 - 1);
                }

                address receiver;
                if (_token == wethAddress) {
                    receiver = address(this);
                } else {
                    receiver = msg.sender;
                }

                uint256 tokenAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
                    _yieldCurrency,
                    _token, 
                    _deposit - _fee, 
                    _amountOutMin, 
                    receiver
                );

                if (_token == wethAddress) {
                    IWETH(wethAddress).withdraw(tokenAmount);
                    (bool success, ) = payable(msg.sender).call{value: tokenAmount}("");
                    require(success, "ERR: FAIL_SENDING_ETH");
                }

                emit Withdraw(msg.sender, _token, _yieldCurrency, tokenAmount, _fee, _beforeMaturityDate);
            }
        }
    }

    function rollToNewMaturity(address _yieldCurrency, uint8 _yieldCurrencyId, uint88 _amount, uint8 _ethMarketIndex, uint32 _maxImpliedRate, uint256 _maturity, uint32 _minLendRate) external {
        require(enableRollToNewMaturity == true, "ERR: NEW_ROLL_STOPPED");
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");

        IS1NotionalFinanceLendProxy(depositors[msg.sender]).rollToNewMaturity(_yieldCurrency, _yieldCurrencyId, _amount, _ethMarketIndex, _maxImpliedRate, _maturity, _minLendRate);
        emit RollToNewMaturity(msg.sender, _yieldCurrency, _amount, _ethMarketIndex, _maturity);
    }

    receive() external payable {}
}

// MN bby ¯\_(ツ)_/¯

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external;

    function transfer(address recipient, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IWETH {
    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../interfaces/INotionalFinance.sol";


interface IS1NotionalFinanceLendProxy {
    function deposit(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _deposit, INotionalFinance.DepositActionType _actionType, uint256 _maturity, uint32 _minLendRate) external payable;
    function withdraw(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, uint256 _withdrawAmountInternalPrecision, bool _withdrawEntireCashBalance, bool _redeemToUnderlying, INotionalFinance.DepositActionType _actionType) external returns(uint256);
    function withdrawBeforeMaturityDate(address _yieldCurrency, uint8 _yieldCurrencyId, uint88 _amount, INotionalFinance.DepositActionType _actionType, uint8 _ethMarketIndex, uint32 _maxImpliedRate) external returns(uint256);
    function rollToNewMaturity(address _yieldCurrency, uint8 _yieldCurrencyId, uint88 _amount, uint8 _ethMarketIndex, uint32 _maxImpliedRate, uint256 _maturity, uint32 _minLendRate) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IBalancerVault {
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IUniswapConnector {
    function swapTokenForToken(address _tokenIn, address _tokenOut, uint256 _amount, uint256 _amountOutMin, address _to) external returns(uint256);

    function swapTokenForETH(address _tokenIn, uint256 _amount, uint256 _amountOutMin, address _to) external returns(uint256);

    function swapETHForToken(address _tokenOut, uint256 _amount, uint256 _amountOutMin, address _to) external payable returns(uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/INotionalFinance.sol";


contract S1NotionalFinanceLendProxy {
    address private deployer;
    address private notionalProxy;

    constructor(
        address _deployer,
        address _notionalProxy
    ) {
        deployer = _deployer;
        notionalProxy = _notionalProxy;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "ERR: WRONG_DEPLOYER");
        _;
    } 

    function deposit(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, INotionalFinance.DepositActionType _actionType, uint256 _maturity, uint32 _minLendRate) external payable onlyDeployer {
        if (_yieldCurrency != address(0) && _yieldCurrencyId != 1) {
            if (IERC20(_yieldCurrency).allowance(address(this), deployer) == 0) {
                IERC20(_yieldCurrency).approve(deployer, 2**256 - 1);
            }

            if (IERC20(_yieldCurrency).allowance(address(this), notionalProxy) == 0) {
                IERC20(_yieldCurrency).approve(notionalProxy, 2**256 - 1);
            }

            IERC20(_yieldCurrency).transferFrom(deployer, address(this), _amount);
        }

        _deposit(_yieldCurrency, _yieldCurrencyId, _amount, _actionType, _maturity, _minLendRate);
    }

    function _deposit(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, INotionalFinance.DepositActionType _actionType, uint256 _maturity, uint32 _minLendRate) private {
        (/* fCashAmount */, /* marketIndex*/, bytes32 encodedLendTrade) = INotionalFinance(notionalProxy).getfCashLendFromDeposit({
            currencyId: _yieldCurrencyId,
            depositAmountExternal: _amount,
            maturity: _maturity,
            minLendRate: _minLendRate,
            blockTime: block.timestamp,
            useUnderlying: true
        });

        INotionalFinance.BalanceActionWithTrades[] memory actions = new INotionalFinance.BalanceActionWithTrades[](1);
        actions[0] = INotionalFinance.BalanceActionWithTrades({
            actionType: _actionType,
            currencyId: _yieldCurrencyId,
            depositActionAmount: _amount,
            withdrawAmountInternalPrecision: 0,
            withdrawEntireCashBalance: true,
            redeemToUnderlying: true,
            trades: new bytes32[](1)
        });
        actions[0].trades[0] = encodedLendTrade;

        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            INotionalFinance(notionalProxy).batchBalanceAndTradeAction{value: _amount}(address(this), actions);
        } else {
            INotionalFinance(notionalProxy).batchBalanceAndTradeAction(address(this), actions);
        }
    }

    function withdraw(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, uint256 _withdrawAmountInternalPrecision, bool _withdrawEntireCashBalance, bool _redeemToUnderlying, INotionalFinance.DepositActionType _actionType) external onlyDeployer returns(uint256) {
        INotionalFinance.BalanceAction[] memory actions = new INotionalFinance.BalanceAction[](1);
        actions[0] = INotionalFinance.BalanceAction({
            actionType: _actionType,
            currencyId: _yieldCurrencyId,
            depositActionAmount: _amount,
            withdrawAmountInternalPrecision: _withdrawAmountInternalPrecision,
            withdrawEntireCashBalance: _withdrawEntireCashBalance,
            redeemToUnderlying: _redeemToUnderlying
        });
        INotionalFinance(notionalProxy).batchBalanceAction(address(this), actions);

        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            uint256 ethBalance = address(this).balance;
            (bool success, ) = payable(deployer).call{value: ethBalance}("");
            require(success, "ERR: FAIL_SENDING_ETH");

            return ethBalance;
        } else {
            return IERC20(_yieldCurrency).balanceOf(address(this));
        }
    }

    function withdrawBeforeMaturityDate(address _yieldCurrency, uint8 _yieldCurrencyId, uint88 _amount, INotionalFinance.DepositActionType _actionType, uint8 _ethMarketIndex, uint32 _maxImpliedRate) external onlyDeployer returns(uint256) {
        uint256 amount = _withdrawBeforeMaturityDate(_yieldCurrency, _yieldCurrencyId, _amount, _actionType, _ethMarketIndex, _maxImpliedRate);

        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            (bool success, ) = payable(deployer).call{value: amount}("");
            require(success, "ERR: FAIL_SENDING_ETH");
        }
        return amount;
    }

    function _withdrawBeforeMaturityDate(address _yieldCurrency, uint8 _yieldCurrencyId, uint88 _amount, INotionalFinance.DepositActionType _actionType, uint8 _ethMarketIndex, uint32 _maxImpliedRate) private returns(uint256) {
        INotionalFinance.BalanceActionWithTrades[] memory actions = new INotionalFinance.BalanceActionWithTrades[](1);
        actions[0] = INotionalFinance.BalanceActionWithTrades({
            actionType: _actionType,
            currencyId: _yieldCurrencyId,
            depositActionAmount: 0,
            withdrawAmountInternalPrecision: 0,
            withdrawEntireCashBalance: true,
            redeemToUnderlying: true,
            trades: new bytes32[](1)
        });
        actions[0].trades[0] = _encodeBorrowTrade(
            _ethMarketIndex, _amount, _maxImpliedRate
        );
        INotionalFinance(notionalProxy).batchBalanceAndTradeAction(address(this), actions);

        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            return address(this).balance;
        } else {
            return IERC20(_yieldCurrency).balanceOf(address(this));
        }
    }

    function rollToNewMaturity(address _yieldCurrency, uint8 _yieldCurrencyId, uint88 _amount, uint8 _ethMarketIndex, uint32 _maxImpliedRate, uint256 _maturity, uint32 _minLendRate) external onlyDeployer {
        _withdrawBeforeMaturityDate(_yieldCurrency, _yieldCurrencyId, _amount, INotionalFinance.DepositActionType.None, _ethMarketIndex, _maxImpliedRate);

        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            _deposit(_yieldCurrency, _yieldCurrencyId, address(this).balance, INotionalFinance.DepositActionType.DepositUnderlying, _maturity, _minLendRate);
        } else {
            _deposit(_yieldCurrency, _yieldCurrencyId, IERC20(_yieldCurrency).balanceOf(address(this)), INotionalFinance.DepositActionType.DepositUnderlying, _maturity, _minLendRate);
        }
    }
    
    function _encodeBorrowTrade(
        uint8 marketIndex,
        uint88 fCashAmount,
        uint32 maxImpliedRate
    ) internal pure returns (bytes32) {
        return bytes32(
            (uint256(uint8(INotionalFinance.TradeActionType.Borrow)) << 248) |
            (uint256(marketIndex) << 240) |
            (uint256(fCashAmount) << 152) |
            (uint256(maxImpliedRate) << 120)
        );
    }

    receive() external payable {}
}

// MN bby ¯\_(ツ)_/¯

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface INotionalFinance {
    function batchBalanceAction(address account, BalanceAction[] calldata actions) external payable;

    struct BalanceAction {
        // Deposit action to take (if any)
        DepositActionType actionType;
        uint16 currencyId;
        // Deposit action amount must correspond to the depositActionType, see documentation above.
        uint256 depositActionAmount;
        // Withdraw an amount of asset cash specified in Notional internal 8 decimal precision
        uint256 withdrawAmountInternalPrecision;
        // If set to true, will withdraw entire cash balance. Useful if there may be an unknown amount of asset cash
        // residual left from trading.
        bool withdrawEntireCashBalance;
        // If set to true, will redeem asset cash to the underlying token on withdraw.
        bool redeemToUnderlying;
    }

    function batchBalanceAndTradeAction(address account, BalanceActionWithTrades[] calldata actions) external payable;

    /// @notice Defines a balance action with a set of trades to do as well
    struct BalanceActionWithTrades {
        DepositActionType actionType;
        uint16 currencyId;
        uint256 depositActionAmount;
        uint256 withdrawAmountInternalPrecision;
        bool withdrawEntireCashBalance;
        bool redeemToUnderlying;
        // Array of tightly packed 32 byte objects that represent trades. See TradeActionType documentation
        bytes32[] trades;
    }

    enum DepositActionType {
        // No deposit action
        None,
        // Deposit asset cash, depositActionAmount is specified in asset cash external precision
        DepositAsset,
        // Deposit underlying tokens that are mintable to asset cash, depositActionAmount is specified in underlying token
        // external precision
        DepositUnderlying,
        // Deposits specified asset cash external precision amount into an nToken and mints the corresponding amount of
        // nTokens into the account
        DepositAssetAndMintNToken,
        // Deposits specified underlying in external precision, mints asset cash, and uses that asset cash to mint nTokens
        DepositUnderlyingAndMintNToken,
        // Redeems an nToken balance to asset cash. depositActionAmount is specified in nToken precision. Considered a deposit action
        // because it deposits asset cash into an account. If there are fCash residuals that cannot be sold off, will revert.
        RedeemNToken,
        // Converts specified amount of asset cash balance already in Notional to nTokens. depositActionAmount is specified in
        // Notional internal 8 decimal precision.
        ConvertCashToNToken
    }

    function getfCashLendFromDeposit(
        uint16 currencyId,
        uint256 depositAmountExternal,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime,
        bool useUnderlying
    ) external view returns (uint88 fCashAmount, uint8 marketIndex, bytes32 encodedTrade);

    function getActiveMarkets(uint16 currencyId) external view returns (MarketParameters[] memory);

    /// @dev Market object as represented in memory
    struct MarketParameters {
        bytes32 storageSlot;
        uint256 maturity;
        // Total amount of fCash available for purchase in the market.
        int256 totalfCash;
        // Total amount of cash available for purchase in the market.
        int256 totalAssetCash;
        // Total amount of liquidity tokens (representing a claim on liquidity) in the market.
        int256 totalLiquidity;
        // This is the previous annualized interest rate in RATE_PRECISION that the market traded
        // at. This is used to calculate the rate anchor to smooth interest rates over time.
        uint256 lastImpliedRate;
        // Time lagged version of lastImpliedRate, used to value fCash assets at market rates while
        // remaining resistent to flash loan attacks.
        uint256 oracleRate;
        // This is the timestamp of the previous trade
        uint256 previousTradeTime;
    }

    function withdraw(uint16 _currencyId, uint88 _amountInternalPrecision, bool _redeemToUnderlying) external returns (uint256);

    function getfCashNotional(
        address account,
        uint16 currencyId,
        uint256 maturity
    ) external view returns (int256);

    /// @notice Specifies the different trade action types in the system. Each trade action type is
    /// encoded in a tightly packed bytes32 object. Trade action type is the first big endian byte of the
    /// 32 byte trade action object. The schemas for each trade action type are defined below.
    enum TradeActionType {
        // (uint8 TradeActionType, uint8 MarketIndex, uint88 fCashAmount, uint32 minImpliedRate, uint120 unused)
        Lend,
        // (uint8 TradeActionType, uint8 MarketIndex, uint88 fCashAmount, uint32 maxImpliedRate, uint128 unused)
        Borrow,
        // (uint8 TradeActionType, uint8 MarketIndex, uint88 assetCashAmount, uint32 minImpliedRate, uint32 maxImpliedRate, uint88 unused)
        AddLiquidity,
        // (uint8 TradeActionType, uint8 MarketIndex, uint88 tokenAmount, uint32 minImpliedRate, uint32 maxImpliedRate, uint88 unused)
        RemoveLiquidity,
        // (uint8 TradeActionType, uint32 Maturity, int88 fCashResidualAmount, uint128 unused)
        PurchaseNTokenResidual,
        // (uint8 TradeActionType, address CounterpartyAddress, int88 fCashAmountToSettle)
        SettleCashDebt
    }

    function nTokenClaimIncentives() external returns (uint256);

    function nTokenGetClaimableIncentives(address account, uint256 blockTime) external view returns (uint256);

    function nTokenPresentValueUnderlyingDenominated(uint16 currencyId)
        external
        view
        returns (int256);

    function nTokenAddress(uint16 currencyId) external view returns (address);
    
    function nTokenTotalSupply(address nTokenAddress) external view returns (uint256);

    function getCashAmountGivenfCashAmount(
        uint16 currencyId,
        int88 fCashAmount,
        uint256 marketIndex,
        uint256 blockTime
    ) external view returns (int256, int256);

    function getAccountBalance(uint16 currencyId, address account) external view returns (
        int256 cashBalance,
        int256 nTokenBalance,
        uint256 lastClaimTime
    );

    function getPresentfCashValue(
        uint16 currencyId,
        uint256 maturity,
        int256 notional,
        uint256 blockTime,
        bool riskAdjusted
    ) external view returns (int256 presentValue);

    function getAccountPortfolio(address account) external view returns (PortfolioAsset[] memory);

    /// @dev A portfolio asset when loaded in memory
    struct PortfolioAsset {
        // Asset currency id
        uint256 currencyId;
        uint256 maturity;
        // Asset type, fCash or liquidity token.
        uint256 assetType;
        // fCash amount or liquidity token amount
        int256 notional;
        // Used for managing portfolio asset state
        uint256 storageSlot;
        // The state of the asset for when it is written to storage
        AssetStorageState storageState;
    }
    
    /// @notice Used internally for PortfolioHandler state
    enum AssetStorageState {
        NoChange,
        Update,
        Delete,
        RevertIfStored
    }
}