/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface IERC20_3 { 

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    function mintApprove(address _owner, address _minter) external view returns (bool success);

    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract ERC20_3 is IERC20_3 {

    // DECLARE VIEW FUNCTIONS
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public initialSupply;
    address public owner;
    uint256 public burnedTokens;


    // CREATE CONSTRUCOR
    constructor() {

        name = "SecondToken";
        symbol = "ST";
        decimals = 18;

        // make deployer owner role
        owner = msg.sender;

        // initialSupply
        initialSupply = 200;

        balanceOf[owner] = initialSupply;

        totalSupply = initialSupply + totalSupply;

    }

    // set max
    uint256 public constant MAX_TOTAL_SUPPLY = 10000;

    // CREATE MAPPINGS
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowance;

    mapping(address => mapping(address => bool)) public mintApprove;


    // CREATE FUNCTIONS
    function transfer(address recipient, uint256 amount) public returns (bool success) {
        require(balanceOf[msg.sender] >= amount, "Insufficient Balance");

        balanceOf[recipient] += amount;

        balanceOf[msg.sender] -= amount;

        emit Transfer(msg.sender, recipient, amount);

        return true;

    }

    function approve(address spender, uint256 amount) public returns (bool success) {

        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {

        require(allowance[sender][msg.sender] >= amount, "Insufficient Allowance");

        balanceOf[recipient] += amount;

        balanceOf[sender] -= amount;

        allowance[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);

        return true;
    }

    // MINTING FUNCTIONS

    function approveMinter(address minter) public returns (bool success) {
        mintApprove[owner][minter] = true;

        return true;
    }


    modifier canMint {

        require(msg.sender == owner || mintApprove[owner][msg.sender], "You are not approved");
        _;

    }

    function mintTokens(address recipient, uint256 amount) public canMint returns (bool success) {

        require((totalSupply + amount) <= MAX_TOTAL_SUPPLY, "Mint amount exceeds Max Supply");

        totalSupply += amount;

        balanceOf[recipient] += amount;

        emit Transfer(address(0), recipient, amount);

        return true;
    }

    function burnTokens(uint256 amount) public returns (bool success) {

        require(balanceOf[msg.sender] >= amount);

        burnedTokens += amount;

        balanceOf[msg.sender] -= amount;

        totalSupply -= amount;
        
        emit Transfer(msg.sender, address(0), amount);

        return true;
    }

}