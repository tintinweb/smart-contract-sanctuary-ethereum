/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

pragma solidity >= 0.8.7;

contract almost_erc20 {

    string public name;
    string public symbol;
    uint8  public  decimals;
    address owner;
    uint256 public totalSupply;

    constructor () {
        owner = msg.sender;
        decimals = 18;
        name = "ERC20";
        symbol = "PnT";
        totalSupply = 0;
    }

    event Transfer(address from, address to, uint256 value);
    event Approval(address k1, address k2, uint256 alv);

    mapping(address => uint) balances;

    mapping(address => mapping(address => uint256)) allowed;
    //mapping(from => mapping(spender => value))

    function approve(address spender, uint256 value) external returns(bool) {
        allowed[msg.sender][spender] = value;
        return true;
    }

    function allowance(address from, address spender) external view returns (uint256) {
        return allowed[from][spender];
    }

    function mint(address to, uint256 value) external {
        require(owner == msg.sender, "ERC20: You are not owner");
        totalSupply += value;
        balances[to] += value;
        emit Transfer(address(0), to, value);
    }

    function balanceOf(address to) external view returns (uint256) {
        return to.balance;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balances[msg.sender] >= value, "ERC20: not enough tokens");
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) external returns(bool) {
        require(balances[from] >= value, "ERC20: not enough tokens");
        require(allowed[from][msg.sender] >= value , "ERC20: no permission to spend");
        balances[from] -= value;
        balances[to] += value;
        allowed[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        emit Approval(msg.sender, to, allowed[from][msg.sender]);
        return true;
    }

}