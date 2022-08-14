// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    string public name;
    string public symbols;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) private ownerToBalance;
    mapping(address => mapping(address => uint256)) private allowances;

    constructor(
        string memory _name,
        string memory _symbols,
        uint256 _totalSupply
    ) {
        name = _name;
        symbols = _symbols;
        totalSupply = _totalSupply;
        ownerToBalance[msg.sender] = _totalSupply;
    }

    function balanceOf(address _owner) external view returns (uint256 balance) {
        return ownerToBalance[_owner];
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(
            allowances[_from][_to] >= _value,
            "transfer amount exceed amount"
        );
        _transfer(_from, _to, _value);
        allowances[_from][_to] -= _value;
        return true;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) private {
        require(_from != _to, "to == from");
        require(ownerToBalance[_from] >= _value, "insufficient balance");
        ownerToBalance[_from] -= _value;
        ownerToBalance[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowances[_owner][_spender];
    }
}