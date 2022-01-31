/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

// File: contracts/libs/IBEP20.sol


pragma solidity ^0.8.0;
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/BEP20.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;


contract BEP20 is IBEP20 {

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    address internal _owner;

    mapping(address => uint256) public _balances;

    mapping(address => mapping(address => uint256)) public _allowances;

 constructor(){
     _name = "HEC PAY";
     _symbol = "HCP";
    _decimals = 18;
    _totalSupply = 1000 * 10 ** 18;
    _balances[msg.sender] = _totalSupply;
    _owner = msg.sender;
 }

 modifier Onlyowner {
     require(msg.sender==_owner,"Caller is not owner");
     _;
 }

 function name()external view returns(string memory){
     return _name;
 }

 function symbol()external view returns(string memory){
     return _symbol;
 }

 function decimals()external view returns(uint8){
     return _decimals;
 }

 function getOwner()external view returns(address) {
     return _owner;
 }

 function totalSupply()external view returns(uint256){
     return _totalSupply;
 }

 function transfer(address recipient,uint256 amount)external returns(bool){
    _transfer(msg.sender,recipient,amount);
    return true;
 }

 function transferFrom(address sender, address recipient, uint256 amount)external returns(bool){
     require(amount<=_allowances[sender][msg.sender],"Allowance exceeded!");
     _transfer(sender,recipient,amount);
     _approve(sender,msg.sender,_allowances[sender][msg.sender]);
     return true;
 }

 function allowance(address owner_, address _spender)external view returns(uint){
     return _allowances[owner_][_spender];
 }

 function balanceOf(address _address)external view returns(uint256){
     return _balances[_address];
 }

 function approve(address spender_, uint256 _quantity)external returns(bool) {
     _approve(msg.sender,spender_,_quantity);
     return true;
 }

 function _approve(address owner_, address spender, uint256 amount)internal{
     _allowances[owner_][spender] = amount;
 }

 function _transfer(address sender_, address rec_, uint256 amount_)internal {
       require(_balances[sender_]<=amount_,"Insufficient balance");
       _balances[sender_] -= amount_;
       _balances[rec_] += amount_;

     }

}