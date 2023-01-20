/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract GMP {
    // Creating the GMPToken according to ECR-20
    string public constant name = "GMP Token";
    string public constant symbol = "GMP";
    uint8 public constant decimals = 18;

    // Represents the total amount of tokens created
    uint256 _totalSupply;

    // Relate addresses with balances
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    // Event emitted when a sucessfully transfer ocurr
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // Event emitted when a sucessfully approval
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // Excecuted only in deploy
    constructor(uint256 total) {
        _totalSupply = total;
        balances[msg.sender] = total;
    }

    // When the contract is deployed, select the amount of total supply
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // Check the balance of an address
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    // Function to transfer tokens
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(
            _value <= balances[msg.sender],
            "There are not enough funds to do the transfer"
        );
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(msg.sender, _to, _value);
        success = true;
    }

    // Function that allows to a user transact with the token
    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        success = true;
    }

    // Function to check the allowance of a specific user
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        remaining = allowed[_owner][_spender];
    }

    // Function to transfer from
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(
            _value <= balances[_from],
            "There are not enough funds to do the transfer"
        );
        require(_value <= allowed[_from][msg.sender], "Sender not allowed");

        balances[_from] = balances[_from] - _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(_from, _to, _value);
        success = true;
    }
}