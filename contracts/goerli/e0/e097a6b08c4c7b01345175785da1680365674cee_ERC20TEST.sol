/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

/**
    ERC20代币测试用
    BSC测试网：
    AST : 0x1d5f43500A858Be40309C8183CC7083181241f55
    AUSDT : 0x4c66077E5D7A4C03dA86094037348Bf1e4a7EB9f
    Ropsten测试网:
    AST : 0xB5dBC7BAF2C6D3E79C43Bdd46662964342De3EC0
    AUSDT : 0x2aF21C21fEb926238561cddA11026Ef2059Cd02D
    Goerli 测试网：
    AST : 0xE2ecbA4709dCD1225c6776d6E9F1D2a824A616c1
    AUSDT: 0xE097A6B08C4c7b01345175785dA1680365674cEe
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20TEST {
    string public name;
    string public symbol;
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;
    uint256 balance;

    constructor (string memory name_,string memory symbol_) {
        name = name_;
        symbol = symbol_;
        mint(10000*10**18);
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)  public  returns (bool)  {
        require(balanceOf[src] >= wad);
        if (src != msg.sender && allowance[src][msg.sender] != ~uint(0)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }
        balanceOf[src] -= wad;
        balanceOf[dst] += wad;
        emit Transfer(src, dst, wad);
        return true;
    }

    function mint(uint _value)public payable{ 
        balanceOf[msg.sender] += _value; 
        balance +=_value;
        emit Deposit(msg.sender, _value); 
    }
}