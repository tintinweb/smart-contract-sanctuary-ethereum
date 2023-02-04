// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

//       ___           ___           ___           ___                 
//      /\__\         /\  \         /\  \         /\__\          ___   
//     /:/ _/_       /::\  \       /::\  \       /::|  |        /\  \  
//    /:/ /\__\     /:/\:\  \     /:/\:\  \     /:|:|  |        \:\  \ 
//   /:/ /:/ _/_   /::\~\:\  \   /:/  \:\  \   /:/|:|__|__      /::\__\
//  /:/_/:/ /\__\ /:/\:\ \:\__\ /:/__/_\:\__\ /:/ |::::\__\  __/:/\/__/
//  \:\/:/ /:/  / \/__\:\/:/  / \:\  /\ \/__/ \/__/~~/:/  / /\/:/  /   
//   \::/_/:/  /       \::/  /   \:\ \:\__\         /:/  /  \::/__/    
//    \:\/:/  /        /:/  /     \:\/:/  /        /:/  /    \:\__\    
//     \::/  /        /:/  /       \::/  /        /:/  /      \/__/    
//      \/__/         \/__/         \/__/         \/__/                

/* 
  This is an ill-advised attempt to create a token by
  NOT using openZeppelin's ERC20.sol

  Heed my warning: at all costs, do NOT deal real money into this. 
  it's probably a bad idea lmao cause I have no idea what I'm doing
  
  With much love, 
  - zeroxwagmi
*/

contract WagmiCoin {
  mapping (address=>uint256) hodlers;
  uint256 public maxSupply = 1000000000 * (10 ** uint256(decimals())); // a billi
  uint256 private _totalSupply;
  mapping (address=>mapping(address=>uint256)) private _allowances;
  string public symbol;
  string public name;
  address public owner; 

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  constructor(string memory symbolInput, string memory nameInput) {
    owner = msg.sender;
    symbol = symbolInput;
    name = nameInput;
  }

  modifier onlyOwner() { 
    require(msg.sender == owner, "Only the owner can call this function");
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
  } 

  function mint(uint256 amount) public onlyOwner {
    require(msg.sender != address(0), "ERC20: mint to the zero address");

    hodlers[msg.sender] += amount;
    _totalSupply += amount;

    emit Transfer(address(0), msg.sender, amount);
  }

  function decimals() public pure returns (uint8) { 
    return 18; 
  }

  // Write an approve() function that will allow the user to approve a certain amount of tokens to be transferred from their account to another account.
  function approve(address spender, uint256 amount) public {
    require(msg.sender != address(0), "ERC20: approve from the zero address");
    // Woah, this one below is sneaky. I think if I didn't add this, then anyone would would be able to transfer tokens out of the zero address.
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);
  }

  function increaseAllowance(address spender, uint256 amount) public { 
    require(msg.sender != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[msg.sender][spender] += amount;

    emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
  }

  function decreaseAllowance(address spender, uint256 amount) public {
    require(msg.sender != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[msg.sender][spender] -= amount;

    emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
  }

  function transferFrom(address sender, address recipient, uint256 amount) public {
    require(_allowances[sender][msg.sender] >= amount, "Not approved to spend this amount");
    require(hodlers[sender] >= amount, "Not enough funds");
    require(hodlers[recipient] + amount >= hodlers[recipient], "Overflow error");

    hodlers[sender] -= amount;
    hodlers[recipient] += amount;
    
    emit Transfer(sender, recipient, amount);
  }

  function transfer(address recipient, uint256 amount) public {
    require(hodlers[msg.sender] >= amount, "Not enough funds");
    require(hodlers[recipient] + amount >= hodlers[recipient], "Overflow error");

    hodlers[msg.sender] -= amount;
    hodlers[recipient] += amount;

    emit Transfer(msg.sender, recipient, amount);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address inputAddress) public view returns (uint256) {
    return hodlers[inputAddress];
  }
}