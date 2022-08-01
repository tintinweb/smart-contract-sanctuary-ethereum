/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-License-Identifier: MIT;
pragma solidity >=0.8.0 <0.9.0;
contract OwnToken {

    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;

    mapping(address => uint) public balanceof;
    mapping(address => mapping(address => uint)) public allowance;

    event transfer(address indexed _from, address indexed _to, uint256 value);
    event addspender(address indexed _owner, address indexed _spender,uint value);




    constructor(string memory _name,string memory _symbol, uint _decimals,uint _totalSupply){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceof[msg.sender] = totalSupply;

    }

    function internalTranfer(address _from, address _to, uint256 _value) internal {
        require(balanceof[_from] >= _value);
        require(_to != address(0));
        balanceof[_from] -= _value;
        balanceof[_to] += _value;
        emit transfer(_from,_to,_value);
    }

    function tranferTo(address _to, uint256 _value) external returns(bool) {
        require(balanceof[msg.sender] >= _value);
        internalTranfer(msg.sender,_to,_value);
        return true;
    }

    function approveSpender(address _spender, uint256 _value) external returns(bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit addspender(msg.sender,_spender,_value);
        return true;
    }

    function dexTransfer(address _from, address _to, uint _value) external returns(bool) {
        
        require(balanceof[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        allowance[_from][msg.sender] -= _value;
        internalTranfer(_from,_to,_value);
        emit transfer(_from,_to,_value);
        return true;
    }

}