/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

//SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.0;
contract OwnToken 
{
    address public owner;
    string public name="saurabh";
    string public symbol="SST";
    uint256 public totalSupply;
    uint256 decimal= 18;
    mapping(address=>uint256) public balanceOf;
    mapping(address=>mapping(address=>uint256))public Allowance;
    constructor(uint256 _totalSupply) 
    {
        owner=msg.sender;
        totalSupply=_totalSupply;
        balanceOf[msg.sender] +=_totalSupply;
    
    }
    modifier onlyOwner()
    {
        require(owner==msg.sender,"Not Owner");
        _;
    }
    function burn(uint256 amount)public onlyOwner returns(uint256){
        balanceOf[owner] -=amount;
        totalSupply -=amount;
        return amount;
    }
   function approve (address spender, uint256 amount) public onlyOwner
    {
        require(balanceOf[msg.sender] >amount,"amount is greater than owner");
         require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(balanceOf[owner]> amount,"Exceed balance");
        Allowance[msg.sender][spender] += amount;
    }
    function increaseAllowance(address spender,  uint256 amount) public 
    {
        require(balanceOf[msg.sender] >amount,"amount is greater than owner");

         require( Allowance[msg.sender][spender] > amount,"exceeds balance");

        Allowance[msg.sender][spender] += amount;

    }
    function decreaseAllowance(address spender,  uint256 amount) public 
    {
        require(0 < amount,"amount is greater than owner");
        
        Allowance[msg.sender][spender] -= amount;

    }
    
    function transfer(address to,uint256 amount)public  returns(uint256)
    {
        balanceOf[msg.sender] -=amount;
        balanceOf[to] += amount;
    }
    function transferFrom(address spender,address recipient,uint256 amount) public returns(uint256)
    {
        require(Allowance[owner][spender] > amount,"exceed balance");
   Allowance[owner][spender] -=amount;
   balanceOf[owner] -=amount;
   balanceOf[recipient] +=amount;
    }
    function transferOwnership(address newOwner)public onlyOwner returns(address)
{
    require(owner != address(0), "invalid address ");
    owner=newOwner;
    return newOwner;
}

}