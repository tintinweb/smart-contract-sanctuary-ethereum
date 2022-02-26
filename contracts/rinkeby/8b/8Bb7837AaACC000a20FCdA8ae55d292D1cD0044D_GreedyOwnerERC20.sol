// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./IERC20.sol";

contract GreedyOwnerERC20 is IERC20 {
    address public owner;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Greedy Owner ERC20";
    string public symbol = "GOE";
    uint8 public decimals = 18;
    uint lastMint;

    constructor() {
        owner = msg.sender;
    }

    modifier hasAmount(address sender, uint amount) {
        require(balanceOf[sender] >= amount, "Insufficient balance");
        _;
    }

    function transfer(address recipient, uint amount) external hasAmount(msg.sender, amount) returns (bool) {
        balanceOf[msg.sender] -= amount;
        uint ownersFee = amount / 10 * 1; // 10% goes to the greedy owner
        balanceOf[recipient] += amount - ownersFee;
        balanceOf[owner] += ownersFee;
        emit Transfer(msg.sender, recipient, amount - ownersFee);
        emit Transfer(msg.sender, owner, ownersFee);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external hasAmount(sender, amount) returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        uint ownersFee = amount / 10 * 1; // 10% goes to the greedy owner
        balanceOf[recipient] += amount - ownersFee;
        balanceOf[owner] += ownersFee;
        emit Transfer(msg.sender, recipient, amount - ownersFee);
        emit Transfer(msg.sender, owner, ownersFee);
        return true;
    }

    function mint() external {
        require(block.timestamp - lastMint >= 60, "Last mint was less than 60 seconds ago"); // Only allow minting every 60 seconds
        lastMint = block.timestamp;
        uint token = 10**decimals;
        balanceOf[msg.sender] += token;
        balanceOf[owner] += token; // Of course, the owner also gets a token
        totalSupply += 2 * token;
        emit Transfer(address(0), msg.sender, 1 * token);
        emit Transfer(address(0), owner, 1 * token);
    }
}