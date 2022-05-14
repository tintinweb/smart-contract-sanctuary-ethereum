/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract MyToken {
    string public name = "My Token";
    string public symbol = "MTK";
    string public standard = "MTK Token v0.1";
    uint256 public totalSupply;
    uint8 public decimals;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed indexed _owner, address indexed _spender, uint256 _value);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint256 _initialSupply, uint8 _decimals) {
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
        decimals = _decimals;
        // allocate the initial supply
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    
    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]); //require allowance is big enough

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
}