/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.12;

contract MyCoin {
    string public name;
    string public symbol;
    uint   public totalSupply;
    uint   public decimals = 18;
    address ower;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);
    event  WithdrawalETH(address indexed src, uint wad);
    
    mapping (address => uint)                       public  balanceOf;
    mapping (address => uint)                       public  balanceOfETH;
    mapping (address => mapping (address => uint))  public  allowance;

    constructor(
        string memory _name,
        string memory _symbol,
        uint _totalSupply
    )
    {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply * 10 ** decimals;
        ower = address(msg.sender);
        balanceOf[ower] = totalSupply;
        balanceOf[address(this)] = totalSupply;
        emit Transfer(address(0),msg.sender,totalSupply);
    }
    
    function mint(uint amount) external{
        require(ower == msg.sender);
        balanceOf[ower] += amount;
        totalSupply += amount;
    }
    receive() external payable {
        deposit();
    }
    function deposit() public payable {
        balanceOfETH[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOfETH[msg.sender] >= wad);
        balanceOfETH[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit WithdrawalETH(msg.sender, wad);
    }
    
    function totalETH() public view returns (uint) {
        return address(this).balance;
    }
    
    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }
    
    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }
    
    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);
    
        if (src != msg.sender && allowance[src][msg.sender] != uint(2**256-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }
    
        balanceOf[src] -= wad;
        balanceOf[dst] += wad;
    
        emit Transfer(src, dst, wad);
    
        return true;
    }

   
}