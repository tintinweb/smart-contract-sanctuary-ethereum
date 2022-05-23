// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ERC20 {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public amount;
    address public owner;

    mapping(address => uint256) private balances;

    // will it generate function allowanceMap ?
    mapping(address => mapping(address => uint256)) private allowanceMap;

    // event Transfer(address _from, address _to, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = msg.sender;
    }

    // Returns the total token supply.
    function totalSupply() public view returns (uint256) {
        return amount;
    }

    // Returns the account balance of another account with address _owner.
    function balanceOf(address _owner) public view returns (uint256 balance) {
        balance = balances[_owner];
    }

    // Transfers _value amount of tokens to address _to, and MUST fire the Transfer event.
    // The function SHOULD throw if the message caller’s account balance does not have enough tokens to spend.
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        success = false;
        require(balances[msg.sender] >= _value, "Not enough money");
        require(msg.sender != _to, "Transfering money to yourself");

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        success = true;
    }

    // The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf.
    // This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies.
    // The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism.
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        success = false;
        require(allowanceMap[_from][_to] >= _value, "asking too much money");
        require(balances[_from] >= _value, "_from has not enough money");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowanceMap[_from][_to] -= _value;
        emit Transfer(_from, _to, _value);
    }

    // address => address => amount;

    // Allows _spender to withdraw from your account multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowanceMap with _value.
    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        success = false;
        require(balances[msg.sender] >= _value, "Not enough money yet");
        allowanceMap[msg.sender][_spender] = _value;
        success = true;
        emit Approval(msg.sender, _spender, _value);
    }

    // Returns the amount which _spender is still allowed to withdraw from _owner.
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        remaining = allowanceMap[_owner][_spender];
    }

    function mint(uint256 _amount) public returns (bool success) {
        success = false;
        require(msg.sender == owner, "Only owner can call this function");
        amount += _amount;
        balances[owner] += _amount;
        success = true;
    }
}