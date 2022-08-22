/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

abstract contract erc20 {
    function name() public view virtual returns (string memory);
    function symbol() public view virtual returns (string memory);
    function decimals() public view virtual returns (uint8);
    function totalSupply() public view virtual returns (uint256);
    function balanceOf(address _owner) public view virtual returns (uint256 balance);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) public view virtual returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ownership{
    address public contractOwner;
    address public newOwner;
    event TransferOwnership(address indexed _from, address indexed _to);
    constructor () {
        contractOwner = msg.sender;
    }
    function changeowner(address _to) public {
        require(msg.sender==contractOwner,"only can change ownership");
        newOwner = _to;
    }
    function accept_ownership() public {
        require(msg.sender==newOwner,"you can't able to accept");
        emit TransferOwnership(contractOwner,newOwner);
        contractOwner = newOwner;
        newOwner=address(0); 
    }
}

contract erc20main is ownership,erc20{
    string public _name;
    string public _symbol;
    uint8 public _decimals;
    uint256 public _totalsupply;
    address public _minter;

    mapping(address => uint256) tokenBalances;
    mapping(address => mapping(address => uint256)) allowed;
    constructor (address minter_){
        _name = "Pharaoh's Fortune";
        _symbol= "PF";
        _totalsupply= 1000000;
        _minter= minter_;
        tokenBalances[_minter] = _totalsupply;
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

    function totalSupply() public view override returns (uint256){
        return _totalsupply;
    }

    function balanceOf(address _owner) public view override returns (uint256 balance){
        return tokenBalances[_owner];
    }
    function transfer(address _to, uint256 _value) public override returns (bool success){
        require(tokenBalances[msg.sender] >=_value,"insufficient Balance");
        tokenBalances[msg.sender] -=_value;
        tokenBalances[_to] +=_value;
        emit Transfer(msg.sender,_to,_value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success){
        uint256 allowedBal = allowed [_from][msg.sender];
        require(allowedBal >=_value, "insufficient Balance");
        tokenBalances[_from] -=_value;
        tokenBalances[_to] +=_value;
        emit Transfer(msg.sender,_to,_value);
        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool success){
        require( tokenBalances[msg.sender] >=_value,"insufficient Balance");
        allowed [msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }
    function allowance(address _owner, address _spender) public view override returns (uint256 remaining){
        return allowed [_owner][_spender];
    }

}