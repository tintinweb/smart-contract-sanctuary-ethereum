/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract AwesomeCoin {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    uint public totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowance;

    mapping(address => bool) private _minters;

    string public name = "Awesome Coin";
    string public symbol = "AWC";
    uint8 public decimals = 18;

    constructor(uint256 _totalSupply) {
        _minters[msg.sender] = true;
        mint(msg.sender, _totalSupply);
    }

    function balanceOf(address _account) external view returns(uint){
        return _balances[_account];
    }

    function transfer(address _to, uint _amount) external returns (bool) {
        require(_balances[msg.sender] >= _amount, "ERC20: transfer amount exceeds balance");

        _balances[msg.sender] -= _amount;
        _balances[_to] += _amount;

        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint) {
        return _allowance[_owner][_spender];
    }

    function approve(address _spender, uint _amount) external returns (bool) {
        _allowance[msg.sender][_spender] = _amount;

        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint _amount) external returns (bool) {
        require(_allowance[_sender][msg.sender] >= _amount, "ERC20: transfer amount exceeds allowance");
        require(_balances[_sender] >= _amount, "ERC20: transfer amount exceeds balance");

        _allowance[_sender][msg.sender] -= _amount;
        _balances[_sender] -= _amount;
        _balances[_recipient] += _amount;

        emit Transfer(_sender, _recipient, _amount);
        return true;
    }

    modifier onlyMinter {
        require(_minters[msg.sender], "Only minters can perform operation");
        _;
    }

    function mint(address _account, uint _amount) public onlyMinter {
        _mint(_account, _amount);
    }

    function burn(uint _amount) public {
        _burn(msg.sender, _amount);
    }

    function _mint(address _to, uint _amount) internal {
        _balances[_to] += _amount;
        totalSupply += _amount;

        emit Transfer(address(0), _to, _amount);
    }

    function _burn(address _from, uint _amount) internal {
        require(_balances[_from] >= _amount, "Cannot burn more than available balance");

        _balances[_from] -= _amount;
        totalSupply -= _amount;

        emit Transfer(_from, address(0), _amount);
    }
}