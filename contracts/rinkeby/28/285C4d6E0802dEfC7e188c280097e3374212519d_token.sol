/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface tokenRecipient 
{
    function recieveApproval (address _from, uint256 _value, address _token,bytes memory _extradata) external;
}

contract token 
{
    string public name;
    string public symbol;
    uint8 public decimals=9;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer (address indexed from, address indexed to, uint256 value);
    event Approval (address indexed owner, address indexed spender, uint256 value);
    event Burn (address indexed from, uint256 value);

    constructor (string memory _name, string memory _symbol, uint256 initialSupply)
    {
        name=_name;
        symbol=_symbol;
        totalSupply=initialSupply * 10**uint256(decimals);
        balanceOf [msg.sender] = totalSupply;
    }

    function _transfer (address _from, address _to, uint256 _value) internal 
    {
        require (_from != address(0), "address zero");
        require (_to != address(0), "address zero");
        require (balanceOf[_from]>=_value, "insufficient balance");
        emit Transfer (_from, _to, _value);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value; 
    }

    function transfer (address _to, uint256 _value) public returns (bool success)
    {
        _transfer (msg.sender, _to, _value);
        return true;
    }

    function transferFrom (address _from, address _to, uint256 _value) public returns (bool success)
    {
        require (_value<=allowance[_from][msg.sender], "Nothing");
        allowance [_from][msg.sender] -= _value;
        _transfer (_from, _to, _value); 
        return true;
    }

    function approve (address _spender, uint256 _value) public returns (bool success)
    {
        allowance [msg.sender][_spender] = _value;
        emit Approval (msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall (address _spender, uint256 _value, bytes memory _extradata) public returns (bool success)
    {
        tokenRecipient spender = tokenRecipient (_spender);
        if (approve(_spender,_value))
        {
            spender.recieveApproval (msg.sender, _value, address(this), _extradata);
            return true;
        }
    }

    function burn (uint256 _value) public returns (bool success)
    {
        require (balanceOf [msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn (msg.sender, _value);
        return true;
    }

    function burnFrom (address _from, uint256 _value) public returns (bool success)
    {
        require (balanceOf[_from] >= _value);
        require (_value <= allowance [_from][msg.sender]);
        balanceOf [_from] -= _value;
        totalSupply -= _value;
        emit Burn (msg.sender, _value);
        return true;
    }
}