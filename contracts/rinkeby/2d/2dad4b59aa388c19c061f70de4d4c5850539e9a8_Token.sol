/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Token {
    
    uint256 public constant tokenPrice = 1000; // 1 token for 5 wei
    string public name = "BlockToken";
    string public symbol = "BTK";
    uint256 public decimals = 18;
    uint256 public totalSupply = 1000000000000000000000000;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Bought(uint256 value);
    event Sold(uint256 value);

    constructor(){
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
    function buy(address _from, uint256 _value) external payable {
        require(msg.value == _value * tokenPrice, "Need to send exact amount of wei");
        _transfer(msg.sender, _from, _value);
        emit Bought(_value);
    }
    
    function sell(uint256 _value) external {
        // decrement the token balance of the seller
        balanceOf[msg.sender] -= _value;
        //increment the token balance of this contract
        balanceOf[address(this)] += _value;
        emit Transfer(msg.sender, address(this), _value);
        payable(msg.sender).transfer(_value * tokenPrice);
    }
}