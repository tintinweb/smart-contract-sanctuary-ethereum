/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

pragma solidity 0.8.7;
contract ChocolatePudding
{
    string public name;
    string public symbol;
    uint8  public  decimals;
    address owner;
    uint256 public totalSupply = 0;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint256)) allowed;
    event Transfer(address from, address to, uint256 value);
    event Approval(address from, address to, uint256 newValue);

    constructor (string memory n, string memory s, uint8 dec)
    {
        name = n;
        symbol = s;
        decimals = dec;
        owner = msg.sender;
    }

    function mint(address to, uint256 value) public payable
    {
        require(msg.sender == owner, "ERC20: You are not owner");
        
        balances[to] += value;
        totalSupply += value;

        emit Transfer(address(0),to,value);
    }

    function balanceOf(address to) public view returns (uint256)
    {
        return balances[to];
    }

    function transfer(address to, uint256 value) public payable returns (bool)
    {
        require(balances[msg.sender] >= value, "ERC20: not enough tokens");

        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender,to,value);

        return true;
    }

    function approve(address spender, uint256 value) public payable returns(bool)
    {
        allowed[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function allowance(address from, address spender)public view returns (uint256)
    {
        return allowed[from][spender];
    }

    function transferFrom(address from, address to, uint256 value) public payable returns (bool)
    {
        require(balances[from] >= value, "ERC20: not enough tokens");
        require(allowance(from, msg.sender) >= value, "ERC20: no permission to spend");

        allowed[from][msg.sender] -= value;
        balances[from] -= value;
        balances[to] += value;

        emit Transfer(from, msg.sender, value);
        emit Approval(from, msg.sender, value);

        return true;
    }
}