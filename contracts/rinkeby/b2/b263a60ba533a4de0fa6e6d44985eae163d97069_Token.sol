/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Token{
    // each token has to have a name
    string public name ;
    string public symbol;
    uint256 public decimals ;
    uint256 public totalSupply;
    // decimals not supported in solidity 

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from,address indexed _to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);

    constructor (string memory _name,string memory _symbol, uint _decimals, uint _totalSupply){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer( address _to,uint256 _value)external returns(bool success){
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] = balanceOf[msg.sender] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(msg.sender,_to,_value);
        return true;
    }

    function _transfer( address _from,address _to,uint256 _value)internal{
        require(_to != address(0));

        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from,_to,_value);
    }

    function approve(address _spender,uint256 _value) external returns(bool){
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true; 
    }

    // assigning the address of control
    function transferFrom( address _from,address _to,uint256 _value)external  returns(bool){
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from,_to,_value);
        return true;
    }

}