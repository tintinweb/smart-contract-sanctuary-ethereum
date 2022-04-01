// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DappToken} from "./DappToken.sol";

contract DappTokenSale {
    address admin;
    DappToken public tokenContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;

    event Sell(address _buyer, uint256 _amount);

    constructor(DappToken _tokenContract, uint256 _tokenPrice){
        admin = msg.sender;
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
    }

    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
        require(msg.value == multiply(_numberOfTokens, tokenPrice));
        require(tokenContract.balanceOf(address(this)) >= _numberOfTokens);
        require(tokenContract.transfer(msg.sender, _numberOfTokens));

        tokensSold += _numberOfTokens;

        emit Sell(msg.sender, _numberOfTokens);
    }

    function endSale() public {
        require(msg.sender == admin);
        require(tokenContract.transfer(admin, tokenContract.balanceOf(address(this))));

        // UPDATE: Let's not destroy the contract here
        // Just transfer the balance to the admin
        payable(address(admin)).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20Interface {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function transferFrom(address sender,address recipient,uint amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract DappToken is ERC20Interface {

  string public name;
  string public symbol;
  uint8 public decimals;
  uint public totalSupply;
  address public admin;

  mapping(address => uint) public balances;
  mapping(address => mapping(address=>uint)) public allowances;

  constructor(){
    name = 'SAM Token';
    symbol = "SAM2";
    decimals = 18;
    totalSupply = 1000000 * 10 ** 18;
    admin = msg.sender;
    balances[msg.sender] = totalSupply;
  }

  function transfer(address recipient, uint amount) external override returns(bool) {
    require(balances[msg.sender] >= amount, 'not enough tokens for transfer');
    balances[msg.sender] -= amount;
    balances[recipient] += amount;
    emit Transfer(msg.sender, recipient, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint amount) external override returns(bool) {
    uint allowed = allowances[sender][msg.sender];
    require(allowed >= amount && balances[sender] >=amount, 'allowance too low');
    allowances[sender][msg.sender] -= amount;
    balances[sender] -= amount;
    balances[recipient] += amount;
    emit Transfer(sender, recipient, amount);
    return true;
  }

  function approve(address spender, uint amount) external override returns(bool){
    require(spender != msg.sender);
    allowances[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function burn(uint amount) external returns(bool){
    require(balances[msg.sender] >= amount, 'not enought tokens to burn');
    balances[msg.sender] -= amount;
    totalSupply -= amount;
    emit Transfer(msg.sender, address(0), amount);
    return true;
  }

  function allowance(address owner, address spender) external override view returns(uint){
    return allowances[owner][spender];
  }

  function balanceOf(address account) external override view returns(uint){
    return balances[account];
  }

}