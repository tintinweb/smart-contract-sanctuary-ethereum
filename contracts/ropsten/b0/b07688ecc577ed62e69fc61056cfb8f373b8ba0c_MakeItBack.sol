/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: Unlicensed


pragma solidity ^0.8.4;

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

contract MakeItBack is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;
    mapping (address => uint) private cooldown;
    uint256 private _tax;
    uint256 private constant _tTotal = 21 * 10**6 * 10**18;
    uint256 private buyfee=3;
    uint256 private sellfee=58;
    uint256 private liqfee=30;
    uint256 private percent1=12;	// DEV FEE
    uint256 private percent2=11;	// MARKETING FEE
	uint256 private percent3=77;	// PRIZEPOOL FEE
    string private constant _name = "MAKE IT BACK";
    string private constant _symbol = "MIB";
	uint256 private _maxWallet = 21 * 10**4 * 10**18; // MAXWALLET 1 %
    uint256 private minBalance = 21 * 10**3 * 10**18; // SWAP THRESHOLD 0.1%
    uint8 private constant _decimals = 18;
	address private _deployer;
    address payable private _feeAddrWallet1;
    address payable private _feeAddrWallet2;
    address payable private _feeAddrWallet3;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
	
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
	
    constructor () payable {
		_deployer = _msgSender();	
        _feeAddrWallet1 = payable(0x2eCDd766bD40e2F53604C8E48927e429Bef1c419);
        _feeAddrWallet2 = payable(0x1E5B901e238611a96FD178FfCDCC08046E6C238d);
        _feeAddrWallet3 = payable(0xe47A6cFE6D9D643862af4ef2b12D3f87D6408723);
        _tOwned[address(this)] = _tTotal.div(100).mul(95);
        _tOwned[address(0x54Ae5E89c3447049d8eeAa7Db689C3eae41616dB)] = _tTotal.div(100).mul(1);
        _tOwned[address(0xB34AFc56a768Ca22885AD0D0604F2EC8B5257D76)] = _tTotal.div(100).mul(1);
        _tOwned[address(0x14A0cC28885D0d40d366753741748de4AFF592F7)] = _tTotal.div(100).mul(1);
        _tOwned[address(0x5c674D0362678c219C3f8F394bA6d01579D3b69F)] = _tTotal.div(100).mul(1);		
        _tOwned[address(0xd4e0463c6a6F57A71896B718829633422F578E13)] = _tTotal.div(100).mul(1);		
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_feeAddrWallet1] = true;
        _isExcludedFromFee[_feeAddrWallet2] = true;
        _isExcludedFromFee[_feeAddrWallet3] = true;		
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
		
		bots[address(0x0Ff5F706A99BE785B35dF6788ED698290ab56ac0)] = true;  // BLACKLIST ANYSNIPER CA

        emit Transfer(address(0),address(this),_tTotal.div(100).mul(95));
		emit Transfer(address(0),address(0x54Ae5E89c3447049d8eeAa7Db689C3eae41616dB),_tTotal.div(100).mul(1));
		emit Transfer(address(0),address(0xB34AFc56a768Ca22885AD0D0604F2EC8B5257D76),_tTotal.div(100).mul(1));
		emit Transfer(address(0),address(0x14A0cC28885D0d40d366753741748de4AFF592F7),_tTotal.div(100).mul(1));
		emit Transfer(address(0),address(0x5c674D0362678c219C3f8F394bA6d01579D3b69F),_tTotal.div(100).mul(1));
		emit Transfer(address(0),address(0xd4e0463c6a6F57A71896B718829633422F578E13),_tTotal.div(100).mul(1));
		
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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
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

    function changeMinBalance(uint256 newMin) external onlyOwner {
        minBalance = newMin;
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
		require(!bots[from] && !bots[to],"No bots allowed");
		
		
		// Swap enabled?
		if (!swapEnabled) {
			require(_isExcludedFromFee[from] || _isExcludedFromFee[to], "Trading is not active");
		}
		
		// buy max wallet check
		if (from == uniswapV2Pair && !_isExcludedFromFee[to]) {
			require(amount + balanceOf(to) <= _maxWallet, "Max wallet exceeded");
		}
		
		
		bool takeFee = !inSwap;
		bool walletToWallet = (uniswapV2Pair != from && uniswapV2Pair != to);
		
		if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || walletToWallet)  {
			takeFee = false;
		}
		
		_tax = 0;
		
		if (takeFee) {
			_tax = sellfee.add(liqfee);
			if (uniswapV2Pair == from){
				_tax = buyfee.add(liqfee);
			}
		}
				
        if (!inSwap && from != uniswapV2Pair && swapEnabled && !_isExcludedFromFee[from]) {
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > minBalance){
                swapAndLiquify(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
		
        _transferStandard(from,to,amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function swapAndLiquify(uint256 tokenAmount) private {
        uint256 half = liqfee.div(2);
        uint256 part = sellfee.add(half);
        uint256 sum = sellfee.add(liqfee);
        uint256 swapTotal = tokenAmount.mul(part).div(sum);
        swapTokensForEth(swapTotal);
        addLiquidity(tokenAmount.sub(swapTotal),address(this).balance.mul(half).div(part),_deployer);
    }

    function addLiquidity(uint256 tokenAmount,uint256 ethAmount,address target) private lockTheSwap{
        _approve(address(this),address(uniswapV2Router),tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this),tokenAmount,0,0,target,block.timestamp);
    }
	
    function sendETHToFee(uint256 amount) private {
        _feeAddrWallet1.transfer(amount.div(100).mul(percent1));
        _feeAddrWallet2.transfer(amount.div(100).mul(percent2));
        _feeAddrWallet3.transfer(amount.div(100).mul(percent3));
    }
    
    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        addLiquidity(balanceOf(address(this)),address(this).balance,owner());
        swapEnabled = true;
        tradingOpen = true;
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 transferAmount,uint256 tfee) = _getTValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(transferAmount); 
        _tOwned[address(this)] = _tOwned[address(this)].add(tfee);
        emit Transfer(sender, recipient, transferAmount);
		if (tfee > 0) {
			emit Transfer(sender, address(this),tfee);		
		}
    }

    receive() external payable {}
    
    function manualswap() external {
        uint256 contractBalance = balanceOf(address(this));
        swapAndLiquify(contractBalance);
    }
    
    function manualsend() external {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
   
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = tAmount.mul(_tax).div(1000);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

}