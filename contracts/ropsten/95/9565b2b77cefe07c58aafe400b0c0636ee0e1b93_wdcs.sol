/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;



contract wdcs{

	string name;
	string symbol;
	uint public totalsupply;
	
	mapping(address => uint) balances;
	mapping(address => mapping(address => uint)) allowed;
	
	constructor(string memory _name, string memory _symbol, uint _totalsupply){
		name = _name;
		symbol = _symbol;
		totalsupply = _totalsupply;
		
		balances[msg.sender] = totalsupply * 10 **18;
	}

	// function totalsupply() public view returns(uint){
		
	
	function balanceof(address tokenowner) public view returns(uint){
		return balances[tokenowner];
	}
	
	function allownces(address from, address spender) public view returns(uint){
		return allowed[from][spender];
	}
	
	function approve(address spender, uint tokens) public returns (bool){
		allowed[msg.sender][spender] = allowed[msg.sender][spender] + tokens;
		return true;
	}
	
	function transfer(address to , uint tokens) public returns (bool){
		balances[msg.sender] = balances[msg.sender] - tokens;
		balances[to] = balances[to] + tokens;
		return true;
	}
	
	function transferfrom(address from, address to, uint tokens) public returns (bool){
		balances[from] = balances[from] - tokens;
		allowed[from][msg.sender] = allowed[from][msg.sender] - tokens;
		balances[to] = balances[to]+tokens;
		return true;
	} 

    function burn(address account ,uint amount) public returns (bool){
         balances[account] = balances[account]-amount;
         totalsupply = totalsupply - amount;
         return true;
    }

    function mint(address account ,uint amount) public returns (bool){
        balances[account] = balances[account] + amount;
        totalsupply = totalsupply + amount;
        return true;
    }


}