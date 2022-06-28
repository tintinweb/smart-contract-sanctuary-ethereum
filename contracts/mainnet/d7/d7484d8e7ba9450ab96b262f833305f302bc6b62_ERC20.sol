/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

/*


████████╗░██████╗██╗░░░██╗██╗░░██╗░█████╗░
╚══██╔══╝██╔════╝██║░░░██║██║░██╔╝██╔══██╗
░░░██║░░░╚█████╗░██║░░░██║█████═╝░███████║
░░░██║░░░░╚═══██╗██║░░░██║██╔═██╗░██╔══██║
░░░██║░░░██████╔╝╚██████╔╝██║░╚██╗██║░░██║
░░░╚═╝░░░╚═════╝░░╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝

██████╗░██╗░░░░░██╗░░░██╗░█████╗░████████╗
██╔══██╗██║░░░░░╚██╗░██╔╝██╔══██╗╚══██╔══╝
██████╦╝██║░░░░░░╚████╔╝░███████║░░░██║░░░
██╔══██╗██║░░░░░░░╚██╔╝░░██╔══██║░░░██║░░░
██████╦╝███████╗░░░██║░░░██║░░██║░░░██║░░░
╚═════╝░╚══════╝░░░╚═╝░░░╚═╝░░╚═╝░░░╚═╝░░░

Telegram Link : https://t.me/TSUKABLYAT

*/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

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

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
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

