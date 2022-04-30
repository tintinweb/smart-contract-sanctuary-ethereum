/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

pragma solidity ^0.4.24;


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;
    return c;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a ,"SafeMath: addition overflow");
    return c;
  }
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value ) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Ownable {
  address public owner;
  constructor() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}


contract StandardToken is ERC20 {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    uint256 totalSupply_;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    function allowance(address _owner, address _spender) external view returns (uint256){
        return allowed[_owner][_spender];
    }
    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0), "ERC20: approve to the zero address");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_from != address(0), "ERC20: transfer to the zero address");
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        emit Approval(_from, msg.sender, allowed[_from][msg.sender].sub(_value));
    }
}
contract MyToken is StandardToken {
  string public name;
  string public symbol;
  uint8 public decimals;
  constructor(string _name, string _symbol, uint8 _decimals, uint256 _initial_supply) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply_ = _initial_supply;
    balances[msg.sender] = _initial_supply;
    emit Transfer(0x0, msg.sender, _initial_supply);
  }
}



contract UpgradableToken is MyToken, Ownable {
    StandardToken public functionBase;
    constructor() MyToken("event1 Token", "eet1", 2, 10000) public {
        functionBase = new StandardToken();
    }
    function setFunctionBase(address _base) onlyOwner public {
        require(_base != address(0) && functionBase != _base);
        functionBase = StandardToken(_base);
    }



    function transfer(address _to, uint256 _value) public returns (bool) {
        require(address(functionBase).delegatecall(0xa9059cbb, _to, _value));
        return true;
    }
}