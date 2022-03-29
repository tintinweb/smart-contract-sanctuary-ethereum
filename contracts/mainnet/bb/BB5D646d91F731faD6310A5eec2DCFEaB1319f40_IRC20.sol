/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}
contract IRC20 is Ownable {
	event Approval(address indexed owner, address indexed spender, uint value);
	event Transfer(address indexed from, address indexed to, uint value);
	
	
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    
    bool public isBridgeToken = true;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
	
    function getOwner() public view returns (address) {
        return owner;
    }

    function balanceOf(address account) public  view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public  returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address account, address spender) public  view returns (uint256) {
        return _allowances[account][spender];
    }

    function approve(address spender, uint256 amount) public  returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public  returns (bool) {
        _transfer(sender, recipient, amount);
        require(_allowances[sender][msg.sender] >= amount, 'ERC20: transfer amount exceeds allowance');
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public  returns (bool) {
        uint c = _allowances[msg.sender][spender] + addedValue;
        require(c >= addedValue, "SafeMath: addition overflow");
        _approve(msg.sender, spender, c);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public  returns (bool) {
        require(_allowances[msg.sender][msg.sender] >= subtractedValue, 'ERC20: decreased allowance below zero');
        _approve(msg.sender, spender, _allowances[msg.sender][msg.sender] - subtractedValue);
        return true;
    }

    function mint(uint256 amount) public  onlyOwner returns (bool) {
        _mint(msg.sender, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), 'HRC20: transfer from the zero address');
        require(recipient != address(0), 'HRC20: transfer to the zero address');
        require(_balances[sender] >= amount, 'ERC20: transfer amount exceeds balance');
        _balances[sender] -= amount;
        uint c = _balances[recipient] + amount;
        require(c >= amount, "SafeMath: addition overflow");
        _balances[recipient] = c;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'HRC20: mint to the zero address');
        uint c = totalSupply + amount;
        require(c >= amount, "SafeMath: addition overflow");
        totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'HRC20: burn from the zero address');
        require(_balances[account] >= amount, 'ERC20: burn amount exceeds balance');
        _balances[account] -= amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address account, address spender, uint256 amount) internal {
        require(account != address(0), 'HRC20: approve from the zero address');
        require(spender != address(0), 'HRC20: approve to the zero address');
        _allowances[account][spender] = amount;
        emit Approval(account, spender, amount);
    }

    function mintTo(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function burnFrom(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }
}