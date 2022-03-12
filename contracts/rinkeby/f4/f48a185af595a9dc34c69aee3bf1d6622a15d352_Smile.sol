// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./interface.sol";

contract Smile is ERC20Interface
{
 string token_name = "Smile";
 string token_symbol = "SMILE";

 uint256 init_time;
 uint256 halt_time;
 uint256 end_time;
 uint256 token_price = 1000000000 wei; // 1 ETH = 1 B SMILE =  1000 M SMILE
 uint256 total_supply = 0;
 uint256 min_payment = 0.000001 ether;
 uint256 max_payment = 1 ether;
 string admin_name;
 address payable deposit;
 mapping(address => uint256) balances;
 mapping(address => mapping(address => uint256)) allowed_allowance; 
 enum State {None, Running, Halted, End}
 State state;
 event Buy(address buyer, uint256 value, uint256 tokens);
 event Sell(address seller, uint256 tokens, uint256 value);

 uint8 public override decimals = 0;
 address public admin;

 constructor(string memory val_admin_name, uint256 val_amount, address payable val_deposit)
 {
  init_time = block.timestamp;
  admin = msg.sender;
  admin_name = val_admin_name;  
  total_supply = val_amount;
  balances[admin] = val_amount;
  deposit = val_deposit;
  state = State.Running;
 }

 modifier bAdmin()
 {
  require(admin==msg.sender);
  _;
 }

 modifier bRunning()
 {
  require(state==State.Running);
  _;
 }

 modifier notEnd()
 {
  require(state!=State.End);
  _;
 }

 function Check_name(string memory val_name) private view
 {
  bytes32 hash_inp = keccak256(abi.encodePacked(val_name));
  bytes32 hash_adminname = keccak256(abi.encodePacked(admin_name));
  require(hash_inp==hash_adminname);
 }




 // admin functions

 function halt(string memory val_name) bAdmin notEnd public
 {
  Check_name(val_name);

  halt_time = block.timestamp;
  state = State.Halted;
 }

 function resume(string memory val_name) bAdmin notEnd public
 {
  Check_name(val_name);
  
  state = State.Running;
 }

 function end(string memory val_name) bAdmin notEnd public
 {
  Check_name(val_name);
  
  state = State.End;
  balances[admin] = 0;
 }




 // public methods

 function name() public override view returns (string memory)
 {
  return token_name;
 }
 
 function symbol() public override view returns (string memory)
 {
  return token_symbol;
 }

 function totalSupply() public override view returns (uint256)
 {
  return total_supply;
 }

 function balanceOf(address owner) notEnd public override view returns (uint256 balance)
 {
  return balances[owner];
 }

 function get_current_state() public view returns (State)
 {
  return state;
 }



 // action functions

 function transfer(address to, uint256 tokens) bRunning public override returns (bool success)
 {
  require(balances[msg.sender]>=tokens);

  balances[to] += tokens;
  balances[msg.sender] -= tokens;

  emit Transfer(msg.sender, to, tokens);
  return true;
 }

 function allowance(address owner, address spender) bRunning public override view returns (uint256 remaining)
 {
  return allowed_allowance[owner][spender];
 }

 function approve(address spender, uint256 tokens) bRunning public override returns (bool success)
 {
  require(balances[msg.sender]>=tokens);
  require(allowed_allowance[msg.sender][spender]==0);
  require(tokens>0);

  allowed_allowance[msg.sender][spender] = tokens;

  emit Approval(msg.sender, spender, tokens);
  return true;
 }

 function transferFrom(address from, address to, uint256 tokens) bRunning public override returns (bool success)
 {
  require(allowed_allowance[from][to]>=tokens);
  require(balances[from]>=tokens);

  balances[to] += tokens;
  allowed_allowance[from][to] -= tokens;
  balances[from] -= tokens;  

  emit Transfer(from, to, tokens);
  return true;
 }




 // payment

 function buy() bRunning payable public returns(bool)
 {
  require(min_payment<=msg.value && msg.value<=max_payment);

  uint256 tokens = msg.value / token_price;

  require(balances[admin]>tokens);
  balances[msg.sender] += tokens;
  deposit.transfer(msg.value);
  balances[admin] -= tokens;

  emit Buy(msg.sender, msg.value, tokens);
  return true;
 }

 receive() bRunning payable external
 {
  buy();
 }

 fallback() payable external
 {
  get_current_state();
 }
}