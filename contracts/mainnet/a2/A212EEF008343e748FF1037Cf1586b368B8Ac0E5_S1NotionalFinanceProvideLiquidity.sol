// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapConnector.sol";
import "./interfaces/IBalancerVault.sol";
import "./interfaces/IS1NotionalFinanceProvideLiquidityProxy.sol";
import "./proxies/S1NotionalFinanceProvideLiquidityProxy.sol";
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


contract S1NotionalFinanceProvideLiquidity is Ownable {
    uint8 constant public strategyIndex = 21;
    address public feesAddress;
    address public uniswapConnector;
    address public balancerVault;
    address public wethAddress;

    // protocols
    address public notionalProxy;
    address public NOTE;
    bytes32 public NOTEPoolId;

    mapping(address => address) public depositors;

    constructor(
        address _feesAddress,
        address _uniswapConnector,
        address _balancerVault,
        address _wethAddress,
        address _notionalProxy,
        address _NOTE,
        bytes32 _NOTEPoolId
    ) {
        feesAddress = _feesAddress;
        uniswapConnector = _uniswapConnector;
        balancerVault = _balancerVault;
        wethAddress = _wethAddress;
        notionalProxy = _notionalProxy;
        NOTE = _NOTE;
        NOTEPoolId = _NOTEPoolId;
    }

    event Deposit(address indexed _depositor, address indexed _token, address indexed _yieldCurrency, uint256 _amountIn, uint256 _amountOut);

    event ProxyCreation(address indexed _depositor, address indexed _proxy);

    event Withdraw(address indexed _depositor, address indexed _token, address indexed _yieldCurrency, uint256 _amount, uint256 _fee);

    event ClaimAdditionalTokens(address indexed _depositor, uint256 _amount0, uint256 _amount1, address indexed _swappedTo);

    function setupNOTEPoolId(bytes32 _NOTEPoolId) external onlyOwner {
        NOTEPoolId = _NOTEPoolId;
    }

    function getPendingAdditionalTokenClaims(address _address) external view returns(uint256, uint256) {
        return (
            INotionalFinance(notionalProxy).nTokenGetClaimableIncentives(depositors[_address], block.timestamp),
            IERC20(NOTE).balanceOf(depositors[_address])
        );
    }

    function getAccountPortfolio(address _address) external view returns(INotionalFinance.PortfolioAsset[] memory) {
        return INotionalFinance(notionalProxy).getAccountPortfolio(depositors[_address]);
    }

    function getAccountBalance(address _address, uint8 _yieldCurrencyId) external view returns(int256, int256, uint256) {
        return INotionalFinance(notionalProxy).getAccountBalance(_yieldCurrencyId, depositors[_address]);
    }

    function nTokenPresentValueUnderlyingDenominated(uint16 currencyId) external view returns (int256) {
        return INotionalFinance(notionalProxy).nTokenPresentValueUnderlyingDenominated(currencyId);
    }

    function nTokenAddress(uint16 currencyId) external view returns (address) {
        return INotionalFinance(notionalProxy).nTokenAddress(currencyId);
    }

    function nTokenTotalSupply(address _nTokenAddress) external view returns (uint256) {
        return INotionalFinance(notionalProxy).nTokenTotalSupply(_nTokenAddress);
    }

    function depositETH(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amountOutMin, INotionalFinance.DepositActionType actionType) external payable {
        require(IFees(feesAddress).depositStatus(strategyIndex), "ERR: DEPOSITS_STOPPED");

        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            _yieldDeposit(_yieldCurrency, _yieldCurrencyId, msg.value, actionType);

            emit Deposit(msg.sender, wethAddress, _yieldCurrency, msg.value, msg.value);  
        } else {
            uint256 depositAmount = IUniswapConnector(uniswapConnector).swapETHForToken{value: msg.value}(
                _yieldCurrency, 
                0, 
                _amountOutMin, 
                address(this)
            );
            _yieldDeposit(_yieldCurrency, _yieldCurrencyId, depositAmount, actionType);

            emit Deposit(msg.sender, wethAddress, _yieldCurrency, msg.value, depositAmount);  
        }
    }

    function depositToken(address _yieldCurrency, uint8 _yieldCurrencyId, address _token, uint256 _amount, uint256 _amountOutMin, INotionalFinance.DepositActionType actionType) external {
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
            _yieldDeposit(_yieldCurrency, _yieldCurrencyId, depositAmount, actionType);
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
            _yieldDeposit(_yieldCurrency, _yieldCurrencyId, depositAmount, actionType);
        }
 
        emit Deposit(msg.sender, _token, _yieldCurrency, _amount, depositAmount);
    }

    function _yieldDeposit(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, INotionalFinance.DepositActionType actionType) private {
        if (depositors[msg.sender] == address(0)) {
            // deploy new proxy contract
            S1NotionalFinanceProvideLiquidityProxy s1proxy = new S1NotionalFinanceProvideLiquidityProxy(
                address(this),
                notionalProxy,
                NOTE
            );
            depositors[msg.sender] = address(s1proxy);
            if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
                s1proxy.deposit{value: _amount}(_yieldCurrency, _yieldCurrencyId, _amount, actionType);
            } else {
                IERC20(_yieldCurrency).approve(depositors[msg.sender], 2**256 - 1);
                s1proxy.deposit(_yieldCurrency, _yieldCurrencyId, _amount, actionType);
            }

            emit ProxyCreation(msg.sender, address(s1proxy));
        } else {
            // send the deposit to the existing proxy contract
            if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
                IS1NotionalFinanceProvideLiquidityProxy(depositors[msg.sender]).deposit{value: _amount}(_yieldCurrency, _yieldCurrencyId, _amount, actionType);
            } else {
                if (IERC20(_yieldCurrency).allowance(address(this), depositors[msg.sender]) == 0) {
                    IERC20(_yieldCurrency).approve(depositors[msg.sender], 2**256 - 1); 
                }

                IS1NotionalFinanceProvideLiquidityProxy(depositors[msg.sender]).deposit(_yieldCurrency, _yieldCurrencyId, _amount, actionType);
            }
        }
    }

    // claim NOTE tokens and withdraw them
    function claimRaw() external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        uint256 noteTokens = IS1NotionalFinanceProvideLiquidityProxy(depositors[msg.sender]).claimToDepositor(msg.sender); 

        emit ClaimAdditionalTokens(msg.sender, noteTokens, 0, address(0));
    }

    // claim NOTE tokens, swap them for ETH and withdraw
    function claimInETH(uint256 _amountOutMin) external {
        claimInToken(address(0), _amountOutMin, 0);  
    }

    // claim NOTE tokens, swap them for _token and withdraw
    function claimInToken(address _token, uint256 _wethAmountOutMin, uint256 _tokenAmountOutMin) public {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        uint256 noteTokens = IS1NotionalFinanceProvideLiquidityProxy(depositors[msg.sender]).claimToDeployer();

        uint256 swapResult;
        if (noteTokens > 0) {
            if (IERC20(NOTE).allowance(address(this), balancerVault) == 0) {
                IERC20(NOTE).approve(balancerVault, 2**256 - 1);
            }

            address recipient;
            if (_token == address(0)) {
                recipient = msg.sender;
            } else {
                recipient = address(this);
            }

            // swap NOTE to ETH at Balancer
            swapResult = IBalancerVault(balancerVault).swap(
                IBalancerVault.SingleSwap({
                    poolId: NOTEPoolId,
                    kind: IBalancerVault.SwapKind.GIVEN_IN,
                    assetIn: NOTE,
                    assetOut: address(0),
                    amount: noteTokens,
                    userData: "0x"
                }),
                IBalancerVault.FundManagement({
                    sender: address(this),
                    fromInternalBalance: false,
                    recipient: payable(recipient),
                    toInternalBalance: false
                }),
                _wethAmountOutMin,
                block.timestamp + 7200
            );

            // swap ETH to _token at Uniswap
            if (_token != address(0)) {
                swapResult = IUniswapConnector(uniswapConnector).swapETHForToken{value: swapResult}(
                    _token, 
                    0, 
                    _tokenAmountOutMin, 
                    msg.sender
                );
            }
        }

        emit ClaimAdditionalTokens(msg.sender, noteTokens, swapResult, _token);
    }

    function withdrawETH(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, uint256 _amountOutMin, address _feeToken, INotionalFinance.DepositActionType actionType) external {
        withdrawToken(_yieldCurrency, _yieldCurrencyId, wethAddress, _amount, _amountOutMin, _feeToken, actionType);
    }

    function withdrawToken(address _yieldCurrency, uint8 _yieldCurrencyId, address _token, uint256 _amount, uint256 _amountOutMin, address _feeToken, INotionalFinance.DepositActionType actionType) public {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 yieldDeposit, uint256 fee) = _withdrawYieldDeposit(_yieldCurrency, _yieldCurrencyId, _amount, _feeToken, actionType);

        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            if (_token == wethAddress) {
                // withdraw ETH
                (bool success, ) = payable(msg.sender).call{value: yieldDeposit - fee}("");
                require(success, "ERR: FAIL_SENDING_ETH");
                emit Withdraw(msg.sender, wethAddress, _yieldCurrency, yieldDeposit - fee, fee);
            } else {
                uint256 tokenAmount = IUniswapConnector(uniswapConnector).swapETHForToken{value: yieldDeposit - fee}(
                    _token, 
                    0, 
                    _amountOutMin, 
                    msg.sender
                );

                emit Withdraw(msg.sender, _token, _yieldCurrency, tokenAmount, fee);
            }
        } else {
            if (_token == _yieldCurrency) { 
                // withdraw USDC
                IERC20(_yieldCurrency).transfer(
                    msg.sender,
                    yieldDeposit - fee
                );

                emit Withdraw(msg.sender, _token, _yieldCurrency, yieldDeposit - fee, fee);
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
                    yieldDeposit - fee, 
                    _amountOutMin, 
                    receiver
                );

                if (_token == wethAddress) {
                    IWETH(wethAddress).withdraw(tokenAmount);
                    (bool success, ) = payable(msg.sender).call{value: tokenAmount}("");
                    require(success, "ERR: FAIL_SENDING_ETH");
                }

                emit Withdraw(msg.sender, _token, _yieldCurrency, tokenAmount, fee);
            }
        }
    }

    function _withdrawYieldDeposit(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, address _feeToken, INotionalFinance.DepositActionType actionType) private returns(uint256, uint256) {
        uint256 amountToBeWithdrawn = IS1NotionalFinanceProvideLiquidityProxy(depositors[msg.sender]).withdraw(_yieldCurrency, _yieldCurrencyId, _amount, actionType); 
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

    receive() external payable {}
}

