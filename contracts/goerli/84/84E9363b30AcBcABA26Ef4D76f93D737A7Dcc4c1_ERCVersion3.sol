// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract ERCVersion3 {

    // reentrancy modifier
    modifier Reentrancy(){
        require(!lock, "Execution in process");
        lock = true;
        _;
        lock = false;
    }

    bool private lock;
    address private owner;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name;
    string public symbol;
    uint8 public decimals;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event AllowanceIncreased(
        address indexed owner,
        address indexed spender,
        uint value
    );
    event AllowanceDecreased(
        address indexed owner,
        address indexed spender,
        uint value
    );

    function start(uint amount) external {
        symbol = "HT";
        name = "Haris Tokens";
        decimals = 18;
        owner = msg.sender;
        mintTokens(amount);
    }

    function mintTokens(uint _amount) public Reentrancy {
        require(msg.sender == owner, "Not owner");
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
        emit Transfer(address(0), msg.sender, _amount);
    }

    function burnTokens(uint amount) external Reentrancy {
        require(msg.sender == owner, "Not owner");
        require(amount >= 1, "Invalid amount");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    function transfer(address recipient, uint amount) external Reentrancy {
        require(msg.sender == owner, "Not owner");
        require(amount >= 1, "Invalid amount");
        require(recipient != address(0), "Invalid address");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
    }

    function approve(address spender,uint amount) external {
        require(amount >= 1, "Invalid amount");
        require(spender != address(0), "Invalid spender address");
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
    }
 
    function decreaseAllowance(address spender,uint amount) external
    {
        require(amount >= 1, "Invalid amount");
        require(spender != address(0), "Invalid spender address");
        require(allowance[msg.sender][spender] >= amount, "Invalid allowance amount");
        allowance[msg.sender][spender] -= amount;
        emit AllowanceDecreased(msg.sender, spender, amount);
    }

    function increaseAllowance(address spender,uint amount) external {
        require(amount >= 1, "Invalid amount");
        require(spender != address(0), "Invalid spender address");
        allowance[msg.sender][spender] += amount;
        emit AllowanceIncreased(msg.sender, spender, amount);
    }

    function transferFrom(address sender,address recipient,uint amount) external Reentrancy
    {
        require(amount >= 1, "Invalid amount");
        require(recipient != address(0), "Invalid recipient address");
        require(sender != address(0), "Invalid sender address");
        require(allowance[sender][msg.sender] >= amount, "Invalid allowance amount");
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
}