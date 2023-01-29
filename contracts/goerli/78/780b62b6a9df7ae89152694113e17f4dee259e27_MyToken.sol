// SPDX-License-Identifier: MIT
pragma solidity >0.7.0 <=0.9.0;

import "./abstractERC20.sol";

contract MyToken is ERC20 {


    constructor(string memory _name,string memory _symbol, uint8 _decimals, uint256 _totalSupply) ERC20(_name,_symbol, _decimals)
    {
        totalSupply=_totalSupply;
        balanceOf[msg.sender]=_totalSupply * (10 ** decimals);
    }

    function transfer(address _to, uint256 _value) public override  returns (bool success){
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender] - _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        emit Transfer(msg.sender, _to, _value);
        return(true);
    }

    function transferFrom(address _from, address _to, uint256 _value) public override  returns (bool success){
        require(allowance[_from][msg.sender] >= _value);
        require(balanceOf[_from] >= _value);
        allowance[_from][msg.sender] -= _value;
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return(true);
    }

    function approve(address _spender, uint256 _value) public override  returns (bool success){
        allowance[msg.sender][_spender]=0;
        allowance[msg.sender][_spender]=_value;
        emit Approval(msg.sender, _spender, _value);
        return(true);
    }

}