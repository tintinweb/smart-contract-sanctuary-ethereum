/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

//SPDX-License-Identifier: MIT
/**

███████████████████████████████████████████████████████████████████████████
█▄─▄▄─█─▄▄─█▄─▀█▀─▄███▄─▄█▄─▀█▄─▄█▄─██─▄███▀▀▀▀▀████▄─▄▄─█─▄▄─█▄─▀█▀─▄█▄─▄█
██─▄▄▄█─██─██─█▄█─█████─███─█▄▀─███─██─██████████████─▄▄▄█─██─██─█▄█─███─██
▀▄▄▄▀▀▀▄▄▄▄▀▄▄▄▀▄▄▄▀▀▀▄▄▄▀▄▄▄▀▀▄▄▀▀▄▄▄▄▀▀▀▀▀▀▀▀▀▀▀▀▀▄▄▄▀▀▀▄▄▄▄▀▄▄▄▀▄▄▄▀▄▄▄▀

What is POM Inu?

Branching off Proof of Memes and Pomeranian, POM Inu strives to become the top community-driven meme token.
We are developing a currency for the people and by the people, utilizing blockchain technology for security.

Tokenomics:

Total supply: 1 Billion
Max tx: 2%
Buy tax: 2% auto LP & 3% marketing and buyback = 5% total 
Sell tax: 2% auto LP & 3% marketing and buyback = 5% total 

NOTE: There will be a 15% sell tax applied for the first 24 hours of any purchase. After 24 hours have passed from the purchase time,
the sell tax will be 5% again. This is to encourage holders to hodl as well as to build a stronger LP early on and decrease the supply
at a higher rate when people sell early. Overall, this benefits all long-term holders by increasing the price faster with each auto LP add,
and making sells have less of an effect on the chart.

More info on POM Inu can be found below and come join the POMI community!
Website: https://www.pominu.dev/
Twitter: https://twitter.com/PomInuERC
Telegram: https://t.me/pominutokenportal

**/

pragma solidity ^0.8.17;

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


contract PomInu is Context, IERC20, Ownable {
	using SafeMath for uint256;
    address constant private DEAD = address(0xdead);
    uint256 constant private ONE_HOUR = 3600;

	mapping (address => uint256) private _balance;
	mapping (address => mapping (address => uint256)) private _allowances;
	mapping (address => bool) private _isExcludedFromFee;
    mapping (address => uint256) private _addressTxTime;
	mapping (address => bool) public bots;

	uint256 private _tTotal = 1000000000 * 10**8;
    uint256 private _contractAutoLpLimitToken = 7500000 * 10**8;

	uint256 private _taxFee;
    uint256 private _buyTaxMarketing = 5;
    uint256 private _earlySellTaxMarketing = 13;
    uint256 private _sellTaxMarketing = 3;
    uint256 private _autoLpFee = 2;

    uint256 private _earlySellTime = 24 * ONE_HOUR;

    uint256 private _LpPercentBase100 = 20;
    uint256 private _pominuPercentBase100 = 80;

	address payable private _pomWallet;
    address payable private _pomDeployer;

	uint256 private _maxTxAmount = 20000000 * 10**8;
	uint256 private _maxWallet = 500000000 * 10**8;

	string private constant _name = "POM Inu";
	string private constant _symbol = "POMI";
	uint8 private constant _decimals = 8;

	IUniswapV2Router02 private _uniswap;
	address private _pair;
	bool private _canTrade;
	bool private _inSwap = false;
	bool private _swapEnabled = true;

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
		_pomWallet = payable(0xca7C980fAb1913840B8959f3a8B66FBa52c83cAd);
        _pomDeployer = payable(0x67C058e2AdFFF4DE2CC3d7F98Ac26c39a06ecb19);
        
		_uniswap = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

		_isExcludedFromFee[address(this)] = true;
		_isExcludedFromFee[_pomWallet] = true;
        _isExcludedFromFee[_pomDeployer] = true;

		_balance[_pomDeployer] = _tTotal;
		emit Transfer(address(0x0), _pomDeployer, _tTotal);
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

    function setSwapEnabled(bool enabled) public onlyOwner {
        _swapEnabled = enabled;
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
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function setEarlySellTime(uint256 hrs) external onlyOwner() {
        _earlySellTime = (hrs * ONE_HOUR);
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function setSellMarketingTax(uint256 taxFee) external onlyOwner() {
        _sellTaxMarketing = taxFee;
        require(_sellTaxMarketing <= 10, "Sell tax cannot be set higher than 10%");
    }

    function setBuyMarketingTax(uint256 taxFee) external onlyOwner() {
        _buyTaxMarketing = taxFee;
        require(_buyTaxMarketing <= 10, "Buy tax cannot be set higher than 10%");
    }

    function setAutoLpFee(uint256 taxFee) external onlyOwner() {
        _autoLpFee = taxFee;
        require(_autoLpFee <= 10, "Auto LP tax cannot be set higher than 10%");
    }

    function setEarlySellMarketingTax(uint256 taxFee) external onlyOwner() {
        _earlySellTaxMarketing = taxFee;
        require(_earlySellTaxMarketing <= 30, "Early sell tax cannot be set higher than 30%");
    }

    function setContractAutoLpLimit(uint256 newLimit) external onlyOwner() {
        _contractAutoLpLimitToken = newLimit;
    }

    function setPomInuWallet(address newWallet) external onlyOwner() {
        _pomWallet = payable(newWallet);
    }

    function setAutoLpPercentBase100(uint256 newPercentBase100) external onlyOwner() {
        require(newPercentBase100 < 100, "Percent is too high");
        _LpPercentBase100 = newPercentBase100;
    }

    function setPominuPercentBase100(uint256 newPercentBase100) external onlyOwner() {
        require(newPercentBase100 < 100, "Percent is too high");
        _pominuPercentBase100 = newPercentBase100;
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

    function setPromoter(address[] memory promoters) public onlyOwner { for(uint256 i=0; i<promoters.length; i++) { _isExcludedFromFee[promoters[i]] = true; } }

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
		_pomWallet.transfer(amount);
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
        _maxTxAmount = _tTotal.mul(2).div(10**2);
	    _maxWallet = _tTotal.mul(50).div(10**2);
    }
}