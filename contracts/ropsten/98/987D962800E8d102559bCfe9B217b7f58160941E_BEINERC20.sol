/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 interface IERC20{
function totalSupply() external view returns (uint256);
function balanceOf(address tokenOwner) external view returns (uint);
function allowance(address tokenOwner, address spender) external view returns (uint);
function transfer(address to, uint tokens) external returns (bool);
function approve(address spender, uint tokens)  external returns (bool);
function transferFrom(address from, address to, uint tokens) external returns (bool);
event Approval(address indexed tokenOwner, address indexed spender,
 uint tokens);
event Transfer(address indexed from, address indexed to,
 uint tokens);
 }
 pragma solidity ^0.8.0;
 contract BEINERC20 is IERC20{
     
     string public constant name = "BET-INDIA COIN";
    string public constant symbol = "BEIN";
    uint8 public constant decimals = 18;
     mapping(address=>uint256) private balances;
     mapping(address=>mapping(address=>uint256)) private allow;
     uint256 _totalSupply;
     constructor(uint256 _total){
         _totalSupply=_total;
         balances[msg.sender]=_total;
     }
     function totalSupply() public view override returns(uint256){
         return _totalSupply;
     }
     function balanceOf(address _tokenOwner) public view override returns(uint256){
         return balances[_tokenOwner];
     }
     function transfer(address _reciever , uint256 _amount) public override returns(bool){
         require(_amount<=balances[msg.sender]);
         balances[msg.sender]-=_amount;
         balances[_reciever]+=_amount;
         emit Transfer(msg.sender,_reciever,_amount);
         return true;
     }
     function approve(address delegate, uint _numTokens) public override returns(bool){
         allow[msg.sender][delegate]=_numTokens;
         emit Approval(msg.sender,delegate,_numTokens);
         return true;
     }
     function allowance(address owner,address _account) public override view returns(uint){
        return allow[owner][_account];
     }
     function transferFrom(address _owner, address buyer, uint numToken) public override returns(bool){
         require(numToken<=allow[_owner][buyer]);
         require(numToken<=balances[_owner]);
         balances[_owner]-=numToken;
         allow[_owner][msg.sender] -=numToken;
         balances[buyer]+=numToken;
         emit Transfer(_owner,buyer,numToken);
         return true;
     }
 }