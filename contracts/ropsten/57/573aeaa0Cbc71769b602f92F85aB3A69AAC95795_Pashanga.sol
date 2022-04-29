// SPDX-License-Identifier: UNLICENSED
pragma solidity < 0.9.0;

import "./Token20Interface.sol";

contract SafeMath {
   function safeAdd(uint a, uint b) public pure returns (uint c) {
      c = a + b;
      require(c >= a,"SAFE ADD ERROR");
   }
   function safeSub(uint a, uint b) public pure returns (uint c) {
      require(b <= a,"SAFE SUB ERROR"); c = a - b;
   } 
        
   function safeMul(uint a, uint b) public pure returns (uint c) {
      c = a * b;
      require(a == 0 || c / a == b,"SAFE MUL ERROR");
   }

   function safeDiv(uint a, uint b) public pure returns (uint c) { 
      require(b > 0,"SAFE DIV ERROR");
      c = a / b;
   }
}

contract Pashanga is Token20Interface, SafeMath {

   string public name;
   string public symbol;
   uint8 public decimals;
   uint256 _totalSupply;

   mapping(address => uint) balances;

   mapping(address => mapping(address => uint)) allowed;

   constructor() public {
      name = "Pashanga";
      symbol = "PSH";
      decimals = 18;
      _totalSupply = 100000000000000000000000000;

      balances[msg.sender] = _totalSupply;
      emit Transfer(address(0), msg.sender, _totalSupply);
   }

   function getSender () public view returns (address) {
      return msg.sender;
   }

   function totalSupply() 
		public 
		view
      override
		returns (uint) {

      return _totalSupply - balances[address(0)];
   }

   function balanceOf(address tokenOwner)
      public 
      view
      override
      returns (uint balance) {

    return balances[tokenOwner];
   }

   function allowance (address tokenOwner, address spender) 
      public 
      view
      override
      returns (uint remaining) {

    return allowed[tokenOwner][spender];
   }

   function approve(address spender, uint tokens) override public 
	   returns (bool success) {

      allowed[msg.sender][spender] = tokens;
      emit Approval(msg.sender, spender, tokens);
      
      return true;
   }

   function transfer(address to, uint tokens) override public payable
	   returns (bool success) {

      balances[msg.sender] = safeSub(balances[msg.sender], tokens);
      balances[to] = safeAdd(balances[to], tokens);

      emit Transfer(msg.sender, to, tokens);
      return true;
   }

   function transferFrom (address from, address to, uint tokens) 
	override public returns (bool success) {

      balances[from] = safeSub(balances[from], tokens);
      allowed[from][msg.sender] = safeSub(allowed[from][msg.sender],tokens);
      balances[to] = safeAdd(balances[to],tokens);
         
      emit Transfer(from, to, tokens);
      return true;
   }

}