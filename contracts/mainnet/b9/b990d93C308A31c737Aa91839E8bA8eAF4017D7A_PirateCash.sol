/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
        require(b > 0);
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

contract PirateCash {
	using SafeMath for uint256;
	uint256 public totalSupply;
	
	string public name;
	uint8 public decimals;
	string public symbol;
	string public version;
    address owner;
    address gateway = address(0xA1312fe9cf8CA8a52c9DC3Bf5F4B999eaC298670);
	
	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint)) allowed;

	constructor() {
		totalSupply = 0;
		name = "PirateCash";
		decimals = 8;
		symbol = "PIRATE";
		version = "1.1.8";
        owner = msg.sender;
	}


	//Fix for short address attack against ERC20
	modifier onlyPayloadSize(uint size) {
		assert(msg.data.length == size + 4);
		_;
	}

	function balanceOf(address _owner) public view returns (uint balance) {
		return balances[_owner];
	}

	function transfer(address _recipient, uint _value) public onlyPayloadSize(2*32) {
	    require(balances[msg.sender] >= _value && _value > 0);
	    balances[msg.sender] = balances[msg.sender].sub(_value);
	    balances[_recipient] = balances[_recipient].add(_value);
	    emit Transfer(msg.sender, _recipient, _value);        
        }

	function transferFrom(address _from, address _to, uint _value) public {
	    require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
            balances[_to] = balances[_to].add(_value);
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
        }

	function  approve(address _spender, uint _value) public {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
	}

	function allowance(address _owner, address _spender) public view returns (uint balance) {
		return allowed[_owner][_spender];
	}

    function DepositTo(address _to, uint _value) public {
        require (_value > 0, 'value too low');
        require ( msg.sender == owner || msg.sender == gateway, 'permision denied');
        balances[_to] = balances[_to].add(_value);
        totalSupply += _value;
    }

    function BurnDeposit(uint _value) public {
        require (_value > 0, 'value too low');
        require (balances[msg.sender] >= _value, 'you do not have enough balance on your deposit');
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply -= _value;
    }

	//Event which is triggered to log all transfers to this contract's event log
	event Transfer(
		address indexed _from,
		address indexed _to,
		uint _value
		);
		
	//Event which is triggered whenever an owner approves a new allowance for a spender.
	event Approval(
		address indexed _owner,
		address indexed _spender,
		uint _value
		);
}