/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
interface Erc20_SD
{
function name() external view  returns (string memory);
function symbol() external view returns (string memory);
function decimals() external view returns (uint8);

function totalSupply() external view returns (uint256);
function balanceOf(address _owner) external view returns (uint256 balance);
function transfer(address _to, uint256 _value) external returns (bool success);
function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
function approve(address _spender, uint256 _value) external returns (bool success);
function allowance(address _owner, address _spender) external view returns (uint256 remaining);

event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract LOTA is Erc20_SD {
    string public _name;
    string public _symbol;
    uint8 public _decimal;
    uint public _totalSupply;

    address public _minter;

    mapping(address=>uint256) totalbalances;
    mapping(address=>mapping(address=>uint256)) Allowed;

    constructor(address minter_) {
        _name="SATA";
        _symbol="STT";
        _totalSupply=100000000000*10**18;
        _minter=minter_;
        _decimal =18;
        totalbalances[_minter]=_totalSupply;
    }
    function name() public view returns (string memory){
        return _name;
    }
    function symbol() public view returns (string memory){
        return _symbol;
    }   
    function decimals() public view returns (uint8){
        return _decimal;
    }
    
    function totalSupply() public view returns (uint256){
         return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance){
       return totalbalances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        require(totalbalances[msg.sender]>= _value,"Balance is not sufficient");
        totalbalances[msg.sender]-= _value;
        totalbalances[_to] +=_value;
        emit Transfer(msg.sender,_to,_value);
        return true;
    }
    
    
    function approve(address _spender, uint256 _value) public returns (bool success){
        require(totalbalances[msg.sender]>= _value,"insufficient Balance");
        Allowed[msg.sender][_spender]=_value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }

    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining)
    {
        return Allowed[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        uint AllowedBalanc = Allowed[_from][msg.sender];
        require(AllowedBalanc>=_value);
        Allowed[_from][msg.sender] -= _value;
        totalbalances[_from] -= _value;
        totalbalances[_to] += _value;
        emit Transfer(_from,_to,_value);
        return true;
    }
}