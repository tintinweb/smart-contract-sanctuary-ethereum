/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

contract vicky{
    string public name;
    string public symbol;
    uint public decimals;
    uint public totalsupply;

    constructor(string memory _name,string memory _symbol,uint _decimals,uint _totalsupply){
        name=_name;
        symbol=_symbol;
        decimals=_decimals;
        totalsupply=_totalsupply;
        balanceof[msg.sender]=totalsupply;
    }
    mapping (address =>uint)public balanceof;
    mapping(address =>mapping(address =>uint))allowed;
    event sending(address indexed _from,address indexed _to,uint _value);
    event Approve(address indexed _from,address indexed _to,uint _value);
    
    function transfer(address _to,uint _value)external returns(bool){
        require(_to !=address(0),"invalid ether");
        require(_value <=balanceof[msg.sender],"insufficent ether");
        balanceof[msg.sender]-=_value;
        balanceof[_to]+=_value;
        emit sending(msg.sender,_to,_value);
        return true;
    }
    function approve(address _to,uint _value)external {
        require(_to !=address(0),"insufficend ether");
        allowed[msg.sender][_to]=_value;
        emit Approve(msg.sender,_to,_value);


    }
    function allownace(address _owner,address _reciver)external view returns(uint){
        return allowed[_owner][_reciver];
    }
    function transferfrom(address _from,address _to,uint _value)external returns(bool){
        require(_value <=balanceof[_from],"insufficend balance");
        require(allowed[_from][_to] <=_value,"insufficent ether");
        balanceof[_from]-=_value;
        allowed[_from][_to]-=_value;
        balanceof[_from]-=_value;
        balanceof[_to]+=_value;
        emit sending(msg.sender,_to,_value);
        return true;

    }
}