/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

pragma solidity ^0.4.26;

contract zaza {
    address _authority;
    uint256 _totalsupply;
    mapping(address => uint256) _balance;
    mapping(address => mapping(address => uint256)) _allowance;
    
    constructor() public {
        _totalsupply = 0;
        _authority = msg.sender;        
    }

    modifier isOwner {
        require(msg.sender == _authority);
        _;
    }

    function owner() public view returns (address) {
        return _authority;
    }

    function name() pure public returns (string memory) {
        return 'ZAZA Token';
    }

    function symbol() pure public  returns (string memory) {
        return 'ZAZA';
    }

    function decimals() pure public returns (uint8) {
        return 8;
    }

    function totalSupply() public view returns (uint256) {
        return _totalsupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balance[_owner];
    }

    function mint(uint256 amount) public isOwner {
        _balance[_authority] += amount;
        _totalsupply += amount;
       emit Transfer(address(0),_authority,amount);
    }

    function burn(uint256 amount) public isOwner {
        require(_balance[_authority] >= amount);
        _balance[_authority] -= amount;
        _totalsupply -= amount;
        emit Transfer(_authority,address(0),amount);
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(_balance[msg.sender] >= _value);
        _balance[_to] += _value;
        _balance[msg.sender] -= _value;
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_allowance[_from][msg.sender] >= _value);
        _allowance[_from][msg.sender] -= _value;
        _balance[_from] -= _value;
        _balance[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        _allowance[msg.sender][_spender] = _value;
       emit  Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return _allowance[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);    
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}