/**
 *Submitted for verification at Etherscan.io on 2022-03-17
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
        require(_to != address(0), "ERC20: transfer to the zero address");

        uint senderBalance = _balances[msg.sender];
        require(senderBalance >= _amount, "ERC20: transfer amount exceeds balance");

        _balances[msg.sender] = senderBalance - _amount;
        _balances[_to] += _amount;

        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint) {
        return _allowance[_owner][_spender];
    }

    function approve(address _spender, uint _amount) external returns (bool) {
        require(_spender != address(0), "ERC20: approve to the zero address");

        _allowance[msg.sender][_spender] = _amount;

        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint _amount) external returns (bool) {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        uint senderAllowance = _allowance[_from][msg.sender];
        uint fromBalance = _balances[_from];

        require(senderAllowance >= _amount, "ERC20: transfer amount exceeds allowance");
        require(fromBalance >= _amount, "ERC20: transfer amount exceeds balance");

        _allowance[_from][msg.sender] = senderAllowance - _amount;
        _balances[_from] = fromBalance - _amount;
        _balances[_to] += _amount;

        emit Transfer(_from, _to, _amount);
        return true;
    }

    modifier onlyMinter {
        require(_minters[msg.sender], "Only minters can perform operation");
        _;
    }

    function mint(address _account, uint _amount) public onlyMinter {
        require(_account != address(0), "ERC20: mint to the zero address");

        _balances[_account] += _amount;
        totalSupply += _amount;

        emit Transfer(address(0), _account, _amount);
    }

    function burn(uint _amount) public {
        uint senderBalance = _balances[msg.sender];
        require(senderBalance >= _amount, "Cannot burn more than available balance");

        _balances[msg.sender] = senderBalance - _amount;
        totalSupply -= _amount;

        emit Transfer(msg.sender, address(0), _amount);
    }
}