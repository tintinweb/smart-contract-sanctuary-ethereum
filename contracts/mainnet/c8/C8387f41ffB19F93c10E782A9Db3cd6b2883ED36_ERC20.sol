/**
 *Submitted for verification at Etherscan.io on 2023-06-03
*/

pragma solidity ^0.8.0;

contract ERC20 {  
    string public name;  
    string public symbol;  
    uint8 public decimals;  
    uint256 public totalSupply;  
    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol, uint8 decimalUnits) {  
        balanceOf[msg.sender] = initialSupply;  
        totalSupply = initialSupply;  
        name = tokenName;  
        symbol = tokenSymbol;  
        decimals = decimalUnits;  
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {  
        require(_to != address(0));  
        require(balanceOf[msg.sender] >= _value);  
        require(balanceOf[msg.sender] <= balanceOf[_to]);  
        balanceOf[msg.sender] -= _value;  
        balanceOf[_to] += _value;  
        emit Transfer(msg.sender, _to, _value);  
        return true;  
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {  
        require(_to != address(0));  
        require(_from != address(0));  
        require(balanceOf[_from] >= _value);  
        require(balanceOf[_from] <= balanceOf[_to]);  
        require(balanceOf[msg.sender] >= _value);  
        require(balanceOf[msg.sender] <= balanceOf[_from]);  
        balanceOf[_from] -= _value;  
        balanceOf[_to] += _value;  
        balanceOf[msg.sender] -= _value;  
        emit Transfer(_from, _to, _value);  
        return true;  
    }  
}