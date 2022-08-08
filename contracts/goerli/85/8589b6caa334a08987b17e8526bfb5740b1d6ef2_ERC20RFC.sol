/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IERC20 {
    //Optional
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    //MustExist
    function totalSupply() external view returns (uint256);
    function balanceOf(address addr) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

    //Events
    event Transfer(address indexed from, address indexed to, uint256);
    event Approval(address indexed owner, address indexed spender, uint256);
}

contract ERC20RFC is IERC20 {
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    constructor(uint256 initialMint) {
        _balance[msg.sender] = initialMint * 10 ** 18;
        _totalSupply = initialMint * 10 ** 18;
    }
    
    function name() external pure returns (string memory) {
        return "cba test Coine";
    }

    function symbol() external pure returns (string memory) {
        return "CBA";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;        
    }
    
    function balanceOf(address addr) external view returns (uint256) {
        return _balance[addr];
    }

    function transfer(address to, uint256 value) external returns (bool) {
        //require(_balance[msg.sender] >= value, "ERC20: transfer amount exceeds balance");
        _balance[msg.sender] -= value;
        _balance[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        //require(_allowances[from][msg.sender] >= value, "ERC20: transfer amount exceeds balance");
        //require(_balance[from] >= value, "ERC20: transfer amount exceeds balance");
        _balance[from] -= value;
        _allowances[from][msg.sender] -= value;
        _balance[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }
}