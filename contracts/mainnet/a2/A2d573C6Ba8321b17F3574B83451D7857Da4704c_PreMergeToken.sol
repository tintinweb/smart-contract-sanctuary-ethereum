/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

pragma solidity ^0.8.17;

contract PreMergeToken {

    string public name = "Pre Merge Token";
    string public symbol = "PREM";
    uint8 public decimals = 18;
    uint256 public totalSupply = 42000000e18;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;  

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor ()
    {
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address owner)
    public
    view
    returns (uint256) 
    {
        return balances[owner];
    }

    function allowance(address owner, address spender)
    public
    view
    returns (uint256)
    {
        return allowed[owner][spender];
    }

    function transfer(address to, uint256 value)
    public
    returns (bool) 
    {
        require(balances[msg.sender] >= value);
        require(balances[to] + value >= balances[to]);
        balances[msg.sender] = balances[msg.sender] - value;
        balances[to] = balances[to] + value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value)
    public
    returns (bool) 
    {
        require(spender != address(0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
    public
    returns (bool)
    {
        require(balances[from] >= value);
        require(allowed[from][msg.sender] >= value);
        require(balances[to] + value >= balances[to]);
        balances[from] = balances[from] - value;
        balances[to] = balances[to] + value;
        allowed[from][msg.sender] = allowed[from][msg.sender] - value;
        emit Transfer(from, to, value);
        return true;
    }

}