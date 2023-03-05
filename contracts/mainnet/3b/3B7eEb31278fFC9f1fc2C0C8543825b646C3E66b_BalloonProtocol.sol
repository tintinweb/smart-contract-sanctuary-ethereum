/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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

contract BalloonProtocol is Ownable, ERC20 {
    using Address for address;

    IRouter public uniswapV2Router;
    address public immutable uniswapV2Pair;

    string private constant _name = "Balloon Protocol";
    string private constant _symbol = "AIR";

    bool public isTradingEnabled;

    uint256 public initialSupply = 1000000 * (10**18);

    // max tx is 2% of initialSupply
    uint256 public maxTxAmount = initialSupply * 200 / 10000;

    // max wallet is 2% of initialSupply
    uint256 public maxWalletAmount = initialSupply * 200 / 10000;

    bool private _swapping;
    uint256 public minimumTokensBeforeSwap = initialSupply * 25 / 100000;

    address public liquidityWallet;
    address public operationsWallet;
    address public targetAWallet;
    address public targetBWallet;
    address public targetCWallet;

    struct CustomTaxPeriod {
        bytes23 periodName;
        uint16 liquidityFeeOnBuy;
        uint16 liquidityFeeOnSell;
        uint16 operationsFeeOnBuy;
        uint16 operationsFeeOnSell;
        uint16 targetAFeeOnBuy;
        uint16 targetAFeeOnSell;
        uint16 targetBFeeOnBuy;
        uint16 targetBFeeOnSell;
        uint16 targetCFeeOnBuy;
        uint16 targetCFeeOnSell;
    }

    // Base taxes
    CustomTaxPeriod private _base = CustomTaxPeriod("base", 10, 10, 10, 10, 80, 80, 5, 5, 5, 5);

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

    uint16 private _liquidityFee;
    uint16 private _operationsFee;
    uint16 private _targetAFee;
    uint16 private _targetBFee;
    uint16 private _targetCFee;
    uint16 private _totalFee;

    event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
    event BlockedAccountChange(address indexed holder, bool indexed status);
    event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
    event WalletChange(string indexed indentifier,address indexed newWallet,address indexed oldWallet);
    event FeeChange(string indexed identifier,uint16 liquidityFee,uint16 operationsFee,uint16 targetAFee, uint16 targetBFee, uint16 targetCFee);
    event CustomTaxPeriodChange(uint256 indexed newValue,uint256 indexed oldValue,string indexed taxType,bytes23 period);
    event MaxTransactionAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event MaxWalletAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event ExcludeFromFeesChange(address indexed account, bool isExcluded);
    event ExcludeFromMaxTransferChange(address indexed account, bool isExcluded);
    event ExcludeFromMaxWalletChange(address indexed account, bool isExcluded);
    event AllowedWhenTradingDisabledChange(address indexed account, bool isExcluded);
    event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
    event FeeOnSelectedWalletTransfersChange(address indexed account, bool newValue);
    event ClaimOverflow(address token, uint256 amount);
    event TradingStatusChange(bool indexed newValue, bool indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event FeesApplied(uint16 liquidityFee,uint16 operationsFee,uint16 targetAFee, uint16 targetBFee, uint16 targetCFee, uint16 totalFee);

    constructor() ERC20(_name, _symbol) {
        liquidityWallet = owner();
        operationsWallet = owner();
        targetAWallet = owner();
        targetBWallet = owner();
        targetCWallet = owner();

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
        _isExcludedFromMaxTransactionLimit[_uniswapV2Pair] = true;

        _isExcludedFromMaxWalletLimit[_uniswapV2Pair] = true;
        _isExcludedFromMaxWalletLimit[address(uniswapV2Router)] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[owner()] = true;

        _mint(owner(), initialSupply);
    }

    receive() external payable {}

    function activateTrading() external onlyOwner {
        isTradingEnabled = true;
        if(_launchBlockNumber == 0) {
            _launchBlockNumber = block.number;
            _launchStartTimestamp = block.timestamp;
            _isLaunched = true;
        }
        emit TradingStatusChange(true, false);
    }
    function deactivateTrading() external onlyOwner {
        isTradingEnabled = false;
        emit TradingStatusChange(false, true);
    }
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value,"Balloon Protocol: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit AutomatedMarketMakerPairChange(pair, value);
    }
    function allowTradingWhenDisabled(address account, bool allowed) external onlyOwner {
        _isAllowedToTradeWhenDisabled[account] = allowed;
        emit AllowedWhenTradingDisabledChange(account, allowed);
    }
    function blockAccount(address account) external onlyOwner {
        require(!_isBlocked[account], "Balloon Protocol: Account is already blocked");
        if (_isLaunched) {
            require((block.timestamp - _launchStartTimestamp) < 172800, "Balloon Protocol: Time to block accounts has expired");
        }
        _isBlocked[account] = true;
        emit BlockedAccountChange(account, true);
    }
    function unblockAccount(address account) external onlyOwner {
        require(_isBlocked[account], "Balloon Protocol: Account is not blcoked");
        _isBlocked[account] = false;
        emit BlockedAccountChange(account, false);
    }
    function setFeeOnSelectedWalletTransfers(address account, bool value) external onlyOwner {
        require(_feeOnSelectedWalletTransfers[account] != value,"Balloon Protocol: The selected wallet is already set to the value ");
        _feeOnSelectedWalletTransfers[account] = value;
        emit FeeOnSelectedWalletTransfersChange(account, value);
    }
    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromFee[account] != excluded,"Balloon Protocol: Account is already the value of 'excluded'");
        _isExcludedFromFee[account] = excluded;
        emit ExcludeFromFeesChange(account, excluded);
    }
    function excludeFromMaxTransactionLimit(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromMaxTransactionLimit[account] != excluded,"Balloon Protocol: Account is already the value of 'excluded'");
        _isExcludedFromMaxTransactionLimit[account] = excluded;
        emit ExcludeFromMaxTransferChange(account, excluded);
    }
    function excludeFromMaxWalletLimit(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromMaxWalletLimit[account] != excluded,"Balloon Protocol: Account is already the value of 'excluded'");
        _isExcludedFromMaxWalletLimit[account] = excluded;
        emit ExcludeFromMaxWalletChange(account, excluded);
    }
    function setWallets(address newLiquidityWallet,address newOperationsWallet,address newTargetAWallet, address newTargetBWallet, address newTargetCWallet) external onlyOwner {
        if (liquidityWallet != newLiquidityWallet) {
            require(newLiquidityWallet != address(0), "Balloon Protocol: The liquidityWallet cannot be 0");
            emit WalletChange("liquidityWallet", newLiquidityWallet, liquidityWallet);
            liquidityWallet = newLiquidityWallet;
        }
        if (operationsWallet != newOperationsWallet) {
            require(newOperationsWallet != address(0), "Balloon Protocol: The operationsWallet cannot be 0");
            emit WalletChange("operationsWallet", newOperationsWallet, operationsWallet);
            operationsWallet = newOperationsWallet;
        }
        if (targetAWallet != newTargetAWallet) {
            require(newTargetAWallet != address(0), "Balloon Protocol: The targetAWallet cannot be 0");
            emit WalletChange("targetAWallet", newTargetAWallet, targetAWallet);
            targetAWallet = newTargetAWallet;
        }
        if (targetBWallet != newTargetBWallet) {
            require(newTargetBWallet != address(0), "Balloon Protocol: The targetBWallet cannot be 0");
            emit WalletChange("targetBWallet", newTargetBWallet, targetBWallet);
            targetBWallet = newTargetBWallet;
        }
        if (targetCWallet != newTargetCWallet) {
            require(newTargetCWallet != address(0), "Balloon Protocol: The targetCWallet cannot be 0");
            emit WalletChange("targetCWallet", newTargetCWallet, targetCWallet);
            targetCWallet = newTargetCWallet;
        }
    }
    // Base fees
    function setBaseFeesOnBuy(uint16 _liquidityFeeOnBuy,uint16 _operationsFeeOnBuy,uint16 _targetAFeeOnBuy, uint16 _targetBFeeOnBuy, uint16 _targetCFeeOnBuy) external onlyOwner {
        require(_liquidityFeeOnBuy + _operationsFeeOnBuy + _targetAFeeOnBuy + _targetBFeeOnBuy + _targetCFeeOnBuy <= 150, "Balloon Protocol: Fees must be less or equal to 15%");
        _setCustomBuyTaxPeriod(_base,_liquidityFeeOnBuy,_operationsFeeOnBuy,_targetAFeeOnBuy,_targetBFeeOnBuy, _targetCFeeOnBuy);
        emit FeeChange("baseFees-Buy",_liquidityFeeOnBuy,_operationsFeeOnBuy,_targetAFeeOnBuy,_targetBFeeOnBuy, _targetCFeeOnBuy);
    }
    function setBaseFeesOnSell(uint16 _liquidityFeeOnSell,uint16 _operationsFeeOnSell,uint16 _targetAFeeOnSell, uint16 _targetBFeeOnSell, uint16 _targetCFeeOnSell) external onlyOwner {
        require(_liquidityFeeOnSell + _operationsFeeOnSell + _targetAFeeOnSell + _targetBFeeOnSell + _targetCFeeOnSell <= 150, "Balloon Protocol: Fees must be less or equal to 15%");
        _setCustomSellTaxPeriod(_base,_liquidityFeeOnSell,_operationsFeeOnSell,_targetAFeeOnSell, _targetBFeeOnSell, _targetCFeeOnSell);
        emit FeeChange("baseFees-Sell",_liquidityFeeOnSell,_operationsFeeOnSell,_targetAFeeOnSell, _targetBFeeOnSell, _targetCFeeOnSell);
    }
    function setUniswapRouter(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router),"Balloon Protocol: The router already has that address");
        emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
        uniswapV2Router = IRouter(newAddress);
    }
    function setMaxTransactionAmount(uint256 newValue) external onlyOwner {
        require(newValue >= initialSupply * 50 / 10000, "Balloon Protocol: Max Transation value must be greater than or equal to 0.5% of supply");
        require(newValue != maxTxAmount, "Balloon Protocol: Cannot update maxTxAmount to same value");
        emit MaxTransactionAmountChange(newValue, maxTxAmount);
        maxTxAmount = newValue;
    }
    function setMaxWalletAmount(uint256 newValue) external onlyOwner {
        require(newValue >= initialSupply * 50 / 10000, "Balloon Protocol: Max wallet value must be greater than or equal to 0.5% of supply");
        require(newValue != maxWalletAmount,"Balloon Protocol: Cannot update maxWalletAmount to same value");
        emit MaxWalletAmountChange(newValue, maxWalletAmount);
        maxWalletAmount = newValue;
    }
    function setMinimumTokensBeforeSwap(uint256 newValue) external onlyOwner {
        require(newValue != minimumTokensBeforeSwap,"Balloon Protocol: Cannot update minimumTokensBeforeSwap to same value");
        emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
        minimumTokensBeforeSwap = newValue;
    }
    function claimETHOverflow(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Balloon Protocol: Cannot send more than contract balance");
        (bool success, ) = address(owner()).call{ value: amount }("");
        if (success) {
            emit ClaimOverflow(uniswapV2Router.WETH(), amount);
        }
    }

    // Getters
    function getBaseBuyFees() external view returns (uint16,uint16,uint16,uint16,uint16) {
        return (_base.liquidityFeeOnBuy,_base.operationsFeeOnBuy,_base.targetAFeeOnBuy,_base.targetBFeeOnBuy,_base.targetCFeeOnBuy);
    }
    function getBaseSellFees() external view returns (uint16,uint16,uint16,uint16,uint16) {
        return (_base.liquidityFeeOnSell,_base.operationsFeeOnSell,_base.targetAFeeOnSell,_base.targetBFeeOnSell,_base.targetCFeeOnSell);
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
            require(isTradingEnabled, "Balloon Protocol: Trading is currently disabled.");
            require(!_isBlocked[to], "Balloon Protocol: Account is blocked");
            require(!_isBlocked[from], "Balloon Protocol: Account is blocked");
            if (!_isExcludedFromMaxTransactionLimit[to] && !_isExcludedFromMaxTransactionLimit[from]) {
                require(amount <= maxTxAmount, "Balloon Protocol: Buy amount exceeds the maxTxAmount.");
            }
            if (!_isExcludedFromMaxWalletLimit[to]) {
                require((balanceOf(to) + amount) <= maxWalletAmount, "Balloon Protocol: Expected wallet amount exceeds the maxWalletAmount.");
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
            _swapAndTransfer();
            _swapping = false;
        }

        bool takeFee = !_swapping && isTradingEnabled;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        if (takeFee && _totalFee > 0) {
            uint256 fee = (amount * _totalFee) / 1000;
            amount = amount - fee;
            super._transfer(from, address(this), fee);
        }
        super._transfer(from, to, amount);
    }
    function _adjustTaxes(bool isBuyFromLp,bool isSelltoLp,address from,address to) private {
        _liquidityFee = 0;
        _operationsFee = 0;
        _targetAFee = 0;
        _targetBFee = 0;
        _targetCFee = 0;

        if (isBuyFromLp) {
            if (_isLaunched && block.timestamp - _launchBlockNumber <= 5) {
                _liquidityFee = 1000;
            } else {
                _liquidityFee = _base.liquidityFeeOnBuy;
                _operationsFee = _base.operationsFeeOnBuy;
                _targetAFee = _base.targetAFeeOnBuy;
                _targetBFee = _base.targetBFeeOnBuy;
                _targetCFee = _base.targetCFeeOnBuy;
            }
        }
        if (isSelltoLp || (!isSelltoLp && !isBuyFromLp && (_feeOnSelectedWalletTransfers[from] || _feeOnSelectedWalletTransfers[to]))) {
            _liquidityFee = _base.liquidityFeeOnSell;
            _operationsFee = _base.operationsFeeOnSell;
            _targetAFee = _base.targetAFeeOnSell;
            _targetBFee = _base.targetBFeeOnSell;
            _targetCFee = _base.targetCFeeOnSell;
        }
        _totalFee = _liquidityFee + _operationsFee + _targetAFee + _targetBFee + _targetCFee;
        emit FeesApplied(_liquidityFee, _operationsFee, _targetAFee, _targetBFee, _targetCFee, _totalFee);
    }
    function _setCustomSellTaxPeriod(CustomTaxPeriod storage map,uint16 _liquidityFeeOnSell,uint16 _operationsFeeOnSell,uint16 _targetAFeeOnSell, uint16 _targetBFeeOnSell, uint16 _targetCFeeOnSell ) private {
        if (map.liquidityFeeOnSell != _liquidityFeeOnSell) {
            emit CustomTaxPeriodChange(_liquidityFeeOnSell,map.liquidityFeeOnSell,"liquidityFeeOnSell",map.periodName);
            map.liquidityFeeOnSell = _liquidityFeeOnSell;
        }
        if (map.operationsFeeOnSell != _operationsFeeOnSell) {
            emit CustomTaxPeriodChange(_operationsFeeOnSell,map.operationsFeeOnSell,"operationsFeeOnSell",map.periodName);
            map.operationsFeeOnSell = _operationsFeeOnSell;
        }
        if (map.targetAFeeOnSell != _targetAFeeOnSell) {
            emit CustomTaxPeriodChange(_targetAFeeOnSell,map.targetAFeeOnSell,"targetAFeeOnSell",map.periodName);
            map.targetAFeeOnSell = _targetAFeeOnSell;
        }
        if (map.targetBFeeOnSell != _targetBFeeOnSell) {
            emit CustomTaxPeriodChange(_targetBFeeOnSell,map.targetBFeeOnSell,"targetBFeeOnSell",map.periodName);
            map.targetBFeeOnSell = _targetBFeeOnSell;
        }
        if (map.targetCFeeOnSell != _targetCFeeOnSell) {
            emit CustomTaxPeriodChange(_targetCFeeOnSell,map.targetCFeeOnSell,"targetCFeeOnSell",map.periodName);
            map.targetCFeeOnSell = _targetCFeeOnSell;
        }
    }
    function _setCustomBuyTaxPeriod(CustomTaxPeriod storage map,uint16 _liquidityFeeOnBuy,uint16 _operationsFeeOnBuy,uint16 _targetAFeeOnBuy, uint16 _targetBFeeOnBuy, uint16 _targetCFeeOnBuy) private {
        if (map.liquidityFeeOnBuy != _liquidityFeeOnBuy) {
            emit CustomTaxPeriodChange(_liquidityFeeOnBuy,map.liquidityFeeOnBuy,"liquidityFeeOnBuy",map.periodName);
            map.liquidityFeeOnBuy = _liquidityFeeOnBuy;
        }
        if (map.operationsFeeOnBuy != _operationsFeeOnBuy) {
            emit CustomTaxPeriodChange(_operationsFeeOnBuy,map.operationsFeeOnBuy,"operationsFeeOnBuy",map.periodName);
            map.operationsFeeOnBuy = _operationsFeeOnBuy;
        }
        if (map.targetAFeeOnBuy != _targetAFeeOnBuy) {
            emit CustomTaxPeriodChange(_targetAFeeOnBuy,map.targetAFeeOnBuy,"targetAFeeOnBuy",map.periodName);
            map.targetAFeeOnBuy = _targetAFeeOnBuy;
        }
        if (map.targetBFeeOnBuy != _targetBFeeOnBuy) {
            emit CustomTaxPeriodChange(_targetBFeeOnBuy,map.targetBFeeOnBuy,"targetBFeeOnBuy",map.periodName);
            map.targetBFeeOnBuy = _targetBFeeOnBuy;
        }
        if (map.targetCFeeOnBuy != _targetCFeeOnBuy) {
            emit CustomTaxPeriodChange(_targetCFeeOnBuy,map.targetCFeeOnBuy,"targetCFeeOnBuy",map.periodName);
            map.targetCFeeOnBuy = _targetCFeeOnBuy;
        }
    }
    function _swapAndTransfer() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 initialETHBalance = address(this).balance;
        uint16 _totalFeePrior = _totalFee;

        uint256 amountToLiquify = contractBalance * _liquidityFee / _totalFeePrior / 2;
        uint256 amountToSwap = contractBalance - amountToLiquify;

        _swapTokensForETH(amountToSwap);

        uint256 ETHBalanceAfterSwap = address(this).balance - initialETHBalance;
        uint256 totalETHFee = _totalFeePrior - (_liquidityFee / 2);
        uint256 amountETHLiquidity = ETHBalanceAfterSwap * _liquidityFee / totalETHFee / 2;
        uint256 amountETHOperations = (ETHBalanceAfterSwap * _operationsFee) / totalETHFee;
        uint256 amountETHTargetA = (ETHBalanceAfterSwap * _targetAFee) / totalETHFee;
        uint256 amountETHTargetB = (ETHBalanceAfterSwap * _targetBFee) / totalETHFee;
        uint256 amountETHTargetC = ETHBalanceAfterSwap - (amountETHTargetA  + amountETHTargetB + amountETHOperations + amountETHLiquidity);

        Address.sendValue(payable(operationsWallet),amountETHOperations);
        Address.sendValue(payable(targetAWallet),amountETHTargetA);
        Address.sendValue(payable(targetBWallet),amountETHTargetB);
        Address.sendValue(payable(targetCWallet),amountETHTargetC);

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