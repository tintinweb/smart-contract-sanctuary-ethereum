/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

pragma solidity ^0.8.0;

contract MyCoin {
    string public name = "BULLMASTIFF INU";
    string public symbol = "BMI";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * 10 ** uint256(decimals);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;
    uint256 public taxRate = 7;
    uint256 public burnRate = 1;
    bool public paused;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TaxRateUpdated(uint256 previousTaxRate, uint256 newTaxRate);
    event BurnRateUpdated(uint256 previousBurnRate, uint256 newBurnRate);
    event Paused();
    event Resumed();

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        owner = 0xd928bd8f10DC9C83D38E69046dCE8d5165299F8F;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(!paused, "Token transfer is paused.");

        uint256 taxAmount = (value * taxRate) / 100;
        uint256 burnAmount = (value * burnRate) / 100;

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value - taxAmount - burnAmount;
        balanceOf[owner] += taxAmount;

        // burn the tokens
        balanceOf[address(0)] += burnAmount;

        emit Transfer(msg.sender, to, value - taxAmount - burnAmount);
        emit Transfer(msg.sender, owner, taxAmount);
        emit Transfer(msg.sender, address(0), burnAmount);

        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(!paused, "Token transfer is paused.");

        uint256 taxAmount = (value * taxRate) / 100;
        uint256 burnAmount = (value * burnRate) / 100;

        balanceOf[from] -= value;
        balanceOf[to] += value - taxAmount - burnAmount;
        balanceOf[owner] += taxAmount;

        // burn the tokens
        balanceOf[address(0)] += burnAmount;

        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value - taxAmount - burnAmount);
        emit Transfer(from, owner, taxAmount);
        emit Transfer(from, address(0), burnAmount);

        return true;
    }

    function updateTaxRate(uint256 newTaxRate) public {
        require(msg.sender == owner, "Only the owner can update the tax rate.");
        emit TaxRateUpdated(taxRate, newTaxRate);
        taxRate = newTaxRate;
    }

    function updateBurnRate(uint256 newBurnRate) public {
        require(msg.sender == owner, "Only the owner can update the burn rate.");
        emit BurnRateUpdated(burnRate, newBurnRate);
        burnRate = newBurnRate;
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner, "Only the owner can transfer ownership.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
}

function pause() public {
    require(msg.sender == owner, "Only the owner can pause token transfers.");
    require(!paused, "Token transfers are already paused.");
    paused = true;
    emit Paused();
}

function resume() public {
    require(msg.sender == owner, "Only the owner can resume token transfers.");
    require(paused, "Token transfers are already resumed.");
    paused = false;
    emit Resumed();
}

function pauseTrading() public {
    require(msg.sender == owner, "Only the contract owner can pause trading.");
    paused = true;
    emit Paused();
}

function resumeTrading() public {
    require(msg.sender == owner, "Only the contract owner can resume trading.");
    paused = false;
    emit Resumed();
}

}