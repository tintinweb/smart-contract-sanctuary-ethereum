/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// File: contracts/Distribute.sol

/**
 *Submitted for verification at Etherscan.io on 2020-03-28
*/

pragma solidity ^0.8.17;

library SafeMath {
  function mul(uint a, uint b) internal pure  returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal pure returns (uint) {
    require(b > 0);
    uint c = a / b;
    require(a == b * c + a % b);
    return c;
  }
  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a);
    return c;
  }
  function max64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a >= b ? a : b;
  }
  function min256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a < b ? a : b;
  }
}

abstract contract ERC20Basic {
  uint public totalSupply;
  function transfer(address to, uint value) public virtual;
  event Transfer(address indexed from, address indexed to, uint value);
}

abstract contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public virtual view returns (uint);
  function transferFrom(address from, address to, uint value) public virtual ;
  function approve(address spender, uint value) public virtual;
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract BasicToken is ERC20Basic {

  using SafeMath for uint;

  mapping(address => uint) balances;

  function transfer(address _to, uint _value) public override {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
  }

}

contract StandardToken is BasicToken, ERC20 {
    using SafeMath for uint;
    
  mapping (address => mapping (address => uint)) allowed;

  function transferFrom(address _from, address _to, uint _value) public override {
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint _value) public override{
    require((_value == 0) || (allowed[msg.sender][_spender] == 0)) ;
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) public override view returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

contract Distribute {
    
    using SafeMath for uint;
    
    function tokenSendMultiple(address _tokenAddress, address payable[] memory _to, uint[] memory _value)  internal  {

		require(_to.length == _value.length);
		require(_to.length <= 255);

        StandardToken token = StandardToken(_tokenAddress);
        
		for (uint8 i = 0; i < _to.length; i++) {
			token.transferFrom(msg.sender, _to[i], _value[i]);
		}
	}
	
	function ethSendMultiple(address payable[] memory _to, uint[] memory _value) internal {

		uint remainingValue = msg.value;

		require(_to.length == _value.length);
		require(_to.length <= 255);

		for (uint8 i = 0; i < _to.length; i++) {
			remainingValue = remainingValue.sub(_value[i]);
			require(_to[i].send(_value[i]));
		}
    }
    
    function distributeToken(address _tokenAddress, address payable[] memory _to, uint[] memory _value) payable public {
	    tokenSendMultiple(_tokenAddress, _to, _value);
    }
    
    function distributeEther(address payable[] memory _to, uint[] memory _value) payable public {
		 ethSendMultiple(_to,_value);
	}
}