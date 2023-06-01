/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

/**
 *Submitted for verification at BscScan.com on 2023-05-29
*/

pragma solidity 0.5.16;

interface IBEP20 {
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

interface Irt {
  function mint(address sender, uint256 amount) external;
  function getDailyMintLimit() external view returns (uint256);
  function getDailyBurnLimit() external view returns (uint256);
}

interface IOracle {
  function getCurrentPrice() external view returns (uint256);
}

contract Context {
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; 
    return msg.data;
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

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () internal {
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

contract BEP20Token is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 public _decimals;
  string public _symbol;
  string public _name;

  uint256 private lastUpdate = now;
  uint256 private lastUpdate2 = now;
  uint256 private laggingSupply;
  uint256 private minBalance;
  mapping (address => bool) private isRedeemable;
  IOracle private grtOracle = IOracle(0xeCcA631E96E7BeB702d675927a32Ec8f5705BD34);
  IOracle private bnbOracle = IOracle(0xd1bBAb254757c18763c02f365F26380906d29b8C);

  mapping (address => uint256) public lastClaim;
  mapping (address => uint256) public totalLocked;
  mapping (address => uint256) public totalClaims;
  mapping (uint256 => uint256) public totalMints;
  mapping (uint256 => uint256) public totalBurns;

  mapping (address => mapping(uint256 => uint256)) private dailyBurns;
  mapping (address => mapping(uint256 => uint256)) private dailyMints;
  mapping (address => mapping(address => uint256)) public locked;

  address[] public validLps;
  address[] public redeemList;
  address public updatedOracleAddr;
  address private gCoinAddr;

  constructor() public {
    _name = "GRT";
    _symbol = "GRT";
    _decimals = 18;
    _totalSupply = 3 * 10 * 1e25;
    minBalance = _totalSupply / 10;
    _balances[msg.sender] = _totalSupply;
    gCoinAddr = address(this);
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function getOwner() external view returns (address) {
    return owner();
  }

  function decimals() external view returns (uint8) {
    return _decimals;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function name() external view returns (string memory) {
    return _name;
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  function burn(uint256 amount) public returns (bool) {
    _burn(_msgSender(), amount);
    return true;
  }

  function getDailyBurnLimit(address token) internal view returns (uint256) {
    return Irt(token).getDailyBurnLimit();
  }

  function getDailyMintLimit(address token) internal view returns (uint256) {
    uint256 mintLimit = Irt(token).getDailyMintLimit();
    uint256 amount = getLaggingSupply() / 100 - totalBurns[getCurrentDay()];
    if(amount < mintLimit) return amount;
    return mintLimit;
  }

  function convert(address recipient, uint256 amount) public {
    _convert(msg.sender, recipient, amount);
  }

  function _convert(address sender, address recipient, uint256 amount) internal {
    require(recipient != address(0), "BEP20: transfer to the zero address");
    update();
    require(isRedeemable[recipient]);
    Irt redeemableToken = Irt(recipient);
    uint256 _currentDay = getCurrentDay();
    uint256 _dailyBurns = dailyBurns[recipient][_currentDay].add(amount);
    uint256 _dailyMints = dailyMints[recipient][_currentDay];
    require(_dailyBurns < redeemableToken.getDailyBurnLimit().add(_dailyMints));
    dailyBurns[recipient][_currentDay] = _dailyBurns;
    _burn(sender, amount);
    totalBurns[_currentDay] = totalBurns[_currentDay].add(amount);
    redeemableToken.mint(sender, amount);
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    update();
    if(isRedeemable[recipient]) {
      _convert(sender, recipient, amount);
    } else {
      _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
      _balances[recipient] = _balances[recipient].add(amount);
      emit Transfer(sender, recipient, amount);
    }
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");
    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }

  function getCurrentDay() public view returns (uint256) {
    return now / 86400;
  }

  function settings(address _grtOracle, address _gCoinAddr, address _bnbOracle, uint256 _minBalance) external onlyOwner {
    grtOracle = IOracle(_grtOracle);
    minBalance = _minBalance;
    gCoinAddr = _gCoinAddr;
    if(_bnbOracle != address(bnbOracle)) {
      updatedOracleAddr = _bnbOracle;
      lastUpdate2 = now;
    }
  }

  function setValidLps(address [] calldata _validLps) external onlyOwner {
    require(_validLps.length == 5);
    validLps = _validLps;
  }

  function isTokenRedeemable(address addr) public view returns (bool) {
    return isRedeemable[addr];
  }  

  function setNewOracleAddress() external {
    require(updatedOracleAddr != address(0x0));
    require(now.sub(lastUpdate2) > 1209600 && lastUpdate2 > 0);
    bnbOracle = IOracle(updatedOracleAddr);
    lastUpdate2 = 0;
    updatedOracleAddr = address(0x0);
  }

  function removeToken(address addr) internal {
    isRedeemable[addr] = false;
    removeDisabledTokens();
  }

  function setRedeemStatus(address addr, bool status) public onlyOwner {
    if(status) {
      require(redeemList.length < (now - 1684235642) / 172800);
      isRedeemable[addr] = true;
      redeemList.push(addr);
    } else {
      require(isRedeemable[addr]);
      removeToken(addr);
    }
  }

  function removeDisabledTokens() internal {
    uint256 _l = redeemList.length;
    address[] memory newRedeemList = new address[](_l);
    uint256 index = 0;
    for(uint256 i; i < _l; i++) {
      if(isRedeemable[redeemList[i]]) {
        newRedeemList[index++] = redeemList[i];
      }
    }
    redeemList = newRedeemList;
    for(uint256 i; i < (_l - index); i++) {
      redeemList.pop();
    }
  }

  function update() public {
    uint256 timePassed = now.sub(lastUpdate); 
    if(timePassed > 86400) {
      laggingSupply = getLaggingSupply();
      lastUpdate = now; 
    }
  }

  function lockLP(uint256 index, uint256 amount) external {
    require(index < 5);
    require(validLps[index] != address(0x0));
    withdrawBNB();
    address _tokenAddr = validLps[index];
    IBEP20 _token = IBEP20(_tokenAddr);    
    uint256 balanceBefore = _token.balanceOf(address(this));    
    _token.transferFrom(_msgSender(), address(this), amount);
    uint256 balanceAfter = _token.balanceOf(address(this));
    uint256 diff = balanceAfter.sub(balanceBefore);  
    locked[_tokenAddr][msg.sender] = locked[_tokenAddr][msg.sender].add(diff);
    totalLocked[_tokenAddr] = totalLocked[_tokenAddr].add(diff);
    if(lastClaim[msg.sender] == 0) {
      lastClaim[msg.sender] = now;
    }
  }

  function withdrawBNB() public {
    address payable account = _msgSender();
    require(aboveMinBalance(account));
    uint256 ndays = now.sub(lastClaim[account]) / 86400;
    if(ndays > 0 && lastClaim[account] > 0) {
      lastClaim[account] = now;
      if(ndays > 10) ndays = 10;
      uint256 transferAmount = ndays.mul(withdrawableDailyAmount(account));
      if(transferAmount > 0) {
        totalClaims[account] = totalClaims[account].add(transferAmount);
        account.transfer(transferAmount);
      }
    }
  }

  function aboveMinBalance(address account) internal view returns(bool) {
    return (IBEP20(gCoinAddr).balanceOf(account) > minBalance);
  }

  function withdrawableDailyAmount(address account) public view returns(uint256) {
    uint256 transferAmount;
    for(uint256 i = 0; i < 5; i++) {
      address _token = validLps[i];
      if(_token != address(0x0)) {
        uint256 _a = locked[_token][account].mul(address(this).balance) / (totalLocked[_token].mul(100));
        transferAmount = transferAmount.add(_a);
      } 
    }
    return transferAmount;
  }

  function getLaggingSupply() internal view returns(uint256) {
    uint256 timePassed = now.sub(lastUpdate); 
    return (laggingSupply.mul(2592000).add(_totalSupply.mul(timePassed))) / (2592000 + timePassed);
  }

  function mint(address account, uint256 amount) public {
    require(isRedeemable[msg.sender]);
    require(account != address(0), "BEP20: mint to the zero address");
    uint256 _currentDay = getCurrentDay();
    uint256 _totalMints = totalMints[_currentDay].add(amount);
    if(_totalMints > totalBurns[_currentDay]) {
      require(_totalMints - totalBurns[_currentDay] < getLaggingSupply() / 100);
    }
    uint256 _dailyMints = dailyMints[msg.sender][_currentDay].add(amount);
    uint256 _dailyBurns = dailyBurns[msg.sender][_currentDay];
    require(_dailyMints < Irt(msg.sender).getDailyMintLimit().add(_dailyBurns));
    dailyMints[msg.sender][_currentDay] = _dailyMints;
    totalMints[_currentDay] = _totalMints;
    _mint(account, amount);    
  }

  function getCurrentPrice() public view returns (uint256) {
    return 1000 * 1e15;
  }

  function getBnbPrice() public view returns (uint256) {
    return 1000 * 1e15;
  }

  function getGlobals() external view returns (uint256[4] memory) {
    uint256 _currentDay = getCurrentDay();
    return [totalMints[_currentDay], totalBurns[_currentDay], getLaggingSupply(), minBalance];
  }  

  function mintBurnHistory(address addr, uint256 day) external view returns (uint256[2] memory) {
    return [dailyMints[addr][day], dailyBurns[addr][day]];
  }

  function getTokenInfo(address addr) external view returns (uint256[4] memory) {
    uint256 _currentDay = getCurrentDay();
    return [dailyMints[addr][_currentDay], dailyBurns[addr][_currentDay], getDailyBurnLimit(addr), getDailyMintLimit(addr)];
  }

  function () external payable {
    uint256 _amount = (msg.sender == owner() ? msg.value * 11 / 10 : msg.value) * getBnbPrice() * 100 / 1e18;
    _mint(_msgSender(), _amount);
  }

}