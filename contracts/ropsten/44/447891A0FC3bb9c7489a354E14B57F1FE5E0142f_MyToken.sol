//SPDX-License-Identifier:MIT

//This Smart Contract creates ERC20 token with out using openzeppeling library.

pragma solidity ^0.8.4;

contract MyToken {
    //state variables that are needed.
    address public owner;
    string public _name;
    string public _symbol;
    uint256 public _decimal;
    uint256 public _totalSupply;

    //tracks token balance for accounts.
    mapping(address => uint256) public balance;
    //tracks amount that is allowed by one one contract to another to spend on its behalf.
    mapping(address => mapping(address => uint256)) public spenderAllowance;

    //triggers when token transfer happens from one account to another.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    //trigger when one account approves another account to spend certain amount of token on its behalf.
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    //token name,symbol and decimals is assigned at the time of creation of the token contract.
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 decimal_
    ) {
        owner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _decimal = decimal_;
    }

    //returns name of the token.
    function name() public view returns (string memory) {
        return _name;
    }

    //returns symbol of the token.
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    //returns decimals of the token.
    //eg. if token decimal is 5 then token balance of 100 actually means 100/(10**5) tokens.
    function decimals() public view returns (uint256) {
        return _decimal;
    }

    //returns total number of tokens in circulation.
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    //returns token balance of a given account.
    function balanceOf(address _account) public view returns (uint256) {
        return balance[_account];
    }

    //transfers desired value of token from caller of this function to desired recepient.
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "Please provide a valid recepient!");
        require(balance[msg.sender] >= _value, "Insufficient Balance!");

        balance[msg.sender] -= _value;
        balance[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    //returns token amount that is allowed by one account to another to spend on its behalf.
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return spenderAllowance[_owner][_spender];
    }

    //caller of this function approves another account to spend given amount of tokens on its behalf.
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "Please provide valid spender!");
        spenderAllowance[msg.sender][_spender] += _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    //if allowed caller of this function can transfer token from one account to another.
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(_from != address(0), "Please provide a valid sender!");
        require(_to != address(0), "Please provide a valid recepient!");

        require(balance[_from] >= _value, "Insufficient Balance");

        address spender = msg.sender;
        spendAllowance(_from, spender, _value);

        balance[_from] -= _value;
        balance[_to] += _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    //tracks remaining allowed token that an account can spend on behalf of another account.
    function spendAllowance(
        address _owner,
        address _spender,
        uint256 _value
    ) public {
        require(
            allowance(_owner, _spender) >= _value,
            "Not Enough allowed balance!"
        );
        spenderAllowance[_owner][_spender] -= _value;
    }

    //This function allows owner of this contract to mint new tokens.
    function mint(address _account, uint256 _value) public {
        require(msg.sender == owner, "You are not allowed to mint!");

        _totalSupply += _value;
        balance[_account] += _value;
    }

    //This function lets owner of this contract to burn existing token.
    function burn(address _account, uint256 _value) public {
        require(msg.sender == owner, "You are not allowed to burn!");

        _totalSupply -= _value;
        balance[_account] -= _value;
    }
}