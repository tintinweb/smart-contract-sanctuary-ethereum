/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract eddieERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed; // uint here

    uint256 public decimals;
    uint256 public totalSupply_;
    uint256 public constant tokenPrice = 10**15;

    string public name;
    string public symbol;

    modifier sufficientBalance(address _spender, uint256 _value) {
        require(_value <= balances[_spender], "Insufficient Balance for User");
        _;
    }
    modifier sufficientApproval(
        address _owner,
        address _spender,
        uint256 _value
    ) {
        require(
            _value <= allowed[_owner][_spender],
            "Insufficient allowance for this User from owner"
        );
        _;
    }

    modifier validAddress(address _address) {
        require(_address != address(0), "Invalid address");
        _;
    }

    constructor(
        uint256 _totalSupply,
        uint256 _decimals,
        string memory _name,
        string memory _symbol
    ) {
        totalSupply_ = _totalSupply;
        decimals = _decimals;
        name = _name;
        symbol = _symbol;

        balances[msg.sender] = totalSupply_;
    }

    ////added virtual
    function totalSupply() public view virtual returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _owner)
        public
        view
        virtual
        returns (uint256 balance)
    {
        return balances[_owner]; // he used _who and only uint256 without balance
    }

    //uses to and and value without underscore deleted success from returns
    function transfer(address _to, uint256 _value)
        public
        virtual
        sufficientBalance(msg.sender, _value)
        validAddress(_to)
        returns (bool)
    {
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        virtual
        sufficientBalance(_from, _value)
        sufficientApproval(_from, msg.sender, _value)
        validAddress(_to)
        returns (bool)
    {
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        virtual
        validAddress(_spender)
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    //removed remaining from returns
    function allowance(address _owner, address _spender)
        public
        view
        virtual
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

  function buyToken(address _receiver)
        public
        payable
        validAddress(_receiver)
        returns (bool)
    {
        require(msg.value >= tokenPrice, "Need to send exact amount of wei");

        uint256 amount = msg.value / tokenPrice;
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[_receiver] = balances[_receiver] + amount;

        totalSupply_ += amount;

        emit Transfer(msg.sender, _receiver, amount);

        return true;
    }
}