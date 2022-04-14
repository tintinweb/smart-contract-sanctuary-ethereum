/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BadToken {
    string public name = "BadToken";
    string public symbol = "BAD";
    uint256 public decimals = 1e6;
    uint256 public totalSupply = 1e10;

    address private contractOwner;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _contractOwner,
        address indexed _spender,
        uint256 _value
    );

    constructor(address _contractOwner) {
        contractOwner = _contractOwner;
    }

    modifier owner() {
        require(msg.sender == contractOwner, "You are not the contract owner.");
        _;
    }

    function transferOwnership(address _to)
        external
        owner
        returns (bool sucess)
    {
        require(_to != address(0), "Empty address provided.");

        contractOwner = _to;

        return true;
    }

    function mint(address _account, uint256 value)
        external
        owner
        returns (bool sucess)
    {
        _balances[_account] += value;

        return true;
    }

    function burn(address _account, uint256 value)
        external
        owner
        returns (bool sucess)
    {
        _balances[_account] -= value;

        return true;
    }

    function balanceOf(address _owner)
        external
        view
        returns (uint256 balance)
    {
        return _balances[_owner];
    }

    function transfer(address _to, uint256 _value)
        external
        returns (bool success)
    {
        require(_balances[msg.sender] >= _value, "Not enough funds.");
        require(_to != address(0), "Empty address provided.");

        _balances[msg.sender] -= _value;
        _balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success) {
        require(_to != address(0), "Empty address provided.");
        require(_from != address(0), "Empty address provided.");
        require(
            _balances[_from] >= _value,
            "Not enough funds on sender balance."
        );
        require(
            _allowances[_from][msg.sender] >= _value,
            "Not enough funds were allowed."
        );

        _balances[_from] -= _value;
        _balances[_to] += _value;

        _allowances[_from][msg.sender] -= _value;

        return true;
    }

    function approve(address _spender, uint256 _value)
        external
        returns (bool success)
    {
        require(_spender != address(0), "Empty address provided.");

        _allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _contractOwner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return _allowances[_contractOwner][_spender];
    }
}