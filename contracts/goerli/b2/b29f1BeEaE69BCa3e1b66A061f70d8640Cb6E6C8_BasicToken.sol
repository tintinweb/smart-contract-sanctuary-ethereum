// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract BasicToken {
   event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
   event Transfer(address indexed from, address indexed to, uint256 tokens);

   uint256 _totalSupply;
   string public name;
   string public symbol;
   uint8 public constant decimals = 18;

   mapping(address => uint256) balances;
   mapping(address => mapping(address => uint256)) allowed;

   mapping(string => uint256) public nameToFavoriteNumber;

   constructor(uint256 total, string memory _name, string memory _symbol) {
      _totalSupply = total * (10 ** uint256(decimals));
      name = _name;
      symbol = _symbol;
      balances[msg.sender] = _totalSupply;
   }

   function totalSupply() public view returns (uint256) {
      return _totalSupply;
   }

   function balanceOf(address tokenOwner) public view returns (uint) {
      return balances[tokenOwner];
   }

   function transfer(address receiver, uint numTokens) public returns (bool) {
      require(numTokens <= balances[msg.sender]);
      balances[msg.sender] = balances[msg.sender] - numTokens;
      balances[receiver] = balances[receiver] + numTokens;
      emit Transfer(msg.sender, receiver, numTokens);
      return true;
   }

   function approve(address delegate, uint numTokens) public returns (bool) {
      allowed[msg.sender][delegate] = numTokens;
      emit Approval(msg.sender, delegate, numTokens);
      return true;
   }

   function allowance(address owner, address delegate) public view returns (uint) {
      return allowed[owner][delegate];
   }

   function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
      require(numTokens <= balances[owner]);
      require(numTokens <= allowed[owner][msg.sender]);

      balances[owner] = balances[owner] - numTokens;
      allowed[owner][msg.sender] = allowed[owner][msg.sender] - numTokens;
      balances[buyer] = balances[owner] + numTokens;

      emit Transfer(owner, buyer, numTokens);

      return true;
   }
}