// MN bby ¯\_(ツ)_/¯

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

interface IWETH {
    function withdraw(uint wad) external;
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

import "../interfaces/INotionalFinance.sol";


interface IS1NotionalFinanceProvideLiquidityProxy {
    function deposit(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _deposit, INotionalFinance.DepositActionType actionType) external payable;
    function withdraw(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, INotionalFinance.DepositActionType actionType) external returns(uint256);
    function claimToDepositor(address _depositor) external returns(uint256);
    function claimToDeployer() external returns(uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/INotionalFinance.sol";


contract S1NotionalFinanceProvideLiquidityProxy {
    address private deployer;
    address public notionalProxy;
    address public NOTE;

    constructor(
        address _deployer,
        address _notionalProxy,
        address _NOTE
    ) {
        deployer = _deployer;
        notionalProxy = _notionalProxy;
        NOTE = _NOTE;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "ERR: WRONG_DEPLOYER");
        _;
    } 

    function deposit(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, INotionalFinance.DepositActionType actionType) external payable onlyDeployer {
        if (_yieldCurrency != address(0) && _yieldCurrencyId != 1) {
            if (IERC20(_yieldCurrency).allowance(address(this), deployer) == 0) {
                IERC20(_yieldCurrency).approve(deployer, 2**256 - 1);
            }

            if (IERC20(_yieldCurrency).allowance(address(this), notionalProxy) == 0) {
                IERC20(_yieldCurrency).approve(notionalProxy, 2**256 - 1);
            }
            
            IERC20(_yieldCurrency).transferFrom(deployer, address(this), _amount);
        }

        INotionalFinance.BalanceAction[] memory actions = new INotionalFinance.BalanceAction[](1);
        actions[0] = INotionalFinance.BalanceAction({
            actionType: actionType,
            currencyId: _yieldCurrencyId,
            depositActionAmount: _amount,
            withdrawAmountInternalPrecision: 0,
            withdrawEntireCashBalance: false,
            redeemToUnderlying: false
        });

        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            INotionalFinance(notionalProxy).batchBalanceAction{value: _amount}(address(this), actions);
        } else {
            INotionalFinance(notionalProxy).batchBalanceAction(address(this), actions);
        }
    }

