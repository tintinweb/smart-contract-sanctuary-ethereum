/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address from, address indexed to, uint256 indexed value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenTest is IERC20 {    
    string public constant name = "duc token 6";
    string public constant symbol = "TOKENDUC6";
    uint8 public constant decimals = 0;
    uint256 totalSupply_ = 1000000;

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

   constructor() {       
        balances[msg.sender] = totalSupply_;    
        emit Transfer(address(0), msg.sender, totalSupply_);
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender]-numTokens;
        balances[receiver] = balances[receiver]+numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner]-numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender]+numTokens;
        balances[buyer] = balances[buyer]+numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    event Setting(uint a, uint[] b, bool c, bool[] d, string e, address f, address[] g);
    uint storedUint;
    uint[] storedUintArray;
    bool storedBool;
    bool[] storedBoolArray;
    string storedString;
    address storedAddress;
    address[] storedAddressArray;
    function set(uint a, uint[] memory b, bool c, bool[] memory d, string memory e, address f, address[] memory g) public {
        storedUint = a;
        storedUintArray = b;
        storedBool = c;
        storedBoolArray = d;
        storedString = e;
        storedAddress = f;
        storedAddressArray = g;
        emit Setting(a,b,c,d,e,f,g);
    }
    function get(uint a, uint[] memory b, bool c, bool[] memory d, string memory e, address f, address[] memory g) public pure returns (uint, uint[] memory, bool, bool[] memory, string memory, address, address[] memory) {
        //return (storedUint,storedUintArray,storedBool,storedBoolArray,storedString, storedAddress,storedAddressArray);
        return (a,b,c,d,e,f,g);
    }
}