/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7; 

abstract contract dend {
function name() public view virtual returns (string memory);
function symbol() public view virtual returns (string memory);
function decimals() public view virtual returns (uint8);

function totalSupply() public view  virtual returns (uint256);
function balanceOf(address _owner) public view virtual returns (uint256 balance);
function transfer(address _to, uint256 _value) public virtual returns (bool success);
function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
function approve(address _spender, uint256 _value) public virtual returns (bool success);
function allowance(address _owner, address _spender) public view virtual returns (uint256 remaining);

event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}
 contract Ownership {

    address public contractOwner; 
    address public newOwner;
    event TransferOwnership(address indexed _from, address indexed _to);
    // event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(){
        contractOwner=msg.sender;
    }
    function changeOwner(address _to) public{
        require(msg.sender == contractOwner, 'only owner of the contract can execute it');
        newOwner = _to;
    }
    function acceptOwner() public {
        require(msg.sender == newOwner, 'only new assigned owner can call it');
        emit TransferOwnership (contractOwner, newOwner); 
        contractOwner = newOwner;
        newOwner =address(0);
    }

}

contract dend20 is  dend, Ownership{

    string public _name;
string public _symbol;
uint8 public _decimals;
uint256 public _totalSupply;

address public _minter;

 mapping(address=> uint256) tokenBalance;
 mapping (address => mapping(address => uint256)) allowed; 
 

 constructor( address minter_){
 _name = "Dend"; 
 _symbol = "D20";
 _totalSupply = 12500000000;
_decimals = 18;

 _minter = minter_;
 tokenBalance[_minter] = _totalSupply;

 }


 function name() public view override returns (string memory){
    return _name;
    
  }
 function symbol() public view override returns (string memory){
    return _symbol;
 }
 function decimals() public view override returns (uint8){
    return _decimals;
  }

 function totalSupply() public view  override returns (uint256){
    return _totalSupply;
  }
 function balanceOf(address _owner) public view override returns (uint256 balance) {
    return tokenBalance[_owner]; 
  }
 function transfer(address _to, uint256 _value) public override returns (bool success){
    require (tokenBalance[msg.sender] >= _value,  'insufficient Token');
    tokenBalance[msg.sender] -= _value;
    tokenBalance[_to] += _value;
    emit Transfer(msg.sender, _to , _value);
    }

 function transferFrom(address _from, address _to, uint256 _value) public  override returns (bool success){
   uint256 allowedBal = allowed[_from][msg.sender]; 
   require (allowedBal >= _value, 'insufficient balance'); 
  tokenBalance[_from] -= _value;
  tokenBalance [_to] += _value;
  emit Transfer(_from, _to, _value);


   }
 function approve(address _spender, uint256 _value) public override returns (bool success){
   require(tokenBalance[msg.sender] >= _value, ' insufficient token');
   allowed[msg.sender][_spender] = _value;
   emit Approval(msg.sender, _spender, _value);
   return true;

   }
 function allowance(address _owner, address _spender) public view override returns (uint256 remaining){
  return allowed[_owner][_spender];


 }

}