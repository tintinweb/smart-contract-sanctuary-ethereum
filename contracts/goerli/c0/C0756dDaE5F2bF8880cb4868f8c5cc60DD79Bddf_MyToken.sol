/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT

/*


███████ ██████   ██████ ██████   ██████      ████████  ██████  ██   ██ ███████ ███    ██ ██ 
██      ██   ██ ██           ██ ██  ████        ██    ██    ██ ██  ██  ██      ████   ██ ██ 
█████   ██████  ██       █████  ██ ██ ██        ██    ██    ██ █████   █████   ██ ██  ██ ██ 
██      ██   ██ ██      ██      ████  ██        ██    ██    ██ ██  ██  ██      ██  ██ ██    
███████ ██   ██  ██████ ███████  ██████         ██     ██████  ██   ██ ███████ ██   ████ ██ 
                                                                                            
                                  contract coded by: Zain Ul Abideen AKA The Dragon Emperor

*/

pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract MyToken is IERC20 {
    mapping (address => uint) public _balances;
    mapping (address => mapping (address => uint)) private _allowed;
    string public name = "MyToken";
    string public symbol = "MTKN";
    uint public decimals = 1;
    uint private _totalSupply;
    address public _creator;

    constructor() {
        _creator = msg.sender;
        _totalSupply = 1000000;
        _balances[_creator] = _totalSupply;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) external view returns (uint256 balance) {
        return _balances[_owner];
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(_value > 0 && _balances[msg.sender] >= _value);
        _balances[_to] += _value;
        _balances[msg.sender] -= _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        require(_value > 0 && _balances[msg.sender] >= _value);
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(_value > 0 && _balances[_from] >= _value && _allowed[_from][_to] >= _value);
        _balances[_to] += _value;
        _balances[_from] -= _value;
        _allowed[_from][_to] -= _value;
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return _allowed[_owner][_spender];
    }
}