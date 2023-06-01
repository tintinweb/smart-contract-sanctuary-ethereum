/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

pragma solidity ^0.8.0;

// This is shit coin, BloodMary
// https://twitter.com/VitalikButerin/status/1602429328347877376

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function approveAndCall(address spender, uint tokens, bytes calldata data) external returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
}

contract BloodMary is ERC20 {
    string public constant name = "BloodMary";
    string public constant symbol = "BloodMary";
    uint8 public constant decimals = 18;

    uint256 private _totalSupply = 65745840 * 10**18; 

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    constructor() {
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address player) public view override returns (uint256) {
        return balances[player];
    }

    function allowance(address player, address spender) public view override returns (uint256) {
        return allowed[player][spender];
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        require(value <= balances[msg.sender]);
        require(to != address(0));

        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
        for (uint256 i = 0; i < receivers.length; i++) {
            transfer(receivers[i], amounts[i]);
        }
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function approveAndCall(address spender, uint256 tokens, bytes calldata data) external override returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        require(to != address(0));
    
        balances[from] -= value;
        balances[to] += value;
    
        allowed[from][msg.sender] -= value;
    
        emit Transfer(from, to, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] -= subtractedValue;
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function burn(uint256 amount) external {
        require(amount != 0);
        require(amount <= balances[msg.sender]);
        _totalSupply -= amount;
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}