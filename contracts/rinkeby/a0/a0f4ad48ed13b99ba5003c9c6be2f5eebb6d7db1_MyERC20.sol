/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

// SPDX-License-Identifier: GPL-3.8
pragma solidity 0.8.7;

abstract contract ERC20_STD //first contract to declare standard functions and events
 {

    function name() public view virtual returns (string memory);
function symbol() public view virtual returns (string memory);
function decimals() public view virtual returns (uint8);
function totalSupply() public view virtual  returns (uint256);
function balanceOf(address _owner) public view virtual returns (uint256 balance);
function transfer(address _to, uint256 _value) public virtual returns (bool success);
function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
function approve(address _spender, uint256 _value) public virtual returns (bool success);
function allowance(address _owner, address _spender) public view virtual returns (uint256 remaining);
event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    }

contract Ownership //2nd contract to set contract owner
    {
 
     address public contractOwner;
     address public newOwner;

     event TransferOwnership(address indexed _from,address indexed _to);

     constructor() {
         contractOwner = msg.sender;
     }

     function changeOwner(address _to) public {
         require(msg.sender == contractOwner,"Only owner of contract can change owner");
         newOwner= _to;
     }

     function acceptowner() public{
    
    require(msg.sender == newOwner,"only new owne can accept");
    contractOwner = newOwner;
    emit TransferOwnership(contractOwner,newOwner);
    newOwner = address(0);
     }

    }

contract MyERC20 is ERC20_STD,Ownership //to define function of abstract contract
{

    string public _name;//name of token uint remaining ;
    string public _symbol;//symbol
    uint8 public _decimal;//decimals
    uint256 public _totalSupply;//total supply

    address public _minter;//who supply in market

    mapping(address => uint256) tokenBalances;

    mapping(address => mapping(address => uint256)) allowed;
    //address(0x123) has access to transfer amount from address(0x3232,0x3233) which are in allowed list

    constructor(address minter_) {
        _name = "EST";
        _symbol = "EST";
        _decimal = 18;
        _totalSupply = 10000000*10**18;
        _minter = minter_;


        tokenBalances[_minter] = _totalSupply;



    }

   function name() public view override returns (string memory)//display name 
   {
       return _name;
   }

   function symbol() public view override returns (string memory)//display symbol
   {
       return _symbol;
   }

   function decimals() public view override returns (uint8)//display decimal
   {
       return _decimal;
   }

   function totalSupply() public view override  returns (uint256)//display total supply of account
   {
       return _totalSupply;
   }



   function balanceOf(address _owner) public view override returns (uint256 balance)//display balance of owner
   {
       return tokenBalances[_owner];
   }
   
   
   function transfer(address _to, uint256 _value) public override returns (bool success)//address of TO and VALUE
   {
    require(tokenBalances[msg.sender] >= _value,"insufficient token");
    tokenBalances[msg.sender] -= _value;
    tokenBalances[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
   }
   
   
   function approve(address _spender, uint256 _value) public override returns (bool success)
   {
        require( tokenBalances[msg.sender] >= _value,"insufficient balance");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }


   function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success){
    //uint256 allowedBal = allowed[_from][msg.sender];
    require( allowed[_from][msg.sender] >= _value , "Insufficient balance" );
    allowed[_from][msg.sender] -= _value;
    tokenBalances[_from] -= _value;
    tokenBalances [_to] += _value;
    return true;

   }


   function allowance(address _owner, address _spender) public view override returns (uint256 remaining){
       return allowed[_owner][_spender];
   }

   




}