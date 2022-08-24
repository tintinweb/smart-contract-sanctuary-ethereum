/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IFactory {
	function createPair(address tokenA, address tokenB)
	external
	returns (address pair);

	function getPair(address tokenA, address tokenB)
	external
	view
	returns (address pair);
}

interface IRouter {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function addLiquidityETH(
		address token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	)
	external
	payable
	returns (
		uint256 amountToken,
		uint256 amountETH,
		uint256 liquidity
	);

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable;

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
	function decimals() external view returns (uint8);
}

library SafeMath {

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");

		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;

		return c;
	}

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");

		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, "SafeMath: division by zero");
	}

	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}

	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor () {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}

	function owner() public view returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(_owner == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function renounceOwnership() public virtual onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

contract ERC20 is Context, IERC20, IERC20Metadata {
	using SafeMath for uint256;

	mapping(address => uint256) private _balances;
	mapping(address => mapping(address => uint256)) private _allowances;

	uint256 private _totalSupply;
	string private _name;
	string private _symbol;

	constructor(string memory name_, string memory symbol_) {
		_name = name_;
		_symbol = symbol_;
	}

	function name() public view virtual override returns (string memory) {
		return _name;
	}

	function symbol() public view virtual override returns (string memory) {
		return _symbol;
	}

	function decimals() public view virtual override returns (uint8) {
		return 18;
	}

	function totalSupply() public view virtual override returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public view virtual override returns (uint256) {
		return _balances[account];
	}

	function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) public view virtual override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) public virtual override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public virtual override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
		return true;
	}

	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal virtual {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");
		_beforeTokenTransfer(sender, recipient, amount);
		_balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
		_balances[recipient] = _balances[recipient].add(amount);
		emit Transfer(sender, recipient, amount);
	}

	function _mint(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: mint to the zero address");
		_beforeTokenTransfer(address(0), account, amount);
		_totalSupply = _totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);
	}

	function _burn(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: burn from the zero address");
		_beforeTokenTransfer(account, address(0), amount);
		_balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
		_totalSupply = _totalSupply.sub(amount);
		emit Transfer(account, address(0), amount);
	}

	function _approve(
		address owner,
		address spender,
		uint256 amount
	) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal virtual {}
}

