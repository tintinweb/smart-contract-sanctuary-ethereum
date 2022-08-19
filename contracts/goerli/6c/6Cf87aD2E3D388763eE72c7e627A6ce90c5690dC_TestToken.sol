// SPDX-License-Identifier: MIT
pragma solidity >=0.4.23 <0.9.0;

contract TestToken {
    string public name = "TestToken"; // Name of the token - optional - builtin
    string public symbol = "TTK"; // Symbol of the token - optional - builtin
    string public standard = "TestToken v0.1"; // Test public variable with the version of the token

    uint256 public totalSupply; // variable that holds the total count of the tokens

    mapping(address => uint256) public balanceOf; // mapping to hold the token balance of the each account.
    mapping(address => mapping(address => uint256)) public allowance;

    // event that need to be triggered when a successful transaction is processed
    // Even the amount is 0 this event must be triggered
    // event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // event that need to be triggered when a transaction is approved successfully
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // another transfer event

    // constructor will initalize the totol tokens count and admins balance.
    constructor(uint256 _initialSupply) {
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
    }

    // Transfer function to transact the token from one account from another
    // required
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        // checking that the values of the sender has sufficient balance
        require(balanceOf[msg.sender] >= _value);

        // transferring the token
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        // emitting an event after the successful transfer
        emit Transfer(msg.sender, _to, _value);

        // the true value at the final return as the function declared
        return true;
    }

    // To approve the transaction.
    // required
    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        // updating the allowance mapping to track of the approvals.
        allowance[msg.sender][_spender] = _value;

        // emitting an event after the successful approval
        emit Approval(msg.sender, _spender, _value);

        // the true value at the final return as the function declared
        return true;
    }

    // This is a deligated trasfer,
    // account a allowed to spend some tokens from account b.
    function transferfrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        // basic conditions to throw if values are not valid to process
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);

        // Transaction
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        // updating the permission or approval given
        allowance[_from][msg.sender] -= _value;

        // transfer event to after the successful transfer
        emit Transfer(_from, _to, _value);


        // the true value at the final return as the function declared
        return true;
    }
}