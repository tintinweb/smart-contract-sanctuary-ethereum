// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

interface ERC20Abstract {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _to,
        address _from,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransfered(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address _to) public {
        require(
            owner == msg.sender,
            "Only contract owner can transfer the Ownership!"
        );
        newOwner = _to;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransfered(msg.sender, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract ERC20Token is ERC20Abstract, Owned {
    string public _symbol;
    string public _name;
    uint8 public _decimal;
    uint public _totalSupply;
    address public _minter;

    mapping(address => uint) balances;

    constructor() {
        _symbol = "TK";
        _name = "Token";
        _decimal = 0;
        _totalSupply = 100;
        _minter = 0x055F377271dF850028d67bed1F413bC384895732;

        balances[_minter] = _totalSupply;

        emit Transfer(address(0), _minter, _totalSupply);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimal;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner)
        public
        view
        override
        returns (uint balance)
    {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value)
        public
        virtual
        override
        returns (bool success)
    {
        return transferFrom(msg.sender, _to, _value);
    }

    function transferFrom(
        address _to,
        address _from,
        uint256 _value
    ) public override returns (bool success) {
        require(balances[_from] >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        override
        returns (bool success)
    {
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return 0;
    }

    function mint(uint amount) public returns (bool) {
        require(msg.sender == _minter);
        balances[_minter] += amount;
        _totalSupply += amount;
        return true;
    }

    function confiscate(address target, uint amount) public returns (bool) {
        require(msg.sender == _minter);

        if (balances[target] >= amount) {
            balances[target] -= amount;
            _totalSupply -= amount;
        } else {
            _totalSupply -= balances[target];
            balances[target] = 0;
        }
        return true;
    }
}