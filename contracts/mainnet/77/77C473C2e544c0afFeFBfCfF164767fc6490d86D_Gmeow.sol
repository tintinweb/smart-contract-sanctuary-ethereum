/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

//SPDX-License-Identifier: MIT
/**

█████▀██████████████████████████████
█─▄▄▄▄█▄─▀█▀─▄█▄─▄▄─█─▄▄─█▄─█▀▀▀█─▄█
█─██▄─██─█▄█─███─▄█▀█─██─██─█─█─█─██
▀▄▄▄▄▄▀▄▄▄▀▄▄▄▀▄▄▄▄▄▀▄▄▄▄▀▀▄▄▄▀▄▄▄▀▀

What is Gmeow?
--------------
Gmeow is a new meme-based cryptocurrency that has taken the internet by storm.
This decentralized, blockchain-based token allows users to trade and invest in
some of the funniest and most viral memes on the internet.

Tokenomics
----------
Total supply: 100 Billion
Max wallet: 3%
Buy/Sell tax: 3%

More info
---------
Website: https://gmeow.org/
Twitter: https://twitter.com/gmeowtoken
Telegram: https://t.me/gmeowportal
Medium: https://medium.com/@gmeowtoken_53605/43c4069c513c
Linktree: https://linktr.ee/gmeowtoken

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


contract Gmeow is Context, IERC20, Ownable {
	using SafeMath for uint256;
    address constant private DEAD = address(0xdead);

	mapping (address => uint256) private _balance;
	mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
	mapping (address => bool) public bots;

	uint256 private _tTotal = 100000000000 * 10**8;

    address payable private _gmeowDeployer;
    address payable private _gmeowMarketing;

    uint256 private _taxFee = 3;

	uint256 private _maxWallet = 3000000000 * 10**8;

	string private constant _name = "gmeow";
	string private constant _symbol = "GMEOW";
	uint8 private constant _decimals = 8;

	IUniswapV2Router02 private _uniswap;
	address private _pair;
	bool private _canTrade;
    
	constructor () {
        _gmeowDeployer = payable(0xf5f6260Ac8D8F1b23f0Fb1071d0e2bd3181B4038);
        _gmeowMarketing = payable(0x127f5c8Bb6946adb845bCF0cb9b8E2d2f20A9cB4);
		_uniswap = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _isExcludedFromFee[address(this)] = true;
		_isExcludedFromFee[_gmeowMarketing] = true;
        _isExcludedFromFee[_gmeowDeployer] = true;

		_balance[_gmeowDeployer] = _tTotal;
		emit Transfer(address(0x0), _gmeowDeployer, _tTotal);
	}

	function maxWallet() public view returns (uint256){
		return _maxWallet;
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

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function blockBots(address[] memory bots_) public onlyOwner  {for (uint256 i = 0; i < bots_.length; i++) {bots[bots_[i]] = true;}}
	function unblockBot(address notbot) public onlyOwner {
			bots[notbot] = false;
	}

	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _transfer(address from, address to, uint256 amount) private {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(amount > 0, "Transfer amount must be greater than zero");
		require(!bots[from] && !bots[to], "This account is blacklisted");

        if (from != owner() && to != owner()) {
            require(_canTrade, "Trading not started");
            
            // check if the transfer is a sell
            if(to != _pair && to != DEAD && to != _gmeowDeployer && to != _gmeowMarketing) {
                require(balanceOf(to) + amount <= _maxWallet, "Balance exceeded wallet size");
            }
        }

		_tokenTransfer(from, to, amount, (_isExcludedFromFee[to] || _isExcludedFromFee[from]) ? 0:_taxFee);
	}

	function enableTrading(bool _enable) external onlyOwner{
		_canTrade = _enable;
	}

    function isTradingOpen() public view returns (bool) {
		return _canTrade;
	}

    function updatePair(address _pairAddress) external onlyOwner{
		_pair = _pairAddress;
	}

    function getPair() public view returns (address) {
		return _pair;
	}

    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
        require(_taxFee <= 5, "Tax cannot be set higher than 5%");
    }

	function _tokenTransfer(address sender, address recipient, uint256 tAmount, uint256 taxRate) private {
        if(taxRate == 0) {
            _balance[sender] = _balance[sender].sub(tAmount);
            _balance[recipient] = _balance[recipient].add(tAmount);
            emit Transfer(sender, recipient, tAmount);
        } else {
            uint256 tMarketing = tAmount.mul(taxRate).div(100);
            uint256 tTransferAmount = tAmount.sub(tMarketing);

            _balance[sender] = _balance[sender].sub(tAmount);
            _balance[recipient] = _balance[recipient].add(tTransferAmount);
            _balance[_gmeowMarketing] = _balance[_gmeowMarketing].add(tMarketing);
            emit Transfer(sender, recipient, tTransferAmount);
            emit Transfer(sender, _gmeowMarketing, tMarketing);
        }
	}

	function setMaxWallet(uint256 amount) public onlyOwner{
		_maxWallet=amount;
	}

	receive() external payable {}
}