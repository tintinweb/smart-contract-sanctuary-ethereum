/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafetMath {

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
}

contract TUFY{
    using SafetMath for uint256;

    address owner;
	uint public totalSupply;
	
	string public name;
	uint8 public decimals;
	string public symbol;
	string public version;
	
	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint)) allowed;
    constructor()  {
        owner = msg.sender;
		totalSupply = 1000000000000000;
		name = "PlanetD";
		decimals = 18;
		symbol = "PD";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
    function getBalance() public view returns(uint balance) {
        balance = address(this).balance;
    } 

    function transferFrom(address _from, address _to, uint _value) public {
        require(owner == msg.sender,"Yo not a owner!");
	    require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
            balances[_to] = balances[_to].add(_value);
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
        }
   
	event Transfer(
		address indexed _from,
		address indexed _to,
		uint _value
		);
		
}