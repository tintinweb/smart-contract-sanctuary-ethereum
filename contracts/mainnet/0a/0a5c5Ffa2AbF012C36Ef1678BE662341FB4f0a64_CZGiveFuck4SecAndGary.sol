/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

// SPDX-License-Identifier: Unlicensed
// Simple and eficient PROBLEM?
// RUG is not a PROBLEM for you! What else can i do with this contract?
// All government agencies sucks a *****

//https://t.me/CZGiveFckforSecAndGary
//
pragma solidity ^0.8.0;

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CZGiveFuck4SecAndGary is ERC20 {
    string public constant name = "CZGiveFuck4SecAndGary";
    string public constant symbol = "PROBLEM?";
    uint8 public constant decimals = 18;

    uint256 private _totalSupply = 100000000 * 10**18; 
    uint256 public luckyMoneyWallet; //Just use in the first hour after launch!
    uint256 public startTime;
    bool public isStartTimeSet = false;
    uint256 public constant restrictedPeriod = 3600;
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    constructor() {
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        luckyMoneyWallet = 777888 * 10**18;
        owner = msg.sender;  // Contract Creator = who deployed
    }

    function isSecCorrupt() public pure returns (bool) {
        return true;
    }

    function renounceOwnership() public {
        require(msg.sender == owner, "Fck Off are you Gary?");
        emit OwnershipRenounced(owner);
        owner = address(0);
    }


    function setStartTime() public {
        require(msg.sender == owner, "Go Away Gary you can't do it!");
        require(!isStartTimeSet, "Stop wasting gas! IT's already done");
        startTime = block.timestamp;
        isStartTimeSet = true;
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

        if (block.timestamp > startTime + restrictedPeriod || msg.sender == owner) {
            balances[msg.sender] -= value;
            balances[to] += value;
        } else {
            require(balances[to] + value <= luckyMoneyWallet, "Exceeding initial hour limit? Contact the DEV. PROBLEM?");
            balances[msg.sender] -= value;
            balances[to] += value;
        }

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        require(to != address(0));

        if (block.timestamp > startTime + restrictedPeriod || from == owner) {
            balances[from] -= value;
            balances[to] += value;
            allowed[from][msg.sender] -= value;
        } else {
            require(balances[to] + value <= luckyMoneyWallet, "Exceeding initial hour limit? Contact the DEV. PROBLEM?");
            balances[from] -= value;
            balances[to] += value;
            allowed[from][msg.sender] -= value;
        }

        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
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
}

// Comment in the end of the contract PROBLEM?
// https://m.media-amazon.com/images/I/61sswsPkJXL._AC_UF1000,1000_QL80_.jpg PROBLEM?