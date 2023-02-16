/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

pragma solidity ^0.5.8;     

library SafeMath
{
    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        assert(b <= a);
        uint256 c = a - b;
        return c;
    }
}

contract Variable{
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    address owner;
    
    uint256 internal _decimals;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) internal allowed;

    constructor() public{
        name = "TestToken";
        symbol = "TTN";
        decimals = 18;
        _decimals = 10 ** uint256(decimals);
        totalSupply = _decimals * 1000;
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }
}

contract Modifiers is Variable
{
    modifier isValidAddress
    {
        assert(address(0) != msg.sender);
        _;
    }
}

contract Event
{
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TTN is Variable, Event, Modifiers
{
    using SafeMath for uint256;

    function() external payable 
    {
        revert();
    }

    function transfer(address _to, uint256 _value) public isValidAddress returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);
        require((balanceOf[_to].add(_value)) >= balanceOf[_to]);
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public isValidAddress returns (bool success)
    {
        require(_to != address(0)); 
        require(_value <= balanceOf[_from]); 
        require(_value <= allowed[_from][msg.sender]); 

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); 

        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256)
    {
        return allowed[_owner][_spender];
    }
}