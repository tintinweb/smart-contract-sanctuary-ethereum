/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;


contract Fractatus{

    address owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint )) walletApproved;



    constructor(){
        name = "Factatus";
        symbol = "FCS";
        decimals = 0;
        totalSupply = 1000;
        owner = msg.sender;
        balances[msg.sender] = 500;
    }


    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success){

        require(balances[msg.sender] >= _value);

        balances[msg.sender]-=_value;
        balances[_to]+=_value;

        emit Transfer(msg.sender,_to,  _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(msg.sender == _from || walletApproved[_from][msg.sender] >=_value );
        require(balances[_from] >= _value);

         walletApproved[_from][msg.sender] -= _value;
         balances[_from]-= _value;
         balances[_to]+= _value;

        emit Transfer(_from,_to,  _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        walletApproved[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return walletApproved[_owner][_spender];
    }


    function mint(address _to, uint _value ) public onlyOwner returns(bool success) {
        totalSupply += _value;
        balances[_to] += _value;
        emit Transfer(address(0),_to,  _value);
        return true;
    }



}