/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ClickForAction {
    string nameCrypto = "https://Click4Action.top";

    function name() public view returns (string memory) {
        return nameCrypto;
    }

    function symbol() public pure returns (string memory) {
        return "CLICK";
    }

    function decimals() public pure returns (uint256) {
        return 18;
    }

    mapping (address => uint256) balance;
    mapping (address => mapping(address => uint256)) _allowances;

    uint256 totalSupply;

    function mint(address _account, uint256 _amount) public {
        balance[_account] += _amount;
        totalSupply += _amount;
        emit Transfer(address(0), _account, _amount);
    }

    function burn(address _account, uint256 _amount) public {
        balance[_account] -= _amount;
        totalSupply -= _amount;
        emit Transfer(_account, address(0), _amount);
    }

    function transfer (address _to, uint256 _amount) public {
        balance[msg.sender]-=_amount;
        balance[_to]+=_amount;
        emit Transfer(msg.sender, _to, _amount);
    }

    function transferFrom (address _from, address _to, uint256 _amount) public {
        uint256 currentAllowance = _allowances[_from][msg.sender];
        require (currentAllowance >= _amount, "Not enough permission");
        balance[_from] -= _amount;
        balance[_to] += _amount;
        _allowances[_from][msg.sender] -= _amount;
        emit Transfer(_from, _to, _amount);
    }

    function approve(address _spender, uint256 _amount) public {
        _allowances[msg.sender][_spender] = _amount;
    }

    /*function increaseAllowance(address _spender, uint256 _amount) public {
        _allowances[msg.sender][_spender] += _amount;
    }

    function decreaseAllowance(address _spender, uint256 _amount) public {
        _allowances[msg.sender][_spender] -= _amount;
    }*/
    event Transfer(address _from, address _to, uint256 _amount);

    function balanceOf(address _account) public view returns(uint256) {
        return balance[_account];
    }

    function allowance(address _owner, address _spender) public view returns(uint256) {
        return _allowances[_owner][_spender];
    }

}