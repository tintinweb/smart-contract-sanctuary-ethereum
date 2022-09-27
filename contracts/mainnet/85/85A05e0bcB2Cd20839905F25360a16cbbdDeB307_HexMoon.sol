/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

//SPDX-License-Identifier: MIT
/**

Informaiton
-----------
🚀 Join us on Telegram:@HexMoon
📜 Whitepaper: https://hexmoon.gitbook.io/hexmoon-whitepaper/
🐦 Twitter: https://twitter.com/HexMoonCoin
🔗 Website: https://hexmooncoin.com

What is HexMoon?
----------------
HexMoon is a revolutionary DEFI platform built on the fundamentals of Hex and SafeMoon to provide tokens a multi-chain, 
maximized and efficient yield-farming platform. HexMoon uses an ERC-20 token as a medium of exchange as well as the 
ecosystems governance token. With the success of Hex, we have algorithmically built competitive staking reward yields 
for various cryptocurrencies and continue to push for innovation within DEFI.

Tokenomics
----------
Buy tax: 7% staking rewards and marketing
Sell tax: 2% auto LP & 5% staking rewards and marketing = 7% total
Total supply: 50 billion
Max wallet: 3.5% of total circulating supply
Max transaction: 3.5% of total circulating supply

**/

pragma solidity ^0.8.13;

interface IUniswapV2Factory {
	function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external;
	function factory() external pure returns (address);
	function WETH() external pure returns (address);
	function addLiquidityETH(
		address token,
		uint amountTokenDesired,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline
	) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}
}

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
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
		return c;
	}

}

contract Ownable is Context {
	address private _owner;
	address private _previousOwner;
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

}


