/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

pragma solidity ^0.8.0;

contract TibetanCyberShekels {

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    
    mapping(address => uint256) public balanceOf;

    constructor() {
        name = "Tibetan Cyber Shekels";
        symbol = "OM";
        decimals = 9;
        totalSupply = 999999999 * (10 ** decimals);
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}