contract SlakeToken is ERC20, Ownable {
    IRouter public uniswapV2Router;
    address public immutable uniswapV2Pair;

    string private constant _name = "Slake";
    string private constant _symbol = "SLAKE";
    uint8 private constant _decimals = 18;

    bool public isTradingEnabled;

    // initialSupply
    uint256 constant initialSupply = 500000000 * (10**18);

    address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // max wallet is 2.0% of initialSupply
    uint256 public maxWalletAmount = initialSupply * 200 / 10000;
    // max buy and sell tx is 1.0 % of initialSupply
    uint256 public maxTxAmount = initialSupply * 100 / 10000;

    bool private _swapping;
    uint256 public minimumTokensBeforeSwap = initialSupply * 25 / 100000;

    address public liquidityWallet;
    address public operationsWallet;
    address public buyBackWallet;

    struct CustomTaxPeriod {
        bytes23 periodName;
        uint8 blocksInPeriod;
        uint256 timeInPeriod;
        uint8 liquidityFeeOnBuy;
        uint8 liquidityFeeOnSell;
        uint8 operationsFeeOnBuy;
        uint8 operationsFeeOnSell;
        uint8 buyBackFeeOnBuy;
        uint8 buyBackFeeOnSell;
    }

    // Launch taxes
    bool private _isLaunched;
    uint256 private _launchStartTimestamp;
    uint256 private _launchBlockNumber;

    // Base taxes
    CustomTaxPeriod private _base = CustomTaxPeriod('base',0,0,1,1,7,7,2,2);
    CustomTaxPeriod private _launch = CustomTaxPeriod('base',0,0,1,2,7,7,2,3);

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromMaxTransactionLimit;
    mapping (address => bool) private _isExcludedFromMaxWalletLimit;
    mapping (address => bool) private _isAllowedToTradeWhenDisabled;
    mapping (address => bool) private _feeOnSelectedWalletTransfers;
    mapping (address => bool) public automatedMarketMakerPairs;

    uint8 private _liquidityFee;
    uint8 private _operationsFee;
    uint8 private _buyBackFee;
    uint8 private _totalFee;

    event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
    event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
    event WalletChange(string indexed indentifier, address indexed newWallet, address indexed oldWallet);
    event FeeChange(string indexed identifier, uint8 liquidityFee, uint8 operationsFee, uint8 buyBackFee);
    event CustomTaxPeriodChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType, bytes23 period);
    event MaxTransactionAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event MaxWalletAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event AllowedWhenTradingDisabledChange(address indexed account, bool isExcluded);
    event ExcludeFromFeesChange(address indexed account, bool isExcluded);
    event ExcludeFromMaxTransferChange(address indexed account, bool isExcluded);
    event ExcludeFromMaxWalletChange(address indexed account, bool isExcluded);
    event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived,uint256 tokensIntoLiqudity);
    event FeeOnSelectedWalletTransfersChange(address indexed account, bool newValue);
    event ClaimETHOverflow(uint256 amount);
    event FeesApplied(uint8 liquidityFee, uint8 operationsFee, uint8 buyBackFee, uint256 totalFee);

    constructor() ERC20(_name, _symbol) {
        liquidityWallet = owner();
        operationsWallet = owner();
        buyBackWallet = owner();

        IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Mainnet
        address _uniswapV2Pair = IFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _isAllowedToTradeWhenDisabled[owner()] = true;

        _isExcludedFromMaxTransactionLimit[address(this)] = true;

        _isExcludedFromMaxWalletLimit[_uniswapV2Pair] = true;
        _isExcludedFromMaxWalletLimit[address(uniswapV2Router)] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[owner()] = true;

        _mint(owner(), initialSupply);
    }

    receive() external payable {}

    // Setters
    function activateTrading() external onlyOwner {
        isTradingEnabled = true;
        if(_launchBlockNumber == 0) {
            _launchBlockNumber = block.number;
            _launchStartTimestamp = block.timestamp;
            _isLaunched = true;
        }
    }
    function deactivateTrading() external onlyOwner {
        isTradingEnabled = false;
    }
    function allowTradingWhenDisabled(address account, bool allowed) external onlyOwner {
		_isAllowedToTradeWhenDisabled[account] = allowed;
		emit AllowedWhenTradingDisabledChange(account, allowed);
	}
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "SLAKE: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit AutomatedMarketMakerPairChange(pair, value);
    }
    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromFee[account] != excluded, "SLAKE: Account is already the value of 'excluded'");
        _isExcludedFromFee[account] = excluded;
        emit ExcludeFromFeesChange(account, excluded);
    }
    function excludeFromMaxTransactionLimit(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromMaxTransactionLimit[account] != excluded, "SLAKE: Account is already the value of 'excluded'");
        _isExcludedFromMaxTransactionLimit[account] = excluded;
        emit ExcludeFromMaxTransferChange(account, excluded);
    }
    function excludeFromMaxWalletLimit(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromMaxWalletLimit[account] != excluded, "SLAKE: Account is already the value of 'excluded'");
        _isExcludedFromMaxWalletLimit[account] = excluded;
        emit ExcludeFromMaxWalletChange(account, excluded);
    }
    function setFeeOnSelectedWalletTransfers(address account, bool value) external onlyOwner {
		require(_feeOnSelectedWalletTransfers[account] != value, "SLAKE: The selected wallet is already set to the value ");
		_feeOnSelectedWalletTransfers[account] = value;
		emit FeeOnSelectedWalletTransfersChange(account, value);
	}
    function setWallets(address newLiquidityWallet, address newOperationsWallet, address newBuyBackWallet) external onlyOwner {
        if(liquidityWallet != newLiquidityWallet) {
            require(newLiquidityWallet != address(0), "SLAKE: The liquidityWallet cannot be 0");
            emit WalletChange('liquidityWallet', newLiquidityWallet, liquidityWallet);
            liquidityWallet = newLiquidityWallet;
        }
        if(operationsWallet != newOperationsWallet) {
            require(newOperationsWallet != address(0), "SLAKE: The operationsWallet cannot be 0");
            emit WalletChange('operationsWallet', newOperationsWallet, operationsWallet);
            operationsWallet = newOperationsWallet;
        }
        if(buyBackWallet != newBuyBackWallet) {
            require(newBuyBackWallet != address(0), "SLAKE: The buyBackWallet cannot be 0");
            emit WalletChange('buyBackWallet', newBuyBackWallet, buyBackWallet);
            buyBackWallet = newBuyBackWallet;
        }
    }
    // Base fees
    function setBaseFeesOnBuy(uint8 _liquidityFeeOnBuy, uint8 _operationsFeeOnBuy, uint8 _buyBackFeeOnBuy) external onlyOwner {
        _setCustomBuyTaxPeriod(_base, _liquidityFeeOnBuy, _operationsFeeOnBuy, _buyBackFeeOnBuy);
        emit FeeChange('baseFees-Buy', _liquidityFeeOnBuy, _operationsFeeOnBuy, _buyBackFeeOnBuy);
    }
    function setBaseFeesOnSell(uint8 _liquidityFeeOnSell,uint8 _operationsFeeOnSell , uint8 _buyBackFeeOnSell) external onlyOwner {
        _setCustomSellTaxPeriod(_base, _liquidityFeeOnSell, _operationsFeeOnSell, _buyBackFeeOnSell);
        emit FeeChange('baseFees-Sell', _liquidityFeeOnSell, _operationsFeeOnSell, _buyBackFeeOnSell);
    }
    function setUniswapRouter(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "SLAKE: The router already has that address");
        emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
        uniswapV2Router = IRouter(newAddress);
    }
    function setMaxTransactionAmount(uint256 newValue) external onlyOwner {
        require(newValue != maxTxAmount, "SLAKE: Cannot update maxTxAmount to same value");
        emit MaxTransactionAmountChange(newValue, maxTxAmount);
        maxTxAmount = newValue;
    }
    function setMaxWalletAmount(uint256 newValue) external onlyOwner {
        require(newValue != maxWalletAmount, "SLAKE: Cannot update maxWalletAmount to same value");
        emit MaxWalletAmountChange(newValue, maxWalletAmount);
        maxWalletAmount = newValue;
    }
    function setMinimumTokensBeforeSwap(uint256 newValue) external onlyOwner {
        require(newValue != minimumTokensBeforeSwap, "SLAKE: Cannot update minimumTokensBeforeSwap to same value");
        emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
        minimumTokensBeforeSwap = newValue;
    }
    function claimETHOverflow() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success,) = address(owner()).call{value : amount}("");
        if (success){
            emit ClaimETHOverflow(amount);
        }
    }

    // Getters
    function getBaseBuyFees() external view returns (uint8, uint8, uint8) {
        return (_base.liquidityFeeOnBuy, _base.operationsFeeOnBuy, _base.buyBackFeeOnBuy);
    }
    function getBaseSellFees() external view returns (uint8, uint8, uint8) {
        return (_base.liquidityFeeOnSell, _base.operationsFeeOnSell, _base.buyBackFeeOnSell);
    }

    // Main
    function _transfer(
        address from,
        address to,
        uint256 amount
        ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool isBuyFromLp = automatedMarketMakerPairs[from];
        bool isSelltoLp = automatedMarketMakerPairs[to];

        if(!_isAllowedToTradeWhenDisabled[from] && !_isAllowedToTradeWhenDisabled[to]) {
            require(isTradingEnabled, "SLAKE: Trading is currently disabled.");
            if (!_isExcludedFromMaxTransactionLimit[to] && !_isExcludedFromMaxTransactionLimit[from]) {
                require(amount <= maxTxAmount, "SLAKE: Buy amount exceeds the maxTxBuyAmount.");
            }
            if (!_isExcludedFromMaxWalletLimit[to]) {
                require((balanceOf(to) + amount) <= maxWalletAmount, "SLAKE: Expected wallet amount exceeds the maxWalletAmount.");
            }
        }

        _adjustTaxes(isBuyFromLp, isSelltoLp, from , to);
        bool canSwap = balanceOf(address(this)) >= minimumTokensBeforeSwap;

        if (
            isTradingEnabled &&
            canSwap &&
            !_swapping &&
            _totalFee > 0 &&
            automatedMarketMakerPairs[to]
        ) {
            _swapping = true;
            _swapAndLiquify();
            _swapping = false;
        }

        bool takeFee = !_swapping && isTradingEnabled;

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        if (takeFee && _totalFee > 0) {
            uint256 fee = amount * _totalFee / 100;
            amount = amount - fee;
            super._transfer(from, address(this), fee);
        }

        super._transfer(from, to, amount);
    }
    function _adjustTaxes(bool isBuyFromLp, bool isSelltoLp, address from, address to) private {
        _liquidityFee = 0;
        _operationsFee = 0;
        _buyBackFee = 0;

        if (isBuyFromLp) {
            _liquidityFee = _base.liquidityFeeOnBuy;
            _operationsFee = _base.operationsFeeOnBuy;
            _buyBackFee = _base.buyBackFeeOnBuy;

        }
        if (isSelltoLp) {
			if ((block.timestamp - _launchStartTimestamp) <= 86400*30) {
				_liquidityFee = _launch.liquidityFeeOnSell;
				_operationsFee = _launch.operationsFeeOnSell;
				_buyBackFee = _launch.buyBackFeeOnSell;
			}
			else {
				_liquidityFee = _base.liquidityFeeOnSell;
				_operationsFee = _base.operationsFeeOnSell;
				_buyBackFee = _base.buyBackFeeOnSell;
			}
        }
        if (!isSelltoLp && !isBuyFromLp && (_feeOnSelectedWalletTransfers[from] || _feeOnSelectedWalletTransfers[to])) {
			_liquidityFee = _base.liquidityFeeOnSell;
            _operationsFee = _base.operationsFeeOnSell;
            _buyBackFee = _base.buyBackFeeOnSell;
		}
        _totalFee = _liquidityFee + _operationsFee + _buyBackFee;
        emit FeesApplied(_liquidityFee, _operationsFee, _buyBackFee, _totalFee);
    }
    function _setCustomSellTaxPeriod(CustomTaxPeriod storage map,
        uint8 _liquidityFeeOnSell,
        uint8 _operationsFeeOnSell,
        uint8 _buyBackFeeOnSell
        ) private {
        if (map.liquidityFeeOnSell != _liquidityFeeOnSell) {
            emit CustomTaxPeriodChange(_liquidityFeeOnSell, map.liquidityFeeOnSell, 'liquidityFeeOnSell', map.periodName);
            map.liquidityFeeOnSell = _liquidityFeeOnSell;
        }
        if (map.operationsFeeOnSell != _operationsFeeOnSell) {
            emit CustomTaxPeriodChange(_operationsFeeOnSell, map.operationsFeeOnSell, 'operationsFeeOnSell', map.periodName);
            map.operationsFeeOnSell = _operationsFeeOnSell;
        }
        if (map.buyBackFeeOnSell != _buyBackFeeOnSell) {
            emit CustomTaxPeriodChange(_buyBackFeeOnSell, map.buyBackFeeOnSell, 'buyBackFeeOnSell', map.periodName);
            map.buyBackFeeOnSell = _buyBackFeeOnSell;
        }
    }
    function _setCustomBuyTaxPeriod(CustomTaxPeriod storage map,
        uint8 _liquidityFeeOnBuy,
        uint8 _operationsFeeOnBuy,
        uint8 _buyBackFeeOnBuy
        ) private {
        if (map.liquidityFeeOnBuy != _liquidityFeeOnBuy) {
            emit CustomTaxPeriodChange(_liquidityFeeOnBuy, map.liquidityFeeOnBuy, 'liquidityFeeOnBuy', map.periodName);
            map.liquidityFeeOnBuy = _liquidityFeeOnBuy;
        }
        if (map.operationsFeeOnBuy != _operationsFeeOnBuy) {
            emit CustomTaxPeriodChange(_operationsFeeOnBuy, map.operationsFeeOnBuy, 'operationsFeeOnBuy', map.periodName);
            map.operationsFeeOnBuy = _operationsFeeOnBuy;
        }
        if (map.buyBackFeeOnBuy != _buyBackFeeOnBuy) {
            emit CustomTaxPeriodChange(_buyBackFeeOnBuy, map.buyBackFeeOnBuy, 'buyBackFeeOnBuy', map.periodName);
            map.buyBackFeeOnBuy = _buyBackFeeOnBuy;
        }
    }
    function _swapAndLiquify() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 initialETHBalance = address(this).balance;
        uint8 _totalFeePrior = _totalFee;

        uint256 amountToLiquify = contractBalance * _liquidityFee / _totalFeePrior / 2;
        uint256 amountToSwap = contractBalance - amountToLiquify;

        _swapTokensForETH(amountToSwap);

        uint256 ETHBalanceAfterSwap = address(this).balance - initialETHBalance;
        uint256 totalETHFee = _totalFeePrior - (_liquidityFee / 2);
        uint256 amountETHLiquidity = ETHBalanceAfterSwap * _liquidityFee / totalETHFee / 2;
        uint256 amountETHOperations = ETHBalanceAfterSwap * _operationsFee / totalETHFee;
        uint256 amountETHBuyBack = ETHBalanceAfterSwap - (amountETHLiquidity + amountETHOperations);

        payable(buyBackWallet).transfer(amountETHBuyBack);

        _swapETHForCustomToken(amountETHOperations, USDC, operationsWallet);

        if (amountToLiquify > 0) {
            _addLiquidity(amountToLiquify, amountETHLiquidity);
            emit SwapAndLiquify(amountToSwap, amountETHLiquidity, amountToLiquify);
        }

        _totalFee = _totalFeePrior;
    }
    function _swapETHForCustomToken(uint256 ethAmount, address token, address wallet) private {
        address[] memory path = new address[](2);
		path[0] = uniswapV2Router.WETH();
		path[1] = token;
		uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value : ethAmount}(
			0, // accept any amount of ETH
			path,
			wallet,
			block.timestamp
		);
    }
    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
    }
}