    function withdraw(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, INotionalFinance.DepositActionType actionType) external onlyDeployer returns(uint256) {
        INotionalFinance.BalanceAction[] memory actions = new INotionalFinance.BalanceAction[](1);
        actions[0] = INotionalFinance.BalanceAction({
            actionType: actionType,
            currencyId: _yieldCurrencyId,
            depositActionAmount: _amount,
            withdrawAmountInternalPrecision: 0,
            withdrawEntireCashBalance: true,
            redeemToUnderlying: true
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

    function claimToDepositor(address _depositor) external onlyDeployer returns(uint256) {
        return _claim(_depositor);
    }

    function claimToDeployer() external onlyDeployer returns(uint256) {
        return _claim(deployer);
    }

    function _claim(address _address) private returns(uint256) {
        INotionalFinance(notionalProxy).nTokenClaimIncentives();

        uint256 noteBalance = IERC20(NOTE).balanceOf(address(this));
        if (noteBalance > 0) {
            IERC20(NOTE).transfer(
                _address,
                noteBalance
            );
        }

        return noteBalance;
    }

    receive() external payable {}
}

// MN bby ¯\_(ツ)_/¯

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

    /**
     * @notice Prior to maturity, allows an account to withdraw their position from the vault. Will
     * redeem some number of vault shares to the borrow currency and close the borrow position by
     * lending `fCashToLend`. Any shortfall in cash from lending will be transferred from the account,
     * any excess profits will be transferred to the account.
     *
     * Post maturity, will net off the account's debt against vault cash balances and redeem all remaining
     * strategy tokens back to the borrowed currency and transfer the profits to the account.
     *
     * @param account the address that will exit the vault
     * @param vault the vault to enter
     * @param vaultSharesToRedeem amount of vault tokens to exit, only relevant when exiting pre-maturity
     * @param fCashToLend amount of fCash to lend
     * @param minLendRate the minimum rate to lend at
     * @param exitVaultData passed to the vault during exit
     * @return underlyingToReceiver amount of underlying tokens returned to the receiver on exit
     */
    function exitVault(
        address account,
        address vault,
        address receiver,
        uint256 vaultSharesToRedeem,
        uint256 fCashToLend,
        uint32 minLendRate,
        bytes calldata exitVaultData
    ) external payable returns (uint256 underlyingToReceiver);

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

    function getfCashNotional(
        address account,
        uint16 currencyId,
        uint256 maturity
    ) external view returns (int256);

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