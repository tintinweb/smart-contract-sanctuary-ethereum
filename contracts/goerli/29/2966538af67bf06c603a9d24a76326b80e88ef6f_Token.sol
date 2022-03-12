/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Token {

    string public name; // token name
    string public symbol; // token symbol
    uint256 public decimals; // token decimals
    uint256 public totalSupply; // token decimals
    // 10000000000000000000000000

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint _decimal, uint _totalSupply) {
        
        name = _name;
        symbol = _symbol;
        decimals = _decimal;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply;

    }

    function internalTransfer(address _from, address _to, uint256 _value) internal {

        require(_to != address(0));

        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);

        emit Transfer(_from, _to, _value);

    }

    function transferTo(address _to, uint256 _value) external returns(bool) {

        require(balanceOf[msg.sender] >= _value);
        internalTransfer(msg.sender, _to, _value);
        return true;

    }

    function approve(address _spender, uint256 _value) external returns(bool){

        require(_spender != address(0));

        allowance[msg.sender][_spender] = _value; // allows DEX an amount
        emit Approval(msg.sender, _spender, _value);
        return true;

    }


    function transferFrom(address _from, address _to, uint256 _value) external returns(bool) {

        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        internalTransfer(_from, _to, _value);
        return true;

    }

}