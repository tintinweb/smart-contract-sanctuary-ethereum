/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract ERC20 {
    uint256 public totalSupply = 1000000 * 10 ** 18;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    function transfer(address _to, uint256 _value) virtual public returns (bool) {
        require(balanceOf[msg.sender] >= _value && _value > 0, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool) {
        require(balanceOf[_from] >= _value && _value > 0, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract OptimisticERC20 is ERC20 {
    uint256 public gasFee;
    uint256 public gasFeePercentage;

    function setGasFee(uint256 _gasFee, uint256 _gasFeePercentage) public {
        gasFee = _gasFee;
        gasFeePercentage = _gasFeePercentage;
    }

    function transfer(address _to, uint256 _value) override public returns (bool) {
        uint256 fee = _value * gasFeePercentage / 100;
        require(balanceOf[msg.sender] >= _value + fee && _value > 0, "Insufficient balance");
        balanceOf[msg.sender] -= fee;
        balanceOf[_to] += fee;
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool) {
        uint256 fee = _value * gasFeePercentage / 100;
        require(balanceOf[_from] >= _value + fee && _value > 0, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value + fee, "Insufficient allowance");
        balanceOf[_from] -= fee;
        balanceOf[_to] += fee;
        return super.transferFrom(_from, _to, _value);
    }
}