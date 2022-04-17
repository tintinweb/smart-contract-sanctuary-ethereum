//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/ERC20.sol";

contract ItPubToken is ERC20{
    uint8 public decimals;
    uint256 public totalSupply;

    string public name;
    string public symbol;

    address private _tokenOwner;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        balance = _balances[_owner];
    }

    function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {
        remaining = _allowances[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(_balances[msg.sender] >= _value, "Not enough money");

        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);

        success = true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        success = true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        require(_allowances[_from][_to] >= _value, "Not permitted");
        require(_balances[_from] >= _value, "Not enough money");

        _balances[_from] -= _value;
        _balances[_to] += _value;

        emit Transfer(_from, _to, _value);

        success = true;
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function mint(uint256 amount) public {
        require(msg.sender == _tokenOwner, "Only owner can do that");
        _mint(msg.sender, amount);
    }

    constructor() {
        name = "ITPubToken";
        symbol = "ITP";
        decimals = 18;
        _tokenOwner = msg.sender;
        _mint(msg.sender, 1_000_000);
    }

    function _mint(address account, uint256 amount) internal {
        totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(_balances[account] >= amount, "Not enough money");
        totalSupply -= amount;
        _balances[account] -= amount;
        emit Transfer(account, address(0), amount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;


interface ERC20{
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function balanceOf(address _owner) external view returns(uint256 balance);
    function allowance(address _owner, address _spender) external view returns(uint256 remaining);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

}