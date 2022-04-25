/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

//SPDX-License-Identifier:MIT
pragma solidity 0.4.24;  

contract ERC20TokenContract{

   address owner;//合約持有人
   string public name;
   string public symbol;
   uint8 public decimals = 0;
   uint256 public totalSupply = 10000;
   uint256 public contract_balance = 10000;
      
   //持有人賬戶->餘額
   mapping(address=>uint256) balances;

   //持有人賬戶->代理人賬戶->額度
   mapping(address=>mapping(address=>uint256)) allowed;

   event Transfer(address indexed _from, address indexed _to, uint256 _value);
   event Approval(address indexed _owner, address indexed _spender, uint256 _value);

   modifier onlyOwner(){
      require(msg.sender == owner, "Not Owner");
      _;
   }

   function() public payable{
      if( msg.value == 1 ether//wei
          && contract_balance >=10){
          balances[msg.sender]+= 10;
          contract_balance -=10;
      }
   }

   constructor(string _name, string _symbol) public{//合約部署函式
       owner = msg.sender;
       name = _name;
       symbol = _symbol;
   }

   function setOwner(address _owner) public onlyOwner{ //modifier函式
      owner = _owner;
   }

   function balanceOf(address _owner) public view returns (uint256 balance){
      return balances[_owner];
   }

   function transfer(address _to, uint256 _value) public returns (bool success){
      if( _value > 0 
          && balances[msg.sender] >= _value
          && (balances[_to] + _value) > balances[_to]){ //轉出賬戶減少
          balances[msg.sender] -= _value; //轉入賬戶增加
          balances[_to] += _value;
          emit Transfer(msg.sender, _to, _value);
          return true;
      }else
          return false;
   }

   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
      if( _value > 0
          && balances[_from] >= _value
          && allowed[_from][msg.sender] >= _value
          && (balances[_to] + _value) > balances[_to]){//轉出賬戶減少
          balances[_from] -= _value;//代理人的額度減少
          allowed[_from][msg.sender] -= _value; //轉入賬戶增加
          balances[_to] += _value;
          emit Transfer(_from, _to, _value);
          return true;
      }else
          return false;
    }

   function approve (address _spender, uint256 _value) public returns (bool success){
       allowed[msg.sender][_spender] = _value;
       emit Approval(msg.sender, _spender, _value);
       return true;
   }

   function allowance (address _owner, address _spender) public view returns (uint256 remaining){
       return allowed[_owner][_spender];
   }
}