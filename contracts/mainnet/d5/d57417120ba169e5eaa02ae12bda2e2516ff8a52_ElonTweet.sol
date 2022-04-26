/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

/**
 * TG     : https://t.me/ElonTweetsFastestPlays
 * Max buy: 2% or 20_000_000
*/

pragma solidity 0.8.4;
// SPDX-License-Identifier: Unlicensed

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface PancakeSwapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
    ) external;
}

interface PancakeSwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

contract ElonTweet is IERC20, Ownable {

    ///////////// TRANSFERS /////////////

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (_isContractSell) {return _basicTransfer(sender, recipient, amount);}
        require(!_isBl(sender, recipient) && amount <= _maxTxAmount || isTxLimitExempt[sender], "Transfer amount exceeds the maxTxAmount.");
        if (!isTxLimitExempt[recipient]) require(_balances[recipient].add(amount) <= _maxWalletSize, "Max wallet exceeds.");
        if (_isPairCreated && msg.sender != pair[0] && !_isContractSell && _balances[address(this)] >= _swapThreshold) swapAndLiquify();
        _balances[sender] = _balances[sender].sub(amount);
        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient] ? extractFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(finalAmount);
        emit Transfer(sender, recipient, finalAmount);
        return true;
    }

    function _isBl(address sender, address recipient) private view returns (bool){
        return _isBd[sender] || _isBd[recipient];
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) private returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function extractFee(address sender, uint256 amount) private returns (uint256) {
        uint256 feeAmount = amount.mul(_totalFee).div(100);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    ///////////// CONTRACT SELL /////////////

    function swapAndLiquify() private lockTheSwap {
        uint256 tokensToLiquify = _balances[address(this)];
        uint256 liquidityToAddInTokens = tokensToLiquify.mul(_liqFee).div(_totalFee).div(2);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(liquidityToAddInTokens, 0, path, address(this), block.timestamp);

        uint256 amountBNB = address(this).balance;
        uint256 totalBNBFee = _totalFee.sub(_liqFee.div(2));

        uint256 liquidityToAddInBNB = amountBNB.mul(_liqFee).div(totalBNBFee).div(2);
        uint256 divvesAmountInBNB = amountBNB.mul(_devFee).div(totalBNBFee);

        (bool suc,) = payable(_ar[0]).call{value : divvesAmountInBNB, gas : 30000}("");
        suc = true;

        if (liquidityToAddInTokens > 0) {
            router.addLiquidityETH{value : liquidityToAddInBNB}(address(this), liquidityToAddInTokens, 0, 0, _ar[0], block.timestamp);
            emit AutoLiquify(liquidityToAddInBNB, liquidityToAddInTokens);
        }
    }

    ///////////// IBEP20 IMPL /////////////

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function name() external view override returns (string memory) {return _tokenName;}

    function totalSupply() external pure override returns (uint256) {return _totalSupply;}

    function symbol() external view override returns (string memory) {return _tokenTicker;}

    function decimals() external pure override returns (uint8) {return _decimals;}

    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}

    function allowance(address holder, address spender) external view override returns (uint256) {return _allowances[holder][spender];}

    function getOwner() external view override returns (address) {return owner();}

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD_WALLET)).sub(balanceOf(address(0)));
    }

    function bulkBl(address[] memory bl) external onlyOwner() {
        for (uint256 i = 0; i < bl.length; i++) {
            _isBd[bl[i]] = true;
        }
    }

    function singleBl(address bl) external onlyOwner() {
        _isBd[bl] = true;
    }

    function launch(string memory tokenName, string memory tokenTicker) external onlyOwner() {
        _tokenTicker = tokenTicker;
        _tokenName = tokenName;
        pair.push(PancakeSwapFactory(router.factory()).createPair(router.WETH(), address(this)));
        isTxLimitExempt[pair[0]] = true;
        router.addLiquidityETH{value : address(this).balance}(address(this), _totalSupply, 0, 0, owner(), block.timestamp);
        _isPairCreated = true;
    }

    ///////////// STORAGE /////////////

    uint8 constant _decimals = 18;
    address private DEAD_WALLET = 0x000000000000000000000000000000000000dEaD;

    string public _tokenName;
    string public _tokenTicker;

    uint256 public constant _totalSupply = 1_000_000_000 * (10 ** _decimals);

    uint256 public constant _swapThreshold = _totalSupply * 4 / 1000;
    uint256 public constant _maxWalletSize = _totalSupply * 20 / 1000;
    uint256 public constant _maxTxAmount = _totalSupply * 20 / 1000;

    address[] public _ar;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public isFeeExempt;

    uint256 public _liqFee = 3;
    uint256 public _devFee = 7;
    uint256 public _totalFee = 10;

    PancakeSwapRouter public immutable router;
    address[] public pair;
    bool _isPairCreated = false;
    bool _isContractSell;
    mapping(address => bool) public _isBd;

    ///////////// CONSTRUCTOR /////////////

    constructor(address routerAddress) {
        router = PancakeSwapRouter(routerAddress);
        _ar.push(owner());

        _balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);

        _allowances[address(this)][routerAddress] = type(uint256).max;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[DEAD_WALLET] = true;
        isFeeExempt[address(this)] = true;

        isTxLimitExempt[DEAD_WALLET] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
    }

    ///////////// MISC /////////////

    using SafeMath for uint256;

    event AutoLiquify(uint256 amountBNB, uint256 amountToken);
    modifier lockTheSwap {
        _isContractSell = true;
        _;
        _isContractSell = false;
    }

    receive() external payable {}

    function manualBNBSend() external onlyOwner() {
        (bool suc,) = payable(owner()).call{value : address(this).balance, gas : 30000}("");
        suc = true;
    }
}