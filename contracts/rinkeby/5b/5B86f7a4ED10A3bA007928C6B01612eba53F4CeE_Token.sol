/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.7;

contract Token {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    string private tokenName;
    string private tokenSymbol;
    uint256 private totalAmount;
    uint8 private decimalsValue;
    address public owner;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        uint8 _decimals
    ) {
        tokenName = _name;
        tokenSymbol = _symbol;
        totalAmount = _initialSupply;
        balances[msg.sender] = _initialSupply;
        decimalsValue = _decimals;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    modifier isOwner() {
        require(msg.sender == owner, "not an owner");
        _;
    }

    function name() public view returns (string memory) {
        return tokenName;
    }

    function symbol() public view returns (string memory) {
        return tokenSymbol;
    }

    function decimals() public view returns (uint8) {
        return decimalsValue;
    }

    function totalSupply() public view returns (uint256) {
        return totalAmount;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint256 _amount)
        public
        returns (bool success)
    {
        require(_amount <= balances[msg.sender], "not enough token!");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool success) {
        require(_amount <= balances[_from], "not enough token!");
        require(
            _amount <= allowances[_from][msg.sender],
            "amount is not allowed!"
        );
        balances[_from] -= _amount;
        balances[_to] += _amount;
        allowances[_from][msg.sender] -= _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function mint(address _account, uint256 _amount)
        public
        isOwner
        returns (bool success)
    {
        totalAmount += _amount;
        balances[_account] += _amount;
        emit Transfer(address(0), _account, _amount);
        return true;
    }

    function burn(address _account, uint256 _amount)
        public
        isOwner
        returns (bool success)
    {
        require(_amount <= balances[_account], "not enough token!");
        totalAmount -= _amount;
        balances[_account] -= _amount;
        emit Transfer(_account, address(0), _amount);
        return true;
    }
}