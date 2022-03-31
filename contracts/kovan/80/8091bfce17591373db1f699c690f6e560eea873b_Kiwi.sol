/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.13;

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
	
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
	
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
}

contract Ownable {

    address public owner;
	
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
	
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
    
}

contract Pausable is Ownable {
	event Pause();
	event Unpause();

	bool public paused = false;
  
	modifier whenNotPaused() {
		require(!paused);
		_;
	}
  
	modifier whenPaused() {
		require(paused);
		_;
	}
  
	function pause() onlyOwner whenNotPaused public {
		paused = true;
		emit Pause();
	}
	
	function unpause() onlyOwner whenPaused public {
		paused = false;
		emit Unpause();
	}
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
	event Burn(address indexed burner, uint256 value);
	
    event AddToWhiteList(address _address);
    event RemovedFromWhiteList(address _address);
	event AddedBlackList(address _address);
    event RemovedBlackList(address _address);
}

contract ERC20Basic is IERC20, Pausable {
	using SafeMath for uint256;
	
	uint256 public txnFee = 100;
	address public feeAddress = address(this); 
	address public exchangeAddress;
	
	struct User{
	   uint256 lockedAmount;
	   uint256 unlockTime;
	}
	
	mapping(address => uint256) balances;
	mapping(address => bool) public isBlackListed;
    mapping(address => mapping (address => uint256)) allowed;
	mapping(address => bool) public isWhiteListed;
	mapping(address => bool) public isExcludedFromFee;
	mapping(address => User) public users;
	
    uint256 totalSupply_;
	
    function totalSupply() public override view returns (uint256) {
       return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }
	
    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
	    require(!isBlackListed[msg.sender]);
		
		if(users[msg.sender].unlockTime > block.timestamp)
		{
		   uint256 newBalances = balances[msg.sender].sub(users[msg.sender].lockedAmount); 
		   require(numTokens <= newBalances, "transfer amount exceeds balance");
		}
		else
		{
		    if(users[msg.sender].unlockTime > 0)
			{
			   users[msg.sender].unlockTime = 0;
			   users[msg.sender].lockedAmount = 0;
			}
		    require(numTokens <= balances[msg.sender], "transfer amount exceeds balance");
		}
		
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
		if(paused) 
		{
		    require(isWhiteListed[msg.sender], "sender not whitelist to transfer");
		}
		if(isExcludedFromFee[msg.sender] || isExcludedFromFee[receiver])
		{
			balances[receiver] = balances[receiver].add(numTokens);
			emit Transfer(msg.sender, receiver, numTokens);
        }
		else
		{
			uint256 txnFeeTrx = numTokens.mul(txnFee).div(10000);
			balances[feeAddress] = balances[feeAddress].add(txnFeeTrx);
			
			balances[receiver] = balances[receiver].add(numTokens.sub(txnFeeTrx));
			emit Transfer(msg.sender, receiver, numTokens.sub(txnFeeTrx));
			emit Transfer(msg.sender, feeAddress, txnFeeTrx);
		}
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }
	
    function transferFrom(address sender, address receiver, uint256 numTokens) public override returns (bool) {
        require(!isBlackListed[sender]);
		
		if(users[sender].unlockTime > block.timestamp)
		{
		   uint256 newBalances = balances[sender].sub(users[sender].lockedAmount); 
		   require(numTokens <= newBalances, "transfer amount exceeds balance");
		}
		else
		{
		    if(users[sender].unlockTime > 0)
			{
			   users[sender].unlockTime = 0;
			   users[sender].lockedAmount = 0;
			}
		    require(numTokens <= balances[sender], "transfer amount exceeds balance");
		}
		
        require(numTokens <= allowed[sender][msg.sender]);
		if(paused)
		{
		   require(isWhiteListed[sender], "sender not whitelist to transfer");
		}
        balances[sender] = balances[sender].sub(numTokens);
        allowed[sender][msg.sender] = allowed[sender][msg.sender].sub(numTokens);
		
		if(isExcludedFromFee[sender] || isExcludedFromFee[receiver])
		{
			balances[receiver] = balances[receiver].add(numTokens);
			emit Transfer(sender, receiver, numTokens);
        }
		else
		{
			uint256 txnFeeTrx = numTokens.mul(txnFee).div(10000);
			balances[feeAddress] = balances[feeAddress].add(txnFeeTrx);
			
			balances[receiver] = balances[receiver].add(numTokens.sub(txnFeeTrx));
			emit Transfer(sender, receiver, numTokens.sub(txnFeeTrx));
			emit Transfer(sender, feeAddress, txnFeeTrx);
		}
		return true;
    }
	
	function burn(uint256 _value) public whenNotPaused{
	    require(!isBlackListed[msg.sender]);
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
    }
	
	function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

	function __mint(address _to, uint256 _amount) internal {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);
    }
	
	function getBlackListStatus(address _maker) public view returns (bool) {
        return isBlackListed[_maker];
    }
	
	function addBlackList(address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }
	
	function getWhiteListStatus(address _address) public view returns (bool) {
        return isWhiteListed[_address];
	}
	
	function whiteListAddress(address _address) public onlyOwner{
	   isWhiteListed[_address] = true;
	   emit AddToWhiteList(_address);
    }
	
	function removeWhiteListAddress (address _address) public onlyOwner{
	   isWhiteListed[_address] = false;
	   emit RemovedFromWhiteList(_address);
	}
	
	function setTxnFee(uint256 newFee) external onlyOwner {
		txnFee = newFee;
	}
	
	function setFeeAddress(address payable newAddress) external onlyOwner() {
       require(newAddress != address(0), "zero-address not allowed");
	   feeAddress = newAddress;
    }
	
	function setExchangeAddress(address newAddress) external onlyOwner() {
       require(newAddress != address(0), "zero-address not allowed");
	   exchangeAddress = newAddress;
    }
	
	function excludeFromFee(address account) public onlyOwner {
        isExcludedFromFee[account] = true;
    }
	
	function includeInFee(address account) public onlyOwner {
        isExcludedFromFee[account] = false;
    }
	
	function transferTokens(address tokenAddress, address to, uint256 amount) public onlyOwner {
        IERC20(tokenAddress).transfer(to, amount);
    }
	
	function withdrawalTokens(address to, uint256 amount) public onlyOwner {
        IERC20(address(this)).transfer(to, amount);
    }
	
	function lockToken(address user, uint256 amount, uint256 unlockTime) public {
	   require(msg.sender == owner || msg.sender == exchangeAddress, "sender not allowed");
	   require(unlockTime > 0, "unlockTime is not correct");
	   require(balances[user] >= amount, "lock amount exceeds balance");
	   
	   users[user].lockedAmount = users[user].lockedAmount.add(amount);
	   users[user].unlockTime = unlockTime;
    }
	
	function unlockToken(address user) public onlyOwner{
	   require(users[user].lockedAmount >= 0, "locked amount not found");
	   
	   users[user].lockedAmount = 0;
	   users[user].unlockTime = 0;
    }
}

contract Kiwi is ERC20Basic {
    string public constant name = "Kiwi Holding";
    string public constant symbol = "Kiwi";
    uint8 public constant decimals = 2;
    uint256 public constant INITIAL_SUPPLY = 20000000 * 10**2;
	
	constructor(address _owner){
	   owner = _owner;
	   isExcludedFromFee[owner] = true;
	   __mint(owner, INITIAL_SUPPLY);
   }
}