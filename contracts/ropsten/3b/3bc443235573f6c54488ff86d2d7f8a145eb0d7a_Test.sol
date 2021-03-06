pragma solidity ^0.4.21;

contract Token {
 
  function transferFrom(address from, address to, uint256 tokens) public returns(uint256);
  function transfer(address to, uint256 tokens) public returns (bool);
  function balanceOf(address _owner) public returns (uint256); 
}

contract Test {
 
   address token_address = 0x6eacf7590c3842AF65cC718Ea9e87406B5F6Db7D;
 
  function sendTokens() public {
    Token(token_address).transfer(msg.sender,300);
  }      
  
  function checkBalance() public returns(uint256) {
    return Token(token_address).balanceOf(this);      
  }
    
}