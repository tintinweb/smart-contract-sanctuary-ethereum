/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
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
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

library Address {
	function isContract(address account) internal view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}

	function sendValue(address payable recipient, uint256 amount) internal {
		require(
			address(this).balance >= amount,
			"Address: insufficient balance"
		);

		(bool success, ) = recipient.call{value: amount}("");
		require(
			success,
			"Address: unable to send value, recipient may have reverted"
		);
	}

	function functionCall(address target, bytes memory data)
	internal
	returns (bytes memory)
	{
		return functionCall(target, data, "Address: low-level call failed");
	}

	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) internal returns (bytes memory) {
		return
		functionCallWithValue(
			target,
			data,
			value,
			"Address: low-level call with value failed"
		);
	}

	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(
			address(this).balance >= value,
			"Address: insufficient balance for call"
		);
		require(isContract(target), "Address: call to non-contract");

		(bool success, bytes memory returndata) = target.call{value: value}(
		data
		);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionStaticCall(address target, bytes memory data)
	internal
	view
	returns (bytes memory)
	{
		return
		functionStaticCall(
			target,
			data,
			"Address: low-level static call failed"
		);
	}

	function functionStaticCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal view returns (bytes memory) {
		require(isContract(target), "Address: static call to non-contract");

		(bool success, bytes memory returndata) = target.staticcall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionDelegateCall(address target, bytes memory data)
	internal
	returns (bytes memory)
	{
		return
		functionDelegateCall(
			target,
			data,
			"Address: low-level delegate call failed"
		);
	}

	function functionDelegateCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(isContract(target), "Address: delegate call to non-contract");

		(bool success, bytes memory returndata) = target.delegatecall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function _verifyCallResult(
		bool success,
		bytes memory returndata,
		string memory errorMessage
	) private pure returns (bytes memory) {
		if (success) {
			return returndata;
		} else {
			if (returndata.length > 0) {
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

    constructor() {
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

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }


    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract BaltoToken is Ownable, ERC20 {
    using Address for address;

    IRouter public uniswapV2Router;
    address public immutable uniswapV2Pair;

    string private constant _name = "Balto Token";
    string private constant _symbol = "BALTO";

    bool public isTradingEnabled;

    uint256 public initialSupply = 220000000 * (10**18);

    // max buy and sell tx is 2.25% of initialSupply
    uint256 public maxTxAmount = initialSupply * 225 / 10000;

    // max wallet is 1% of initialSupply
    uint256 public maxWalletAmount = initialSupply * 100 / 10000;

    bool private _swapping;
    uint256 public minimumTokensBeforeSwap = initialSupply * 25 / 100000;

    address public liquidityWallet;
    address public operationsWallet;
    address public buyBackWallet;
    address public charityWallet;
    address public otherWallet;

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
        uint8 charityFeeOnBuy;
        uint8 charityFeeOnSell;
        uint8 otherFeeOnBuy;
        uint8 otherFeeOnSell;
    }

    // Base taxes
    CustomTaxPeriod private _base = CustomTaxPeriod("base", 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2);

    bool private _isLaunched;
    uint256 private _launchStartTimestamp;
    uint256 private _launchBlockNumber;

    mapping (address => bool) private _isBlocked;
    mapping(address => bool) private _isAllowedToTradeWhenDisabled;
    mapping(address => bool) private _feeOnSelectedWalletTransfers;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMaxTransactionLimit;
    mapping(address => bool) private _isExcludedFromMaxWalletLimit;
    mapping(address => bool) public automatedMarketMakerPairs;

    uint8 private _liquidityFee;
    uint8 private _operationsFee;
    uint8 private _buyBackFee;
    uint8 private _charityFee;
    uint8 private _otherFee;
    uint8 private _totalFee;

    event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
    event BlockedAccountChange(address indexed holder, bool indexed status);
    event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
    event WalletChange(string indexed indentifier,address indexed newWallet,address indexed oldWallet);
    event FeeChange(string indexed identifier,uint8 liquidityFee,uint8 operationsFee,uint8 buyBackFee,uint8 charityFee,uint8 otherFee);
    event CustomTaxPeriodChange(uint256 indexed newValue,uint256 indexed oldValue,string indexed taxType,bytes23 period);
    event MaxTransactionAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event MaxWalletAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event ExcludeFromFeesChange(address indexed account, bool isExcluded);
    event ExcludeFromMaxTransferChange(address indexed account, bool isExcluded);
    event ExcludeFromMaxWalletChange(address indexed account, bool isExcluded);
    event AllowedWhenTradingDisabledChange(address indexed account, bool isExcluded);
    event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event FeeOnSelectedWalletTransfersChange(address indexed account, bool newValue);
    event ClaimETHOverflow(uint256 amount);
    event FeesApplied(uint8 liquidityFee,uint8 operationsFee,uint8 buyBackFee,uint8 charityFee,uint8 otherFee,uint8 totalFee);

    constructor() ERC20(_name, _symbol) {
        liquidityWallet = owner();
        operationsWallet = owner();
        buyBackWallet = owner();
        otherWallet = owner();

        IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IFactory(_uniswapV2Router.factory()).createPair(address(this),_uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _isAllowedToTradeWhenDisabled[owner()] = true;
        _isAllowedToTradeWhenDisabled[address(this)] = true;

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
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value,"Balto: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit AutomatedMarketMakerPairChange(pair, value);
    }
    function allowTradingWhenDisabled(address account, bool allowed) external onlyOwner {
        _isAllowedToTradeWhenDisabled[account] = allowed;
        emit AllowedWhenTradingDisabledChange(account, allowed);
    }
    function blockAccount(address account) external onlyOwner {
        require(!_isBlocked[account], "Balto: Account is already blocked");
        if (_isLaunched) {
            require((block.timestamp - _launchStartTimestamp) < 172800, "Balto: Time to block accounts has expired");
        }
        _isBlocked[account] = true;
        emit BlockedAccountChange(account, true);
    }
    function unblockAccount(address account) external onlyOwner {
        require(_isBlocked[account], "Balto: Account is not blcoked");
        _isBlocked[account] = false;
        emit BlockedAccountChange(account, false);
    }
    function setFeeOnSelectedWalletTransfers(address account, bool value) external onlyOwner {
        require(_feeOnSelectedWalletTransfers[account] != value,"Balto: The selected wallet is already set to the value ");
        _feeOnSelectedWalletTransfers[account] = value;
        emit FeeOnSelectedWalletTransfersChange(account, value);
    }
    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromFee[account] != excluded,"Balto: Account is already the value of 'excluded'");
        _isExcludedFromFee[account] = excluded;
        emit ExcludeFromFeesChange(account, excluded);
    }
    function excludeFromMaxTransactionLimit(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromMaxTransactionLimit[account] != excluded,"Balto: Account is already the value of 'excluded'");
        _isExcludedFromMaxTransactionLimit[account] = excluded;
        emit ExcludeFromMaxTransferChange(account, excluded);
    }
    function excludeFromMaxWalletLimit(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromMaxWalletLimit[account] != excluded,"Balto: Account is already the value of 'excluded'");
        _isExcludedFromMaxWalletLimit[account] = excluded;
        emit ExcludeFromMaxWalletChange(account, excluded);
    }
    function setWallets(
        address newLiquidityWallet,address newOperationsWallet,address newBuyBackWallet,address newCharityWallet,address newOtherWallet
    ) external onlyOwner {
        if (liquidityWallet != newLiquidityWallet) {
            require(newLiquidityWallet != address(0), "Balto: The liquidityWallet cannot be 0");
            emit WalletChange("liquidityWallet", newLiquidityWallet, liquidityWallet);
            liquidityWallet = newLiquidityWallet;
        }
        if (operationsWallet != newOperationsWallet) {
            require(newOperationsWallet != address(0), "Balto: The operationsWallet cannot be 0");
            emit WalletChange("operationsWallet", newOperationsWallet, operationsWallet);
            operationsWallet = newOperationsWallet;
        }
        if (buyBackWallet != newBuyBackWallet) {
            require(newBuyBackWallet != address(0), "Balto: The buyBackWallet cannot be 0");
            emit WalletChange("buyBackWallet", newBuyBackWallet, buyBackWallet);
            buyBackWallet = newBuyBackWallet;
        }
        if (charityWallet != newCharityWallet) {
            require(newCharityWallet != address(0), "Balto: The charityWallet cannot be 0");
            emit WalletChange("charityWallet", newCharityWallet, charityWallet);
            charityWallet = newCharityWallet;
        }
        if (otherWallet != newOtherWallet) {
            require(newOtherWallet != address(0), "Balto: The otherWallet cannot be 0");
            emit WalletChange("otherWallet", newOtherWallet, otherWallet);
            otherWallet = newOtherWallet;
        }
    }
    // Base fees
    function setBaseFeesOnBuy(uint8 _liquidityFeeOnBuy,uint8 _operationsFeeOnBuy,uint8 _buyBackFeeOnBuy,uint8 _charityFeeOnBuy,uint8 _otherFeeOnBuy) external onlyOwner {
        _setCustomBuyTaxPeriod(_base,_liquidityFeeOnBuy,_operationsFeeOnBuy,_buyBackFeeOnBuy,_charityFeeOnBuy,_otherFeeOnBuy);
        emit FeeChange("baseFees-Buy",_liquidityFeeOnBuy,_operationsFeeOnBuy,_buyBackFeeOnBuy,_charityFeeOnBuy,_otherFeeOnBuy);
    }
    function setBaseFeesOnSell(uint8 _liquidityFeeOnSell,uint8 _operationsFeeOnSell,uint8 _buyBackFeeOnSell,uint8 _charityFeeOnSell,uint8 _otherFeeOnSell) external onlyOwner {
        _setCustomSellTaxPeriod(_base,_liquidityFeeOnSell,_operationsFeeOnSell,_buyBackFeeOnSell,_charityFeeOnSell,_otherFeeOnSell);
        emit FeeChange("baseFees-Sell",_liquidityFeeOnSell,_operationsFeeOnSell,_buyBackFeeOnSell,_charityFeeOnSell,_otherFeeOnSell);
    }
    function setUniswapRouter(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router),"Balto: The router already has that address");
        emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
        uniswapV2Router = IRouter(newAddress);
    }
    function setMaxTransactionAmount(uint256 newValue) external onlyOwner {
        require(newValue != maxTxAmount, "Balto: Cannot update maxTxAmount to same value");
        emit MaxTransactionAmountChange(newValue, maxTxAmount);
        maxTxAmount = newValue;
    }
    function setMaxWalletAmount(uint256 newValue) external onlyOwner {
        require(newValue != maxWalletAmount,"Balto: Cannot update maxWalletAmount to same value");
        emit MaxWalletAmountChange(newValue, maxWalletAmount);
        maxWalletAmount = newValue;
    }
    function setMinimumTokensBeforeSwap(uint256 newValue) external onlyOwner {
        require(newValue != minimumTokensBeforeSwap,"Balto: Cannot update minimumTokensBeforeSwap to same value");
        emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
        minimumTokensBeforeSwap = newValue;
    }
    function claimETHOverflow(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Balto: Cannot send more than contract balance");
        (bool success, ) = address(owner()).call{ value: amount }("");
        if (success) {
            emit ClaimETHOverflow(amount);
        }
    }

    // Getters
    function getBaseBuyFees() external view returns (uint8,uint8,uint8,uint8,uint8) {
        return (_base.liquidityFeeOnBuy,_base.operationsFeeOnBuy,_base.buyBackFeeOnBuy,_base.charityFeeOnBuy,_base.otherFeeOnBuy);
    }
    function getBaseSellFees() external view returns (uint8,uint8,uint8,uint8,uint8) {
        return (_base.liquidityFeeOnSell,_base.operationsFeeOnSell,_base.buyBackFeeOnSell,_base.charityFeeOnSell,_base.otherFeeOnSell);
    }
    // Main
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (!_isAllowedToTradeWhenDisabled[from] && !_isAllowedToTradeWhenDisabled[to]) {
            require(isTradingEnabled, "Balto: Trading is currently disabled.");
            require(!_isBlocked[to], "Balto: Account is blocked");
            require(!_isBlocked[from], "Balto: Account is blocked");
            if (!_isExcludedFromMaxTransactionLimit[to] && !_isExcludedFromMaxTransactionLimit[from]) {
                require(amount <= maxTxAmount, "Balto: Buy amount exceeds the maxTxBuyAmount.");
            }
            if (!_isExcludedFromMaxWalletLimit[to]) {
                require((balanceOf(to) + amount) <= maxWalletAmount, "Balto: Expected wallet amount exceeds the maxWalletAmount.");
            }
        }

        _adjustTaxes(automatedMarketMakerPairs[from], automatedMarketMakerPairs[to], from, to);
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

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        if (takeFee && _totalFee > 0) {
            uint256 fee = (amount * _totalFee) / 100;
            amount = amount - fee;
            super._transfer(from, address(this), fee);
        }
        super._transfer(from, to, amount);
    }

    function _adjustTaxes(bool isBuyFromLp,bool isSelltoLp,address from,address to) private {
        _liquidityFee = 0;
        _operationsFee = 0;
        _buyBackFee = 0;
        _charityFee = 0;
        _otherFee = 0;

        if (isBuyFromLp) {
            if (_isLaunched && block.number - _launchBlockNumber <= 5) {
                _liquidityFee = 100;
            } else {
                _liquidityFee = _base.liquidityFeeOnBuy;
                _operationsFee = _base.operationsFeeOnBuy;
                _buyBackFee = _base.buyBackFeeOnBuy;
                _charityFee = _base.charityFeeOnBuy;
                _otherFee = _base.otherFeeOnBuy;
            }
        }
        if (isSelltoLp) {
            _liquidityFee = _base.liquidityFeeOnSell;
            _operationsFee = _base.operationsFeeOnSell;
            _buyBackFee = _base.buyBackFeeOnSell;
            _charityFee = _base.charityFeeOnSell;
            _otherFee = _base.otherFeeOnSell;
        }
        if (!isSelltoLp && !isBuyFromLp && (_feeOnSelectedWalletTransfers[from] || _feeOnSelectedWalletTransfers[to])) {
            _liquidityFee = _base.liquidityFeeOnBuy;
            _operationsFee = _base.operationsFeeOnBuy;
            _buyBackFee = _base.buyBackFeeOnBuy;
            _charityFee = _base.charityFeeOnBuy;
            _otherFee = _base.otherFeeOnBuy;
        }
        _totalFee = _liquidityFee + _operationsFee + _buyBackFee + _charityFee + _otherFee;
        emit FeesApplied(_liquidityFee, _operationsFee, _buyBackFee, _charityFee, _otherFee, _totalFee);
    }

    function _setCustomSellTaxPeriod(CustomTaxPeriod storage map,uint8 _liquidityFeeOnSell,uint8 _operationsFeeOnSell,uint8 _buyBackFeeOnSell,uint8 _charityFeeOnSell,uint8 _otherFeeOnSell) private {
        if (map.liquidityFeeOnSell != _liquidityFeeOnSell) {
            emit CustomTaxPeriodChange(_liquidityFeeOnSell,map.liquidityFeeOnSell,"liquidityFeeOnSell",map.periodName);
            map.liquidityFeeOnSell = _liquidityFeeOnSell;
        }
        if (map.operationsFeeOnSell != _operationsFeeOnSell) {
            emit CustomTaxPeriodChange(_operationsFeeOnSell,map.operationsFeeOnSell,"operationsFeeOnSell",map.periodName);
            map.operationsFeeOnSell = _operationsFeeOnSell;
        }
        if (map.buyBackFeeOnSell != _buyBackFeeOnSell) {
            emit CustomTaxPeriodChange(_buyBackFeeOnSell,map.buyBackFeeOnSell,"buyBackFeeOnSell",map.periodName);
            map.buyBackFeeOnSell = _buyBackFeeOnSell;
        }
        if (map.charityFeeOnSell != _charityFeeOnSell) {
            emit CustomTaxPeriodChange(_charityFeeOnSell,map.charityFeeOnSell,"charityFeeOnSell",map.periodName);
            map.charityFeeOnSell = _charityFeeOnSell;
        }
        if (map.otherFeeOnSell != _otherFeeOnSell) {
            emit CustomTaxPeriodChange(_otherFeeOnSell,map.otherFeeOnSell,"otherFeeOnSell",map.periodName);
            map.otherFeeOnSell = _otherFeeOnSell;
        }
    }
    function _setCustomBuyTaxPeriod(CustomTaxPeriod storage map,uint8 _liquidityFeeOnBuy,uint8 _operationsFeeOnBuy,uint8 _buyBackFeeOnBuy,uint8 _charityFeeOnBuy,uint8 _otherFeeOnBuy) private {
        if (map.liquidityFeeOnBuy != _liquidityFeeOnBuy) {
            emit CustomTaxPeriodChange(_liquidityFeeOnBuy,map.liquidityFeeOnBuy,"liquidityFeeOnBuy",map.periodName);
            map.liquidityFeeOnBuy = _liquidityFeeOnBuy;
        }
        if (map.operationsFeeOnBuy != _operationsFeeOnBuy) {
            emit CustomTaxPeriodChange(_operationsFeeOnBuy,map.operationsFeeOnBuy,"operationsFeeOnBuy",map.periodName);
            map.operationsFeeOnBuy = _operationsFeeOnBuy;
        }
        if (map.buyBackFeeOnBuy != _buyBackFeeOnBuy) {
            emit CustomTaxPeriodChange(_buyBackFeeOnBuy,map.buyBackFeeOnBuy,"buyBackFeeOnBuy",map.periodName);
            map.buyBackFeeOnBuy = _buyBackFeeOnBuy;
        }
        if (map.charityFeeOnBuy != _charityFeeOnBuy) {
            emit CustomTaxPeriodChange(_charityFeeOnBuy,map.charityFeeOnBuy,"charityFeeOnBuy",map.periodName);
            map.charityFeeOnBuy = _charityFeeOnBuy;
        }
        if (map.otherFeeOnBuy != _otherFeeOnBuy) {
            emit CustomTaxPeriodChange(_otherFeeOnBuy,map.otherFeeOnBuy,"otherFeeOnBuy",map.periodName);
            map.otherFeeOnBuy = _otherFeeOnBuy;
        }
    }

    function _swapAndLiquify() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 initialETHBalance = address(this).balance;

        uint256 amountToLiquify = (contractBalance * _liquidityFee) / _totalFee / 2;
        uint256 amountToSwap = contractBalance - amountToLiquify;

        _swapTokensForETH(amountToSwap);

        uint256 ETHBalanceAfterSwap = address(this).balance - initialETHBalance;
        uint256 totalETHFee = _totalFee - (_liquidityFee / 2);
        uint256 amountETHLiquidity = (ETHBalanceAfterSwap * _liquidityFee) / totalETHFee / 2;
        uint256 amountETHOperations = (ETHBalanceAfterSwap * _operationsFee) / totalETHFee;
        uint256 amountETHBuyBack = (ETHBalanceAfterSwap * _buyBackFee) / totalETHFee;
        uint256 amountETHCharity = (ETHBalanceAfterSwap * _charityFee) / totalETHFee;
        uint256 amountETHOther = ETHBalanceAfterSwap - (amountETHLiquidity + amountETHBuyBack + amountETHOperations + amountETHCharity);

        Address.sendValue(payable(operationsWallet),amountETHOperations);
        Address.sendValue(payable(buyBackWallet),amountETHBuyBack);
        Address.sendValue(payable(charityWallet),amountETHCharity);
        Address.sendValue(payable(otherWallet),amountETHOther);

        if (amountToLiquify > 0) {
            _addLiquidity(amountToLiquify, amountETHLiquidity);
            emit SwapAndLiquify(amountToSwap, amountETHLiquidity, amountToLiquify);
        }
    }

    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            1, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{ value: ethAmount }(
            address(this),
            tokenAmount,
            1, // slippage is unavoidable
            1, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
    }
}