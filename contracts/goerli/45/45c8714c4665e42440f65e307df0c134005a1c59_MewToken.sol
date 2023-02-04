/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        _transferOwnerShip(address(0));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnerShip(newOwner);
    }

    function _transferOwnerShip(address newOwner) private {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract MewToken is IERC20, Ownable {
    uint   public totalSupply;
    string public name;
    string public symbol;
    uint8  public decimals;

    mapping(address => uint)                     public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    constructor() {
        name        = "Mew Token";
        symbol      = "MEW";
        decimals    = 18;
        totalSupply = 1000_000_000 * 10 ** 18;

        balanceOf[msg.sender] = totalSupply;
    }

    function approve(address spender, uint amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return(true);
    }

    function transfer(address recipient, uint amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return(true);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint    amount
    ) external returns (bool) {
        uint256 currentAllowance = allowance[sender][msg.sender];
        require(currentAllowance >= amount, "MewToken: transfer amount exceeds allowance");

        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, currentAllowance - amount);

        return(true);
    }

    function _transfer(
        address sender,
        address spender,
        uint    amount
    ) private {
        require(sender != address(0), "MewToken: transfer from the zero address");
        require(spender != address(0), "MewToken: transfer to the zero address");

        uint256 senderBalance = balanceOf[sender];
        require(senderBalance >= amount, "MewToken: transfer amount exceeds balance");

        balanceOf[sender] -= amount;
        balanceOf[spender] += amount;

        emit Transfer(sender, spender, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint    amount
    ) private {
        require(owner != address(0), "MewToken: approve from the zero address");
        require(spender != address(0), "MewToken: approve to the zero address");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}