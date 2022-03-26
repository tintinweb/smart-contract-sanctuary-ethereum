/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);
}

contract NduToken is IERC20 {
    string private _name;
    string private _symbol;

    uint8 private _decimals;
    uint256 private _totalSupply;

    address private _owner;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    constructor(uint256 _initSupply) {
        _name = "Ndu Token";
        _symbol = "NDT";
        _decimals = 18;
        _owner = msg.sender;

        _mint(msg.sender, _initSupply * 10**decimals());
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function balanceOf(address _account)
        public
        view
        override
        returns (uint256)
    {
        return _balances[_account];
    }

    function mint(address _to, uint256 _value)
        public
        mustBeOwner(msg.sender)
        returns (bool)
    {
        _mint(_to, _value);

        return true;
    }

    function transfer(address _to, uint256 _value)
        public
        override
        returns (bool)
    {
        require(
            _balances[msg.sender] >= _value,
            "Ndu Token: Insufficient funds"
        );

        _transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool) {
        require(
            _allowances[_from][msg.sender] >= _value,
            "Ndu Token: Allowance is not enough"
        );

        _transfer(_from, _to, _value);
        _allowances[_from][msg.sender] -= _value;

        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _account, address _spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[_account][_spender];
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) private {
        _balances[_from] -= _value;
        _balances[_to] += _value;

        emit Transfer(_from, _to, _value);
    }

    function _mint(address _to, uint256 _value) private {
        _balances[_to] += _value;
        _totalSupply += _value;

        emit Transfer(address(0), _to, _value);
    }

    modifier mustBeOwner(address _account) {
        require(_owner == _account, "Ndu Token: Caller must be owner");
        _;
    }
}