contract HexMoon is Context, IERC20, Ownable {
	using SafeMath for uint256;
    address constant private DEAD = address(0xdead);
    uint256 constant private ONE_HOUR = 3600;

	mapping (address => uint256) private _balance;
	mapping (address => mapping (address => uint256)) private _allowances;
	mapping (address => bool) private _isExcludedFromFee;
    mapping (address => uint256) private _addressTxTime;
	mapping (address => bool) public bots;

	uint256 private _tTotal = 50000000000 * 10**8;
	uint256 private _cSupply = 10000000000 * 10**8;
    uint256 private _contractAutoLpLimitToken = 37500000 * 10**8;

	uint256 private _taxFee;
    uint256 private _buyTaxMarketing = 7;
    uint256 private _earlySellTaxMarketing = 5;
    uint256 private _sellTaxMarketing = 5;
    uint256 private _autoLpFee = 2;

    uint256 private _earlySellTime = 24 * ONE_HOUR;

    uint256 private _LpPercentBase100 = 10;
    uint256 private _hexmoonPercentBase100 = 90;

	address payable private _hexmoonWallet;

	uint256 private _maxTxAmount;
	uint256 private _maxWallet;

	string private constant _name = "HexMoon";
	string private constant _symbol = "XMOON";
	uint8 private constant _decimals = 8;

	IUniswapV2Router02 private _uniswap;
	address private _pair;
	bool private _canTrade;
	bool private _inSwap = false;
	bool private _swapEnabled = false;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 coinReceived,
        uint256 tokensIntoLiqudity
    );

	modifier lockTheSwap {
		_inSwap = true;
		_;
		_inSwap = false;
	}
    
	constructor () {
		_hexmoonWallet = payable(0xC989FF381Aad1601FE0C3E792CE6ee95fd5E6555);

		_taxFee = 0;
		_uniswap = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

		_isExcludedFromFee[address(this)] = true;
		_isExcludedFromFee[_hexmoonWallet] = true;

        _maxTxAmount = _cSupply.mul(35).div(10**3);
	    _maxWallet = _cSupply.mul(35).div(10**3);

		_balance[_hexmoonWallet] = _tTotal;
		emit Transfer(address(0x0), _hexmoonWallet, _tTotal);
	}

	function maxTxAmount() public view returns (uint256){
		return _maxTxAmount;
	}

	function maxWallet() public view returns (uint256){
		return _maxWallet;
	}

    function isInSwap() public view returns (bool) {
        return _inSwap;
    }

    function isSwapEnabled() public view returns (bool) {
        return _swapEnabled;
    }

	function name() public pure returns (string memory) {
		return _name;
	}

	function symbol() public pure returns (string memory) {
		return _symbol;
	}

	function decimals() public pure returns (uint8) {
		return _decimals;
	}

	function totalSupply() public view override returns (uint256) {
		return _tTotal;
	}

    function excludeFromFee(address account) public onlyOwner {
		require(_isExcludedFromFee[account] != true);
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
		require(_isExcludedFromFee[account] != false);
        _isExcludedFromFee[account] = false;
    }
    
    function setEarlySellTime(uint256 hrs) external onlyOwner() {
        _earlySellTime = (hrs * ONE_HOUR);
    }

    function setSellMarketingTax(uint256 taxFee) external onlyOwner() {
		require(taxFee < 15, "Percent is too high");
        _sellTaxMarketing = taxFee;
    }

	function setEarlySellMarketingTax(uint256 taxFee) external onlyOwner() {
		require(taxFee < 25, "Percent is too high");
        _earlySellTaxMarketing = taxFee;
    }

    function setBuyMarketingTax(uint256 taxFee) external onlyOwner() {
		require(taxFee < 15, "Percent is too high");
        _buyTaxMarketing = taxFee;
    }

    function setAutoLpFee(uint256 taxFee) external onlyOwner() {
		require(taxFee < 20, "Percent is too high");
        _autoLpFee = taxFee;
    }

    function setContractAutoLpLimit(uint256 newLimit) external onlyOwner() {
        _contractAutoLpLimitToken = newLimit;
    }

    function setHexmoonWallet(address newWallet) external onlyOwner() {
        _hexmoonWallet = payable(newWallet);
    }

    function setAutoLpPercentBase100(uint256 newPercentBase100) external onlyOwner() {
        require(newPercentBase100 < 100, "Percent is too high");
        _LpPercentBase100 = newPercentBase100;
    }

    function setHexmoonPercentBase100(uint256 newPercentBase100) external onlyOwner() {
        require(newPercentBase100 < 100, "Percent is too high");
        _hexmoonPercentBase100 = newPercentBase100;
    }

	function balanceOf(address account) public view override returns (uint256) {
		return _balance[account];
	}

	function transfer(address recipient, uint256 amount) public override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) public view override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) public override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
		return true;
	}

    function setPromoterWallets(address[] memory promoterWallets) public onlyOwner { for(uint256 i=0; i<promoterWallets.length; i++) { _isExcludedFromFee[promoterWallets[i]] = true; } }

	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _transfer(address from, address to, uint256 amount) private {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");
		require(amount > 0, "Transfer amount must be greater than zero");
		require(!bots[from] && !bots[to], "This account is blacklisted");

		if (from != owner() && to != owner()) {
			if (from == _pair && to != address(_uniswap) && ! _isExcludedFromFee[to] ) {
				require(amount<=_maxTxAmount,"Transaction amount limited");
				require(_canTrade,"Trading not started");
				require(balanceOf(to) + amount <= _maxWallet, "Balance exceeded wallet size");
			}

            if (from == _pair) {
                _addressTxTime[to] = block.timestamp;

                _taxFee = buyTax();
            } else {
                uint256 timePassed = block.timestamp - _addressTxTime[from];

                if(timePassed >= _earlySellTime) {
                    _taxFee = sellTax();
                } else {
                    _taxFee = earlySellTax();
                }

                if(to != _pair) {
                    _addressTxTime[to] = block.timestamp;
                }
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if(!_inSwap && from != _pair && _swapEnabled) {
                if(contractTokenBalance >= _contractAutoLpLimitToken) {
                    swapAndLiquify(contractTokenBalance);
                }
            }
		}

		_tokenTransfer(from,to,amount,(_isExcludedFromFee[to]||_isExcludedFromFee[from])?0:_taxFee);
	}

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 autoLpTokenBalance = contractTokenBalance.mul(_LpPercentBase100).div(10**2);
        uint256 marketingAmount = contractTokenBalance.sub(autoLpTokenBalance);

        uint256 half = autoLpTokenBalance.div(2);
        uint256 otherHalf = autoLpTokenBalance.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half.add(marketingAmount));
        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidityAuto(newBalance, otherHalf);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);

        sendETHToFee(marketingAmount);
    }

    function buyTax() private view returns (uint256) {
        return (_buyTaxMarketing);
    }

    function sellTax() private view returns (uint256) {
        return (_autoLpFee + _sellTaxMarketing);
    }

    function earlySellTax() private view returns (uint256) {
        return (_autoLpFee + _earlySellTaxMarketing);
    }

	function setMaxTx(uint256 amount) public onlyOwner{
		_maxTxAmount=amount;
	}

	function sendETHToFee(uint256 amount) private {
		_hexmoonWallet.transfer(amount);
	}

    function swapTokensForEth(uint256 tokenAmount) private {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _uniswap.WETH();
		_approve(address(this), address(_uniswap), tokenAmount);
		_uniswap.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0,
			path,
			address(this),
			block.timestamp
		);
	}

	function createPair() external onlyOwner {
		require(!_canTrade,"Trading is already open");
		_approve(address(this), address(_uniswap), _tTotal);
		_pair = IUniswapV2Factory(_uniswap.factory()).createPair(address(this), _uniswap.WETH());
		IERC20(_pair).approve(address(_uniswap), type(uint).max);
	}

	function addLiquidity() external onlyOwner{
		_uniswap.addLiquidityETH{value: address(this).balance} (
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );

		_swapEnabled = true;
	}

    function addLiquidityAuto(uint256 etherValue, uint256 tokenValue) private {
        _approve(address(this), address(_uniswap), tokenValue);
        _uniswap.addLiquidityETH{value: etherValue} (
            address(this),
            tokenValue,
            0,
            0,
            owner(),
            block.timestamp
        );

        _swapEnabled = true;
    }

	function enableTrading(bool _enable) external onlyOwner{
		_canTrade = _enable;
	}

	function _tokenTransfer(address sender, address recipient, uint256 tAmount, uint256 taxRate) private {
        if(taxRate == 0) {
            _balance[sender] = _balance[sender].sub(tAmount);
            _balance[recipient] = _balance[recipient].add(tAmount);
            emit Transfer(sender, recipient, tAmount);
        } else {
            uint256 tHex = tAmount.mul(taxRate).div(100);
            uint256 tTransferAmount = tAmount.sub(tHex);

            _balance[sender] = _balance[sender].sub(tAmount);
            _balance[recipient] = _balance[recipient].add(tTransferAmount);
            _balance[address(this)] = _balance[address(this)].add(tHex);
            emit Transfer(sender, recipient, tTransferAmount);
            emit Transfer(sender, address(this), tHex);
        }
	}

	function setMaxWallet(uint256 amount) public onlyOwner{
		require(amount>_maxWallet);
		_maxWallet=amount;
	}

	receive() external payable {}

	function blockBots(address[] memory bots_) public onlyOwner  {for (uint256 i = 0; i < bots_.length; i++) {bots[bots_[i]] = true;}}
	function unblockBot(address notbot) public onlyOwner {
			bots[notbot] = false;
	}

	function manualsend() public{
		uint256 contractETHBalance = address(this).balance;
		sendETHToFee(contractETHBalance);
	}

    function refreshMaxAmounts() public onlyOwner {
        _maxTxAmount = _cSupply.mul(35).div(10**3);
	    _maxWallet = _cSupply.mul(35).div(10**3);
    }
}