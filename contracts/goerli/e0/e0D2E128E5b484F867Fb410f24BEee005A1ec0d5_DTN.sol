/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

pragma solidity ^0.5.5;

library SafeMath
{
    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Variable
{
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    address public owner;

    uint256 internal _decimals;
    bool internal transferLock;

    mapping (address => uint256) public balanceOf;

    constructor() public
    {
        name = "DanToken";
        symbol = "DTN";
        decimals = 18;
        _decimals = 10 ** uint256(decimals);
        totalSupply = _decimals * 1000;
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
        transferLock = false;
    }
}

contract Modf is Variable
{
    modifier isValidAddress
    {
        assert(msg.sender != address(0));
        _;
    }

    modifier isOwner
    {
        assert(owner == msg.sender);
        _;
    }
}

contract Event
{
    event ethSend(address _from, address _to, uint256 _value);
}

contract LockOff is Variable
{
    function unlock() public view returns(bool)
    {
        return transferLock;
    }
}

contract LockOn is Variable, Modf
{
    function lock(bool _transferLock) public isOwner returns(bool success)
    {
        transferLock = _transferLock;
        return true;
    }
}

contract DTN is Variable, Modf, Event, LockOff, LockOn 
{
    using SafeMath for uint256;

    function() external payable
    {
        revert();
    }

    function transfer(address _to, uint256 _value) public isValidAddress
    {
        require(transferLock == false);
        require(balanceOf[msg.sender] >= _value && _value > 0);
        require((balanceOf[_to].add(_value)) >= balanceOf[_to]);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit ethSend(msg.sender, _to, _value);
    }
}