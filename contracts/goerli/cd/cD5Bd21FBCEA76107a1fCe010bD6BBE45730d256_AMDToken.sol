// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

contract AMDToken {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 _totalSupply = 0;
    address _owner;


    constructor()  {
      _owner = msg.sender;
    }

    modifier isNotZeroAddress(address adrs) {
        require(adrs != address(0), "ERC20: approve from the zero address");
        _;
    }

    modifier isOwner() {
        require(msg.sender == _owner, "ERC20: only owner is allowed");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint amount) public returns (bool) {
        require(_balances[msg.sender]>=amount, "The owner doesn't have enough money");
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public isNotZeroAddress(spender) virtual  returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }


    function _transfer(address from, address to, uint256 amount) internal{
          _balances[from] -= amount;
          _balances[to] += amount;
    }

    function _mint(uint256 value, address to) public isNotZeroAddress(to) isOwner {
        _balances[to] +=value;
        _totalSupply+=value;
    }

    function _burn(address account, uint256 amount) internal isNotZeroAddress(account){
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount);
        _balances[account] = accountBalance - amount;
    }
}