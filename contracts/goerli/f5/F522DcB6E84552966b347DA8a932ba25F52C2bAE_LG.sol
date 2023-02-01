/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

pragma solidity ^0.4.24;
/**
 * 链改网

 * 域名：https://lgqkl.github.io/LG-QKL     ------Domain name: https://lgqkl.github.io/LG-QKL
 * 最新域名请通过 “HTTPS” 函数调取。 ----Call function “HTTPS" for get new domain name.
 * 
 * 打造良心区块链生态应用。---Build a conscience based Ecological Application of blockchain.
 * 
 * 打造中国人自己的区块链生态应用。---Build Chinese people's own ecological application of blockchain.
 * 
 * 大原则：不坑人、不圈钱、不跑路！---Big principle: no cheated, no Misappropriating money, no running!
 * 
 * 目标：---Target 
 * 开发各种实用生态   ---Develop all kinds of practical ecology
 * 让老百姓享受到区块链带来的好处  ---Let people enjoy the benefits of blockchain
 * 最终让区块链赋能实体经济  ---Finally, let the blockchain enable the real economy
 * 
 * 联系我们：
 * github: https://github.com/LGQKL/LG-QKL/tree/main
 */

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)external returns (bool);

  function transferFrom(address from, address to, uint256 value)external returns (bool);

  event Transfer(address indexed from,address indexed to,uint256 value);

  event Approval(address indexed owner,address indexed spender,uint256 value);
}
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner,address spender)public view returns (uint256){
    return _allowed[owner][spender];
  }

  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value)public returns (bool){
    require(value <= _allowed[from][msg.sender]);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue)public returns (bool){
    require(spender != address(0));
    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)public returns (bool){
    require(spender != address(0));
    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);
    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

contract LG is ERC20 {

    string public name = "LG-QKL";  
    string public symbol = "LG";
    uint8 public decimals = 18;
    string public HTTPS = "https://lgqkl.github.io/LG-QKL";  //最新域名请通过此函数调取。Call this string for get new domain name.
    address public owner;

    constructor() public{
      owner = msg.sender;
      _mint(msg.sender, 21000000000000000000000000);
    }
    modifier ownerOnly() {
        require(msg.sender == owner);
        _; 
    }

    function transferOwer(address newOwner)public ownerOnly{
        owner = newOwner;
    }

    function mint(uint256 value) public ownerOnly returns (bool){
      _mint(msg.sender,value);
      return true;
    }

    function burn(uint256 value) public ownerOnly returns (bool){
      _burn(msg.sender, value);
      return true;
    }

    function https(string _https) public ownerOnly returns (bool){
      HTTPS = _https;
      return true;
    }

}