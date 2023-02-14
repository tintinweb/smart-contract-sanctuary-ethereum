/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;
abstract contract Implementation{
function name() public virtual view returns (string memory);
function symbol() public virtual view returns (string memory);
function decimals() public virtual view returns (uint8);
function totalSupply() public virtual view returns (uint256);
function balanceOf(address _owner) public virtual view returns (uint256 );
function transfer(address _to, uint256 _value) public virtual returns (bool );
function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
function approve(address _spender, uint256 _value) public  virtual returns (bool );
function allowance(address _owner, address _spender) public  virtual view returns (uint256 );
event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);


}
contract ownerstatus{
     address owner;
     address newowner;

  constructor (){
      owner ==msg.sender;
                }
     
     function ownership_chnage(address _to) public { 
         require(msg.sender==owner,"You are not the owner ");
         newowner=_to;
        }
        function accept_ownership()public   returns(address){
            require( msg.sender==newowner," Only new owner can excute the function");
            owner=newowner;
            return newowner;
        }
    }
     


contract mytoken is Implementation,ownerstatus {

    string  public _token_name;
    string  public _symbol;
    uint8 public  _token_decimal;
    uint256 public _total_supply;
    mapping(address=>uint) balances;
    mapping(address=>mapping(address=>uint256)) approval;



    constructor(){
        _token_name="Zotish";
        _symbol="ztc";
        _token_decimal=8;
        _total_supply=1000000000000;
        balances[msg.sender]=_total_supply; 

    }
function name() public override view  returns (string memory ){
        return _token_name;
}
function symbol() public override  view returns (string memory ){
        return _symbol;
}
function decimals() public override view  returns (uint8){
        return _token_decimal;
}
function totalSupply() public override view  returns (uint256){
        return _total_supply;
}
function balanceOf(address _owner) public override view   returns (uint256 ){
        return balances[_owner];
}
function transfer(address _to, uint256 _value) public override  returns (bool ){
         require(balances[msg.sender]>=_value,"you donot have sufficient balance ");
         balances[msg.sender] -= _value;
         balances[_to] +=_value;
        emit Transfer(msg.sender,_to,_value);
        return true;
}
function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success){
           uint256 allowbal =approval[_from][_to]=_value;
           require(allowbal>=_value,"insu");
           return true;
        
}
function approve(address _spender, uint256 _value) public  override returns (bool ){
           require(balances[msg.sender] >=_value, "Inusuffiecnet balance ");
         approval[msg.sender][_spender]=_value;
         emit Transfer(msg.sender,_spender,_value);
         return true;
         
}
function allowance(address _owner, address _spender) public  override view  returns (uint256 ){
              return approval[_owner][_spender];
}




}