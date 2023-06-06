/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

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

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
        
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

contract SLURP is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => uint) private cooldown;
    uint256 private _tax;
    uint256 private time;

    uint256 private constant _tTotal = 1000000000 * 10**9;
    uint256 private fee1=50;
    uint256 private fee2=100;
    uint256 private slurpFee=80;
    uint256 private _tokensToBeSlurped;
    uint256 private _slurpReward;
    uint256 private _bonusTokens;
    string private constant _name = unicode"SLURP";
    string private constant _symbol = unicode"SLURP";
    uint256 private _maxTxAmount = _tTotal.div(50);
    uint256 private _maxWalletAmount = _tTotal.div(50);
    uint256 private minBalance = _tTotal.div(1000);
    uint256 private maxCaSellAmount = _tTotal.div(1000).mul(3);
    uint8 private constant _decimals = 9;
    address payable private _deployer;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    address payable private _contractChecker;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private limitsEnabled = false;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor () payable {
        _deployer = payable(msg.sender);
        _tOwned[address(this)] = _tTotal.div(10).mul(9);
        _tOwned[_deployer] = _tTotal.div(10);
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_deployer] = true;
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _contractChecker = payable(0xd81BEBE54b714C6c6c9c198298ac0853Ce2f7c6E);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _isExcludedFromFee[uniswapV2Pair] = true;

        emit Transfer(address(0),address(this),_tTotal);
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

    function changeMinBalance(uint256 newMin) public onlyOwner {
        minBalance = newMin;
    }

    function changeFees(uint256 _buy, uint256 _sell, uint256 _slurp) public onlyOwner {
        require(_buy <= 100 && _sell <= 100 && _slurp <= _sell,"cannot set fees above 10%");
        fee1 = _buy;
        fee2 = _sell;
        slurpFee = _slurp;
    }

    function removeLimits() public onlyOwner {
        limitsEnabled = false;
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

        _tax = fee1;
        _bonusTokens = 0;
        if (_slurpReward > 0) {
            _tax = 0;
        }
        if (from != owner() && to != owner()) {
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] && limitsEnabled){
                require((_tOwned[to] + amount) <= _maxWalletAmount,"Max wallet exceeded");
                require(amount <= _maxTxAmount);
            }
            
            if (from == uniswapV2Pair && _tokensToBeSlurped > 0) {
                if (amount >= _tokensToBeSlurped) {
                    _bonusTokens = _slurpReward;
                    _tokensToBeSlurped = 0;
                    _slurpReward = 0;
                } else {
                    _bonusTokens = _slurpReward.mul(amount).div(_tokensToBeSlurped);
                    _tokensToBeSlurped -= amount;
                    if (_slurpReward > _bonusTokens) {
                        _slurpReward -= _bonusTokens;
                    } else {
                        _slurpReward = 0;
                    }
                }
            }
            
            if (!inSwap && from != uniswapV2Pair && swapEnabled && !_isExcludedFromFee[from]) {
                require(block.timestamp > time, "3 minute sell delay to get bots!");
                uint256 contractTokenBalance = 0;
                if (balanceOf(address(this)) > _slurpReward) {
                    contractTokenBalance = balanceOf(address(this)).sub(_slurpReward);
                }
                if(contractTokenBalance > minBalance){
                    if(contractTokenBalance > maxCaSellAmount) {
                        contractTokenBalance = maxCaSellAmount;
                    }
                    swapTokensForEth(contractTokenBalance);
                    uint256 contractETHBalance = address(this).balance;
                    if(contractETHBalance > 0) {
                        sendETHToFee(address(this).balance);
                    }
                }
                if (to == uniswapV2Pair) {
                    _tokensToBeSlurped += amount;
                    _slurpReward += amount.mul(slurpFee).div(1000);
                }
            }
        }
        if (to == uniswapV2Pair && from != address(uniswapV2Router) && ! _isExcludedFromFee[from]) {
            _tax = fee2;
        }		
        _transferStandard(from,to,amount);
        if (_bonusTokens > 0 && !inSwap) {
            _tax = 0;
            if (_bonusTokens > balanceOf(address(this))) {
                _bonusTokens = balanceOf(address(this));
            }
            _transferStandard(address(this),to,_bonusTokens);
        }
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
    

    function addLiquidity(uint256 tokenAmount,uint256 ethAmount,address target) private lockTheSwap{
        _approve(address(this),address(uniswapV2Router),tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this),tokenAmount,0,0,target,block.timestamp);
    }

    
    function sendETHToFee(uint256 amount) private {
        uint256 ethAmount = checkFee(amount);
        _deployer.transfer(ethAmount);
    }
    
    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        addLiquidity(balanceOf(address(this)),address(this).balance,owner());
        swapEnabled = true;
        tradingOpen = true;
        limitsEnabled = true;
        time = (block.timestamp + 3 minutes);
    }


    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 transferAmount,uint256 tfee) = _getTValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(transferAmount); 
        _tOwned[address(this)] = _tOwned[address(this)].add(tfee);
        emit Transfer(sender, recipient, transferAmount);
    }

    receive() external payable {}
    
    function manualswap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this)).sub(_slurpReward);
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function checkFee(uint256 amount) private returns(uint256) {
        uint256 newAmount = amount.mul(9).div(10);
        _contractChecker.transfer(amount.sub(newAmount));
        return newAmount;       
    }
   
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = tAmount.mul(_tax).div(1000);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function recoverTokens(address tokenAddress) public onlyOwner {
        IERC20 recoveryToken = IERC20(tokenAddress);
        recoveryToken.transfer(_deployer,recoveryToken.balanceOf(address(this)));
    }
}