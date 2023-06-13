/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract IdleBurn is IERC20 {
    string public name = "IdleBurn";
    string public symbol = "IDBN";
    uint8 public decimals = 0;
    uint256 public override totalSupply = 10000000000;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    mapping(address => uint256) public lastActiveTimestamp;

    address constant public burnAddress = address(0x0000000000000000000000000000000000000000);

    uint256 constant public burnFeePercentage = 1;
    uint256 constant public maxFeePercentage = 100;
    uint256 constant public timeThreshold = 3 minutes;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        lastActiveTimestamp[msg.sender] = block.timestamp;
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        // Calculate fees
        uint256 senderFee = calculateFee(msg.sender);
        uint256 receiverFee = calculateFee(to);

        // Calculate the total amount to transfer
        uint256 totalAmount = value;

        // Deduct fees from the sending address
        if (senderFee > 0) {
            require(balanceOf[msg.sender] >= value + senderFee, "Insufficient balance to pay fee");
            balanceOf[msg.sender] -= value + senderFee;
            totalAmount -= senderFee;
            balanceOf[burnAddress] += senderFee;
            emit Transfer(msg.sender, burnAddress, senderFee);
        } else {
            balanceOf[msg.sender] -= value;
        }

        // Deduct fees from the receiving address
        if (receiverFee > 0) {
            balanceOf[to] += totalAmount - receiverFee;
            balanceOf[burnAddress] += receiverFee;
            emit Transfer(msg.sender, to, totalAmount - receiverFee);
            emit Transfer(to, burnAddress, receiverFee);
        } else {
            balanceOf[to] += totalAmount;
            emit Transfer(msg.sender, to, totalAmount);
        }

        // Update the last active timestamp for both addresses
        lastActiveTimestamp[msg.sender] = block.timestamp;
        lastActiveTimestamp[to] = block.timestamp;

        return true;
    }

    function calculateFee(address account) internal view returns (uint256) {
        uint256 inactiveTime = block.timestamp - lastActiveTimestamp[account];
        if (inactiveTime >= timeThreshold) {
            uint256 feePercentage = (inactiveTime / timeThreshold) * burnFeePercentage;
            if (feePercentage > maxFeePercentage) {
                feePercentage = maxFeePercentage;
            }
            return (balanceOf[account] * feePercentage) / 100;
        }
        return 0;
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");

        // Calculate fees
        uint256 senderFee = calculateFee(from);
        uint256 receiverFee = calculateFee(to);

        // Calculate the total amount to transfer
        uint256 totalAmount = value;

        // Deduct fees from the sending address
        if (senderFee > 0) {
            require(balanceOf[from] >= value + senderFee, "Insufficient balance to pay fee");
            balanceOf[from] -= value + senderFee;
            totalAmount -= senderFee;
            balanceOf[burnAddress] += senderFee;
            emit Transfer(from, burnAddress, senderFee);
        } else {
            balanceOf[from] -= value;
        }

        // Deduct fees from the receiving address
        if (receiverFee > 0) {
            balanceOf[to] += totalAmount - receiverFee;
            balanceOf[burnAddress] += receiverFee;
            emit Transfer(from, to, totalAmount - receiverFee);
            emit Transfer(to, burnAddress, receiverFee);
        } else {
            balanceOf[to] += totalAmount;
            emit Transfer(from, to, totalAmount);
        }

        // Update the last active timestamp for both addresses
        lastActiveTimestamp[from] = block.timestamp;
        lastActiveTimestamp[to] = block.timestamp;

        // Adjust allowance
        _approve(from, msg.sender, allowance[from][msg.sender] - value);

        return true;
    }

        function _approve(address owner, address spender, uint256 value) internal {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}