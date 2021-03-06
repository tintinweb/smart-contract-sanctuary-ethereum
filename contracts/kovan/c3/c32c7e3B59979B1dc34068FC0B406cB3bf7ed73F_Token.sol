/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.11;

contract Token {
    string public name;
    string public symbol;
    uint256 public decimal;
    uint256 public totalSupply;

mapping(address => uint256) public balanceOf;
mapping(address => mapping(address => uint256)) public allowance;
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);

constructor (string memory _name, string memory _symbol, uint _decimal,uint _totalSupply ) {
    name = _name;
    symbol = _symbol;
    decimal = _decimal;
    totalSupply = _totalSupply;
    balanceOf[msg.sender] = totalSupply;
}

function _transfer(address _from, address _to, uint256 _value) internal {
    require(_to != address(0));
    balanceOf[_from] = balanceOf[_from] - (_value);
    balanceOf[_to] = balanceOf[_to] + (_value);
    emit Transfer(_from,_to,_value);
}
function approve(address _spender, uint256 _value) external returns (bool) {
    require(_spender != address(0));
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender,_value);
    return true;
}

function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
    require(_value <= balanceOf[_from]);
    require(_value <= allowance[_from][msg.sender]);
    allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
    _transfer(_from,_to,_value);
    return true;
}


}