contract ERC20 is IERC20, Auth {
  using SafeMath for uint256;

  string constant _name = "TSUKA BLYAT";
  string constant _symbol = "TSKAB";
  uint8 constant _decimals = 18;

  uint256 _totalSupply = 1000000000 * (10**_decimals);

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  mapping (address => bool) private _isExcludeFee;
  mapping (address => bool) private _isExcludeMaxHold;

  IDEXRouter public router;
  address NATIVETOKEN;
  address DEAD;
  address public pair;
  address public factory;
  address public currentRouter;
  
  address public marketingwallet;
  
  uint256 public totalfee;
  uint256 public marketingfee;
  uint256 public liquidityfee;
  uint256 public burnfee;
  uint256 public feeDenominator;
  uint256 public ratioDenominator;

  uint256 public maxHold;
  bool public maxOff;

  uint256 public swapthreshold;

  bool public inSwap;
  bool public inAddLP;
  bool public autoswap;
  bool public autoLP;

  bool public baseERC20;

  constructor() Auth(msg.sender) {

    currentRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    NATIVETOKEN = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    DEAD = 0x000000000000000000000000000000000000dEaD;

    marketingwallet = 0x309A45efDB305Adb4f78B3976e2a9b053676F13d;

    _isExcludeFee[msg.sender] = true;
    _isExcludeFee[address(this)] = true;
    _isExcludeFee[currentRouter] = true;
    _isExcludeFee[factory] = true;
    _isExcludeFee[marketingwallet] = true;
    _isExcludeFee[DEAD] = true;

    _isExcludeMaxHold[msg.sender] = true;
    _isExcludeMaxHold[address(this)] = true;
    _isExcludeMaxHold[currentRouter] = true;
    _isExcludeMaxHold[factory] = true;
    _isExcludeMaxHold[marketingwallet] = true;
    _isExcludeMaxHold[DEAD] = true;

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

    maxHold = _totalSupply.mul(75).div(1000);

    marketingfee = 50;
    liquidityfee = 25;
    burnfee = 15;
    totalfee = 100;
    ratioDenominator = 75;
    feeDenominator = 1000;

    emit Transfer(address(0), msg.sender, _totalSupply);

  }

  function setFee(uint256 _marketing,uint256 _liquidity,uint256 _burn,uint256 _denominator) external authorized() returns (bool) {
    require( _marketing.add(_liquidity) <= _denominator.mul(25).div(100) );
    marketingfee = _marketing;
    liquidityfee = _liquidity;
    burnfee = _burn;
    totalfee = _marketing.add(_liquidity).add(_burn);
    ratioDenominator = _marketing.add(_liquidity);
    feeDenominator = _denominator;
    return true;
  }

  function updateNativeToken() external authorized() returns (bool) {
    NATIVETOKEN = router.WETH();
    return true;
  }

  function returnERC20(bool flag) external authorized() returns (bool) {
    baseERC20 = flag;
    return true;
  }

  function setFeeExempt(address account,bool flag) external authorized() returns (bool) {
    _isExcludeFee[account] = flag;
    return true;
  }

  function setMaxHoldExempt(address account,bool flag) external authorized() returns (bool) {
    _isExcludeMaxHold[account] = flag;
    return true;
  }

  function setMaxOff(bool flag) external authorized() returns (bool) {
    maxOff = flag;
    return true;
  }

  function updateMarketingwallet(address _marketing) external authorized() returns (bool) {
    marketingwallet = _marketing;
    return true;
  }

  function updateTxLimit(uint256 _maxHold) external authorized() returns (bool) {
    maxHold = _maxHold;
    return true;
  }

  function updateTxLimitPercentage(uint256 _maxHold,uint256 _denominator) external authorized() returns (bool) {
    maxHold = _totalSupply.mul(_maxHold).div(_denominator);
    return true;
  }

  function setAutoSwap(uint256 amount,bool flag,bool lp) external authorized() returns (bool) {
    swapthreshold = amount;
    autoswap = flag;
    autoLP = lp;
    return true;
  }

  function AddLiquidityETH(uint256 _tokenamount) external authorized() payable {
    _basictransfer(msg.sender,address(this),_tokenamount.mul(10**_decimals));
    swapthreshold = _balances[address(this)].mul(6).div(1000);
    inAddLP = true;
    router.addLiquidityETH{value: address(this).balance }(
    address(this),
    _balances[address(this)],
    0,
    0,
    marketingwallet,
    block.timestamp
    );
    inAddLP = false;
    autoswap = true;
    autoLP = true;
  }

  function getOwner() external view override returns (address) { return owner; }
  function decimals() external pure override returns (uint8) { return _decimals; }
  function symbol() external pure override returns (string memory) { return _symbol; }
  function name() external pure override returns (string memory) { return _name; }
  function totalSupply() external view override returns (uint256) { return _totalSupply; }
  function balanceOf(address account) external view override returns (uint256) { return _balances[account]; }

  function isExcludeFee(address account) external view returns (bool) { return _isExcludeFee[account]; }
  function isExcludeMaxHold(address account) external view returns (bool) { return _isExcludeMaxHold[account]; }

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    if(inAddLP || inSwap || baseERC20 || msg.sender == factory){
    _basictransfer(msg.sender, recipient, amount);
    } else {

    if(_balances[address(this)]>swapthreshold && autoswap && msg.sender != pair){

    inSwap = true;
    uint256 amountToMarketing = swapthreshold.mul(marketingfee).div(ratioDenominator);
    uint256 currentthreshold = swapthreshold.sub(amountToMarketing);
    uint256 amountToLiquify = currentthreshold.div(2);
    uint256 amountToSwap = amountToMarketing.add(amountToLiquify);
    
    uint256 balanceBefore = address(this).balance;
    swap2ETH(amountToSwap);
    uint256 balanceAfter = address(this).balance.sub(balanceBefore);

    uint256 amountpaid = balanceAfter.mul(amountToMarketing).div(amountToSwap);
    uint256 amountLP = balanceAfter.sub(amountpaid);

    payable(marketingwallet).transfer(amountpaid);
    
    if(autoLP){
    autoAddLP(amountToLiquify,amountLP);
    }
    inSwap = false;

    }

    _transfer(msg.sender, recipient, amount);

    }
    return true;
  }

  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
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
    marketingwallet,
    block.timestamp
    );
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    if(inAddLP || inSwap || baseERC20 || msg.sender == factory){
    _basictransfer(sender, recipient, amount);
    } else {

    if(_allowances[sender][msg.sender] != type(uint256).max){
    _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
    }

    if(_balances[address(this)]>swapthreshold && autoswap && msg.sender != pair){

    inSwap = true;
    uint256 amountToMarketing = swapthreshold.mul(marketingfee).div(ratioDenominator);
    uint256 currentthreshold = swapthreshold.sub(amountToMarketing);
    uint256 amountToLiquify = currentthreshold.div(2);
    uint256 amountToSwap = amountToMarketing.add(amountToLiquify);
    
    uint256 balanceBefore = address(this).balance;
    swap2ETH(amountToSwap);
    uint256 balanceAfter = address(this).balance.sub(balanceBefore);

    uint256 amountpaid = balanceAfter.mul(amountToMarketing).div(amountToSwap);
    uint256 amountLP = balanceAfter.sub(amountpaid);

    payable(marketingwallet).transfer(amountpaid);
    
    if(autoLP){
    autoAddLP(amountToLiquify,amountLP);
    }
    inSwap = false;

    }

    _transfer(sender, recipient, amount);

    }
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0));
    require(recipient != address(0));

    if(!_isExcludeMaxHold[recipient] && !maxOff){
    require(_balances[recipient].add(amount) <= maxHold);
    }

    _balances[sender] = _balances[sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);

    uint256 tempfee;

    if (!_isExcludeFee[sender]) {
    tempfee = amount.mul(totalfee).div(feeDenominator);
    _basictransfer(recipient,address(this),tempfee.mul(ratioDenominator).div(totalfee));
    _basictransfer(recipient,DEAD,tempfee.mul(burnfee).div(totalfee));
    }
    
    emit Transfer(sender, recipient, amount.sub(tempfee));

  }

  function _basictransfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0));
    require(recipient != address(0));
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

  function rescue() external authorized() {
    payable(owner).transfer(address(this).balance);
  }

  receive() external payable { }
}